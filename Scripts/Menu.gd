extends Control

func _ready() -> void:
	pass

func _on_boton_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Level 1/1-1/Level1.tscn")

func _on_boton_opciones_pressed() -> void:
	pass

func _on_boton_salir_pressed() -> void:
	get_tree().quit()
