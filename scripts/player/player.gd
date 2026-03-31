extends CharacterBody3D

const HAS_FLYING_PERMS := true

const WALK_SPEED := 5.0
const SPRINT_SPEED := 7.5
const CROUCH_SPEED := 3.2
const JUMP_VELOCITY := 4.5

const STANDING_HEIGHT := 3.0
const CROUCH_HEIGHT := 2.2
const STANDING_COLLISION_Y := 1.85
const CROUCH_COLLISION_Y := 1.45
const STANDING_MESH_Y := 1.78
const CROUCH_MESH_Y := 1.38

const FLY_SPEED := 117.0
const FLY_VERTICAL_SPEED := 115.0

@onready var jump: AudioStreamPlayer3D = $jump
@onready var walking: AudioStreamPlayer3D = $walking
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $MeshInstance3D
@onready var camera: Camera3D = $Camera3D
@onready var cursor_ui: TextureRect = $UI/CustomCursor

@export var mouse_sensitivity := 0.005
@export var tilt_amount := 0.08
@export var tilt_speed := 8.0
@export var bob_freq := 2.4
@export var bob_amp := 0.1
@export var shake_intensity := 0.2

var current_speed := WALK_SPEED
var mouse_jolt := 0.0
var was_in_air := false
var is_crouching := false
var is_locked := true
var is_flying := false
var is_sprinting := false
var bob_t := 0.0


func _ready() -> void:
	Background.playing = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	process_mode = Node.PROCESS_MODE_ALWAYS
	camera.rotation.z = 0.0


func _input(event: InputEvent) -> void:
	if _should_recapture_mouse(event):
		_capture_mouse()
		return

	if event.is_action_pressed("pause") or Global.player_reset_button:
		_toggle_pause()

	if not is_locked:
		return

	if event.is_action_pressed("fly"):
		_toggle_flight_mode()

	if Input.is_action_just_pressed("run"):
		_toggle_sprint()

	var mouse_event := event as InputEventMouseMotion
	if mouse_event != null:
		_handle_mouse_look(mouse_event)


func _process(delta: float) -> void:
	if not is_locked:
		return

	_handle_camera_effects(delta)
	mouse_jolt = lerp(mouse_jolt, 0.0, delta * 10.0)


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return

	_update_crouch_state()

	if is_on_floor() and was_in_air:
		_on_land()

	was_in_air = not is_on_floor()

	if is_flying and HAS_FLYING_PERMS:
		_handle_fly_movement()
	else:
		is_flying = false
		_handle_ground_movement(delta)

	move_and_slide()
	_handle_audio()


func _should_recapture_mouse(event: InputEvent) -> bool:
	if get_tree().paused:
		return false

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return false

	return (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	)


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_locked = true


func _toggle_pause() -> void:
	is_locked = not is_locked
	get_tree().paused = not is_locked
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if is_locked else Input.MOUSE_MODE_VISIBLE
	cursor_ui.visible = is_locked


func _toggle_flight_mode() -> void:
	if not HAS_FLYING_PERMS:
		is_flying = false
		return

	is_flying = not is_flying
	velocity.y = 0.0


func _toggle_sprint() -> void:
	is_sprinting = not is_sprinting
	walking.pitch_scale = 1.5 if is_sprinting else 1.0


func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	var direction_multiplier := -1.0 if Global.is_conversio else 1.0
	var yaw_delta := -event.relative.x * mouse_sensitivity * direction_multiplier
	var pitch_delta := -event.relative.y * mouse_sensitivity * direction_multiplier

	mouse_jolt += yaw_delta * shake_intensity
	rotate_y(yaw_delta)
	camera.rotate_x(pitch_delta)

	if Global.is_conversio and camera.global_transform.basis.y.y < 0.0:
		Global.is_conversio = false


func _handle_camera_effects(delta: float) -> void:
	var local_velocity := velocity * transform.basis
	var movement_tilt := -local_velocity.x * (tilt_amount / current_speed)
	var target_tilt := movement_tilt + mouse_jolt
	camera.rotation.z = lerp_angle(camera.rotation.z, target_tilt, delta * tilt_speed)

	var horizontal_velocity := Vector2(velocity.x, velocity.z)
	var base_camera_height := 2.0 if is_crouching else 2.8

	if is_on_floor() and horizontal_velocity.length() > 0.1:
		bob_t += delta * horizontal_velocity.length()
		camera.transform.origin = Vector3(
			cos(bob_t * bob_freq * 0.5) * (bob_amp * 0.6),
			base_camera_height + sin(bob_t * bob_freq) * bob_amp,
			0.0
		)
		return

	bob_t = 0.0
	var idle_position := Vector3(0.0, base_camera_height, 0.0)
	camera.transform.origin = camera.transform.origin.lerp(idle_position, delta * 10.0)


func _handle_ground_movement(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := _get_move_direction()

	if direction == Vector3.ZERO:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)
		return

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed


func _handle_fly_movement() -> void:
	var direction := _get_move_direction()

	if direction == Vector3.ZERO:
		velocity = velocity.move_toward(Vector3.ZERO, FLY_SPEED)
	else:
		velocity = direction * FLY_SPEED

	if Input.is_action_pressed("jump"):
		velocity.y = -FLY_VERTICAL_SPEED if Global.is_conversio else FLY_VERTICAL_SPEED
	elif Input.is_action_pressed("crouch"):
		velocity.y = FLY_VERTICAL_SPEED if Global.is_conversio else -FLY_VERTICAL_SPEED
	else:
		velocity.y = 0.0


func _get_move_direction() -> Vector3:
	var input_direction := Input.get_vector("left", "right", "forward", "backward")

	if Global.is_conversio:
		input_direction *= -1.0

	return (transform.basis * Vector3(input_direction.x, 0.0, input_direction.y)).normalized()


func _update_crouch_state() -> void:
	is_crouching = Input.is_action_pressed("crouch")

	if is_crouching:
		current_speed = CROUCH_SPEED
		walking.pitch_scale = 0.59
	else:
		current_speed = SPRINT_SPEED if is_sprinting else WALK_SPEED
		walking.pitch_scale = 1.5 if is_sprinting else 1.0

	var body_height := CROUCH_HEIGHT if is_crouching else STANDING_HEIGHT
	var collision_y := CROUCH_COLLISION_Y if is_crouching else STANDING_COLLISION_Y
	var mesh_y := CROUCH_MESH_Y if is_crouching else STANDING_MESH_Y

	if collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = body_height

	collision_shape.position.y = collision_y

	if body_mesh.mesh is CapsuleMesh:
		body_mesh.mesh.height = body_height

	body_mesh.position.y = mesh_y


func _on_land() -> void:
	if not jump.playing:
		jump.play()


func _handle_audio() -> void:
	var is_moving := Vector2(velocity.x, velocity.z).length() > 0.1

	if is_on_floor() and is_moving and not is_flying:
		if not walking.playing:
			walking.play()
		return

	if walking.playing:
		walking.stop()
