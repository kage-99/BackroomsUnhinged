extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"../Player".creepynes = 0
	$"../Player/SanityBar".visible = false

func _physics_process(delta: float) -> void:
	$"../Player".SANITY = 100
