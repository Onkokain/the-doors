extends CenterContainer
@onready var achievements: TextureButton = $VBoxContainer/Panel2/achievements
@onready var rooms_visited: TextureButton = $"VBoxContainer/Panel3/Rooms Visited"
@onready var return_back: TextureButton = $VBoxContainer/Panel4/Return
@onready var rooms_list: Panel = $"../rooms_list"
@onready var statistics: CenterContainer = $"."
@onready var panel: Panel = $"../Panel"



var button_type = null
var hover_tweens := {}
var hovered_cards := {}
var pressed_cards := {}	

func _ready() -> void:
	rooms_list.visible=false
	_configure_hover(return_back)
	_configure_hover(rooms_visited)
	_configure_hover(achievements)
	

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



	


func _on_rooms_visited_pressed() -> void:
	rooms_list.visible=true
	statistics.visible=false
	panel.visible=false
	

func _on_return_inside_door_list_pressed() -> void:
	rooms_list.visible=false
	statistics.visible=true
	panel.visible=true
