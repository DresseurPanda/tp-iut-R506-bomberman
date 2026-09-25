extends StaticBody3D

@export var destruction_time := 0.3

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		explode()

func explode() -> void:
	set_collision_layer(0)
	set_collision_mask(0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ZERO, destruction_time)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", position.y - 0.5, destruction_time)

	tween.chain().tween_callback(queue_free)
