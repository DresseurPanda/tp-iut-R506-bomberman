extends Node3D

const HUD_SCENE := preload("res://HUD/hud.tscn")

@onready var viewport_p1: SubViewport = $SplitScreenUI/HBoxContainer/SubViewportContainer/SubViewport
@onready var viewport_p2: SubViewport = $SplitScreenUI/HBoxContainer/SubViewportContainer2/SubViewport
@onready var cam_p1: Camera3D = $SplitScreenUI/HBoxContainer/SubViewportContainer/SubViewport/Camera3D
@onready var cam_p2: Camera3D = $SplitScreenUI/HBoxContainer/SubViewportContainer2/SubViewport/Camera3D
@onready var hud_container_p1 := $SplitScreenUI/HBoxContainer/SubViewportContainer
@onready var hud_container_p2 := $SplitScreenUI/HBoxContainer/SubViewportContainer2

func _ready() -> void:
	$SplitScreenUI.visible = false
	viewport_p1.world_3d = get_viewport().world_3d
	viewport_p2.world_3d = get_viewport().world_3d

func _process(_delta: float) -> void:
	if $SplitScreenUI.visible:
		var p1 := $Personnage
		var p2 := $Personnage2
		cam_p1.global_transform = p1.get_node("Camera3D").global_transform
		cam_p2.global_transform = p2.get_node("Camera3D").global_transform

func activer_split_screen() -> void:
	cam_p1.current = true
	cam_p2.current = true
	$SplitScreenUI.visible = true

	var hud1 = HUD_SCENE.instantiate()
	hud1.player = $Personnage
	hud_container_p1.add_child(hud1)

	var hud2 = HUD_SCENE.instantiate()
	hud2.player = $Personnage2
	hud_container_p2.add_child(hud2)
