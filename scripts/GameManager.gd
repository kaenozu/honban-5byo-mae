extends Node
class_name GameManager

signal score_changed
signal camera_changed(camera_id: int)
signal rating_changed
signal accident_changed
signal cm_changed
signal mode_changed
signal game_ended

enum GameState { IDLE, PLAYING, ENDED }

const GAME_DURATION := 90.0
const CM_COOLDOWN_DURATION := 10.0
const INITIAL_RATING := 40

var time_left: float = GAME_DURATION
var score: int = 0
var rating: int = INITIAL_RATING
var accident: int = 0
var current_camera: int = 1
var cm_count: int = 2
var cm_cooldown: float = 0.0
var is_muted: bool = false
var is_telop_on: bool = false
var game_state: GameState = GameState.IDLE


func _process(delta: float) -> void:
    if game_state != GameState.PLAYING:
        return

    time_left = maxf(0.0, time_left - delta)

    if cm_cooldown > 0.0:
        var previous_cooldown := cm_cooldown
        cm_cooldown = maxf(0.0, cm_cooldown - delta)
        if previous_cooldown > 0.0 and is_zero_approx(cm_cooldown):
            cm_changed.emit()

    if is_zero_approx(time_left):
        end_game()


func start_game() -> void:
    _reset_values()
    game_state = GameState.PLAYING
    _emit_full_state()


func reset_for_restart() -> void:
    _reset_values()
    game_state = GameState.IDLE
    _emit_full_state()


func reset_event_modes() -> void:
    if not is_muted and not is_telop_on:
        return

    is_muted = false
    is_telop_on = false
    mode_changed.emit()


func switch_camera(camera_id: int) -> bool:
    if game_state != GameState.PLAYING or camera_id < 1 or camera_id > 3:
        return false
    if current_camera == camera_id:
        return false

    current_camera = camera_id
    camera_changed.emit(camera_id)
    return true


func use_cm() -> bool:
    if game_state != GameState.PLAYING:
        return false
    if cm_count <= 0 or cm_cooldown > 0.0:
        return false

    cm_count -= 1
    cm_cooldown = CM_COOLDOWN_DURATION
    cm_changed.emit()
    return true


func toggle_mute() -> bool:
    if game_state != GameState.PLAYING:
        return false

    is_muted = not is_muted
    mode_changed.emit()
    return true


func toggle_telop() -> bool:
    if game_state != GameState.PLAYING:
        return false

    is_telop_on = not is_telop_on
    mode_changed.emit()
    return true


func add_score(value: int) -> void:
    score += value
    score_changed.emit()


func add_rating(value: int) -> void:
    rating = clampi(rating + value, 0, 100)
    rating_changed.emit()


func add_accident(value: int) -> void:
    accident = clampi(accident + value, 0, 100)
    accident_changed.emit()


func end_game() -> void:
    if game_state == GameState.ENDED:
        return

    game_state = GameState.ENDED
    game_ended.emit()


func _reset_values() -> void:
    time_left = GAME_DURATION
    score = 0
    rating = INITIAL_RATING
    accident = 0
    current_camera = 1
    cm_count = 2
    cm_cooldown = 0.0
    is_muted = false
    is_telop_on = false


func _emit_full_state() -> void:
    score_changed.emit()
    camera_changed.emit(current_camera)
    rating_changed.emit()
    accident_changed.emit()
    cm_changed.emit()
    mode_changed.emit()
