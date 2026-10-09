extends Node2D

var alive_enemies := 0

func _ready() -> void:
	for child in get_children():
		if child.has_signal("died"):
			alive_enemies += 1
			child.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	alive_enemies -= 1
	if alive_enemies <= 0:
		var screen := get_tree().get_first_node_in_group("ui_fin_juego")
		if screen:
			screen.mostrar_pantalla(true)
