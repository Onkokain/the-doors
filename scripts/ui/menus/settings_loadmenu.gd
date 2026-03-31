extends CenterContainer

const CARD_NORMAL_TINT := Color(1.0, 1.0, 1.0, 0.96)
const CARD_HOVER_TINT := Color(1.0, 0.9, 0.92, 1.0)
const CARD_PRESSED_TINT := Color(1.0, 0.82, 0.86, 1.0)
const LABEL_NORMAL_TINT := Color(1.0, 1.0, 1.0, 1.0)
const LABEL_HOVER_TINT := Color(1.08, 0.92, 0.94, 1.0)

@onready var visuals: TextureButton = $VBoxContainer/Panel2/visuals
@onready var audio: TextureButton = $VBoxContainer/Panel3/Audio
@onready var settings_return: TextureButton = $VBoxContainer/Panel4/Return
@onready var visuals_menu: Node2D = $visuals_menu
@onready var controls_menu: Node2D = $controls_menu
@onready var settings: VBoxContainer = $VBoxContainer
@onready var return_inside_audio: TextureButton = $visuals_menu/Panel4/Return_inside_audio
@onready var return_inside_control: TextureButton = $controls_menu/return/return_inside_control
@onready var frame: PanelContainer = $Frame

var hover_tweens := {}
var hovered_cards := {}
var pressed_cards := {}
var card_labels := {}


func _ready() -> void:
	visuals_menu.visible = false
	controls_menu.visible = false

	for button in [settings_return, audio, visuals, return_inside_audio, return_inside_control]:
		_configure_hover(button)


func _configure_hover(button: TextureButton) -> void:
	var card := button.get_parent() as Control
	if card == null:
		return

	hovered_cards[card] = false
	pressed_cards[card] = false
	card_labels[card] = _find_card_label(button)
	_sync_card_pivot(card)
	card.resized.connect(_sync_card_pivot.bind(card))

	button.mouse_entered.connect(_set_button_hover.bind(card, true))
	button.mouse_exited.connect(_set_button_hover.bind(card, false))
	button.focus_entered.connect(_set_button_hover.bind(card, true))
	button.focus_exited.connect(_set_button_hover.bind(card, false))
	button.button_down.connect(_set_button_pressed.bind(card, true))
	button.button_up.connect(_set_button_pressed.bind(card, false))


func _find_card_label(button: TextureButton) -> Label:
	for child in button.get_children():
		if child is Label:
			return child
	return null


func _sync_card_pivot(card: Control) -> void:
	card.pivot_offset = card.size / 2.0


func _set_button_hover(card: Control, hovered: bool) -> void:
	hovered_cards[card] = hovered
	_update_button_state(card)


func _set_button_pressed(card: Control, pressed: bool) -> void:
	pressed_cards[card] = pressed
	_update_button_state(card)


func _update_button_state(card: Control) -> void:
	_sync_card_pivot(card)

	var existing: Tween = hover_tweens.get(card)
	if existing != null:
		existing.kill()

	var target_scale := Vector2.ONE
	var target_tint := CARD_NORMAL_TINT
	var label_tint := LABEL_NORMAL_TINT

	if pressed_cards.get(card, false):
		target_scale = Vector2.ONE * 0.95
		target_tint = CARD_PRESSED_TINT
		label_tint = LABEL_HOVER_TINT
	elif hovered_cards.get(card, false):
		target_scale = Vector2.ONE * 1.04
		target_tint = CARD_HOVER_TINT
		label_tint = LABEL_HOVER_TINT

	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hover_tweens[card] = tween
	tween.parallel().tween_property(card, "scale", target_scale, 0.14)
	tween.parallel().tween_property(card, "modulate", target_tint, 0.14)

	var label: Label = card_labels.get(card)
	if label != null:
		tween.parallel().tween_property(label, "modulate", label_tint, 0.14)


func _on_visuals_pressed() -> void:
	settings.visible = false
	visuals_menu.visible = true
	frame.visible=false


func _on_audio_pressed() -> void:
	controls_menu.visible = true
	settings.visible = false
	frame.visible=false


func _on_return_inside_audio_pressed() -> void:
	settings.visible = true
	visuals_menu.visible = false
	frame.visible=true


func _on_return_inside_control_pressed() -> void:
	controls_menu.visible = false
	settings.visible = true
	frame.visible=true
