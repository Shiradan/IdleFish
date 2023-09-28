extends Control

signal text_sent(text)
signal chat_edit_started
signal chat_edit_ended

@onready var chat_box := $HBoxContainer/ChatBox
@onready var toggle_chat_button := $HBoxContainer/ToggleChatButton
@onready var chat_bubble_icon := $ChatBubbleIcon

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		chat_box.line_edit.release_focus()
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if not chat_box.visible:
			toggle_chat_button.button_pressed = true
		if not chat_box.line_edit.has_focus():
			chat_box.line_edit.grab_focus()
	if event.is_action_pressed("ui_cancel") and not chat_box.line_edit.has_focus():
		toggle_chat_button.button_pressed = false

func add_chat_reply(text: String, sender: String, text_color: Color) -> void:
	chat_box.add_reply(text, sender, text_color)

func show_bubble():
	if not chat_box.visible:
		chat_bubble_icon.visible=true
	
func hide_bubble():
	chat_bubble_icon.visible=false


func _on_chat_box_text_sent(text):
	emit_signal("text_sent", text)


func _on_chat_box_edit_ended():
	emit_signal("chat_edit_ended")


func _on_chat_box_edit_started():
	emit_signal("chat_edit_started")

func _on_toggle_chat_button_toggled(_button_pressed):
	hide_bubble()
