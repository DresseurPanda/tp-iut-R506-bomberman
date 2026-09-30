extends CharacterBody3D
const T_MAX=2
const T_MIN=0.5 #valeur min d'un déplacement d'un ennemi
var compteur=0
const SPEED = 3.0
@onready var directionRandom = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]

func _ready() -> void:
	placementRandom()
		
func placementRandom() -> void:
	var position_x
	var position_z
	position_x= randf_range(-7,7)
	position_z= randf_range(-8,8)
	while (position_x >-1 and position_x < 1 and position_z >-1 and position_z < 1):
		position_x= randf_range(-7,7)
	global_position=Vector3(position_x,0,position_z)

func _physics_process(delta: float) -> void:
	compteur-=delta
	if get_slide_collision_count() > 0:
		compteur=0
	if compteur<=0:
		position+=Vector3.ZERO
		var direction
		direction= directionRandom[randi()%4]
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		compteur = randf_range(T_MIN, T_MAX)
	move_and_slide()
