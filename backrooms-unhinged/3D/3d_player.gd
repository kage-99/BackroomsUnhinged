extends CharacterBody3D

# --- Einstellungen ---
@export_group("Movement Speeds")
@export var WALK_SPEED: float = 5.0
@export var SPRINT_SPEED: float = 8.0
@export var CROUCH_SPEED: float = 2.5
@export var JUMP_VELOCITY: float = 6
@export var ACCELERATION: float = 10.0
@export var FRICTION: float = 12.0

@export_group("Crouch Settings")
@export var CROUCH_HEIGHT: float = 1.2 # Höhe des CollisionShapes beim Ducken
@export var STAND_HEIGHT: float = 2.0  # Nomale Höhe des CollisionShapes
@export var CROUCH_SPEED_LERP: float = 10.0

@export_group("Mouse Controls")
@export var MOUSE_SENSITIVITY: float = 0.003

# --- Private Variablen ---
var current_speed: float = WALK_SPEED

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
		if is_sprinting:
			current_speed = SPRINT_SPEED
		else:
			current_speed = WALK_SPEED

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
