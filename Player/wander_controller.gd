extends Node2D

@export var wander_range=32

@onready var start_position=global_position: set=set_start_position
@onready var target_position=global_position
@onready var timer=$Timer

func _ready():
	update_target_position()

func set_start_position(current_position):
	start_position=current_position

func update_target_position():
	var target_vector=Vector2(randi_range(-wander_range,wander_range),randi_range(-wander_range,wander_range))
	target_position=start_position+target_vector

func get_time_left():
	return timer.time_left
	
func start_wander_timer(duration):
	timer.start(duration)

func _on_timer_timeout():
	update_target_position()
