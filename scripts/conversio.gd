extends Node
@onready var heartbeat: AudioStreamPlayer2D = $"../Utilities/heartbeat"
@onready var bloodred: AnimationPlayer = $"../Utilities/red flash/AnimationPlayer"

var was_conversio: bool = false

func _process(_delta: float) -> void:
	if Global.is_conversio:
		if not was_conversio:
			conversio()
	else:
		if was_conversio:
			conversio_disable()
	was_conversio = Global.is_conversio

func conversio():
	if not heartbeat.playing:
		heartbeat.play()
		await get_tree().create_timer(5).timeout
		bloodred.play("pulse")
	
func conversio_disable():
	if heartbeat.playing:
		heartbeat.stop()
		bloodred.stop()
