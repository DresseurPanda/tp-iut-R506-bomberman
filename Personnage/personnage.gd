extends CharacterBody3D
class_name Joueur

signal a_rejoint_partie
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const BOMB_SCENE := preload("res://Bombe/bombe.tscn")

## Partagé entre tous les joueurs : numéro du gagnant (0 = pas de vainqueur net / égalité).
static var gagnant_numero: int = 0

## 1 = joueur 1 (touches habituelles), 2 = joueur 2 (touches p2_*)
@export var numero_joueur: int = 1
## Couleur distinctive appliquée au mesh pour reconnaître le joueur 2
@export var couleur_joueur: Color = Color(1, 1, 1)

@export var max_bombs: int = 1
var active_bomb_positions: Array[Vector3] = []
var spawn_position := Vector3(0, 0.5, 0)

@onready var health = 3
@onready var ennemis

var action_gauche: String
var action_droite: String
var action_haut: String
var action_bas: String
var action_bombe: String

## Joueur 2 uniquement : tant qu'il n'a pas appuyé sur une touche, il n'est pas "dans la partie".
var a_rejoint: bool = true

func _ready() -> void:
	Bomb.range_multiplier = 1.0
	add_to_group("joueurs")
	if numero_joueur == 2:
		action_gauche = "p2_left"
		action_droite = "p2_right"
		action_haut = "p2_up"
		action_bas = "p2_down"
		action_bombe = "p2_bombe"
		a_rejoint = false
		visible = false
		set_physics_process(false)
		for child in find_children("*", "CollisionShape3D"):
			child.disabled = true
	else:
		action_gauche = "ui_left"
		action_droite = "ui_right"
		action_haut = "ui_up"
		action_bas = "ui_down"
		action_bombe = "poser_bombe"

	# Applique la couleur distinctive si un mesh existe
	var mesh := find_children("*", "MeshInstance3D")
	if mesh.size() > 0:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = couleur_joueur
		mesh[0].material_override = mat

func _process(_delta: float) -> void:
	# US23 : le joueur 2 rejoint la partie à la première touche pressée
	if not a_rejoint and numero_joueur == 2:
		if Input.is_action_just_pressed(action_gauche) \
		or Input.is_action_just_pressed(action_droite) \
		or Input.is_action_just_pressed(action_haut) \
		or Input.is_action_just_pressed(action_bas) \
		or Input.is_action_just_pressed(action_bombe):
			rejoindre_partie()

func rejoindre_partie() -> void:
	a_rejoint = true
	visible = true
	set_physics_process(true)
	for child in find_children("*", "CollisionShape3D"):
		child.disabled = false
	global_position = spawn_position
	a_rejoint_partie.emit()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector(action_gauche, action_droite, action_haut, action_bas)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	if Input.is_action_just_pressed(action_bombe):
		poser_bombe()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("ennemi"):
		take_damage()

func poser_bombe() -> void:
	if active_bomb_positions.size() >= max_bombs:
		return
	var target_pos := global_position.round()
	if target_pos in active_bomb_positions:
		return
	var bomb = BOMB_SCENE.instantiate()
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = target_pos
	active_bomb_positions.append(target_pos)
	bomb.tree_exited.connect(func(): active_bomb_positions.erase(target_pos))

func take_damage() -> void:
	print("take_damage() joueur ", numero_joueur, " health avant=", health)
	health -= 1
	if health == 0:
		mort()
		return
	global_position = spawn_position

func mort() -> void:
	print("mort() appelée pour joueur ", numero_joueur)
	var joueurs := get_tree().get_nodes_in_group("joueurs")
	print("joueurs trouvés dans le groupe : ", joueurs.size())
	var joueurs_actifs := joueurs.filter(func(j): return j.a_rejoint)
	print("joueurs actifs : ", joueurs_actifs.size())

	if joueurs_actifs.size() < 2:
		print("-> Mode solo détecté, game over")
		get_tree().change_scene_to_file.call_deferred("res://GameOver/game_over.tscn")
		return

	var vivants := joueurs_actifs.filter(func(j): return j.health > 0)
	print("vivants restants : ", vivants.size())
	if vivants.size() == 1:
		gagnant_numero = vivants[0].numero_joueur
		print("-> Victoire du joueur ", gagnant_numero)
		get_tree().change_scene_to_file.call_deferred("res://Victoire/victoire.tscn")
	elif vivants.size() == 0:
		gagnant_numero = 0
		print("-> Égalité")
		get_tree().change_scene_to_file.call_deferred("res://Victoire/victoire.tscn")
