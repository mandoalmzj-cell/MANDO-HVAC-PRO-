extends Node3D

@export var drive_speed: float = 8.0
@export var turn_speed: float = 2.0

var throttle := 0.0
var steering := 0.0

@onready var car_body: MeshInstance3D = $CarBody
@onready var car_cabin: MeshInstance3D = $CarCabin
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
    create_mobile_controls()

func _physics_process(delta: float) -> void:
    var forward_input := Input.get_axis("ui_up", "ui_down")
    var turn_input := Input.get_axis("ui_right", "ui_left")
    forward_input = clamp(forward_input + throttle, -1.0, 1.0)
    turn_input = clamp(turn_input + steering, -1.0, 1.0)

    if abs(forward_input) > 0.01:
        car_body.position += -car_body.global_basis.z * forward_input * drive_speed * delta
        car_cabin.position += -car_cabin.global_basis.z * forward_input * drive_speed * delta

    if abs(turn_input) > 0.01:
        var turn_amount := -turn_input * turn_speed * delta
        car_body.rotate_y(turn_amount)
        car_cabin.rotate_y(turn_amount)

    var target := car_body.global_position + Vector3(0, 6, 10)
    camera.global_position = camera.global_position.lerp(target, delta * 3.0)
    camera.look_at(car_body.global_position, Vector3.UP)

func create_mobile_controls() -> void:
    var layer := CanvasLayer.new()
    layer.name = "MobileControls"
    add_child(layer)

    var ui := Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(ui)

    add_hold_button(ui, "◀", Vector2(25, -125), Vector2(85, 85), "steer_left")
    add_hold_button(ui, "▶", Vector2(120, -125), Vector2(85, 85), "steer_right")
    add_hold_button(ui, "▲", Vector2(-115, -220), Vector2(85, 85), "accelerate")
    add_hold_button(ui, "▼", Vector2(-115, -125), Vector2(85, 85), "brake")

func add_hold_button(parent: Control, caption: String, offset: Vector2, button_size: Vector2, action: String) -> void:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = button_size
    button.size = button_size
    button.add_theme_font_size_override("font_size", 28)
    button.modulate = Color(0.3, 0.9, 1.0, 0.85)

    if action.begins_with("steer"):
        button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
        button.position = Vector2(25, -125) if action == "steer_left" else Vector2(120, -125)
    else:
        button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
        button.position = Vector2(-115, -220) if action == "accelerate" else Vector2(-115, -125)

    parent.add_child(button)
    button.button_down.connect(func(): set_control(action, true))
    button.button_up.connect(func(): set_control(action, false))

func set_control(action: String, pressed: bool) -> void:
    match action:
        "steer_left":
            steering = -1.0 if pressed else 0.0
        "steer_right":
            steering = 1.0 if pressed else 0.0
        "accelerate":
            throttle = 1.0 if pressed else 0.0
        "brake":
            throttle = -1.0 if pressed else 0.0
