extends CanvasLayer

@onready var label: Label = $Label

var temps := 0.0
var a_rejoint := false

func _ready() -> void:
	await get_tree().process_frame
	var joueur2 = get_tree().current_scene.get_node_or_null("Personnage2")
	if joueur2:
		joueur2.a_rejoint_partie.connect(_on_joueur2_rejoint)
	label.text = "Joueur 2 : appuie sur une touche pour rejoindre"

func _process(delta: float) -> void:
	if a_rejoint:
		return
	temps += delta
	label.modulate.a = (sin(temps * 4.0) + 1.0) / 2.0

func _on_joueur2_rejoint() -> void:
	a_rejoint = true
	label.text = "Joueur 2 a rejoint !"
	label.modulate.a = 1.0
	get_parent().activer_split_screen()
	await get_tree().create_timer(1.5).timeout
	label.visible = false
