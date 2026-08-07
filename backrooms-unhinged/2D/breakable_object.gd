extends StaticBody2D

@onready var tile_map: TileMap = $TileMap3
@export var sprite_visible = true

func _ready() -> void:
	$TileMap3.visible = sprite_visible

func change_layer_color(color: Color) -> void:
	tile_map.set_layer_modulate(0, color)

func shift_layer_hue(amount: float = 0.1) -> void:
	# 1. Aktuelle Farbe von Layer 0 holen
	var current_color: Color = tile_map.get_layer_modulate(0)
	
	# 2. H-Wert erhöhen und bei > 1.0 wieder bei 0.0 anfangen lassen (Wrap-Around)
	current_color.h = fmod(current_color.h + amount, 1.0)
	
	# 3. Geänderte Farbe zurück auf Layer 0 anwenden
	tile_map.set_layer_modulate(0, current_color)

func on_break() -> void:
	if sprite_visible:
		for i in range(5):
			change_layer_color(Color.RED)
			await wait(0.1)
			change_layer_color(Color.GREEN)
			await wait(0.1)
			change_layer_color(Color.DODGER_BLUE)
			await wait(0.1)
	$".".queue_free()

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

var entered = false
var attacked = false

func _process(delta: float) -> void:
	if entered and not attacked:
		if Input.is_action_just_pressed("ui_attack"):
			attacked = true
			print("Detected attack")
			await wait(1)
			on_break()
		#var color = $TileMap3.layers[0].modulate
		#color = Color.from_hsv(color.h+1)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if len(body.get_groups()) > 0 and body.get_groups()[0] == "Player":
		entered = true
		print("entered")


func _on_area_2d_body_exited(body: Node2D) -> void:
	if len(body.get_groups()) > 0 and body.get_groups()[0] == "Player":
		entered = false
		print("exit")
