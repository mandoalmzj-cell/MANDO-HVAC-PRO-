extends Node3D

@export var drive_speed: float = 8.0
@export var reverse_speed: float = 4.0
@export var turn_speed: float = 1.8
@export var camera_smoothness: float = 5.0

var throttle: float = 0.0
var steering: float = 0.0

@onready var car: Node3D = $Car
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
    create_mobile_controls()

func _physics_process(delta: float) -> void:
    var forward_input := Input.get_axis("ui_down", "ui_up")
    var turn_input := Input.get_axis("ui_right", "ui_left")

    forward_input = clampf(forward_input + throttle, -1.0, 1.0)
    turn_input = clampf(turn_input + steering, -1.0, 1.0)

    var speed := drive_speed if forward_input >= 0.0 else reverse_speed
    car.position += -car.global_basis.z * forward_input * speed * delta

    if absf(forward_input) > 0.05:
        car.rotate_y(turn_input * turn_speed * delta * signf(forward_input))

    var target_position := car.global_position + car.global_basis * Vector3(0.0, 5.0, 9.0)
    camera.global_position = camera.global_position.lerp(target_position, clampf(delta * camera_smoothness, 0.0, 1.0))
    camera.look_at(car.global_position + Vector3(0.0, 0.8, 0.0), Vector3.UP)

func create_mobile_controls() -> void:
    var layer := CanvasLayer.new()
    layer.name = "MobileControls"
    add_child(layer)

    var ui := Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(ui)

    add_hold_button(ui, "◀", Vector2(25, -115), Vector2(80, 80), "left")
    add_hold_button(ui, "▶", Vector2(115, -115), Vector2(80, 80), "right")
    add_hold_button(ui, "▲", Vector2(-105, -205), Vector2(80, 80), "forward")
    add_hold_button(ui, "▼", Vector2(-105, -115), Vector2(80, 80), "reverse")

func add_hold_button(parent: Control, caption: String, offset: Vector2, button_size: Vector2, action: String) -> void:
    var button := Button.new()
    button.text = caption
    button.size = button_size
    button.custom_minimum_size = button_size
    button.add_theme_font_size_override("font_size", 28)
    button.modulate = Color(0.3, 0.9, 1.0, 0.9)

    if action == "left" or action == "right":
        button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
        button.position = offset
    else:
        button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
        button.position = offset

    parent.add_child(button)
    button.button_down.connect(_on_control_down.bind(action))
    button.button_up.connect(_on_control_up.bind(action))

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
