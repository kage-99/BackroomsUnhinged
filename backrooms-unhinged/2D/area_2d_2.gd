extends Area2D

var entered = false

func _on_body_entered(body: Node2D) -> void:
	if len(body.get_groups()) > 0 and body.get_groups()[0] == "Player" and not entered:
		$"../Disable Sprint".queue_free()
		entered = true
