extends Control

@onready var label_resultat: Label = $CenterContainer/VBoxContainer/Label

func _ready() -> void:
	match Joueur.gagnant_numero:
		1:
			label_resultat.text = "Joueur 1 a gagné !"
		2:
			label_resultat.text = "Joueur 2 a gagné !"
		_:
			label_resultat.text = "Égalité !"

func _on_rejouer_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_quitter_pressed() -> void:
	get_tree().quit()
