extends Control
class_name Main

@onready var gm: GameManager = $GameManager
@onready var score_manager: ScoreManager = $ScoreManager
@onready var em: EventManager = $EventManager
@onready var director_ai: DirectorAI = $DirectorAI
@onready var start_screen: StartScreen = $StartScreen
@onready var onair_display: Control = $OnAirDisplay
@onready var onair_feed: ColorRect = $OnAirDisplay/Feed
@onready var onair_incident_overlay: ColorRect = $OnAirDisplay/IncidentOverlay
@onready var onair_incident_icon: Label = $OnAirDisplay/IncidentIcon
@onready var onair_camera_label: Label = $OnAirDisplay/CameraLabel
@onready var onair_status_label: Label = $OnAirDisplay/StatusLabel
@onready var onair_mute_badge: Label = $OnAirDisplay/MuteBadge
@onready var onair_telop_bar: ColorRect = $OnAirDisplay/TelopBar
@onready var onair_telop_text: Label = $OnAirDisplay/TelopBar/Text
@onready var onair_cm_card: Control = $OnAirDisplay/CMCard
@onready var director_label: Label = $DirectorPanel/AdviceLabel
@onready var control_status: Label = $ControlPanel/StatusLabel
@onready var result_screen: Control = $ResultScreen
@onready var result_score: Label = $ResultScreen/ResultPanel/ResultVBox/ResultScore
@onready var result_rating: Label = $ResultScreen/ResultPanel/ResultVBox/ResultRating
@onready var result_accident: Label = $ResultScreen/ResultPanel/ResultVBox/ResultAccident
@onready var result_bonus: Label = $ResultScreen/ResultPanel/ResultVBox/ResultBonus
@onready var result_event_results: VBoxContainer = $ResultScreen/ResultPanel/ResultVBox/EventResultsScroll/EventResults

var cameras: Dictionary = {}
var buttons: Dictionary = {}
var warning_tween: Tween = null
var onair_shake_tween: Tween = null
var onair_base_position: Vector2
var cm_card_token: int = 0


func _ready() -> void:
    setup_cameras()
    setup_buttons()
    setup_signals()
    onair_base_position = onair_display.position
    result_screen.visible = false
    onair_cm_card.visible = false
    _prepare_start()


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
    $ResultScreen/ResultPanel/ResultVBox/RestartButton.pressed.connect(_prepare_start)


func setup_signals() -> void:
    start_screen.countdown_finished.connect(_start_game)
    gm.camera_changed.connect(_on_camera_changed)
    gm.cm_changed.connect(_update_control_status)
    gm.mode_changed.connect(_on_mode_changed)
    gm.game_ended.connect(_on_game_ended)
    em.event_started.connect(_on_event_started)
    em.event_phase_changed.connect(_on_event_phase_changed)
    em.event_ended.connect(_on_event_ended)


func _prepare_start() -> void:
    cm_card_token += 1
    em.cleanup()
    gm.reset_for_restart()
    result_screen.visible = false
    onair_cm_card.visible = false
    director_label.text = "プレビューを見ろ。事故の兆候を逃すな"
    _reset_camera_states()
    _on_camera_changed(gm.current_camera)
    _on_mode_changed()
    _clear_result_rows()
    start_screen.show_ready()


func _start_game() -> void:
    gm.start_game()
    director_label.text = "プレビューを見ろ。事故の兆候を逃すな"
    _reset_camera_states()
    _on_camera_changed(gm.current_camera)
    _on_mode_changed()
    _update_control_status()


func _select_camera(camera_id: int) -> void:
    _animate_button(buttons[camera_id] as Button)
    if gm.switch_camera(camera_id):
        em.resolve_current_event("switch")


func _use_cm() -> void:
    _animate_button(buttons["cm"] as Button)
    if gm.use_cm():
        _show_cm_card()
        em.resolve_current_event("cm")


func _toggle_mute() -> void:
    _animate_button(buttons["mute"] as Button)
    if gm.toggle_mute():
        em.resolve_current_event("mute")


func _toggle_telop() -> void:
    _animate_button(buttons["telop"] as Button)
    if gm.toggle_telop():
        em.resolve_current_event("telop")


