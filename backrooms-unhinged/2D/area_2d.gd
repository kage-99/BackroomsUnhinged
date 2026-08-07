extends Area2D



func _on_body_entered(body: Node2D) -> void:
	if body.get_groups()[0] == "Player":
		$"../Label2".visible = true
