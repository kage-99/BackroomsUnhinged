extends Area2D

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _on_body_entered(body: Node2D) -> void:
	if len(body.get_groups()) > 0 and body.get_groups()[0] == "Player":
		$"../Player/Camera2D/Panel4".visible = true
		await wait(1)
		get_tree().change_scene_to_file("res://3D/3D Main.tscn")
