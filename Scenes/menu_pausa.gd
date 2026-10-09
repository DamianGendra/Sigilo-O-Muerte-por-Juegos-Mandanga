extends CanvasLayer

@onready var control: Control = $Control
@onready var btn_continuar: Button = $Control/VBoxContainer/BtnContinuar
@onready var btn_configuraciones: Button = $Control/VBoxContainer/BtnConfiguraciones
@onready var btn_salir: Button = $Control/VBoxContainer/BtnSalir

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	control.hide()

	btn_continuar.pressed.connect(_on_btn_continuar_pressed)
	btn_configuraciones.pressed.connect(_on_btn_configuraciones_pressed)
	btn_salir.pressed.connect(_on_btn_salir_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if control.visible:
			reanudar()
		else:
			pausar()
		get_viewport().set_input_as_handled()


func pausar() -> void:
	control.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func reanudar() -> void:
	control.hide()
	get_tree().paused = false


func _on_btn_continuar_pressed() -> void:
	reanudar()


func _on_btn_configuraciones_pressed() -> void:
	print("No tuvimos tiempo para implementarlas")


func _on_btn_salir_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
