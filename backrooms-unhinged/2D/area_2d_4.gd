extends Area2D

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _on_body_entered(body: Node2D) -> void:
	if body.get_groups()[0] == "Player":
		$"../Label8".visible = true
		await wait(0.75)
		$"../Player/Camera2D/Panel3".visible = true
		await wait(1)
		get_tree().change_scene_to_file("res://2D/Level 0.tscn")
