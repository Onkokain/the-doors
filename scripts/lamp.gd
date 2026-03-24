extends Node3D
@onready var lamp_audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

@onready var omni_light_3d: OmniLight3D = $OmniLight3D
@onready var label_3d: Label3D = $Area3D/Label3D

var is_player_inside: bool = false
var is_flickering: bool = false # Prevents spamming the toggle during the animation

func _ready() -> void:
	label_3d.visible = false
	omni_light_3d.light_energy = 8.0

func _process(_delta: float) -> void:
	if is_player_inside and Input.is_action_just_pressed("interact") and not is_flickering:
		toggle_light()
		lamp_audio.play()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_inside = true
		label_3d.visible = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_inside = false
		label_3d.visible = false

func toggle_light() -> void:
	if omni_light_3d.light_energy > 0:
		# Instant OFF for a clean "click" feel
		omni_light_3d.light_energy = 0.0
	else:
		# Start the flicker effect for turning it ON
		run_flicker_effect()

func run_flicker_effect() -> void:
	is_flickering = true
	var tween = create_tween()
	
	# Flicker sequence: On (dim) -> Off -> On (bright) -> Off -> Final On (8.0)
	tween.tween_property(omni_light_3d, "light_energy", 2.0, 0.05)
	tween.tween_property(omni_light_3d, "light_energy", 0.0, 0.05)
	tween.tween_property(omni_light_3d, "light_energy", 5.0, 0.07)
	tween.tween_property(omni_light_3d, "light_energy", 0.0, 0.05)
	tween.tween_property(omni_light_3d, "light_energy", 8.0, 0.03)
	
	# Re-enable interaction once the flicker finishes
	await tween.finished
	is_flickering = false
