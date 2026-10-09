class_name Bullet
extends Area2D

@export var current_speed: float = 300.0
@export var acceleration: float = 800.0
@export var max_speed: float = 1500.0

var damage: int

var direction := Vector2.RIGHT

# Who did the pewh pewh
var shooter: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

# Singleton for bullet configuration
func launch(from: Vector2, dir: Vector2, dmg: int, who: Node, speed: float = -1.0) -> void:
	global_position = from
	direction = dir.normalized()
	global_rotation = direction.angle()
	damage = dmg
	shooter = who
	if speed >= 0.0:
		current_speed = speed

func _physics_process(delta: float) -> void:
	if current_speed < max_speed:
		current_speed += acceleration * delta
		current_speed = min(current_speed, max_speed)

	position += direction * current_speed * delta

func _on_body_entered(body: Node) -> void:

	if body == shooter:
		return
	# Does damage
	if body.has_method("take_damage"):
		body.take_damage(damage)
	# Removes bullet if collides
	queue_free()
