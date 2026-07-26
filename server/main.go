package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
	"unicode"
	"unicode/utf8"

	goaway "github.com/TwiN/go-away"
	_ "modernc.org/sqlite"
)

const (
	maxNameLen     = 32
	maxScore       = 1_000_000_000
	defaultLimit   = 100
	maxLimit       = 100
	requestTimeout = 5 * time.Second
	maxBodyBytes   = 4 << 10
)

type server struct {
	db *sql.DB
	rl *rateLimiter
}

type scoreEntry struct {
	Rank      int     `json:"rank"`
	Name      string  `json:"name"`
	Score     int64   `json:"score"`
	DeathPosX float64 `json:"death_pos_x"`
	DeathPosY float64 `json:"death_pos_y"`
	Created   int64   `json:"created"`
}

func main() {
	log.SetFlags(log.LstdFlags | log.LUTC)

	addr := env("LISTEN_ADDR", "127.0.0.1:8080")
	dbPath := env("DB_PATH", "scores.db")
	rate := envInt("RATE_LIMIT", 10)

	db, err := openDB(dbPath)
	if err != nil {
		log.Fatalf("open database %q: %v", dbPath, err)
	}
	defer db.Close()

	srv := &server{db: db, rl: newRateLimiter(rate, time.Minute)}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", srv.health)
	mux.HandleFunc("GET /scores", srv.listScores)
	mux.HandleFunc("POST /scores", srv.createScore)

	httpSrv := &http.Server{
		Addr:              addr,
		Handler:           logRequests(mux),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
		MaxHeaderBytes:    8 << 10,
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	errCh := make(chan error, 1)
	go func() {
		log.Printf("listening on %s (db=%s)", addr, dbPath)
		if err := httpSrv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errCh <- err
		}
	}()

	select {
	case err := <-errCh:
		log.Fatalf("serve: %v", err)
	case <-ctx.Done():
		log.Print("shutting down")
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := httpSrv.Shutdown(shutdownCtx); err != nil {
		log.Printf("shutdown: %v", err)
	}
}

func openDB(path string) (*sql.DB, error) {
	dataSourceName := "file:" + path +
		"?_pragma=journal_mode(WAL)" +
		"&_pragma=busy_timeout(5000)" +
		"&_pragma=synchronous(NORMAL)" +
		"&_pragma=foreign_keys(1)"

	db, err := sql.Open("sqlite", dataSourceName)
	if err != nil {
		return nil, err
	}

	db.SetMaxOpenConns(4)
	db.SetMaxIdleConns(4)
	db.SetConnMaxIdleTime(time.Hour)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := db.PingContext(ctx); err != nil {
		db.Close()
		return nil, err
	}

	const schema = `
		CREATE TABLE IF NOT EXISTS scores (
			id          INTEGER PRIMARY KEY AUTOINCREMENT,
			name        TEXT 	NOT NULL,
			score       INTEGER NOT NULL,
			death_pos_x REAL    NOT NULL,
			death_pos_y REAL    NOT NULL,
			created     INTEGER NOT NULL
		);
		CREATE INDEX IF NOT EXISTS scores_by_score ON scores (score DESC, created ASC);
	`

	if _, err := db.ExecContext(ctx, schema); err != nil {
		db.Close()
		return nil, fmt.Errorf("apply schema: %w", err)
	}
	return db, nil
}

func (s *server) health(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	_, _ = w.Write([]byte("ok\n"))
}

func (s *server) listScores(w http.ResponseWriter, r *http.Request) {
	limit := defaultLimit
	if raw := r.URL.Query().Get("limit"); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n < 1 || n > maxLimit {
			writeError(w, http.StatusBadRequest, fmt.Sprintf("limit must be an integer between 1 and %d", maxLimit))
			return
		}
		limit = n
	}

	ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
	defer cancel()

	rows, err := s.db.QueryContext(ctx, `
		SELECT name, score, death_pos_x, death_pos_y, created FROM scores
		ORDER BY score DESC, created ASC
		LIMIT ?`, limit)
	if err != nil {
		log.Printf("list scores: %v", err)
		writeError(w, http.StatusInternalServerError, "could not read scores")
		return
	}
	defer rows.Close()

	entries := make([]scoreEntry, 0, limit)
	for rows.Next() {
		var e scoreEntry
		if err := rows.Scan(&e.Name, &e.Score, &e.DeathPosX, &e.DeathPosY, &e.Created); err != nil {
			log.Printf("scan score row: %v", err)
			writeError(w, http.StatusInternalServerError, "could not read scores")
			return
		}
		e.Rank = len(entries) + 1
		entries = append(entries, e)
	}
	if err := rows.Err(); err != nil {
		log.Printf("iterate score rows: %v", err)
		writeError(w, http.StatusInternalServerError, "could not read scores")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"scores": entries})
}

