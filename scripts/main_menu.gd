extends Node2D

# Preloading the scene into memory
const MAIN_SCENE = preload("res://scenes/main.tscn")

@onready var start: TextureButton = $CenterContainer/VBoxContainer/Panel/start
@onready var settings: TextureButton = $CenterContainer/VBoxContainer/Panel2/settings
@onready var cutscene: TextureButton = $CenterContainer/VBoxContainer/Panel3/cutscene
@onready var endgame: TextureButton = $CenterContainer/VBoxContainer/Panel4/endgame

var button_type = null
var hover_tweens := {}
var hovered_cards := {}
var pressed_cards := {}	

func _ready() -> void:
	_configure_hover(start)
	_configure_hover(settings)
	_configure_hover(cutscene)
	_configure_hover(endgame)
	
	# Connecting the signal via code
	start.pressed.connect(_on_start_pressed)

func _configure_hover(button: TextureButton) -> void:
	var card := button.get_parent() as Control
	hovered_cards[card] = false
	pressed_cards[card] = false
	_sync_card_pivot(card)
	card.resized.connect(_sync_card_pivot.bind(card))
	
	button.mouse_entered.connect(_set_button_hover.bind(card, true))
	button.mouse_exited.connect(_set_button_hover.bind(card, false))
	button.focus_entered.connect(_set_button_hover.bind(card, true))
	button.focus_exited.connect(_set_button_hover.bind(card, false))
	button.button_down.connect(_set_button_pressed.bind(card, true))
	button.button_up.connect(_set_button_pressed.bind(card, false))
	
func _sync_card_pivot(card: Control) -> void:
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

	var target_scale := Vector2.ONE
	if pressed_cards.get(card, false):
		target_scale *= 0.94
	elif hovered_cards.get(card, false):
		target_scale *= 1.06

	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hover_tweens[card] = tween
	tween.tween_property(card, "scale", target_scale, 0.12)
	
func _on_start_pressed() -> void:
	# Using change_scene_to_packed since we already preloaded it
	get_tree().change_scene_to_packed(MAIN_SCENE)
