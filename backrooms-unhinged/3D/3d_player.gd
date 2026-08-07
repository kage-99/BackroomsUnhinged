extends CharacterBody3D

# --- Einstellungen ---
@export_group("Movement Speeds")
@export var WALK_SPEED: float = 5.0
@export var SPRINT_SPEED: float = 8.0
@export var CROUCH_SPEED: float = 2.5
@export var JUMP_VELOCITY: float = 4
@export var ACCELERATION: float = 10.0
@export var FRICTION: float = 12.0

@export_group("Crouch Settings")
@export var CROUCH_HEIGHT: float = 0.7 # Höhe des CollisionShapes beim Ducken
@export var STAND_HEIGHT: float = 2.0  # Nomale Höhe des CollisionShapes
@export var CROUCH_SPEED_LERP: float = 10.0

@export_group("Mouse Controls")
@export var MOUSE_SENSITIVITY: float = 0.003

# --- Private Variablen ---
var current_speed: float = WALK_SPEED
var STAMINA = 100
var isSprintLock = false

# --- Node-Referenzen ---
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	$"../CanvasLayer3/Control/StanimaBar".value = STAMINA
	# 1. Schwerkraft
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Crouching & Sprinting Logik
	var is_crouching := Input.is_key_pressed(KEY_CTRL)
	var is_sprinting := Input.is_key_pressed(KEY_SHIFT) and not is_crouching

	if is_crouching:
		current_speed = CROUCH_SPEED
		# Kamera und Kollision absenken
		head.position.y = move_toward(head.position.y, 0.5, CROUCH_SPEED_LERP * delta)
		if collision_shape.shape is CapsuleShape3D:
			collision_shape.shape.height = move_toward(collision_shape.shape.height, CROUCH_HEIGHT, CROUCH_SPEED_LERP * delta)
	else:
		# Wieder aufrichten
		head.position.y = move_toward(head.position.y, 1.0, CROUCH_SPEED_LERP * delta)
		if collision_shape.shape is CapsuleShape3D:
			collision_shape.shape.height = move_toward(collision_shape.shape.height, STAND_HEIGHT, CROUCH_SPEED_LERP * delta)

	# Geschwindigkeits-Wahl
	if isSprintLock:
		var new_stylebox_normal = $"../CanvasLayer3/Control/StanimaBar".get_theme_stylebox("fill").duplicate()
		new_stylebox_normal.bg_color = Color.DIM_GRAY
		new_stylebox_normal.corner_radius_top_left = 0
		new_stylebox_normal.corner_radius_top_right = 0
		new_stylebox_normal.corner_radius_bottom_right = 0
		new_stylebox_normal.corner_radius_bottom_left = 0
		$"../CanvasLayer3/Control/StanimaBar".remove_theme_stylebox_override("fill")
		$"../CanvasLayer3/Control/StanimaBar".add_theme_stylebox_override("fill", new_stylebox_normal)
		#var stylebox:StyleBoxFlat = $"StanimaBar".get_theme_stylebox()
		#stylebox.bg_color = Color.DIM_GRAY
		#$"StanimaBar".set_theme_stylebox_override()
	else:
		var new_stylebox_normal = $"../CanvasLayer3/Control/StanimaBar".get_theme_stylebox("fill").duplicate()
		new_stylebox_normal.bg_color = Color(0.0, 0.74, 0.037, 1.0)
		new_stylebox_normal.corner_radius_top_left = 0
		new_stylebox_normal.corner_radius_top_right = 0
		new_stylebox_normal.corner_radius_bottom_right = 0
		new_stylebox_normal.corner_radius_bottom_left = 0
		$"../CanvasLayer3/Control/StanimaBar".remove_theme_stylebox_override("fill")
		$"../CanvasLayer3/Control/StanimaBar".add_theme_stylebox_override("fill", new_stylebox_normal)
	if STAMINA <= 0:
		isSprintLock = true
	if STAMINA >= 90:
		isSprintLock = false
	
	# Sprint-Taste abfragen (z. B. Shift / "sprint")
	if Input.is_action_pressed("ui_shift") and STAMINA > 0 and not isSprintLock:
		is_sprinting = true
	else:
		is_sprinting = false

	# Bewegungs-Vektor holen
	var vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Sprint-Logik
	if is_sprinting and vector.length() > 0.0:
		current_speed = SPRINT_SPEED
		STAMINA = max(0.0, STAMINA - 0.25)
	
		# Wenn die Ausdauer durch den Verbrauch JETZT 0 erreicht hat -> Sprint sofort beenden
		if STAMINA <= 0.0:
			is_sprinting = false
			current_speed = WALK_SPEED
	else:
		if not is_crouching:
			current_speed = WALK_SPEED
		if STAMINA < 100.0:
			STAMINA = min(100.0, STAMINA + 0.1)
		
	# 3. Sprung (nur möglich wenn am Boden und nicht geduckt)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 4. Input-Richtung berechnen
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 5. Bewegung glätten
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, ACCELERATION * current_speed * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, ACCELERATION * current_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * current_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * current_speed * delta)

	move_and_slide()
