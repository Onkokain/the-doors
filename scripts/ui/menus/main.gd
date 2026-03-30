extends Panel

var is_already_playing = false
var paused = false

# Using @onready to ensure nodes are loaded
@onready var panel: Panel = self
@onready var container: CenterContainer = $CenterContainer
@onready var quit_game: TextureButton = $"CenterContainer/VBoxContainer/Panel/quit game"
@onready var settings: TextureButton = $CenterContainer/VBoxContainer/Panel2/settings
@onready var achievements: TextureButton = $CenterContainer/VBoxContainer/Panel3/achievements
@onready var statistics_menu: CenterContainer = $"../statistics"
@onready var player: CharacterBody3D = $"../player"
@onready var return_inside_door_list: TextureButton = $"../rooms_list/return/return_inside_door_list"

var spawn_position : Vector3


# Animation dictionaries
var hover_tweens := {}
var hovered_cards := {}
var pressed_cards := {}

func _ready() -> void:
	spawn_position = player.global_position
	statistics_menu.visible=false
	# 1. CRITICAL: Set process mode so this script runs while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 2. Hide everything on startup
	_update_menu_state(false)
	
	# 3. Setup hover effects
	_configure_hover(achievements)
	_configure_hover(quit_game)
	_configure_hover(settings)
	_configure_hover(return_inside_door_list)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()



func _toggle_pause() -> void:
	paused = !paused
	get_tree().paused = paused
	_update_menu_state(paused)
	
	# Sync Background Audio
	if is_instance_valid(Background):
		Background.playing = paused

func _update_menu_state(should_show: bool) -> void:
	# Update the main panel
	panel.visible = should_show
	
	# Update the container holding the buttons
	if container:
		container.visible = should_show
	
	# Explicitly update button visibility just to be safe
	quit_game.visible = should_show
	settings.visible = should_show
	achievements.visible = should_show

# --- Animation Logic ---

func _configure_hover(button: TextureButton) -> void:
	var card := button.get_parent() as Control
	hovered_cards[card] = false
	pressed_cards[card] = false
	
	# Force sync the pivot right away
	_sync_card_pivot(card)
	card.resized.connect(_sync_card_pivot.bind(card))
	
	button.mouse_entered.connect(_set_button_hover.bind(card, true))
	button.mouse_exited.connect(_set_button_hover.bind(card, false))
	button.focus_entered.connect(_set_button_hover.bind(card, true))
	button.focus_exited.connect(_set_button_hover.bind(card, false))
	button.button_down.connect(_set_button_pressed.bind(card, true))
	button.button_up.connect(_set_button_pressed.bind(card, false))
	
func _sync_card_pivot(card: Control) -> void:
	# Force the UI to calculate its size if it hasn't already
	if card.size == Vector2.ZERO:
		card.force_update_transform()
	card.pivot_offset = card.size / 2.0

func _set_button_hover(card: Control, hovered: bool) -> void:
	hovered_cards[card] = hovered
	_update_button_scale(card)

func _set_button_pressed(card: Control, pressed: bool) -> void:
	pressed_cards[card] = pressed
	_update_button_scale(card)

func _update_button_scale(card: Control) -> void:
	_sync_card_pivot(card)
	
	var existing = hover_tweens.get(card)
	if existing != null:
		existing.kill()

	# Using absolute vectors instead of multiplication for accuracy
	var target_scale := Vector2.ONE
	if pressed_cards.get(card, false):
		target_scale = Vector2(0.90, 0.90) # Punched up the shrink effect here
	elif hovered_cards.get(card, false):
		target_scale = Vector2(1.06, 1.06)

	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# This ensures buttons still "pop" when you hover them in the pause menu
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	
	hover_tweens[card] = tween
	tween.tween_property(card, "scale", target_scale, 0.1) # Snappier animation speed


func _on_quit_game_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/core/main_menu.tscn")
	



func _on_settings_pressed() -> void:
	if player:
		player.global_position=spawn_position
		player.velocity=Vector3.ZERO
		_toggle_pause()
		Global.player_reset_button=true
		await get_tree().create_timer(0.01).timeout
		Global.player_reset_button=false




func _on_achievements_pressed() -> void:
	statistics_menu.visible=true
	container.visible=false


func _on_return_pressed() -> void:
	statistics_menu.visible=false
	container.visible=true
	
	
