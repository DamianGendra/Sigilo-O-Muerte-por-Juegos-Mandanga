class_name EnemyBase
extends CharacterBody2D
## Shared state machine for the enemies shoto:
##   PATROL -> SUSPICIOUS -> CHASE -> SEARCH -> PATROL

enum State { PATROL, SUSPICIOUS, CHASE, SEARCH }

signal state_changed(old_state: State, new_state: State)

@export_group("Detection")
@export var suspicion_time := 0.6
@export var lose_track_time := 1.5
@export var search_time := 4.0
@export var player: Node2D
@export var player_groups: Array[StringName] = [&"Player", &"player"]
@export var debug_vision := true

var state := State.PATROL
var last_known := Vector2.ZERO
var awareness := 0.0

var _lost_timer := 0.0
var _search_timer := 0.0


func _physics_process(delta: float) -> void:
	_find_player()
	_before_state(delta)

	var sees := _can_see_player()
	_update_state(sees, delta)

	match state:
		State.PATROL: _state_patrol(delta)
		State.SUSPICIOUS: _state_suspicious(delta)
		State.CHASE: _state_chase(sees, delta)
		State.SEARCH: _state_search(delta)

	move_and_slide()
	_after_move()
	if debug_vision:
		queue_redraw()


func _find_player() -> void:
	if is_instance_valid(player):
		return
	for group in player_groups:
		var node := get_tree().get_first_node_in_group(group)
		if node is Node2D:
			player = node
			return


# States shoto

func _update_state(sees: bool, delta: float) -> void:
	if sees:
		last_known = player.global_position
		awareness += delta
	else:
		awareness = maxf(0.0, awareness - delta * 0.5)

	match state:
		State.PATROL:
			if sees:
				set_state(State.SUSPICIOUS)
		State.SUSPICIOUS:
			if awareness >= suspicion_time:
				set_state(State.CHASE)
			elif awareness <= 0.0:
				set_state(State.PATROL)
		State.CHASE:
			_lost_timer = 0.0 if sees else _lost_timer + delta
			if _lost_timer >= lose_track_time:
				set_state(State.SEARCH)
		State.SEARCH:
			if sees:
				set_state(State.SUSPICIOUS)
			elif _reached_last_known():
				_search_timer -= delta
				if _search_timer <= 0.0:
					set_state(State.PATROL)


func set_state(new_state: State) -> void:
	var old_state := state
	state = new_state
	match new_state:
		State.PATROL:
			awareness = 0.0
		State.CHASE:
			_lost_timer = 0.0
		State.SEARCH:
			_search_timer = search_time
	_on_state_entered(new_state, old_state)
	state_changed.emit(old_state, new_state)


func investigate(pos: Vector2) -> void:
	if state == State.CHASE:
		return
	last_known = pos
	set_state(State.SEARCH)

## If it can see the player shoto
func _can_see_player() -> bool: return false
## If it reaches to last know shoto
func _reached_last_known() -> bool: return true
## Its call before anything shoto
func _before_state(_delta: float) -> void: pass
## After moving
func _after_move() -> void: pass
## States shoto
func _on_state_entered(_new_state: State, _old_state: State) -> void: pass
func _state_patrol(_delta: float) -> void: pass
func _state_suspicious(_delta: float) -> void: pass
func _state_chase(_sees: bool, _delta: float) -> void: pass
func _state_search(_delta: float) -> void: pass
