extends Node
@onready var heartbeat: AudioStreamPlayer2D = $"../Utilities/heartbeat"
@onready var bloodred: AnimationPlayer = $"../Utilities/red_flash/AnimationPlayer"

var in_effect: bool = false

func _process(_delta: float) -> void:
	if Global.is_conversio:
		if not in_effect:
			conversio()
	else:
		if in_effect:
			conversio_disable()
	in_effect = Global.is_conversio

func conversio():
	if not heartbeat.playing:
		heartbeat.play()
		await get_tree().create_timer(5).timeout
		bloodred.play("pulse")
	
func conversio_disable():
	if heartbeat.playing or bloodred.playing:
		heartbeat.stop()
		bloodred.stop()
