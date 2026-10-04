extends Node3D

const CELL_SIZE := 1
const WIDTH := 17
const HEIGHT := 17
const PLAYER_SPAWN := Vector2i(1, 1)
const PLAYER2_SPAWN := Vector2i( HEIGHT - 2, HEIGHT - 2)
const SAFE_RADIUS := 5
## Distance minimale (en cases) entre deux ennemis au depart.
const ENEMY_MIN_DISTANCE := 4

# Decalage de chaque modele pour que sa base soit sur le sol et sa collision centree sur la case.
const PILLAR_OFFSET := Vector3(0, 0.026, -0.178)
const BRICK_OFFSET := Vector3(0, 0.45, 0)

@export var pillar_scene: PackedScene
@export var brick_scene: PackedScene
@export var enemy_scene: PackedScene
@export var brick_chance := 0.55
@export var enemy_count := 1

var grid := []

func generate_grid() -> void:
	grid.clear()
	for y in range(HEIGHT):
		var row := []
		for x in range(WIDTH):
			var in_corner := (x == 0 and y == 0) \
				or (x == WIDTH - 1 and y == 0) \
				or (x == 0 and y == HEIGHT - 1) \
				or (x == WIDTH - 1 and y == HEIGHT - 1)

			var on_border := (x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1)

			if in_corner:
				row.append(0)  # coin toujours vide
			elif on_border:
				row.append(2 if randf() < brick_chance else 0)  # 1 ligne de marge : brique ou vide, jamais pilier
			elif x % 2 == 0 and y % 2 == 0:
				row.append(3)  # pilier en damier
			else:
				row.append(2 if randf() < brick_chance else 0)
		grid.append(row)

	# Zone de depart des joueurs toujours libre (la case et ses voisines).
	for cell in [PLAYER_SPAWN, PLAYER_SPAWN + Vector2i.RIGHT, PLAYER_SPAWN + Vector2i.DOWN]:
		grid[cell.y][cell.x] = 0
	for cell in [PLAYER2_SPAWN, PLAYER2_SPAWN + Vector2i.RIGHT, PLAYER2_SPAWN + Vector2i.UP]:
		grid[cell.y][cell.x] = 0

func get_walkable_cells_far_from_player() -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for y in range(HEIGHT):
		for x in range(WIDTH):
			if grid[y][x] != 0:
				continue
			var dist1 = Vector2i(x, y).distance_to(PLAYER_SPAWN)
			var dist2 = Vector2i(x, y).distance_to(PLAYER2_SPAWN)
			if dist1 >= SAFE_RADIUS and dist2 >= SAFE_RADIUS:
				candidates.append(Vector2i(x, y))
	return candidates

## Place les ennemis sur des cases vides, loin du joueur et loin les uns des autres.
func spawn_enemies() -> void:
	if not enemy_scene:
		return
	var candidates = get_walkable_cells_far_from_player()
	candidates.shuffle()

	var chosen: Array[Vector2i] = []
	for cell in candidates:
		if chosen.size() >= enemy_count:
			break
		# On saute la case si un ennemi deja choisi est trop proche.
		var too_close := chosen.any(func(other): return Vector2(cell).distance_to(Vector2(other)) < ENEMY_MIN_DISTANCE)
		if not too_close:
			chosen.append(cell)

	for cell in chosen:
		var enemy = enemy_scene.instantiate()
		enemy.position = get_cell_center(cell)
		add_child(enemy)

## Retourne la position 3D (locale au generateur) du centre d'une case de la grille.
## La grille est centree sur le generateur : la case (0, 0) est en haut a gauche.
## Le "+ 0.5" place le point au milieu de la case et non sur son coin.
func get_cell_center(cell: Vector2i) -> Vector3:
	var x := (cell.x + 0.5 - WIDTH / 2.0) * CELL_SIZE
	var z := (cell.y + 0.5 - HEIGHT / 2.0) * CELL_SIZE
	return Vector3(x, 0, z)

## Deplace chaque joueur au centre de sa case de depart. Le joueur 1 spawn en haut
## a gauche (PLAYER_SPAWN), le joueur 2 en bas a gauche (PLAYER2_SPAWN).
## Les joueurs sont cherches dans la scene parente (main.tscn).
func place_player() -> void:
	var spawns := {
		"Personnage": PLAYER_SPAWN,
		"Personnage2": PLAYER2_SPAWN,
	}
	for nom_joueur in spawns:
		var player = get_parent().get_node_or_null(nom_joueur)
		if player:
			var spawn_pos := to_global(get_cell_center(spawns[nom_joueur]))
			player.global_position = Vector3(spawn_pos.x, player.global_position.y, spawn_pos.z)
			player.spawn_position = player.global_position

func build_level() -> void:
	generate_grid()
	var offset_x = -(WIDTH * CELL_SIZE) / 2.0 + CELL_SIZE / 2.0
	var offset_z = -(HEIGHT * CELL_SIZE) / 2.0 + CELL_SIZE / 2.0

	for y in range(HEIGHT):
		for x in range(WIDTH):
			var cell = grid[y][x]
			var world_pos = Vector3(x * CELL_SIZE + offset_x, 0, y * CELL_SIZE + offset_z)

			if cell == 3 and pillar_scene:
				var pillar = pillar_scene.instantiate()
				pillar.position = world_pos + Vector3(0, CELL_SIZE / 2.0, 0) + PILLAR_OFFSET
				add_child(pillar)
			elif cell == 2 and brick_scene:
				var brick = brick_scene.instantiate()
				brick.position = world_pos + Vector3(0, CELL_SIZE / 2.0, 0) + BRICK_OFFSET
				add_child(brick)

	place_player()
	spawn_enemies()

func _ready() -> void:
	build_level()
