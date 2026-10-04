extends CanvasLayer

## Affiche en haut a gauche les stats que les bonus font evoluer.
## Doit etre enfant du joueur : il lit ses valeurs directement.

@onready var bombes: Label = $Marge/Infos/Bombes
@onready var portee: Label = $Marge/Infos/Portee


func _process(_delta: float) -> void:
	var player = get_parent()
	bombes.text = "Bombes : %d" % player.max_bombs
	portee.text = "Portée : %d" % Bomb.range_multiplier
