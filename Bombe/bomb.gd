class_name Bomb
extends Area3D

## Taille d'une case de la grille (doit correspondre au pas utilise par le joueur).
const CELL_SIZE := 1.0
@onready var sfx_explosion = get_node("explosion")
## Scene du bonus et chance qu'une brique detruite en laisse un.
const BONUS_SCENE := preload("res://Bonus/bonus.tscn")
const BONUS_DROP_CHANCE := 0.1

## Groupes des murs (definis sur les scenes Brick, Pillar et Wall).
const GROUP_DESTRUCTIBLE := "destructible"
const GROUP_INDESTRUCTIBLE := "indestructible"

## Groupes des personnages touches par l'explosion.
const GROUP_ENNEMI := "ennemi"
const GROUP_JOUEUR := "personnage"

## Effet d'explosion d'une case : flamme + particules (scene editable dans l'editeur).
const EXPLOSION_SCENE := preload("res://Bombe/explosion.tscn")
const KICK_SPEED := 6.0

## Les 4 directions de propagation de l'explosion (croix).
const DIRECTIONS := [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]

## Portee de base de la bombe (en nombre de cases), avant application du multiplicateur.
@export var base_range: int = 1

## Multiplicateur de portee partage par toutes les bombes.
## Les bonus n'auront qu'a faire "Bomb.range_multiplier += 1" pour l'augmenter.
static var range_multiplier: float = 1.0

@onready var timer: Timer = $Timer

## Partie solide de la bombe : elle bloque le joueur et les ennemis une fois activee.
@onready var solid: StaticBody3D = $Solid

## Personnages qui etaient sur la case a la pose : ils peuvent en sortir librement.
var _passing_bodies: Array[CharacterBody3D] = []

## Direction de glissement quand la bombe est poussee (ZERO = elle est immobile).
var _kick_direction := Vector3.ZERO

## Centre de la prochaine case vers laquelle la bombe glisse.
var _kick_target := Vector3.ZERO

## Vrai des que la bombe a explose (evite une 2e explosion pendant que le son se termine).
var _exploded := false


func _ready() -> void:
	timer.start()
	timer.timeout.connect(_on_timeout)
	body_exited.connect(_on_body_exited)
	_activate_solid()


## Fait apparaitre l'effet d'explosion sur une case (il se supprime tout seul).
## Il est ajoute a la scene car la bombe est supprimee juste apres.
func _spawn_explosion_effect(cell_pos: Vector3) -> void:
	var effect: Node3D = EXPLOSION_SCENE.instantiate()
	# top_level + position AVANT add_child : sinon les particules demarrent a l'origine de la carte.
	effect.top_level = true
	effect.position = cell_pos
	get_tree().current_scene.add_child(effect)


## Rend la bombe solide, sauf pour ceux qui se trouvent deja sur sa case :
## ils la traversent jusqu'a ce qu'ils en sortent (sinon ils seraient coinces).
func _activate_solid() -> void:
	# Il faut attendre que la physique ait detecte les corps qui chevauchent la bombe.
	await get_tree().physics_frame
	await get_tree().physics_frame
	for body in get_overlapping_bodies():
		if body is CharacterBody3D and _is_in_cell(body, global_position):
			body.add_collision_exception_with(solid)
			_passing_bodies.append(body)
	solid.collision_layer = 1


## Pousse la bombe d'un coup de pied : elle glisse en ligne droite, case par case,
## puis explose des qu'un obstacle se trouve devant elle.
func kick(direction: Vector3) -> void:
	if _exploded or _kick_direction != Vector3.ZERO:
		return
	var axis := _snap_to_axis(direction)
	# Pas de coup de pied si la case d'a cote est deja bloquee.
	if _is_blocked(axis):
		return
	_kick_direction = axis
	_kick_target = global_position + axis * CELL_SIZE


func _physics_process(delta: float) -> void:
	if _kick_direction == Vector3.ZERO:
		return
	global_position = global_position.move_toward(_kick_target, KICK_SPEED * delta)
	if not global_position.is_equal_approx(_kick_target):
		return
	# Arrivee au centre d'une case : on continue ou on explose si un obstacle est devant.
	if _is_blocked(_kick_direction):
		_on_timeout()
	else:
		_kick_target += _kick_direction * CELL_SIZE


