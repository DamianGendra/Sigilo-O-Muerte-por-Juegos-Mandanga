extends CharacterBody2D

signal died

@export var speed: float = 300.0
@export var jump_velocity: float = -450.0
@export var acceleration: float = 1500.0
@export var friction: float = 2000.0
@export var max_health: int = 100
@export var restart_delay: float = 1.5
@export var Pantalla_fin_juego: CanvasLayer

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var current_health: int
var facing: float = 1.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _dead := false

func _ready() -> void:
	add_to_group("player")
	current_health = max_health

func _update_animation(direction: float) -> void:
	if direction != 0 and is_on_floor():
		if not anim.is_playing():
			anim.play("Player Lv1")
	else:
		anim.stop()
		anim.frame = 0

func _physics_process(delta: float) -> void:
	if _dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_velocity

	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y *= 0.5

	var direction := Input.get_axis("Left", "Right")

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		facing = sign(direction)
		anim.flip_h = facing < 0
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()
	_update_animation(direction)

func take_damage(amount: int) -> void:
	if _dead:
		return
	current_health = max(0, current_health - amount)
	if current_health <= 0:
		die()

func die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector2.ZERO
	died.emit()
	if $AnimatedSprite2D:
		$AnimatedSprite2D.modulate = Color(1, 0.3, 0.3, 0.6)
	await get_tree().create_timer(restart_delay).timeout
	get_tree().call_group("ui_fin_juego", "mostrar_pantalla", false)
