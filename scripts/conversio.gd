extends Node

@onready var heartbeat: AudioStreamPlayer2D = $heartbeat
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
	
func conversio_disable():
	if heartbeat.playing:
		heartbeat.stop()
