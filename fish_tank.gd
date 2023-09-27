extends Node2D

@export var PlayerScene: PackedScene
@export var CharacterScene: PackedScene

var characters = {}

@onready var world = $Water
@onready var player: Node = $Player
@onready var game_ui := $CanvasLayer/GameUI

func _ready() -> void:
	#warning-ignore: return_value_discarded
	ServerConnection.connect(
		"initial_state_received", _on_ServerConnection_initial_state_received
	)
	
func join_world(
	state_positions: Dictionary,
	state_inputs: Dictionary,
	state_names: Dictionary
) -> void:
	var user_id := ServerConnection.get_user_id()
	assert(state_positions.has(user_id), "Server did not return valid state")
	var username: String = state_names.get(user_id)

	var player_position: Vector2 = Vector2(state_positions[user_id].x, state_positions[user_id].y)
	player.setup(username, player_position)

	var presences = ServerConnection._presences
	for p in presences.keys():
		var character_position := Vector2(state_positions[p].x, state_positions[p].y)
		var character_input = Vector2(state_inputs[p].dirx,state_inputs[p].diry)
		create_character(
			p, state_names[p], character_position, character_input, true
		)

	#warning-ignore: return_value_discarded
	ServerConnection.connect("presences_changed", _on_ServerConnection_presences_changed)
	#warning-ignore: return_value_discarded
	ServerConnection.connect("state_updated", _on_ServerConnection_state_updated)
	#warning-ignore: return_value_discarded
	ServerConnection.connect("character_spawned", _on_ServerConnection_character_spawned)
	#warning-ignore: return_value_discarded
	ServerConnection.connect(
		"chat_message_received", _on_ServerConnection_chat_message_received
	)


func create_character(
	id: String,
	username: String,
	pos: Vector2,
	direction: Vector2,
	do_spawn: bool
) -> void:
	var character = CharacterScene.instantiate()
	character.position = pos
	character.direction = direction

	#warning-ignore: return_value_discarded
	world.add_child(character)
	character.username = username
	characters[id] = character
	if do_spawn:
		character.spawn_character()
	else:
		character.do_hide()
	
func _on_ServerConnection_initial_state_received(
	positions: Dictionary, inputs: Dictionary, names: Dictionary
) -> void:
	#warning-ignore: return_value_discarded
	ServerConnection.disconnect(
		"initial_state_received", _on_ServerConnection_initial_state_received
	)
	join_world(positions, inputs, names)
	
func _on_ServerConnection_presences_changed() -> void:
	var presences = ServerConnection._presences

	for key in presences:
		if not key in characters:
			create_character(key, "User", Vector2.ZERO, Vector2.ZERO, false)

	var to_delete := []
	for key in characters.keys():
		if not key in presences:
			to_delete.append(key)

	for key in to_delete:
		characters[key].despawn()
		characters.erase(key)

func _on_ServerConnection_state_updated(positions: Dictionary, inputs: Dictionary) -> void:
	var update := false
	for key in characters:
		update = false
		if key in positions:
			var next_position: Dictionary = positions[key]
			characters[key].next_position = Vector2(next_position.x, next_position.y)
			update = true
		if key in inputs:
			var next_input: Dictionary = inputs[key]
			characters[key].next_input = Vector2(next_input.dirx,next_input.diry)
			update = true
		if update:
			characters[key].update_state()

func _on_ServerConnection_character_spawned(id: String, n: String) -> void:
	if id in characters:
		characters[id].username = n
		characters[id].spawn_character()
		characters[id].do_show()

func _on_ServerConnection_chat_message_received(sender_id: String, message: String) -> void:
	var color := Color.GRAY
	var sender_name := "User"

	if sender_id in characters:
		color = Color.SADDLE_BROWN
		sender_name = characters[sender_id].username
	elif sender_id == ServerConnection.get_user_id():
		color = Color.DARK_BLUE
		sender_name = player.username

	game_ui.add_chat_reply(message, sender_name, color)

func _on_game_ui_text_sent(text):
	ServerConnection.send_text_async(text)
