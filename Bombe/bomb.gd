extends Area3D

## Taille d'une case de la grille (doit correspondre au pas utilise par le joueur).
const CELL_SIZE := 1.0

## Groupes des murs (definis sur les scenes Brick, Pillar et Wall).
const GROUP_DESTRUCTIBLE := "destructible"
const GROUP_INDESTRUCTIBLE := "indestructible"

## Les 4 directions de propagation de l'explosion (croix).
const DIRECTIONS := [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]

## Portee de base de la bombe (en nombre de cases), avant application du multiplicateur.
@export var base_range: int = 1

## Multiplicateur de portee partage par toutes les bombes.
## Les bonus n'auront qu'a faire "Bomb.range_multiplier += 1" pour l'augmenter.
static var range_multiplier: float = 1.0

@onready var timer: Timer = $Timer


func _ready() -> void:
	timer.start()
	timer.timeout.connect(_on_timeout)


func get_effective_range() -> int:
	return int(base_range * range_multiplier)


func _on_timeout() -> void:
	explode()
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

	# Une brique est detruite et arrete aussi l'explosion.
	var brick := _node_in_cell(GROUP_DESTRUCTIBLE, cell_pos)
	if brick:
		brick.remove_from_group(GROUP_DESTRUCTIBLE)
		brick.explode()
		return true

	print("Explosion sur la case : ", cell_pos)
	return false


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
