extends ColorRect

const MAIN_SCENE := "res://main.tscn"


func _on_un_joueur_pressed() -> void:
	Joueur.deux_joueurs = false
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_deux_joueurs_pressed() -> void:
	Joueur.deux_joueurs = true
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_quitter_pressed() -> void:
	get_tree().quit()
