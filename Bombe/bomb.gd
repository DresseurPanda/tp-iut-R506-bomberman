extends Area3D

## Taille d'une case de la grille (doit correspondre au pas utilise par le joueur).
const CELL_SIZE := 1.0

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
	# TODO (US08/US09) : verifier ici si un mur indestructible bloque la case
	# (retourner true sans effet), ou si un mur destructible doit etre detruit
	# (le detruire puis retourner true).
	print("Explosion sur la case : ", cell_pos)
	return false
