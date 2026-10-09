extends CharacterBody2D

@export var speed: float = 300.0
@export var max_health: int = 100
@export var bullet_scene: PackedScene
@export var bullet_damage: int = 10
@export var muzzle_offset: float = 20.0

@onready var health_bar: ProgressBar = $ProgressBar

var current_health: int

func _ready() -> void:
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("Left", "Right", "Up", "Down")
	velocity = direction * speed
	move_and_slide()
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("Shoot"):
		shoot()

func shoot() -> void:
	if bullet_scene == null:
		push_warning("No bullet on the player is assigned")
		return

	var bullet := bullet_scene.instantiate() as Bullet
	if bullet == null:
		push_warning("The player bullet dont use the script")
		return

	get_tree().current_scene.add_child(bullet)

	var muzzle_pos := global_position + Vector2(muzzle_offset, 0).rotated(rotation)
	var shoot_direction := Vector2.RIGHT.rotated(rotation)
	bullet.launch(muzzle_pos, shoot_direction, bullet_damage, self)

func take_damage(amount: int) -> void:
	current_health -= amount
	if health_bar:
		health_bar.value = current_health
	if current_health <= 0:
		die()

func die() -> void:
	var pantalla := get_tree().get_first_node_in_group("ui_fin_juego")
	if pantalla:
		pantalla.mostrar_pantalla(false)
	queue_free()
