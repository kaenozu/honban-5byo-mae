extends Node
class_name EventManager

signal event_started(event: TVEvent)
signal event_phase_changed(event: TVEvent)
signal event_ended(event: TVEvent)

@onready var gm: GameManager = get_parent().get_node("GameManager") as GameManager
@onready var score_manager: ScoreManager = get_parent().get_node("ScoreManager") as ScoreManager

var events: Array[TVEvent] = []
var timeline: Array[Dictionary] = []
var elapsed: float = 0.0
var current_event: TVEvent = null
var event_index: int = 0


func _ready() -> void:
    load_events()


func load_events() -> void:
    timeline.clear()

    var file := FileAccess.open("res://data/events.json", FileAccess.READ)
    if file == null:
        push_error("events.json not found")
        return

    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()

    if typeof(parsed) != TYPE_ARRAY:
        push_error("events.json must contain a JSON array")
        return

    for entry: Variant in parsed:
        if typeof(entry) == TYPE_DICTIONARY:
            var entry_data: Dictionary = entry
            timeline.append(entry_data)

    timeline.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a.get("time", 0.0)) < float(b.get("time", 0.0))
    )


func _process(delta: float) -> void:
    if gm == null or gm.game_state != GameManager.GameState.PLAYING:
        return

    elapsed += delta

    while event_index < timeline.size() and elapsed >= float(timeline[event_index].get("time", INF)):
        spawn_event(timeline[event_index])
        event_index += 1

    if current_event != null:
        update_event(delta)


func spawn_event(data: Dictionary) -> void:
    if current_event != null:
        _resolve_as_failure()
        _finish_current_event()

    var event := TVEvent.new()
    event.id = str(data.get("id", "unknown"))
    event.camera = clampi(int(data.get("camera", 1)), 1, 3)
    event.solution = str(data.get("solution", "switch"))
    event.warning_duration = maxf(0.1, float(data.get("warning_duration", 3.0)))
    event.accident_duration = maxf(0.1, float(data.get("accident_duration", 4.0)))
    event.aftermath_duration = maxf(0.1, float(data.get("aftermath_duration", 3.0)))
    event.severity = clampi(int(data.get("severity", 10)), 0, 100)
    event.rating_bonus = int(data.get("rating_bonus", 4))
    event.label = str(data.get("label", event.id))
    event.description = str(data.get("description", ""))
    event.phase = TVEvent.Phase.WARNING
    event.timer = 0.0

    current_event = event
    events.append(event)
    event_started.emit(event)


func update_event(delta: float) -> void:
    current_event.timer += delta

    match current_event.phase:
        TVEvent.Phase.WARNING:
            if current_event.timer >= current_event.warning_duration:
                current_event.phase = TVEvent.Phase.ACCIDENT
                current_event.timer = 0.0
                event_phase_changed.emit(current_event)
        TVEvent.Phase.ACCIDENT:
            if current_event.timer >= current_event.accident_duration:
                _resolve_as_failure()
        TVEvent.Phase.AFTERMATH:
            if current_event.is_expired():
                _finish_current_event()


func resolve_current_event(action: String) -> bool:
    if current_event == null:
        return false
    if current_event.phase != TVEvent.Phase.WARNING and current_event.phase != TVEvent.Phase.ACCIDENT:
        return false

    var success := false
    match current_event.solution:
        "switch":
            success = action == "switch" and gm.current_camera != current_event.camera
        "cm":
            success = action == "cm"
        "mute":
            success = action == "mute" and gm.is_muted
        "telop":
            success = action == "telop" and gm.is_telop_on

    if not success:
        return false

    current_event.resolved = true
    current_event.success = true
    score_manager.resolve_event(true, current_event)
    current_event.phase = TVEvent.Phase.AFTERMATH
    current_event.timer = 0.0
    event_phase_changed.emit(current_event)
    return true


func cleanup() -> void:
    current_event = null
    events.clear()
    event_index = 0
    elapsed = 0.0


func _resolve_as_failure() -> void:
    if current_event == null or current_event.resolved:
        return

    current_event.resolved = true
    current_event.success = false
    score_manager.resolve_event(false, current_event)
    current_event.phase = TVEvent.Phase.AFTERMATH
    current_event.timer = 0.0
    event_phase_changed.emit(current_event)


func _finish_current_event() -> void:
    if current_event == null:
        return

    var finished := current_event
    current_event = null
    event_ended.emit(finished)
