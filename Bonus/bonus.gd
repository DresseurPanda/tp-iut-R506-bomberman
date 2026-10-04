class_name Bonus
extends Area3D

enum Type { BOMBE, PORTEE }

## Couleur du mesh pour chaque type de bonus.
const COLORS := {
	Type.BOMBE: Color(0.2, 0.5, 1.0),
	Type.PORTEE: Color(1.0, 0.5, 0.1),
}

@export var type: Type = Type.BOMBE

## Vitesse de rotation du bonus (radians par seconde).
@export var rotation_speed := 2.0

@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = COLORS[type]
	material.emission_enabled = true
	material.emission = COLORS[type]
	mesh.material_override = material
	body_entered.connect(_on_body_entered)


## Choisit un type de bonus au hasard (appele par la bombe, qui ne connait pas la classe Bonus).
func randomize_type() -> void:
	type = Type.values().pick_random()


func _process(delta: float) -> void:
	rotate_y(rotation_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("personnage"):
		return
	match type:
		Type.BOMBE:
			body.max_bombs += 1
		Type.PORTEE:
			Bomb.range_multiplier += 1.0
	queue_free()

