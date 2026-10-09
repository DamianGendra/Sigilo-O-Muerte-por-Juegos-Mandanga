extends EnemyBase

signal jugador_atrapado

@export_group("Movement")
@export var patrol_speed := 50.0
@export var chase_speed := 110.0
@export var gravity := 900.0
@export var edge_wait := 1.0
@export var ground_ray_length := 24.0
@export var ground_ray_lookahead := 12.0

@export_group("Vision")
@export var vision_range := 160.0
@export_range(5, 180) var vision_half_angle := 40.0
@export_flags_2d_physics var obstacle_mask := 1
@export var capture_distance := 24.0

@export_group("Combat")
@export var contact_distance := 55.0

var direction := 1
var wait := 0.0
var _turn_done := false
var _captured := false

var _ground_ray := RayCast2D.new()
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_ground_ray.target_position = Vector2(0, ground_ray_length)
	_ground_ray.collision_mask = obstacle_mask
	add_child(_ground_ray)



func _find_player() -> void:
	if not is_instance_valid(player):
		_captured = false
	super()


func _before_state(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	_ground_ray.position.x = ground_ray_lookahead * direction


func _after_move() -> void:
	sprite.flip_h = direction < 0
	_kill_on_contact()


func _kill_on_contact() -> void:
	if not is_instance_valid(player) or not player.has_method("die"):
		return
	if global_position.distance_to(player.global_position) <= contact_distance:
		player.die()


func _on_state_entered(new_state: State, _old_state: State) -> void:
	if new_state == State.SEARCH:
		_turn_done = false


func _can_see_player() -> bool:
	if not is_instance_valid(player):
		return false
	var toward := player.global_position - global_position
	if toward.length() > vision_range:
		return false
	var angle := rad_to_deg(Vector2(direction, 0).angle_to(toward))
	if abs(angle) > vision_half_angle:
		return false
	var query := PhysicsRayQueryParameters2D.create(
			global_position, player.global_position, obstacle_mask)
	var excluded: Array[RID] = [get_rid()]
	if player is CollisionObject2D:
		excluded.append(player.get_rid())
	query.exclude = excluded
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _reached_last_known() -> bool:
	var dx := last_known.x - global_position.x
	return abs(dx) <= 8 or is_on_wall() or _is_at_edge()



func _is_at_edge() -> bool:
	return is_on_floor() and not _ground_ray.is_colliding()


func _state_patrol(delta: float) -> void:
	if wait > 0.0:
		wait -= delta
		velocity.x = 0
		return
	if is_on_wall() or _is_at_edge():
		direction *= -1
		wait = edge_wait
		velocity.x = 0
		return
	velocity.x = direction * patrol_speed


func _state_suspicious(_delta: float) -> void:
	velocity.x = 0
	var dx := last_known.x - global_position.x
	if abs(dx) > 4:
		direction = int(sign(dx))


func _state_chase(sees: bool, _delta: float) -> void:
	var dx := last_known.x - global_position.x
	if sees and global_position.distance_to(player.global_position) <= capture_distance:
		if not _captured:
			_captured = true
			jugador_atrapado.emit()
		velocity.x = 0
		return
	if abs(dx) < 8 or is_on_wall() or _is_at_edge():
		velocity.x = 0
		return
	direction = int(sign(dx))
	velocity.x = direction * chase_speed


func _state_search(_delta: float) -> void:
	if not _reached_last_known():
		direction = int(sign(last_known.x - global_position.x))
		velocity.x = direction * patrol_speed
		return
	velocity.x = 0
	if _search_timer < search_time * 0.5 and not _turn_done:
		direction *= -1
		_turn_done = true
