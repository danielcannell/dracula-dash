extends CanvasLayer


func _ready():
	visible = false


func _show():
	visible = true


func _on_restart():
	visible = false
	get_tree().reload_current_scene()
