extends CenterContainer

const CARD_NORMAL_TINT := Color(1.0, 1.0, 1.0, 0.96)
const CARD_HOVER_TINT := Color(1.0, 0.9, 0.92, 1.0)
const CARD_PRESSED_TINT := Color(1.0, 0.82, 0.86, 1.0)
const LABEL_NORMAL_TINT := Color(1.0, 1.0, 1.0, 1.0)
const LABEL_HOVER_TINT := Color(1.08, 0.92, 0.94, 1.0)

@onready var achievements: TextureButton = $VBoxContainer/Panel2/achievements
@onready var rooms_visited: TextureButton = $"VBoxContainer/Panel3/Rooms Visited"
@onready var return_back: TextureButton = $VBoxContainer/Panel4/Return
@onready var rooms_list: Panel = $"../rooms_list"
@onready var statistics: CenterContainer = $"."
@onready var panel: Panel = $"../Panel"

var hover_tweens := {}
var hovered_cards := {}
var pressed_cards := {}
var card_labels := {}


func _ready() -> void:
	rooms_list.visible = false

	for button in [return_back, rooms_visited, achievements]:
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


func _on_rooms_visited_pressed() -> void:
	rooms_list.visible = true
	statistics.visible = false


func _on_return_inside_door_list_pressed() -> void:
	rooms_list.visible = false
	statistics.visible = true
