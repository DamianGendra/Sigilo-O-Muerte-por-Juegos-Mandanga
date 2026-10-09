extends Area2D

@export_file("*.tscn") var escena_destino: String
@export var duracion_fundido := 0.5

var _cambiando := false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player" and not _cambiando:
		_cambiando = true
		_transicion()

func _transicion():
	var capa := CanvasLayer.new()
	capa.layer = 100
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	capa.add_child(rect)
	get_tree().root.add_child(capa)

	var tween := capa.create_tween()
	tween.tween_property(rect, "color:a", 1.0, duracion_fundido)
	tween.tween_callback(get_tree().change_scene_to_file.bind(escena_destino))
	tween.tween_interval(0.1)
	tween.tween_property(rect, "color:a", 0.0, duracion_fundido)
	tween.tween_callback(capa.queue_free)
