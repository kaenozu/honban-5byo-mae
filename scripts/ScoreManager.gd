extends Node
class_name ScoreManager

@onready var gm: GameManager = get_parent().get_node("GameManager") as GameManager


func resolve_event(success: bool, event: TVEvent) -> void:
    if success:
        gm.add_score(500)
        gm.add_rating(event.rating_bonus)
        gm.add_accident(-10)
    else:
        gm.add_score(-250)
        gm.add_rating(-8)
        gm.add_accident(event.severity)


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
