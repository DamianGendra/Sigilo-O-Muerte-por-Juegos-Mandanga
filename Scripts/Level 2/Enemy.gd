extends EnemyBase

signal died

const ROTATION_SPEED := 6.0

@export_group("Health")
@export var max_health: int = 100
@export var health_bar_offset := Vector2(-16, -30)

@export_group("Movement")
@export var search_speed := 84.0
@export var chase_speed := 110.0
@export var acceleration := 600.0
@export var arrive_distance := 12.0

@export_group("Vision")
@export var vision_range := 260.0
@export_range(5, 180) var vision_half_angle := 50.0
@export var awareness_radius := 48.0

@export_group("Combat")
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 400.0
@export var fire_rate: float = 1.0
@export var muzzle_offset: float = 20.0
@export var bullet_damage: int = 10
@export var preferred_distance := 150.0
@export var distance_tolerance := 30.0
@export_range(0.0, 1.0) var aim_lead := 0.6
@export var aim_tolerance_deg := 8.0

var current_health: int

var _fire_cooldown := 0.0
var _scan_dir := 1.0
var _scan_flipped := false
var _idle_base := 0.0
var _idle_time := 0.0
var _strafe_dir := 1.0
var _strafe_timer := 0.0

@onready var raycast: RayCast2D = $RayCast2D
@onready var health_bar: ProgressBar = get_node_or_null("ProgressBar")

func _ready() -> void:
	current_health = max_health
	_idle_base = rotation
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.top_level = true


func _process(_delta: float) -> void:
	if health_bar:
		health_bar.rotation = 0.0
		health_bar.global_position = global_position + health_bar_offset



func _before_state(delta: float) -> void:
	_fire_cooldown = max(0.0, _fire_cooldown - delta)


func _on_state_entered(new_state: State, _old_state: State) -> void:
	match new_state:
		State.PATROL:
			_idle_base = rotation
			_idle_time = 0.0
		State.SEARCH:
			_scan_flipped = false
			_scan_dir = 1.0 if randf() > 0.5 else -1.0


func _reached_last_known() -> bool:
	return global_position.distance_to(last_known) <= arrive_distance


func _is_player(node: Object) -> bool:
	if node == null or not node is Node:
		return false
	for group in player_groups:
		if node.is_in_group(group):
			return true
	return false


func _can_see_player() -> bool:
	if not is_instance_valid(player):
		return false
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if dist > vision_range:
		return false
	# Field of view
	if dist > awareness_radius:
		var diff: float = abs(angle_difference(rotation, to_player.angle()))
		if diff > deg_to_rad(vision_half_angle):
			return false
	# Line of sight
	raycast.target_position = to_local(player.global_position)
	raycast.force_raycast_update()
	return raycast.is_colliding() and _is_player(raycast.get_collider())


func _state_patrol(delta: float) -> void:
	_stop(delta)
	_idle_time += delta
	rotation = _idle_base + sin(_idle_time * 0.8) * 0.7


func _state_suspicious(delta: float) -> void:
	_stop(delta)
	_face((last_known - global_position).angle(), delta)


func _state_chase(sees: bool, delta: float) -> void:
	if not sees:
		_move_to(last_known, chase_speed, delta)
		_face_velocity(delta)
		return

	var aim_pos := _aim_position()
	var aim_angle := (aim_pos - global_position).angle()
	_face(aim_angle, delta)

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized()
	if dist > preferred_distance + distance_tolerance:
		_move_to(player.global_position, chase_speed, delta)
	elif dist < preferred_distance - distance_tolerance:
		velocity = velocity.move_toward(-dir * chase_speed, acceleration * delta)
	else:
		_strafe_timer -= delta
		if _strafe_timer <= 0.0:
			_strafe_timer = randf_range(1.0, 2.0)
			_strafe_dir = 1.0 if randf() > 0.5 else -1.0
		velocity = velocity.move_toward(dir.orthogonal() * _strafe_dir * chase_speed * 0.6, acceleration * delta)

	# Shoot only if aimed at the target
	var aligned: bool = abs(angle_difference(rotation, aim_angle)) <= deg_to_rad(aim_tolerance_deg)
	if aligned and _fire_cooldown <= 0.0:
		shoot()


func _state_search(delta: float) -> void:
	if not _reached_last_known():
		_move_to(last_known, search_speed, delta)
		_face_velocity(delta)
		return

	_stop(delta)
	rotation += _scan_dir * 1.5 * delta
	if _search_timer < search_time * 0.5 and not _scan_flipped:
		_scan_dir *= -1.0
		_scan_flipped = true


func _move_to(pos: Vector2, speed: float, delta: float) -> void:
	var target := pos
	var dir := (target - global_position).normalized()
	velocity = velocity.move_toward(dir * speed, acceleration * delta)


func _stop(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)


func _face(angle: float, delta: float) -> void:
	rotation = lerp_angle(rotation, angle, ROTATION_SPEED * delta)


func _face_velocity(delta: float) -> void:
	if velocity.length() > 5.0:
		_face(velocity.angle(), delta)


func _aim_position() -> Vector2:
	var target_velocity := Vector2.ZERO
	if player is CharacterBody2D:
		target_velocity = player.velocity
	var travel_time := global_position.distance_to(player.global_position) / bullet_speed
	return player.global_position + target_velocity * travel_time * aim_lead


func shoot() -> void:
	if bullet_scene == null:
		push_warning("No bullet on the enemy is assigned")
		return

	var bullet := bullet_scene.instantiate() as Bullet
	if bullet == null:
		push_warning("The enemy's bullet scene doesn't use the Bullet script")
		return

	get_tree().current_scene.add_child(bullet)

	var muzzle_pos := global_position + Vector2(muzzle_offset, 0).rotated(rotation)
	var shoot_direction := Vector2.RIGHT.rotated(rotation)
	bullet.launch(muzzle_pos, shoot_direction, bullet_damage, self, bullet_speed)

	_fire_cooldown = 1.0 / fire_rate


func take_damage(amount: int, from_position := Vector2.INF) -> void:
	current_health -= amount
	if health_bar:
		health_bar.value = current_health
	if current_health <= 0:
		die()
		return
	if from_position != Vector2.INF:
		investigate(from_position)


func die() -> void:
	died.emit()
	queue_free()
	GameState.player_won = true
	GameState.player_won = false
