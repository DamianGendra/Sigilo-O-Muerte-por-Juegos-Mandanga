extends Node2D

func _ready():
	$Player.global_position = $SpawnPoint.global_position
