
extends Node3D

@export var drive_speed: float = 8.0
@export var reverse_speed: float = 4.0
@export var turn_speed: float = 1.8
@export var camera_smoothness: float = 5.0

var throttle: float = 0.0
var steering: float = 0.0

var money: int = 5000
var car_condition: int = 100
var car_paint: Color = Color(0.05, 0.65, 0.9, 1.0)

var save_path: String = "user://mando_scrap_save.json"

@onready var car: Node3D = $Car
@onready var camera: Camera3D = $Camera3D

var status_label: Label
var money_label: Label
var repair_button: Button
var save_button: Button


func _ready() -> void:
	load_progress()
	create_mobile_controls()
	create_game_ui()
	update_game_ui()


func _physics_process(delta: float) -> void:
	var forward_input: float = throttle
	var turn_input: float = steering

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		forward_input = 1.0
	elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		forward_input = -1.0

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		turn_input = -1.0
	elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		turn_input = 1.0

	var speed: float = drive_speed if forward_input >= 0.0 else reverse_speed
	car.global_position += -car.global_basis.z * forward_input * speed * delta

	if absf(forward_input) > 0.05:
		car.rotate_y(turn_input * turn_speed * delta * signf(forward_input))

	var camera_offset: Vector3 = car.global_basis * Vector3(0.0, 5.0, 9.0)
	var target_position: Vector3 = car.global_position + camera_offset

	camera.global_position = camera.global_position.lerp(
		target_position,
		clampf(delta * camera_smoothness, 0.0, 1.0)
	)

	camera.look_at(
		car.global_position + Vector3(0.0, 0.8, 0.0),
		Vector3.UP
	)


func create_mobile_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MobileControls"
	add_child(layer)

	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)

	add_hold_button(ui, "◀", Vector2(25, -100), Vector2(75, 75), "left")
	add_hold_button(ui, "▶", Vector2(110, -100), Vector2(75, 75), "right")
	add_hold_button(ui, "▲", Vector2(-95, -185), Vector2(75, 75), "forward")
	add_hold_button(ui, "▼", Vector2(-95, -100), Vector2(75, 75), "reverse")


func add_hold_button(
	parent: Control,
	caption: String,
	offset: Vector2,
	button_size: Vector2,
	action: String
) -> void:
	var button := Button.new()
	button.text = caption
	button.size = button_size
	button.custom_minimum_size = button_size
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override(
		"font_hover_color",
		Color(0.3, 0.9, 1.0)
	)
	button.add_theme_stylebox_override("normal", make_button_style())

	if action == "left" or action == "right":
		button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	else:
		button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)

	button.position = offset
	parent.add_child(button)

	button.button_down.connect(_on_control_down.bind(action))
	button.button_up.connect(_on_control_up.bind(action))


func make_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.12, 0.17, 0.85)
	style.border_color = Color(0.05, 0.8, 1.0, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style


func create_game_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "GameInfo"
	add_child(layer)

	var panel := VBoxContainer.new()
	panel.position = Vector2(20, 20)
	panel.add_theme_constant_override("separation", 8)
	layer.add_child(panel)

	money_label = Label.new()
	money_label.add_theme_font_size_override("font_size", 24)
	panel.add_child(money_label)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(status_label)

	repair_button = Button.new()
	repair_button.text = "Repair Car - $1000"
	repair_button.custom_minimum_size = Vector2(200, 50)
	panel.add_child(repair_button)
	repair_button.pressed.connect(repair_car)

	save_button = Button.new()
	save_button.text = "Save Game"
	save_button.custom_minimum_size = Vector2(200, 50)
	panel.add_child(save_button)
	save_button.pressed.connect(save_progress)


func update_game_ui() -> void:
	if is_instance_valid(money_label):
		money_label.text = "MANDO SCRAP CARS | Money: $" + str(money)

	if is_instance_valid(status_label):
		status_label.text = "Car condition: " + str(car_condition) + "%"

	if is_instance_valid(repair_button):
		repair_button.disabled = money < 1000 or car_condition >= 100


func repair_car() -> void:
	if money < 1000 or car_condition >= 100:
		return

	money -= 1000
	car_condition = 100
	update_game_ui()
	save_progress()


func save_progress() -> void:
	var data := {
		"money": money,
		"car_condition": car_condition
	}

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
		file.close()

	update_game_ui()


func load_progress() -> void:
	if not FileAccess.file_exists(save_path):
		return

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed is Dictionary:
		money = int(parsed.get("money", 5000))
		car_condition = clampi(
			int(parsed.get("car_condition", 100)),
			0,
			100
		)


func _on_control_down(action: String) -> void:
	match action:
		"left":
			steering = -1.0
		"right":
			steering = 1.0
		"forward":
			throttle = 1.0
		"reverse":
			throttle = -1.0


func _on_control_up(action: String) -> void:
	match action:
		"left", "right":
			steering = 0.0
		"forward", "reverse":
			throttle = 0.0
