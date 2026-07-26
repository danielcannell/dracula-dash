extends Node


signal leaderboard_updated(leaderboard: Dictionary)


enum State { IDLE, GET, POST }


const SCORES_URL = "http://api.dracula-dash.co.uk/scores"
var state: State = State.IDLE
var http_request: HTTPRequest


func _ready() -> void:
	http_request = HTTPRequest.new()
	http_request.request_completed.connect(self._on_request_completed)
	add_child(http_request)


func get_leaderboard():
	if state == State.IDLE:
		var err = http_request.request(SCORES_URL)
		if err == Error.OK:
			state = State.GET
		else:
			print("http error: ", error_string(err))


func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if state == State.GET:
		state = State.IDLE
		var json = JSON.parse_string(body.get_string_from_utf8())
		leaderboard_updated.emit(json)