func _on_camera_changed(camera_id: int) -> void:
    update_onair(camera_id)
    update_camera_states()
    _refresh_onair_event_state(true)


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
    _refresh_onair_event_state()
    _on_mode_changed()


func _on_event_phase_changed(event: TVEvent) -> void:
    var camera := cameras[event.camera] as BroadcastCamera

    match event.phase:
        TVEvent.Phase.ACCIDENT:
            camera.set_state("danger")
            camera.shake()
        TVEvent.Phase.AFTERMATH:
            camera.set_state("resolved" if event.success else "danger")

    director_label.text = director_ai.get_advice(event.id, event.phase)
    _refresh_onair_event_state(true)
    _on_mode_changed()


func _on_event_ended(event: TVEvent) -> void:
    var camera := cameras[event.camera] as BroadcastCamera
    camera.set_state("normal")
    director_label.text = director_ai.get_random_idle_comment()
    _refresh_onair_event_state()
    _on_mode_changed()


func _on_mode_changed() -> void:
    _update_control_status()
    onair_mute_badge.visible = gm.is_muted
    onair_telop_bar.visible = gm.is_telop_on

    if gm.is_telop_on:
        var event := em.current_event
        if event != null and not event.description.is_empty():
            onair_telop_text.text = event.description
        else:
            onair_telop_text.text = "本番5秒前　生放送中"


func _on_game_ended() -> void:
    var result := score_manager.calculate_final_score()
    result_score.text = "TOTAL SCORE  %06d" % int(result["total_score"])
    result_rating.text = "視聴率  %d%%" % int(result["rating"])
    result_accident.text = "事故度  %d%%" % int(result["accident"])
    result_bonus.text = "安全運行ボーナス  +%d" % int(result["bonus"])
    _populate_event_results()
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

    var is_playing := gm.game_state == GameManager.GameState.PLAYING
    for camera_id in range(1, 4):
        (buttons[camera_id] as Button).disabled = not is_playing

    buttons["cm"].disabled = not is_playing or gm.cm_count <= 0 or gm.cm_cooldown > 0.0
    buttons["mute"].disabled = not is_playing
    buttons["telop"].disabled = not is_playing
    buttons["mute"].text = "M  MUTE: %s" % ("ON" if gm.is_muted else "OFF")
    buttons["telop"].text = "T  TELOP: %s" % ("ON" if gm.is_telop_on else "OFF")
    buttons["mute"].modulate = Color(0.68, 1.0, 0.78, 1.0) if gm.is_muted else Color(1, 1, 1, 1)
    buttons["telop"].modulate = Color(0.68, 1.0, 0.78, 1.0) if gm.is_telop_on else Color(1, 1, 1, 1)


func _reset_camera_states() -> void:
    for camera_id in range(1, 4):
        var camera := cameras[camera_id] as BroadcastCamera
        camera.set_state("normal")

    _stop_warning_pulse()
    if onair_shake_tween != null and onair_shake_tween.is_valid():
        onair_shake_tween.kill()
    onair_display.position = onair_base_position
    onair_incident_overlay.visible = false
    onair_incident_icon.visible = false
    onair_status_label.text = "LIVE"


func _refresh_onair_event_state(allow_shake: bool = false) -> void:
    _stop_warning_pulse()
    if onair_shake_tween != null and onair_shake_tween.is_valid():
        onair_shake_tween.kill()
    onair_shake_tween = null
    onair_incident_overlay.visible = false
    onair_incident_icon.visible = false
    onair_incident_overlay.modulate = Color(1, 1, 1, 1)
    onair_display.position = onair_base_position

    var event := em.current_event
    if event == null or event.camera != gm.current_camera:
        onair_status_label.text = "LIVE"
        return

    onair_incident_icon.text = _event_icon_text(event.id)
    onair_incident_icon.visible = true

    match event.phase:
        TVEvent.Phase.WARNING:
            onair_incident_overlay.color = Color(1.0, 0.72, 0.08, 0.32)
            onair_incident_overlay.visible = true
            onair_status_label.text = "WARNING: %s" % event.label
            _start_warning_pulse()
        TVEvent.Phase.ACCIDENT:
            onair_incident_overlay.color = Color(0.92, 0.08, 0.08, 0.52)
            onair_incident_overlay.visible = true
            onair_status_label.text = "INCIDENT: %s" % event.label
            if allow_shake:
                _shake_onair()
        TVEvent.Phase.AFTERMATH:
            onair_incident_overlay.color = Color(0.16, 0.72, 0.32, 0.24) if event.success else Color(0.92, 0.08, 0.08, 0.44)
            onair_incident_overlay.visible = true
            onair_incident_icon.text = "RESOLVED" if event.success else "FAILED"
            onair_status_label.text = "RESOLVED" if event.success else "FAILED"
        _:
            onair_status_label.text = "LIVE"


