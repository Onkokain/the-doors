extends CenterContainer

const BUTTON_HOVER_SOUND = preload("res://assets/music/button_hover.mp3")
const BUTTON_PRESS_SOUND = preload("res://assets/music/button_press.mp3")
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
var configured_buttons := {}
var hover_player: AudioStreamPlayer
var press_player: AudioStreamPlayer


func _ready() -> void:
	visuals_menu.visible = false
	controls_menu.visible = false
	_setup_ui_sound_players()

	_configure_buttons_in(self)


func _configure_buttons_in(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton:
			_configure_hover(child)
		_configure_buttons_in(child)


func _configure_hover(button: BaseButton) -> void:
	if configured_buttons.has(button):
		return

	configured_buttons[button] = true
	var card := _resolve_card(button)
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
	button.button_down.connect(_on_button_down.bind(card))
	button.button_up.connect(_set_button_pressed.bind(card, false))


func _resolve_card(button: BaseButton) -> Control:
	var parent := button.get_parent() as Control
	if parent is PanelContainer or parent is Panel:
		return parent
	return button as Control


func _find_card_label(button: BaseButton) -> Label:
	for child in button.get_children():
		if child is Label:
			return child
	return null


func _sync_card_pivot(card: Control) -> void:
	card.pivot_offset = card.size / 2.0


func _setup_ui_sound_players() -> void:
	hover_player = AudioStreamPlayer.new()
	hover_player.stream = BUTTON_HOVER_SOUND
	hover_player.bus = &"effects"
	add_child(hover_player)

	press_player = AudioStreamPlayer.new()
	press_player.stream = BUTTON_PRESS_SOUND
	press_player.bus = &"effects"
	add_child(press_player)


func _set_button_hover(card: Control, hovered: bool) -> void:
	var was_hovered: bool = hovered_cards.get(card, false)
	hovered_cards[card] = hovered

	if hovered and not was_hovered:
		_play_ui_hover()

	_update_button_state(card)


func _set_button_pressed(card: Control, pressed: bool) -> void:
	pressed_cards[card] = pressed
	_update_button_state(card)


func _on_button_down(card: Control) -> void:
	_set_button_pressed(card, true)
	_play_ui_press()


func _update_button_state(card: Control) -> void:
	_sync_card_pivot(card)

	var existing: Tween = hover_tweens.get(card) as Tween
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


func _play_ui_hover() -> void:
	if hover_player != null:
		hover_player.play()


func _play_ui_press() -> void:
	if press_player != null:
		press_player.play()


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
