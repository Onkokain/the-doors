extends CenterContainer
@onready var visuals: TextureButton = $VBoxContainer/Panel2/visuals
@onready var audio: TextureButton = $VBoxContainer/Panel3/Audio
@onready var settings_return: TextureButton = $VBoxContainer/Panel4/Return
@onready var visuals_menu: Node2D = $visuals_menu
@onready var controls_menu: Node2D = $controls_menu
@onready var settings : VBoxContainer = $VBoxContainer
@onready var return_inside_audio: TextureButton = $visuals_menu/Panel4/Return_inside_audio
@onready var return_inside_control: TextureButton = $controls_menu/return/return_inside_control



var button_type = null
var hover_tweens := {}
var hovered_cards := {}
var pressed_cards := {}	

func _ready() -> void:
	visuals_menu.visible=false
	controls_menu.visible=false
	_configure_hover(settings_return)
	_configure_hover(audio)
	_configure_hover(visuals)
	_configure_hover(return_inside_audio)
	_configure_hover(return_inside_control)
	
	

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



	


func _on_visuals_pressed() -> void:
	settings.visible=false
	visuals_menu.visible=true


func _on_audio_pressed() -> void:
	controls_menu.visible=true
	settings.visible=false


func _on_return_inside_audio_pressed() -> void:
	settings.visible=true
	visuals_menu.visible=false


func _on_return_inside_control_pressed() -> void:
	controls_menu.visible=false
	settings.visible=true
