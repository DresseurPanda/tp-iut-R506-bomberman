extends Area3D

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.start()
	timer.timeout.connect(_on_timeout)

func _on_timeout() -> void:
	print("Boom !")
	queue_free()
