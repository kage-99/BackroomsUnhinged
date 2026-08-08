extends Node3D

@export_group("Auto Start Settings")
## Zeit in Sekunden, bis nach der 2D-Map automatisch die 3D-Welt gebaut wird
@export var auto_generate_delay: float = 3.0

@export_group("Scene References")
@export var wall_scene: PackedScene = preload("res://3D/Wall3D.tscn")
@export var ground_scene: PackedScene
## Falls du einen Player hast, kannst du ihn hier zuweisen
@export var player_node: Node3D
## Referenz zum Howler (falls leer, wird automatisch ../Howler gesucht)
@export var howler_node: Node3D
@export var door_node: Node3D

@export_group("Level Dimensions")
@export var map_width: int = 16
@export var map_depth: int = 16
@export var wall_spacing: float = 4.0

@export_group("Backrooms Style Settings")
@export_range(0.1, 0.6) var wall_density: float = 0.35
@export_range(0, 5) var spawn_clear_radius: int = 1
@export var enable_loops: bool = true

@export_group("Upper Room Settings")
## Raumhöhe des Hauptraums (reduziert, damit es nicht zu hoch ist)
@export var room_height: float = 4.0
## Höhe des oberen Raums
@export var upper_room_height: float = 3.0
## Wie viele Tiles breit/lang der obere Raum sein soll (z. B. 3 = 3x3 Grid-Tiles)
@export var upper_room_tiles: int = 3

@export_group("Seed")
@export var use_random_seed: bool = true
@export var custom_seed: int = 1337

var nav_region: NavigationRegion3D = null

var h_walls: Array = []
var v_walls: Array = []
var exit_pos_2d := Vector2i.ZERO
var howler_pos_2d := Vector2i.ZERO
var door_pos_2d := Vector2i.ZERO

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	print("[Generator] Initialisiere Prozeduralen Generator...")
	
	# 1. NavigationRegion3D aufbauen
	_setup_navigation_region()

	# 2. 2D Karte generieren
	generate_2d_map()
	
	# 3. Automatischer Timer für 3D-Welt & NavMesh Bake
	_start_auto_generate_timer()

func _setup_navigation_region() -> void:
	nav_region = get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	
	if not nav_region:
		nav_region = NavigationRegion3D.new()
		nav_region.name = "NavigationRegion3D"
		add_child(nav_region)
		print("[Generator] -> NavigationRegion3D war nicht vorhanden. Automatisch erstellt.")
	else:
		print("[Generator] -> Existierende NavigationRegion3D im Scene-Tree gefunden.")

	if nav_region.navigation_mesh == null:
		var nav_mesh := NavigationMesh.new()
		nav_mesh.agent_radius = 0.5
		nav_mesh.agent_height = 2.0
		nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
		nav_region.navigation_mesh = nav_mesh
		print("[Generator] -> Neues NavigationMesh zugewiesen (Radius: 0.5, Height: 2.0).")

func _start_auto_generate_timer() -> void:
	print("[Generator] Starte Wartezeit vor 3D-Generierung (Wartezeit: %.1f Sek)..." % auto_generate_delay)
	
	var time_left: float = auto_generate_delay
	while time_left > 0:
		await get_tree().create_timer(0.5).timeout
		time_left -= 0.5
		print("[Generator] Countdown 3D-Bau: %.1f Sek" % max(time_left, 0.0))

	await wait(0.2)
	
	print("[Generator] Erstelle 3D-Geometrie...")
	_build_3d_walls()
	_spawn_exit_ladder(exit_pos_2d)
	_spawn_howler(howler_pos_2d)

	if player_node:
		var spawn_pos := get_spawn_position_3d()
		player_node.global_position = spawn_pos
		print("[Generator] Spieler zum Startpunkt teleportiert: ", spawn_pos)
	else:
		print("[Generator] Hinweis: Kein 'player_node' zugewiesen. Teleportation übersprungen.")

	# NavigationMesh baken
	_bake_nav_mesh()

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

# --- 2D GRID GENERATION ---

func generate_2d_map() -> void:
	if use_random_seed:
		rng.randomize()
		print("[Generator] Verwende zufälligen Seed: ", rng.seed)
	else:
		rng.seed = custom_seed
		print("[Generator] Verwende manuellen Seed: ", custom_seed)

	_init_grids()
	_simulate_backrooms_2d()
	exit_pos_2d = _ensure_path_and_get_exit()
	howler_pos_2d = _get_random_howler_pos()
	door_pos_2d = _get_random_door_pos()

	print("[Generator] 2D-Layout abgeschlossen.")
	print("   -> Map-Größe: %dx%d Cells" % [map_width, map_depth])
	print("   -> Ausgang 2D: ", exit_pos_2d)

