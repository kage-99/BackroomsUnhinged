extends CharacterBody3D

enum Stage {
	IDLE,           # Streunt umher / Patrouilliert
	AMBUSH_WAIT,    # Bleibt still stehen und lauscht (Täuschung)
	INVESTIGATE,    # Untersucht Geräusche oder Spuren
	CORNER_CHECK,   # Späht gezielt um Ecken/Gänge
	STALKING,       # Schleicht vorsichtig nach (Fernsicht)
	CHASING,        # Vollgas-Verfolgung
	SPRINTING       # Tödlicher Endspurt
}

@export_group("Base Movement")
@export var base_move_speed: float = 4.0
@export var stop_distance: float = 1.0
@export var rotation_speed: float = 8.0

@export_group("Vision & Hearing (Sinne)")
@export var vision_angle: float = 65.0          # Sichtkegel (Grad)
@export var vision_range: float = 28.0          # Sichtweite
@export var hearing_range: float = 10.0         # Hörweite (Fußschritte/Geräusche)
@export var memory_time: float = 6.0            # Gedächtnisdauer in Sekunden

@export_group("Smart AI Settings")
## Chance (0.0 - 1.0), dass das Monster bei Sichtverlust mäuschenstill stehen bleibt
@export_range(0.0, 1.0) var ambush_chance: float = 0.35 
@export var max_agitation: float = 2.0          # Max. Geschwindigkeits-Boost bei Frustration

@export_group("Wander Settings")
@export var wander_radius: float = 12.0
@export var wander_pause_time: float = 3.0

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var sprite_3d_2: Sprite3D = $Sprite3D2

var player: Node3D = null
var current_stage: Stage = Stage.IDLE
var current_speed: float = 0.0

# KI State Data
var can_see_player: bool = false
var can_hear_player: bool = false
var last_known_player_pos: Vector3 = Vector3.ZERO
var search_timer: float = 0.0
var agitation_level: float = 1.0 # Baut sich bei Jagd auf

# Ecke/Wand Search State
var is_checking_corner: bool = false
var corner_look_angle: float = 0.0

# Wander & Ambush State
var wander_target: Vector3 = Vector3.ZERO
var is_wandering: bool = false
var is_waiting: bool = false
var ambush_timer: float = 0.0

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _ready() -> void:
	await wait(2)
	print("[Howler Advanced AI] Skript gestartet. Initialisiere Wahrnehmung...")
	_find_player()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		print("[Howler] Spieler lokalisiert: ", player.name)
	else:
		push_warning("[Howler] Kein Spieler in Gruppe 'Player' gefunden!")

func _physics_process(delta: float) -> void:
	if not player:
		_find_player()
		return

	# 1. Distanz berechnen & UI Label
	var my_pos := global_position
	var player_pos := player.global_position
	var distance := my_pos.distance_to(player_pos)
	
	if has_node("../CanvasLayer3/Control/Label"):
		$"../CanvasLayer3/Control/Label".text = "Distance: " + str(snapped(distance, 0.01))

	# 2. Sinne verarbeiten
	_check_senses(distance)

	# 3. KI-Gehirn & Entscheidungsbaum
	_process_brain(delta, distance)

	# 4. Verhalten ausführen
	_execute_behavior(delta, player_pos)

func _check_senses(distance: float) -> void:
	var was_seeing := can_see_player
	can_see_player = false
	can_hear_player = false

	# --- GEHÖR ---
	if distance <= hearing_range:
		can_hear_player = true
		last_known_player_pos = player.global_position

	# --- SEHEN (Raycast & Winkel) ---
	if distance <= vision_range:
		var dir_to_player := (player.global_position - global_position).normalized()
		dir_to_player.y = 0.0
		
		var forward := -transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()

		var angle := rad_to_deg(forward.angle_to(dir_to_player))

		if angle <= vision_angle:
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.2, player.global_position + Vector3.UP * 1.2)
			query.exclude = [self]
			var result = space_state.intersect_ray(query)

			if result and result.collider == player:
				can_see_player = true
				last_known_player_pos = player.global_position

	# Wut-Level Steuerung
	if can_see_player:
		agitation_level = min(agitation_level + 0.1 * get_process_delta_time(), max_agitation)
	elif was_seeing and not can_see_player:
		# Sichtkontakt GERADE verloren -> Mögliche Finte/Ambush planen!
		if randf() < ambush_chance:
			current_stage = Stage.AMBUSH_WAIT
			ambush_timer = randf_range(2.0, 4.0)