func (s *server) createScore(w http.ResponseWriter, r *http.Request) {
	if !s.rl.allow(clientIP(r)) {
		w.Header().Set("Retry-After", "60")
		writeError(w, http.StatusTooManyRequests, "too many submissions, try again shortly")
		return
	}

	var body struct {
		Name      *string  `json:"name"`
		Score     *int64   `json:"score"`
		DeathPosX *float64 `json:"death_pos_x"`
		DeathPosY *float64 `json:"death_pos_y"`
	}
	dec := json.NewDecoder(http.MaxBytesReader(w, r.Body, maxBodyBytes))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "request body must be JSON: "+err.Error())
		return
	}
	if body.Name == nil || body.Score == nil || body.DeathPosX == nil || body.DeathPosY == nil {
		writeError(w, http.StatusBadRequest, `all fields are required`)
		return
	}

	name, ok := cleanName(*body.Name)
	if !ok {
		writeError(w, http.StatusBadRequest,
			fmt.Sprintf("name must be 1-%d printable characters", maxNameLen))
		return
	}

	score := *body.Score
	if score < 0 || score > maxScore {
		writeError(w, http.StatusBadRequest,
			fmt.Sprintf("score must be between 0 and %d", maxScore))
		return
	}

	deathPosX := body.DeathPosX
	deathPosY := body.DeathPosY

	ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
	defer cancel()

	res, err := s.db.ExecContext(ctx,
		`INSERT INTO scores (name, score, death_pos_x, death_pos_y, created) VALUES (?, ?, ?, ?, ?)`,
		name, score, deathPosX, deathPosY, time.Now().Unix())
	if err != nil {
		log.Printf("insert score: %v", err)
		writeError(w, http.StatusInternalServerError, "could not save score")
		return
	}
	id, err := res.LastInsertId()
	if err != nil {
		log.Printf("last insert id: %v", err)
		writeError(w, http.StatusInternalServerError, "could not save score")
		return
	}

	// How many scores beat this one, plus one.
	var rank int
	if err := s.db.QueryRowContext(ctx,
		`SELECT COUNT(*) + 1 FROM scores WHERE score > ?`, score).Scan(&rank); err != nil {
		log.Printf("compute rank: %v", err)
		rank = 0 // saved fine; just report an unknown rank
	}

	writeJSON(w, http.StatusCreated, map[string]any{"id": id, "rank": rank})
}

func cleanName(raw string) (string, bool) {
	if !utf8.ValidString(raw) {
		return "", false
	}
	name := strings.TrimSpace(raw)
	if name == "" || utf8.RuneCountInString(name) > maxNameLen {
		return "", false
	}
	for _, r := range name {
		if unicode.IsControl(r) {
			return "", false
		}
	}
	if goaway.IsProfane(name) {
		return "", false
	}
	return name, true
}

type rateLimiter struct {
	mutex  sync.Mutex
	counts map[string]*counter
	limit  int
	period time.Duration
}

type counter struct {
	n       int
	expires time.Time
}

func newRateLimiter(limit int, period time.Duration) *rateLimiter {
	rl := &rateLimiter{
		counts: make(map[string]*counter),
		limit:  limit,
		period: period,
	}
	go rl.collect()
	return rl
}

func (rl *rateLimiter) allow(key string) bool {
	if rl.limit <= 0 {
		return true
	}

	rl.mutex.Lock()
	defer rl.mutex.Unlock()

	now := time.Now()
	c, ok := rl.counts[key]
	if !ok || now.After(c.expires) {
		rl.counts[key] = &counter{n: 1, expires: now.Add(rl.period)}
		return true
	}

	if c.n >= rl.limit {
		return false
	}

	c.n++
	return true
}

func (rl *rateLimiter) collect() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		now := time.Now()
		rl.mutex.Lock()
		for k, c := range rl.counts {
			if now.After(c.expires) {
				delete(rl.counts, k)
			}
		}
		rl.mutex.Unlock()
	}
}

func clientIP(r *http.Request) string {
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		parts := strings.Split(xff, ",")
		return strings.TrimSpace(parts[len(parts)-1])
	}

	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}

	return host
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (sr *statusRecorder) WriteHeader(code int) {
	sr.status = code
	sr.ResponseWriter.WriteHeader(code)
}

func logRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rec, r)
		log.Printf("%s %s %d %s %s", r.Method, r.URL.Path, rec.status, time.Since(start).Round(time.Millisecond), clientIP(r))
	})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(payload); err != nil {
		log.Printf("write response: %v", err)
	}
}

func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]string{"error": msg})
}

func env(key string, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func envInt(key string, fallback int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
		log.Printf("ignoring invalid %s=%q", key, v)
	}
	return fallback
}
