extends Node

const DEFAULT_PORT=7350
const REMOTE_NAKAMA_SERVER_IP="www.qtwsbq.fun"
const SERVER_KEY="chaibao20230808"
const DEFAULT_PROTOCOL="http"

enum ReadPermissions {
	NO_READ,
	OWNER_READ,
	PUBLIC_READ
}

enum WritePermissions {
	NO_WRITE,
	OWNER_WRITE,
	PUBLIC_WRITE
}

enum OpCodes {
	UPDATE_POSITION = 1,
	UPDATE_INPUT = 2,
	UPDATE_STATE = 3,
	#UPDATE_JUMP,
	DO_SPAWN = 5,
	#UPDATE_COLOR,
	INITIAL_STATE = 7
}

# Emitted when the server has received the game state dump for all connected characters
signal initial_state_received(positions, inputs, names)

# Emitted when the `presences` Dictionary has changed by joining or leaving clients
signal presences_changed

# Emitted when the server has sent an updated game state. 10 times per second.
signal state_updated(positions, inputs)

# Emitted when the server has been informed of a new character having been selected and is ready to
# spawn.
signal character_spawned(id, name)

var _client=Nakama.create_client(SERVER_KEY,REMOTE_NAKAMA_SERVER_IP,DEFAULT_PORT,DEFAULT_PROTOCOL,10)
var _session:NakamaSession
var _socket:NakamaSocket
var _worldId=""
var _presences={}: set=_no_set
var error_message := "": set= _no_set, get= _get_error_message
var _exception_handler := ExceptionHandler.new()

func authenticate_async(email, password):
	var result=OK
	var new_session = await _client.authenticate_email_async(email,password,null,true)
	if not new_session.is_exception():
		_session=new_session
	else:
		result=new_session.get_exception().status_code
		print(new_session.get_exception()._to_string())
	return result

func connect_to_server_async():
	_socket=Nakama.create_socket_from(_client)
	var result=await _socket.connect_async(_session)
	if not result.is_exception():
		#warning-ignore: return_value_discarded
		_socket.connect("connected", _on_NakamaSocket_connected)
		#warning-ignore: return_value_discarded
		_socket.connect("closed", _on_NakamaSocket_closed)
		#warning-ignore: return_value_discarded
		_socket.connect("connection_error", _on_NakamaSocket_connection_error)
		#warning-ignore: return_value_discarded
		_socket.connect("received_error", _on_NakamaSocket_received_error)
		#warning-ignore: return_value_discarded
		_socket.connect("received_match_presence", _on_NakamaSocket_received_match_presence)
		#warning-ignore: return_value_discarded
		_socket.connect("received_match_state", _on_NakamaSocket_received_match_state)

		return OK
	return ERR_CANT_CONNECT

func join_world_async():
	var world:NakamaAPI.ApiRpc=await _client.rpc_async(_session,"get_world_id","")
	if not world.is_exception():
		_worldId=world.payload
		
	var matchJoinResult:NakamaRTAPI.Match=await _socket.join_match_async(_worldId)
	if matchJoinResult.is_exception():
		var exception:NakamaException=matchJoinResult.get_exception()
		printerr("Error joining the match: %s - %s" % [exception.status_code,exception.message])
		return {}
	
	for presence in matchJoinResult.presences:
		_presences[presence.user_id]=presence
	
	return _presences

func write_characters_async(chars):
	await _client.write_storage_objects_async(
		_session,
		[
			NakamaWriteStorageObject.new(
				"player_data",
				"characters",
				ReadPermissions.PUBLIC_READ,
				WritePermissions.OWNER_WRITE,
				JSON.stringify(
					{
						characters=chars
					}
				),
				""
			)
		]
	)

func read_characters_async():
	var characters=[]
	var storageObjects:NakamaAPI.ApiStorageObjects=await _client.read_storage_objects_async(
		_session,
		[
			NakamaStorageObjectId.new(
				"player_data",
				"characters",
				_session.user_id
			)
		]
	)
	
	if storageObjects.objects:
		var decodedCharacters=JSON.parse_string(storageObjects.objects[0].value).characters
		characters=decodedCharacters
		
	return characters

func get_user_id() -> String:
	if _session:
		return _session.user_id
	return ""

func send_position_update(position: Vector2):
	if _socket:
		var payload = {
				id = get_user_id(), 
				pos = {
					x = position.x, 
					y = position.y
				}
			}
		_socket.send_match_state_async(_worldId, OpCodes.UPDATE_POSITION, JSON.stringify(payload))

func send_direction_update(input):
	if _socket:
		var payload := {
				id = get_user_id(), 
				inp = {
					dirx=input.x,
					diry=input.y
				}
			}
		_socket.send_match_state_async(_worldId, OpCodes.UPDATE_INPUT, JSON.stringify(payload))

func send_spawn(n: String) -> void:
	if _socket:
		var payload := {id = get_user_id(), nm = n}
		_socket.send_match_state_async(_worldId, OpCodes.DO_SPAWN, JSON.stringify(payload))

# Called when the socket was connected.
func _on_NakamaSocket_connected() -> void:
	return

# Called when the socket was closed.
func _on_NakamaSocket_closed():
	_socket.close()
 
# Called when the socket was unable to connect.
func _on_NakamaSocket_connection_error(error: int) -> void:
	error_message = "Unable to connect with code %s" % error
	_socket.close()

# Called when the socket reported an error.
func _on_NakamaSocket_received_error(error: NakamaRTAPI.Error) -> void:
	error_message = str(error)
	_socket = null

# Called when the server reported presences have changed.
func _on_NakamaSocket_received_match_presence(new_presences: NakamaRTAPI.MatchPresenceEvent) -> void:
	for leave in new_presences.leaves:
		#warning-ignore: return_value_discarded
		_presences.erase(leave.user_id)

	for join in new_presences.joins:
		if not join.user_id == get_user_id():
			_presences[join.user_id] = join

	emit_signal("presences_changed")

# Called when the server received a custom message from the server.
func _on_NakamaSocket_received_match_state(match_state: NakamaRTAPI.MatchData) -> void:
	var code := match_state.op_code
	var raw := match_state.data

	match code:
		OpCodes.UPDATE_STATE:
			var decoded: Dictionary = JSON.parse_string(raw)

			var positions: Dictionary = decoded.pos
			var inputs: Dictionary = decoded.inp

			emit_signal("state_updated", positions, inputs)

		OpCodes.INITIAL_STATE:
			var decoded: Dictionary = JSON.parse_string(raw)

			var positions: Dictionary = decoded.pos
			var inputs: Dictionary = decoded.inp
			var names: Dictionary = decoded.nms

			emit_signal("initial_state_received", positions, inputs, names)

		OpCodes.DO_SPAWN:
			var decoded: Dictionary = JSON.parse_string(raw)

			var id: String = decoded.id
			var n: String = decoded.nm

			emit_signal("character_spawned", id, n)



func _no_set(_value) -> void:
	pass

func _get_error_message() -> String:
	return _exception_handler.error_message
