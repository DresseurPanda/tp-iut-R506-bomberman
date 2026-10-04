extends CanvasLayer

## Affiche en haut a gauche les stats que les bonus font evoluer.
## Doit etre enfant du joueur : il lit ses valeurs directement.

var label := Label.new()


func _ready() -> void:
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.position = Vector2(20, 20)
	add_child(label)


func _process(_delta: float) -> void:
	var player = get_parent()
	label.text = "Bombes : %d\nPortée : %d" % [player.max_bombs, Bomb.range_multiplier]
