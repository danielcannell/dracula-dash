extends CanvasLayer

var cur_scale = 0.0


signal show_leaderboard()
signal restart()


func _ready():
	visible = false

func _on_death():
	if not visible:
		cur_scale = 0
		$ColorRect/VBoxContainer/Restart.grab_focus()
		visible = true

func _process(delta):
	if cur_scale < 3:
		var count_scale = min(cur_scale, 1)
		var down_scale = min(max(0, cur_scale-1.5), 1)
		$ColorRect/VBoxContainer/Count/Count.scale = Vector2(count_scale, count_scale)
		$ColorRect/VBoxContainer/Down/Down.scale = Vector2(down_scale, down_scale)
		cur_scale += 1.0 * delta

func _on_restart():
	restart.emit()
	visible = false

func _on_leaderbaord_pressed() -> void:
	show_leaderboard.emit()
