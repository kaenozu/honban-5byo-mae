extends Node
class_name DirectorAI

var advice_queue: Array[String] = []
var current_advice: String = "プレビューを見ろ"


func get_advice(event_id: String, phase: int) -> String:
    var advice := ""

    match event_id:
        "E03_VOICE":
            match phase:
                TVEvent.Phase.WARNING:
                    advice = "声がおかしい… MUTEを確認"
                TVEvent.Phase.ACCIDENT:
                    advice = "今だ！MUTE！"
                TVEvent.Phase.AFTERMATH:
                    advice = "放送禁止用語だったかも"
        "E11_WIND":
            match phase:
                TVEvent.Phase.WARNING:
                    advice = "CAM2が揺れてる"
                TVEvent.Phase.ACCIDENT:
                    advice = "CAM2を切れ！"
                TVEvent.Phase.AFTERMATH:
                    advice = "強風でセットが…"
        "E01_HORSE":
            match phase:
                TVEvent.Phase.WARNING:
                    advice = "CAM1の後ろに何か…"
                TVEvent.Phase.ACCIDENT:
                    advice = "馬だ！CAMを切れ！"
                TVEvent.Phase.AFTERMATH:
                    advice = "馬は料理セットへ向かった"
        "E06_EXPLOSION":
            match phase:
                TVEvent.Phase.WARNING:
                    advice = "CAM2の鍋が…"
                TVEvent.Phase.ACCIDENT:
                    advice = "CM！CM！"
                TVEvent.Phase.AFTERMATH:
                    advice = "花火みたいだった"
        _:
            match phase:
                TVEvent.Phase.WARNING:
                    advice = "プレビューに注目"
                TVEvent.Phase.ACCIDENT:
                    advice = "今すぐ対処せよ"
                TVEvent.Phase.AFTERMATH:
                    advice = "復旧中…"

    if not advice.is_empty():
        current_advice = advice
    return current_advice


func get_random_idle_comment() -> String:
    var comments: Array[String] = [
        "プレビューを見ろ",
        "CAM2を確認しとけ",
        "油断するな",
        "視聴率が上がってる",
        "ここで一息…",
        "次が来るぞ",
        "CMの準備はいいか",
    ]
    current_advice = comments.pick_random()
    return current_advice
