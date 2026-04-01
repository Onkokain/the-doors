extends Panel

const BUTTON_HOVER_SOUND = preload("res://assets/music/button_hover.mp3")
const BUTTON_PRESS_SOUND = preload("res://assets/music/button_press.mp3")
const CARD_NORMAL_TINT := Color(1.0, 1.0, 1.0, 0.96)
const CARD_HOVER_TINT := Color(1.0, 0.9, 0.92, 1.0)
const CARD_PRESSED_TINT := Color(1.0, 0.82, 0.86, 1.0)
const LABEL_NORMAL_TINT := Color(1.0, 1.0, 1.0, 1.0)
const LABEL_HOVER_TINT := Color(1.08, 0.92, 0.94, 1.0)
@onready var center_container: CenterContainer = $CenterContainer

@onready var panel: Panel = self
@onready var title_label: Label = $Label
@onready var title_shadow: Label = $TitleShadow
@onready var subtitle_label: Label = $Subtitle
@onready var frame_glow: ColorRect = $FrameGlow
@onready var menu_frame: PanelContainer = $MenuFrame
@onready var container: CenterContainer = $CenterContainer
@onready var quit_game: TextureButton = $"CenterContainer/VBoxContainer/Panel/quit game"
@onready var settings: TextureButton = $CenterContainer/VBoxContainer/Panel2/settings
@onready var achievements: TextureButton = $CenterContainer/VBoxContainer/Panel3/achievements
@onready var statistics_menu: CenterContainer = $"../statistics"
@onready var rooms_list: Panel = $"../rooms_list"
@onready var player: CharacterBody3D = $"../player"
@onready var return_inside_door_list: TextureButton = $"../rooms_list/return/return_inside_door_list"

var spawn_position: Vector3
var paused := false
var hover_tweens := {}
var hovered_cards := {}
var pressed_cards := {}
var card_labels := {}
var configured_buttons := {}
var ambient_time := 0.0
var title_base_position := Vector2.ZERO
var shadow_base_position := Vector2.ZERO
var subtitle_base_position := Vector2.ZERO
var hover_player: AudioStreamPlayer
var press_player: AudioStreamPlayer


func _ready() -> void:
	spawn_position = player.global_position
	process_mode = Node.PROCESS_MODE_ALWAYS

	title_base_position = title_label.position
	shadow_base_position = title_shadow.position
	subtitle_base_position = subtitle_label.position
	title_shadow.z_index = 0
	title_label.z_index = 1
	menu_frame.pivot_offset = menu_frame.size / 2.0
	_setup_ui_sound_players()

	_reset_submenu_state()
	_update_menu_state(false)

	_configure_buttons_in(self)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _process(delta: float) -> void:
	if not paused:
		return

	ambient_time += delta
	var title_bob := sin(ambient_time * 0.9) * 4.0
	var title_sway := cos(ambient_time * 0.5) * 2.5

	title_label.position = title_base_position + Vector2(title_sway, title_bob)
	title_shadow.position = shadow_base_position + Vector2(title_sway + 6.0, title_bob + 6.0)
	subtitle_label.position = subtitle_base_position + Vector2(0.0, title_bob * 0.2)
	frame_glow.modulate.a = 0.68 + 0.16 * sin(ambient_time * 0.85)
	menu_frame.scale = Vector2.ONE * (1.0 + 0.006 * sin(ambient_time * 0.65))


func _toggle_pause() -> void:
	if player == null:
		return

	var should_pause := not get_tree().paused
	player.set_pause_state(should_pause)
	paused = should_pause

	if should_pause:
		_reset_submenu_state()

	_update_menu_state(should_pause)

	if is_instance_valid(Background):
		Background.playing = should_pause


func _update_menu_state(should_show: bool) -> void:
	panel.visible = should_show

	if should_show:
		_show_main_menu()
	else:
		_hide_all_menus()


func _show_main_menu() -> void:
	container.visible = true
	center_container.visible = true
	menu_frame.visible = true
	statistics_menu.visible = false
	rooms_list.visible = false
	quit_game.visible = true
	settings.visible = true
	achievements.visible = true


func _hide_all_menus() -> void:
	container.visible = false
	center_container.visible = false
	menu_frame.visible = false
	statistics_menu.visible = false
	rooms_list.visible = false
	quit_game.visible = false
	settings.visible = false
	achievements.visible = false


func _reset_submenu_state() -> void:
	statistics_menu.visible = false
	rooms_list.visible = false
	_show_main_menu()


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
	if card.size == Vector2.ZERO:
		card.force_update_transform()
	card.pivot_offset = card.size / 2.0


func _setup_ui_sound_players() -> void:
	hover_player = AudioStreamPlayer.new()
	hover_player.stream = BUTTON_HOVER_SOUND
	hover_player.bus = &"effects"
	hover_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hover_player)

	press_player = AudioStreamPlayer.new()
	press_player.stream = BUTTON_PRESS_SOUND
	press_player.bus = &"effects"
	press_player.process_mode = Node.PROCESS_MODE_ALWAYS
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
		target_scale = Vector2.ONE * 1.045
		target_tint = CARD_HOVER_TINT
		label_tint = LABEL_HOVER_TINT

	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
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


func _on_quit_game_pressed() -> void:
	if player != null:
		player.set_pause_state(false)
	paused = false
	get_tree().change_scene_to_file("res://scenes/core/main_menu.tscn")


func _on_settings_pressed() -> void:
	if player:
		player.global_position = spawn_position
		player.velocity = Vector3.ZERO
		player.set_pause_state(false)
		paused = false
		_update_menu_state(false)
		Global.player_reset_button = true
		await get_tree().create_timer(0.01).timeout
		Global.player_reset_button = false


func _on_achievements_pressed() -> void:
	statistics_menu.visible = true
	container.visible = false
	center_container.visible = false
	menu_frame.visible = false


func _on_return_pressed() -> void:
	_show_main_menu()
