extends CharacterBody3D
const T_MAX=2
const T_MIN=0.5 #valeur min d'un déplacement d'un ennemi
var compteur=0
const SPEED = 3.0
const SCENE_VICTOIRE := "res://VictoireSolo/victoire_solo.tscn"
@onready var directionRandom = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]

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

func mourir() -> void:
	remove_from_group("ennemi")
	var dernier := get_tree().get_nodes_in_group("ennemi").is_empty()
	set_physics_process(false)
	$CollisionShape3D.set_deferred("disabled", true)
	rotation = Vector3(deg_to_rad(-90), 0, 0)
	$son_mort.play()
	await $son_mort.finished
	
	#test victoire
	if dernier:
		get_tree().change_scene_to_file(SCENE_VICTOIRE)
	else:
		queue_free()
