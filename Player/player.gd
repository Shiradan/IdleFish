class_name Player
extends Character

var input_locked := false
var accel := Vector2.ZERO
var last_direction := Vector2.ZERO

var is_active := true: set = set_is_active

@onready var timer: Timer = $Timer

func _ready():
	#warning-ignore: return_value_discarded
	timer.connect("timeout", _on_Timer_timeout)
	hide()

func _physics_process(_delta):
	direction = _get_direction()
	velocity=velocity.move_toward(direction*MAX_SPEED,ACCELERATION*_delta)
	sprite.flip_h=velocity.x<0	
	move_and_slide()
	
func setup(u: String, pos: Vector2) -> void:
	self.username = u
	global_position = pos
	spawn()
	set_process(true)
	show()

func spawn() -> void:
	set_process_unhandled_input(false)
	spawn_character()
	set_process_unhandled_input(true)

func set_is_active(value: bool) -> void:
	is_active = value
	set_process(value)
	set_process_unhandled_input(value)
	timer.paused = not value

func _get_direction() -> Vector2:

	var new_direction := Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), 
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		).normalized()
	if new_direction != last_direction:
		ServerConnection.send_direction_update(new_direction)
		last_direction = new_direction
	return new_direction

func _on_Timer_timeout() -> void:
	ServerConnection.send_position_update(global_position)