func _get_random_howler_pos() -> Vector2i:
	var player_spawn := Vector2i(map_width / 2, map_depth / 2)
	var random_pos := Vector2i.ZERO
	var valid_pos := false
	var attempts := 0

	while not valid_pos and attempts < 100:
		attempts += 1
		random_pos.x = rng.randi_range(0, map_width - 1)
		random_pos.y = rng.randi_range(0, map_depth - 1)

		var dist_to_player: int = abs(random_pos.x - player_spawn.x) + abs(random_pos.y - player_spawn.y)
		var dist_to_exit: int = abs(random_pos.x - exit_pos_2d.x) + abs(random_pos.y - exit_pos_2d.y)

		if dist_to_player >= 7 and dist_to_exit >= 1:
			valid_pos = true

	return random_pos

func _get_random_door_pos() -> Vector2i:
	var player_spawn := Vector2i(map_width / 2, map_depth / 2)
	var random_pos := Vector2i.ZERO
	var valid_pos := false
	var attempts := 0

	while not valid_pos and attempts < 100:
		attempts += 1
		random_pos.x = rng.randi_range(0, map_width - 1)
		random_pos.y = rng.randi_range(0, map_depth - 1)

		var dist_to_player: int = abs(random_pos.x - player_spawn.x) + abs(random_pos.y - player_spawn.y)
		var dist_to_exit: int = abs(random_pos.x - exit_pos_2d.x) + abs(random_pos.y - exit_pos_2d.y)

		if dist_to_player >= 2 and dist_to_exit >= 5:
			valid_pos = true

	return random_pos

func _init_grids() -> void:
	h_walls.clear()
	v_walls.clear()

	for x in range(map_width):
		var column: Array[bool] = []
		for z in range(map_depth + 1):
			column.append(z == 0 or z == map_depth)
		h_walls.append(column)

	for x in range(map_width + 1):
		var column: Array[bool] = []
		for z in range(map_depth):
			column.append(x == 0 or x == map_width)
		v_walls.append(column)

func _simulate_backrooms_2d() -> void:
	var center_x := map_width / 2
	var center_z := map_depth / 2

	for x in range(map_width):
		for z in range(1, map_depth):
			if spawn_clear_radius > 0 and abs(x - center_x) < spawn_clear_radius and abs(z - center_z) < spawn_clear_radius:
				continue
			if rng.randf() < wall_density:
				h_walls[x][z] = true

	for x in range(1, map_width):
		for z in range(map_depth):
			if spawn_clear_radius > 0 and abs(x - center_x) < spawn_clear_radius and abs(z - center_z) < spawn_clear_radius:
				continue
			if rng.randf() < wall_density:
				v_walls[x][z] = true

func _ensure_path_and_get_exit() -> Vector2i:
	var spawn := Vector2i(map_width / 2, map_depth / 2)
	var exit := Vector2i(map_width - 2, map_depth - 2)

	var curr := spawn

	while curr != exit:
		if curr.x != exit.x and (rng.randf() < 0.5 or curr.y == exit.y):
			var next_x: int = curr.x + (1 if exit.x > curr.x else -1)
			var wall_x: int = int(max(curr.x, next_x))
			if v_walls[wall_x][curr.y]:
				v_walls[wall_x][curr.y] = false
			curr.x = next_x
		elif curr.y != exit.y:
			var next_z: int = curr.y + (1 if exit.y > curr.y else -1)
			var wall_z: int = int(max(curr.y, next_z))
			if h_walls[curr.x][wall_z]:
				h_walls[curr.x][wall_z] = false
			curr.y = next_z

	if enable_loops:
		_create_random_loops()

	return exit

func _create_random_loops() -> void:
	for x in range(1, map_width - 1):
		for z in range(1, map_depth - 1):
			if rng.randf() < 0.2:
				if rng.randf() < 0.5 and h_walls[x][z]:
					h_walls[x][z] = false
				elif v_walls[x][z]:
					v_walls[x][z] = false

# --- 3D BUILDER ---

func _clear_map() -> void:
	if nav_region:
		for child in nav_region.get_children():
			child.queue_free()

