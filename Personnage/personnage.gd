extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const BOMB_SCENE := preload("res://Bombe/bombe.tscn")
const HUD_SCENE := preload("res://HUD/hud.tscn")

## Nombre de bombes que ce joueur peut avoir posees en meme temps.
## Un bonus n'a qu'a faire "max_bombs += 1" pour l'augmenter.
@export var max_bombs: int = 1

## Bombes actuellement posees par ce joueur (elles peuvent bouger si on les pousse).
var active_bombs: Array[Node3D] = []

## Position de depart du joueur, definie par le level_generator. Sert au respawn.
var spawn_position := Vector3(0, 0.5, 0)

@onready var health = 3
@onready var ennemis
## Vitesse d'une bombe poussee d'un coup de pied (unites par seconde).
const KICK_SPEED := 6.0

func _ready() -> void:
	# La portee est statique : on la remet a 1 a chaque nouvelle partie.
	Bomb.range_multiplier = 1.0
	add_child(HUD_SCENE.instantiate())

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
	_kick_bombs()

	if Input.is_action_just_pressed("poser_bombe"):
		poser_bombe()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("ennemi"):
		print("test")
		take_damage() # Replace with function body.

## Pousse les bombes contre lesquelles le joueur marche (coup de pied).
func _kick_bombs() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var bomb = collision.get_collider().get_parent()
		if bomb is Bomb:
			# La normale pointe vers le joueur : la bombe part dans le sens inverse.
			bomb.kick(-collision.get_normal())

func poser_bombe() -> void:
	# On ne peut pas depasser son nombre de bombes autorise en simultane.
	if active_bombs.size() >= max_bombs:
		return

	var target_pos := global_position.round()

	# On ne peut pas reposer une bombe sur une case deja occupee par une bombe.
	if active_bombs.any(func(b): return b.global_position.round() == target_pos):
		return

	var bomb = BOMB_SCENE.instantiate()
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = target_pos

	active_bombs.append(bomb)
	bomb.tree_exited.connect(func(): active_bombs.erase(bomb))

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
