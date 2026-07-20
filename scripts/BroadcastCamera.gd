extends Control
class_name BroadcastCamera

@export_range(1, 3) var camera_id: int = 1
@export var camera_title: String = "CAM1"
@export var preview_color: Color = Color(0.145, 0.514, 1.0, 1.0)

var state: String = "normal"

@onready var content: Control = $Content
@onready var preview: TextureRect = $Content/Preview
@onready var preview_background: ColorRect = $Content/PreviewBackground
@onready var overlay: ColorRect = $Content/Overlay
@onready var label: Label = $Content/Label
@onready var state_label: Label = $Content/StateLabel
@onready var on_air_label: Label = $Content/OnAirLabel


func _ready() -> void:
    preview_background.color = preview_color
    label.text = camera_title
    set_state("normal")
    set_on_air(false)


func set_state(new_state: String) -> void:
    state = new_state

    match new_state:
        "normal":
            overlay.color = Color(0.0, 0.0, 0.0, 0.0)
            state_label.text = ""
        "warning":
            overlay.color = Color(1.0, 0.69, 0.13, 0.28)
            state_label.text = "⚠ WARNING"
        "danger":
            overlay.color = Color(0.91, 0.2, 0.2, 0.48)
            state_label.text = "● INCIDENT"
        "resolved":
            overlay.color = Color(0.27, 0.79, 0.42, 0.24)
            state_label.text = "✓ RESOLVED"
        _:
            overlay.color = Color(0.0, 0.0, 0.0, 0.0)
            state_label.text = ""


func set_on_air(active: bool) -> void:
    on_air_label.visible = active


func get_preview_color() -> Color:
    return preview_color


func pulse() -> void:
    var tween := create_tween()
    tween.tween_property(content, "scale", Vector2(1.03, 1.03), 0.12)
    tween.tween_property(content, "scale", Vector2.ONE, 0.12)


func shake() -> void:
    var original_position := content.position
    var tween := create_tween()
    for index in range(5):
        var offset := Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
        tween.tween_property(content, "position", original_position + offset, 0.035)
    tween.tween_property(content, "position", original_position, 0.035)
