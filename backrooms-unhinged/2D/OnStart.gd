extends Node2D

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _ready() -> void:
	$"../Player/Camera2D/Panel3".visible = true
	await wait(0.5)
	$"../Player/Camera2D/Panel3".visible = false
