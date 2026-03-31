extends Label
@onready var coins: Label = $"."

func _process(_delta: float) -> void:
	coins.text=str(Global.coins)