func _spawn_roof() -> void:
	if ground_scene == null:
		return

	var map_total_width := map_width * wall_spacing
	var map_total_depth := map_depth * wall_spacing

	var ground := ground_scene.instantiate() as Node3D
	ground.name = "Roof"
	nav_region.add_child(ground)

	var base_ground_width := 48.4
	var base_ground_depth := 33.1
	var scale_x := map_total_width / base_ground_width
	var scale_z := map_total_depth / base_ground_depth

	if ground.get_child_count() > 1:
		var mat = ground.get_child(1).get_active_material(0) as StandardMaterial3D
		if mat:
			mat = mat.duplicate()
			ground.get_child(1).set_surface_override_material(0, mat)
			var texture = load("res://Sprites/Roof.png") as Texture2D
			if texture:
				mat.albedo_texture = texture
			mat.uv1_scale = Vector3(50.0 * scale_x * 2, 50.0 * scale_z * 2, 1.0)

	ground.scale = Vector3(scale_x, 1.0, scale_z)
	ground.position = Vector3(map_total_width / 2.0, room_height, map_total_depth / 2.0)

func _spawn_ground() -> void:
	if ground_scene == null:
		return

	var map_total_width := map_width * wall_spacing
	var map_total_depth := map_depth * wall_spacing

	var ground := ground_scene.instantiate() as Node3D
	ground.name = "Ground"
	nav_region.add_child(ground)

	var base_ground_width := 48.4
	var base_ground_depth := 33.1
	var scale_x := map_total_width / base_ground_width
	var scale_z := map_total_depth / base_ground_depth

	if ground.get_child_count() > 1:
		var mat = ground.get_child(1).get_active_material(0) as StandardMaterial3D
		if mat:
			mat = mat.duplicate()
			ground.get_child(1).set_surface_override_material(0, mat)
			mat.uv1_scale = Vector3(50.0 * scale_x * 5, 50.0 * scale_z * 5, 1.0)

	ground.scale = Vector3(scale_x, 1.0, scale_z)
	ground.position = Vector3(map_total_width / 2.0, 0.0, map_total_depth / 2.0)

'''func _build_upper_room(exit_2d: Vector2i) -> void:
	await wait(1)
	# Baut einen mehrteiligen Raum (über upper_room_tiles hinweg)
	var room_size_m := upper_room_tiles * wall_spacing
	var room_center_3d := Vector3(
		(exit_2d.x + 0.5) * wall_spacing,
		room_height,
		(exit_2d.y + 0.5) * wall_spacing
	)

	var upper_room := Node3D.new()
	upper_room.name = "UpperRoom"
	nav_region.add_child(upper_room)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)

	# 1. Bodenplatten für den oberen Raum aufbauen (mit Loch über der Leiter)
	var hole_radius := 1.0 # Breiteres Deckenloch für einfache Kollision
	
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(room_size_m, 0.2, room_size_m)
	floor_mesh.mesh = box
	floor_mesh.material_override = mat
	floor_mesh.position = room_center_3d
	upper_room.add_child(floor_mesh)

	var static_body := StaticBody3D.new()
	# 4 Kollisionsboxen um die Leiteröffnung herum bauen
	var h_size := (room_size_m - hole_radius * 2) / 2.0
	
	_add_box_col(static_body, Vector3(room_size_m, 0.2, h_size), room_center_3d + Vector3(0, 0, (room_size_m/2.0 - h_size/2.0)))
	_add_box_col(static_body, Vector3(room_size_m, 0.2, h_size), room_center_3d + Vector3(0, 0, -(room_size_m/2.0 - h_size/2.0)))
	_add_box_col(static_body, Vector3(h_size, 0.2, hole_radius * 2), room_center_3d + Vector3((room_size_m/2.0 - h_size/2.0), 0, 0))
	_add_box_col(static_body, Vector3(h_size, 0.2, hole_radius * 2), room_center_3d + Vector3(-(room_size_m/2.0 - h_size/2.0), 0, 0))
	upper_room.add_child(static_body)

	# 2. Decke für den oberen Raum
	var upper_roof := MeshInstance3D.new()
	var roof_box := BoxMesh.new()
	roof_box.size = Vector3(room_size_m, 0.2, room_size_m)
	upper_roof.mesh = roof_box
	upper_roof.material_override = mat
	upper_roof.position = room_center_3d + Vector3(0, upper_room_height, 0)
	upper_room.add_child(upper_roof)

	# 3. Außenwände des oberen Raums platzieren
	var half_r := room_size_m / 2.0
	var h_wall := upper_room_height / 2.0

	_spawn_wall_instance(room_center_3d + Vector3(0, h_wall, half_r), 0.0)
	_spawn_wall_instance(room_center_3d + Vector3(0, h_wall, -half_r), 0.0)
	_spawn_wall_instance(room_center_3d + Vector3(half_r, h_wall, 0), 90.0)
	_spawn_wall_instance(room_center_3d + Vector3(-half_r, h_wall, 0), 90.0)

	print("[Generator] Großer oberer Raum (%dx%d Tiles) erstellt." % [upper_room_tiles, upper_room_tiles])

func _add_box_col(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.global_position = pos
	body.add_child(col)'''

