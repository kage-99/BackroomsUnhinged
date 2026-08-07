extends Area2D

var found = false

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _process(delta: float) -> void:
	if found:
		$"../HowlerScare".rotate(-0.05)
		$"../HowlerScare".position = Vector2($"../HowlerScare".position.x - 10 ,$"../HowlerScare".position.y)

func _on_body_entered(body: Node2D) -> void:
	if len(body.get_groups()) > 0 and body.get_groups()[0] == "Player":
		found = true
		await wait(0.1)
		found = false
		#$"../HowlerScare".visible = false
