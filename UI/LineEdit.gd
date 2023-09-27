extends LineEdit


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		release_focus()
		accept_event()
