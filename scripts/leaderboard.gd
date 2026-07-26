extends CanvasLayer


const SCORES_URL = "https://api.dracula-dash.co.uk/scores"
enum HTTPState { IDLE, GET, POST }
var http_state: HTTPState = HTTPState.IDLE


var do_post: bool = false
var do_get: bool = false
var score: int = -1


func _ready() -> void:
	$HTTPRequest.request_completed.connect(self._on_request_completed)
	get_leaderboard()


func set_score(new_score: int):
	score = new_score


func post_score():
	if score < 0:
		return

	var regex := RegEx.new()
	regex.compile("[^a-zA-Z0-9 ]")
	var name = $ColorRect/VBoxContainer/HBoxContainer/NameLineEdit.text
	name = regex.sub(name, "", true)
	name = name.substr(0, 20)
	name = name.strip_edges()
	if name == "":
		return

	var err = $HTTPRequest.request(SCORES_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"name": name, "score": score}))
	if err == Error.OK:
		http_state = HTTPState.POST
	else:
		print("http error: ", error_string(err))


func get_score():
	var err = $HTTPRequest.request(SCORES_URL)
	if err == Error.OK:
		http_state = HTTPState.GET
	else:
		print("http error: ", error_string(err))


func next_request():
	if http_state != HTTPState.IDLE:
		return
		
	if do_post:
		do_post = false
		post_score()
		if http_state != HTTPState.IDLE:
			return
	
	if do_get:
		do_get = false
		get_score()
		if http_state != HTTPState.IDLE:
			return
			

func update_leaderboard(json: Dictionary):
	var container = $ColorRect/VBoxContainer/GridContainer
	
	# Remove all old entries
	for entry in container.get_children():
		container.remove_child(entry)
		entry.queue_free()
		
	for row in json["scores"]:
		var name: String = row["name"]
		var score: int = row["score"]
		
		var name_label = Label.new()
		name_label.text = name
		
		var score_label = Label.new()
		score_label.text = str(score)
		
		container.add_child(name_label)
		container.add_child(score_label)


func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if http_state == HTTPState.GET:
		if 200 <= response_code and response_code < 300:
			var json = JSON.parse_string(body.get_string_from_utf8())
			update_leaderboard(json)
		else:
			print("http error: get returned ", response_code)
			
	if http_state == HTTPState.POST:
		if 200 <= response_code and response_code < 300:
			pass
		else:
			print("http error: post returned ", response_code)
	
	http_state = HTTPState.IDLE
	next_request()


func get_leaderboard():
	do_get = true
	next_request()


func _on_submit_button_pressed() -> void:
	do_post = true
	do_get = true
	next_request()