func _process_brain(delta: float, distance: float) -> void:
	# Falls in Fintr/Hinterhalt -> Warten erzwingen
	if current_stage == Stage.AMBUSH_WAIT:
		ambush_timer -= delta
		if ambush_timer <= 0 or can_see_player or can_hear_player:
			current_stage = Stage.INVESTIGATE
		else:
			return

	if can_see_player:
		search_timer = memory_time
		is_checking_corner = false
		
		if distance <= 5.0:
			current_stage = Stage.SPRINTING
			current_speed = base_move_speed * 2 * agitation_level
		elif distance <= 14.0:
			current_stage = Stage.CHASING
			current_speed = base_move_speed * 1.4 * agitation_level
		else:
			current_stage = Stage.STALKING
			current_speed = base_move_speed * 0.7

	elif can_hear_player:
		search_timer = memory_time
		current_stage = Stage.INVESTIGATE
		current_speed = base_move_speed * 1.0 * agitation_level

	else:
		# Sichtverlust -> Speicher herunterzählen
		if search_timer > 0:
			search_timer -= delta
			
			# Wenn er fast am Ort ist, wechselt er ins Eckensuchen (Corner Checking)
			if global_position.distance_to(last_known_player_pos) < 2.5:
				current_stage = Stage.CORNER_CHECK
			else:
				current_stage = Stage.INVESTIGATE
			
			current_speed = base_move_speed * 0.8
		else:
			# Beruhigen & Patrouillieren
			agitation_level = max(1.0, agitation_level - 0.05 * delta)
			current_stage = Stage.IDLE
			current_speed = base_move_speed * 0.45

func _execute_behavior(delta: float, player_pos: Vector3) -> void:
	var dist_to_target := global_position.distance_to(player_pos)

	# Nah genug -> Stopp
	if dist_to_target <= stop_distance and can_see_player:
		print("Nah genug!!!")
		velocity = Vector3.ZERO
		return

	match current_stage:
		Stage.IDLE:
			_process_wandering(delta)

		Stage.AMBUSH_WAIT:
			# Mäuschenstill stehen und lauschen (Täuscht den Spieler vor, er wäre weg)
			velocity = Vector3.ZERO

		Stage.INVESTIGATE:
			is_wandering = false
			is_waiting = false
			_move_towards(last_known_player_pos, current_speed, delta)

		Stage.CORNER_CHECK:
			# Am Ort angekommen: Prüft aktiv die Umgebung / schwenkt den Kopf
			velocity = Vector3.ZERO
			corner_look_angle += delta * 3.0
			rotate_y(sin(corner_look_angle) * 0.03) # Schwenkt suchend hin und her

		Stage.STALKING, Stage.CHASING, Stage.SPRINTING:
			is_wandering = false
			is_waiting = false
			_move_towards(player_pos, current_speed, delta)

func _process_wandering(delta: float) -> void:
	if is_waiting:
		velocity = Vector3.ZERO
		return

	if not is_wandering:
		_pick_new_wander_target()

	var dist_to_target := global_position.distance_to(wander_target)
	
	if dist_to_target <= 1.2 or is_on_wall():
		_pause_wandering()
	else:
		_move_towards(wander_target, current_speed, delta)

func _pick_new_wander_target() -> void:
	var random_offset := Vector3(
		randf_range(-wander_radius, wander_radius),
		0.0,
		randf_range(-wander_radius, wander_radius)
	)
	wander_target = global_position + random_offset
	wander_target.y = global_position.y
	is_wandering = true

func _pause_wandering() -> void:
	is_wandering = false
	is_waiting = true
	velocity = Vector3.ZERO
	await get_tree().create_timer(wander_pause_time).timeout
	is_waiting = false

func _move_towards(target_pos: Vector3, speed: float, delta: float) -> void:
	var my_pos := global_position
	var direction := (target_pos - my_pos)
	direction.y = 0.0
	
	if direction.length() > 0.1:
		direction = direction.normalized()
		velocity = direction * speed
		move_and_slide()

		# Drehung sanft und realistisch interpolieren (Kein logarithmisches Instant-Umdrehen)
		var look_target := global_position + Vector3(velocity.x, 0.0, velocity.z)
		var target_transform := transform.looking_at(look_target, Vector3.UP)
		transform.basis = transform.basis.slerp(target_transform.basis, rotation_speed * delta)