func _build_3d_walls() -> void:
	_clear_map()
	await get_tree().process_frame

	_spawn_ground()
	_spawn_roof()

	for x in range(map_width):
		for z in range(map_depth + 1):
			if h_walls[x][z]:
				var pos := Vector3((x + 0.5) * wall_spacing, 0, z * wall_spacing)
				_spawn_wall_instance(pos, 0.0)

	for x in range(map_width + 1):
		for z in range(map_depth):
			if v_walls[x][z]:
				var pos := Vector3(x * wall_spacing, 0, (z + 0.5) * wall_spacing)
				_spawn_wall_instance(pos, 90.0)

	#_build_upper_room(exit_pos_2d)

func _spawn_wall_instance(pos: Vector3, rot_y: float) -> void:
	if wall_scene == null:
		return
	var wall := wall_scene.instantiate() as Node3D
	nav_region.add_child(wall)
	wall.position = pos
	wall.rotation_degrees.y = rot_y

func _bake_nav_mesh() -> void:
	if nav_region and nav_region.navigation_mesh:
		nav_region.bake_navigation_mesh(true)

func _spawn_exit_ladder(exit_2d: Vector2i) -> void:
	var exit_3d := Vector3(
		(exit_2d.x + 0.5) * wall_spacing,
		0,
		(exit_2d.y + 0.5) * wall_spacing
	)

	# Die Leiter ragt 1 Meter in den oberen Raum hinein
	var total_ladder_height: float = room_height + 1.2

	var exit_node := Node3D.new()
	exit_node.name = "ExitLadder"
	exit_node.position = exit_3d
	nav_region.add_child(exit_node)

	var ladder_material := StandardMaterial3D.new()
	ladder_material.albedo_color = Color(0.25, 0.25, 0.25)

	# Seitenschienen
	for side in [-0.35, 0.35]:
		var pole := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.06, total_ladder_height, 0.06)
		pole.mesh = box
		pole.material_override = ladder_material
		pole.position = Vector3(side, total_ladder_height / 2.0, 0)
		exit_node.add_child(pole)

	# Sprossen
	var rung_step_distance := 0.4
	var num_steps := int(total_ladder_height / rung_step_distance)

	for step in range(num_steps):
		var rung := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.7, 0.04, 0.06)
		rung.mesh = box
		rung.material_override = ladder_material
		rung.position = Vector3(0, step * rung_step_distance + 0.2, 0)
		exit_node.add_child(rung)

	# Kollision der Leiter
	var static_body := StaticBody3D.new()
	static_body.add_to_group("Ladder")
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(0.8, total_ladder_height, 0.3)
	collision.shape = box_shape
	collision.position = Vector3(0, total_ladder_height / 2.0, 0)
	static_body.add_child(collision)
	exit_node.add_child(static_body)

	# Teleport/Kletter-Area3D Trigger für einfaches Aufsteigen
	var climb_area := Area3D.new()
	climb_area.name = "ClimbArea"
	var area_col := CollisionShape3D.new()
	var area_box := BoxShape3D.new()
	area_box.size = Vector3(1.0, total_ladder_height, 1.0)
	area_col.shape = area_box
	area_col.position = Vector3(0, total_ladder_height / 2.0, 0)
	climb_area.add_child(area_col)
	climb_area.body_entered.connect(_on_ladder_body_entered)
	exit_node.add_child(climb_area)

	# Licht oben im Raum
	var exit_light := OmniLight3D.new()
	exit_light.light_color = Color(0.3, 1.0, 0.4)
	exit_light.light_energy = 80.0
	exit_light.omni_range = 100.0
	exit_light.position = Vector3(0, room_height + 1.0, 0)
	exit_node.add_child(exit_light)

func _on_ladder_body_entered(body: Node) -> void:
	# Hilft dem Spieler nach oben zu steigen, sobald er die Leiter berührt
	if player_node and body == player_node:
		$"../3dPlayer".showPanel()
		await wait(1.5)
		get_tree().change_scene_to_file("res://2D/Level 0 Part 2.tscn")

func _spawn_howler(howler_2d: Vector2i) -> void:
	var howler_3d := Vector3(
		(howler_2d.x + 0.5) * wall_spacing,
		0.0,
		(howler_2d.y + 0.5) * wall_spacing
	)

	if not howler_node:
		howler_node = get_node_or_null("../Howler") as Node3D

	if howler_node:
		howler_node.global_position = howler_3d

func get_spawn_position_3d() -> Vector3:
	var spawn_2d := Vector2i(map_width / 2, map_depth / 2)
	return Vector3(
		(spawn_2d.x + 0.5) * wall_spacing,
		1.0,
		(spawn_2d.y + 0.5) * wall_spacing
	)