func _start_warning_pulse() -> void:
    onair_incident_overlay.modulate.a = 0.35
    warning_tween = create_tween().set_loops()
    warning_tween.tween_property(onair_incident_overlay, "modulate:a", 1.0, 0.35)
    warning_tween.tween_property(onair_incident_overlay, "modulate:a", 0.35, 0.35)


func _stop_warning_pulse() -> void:
    if warning_tween != null and warning_tween.is_valid():
        warning_tween.kill()
    warning_tween = null
    onair_incident_overlay.modulate.a = 1.0


func _shake_onair() -> void:
    if onair_shake_tween != null and onair_shake_tween.is_valid():
        onair_shake_tween.kill()

    onair_display.position = onair_base_position
    onair_shake_tween = create_tween()
    for index in range(8):
        var offset := Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0))
        onair_shake_tween.tween_property(onair_display, "position", onair_base_position + offset, 0.035)
    onair_shake_tween.tween_property(onair_display, "position", onair_base_position, 0.05)


func _show_cm_card() -> void:
    cm_card_token += 1
    var token := cm_card_token
    onair_cm_card.visible = true
    onair_cm_card.modulate.a = 0.0
    onair_cm_card.scale = Vector2(0.96, 0.96)
    onair_cm_card.pivot_offset = onair_cm_card.size * 0.5

    var tween := create_tween().set_parallel(true)
    tween.tween_property(onair_cm_card, "modulate:a", 1.0, 0.12)
    tween.tween_property(onair_cm_card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    await get_tree().create_timer(1.5).timeout
    if token != cm_card_token:
        return

    var hide_tween := create_tween()
    hide_tween.tween_property(onair_cm_card, "modulate:a", 0.0, 0.18)
    await hide_tween.finished
    if token == cm_card_token:
        onair_cm_card.visible = false


func _animate_button(button: Button) -> void:
    button.pivot_offset = button.size * 0.5
    var tween := create_tween()
    tween.tween_property(button, "scale", Vector2(0.94, 0.94), 0.06)
    tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _event_icon_text(event_id: String) -> String:
    match event_id:
        "E03_VOICE":
            return "VOICE\n)))"
        "E11_WIND":
            return "WIND\n>>>>"
        "E01_HORSE":
            return "HORSE\n/\\_/\\"
        "E06_EXPLOSION":
            return "BOOM\n* * *"
        _:
            return "INCIDENT"


func _populate_event_results() -> void:
    _clear_result_rows()

    for result: Dictionary in em.get_event_results():
        var row := Label.new()
        row.custom_minimum_size = Vector2(0, 72)
        row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        row.add_theme_font_size_override("font_size", 17)
        row.text = "%s  [%s]  reaction %.2fs  phase %s  action %s\nscore %s  rating %s  accident %s" % [
            str(result.get("event_id", "unknown")),
            "SUCCESS" if bool(result.get("success", false)) else "FAILED",
            float(result.get("reaction_time", 0.0)),
            str(result.get("resolved_phase", "-")),
            str(result.get("action", "none")),
            _signed_value(int(result.get("score_delta", 0))),
            _signed_value(int(result.get("rating_delta", 0))),
            _signed_value(int(result.get("accident_delta", 0))),
        ]
        result_event_results.add_child(row)


func _clear_result_rows() -> void:
    for child in result_event_results.get_children():
        result_event_results.remove_child(child)
        child.queue_free()


func _signed_value(value: int) -> String:
    return "+%d" % value if value >= 0 else str(value)


func _unhandled_input(event: InputEvent) -> void:
    if gm.game_state != GameManager.GameState.PLAYING:
        return

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
