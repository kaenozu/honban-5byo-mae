extends Control
class_name Main

@onready var gm: GameManager = $GameManager
@onready var score_manager: ScoreManager = $ScoreManager
@onready var em: EventManager = $EventManager
@onready var director_ai: DirectorAI = $DirectorAI
@onready var hud: HUD = $HUD
@onready var onair_feed: ColorRect = $OnAirDisplay/Feed
@onready var onair_camera_label: Label = $OnAirDisplay/CameraLabel
@onready var onair_status_label: Label = $OnAirDisplay/StatusLabel
@onready var director_label: Label = $DirectorPanel/AdviceLabel
@onready var control_status: Label = $ControlPanel/StatusLabel
@onready var result_screen: Control = $ResultScreen
@onready var result_score: Label = $ResultScreen/ResultPanel/ResultVBox/ResultScore
@onready var result_rating: Label = $ResultScreen/ResultPanel/ResultVBox/ResultRating
@onready var result_accident: Label = $ResultScreen/ResultPanel/ResultVBox/ResultAccident
@onready var result_bonus: Label = $ResultScreen/ResultPanel/ResultVBox/ResultBonus

var cameras: Dictionary = {}
var buttons: Dictionary = {}


func _ready() -> void:
    setup_cameras()
    setup_buttons()
    setup_signals()
    hud.bind_game_manager(gm)
    result_screen.visible = false
    _start_game()


func _process(_delta: float) -> void:
    _update_control_status()


func setup_cameras() -> void:
    cameras[1] = $PreviewContainer/CAM1
    cameras[2] = $PreviewContainer/CAM2
    cameras[3] = $PreviewContainer/CAM3


func setup_buttons() -> void:
    buttons[1] = $ControlPanel/CAM1Button
    buttons[2] = $ControlPanel/CAM2Button
    buttons[3] = $ControlPanel/CAM3Button
    buttons["cm"] = $ControlPanel/CMButton
    buttons["mute"] = $ControlPanel/MuteButton
    buttons["telop"] = $ControlPanel/TelopButton

    buttons[1].pressed.connect(_select_camera.bind(1))
    buttons[2].pressed.connect(_select_camera.bind(2))
    buttons[3].pressed.connect(_select_camera.bind(3))
    buttons["cm"].pressed.connect(_use_cm)
    buttons["mute"].pressed.connect(_toggle_mute)
    buttons["telop"].pressed.connect(_toggle_telop)
    $ResultScreen/ResultPanel/ResultVBox/RestartButton.pressed.connect(_start_game)


func setup_signals() -> void:
    gm.camera_changed.connect(_on_camera_changed)
    gm.score_changed.connect(_on_score_changed)
    gm.rating_changed.connect(_on_rating_changed)
    gm.accident_changed.connect(_on_accident_changed)
    gm.cm_changed.connect(_update_control_status)
    gm.mode_changed.connect(_update_control_status)
    gm.game_ended.connect(_on_game_ended)
    em.event_started.connect(_on_event_started)
    em.event_phase_changed.connect(_on_event_phase_changed)
    em.event_ended.connect(_on_event_ended)


func _start_game() -> void:
    em.cleanup()
    result_screen.visible = false
    director_label.text = "プレビューを見ろ。事故の兆候を逃すな"
    gm.start_game()
    _on_camera_changed(gm.current_camera)
    _reset_camera_states()
    _update_control_status()


func _select_camera(camera_id: int) -> void:
    if gm.switch_camera(camera_id):
        em.resolve_current_event("switch")


func _use_cm() -> void:
    if gm.use_cm():
        em.resolve_current_event("cm")


func _toggle_mute() -> void:
    if gm.toggle_mute():
        em.resolve_current_event("mute")


func _toggle_telop() -> void:
    if gm.toggle_telop():
        em.resolve_current_event("telop")


func _on_camera_changed(camera_id: int) -> void:
    update_onair(camera_id)
    update_camera_states()


func update_onair(camera_id: int) -> void:
    var camera := cameras.get(camera_id) as BroadcastCamera
    if camera == null:
        return

    onair_feed.color = camera.get_preview_color()
    onair_camera_label.text = "ON AIR  /  CAM%d" % camera_id


func update_camera_states() -> void:
    for camera_id in range(1, 4):
        var camera := cameras[camera_id] as BroadcastCamera
        camera.set_on_air(camera_id == gm.current_camera)


func _on_event_started(event: TVEvent) -> void:
    var camera := cameras[event.camera] as BroadcastCamera
    camera.set_state("warning")
    camera.pulse()
    director_label.text = director_ai.get_advice(event.id, event.phase)
    onair_status_label.text = "WARNING: %s" % event.label


func _on_event_phase_changed(event: TVEvent) -> void:
    var camera := cameras[event.camera] as BroadcastCamera

    match event.phase:
        TVEvent.Phase.ACCIDENT:
            camera.set_state("danger")
            camera.shake()
            onair_status_label.text = "INCIDENT: %s" % event.label
        TVEvent.Phase.AFTERMATH:
            camera.set_state("resolved" if event.success else "danger")
            onair_status_label.text = "RESOLVED" if event.success else "FAILED"

    director_label.text = director_ai.get_advice(event.id, event.phase)


func _on_event_ended(event: TVEvent) -> void:
    var camera := cameras[event.camera] as BroadcastCamera
    camera.set_state("normal")
    director_label.text = director_ai.get_random_idle_comment()
    onair_status_label.text = "LIVE"


func _on_score_changed() -> void:
    hud.update_labels()


func _on_rating_changed() -> void:
    hud.update_labels()


func _on_accident_changed() -> void:
    hud.update_labels()


func _on_game_ended() -> void:
    var result := score_manager.calculate_final_score()
    result_score.text = "TOTAL SCORE  %06d" % int(result["total_score"])
    result_rating.text = "視聴率  %d%%" % int(result["rating"])
    result_accident.text = "事故度  %d%%" % int(result["accident"])
    result_bonus.text = "安全運行ボーナス  +%d" % int(result["bonus"])
    result_screen.visible = true


func _update_control_status() -> void:
    if gm == null:
        return

    var cooldown_text := "READY" if gm.cm_cooldown <= 0.0 else "%.1fs" % gm.cm_cooldown
    control_status.text = "CM残り %d / %s    MUTE %s    TELOP %s" % [
        gm.cm_count,
        cooldown_text,
        "ON" if gm.is_muted else "OFF",
        "ON" if gm.is_telop_on else "OFF",
    ]

    if buttons.is_empty():
        return

    buttons["cm"].disabled = gm.game_state != GameManager.GameState.PLAYING or gm.cm_count <= 0 or gm.cm_cooldown > 0.0
    buttons["mute"].text = "M  MUTE: %s" % ("ON" if gm.is_muted else "OFF")
    buttons["telop"].text = "T  TELOP: %s" % ("ON" if gm.is_telop_on else "OFF")


func _reset_camera_states() -> void:
    for camera_id in range(1, 4):
        var camera := cameras[camera_id] as BroadcastCamera
        camera.set_state("normal")
    onair_status_label.text = "LIVE"


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("cam1"):
        _select_camera(1)
    elif event.is_action_pressed("cam2"):
        _select_camera(2)
    elif event.is_action_pressed("cam3"):
        _select_camera(3)
    elif event.is_action_pressed("cm"):
        _use_cm()
    elif event.is_action_pressed("mute"):
        _toggle_mute()
    elif event.is_action_pressed("telop"):
        _toggle_telop()
