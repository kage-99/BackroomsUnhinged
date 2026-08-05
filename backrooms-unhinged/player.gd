extends CharacterBody2D

var SPEED = 300.0
var HEALTH = 100
const JUMP_VELOCITY = -400.0
@onready var Animator = $AnimatedSprite2D
var is_alive = true
var STAMINA = 100
var SANITY = 100
var inHurtAnim = false
var attack_timeout = 2
var canAttack = true
var isSprintLock = false
var creepynes = 0.5
var inInsane = false
var is_hurt = false
var isunderminus3 = false
var inInsaneOnce = false
@onready var health_bar: ProgressBar = $HealthBar
@onready var stanima_bar: ProgressBar = $StanimaBar
@onready var sanity_bar: ProgressBar = $SanityBar
var crepyner: Sprite2D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K: # Drücke Taste 'K' zum Sterben
			add_damage(5)

func _ready() -> void:
	Animator.play("Idel")
	health_bar.value = HEALTH
	stanima_bar.value = STAMINA
	sanity_bar.value = SANITY
	#crepyner = $"../crepyner"
	$Insane.visible = false
	
func add_damage(amount: int) -> void:
	HEALTH -= amount
	velocity.y = -300
	move_and_slide()
	await wait(0.05)
	velocity.x = -1*1500
	move_and_slide()
	if HEALTH <= 0:
		return
	inHurtAnim = true
	Animator.pause()
	Animator.play("Hurt")
	await wait(0.4)
	Animator.pause()
	inHurtAnim = false
	
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	
func _physics_process(delta: float) -> void:
	health_bar.value = HEALTH
	stanima_bar.value = STAMINA
	sanity_bar.value = SANITY
	
	SANITY -= creepynes*0.01
		
	if SANITY <= 0:
		# VFX
		$"../CanvasLayer2/MeshInstance2D2".material.set_shader_parameter("aberration_x", $"../CanvasLayer2/MeshInstance2D2".material.get_shader_parameter("aberration_x")-0.1)
		$"../CanvasLayer2/MeshInstance2D2".material.set_shader_parameter("aberration_y", $"../CanvasLayer2/MeshInstance2D2".material.get_shader_parameter("aberration_x")-0.1)
		# Health Loos
		HEALTH -= 0.35
	
	var spawn_points = get_tree().get_nodes_in_group("Crepyner")
	# assume the first spawn node is closest
	var nearest_spawn_point = spawn_points[0]

	# look through spawn nodes to see if any are closer
	for spawn_point in spawn_points:
		if spawn_point.global_position.distance_to(global_position) < nearest_spawn_point.global_position.distance_to(global_position):
			nearest_spawn_point = spawn_point
	
	var distanceToNextCrepyner = position.distance_to(nearest_spawn_point.position)
	
	
	if distanceToNextCrepyner <= 300:
		creepynes = 50
	else:
		creepynes = 0.5
	
	if HEALTH <= 0 and is_alive:
		die()
		return

	if not is_alive:
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and is_alive:
		velocity.y = JUMP_VELOCITY
	
	if isSprintLock:
		var new_stylebox_normal = $StanimaBar.get_theme_stylebox("fill").duplicate()
		new_stylebox_normal.bg_color = Color.DIM_GRAY
		new_stylebox_normal.corner_radius_top_left = 0
		new_stylebox_normal.corner_radius_top_right = 0
		new_stylebox_normal.corner_radius_bottom_right = 0
		new_stylebox_normal.corner_radius_bottom_left = 0
		$StanimaBar.remove_theme_stylebox_override("fill")
		$StanimaBar.add_theme_stylebox_override("fill", new_stylebox_normal)
		#var stylebox:StyleBoxFlat = $"StanimaBar".get_theme_stylebox()
		#stylebox.bg_color = Color.DIM_GRAY
		#$"StanimaBar".set_theme_stylebox_override()
	else:
		var new_stylebox_normal = $StanimaBar.get_theme_stylebox("fill").duplicate()
		new_stylebox_normal.bg_color = Color(0.0, 0.74, 0.037, 1.0)
		new_stylebox_normal.corner_radius_top_left = 0
		new_stylebox_normal.corner_radius_top_right = 0
		new_stylebox_normal.corner_radius_bottom_right = 0
		new_stylebox_normal.corner_radius_bottom_left = 0
		$StanimaBar.remove_theme_stylebox_override("fill")
		$StanimaBar.add_theme_stylebox_override("fill", new_stylebox_normal)
	if STAMINA <= 0:
		isSprintLock = true
	if STAMINA >= 90:
		isSprintLock = false
	
	if Input.is_action_pressed("ui_shift") and STAMINA > 0 and not isSprintLock:
		SPEED = 500.0
		if Input.get_axis("ui_left", "ui_right") != 0:
			STAMINA -= 0.25
		else:
			if STAMINA < 100:
				STAMINA+=0.1
	else:
		SPEED = 300.0
		if STAMINA < 100:
			STAMINA+=0.1
	
	if Input.is_action_just_pressed("ui_attack") and canAttack:
		canAttack = false
		inHurtAnim = true
		is_hurt = true
		Animator.pause()
		Animator.play("Attack")
		await wait(1.2)
		Animator.pause()
		is_hurt = false
		inHurtAnim = false
		await wait(attack_timeout-1.2)
		canAttack = true
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction and is_alive and not is_hurt:
		if direction > 0:
			$"AnimatedSprite2D".scale = Vector2(1.563, 1.563)
			$"AnimatedSprite2D".position = Vector2(13, -4)
		if direction < 0:
			$"AnimatedSprite2D".scale = Vector2(-1.563, 1.563)
			$"AnimatedSprite2D".position = Vector2(-13, -4)
		if not inHurtAnim:
			Animator.pause()
		if Input.is_action_pressed("ui_shift"):
			if not inHurtAnim:
				Animator.play("Walk", 2.0)
		else:
			if not inHurtAnim:
				Animator.play("Walk")
		velocity.x = direction * SPEED
	else:
		if not inHurtAnim:
			Animator.pause()
			Animator.play("Idel")
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	
	if inInsane:
		#print($"../CanvasLayer2/MeshInstance2D2".material.get_shader_parameter("aberration_x"))
		if $"../CanvasLayer2/MeshInstance2D2".material.get_shader_parameter("aberration_x") > -5 and not isunderminus3 and  $"../CanvasLayer2/MeshInstance2D2".material.get_shader_parameter("aberration_y") > -5:
			$"../CanvasLayer2/MeshInstance2D2".material.set_shader_parameter("aberration_x", $"../CanvasLayer2/MeshInstance2D2".material.get_shader_parameter("aberration_x")-0.15)
			$"../CanvasLayer2/MeshInstance2D2".material.set_shader_parameter("aberration_y", $"../CanvasLayer2/MeshInstance2D2".material.get_shader_parameter("aberration_y")-0.15)
		else:
			isunderminus3 = true
		if isunderminus3 and $"../CanvasLayer2/MeshInstance2D2".material.get_shader_parameter("aberration_x") < 0 and $"../CanvasLayer2/MeshInstance2D2".material.get_shader_parameter("aberration_y") < 0:
			await wait(3)
			$"../CanvasLayer2/MeshInstance2D2".material.set_shader_parameter("aberration_x", $"../CanvasLayer2/MeshInstance2D2".material.get_shader_parameter("aberration_x")+0.15)
			$"../CanvasLayer2/MeshInstance2D2".material.set_shader_parameter("aberration_y", $"../CanvasLayer2/MeshInstance2D2".material.get_shader_parameter("aberration_y")+0.15)
		else:
			isunderminus3 = false
	
func _process(delta: float) -> void:
	if SANITY <= 10 and not inInsaneOnce:
		inInsane = true
		$Insane.visible = true
		$Insane.play("default")
		await wait(3.5/$Insane.speed_scale)
		$Insane.visible = false
		$Insane.pause()
		inInsane = false
		$"../CanvasLayer2/MeshInstance2D2".material.set_shader_parameter("aberration_x",0)
		$"../CanvasLayer2/MeshInstance2D2".material.set_shader_parameter("aberration_y",0)
		inInsaneOnce = true
func die() -> void:
	is_alive = false
	set_physics_process(false) # Stoppt _physics_process sofort
	
	velocity = Vector2.ZERO
	Animator.play("Death")
	
	await wait(0.9)
	
	# Prüfen, ob der Node noch im Tree ist, bevor die Szene gewechselt wird
	if is_inside_tree():
		get_tree().change_scene_to_file("res://Game Over.tscn")
