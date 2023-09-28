extends Panel


const DURATION_SCALE := 0.25
const DURATION_VISIBLE := 2.0
const DURATION_FADE_OUT := 2.0

@onready var label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	scale = Vector2.ZERO


func setup(username: String, color := Color.WHITE, disconnected := false) -> void:
	label.text = (
		"野生的[color=#%s]%s[/color] %s"
		% [color.to_html(false), username, "游走了" if disconnected else "出现了"]
	)
	var tween:Tween = get_tree().create_tween()
	tween.tween_property(self,"scale",Vector2.ONE,DURATION_SCALE)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_OUT)
	tween.play()

	tween.tween_property(self,"modulate",Color.TRANSPARENT,DURATION_FADE_OUT).set_delay(DURATION_SCALE+DURATION_VISIBLE)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.play()
	
	tween.tween_callback(self.queue_free)