## Ramene une direction quelconque sur l'axe X ou Z le plus proche.
func _snap_to_axis(direction: Vector3) -> Vector3:
	if absf(direction.x) > absf(direction.z):
		return Vector3(signf(direction.x), 0, 0)
	return Vector3(0, 0, signf(direction.z))


## Retourne true si quelque chose de solide se trouve dans la case voisine (rayon vers elle).
func _is_blocked(direction: Vector3) -> bool:
	var from := global_position
	var query := PhysicsRayQueryParameters3D.create(
		from, from + direction * CELL_SIZE * 0.95, 0xFFFFFFFF, [solid.get_rid()])
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _on_body_exited(body: Node3D) -> void:
	if body in _passing_bodies:
		body.remove_collision_exception_with(solid)
		_passing_bodies.erase(body)


func _exit_tree() -> void:
	for body in _passing_bodies:
		if is_instance_valid(body):
			body.remove_collision_exception_with(solid)


func get_effective_range() -> int:
	return int(base_range * range_multiplier)


func _on_timeout() -> void:
	if _exploded:
		return
	_exploded = true
	# Si la bombe glissait, on la recale au centre d'une case avant d'exploser.
	_kick_direction = Vector3.ZERO
	global_position = global_position.round()
	explode()
	visible=false
	get_node("Solid/FormeBlocage").disabled=true
	sfx_explosion.play()
	await $explosion.finished
	queue_free()


func explode() -> void:
	var range_cases := get_effective_range()

	# La case de la bombe elle-meme explose toujours.
	_explode_cell(global_position)

	# Puis on propage dans les 4 directions, case par case, jusqu'a la portee
	# ou jusqu'a rencontrer un obstacle qui bloque l'explosion.
	for direction in DIRECTIONS:
		for i in range(1, range_cases + 1):
			var cell_pos: Vector3 = global_position + direction * CELL_SIZE * i
			var blocked := _explode_cell(cell_pos)
			if blocked:
				break


## Traite l'explosion d'une case donnee.
## Retourne true si l'explosion doit s'arreter dans cette direction (mur rencontre).
func _explode_cell(cell_pos: Vector3) -> bool:
	# Un mur indestructible arrete l'explosion sans etre touche.
	if _node_in_cell(GROUP_INDESTRUCTIBLE, cell_pos):
		return true
	
	_spawn_explosion_effect(cell_pos)
	

	# Une brique est detruite et arrete aussi l'explosion.
	var brick := _node_in_cell(GROUP_DESTRUCTIBLE, cell_pos)
	if brick:
		brick.remove_from_group(GROUP_DESTRUCTIBLE)
		brick.explode()
		_maybe_drop_bonus(brick.global_position)
		return true

	for ennemi in get_tree().get_nodes_in_group(GROUP_ENNEMI):
		if _is_in_cell(ennemi, cell_pos):
			ennemi.mourir()

	for joueur in get_tree().get_nodes_in_group(GROUP_JOUEUR):
		# Le groupe contient aussi les enfants du personnage : on ne garde que le parent.
		if joueur is CharacterBody3D and _is_in_cell(joueur, cell_pos):
			joueur.take_damage()

	print("Explosion sur la case : ", cell_pos)
	return false
	


## Fait apparaitre un bonus aleatoire a la place de la brique detruite.
func _maybe_drop_bonus(pos: Vector3) -> void:
	if randf() >= BONUS_DROP_CHANCE:
		return
	# Pas de type "Bonus" ici : bonus.gd utilise deja Bomb, ca ferait une dependance circulaire.
	var bonus = BONUS_SCENE.instantiate()
	bonus.randomize_type()
	get_tree().current_scene.add_child(bonus)
	# Le bonus est pose juste au-dessus du sol (sol a y = 0.5).
	bonus.global_position = Vector3(pos.x, 0.8, pos.z)


## Retourne le premier noeud du groupe qui se trouve dans la case, ou null.
func _node_in_cell(group: String, cell_pos: Vector3) -> Node3D:
	for node in get_tree().get_nodes_in_group(group):
		if _is_in_cell(node, cell_pos):
			return node
	return null


## Retourne true si le noeud se trouve dans la case centree sur cell_pos.
func _is_in_cell(node: Node3D, cell_pos: Vector3) -> bool:
	var half := CELL_SIZE / 2.0
	return abs(node.global_position.x - cell_pos.x) <= half \
		and abs(node.global_position.z - cell_pos.z) <= half
