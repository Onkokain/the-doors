extends StaticBody3D

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var prompt: Label3D = $"../Detection Area/Prompt"

var is_open := false
var interactable := true
var is_player_in_range := false
var is_player_inside_closet := false


func _ready() -> void:
	_update_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and is_player_in_range and interactable:
		interact()


func interact() -> void:
	if not interactable:
		return

	interactable = false
	_update_prompt()

	var open_animation := "open_full"
	var close_animation := "close_full"

	if is_player_inside_closet:
		open_animation = "open"
		close_animation = "close"

	if is_open:
		animation_player.play(close_animation)
	else:
		animation_player.play(open_animation)

	await animation_player.animation_finished

	is_open = not is_open
	interactable = true
	_update_prompt()


func _update_prompt() -> void:
	prompt.visible = is_player_in_range and interactable


func _on_detection_area_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_in_range = true
		_update_prompt()


func _on_detection_area_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_in_range = false
		_update_prompt()
		



func _on_inside_closet_detection_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_inside_closet = true


func _on_inside_closet_detection_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_inside_closet = false
