extends VBoxContainer

const Notification := preload("res://UI/notification.tscn")


func add_notification(username: String, color: Color, disconnected := false) -> void:
	if not Notification:
		return
	var n := Notification.instantiate()
	add_child(n)
	n.setup(username, color, disconnected)

