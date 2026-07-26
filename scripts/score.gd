extends Label


func _on_score_update(score: int):
	text = "Score: " + str(score)
