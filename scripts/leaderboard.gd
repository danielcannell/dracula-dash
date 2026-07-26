extends CanvasLayer


const SCORES_URL = "http://api.dracula-dash.co.uk/scores"
enum HTTPState { IDLE, GET, POST }
var http_state: HTTPState = HTTPState.IDLE


func _ready() -> void:
	$HTTPRequest.request_completed.connect(self._on_request_completed)
	get_leaderboard()


func get_leaderboard():
	if http_state == HTTPState.IDLE:
		var err = $HTTPRequest.request(SCORES_URL)
		if err == Error.OK:
			http_state = HTTPState.GET
		else:
			print("http error: ", error_string(err))


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
		http_state = HTTPState.IDLE
		
		if response_code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			update_leaderboard(json)
		else:
			print("http error: get returned ", response_code)
