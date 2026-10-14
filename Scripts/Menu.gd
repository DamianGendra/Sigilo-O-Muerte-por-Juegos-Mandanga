extends Control

func _ready() -> void:
	pass

func _on_boton_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Level 1/1-1/Level1.tscn")

func _on_boton_opciones_pressed() -> void:
	pass

func _on_boton_salir_pressed() -> void:
	get_tree().quit()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	if GameState.player_won:
		get_tree().change_scene_to_file("res://nivel_1.tscn")
	else:
		get_tree().change_scene_to_file("res://nivel_2.tscn")
