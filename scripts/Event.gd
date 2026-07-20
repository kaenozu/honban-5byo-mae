extends Resource
class_name TVEvent

enum Phase { NORMAL, WARNING, ACCIDENT, AFTERMATH }

var id: String = ""
var camera: int = 1
var phase: Phase = Phase.NORMAL
var timer: float = 0.0
var solution: String = "switch"
var warning_duration: float = 3.0
var accident_duration: float = 4.0
var aftermath_duration: float = 3.0
var severity: int = 10
var rating_bonus: int = 4
var label: String = ""
var description: String = ""
var resolved: bool = false
var success: bool = false
var reaction_time: float = 0.0
var resolved_phase: String = ""
var action: String = "none"
var score_delta: int = 0
var rating_delta: int = 0
var accident_delta: int = 0


func is_expired() -> bool:
    return phase == Phase.AFTERMATH and timer >= aftermath_duration


func to_result_dictionary() -> Dictionary:
    return {
        "event_id": id,
        "label": label,
        "success": success,
        "reaction_time": reaction_time,
        "resolved_phase": resolved_phase,
        "action": action,
        "score_delta": score_delta,
        "rating_delta": rating_delta,
        "accident_delta": accident_delta,
    }


static func phase_to_string(phase_value: int) -> String:
    match phase_value:
        Phase.WARNING:
            return "WARNING"
        Phase.ACCIDENT:
            return "ACCIDENT"
        Phase.AFTERMATH:
            return "AFTERMATH"
        _:
            return "NORMAL"
