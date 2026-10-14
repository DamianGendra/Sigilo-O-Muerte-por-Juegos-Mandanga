extends CanvasLayer

@onready var control: Control = $Control
@onready var titulo_estado: Label = $Control/VBoxContainer/TituloEstado
@onready var btn_reiniciar: Button = $Control/VBoxContainer/BtnReiniciar # Ajusta la ruta

var _es_victoria := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_to_group("ui_fin_juego")
	control.hide()


func mostrar_pantalla(es_victoria: bool) -> void:
	_es_victoria = es_victoria
	control.show()
	
	if es_victoria:
		titulo_estado.text = "VICTORIA"
		titulo_estado.modulate = Color.GREEN
		btn_reiniciar.text = "Volver al inicio"
	else:
		titulo_estado.text = "DERROTA"
		titulo_estado.modulate = Color.RED
		btn_reiniciar.text = "Reintentar"
	
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_btn_reiniciar_pressed() -> void:
	get_tree().paused = false
	if _es_victoria:
		get_tree().change_scene_to_file("res://Scenes/Level 1/1-1/Level1.tscn")
	else:
		get_tree().reload_current_scene()


func _on_btn_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")


func _on_btn_menu_principal_pressed() -> void:
	_on_btn_menu_pressed()
