extends Node
class_name ScoreManager

const BASE_SUCCESS_SCORE := 500
const WARNING_PHASE_BONUS := 250
const ACCIDENT_PHASE_BONUS := 100
const STREAK_BONUS_STEP := 100
const MAX_STREAK_BONUS := 300
const FAILURE_SCORE := -250
const FAILURE_RATING := -8

@onready var gm: GameManager = get_parent().get_node("GameManager") as GameManager

var consecutive_successes: int = 0


func reset_for_restart() -> void:
    consecutive_successes = 0


func resolve_event(success: bool, event: TVEvent, resolved_phase: int) -> Dictionary:
    var requested_score_delta := 0
    var requested_rating_delta := 0
    var requested_accident_delta := 0

    if success:
        consecutive_successes += 1
        var phase_bonus := WARNING_PHASE_BONUS if resolved_phase == TVEvent.Phase.WARNING else ACCIDENT_PHASE_BONUS
        var streak_bonus := mini((consecutive_successes - 1) * STREAK_BONUS_STEP, MAX_STREAK_BONUS)
        requested_score_delta = BASE_SUCCESS_SCORE + phase_bonus + streak_bonus
        requested_rating_delta = event.rating_bonus
        requested_accident_delta = 0 if resolved_phase == TVEvent.Phase.WARNING else 3
    else:
        consecutive_successes = 0
        requested_score_delta = FAILURE_SCORE
        requested_rating_delta = FAILURE_RATING
        requested_accident_delta = event.severity

    var score_before := gm.score
    var rating_before := gm.rating
    var accident_before := gm.accident

    gm.add_score(requested_score_delta)
    gm.add_rating(requested_rating_delta)
    gm.add_accident(requested_accident_delta)

    return {
        "score_delta": gm.score - score_before,
        "rating_delta": gm.rating - rating_before,
        "accident_delta": gm.accident - accident_before,
        "success_streak": consecutive_successes,
    }


func calculate_final_score() -> Dictionary:
    var bonus := 0
    if gm.accident < 20:
        bonus = 1000
    elif gm.accident < 50:
        bonus = 500

    return {
        "total_score": gm.score + bonus,
        "rating": gm.rating,
        "accident": gm.accident,
        "bonus": bonus,
    }
