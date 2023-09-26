class_name Character
extends CharacterBody2D

signal spawned

const SCALE_BASE := Vector2(4.0,4.0)
const ANIM_IN_DURATION := 0.1
const ANIM_OUT_DURATION := 0.25

const MAX_SPEED := 80.0
const ACCELERATION := 400.0
const DRAG_AMOUNT := 0.2

var direction := Vector2.ZERO
var username := "": set= _set_username

var last_position := Vector2.ZERO
var last_input := Vector2.ZERO
var next_position := Vector2.ZERO
var next_input := Vector2.ZERO

@onready var sprite = $Sprite2D
@onready var id_label := $CenterContainer/Label
@onready var last_collision_layer := collision_layer
@onready var last_collision_mask := collision_mask



func _physics_process(delta):
	move(delta)
	
func move(delta: float) -> void:
	"Start Move"
	#var accel := ACCELERATION * direction
	#velocity = accel * delta
	#velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	#velocity.y = clamp(velocity.y, -MAX_SPEED, MAX_SPEED)
	velocity=velocity.move_toward(direction*MAX_SPEED,ACCELERATION*delta)
	sprite.flip_h=velocity.x<0
	move_and_slide()

func spawn_character() -> void:
	var tween:Tween = get_tree().create_tween()
	tween.tween_property(sprite,"scale",SCALE_BASE,0.75)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.play()
	emit_signal("spawned")

func despawn() -> void:
	var tween:Tween = get_tree().create_tween()
	tween.tween_property(self,"scale",Vector2.ZERO,1.0)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.play()
	queue_free()

func update_state() -> void:
	var tween:Tween = get_tree().create_tween()
	if global_position.distance_squared_to(last_position) > 10000:
		tween.tween_property(self,"global_position",last_position,0.2)
		tween.play()
	else:
		var anticipated := last_position + velocity * 0.2
		tween.tween_method(do_state_update_move,global_position,anticipated,0.2)
		tween.play()

	direction = last_input

	last_input = next_input
	last_position = next_position
	
func do_hide() -> void:
	collision_layer = 0
	collision_mask = 0
	hide()
	
func do_show() -> void:
	collision_layer = last_collision_layer
	collision_mask = last_collision_mask
	show()
	
func do_state_update_move(new_position: Vector2) -> void:
	velocity = new_position - global_position
	# warning-ignore:return_value_discarded
	move_and_slide()

func _set_username(value: String) -> void:
	username = value
	id_label.text = username
