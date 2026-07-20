extends Control
class_name StartScreen

signal countdown_finished

@onready var title_label: Label = $Dim/Panel/VBox/Title
@onready var subtitle_label: Label = $Dim/Panel/VBox/Subtitle
@onready var countdown_label: Label = $Dim/Panel/VBox/CountdownLabel
@onready var start_button: Button = $Dim/Panel/VBox/StartButton

var is_counting_down: bool = false


func _ready() -> void:
    start_button.pressed.connect(_on_start_pressed)
    show_ready()


func show_ready() -> void:
    visible = true
    is_counting_down = false
    title_label.text = "本番5秒前"
    subtitle_label.text = "4つの事故を処理して、90秒の放送を守れ"
    countdown_label.text = "READY"
    start_button.visible = true
    start_button.disabled = false
    start_button.scale = Vector2.ONE
    start_button.modulate = Color(1, 1, 1, 1)


func _on_start_pressed() -> void:
    if is_counting_down:
        return

    is_counting_down = true
    start_button.disabled = true
    _animate_button(start_button)
    await get_tree().create_timer(0.15).timeout
    start_button.visible = false
    subtitle_label.text = "放送開始まで"

    for count in [3, 2, 1]:
        countdown_label.text = str(count)
        _animate_countdown()
        await get_tree().create_timer(1.0).timeout

    countdown_label.text = "ON AIR"
    _animate_countdown()
    await get_tree().create_timer(0.35).timeout

    visible = false
    countdown_finished.emit()


func _animate_button(button: Button) -> void:
    button.pivot_offset = button.size * 0.5
    var tween := create_tween()
    tween.tween_property(button, "scale", Vector2(0.94, 0.94), 0.07)
    tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animate_countdown() -> void:
    countdown_label.pivot_offset = countdown_label.size * 0.5
    countdown_label.scale = Vector2(0.65, 0.65)
    countdown_label.modulate.a = 0.35
    var tween := create_tween().set_parallel(true)
    tween.tween_property(countdown_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(countdown_label, "modulate:a", 1.0, 0.18)
