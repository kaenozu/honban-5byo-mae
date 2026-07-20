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


func is_expired() -> bool:
    return phase == Phase.AFTERMATH and timer >= aftermath_duration
