extends Label


func _on_score_update(score: float):
	text = "Score: " + str(round(score))
