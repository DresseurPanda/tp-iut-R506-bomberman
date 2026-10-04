extends Control

## Affiche en haut a gauche la vie et les stats que les bonus font evoluer.

@onready var vies: Label = $Marge/Infos/Vies
@onready var bombes: Label = $Marge/Infos/Bombes
@onready var portee: Label = $Marge/Infos/Portee

var player: Node = null

func _process(_delta: float) -> void:
	if player == null:
		return
	vies.text = "Vies : %d" % player.health
	bombes.text = "Bombes : %d" % player.max_bombs
	portee.text = "Portée : %d" % Bomb.range_multiplier
