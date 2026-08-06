extends Area2D

@onready var label_4: Label = $"../Label4"

func _on_body_entered(body: Node2D) -> void:
	if body.get_groups()[0] == "Player":
		label_4.visible = true
