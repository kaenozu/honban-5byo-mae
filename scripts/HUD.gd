extends Control
class_name HUD

@onready var time_label: Label = $TimeLeft
@onready var score_label: Label = $ScoreValue
@onready var rating_label: Label = $RatingValue
@onready var accident_label: Label = $AccidentValue
@onready var gm: GameManager = get_parent().get_node("GameManager") as GameManager


func _ready() -> void:
    gm.score_changed.connect(update_labels)
    gm.rating_changed.connect(update_labels)
    gm.accident_changed.connect(update_labels)
    update_labels()


func _process(_delta: float) -> void:
    if gm != null:
        time_label.text = "%02d" % int(ceil(gm.time_left))


func update_labels() -> void:
    if gm == null:
        return

    time_label.text = "%02d" % int(ceil(gm.time_left))
    score_label.text = "%06d" % gm.score
    rating_label.text = "%d%%" % gm.rating
    accident_label.text = "%d%%" % gm.accident
