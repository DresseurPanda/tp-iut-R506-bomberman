extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const BOMB_SCENE := preload("res://Bombe/bombe.tscn")
const HUD := preload("res://Bonus/hud.gd")

## Nombre de bombes que ce joueur peut avoir posees en meme temps.
## Un bonus n'a qu'a faire "max_bombs += 1" pour l'augmenter.
@export var max_bombs: int = 1

## Positions (alignees sur la grille) des bombes actuellement posees par ce joueur.
var active_bomb_positions: Array[Vector3] = []

## Position de depart du joueur, definie par le level_generator. Sert au respawn.
var spawn_position := Vector3(0, 0.5, 0)

@onready var health = 3
@onready var ennemis

func _ready() -> void:
	# La portee est statique : on la remet a 1 a chaque nouvelle partie.
	Bomb.range_multiplier = 1.0
	add_child(HUD.new())

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

	if Input.is_action_just_pressed("poser_bombe"):
		poser_bombe()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("ennemi"):
		print("test")
		take_damage() # Replace with function body.

func poser_bombe() -> void:
	# On ne peut pas depasser son nombre de bombes autorise en simultane.
	if active_bomb_positions.size() >= max_bombs:
		return

	var target_pos := global_position.round()

	# On ne peut pas reposer une bombe sur une case deja occupee par une bombe.
	if target_pos in active_bomb_positions:
		return

	var bomb = BOMB_SCENE.instantiate()
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = target_pos

	active_bomb_positions.append(target_pos)
	bomb.tree_exited.connect(func(): active_bomb_positions.erase(target_pos))

func take_damage() -> void:
	health-=1
	print("Une vie en moins :(")
	if health == 0:
		mort()
		return
	global_position = spawn_position

func mort() -> void:
	# Differe : la bombe qui nous a tue est encore en train d'exploser.
	get_tree().change_scene_to_file.call_deferred("res://GameOver/game_over.tscn")
	print("Tu es mort :(")
