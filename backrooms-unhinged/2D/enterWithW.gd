extends Area2D

@export var new_pos: Vector2 = Vector2(0,0)
var isEntered = false
var alpha = 0
var isClicked = false
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
func _physics_process(delta: float) -> void:
	if isClicked:
		print("animate")
		alpha += 2
		var new_stylebox_normal = $"../Player/Camera2D/Panel".get_theme_stylebox("panel").duplicate()
		new_stylebox_normal.bg_color = Color.from_rgba8(0,0,0,alpha)
		new_stylebox_normal.corner_radius_top_left = 0
		new_stylebox_normal.corner_radius_top_right = 0
		new_stylebox_normal.corner_radius_bottom_right = 0
		new_stylebox_normal.corner_radius_bottom_left = 0
		$"../Player/Camera2D/Panel".remove_theme_stylebox_override("panel")
		$"../Player/Camera2D/Panel".add_theme_stylebox_override("panel", new_stylebox_normal)
	else:
		var new_stylebox_normal = $"../Player/Camera2D/Panel".get_theme_stylebox("panel").duplicate()
		if new_stylebox_normal.bg_color.a > 0:
			alpha -= 2
			new_stylebox_normal.bg_color = Color.from_rgba8(0,0,0,alpha)
			new_stylebox_normal.corner_radius_top_left = 0
			new_stylebox_normal.corner_radius_top_right = 0
			new_stylebox_normal.corner_radius_bottom_right = 0
			new_stylebox_normal.corner_radius_bottom_left = 0
			$"../Player/Camera2D/Panel".remove_theme_stylebox_override("panel")
			$"../Player/Camera2D/Panel".add_theme_stylebox_override("panel", new_stylebox_normal)
	if Input.is_action_just_pressed("ui_attack"):
		if isEntered:
			isEntered = false
			isClicked = true
			await wait((255/(2*60)))
			await wait(0.5)
			$"../Player".position = new_pos
			await wait(0.5)
			isClicked = false

func _on_body_entered(body: Node2D) -> void:
	if body.get_groups()[0] == "Player":
		print("Enter of skfjsdjhfdsjhfg")
		isEntered = true
		var new_stylebox_normal = $"../Player/Camera2D/Panel".get_theme_stylebox("panel").duplicate()
		new_stylebox_normal.bg_color = Color.hex(0x00000000)
		new_stylebox_normal.corner_radius_top_left = 0
		new_stylebox_normal.corner_radius_top_right = 0
		new_stylebox_normal.corner_radius_bottom_right = 0
		new_stylebox_normal.corner_radius_bottom_left = 0
		$"../Player/Camera2D/Panel".remove_theme_stylebox_override("panel")
		$"../Player/Camera2D/Panel".add_theme_stylebox_override("panel", new_stylebox_normal)
