extends Node3D

const CELL_SIZE := 1
const WIDTH := 17
const HEIGHT := 17
const PLAYER_SPAWN := Vector2i(1, 1)
const SAFE_RADIUS := 5

@export var pillar_scene: PackedScene
@export var brick_scene: PackedScene
@export var enemy_scene: PackedScene
@export var brick_chance := 0.55
@export var enemy_count := 4

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

func get_walkable_cells_far_from_player() -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for y in range(HEIGHT):
		for x in range(WIDTH):
			if grid[y][x] != 0:
				continue
			var dist = Vector2i(x, y).distance_to(PLAYER_SPAWN)
			if dist >= SAFE_RADIUS:
				candidates.append(Vector2i(x, y))
	return candidates

func spawn_enemies() -> void:
	if not enemy_scene:
		return
	var candidates = get_walkable_cells_far_from_player()
	candidates.shuffle()
	var count = min(enemy_count, candidates.size())
	var offset_x = -(WIDTH * CELL_SIZE) / 2.0
	var offset_z = -(HEIGHT * CELL_SIZE) / 2.0
	for i in range(count):
		var cell = candidates[i]
		var enemy = enemy_scene.instantiate()
		enemy.position = Vector3(cell.x * CELL_SIZE + offset_x, 1, cell.y * CELL_SIZE + offset_z)
		add_child(enemy)

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
				pillar.position = world_pos + Vector3(0, CELL_SIZE / 2.0, 0)
				add_child(pillar)
			elif cell == 2 and brick_scene:
				var brick = brick_scene.instantiate()
				brick.position = world_pos + Vector3(0, CELL_SIZE / 2.0, 0)
				add_child(brick)

	spawn_enemies()

func _ready() -> void:
	build_level()
