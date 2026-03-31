extends Node2D

const MAIN_SCENE = preload("res://scenes/core/main.tscn")
const CARD_NORMAL_TINT := Color(1.0, 1.0, 1.0, 0.96)
const CARD_HOVER_TINT := Color(1.0, 0.9, 0.92, 1.0)
const CARD_PRESSED_TINT := Color(1.0, 0.82, 0.86, 1.0)
const LABEL_NORMAL_TINT := Color(1.0, 1.0, 1.0, 1.0)
const LABEL_HOVER_TINT := Color(1.08, 0.92, 0.94, 1.0)

@onready var background_image: Sprite2D = $BgImg
@onready var title_label: Label = $Label
@onready var title_shadow: Label = $TitleShadow
@onready var subtitle_label: Label = $Subtitle
@onready var title_glow: ColorRect = $TitleGlow
@onready var frame_glow: ColorRect = $FrameGlow
@onready var menu_frame: PanelContainer = $MenuFrame
@onready var center_container: CenterContainer = $CenterContainer

@onready var start: TextureButton = $CenterContainer/VBoxContainer/Panel/start
@onready var settings: TextureButton = $CenterContainer/VBoxContainer/Panel2/settings
@onready var cutscene: TextureButton = $CenterContainer/VBoxContainer/Panel3/cutscene
@onready var endgame: TextureButton = $CenterContainer/VBoxContainer/Panel4/endgame

@onready var settings_menu: CenterContainer = $settings
@onready var statistics_menu: CenterContainer = $statistics
@onready var statistics: CenterContainer = $statistics
@onready var rooms_list: Panel = $rooms_list

var hover_tweens := {}
var hovered_cards := {}
var pressed_cards := {}
var card_labels := {}
var ambient_time := 0.0
var background_base_position := Vector2.ZERO
var title_base_position := Vector2.ZERO
var shadow_base_position := Vector2.ZERO
var subtitle_base_position := Vector2.ZERO


func _ready() -> void:
	rooms_list.visible = false
	statistics.visible = false
	center_container.visible = true
	statistics_menu.visible = false
	settings_menu.visible = false

	background_base_position = background_image.position
	title_base_position = title_label.position
	shadow_base_position = title_shadow.position
	subtitle_base_position = subtitle_label.position
	title_shadow.z_index = 0
	title_label.z_index = 1

	menu_frame.pivot_offset = menu_frame.size / 2.0

	for button in [start, settings, cutscene, endgame]:
		_configure_hover(button)

	_play_intro()


func _process(delta: float) -> void:
	ambient_time += delta

	var title_bob := sin(ambient_time * 0.9) * 5.0
	var title_sway := cos(ambient_time * 0.55) * 3.0

	title_label.position = title_base_position + Vector2(title_sway, title_bob)
	title_shadow.position = shadow_base_position + Vector2(title_sway + 8.0, title_bob + 8.0)
	subtitle_label.position = subtitle_base_position + Vector2(0.0, title_bob * 0.2)
	background_image.position = background_base_position + Vector2(cos(ambient_time * 0.17) * 10.0, sin(ambient_time * 0.23) * 7.0)
	title_glow.modulate.a = 0.82 + 0.12 * sin(ambient_time * 1.3)
	frame_glow.modulate.a = 0.7 + 0.16 * sin(ambient_time * 0.85)
	menu_frame.scale = Vector2.ONE * (1.0 + 0.006 * sin(ambient_time * 0.65))


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
		target_scale = Vector2.ONE * 1.045
		target_tint = CARD_HOVER_TINT
		label_tint = LABEL_HOVER_TINT

	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hover_tweens[card] = tween
	tween.parallel().tween_property(card, "scale", target_scale, 0.14)
	tween.parallel().tween_property(card, "modulate", target_tint, 0.14)

	var label: Label = card_labels.get(card)
	if label != null:
		tween.parallel().tween_property(label, "modulate", label_tint, 0.14)


func _play_intro() -> void:
	menu_frame.modulate.a = 0.0
	title_label.modulate.a = 0.0
	title_shadow.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	center_container.position.y += 24.0

	var intro := create_tween().set_parallel(true)
	intro.tween_property(menu_frame, "modulate:a", 1.0, 0.45)
	intro.tween_property(title_label, "modulate:a", 1.0, 0.6)
	intro.tween_property(title_shadow, "modulate:a", 0.88, 0.6)
	intro.tween_property(subtitle_label, "modulate:a", 1.0, 0.8)
	intro.tween_property(center_container, "position:y", center_container.position.y - 24.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var stagger := create_tween()
	for card in [start.get_parent(), settings.get_parent(), cutscene.get_parent(), endgame.get_parent()]:
		card.modulate.a = 0.0
		card.scale = Vector2.ONE * 0.94
		stagger.tween_property(card, "modulate:a", 1.0, 0.16)
		stagger.parallel().tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		stagger.tween_interval(0.05)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_packed(MAIN_SCENE)


func _on_settings_pressed() -> void:
	menu_frame.visible=false
	center_container.visible = false
	settings_menu.visible = true
	statistics_menu.visible = false
	rooms_list.visible = false


func _on_return_pressed() -> void:
	center_container.visible = true
	settings_menu.visible = false
	statistics_menu.visible = false
	rooms_list.visible = false
	menu_frame.visible=true


func _on_endgame_pressed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = 'https://baralekogyan.itch.io/';")
	else:
		get_tree().quit()


func _on_cutscene_pressed() -> void:
	menu_frame.visible=false
	center_container.visible = false
	settings_menu.visible = false
	statistics_menu.visible = true
