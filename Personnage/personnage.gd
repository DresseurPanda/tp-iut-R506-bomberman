extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const BOMB_SCENE := preload("res://Bombe/bombe.tscn")

@onready var health = 3
@onready var ennemis

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("ennemi"):
		print("test")
		take_damage() # Replace with function body.


func take_damage() -> void:
	health-=1
	print("Une vie en moins :(")
	if health == 0:
		mort()
		return
	global_position= Vector3(0,0.5,0)

func mort() -> void:
	# Differe : la bombe qui nous a tue est encore en train d'exploser.
	get_tree().change_scene_to_file.call_deferred("res://GameOver/game_over.tscn")
	print("Tu es mort :(")
	
