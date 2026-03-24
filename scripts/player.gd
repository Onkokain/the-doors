extends CharacterBody3D

@onready var jump: AudioStreamPlayer3D = $jump
@onready var walking: AudioStreamPlayer3D = $walking
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $MeshInstance3D
@onready var camera = $Camera3D
@onready var cursor_ui: TextureRect = $UI/CustomCursor

# --- FEAR CAMERA & TILT SETTINGS ---
@export var mouse_sensitivity: float = 0.006
@export var rotation_speed: float = 22.0    # Speed of horizontal/vertical catch-up
@export var tilt_amount: float = -0.3      # Strength of the side-tilt
@export var tilt_speed: float = 6.0        # How fast it leans and recovers

var target_rotation_x: float = 0.0
var target_rotation_y: float = 0.0
var mouse_velocity_x: float = 0.0

# Movement Constants
var SPEED = 5.0
const WALK_SPEED = 5.0
const SPRINT_SPEED = 7.5
const CROUCH_SPEED = 3.2
const STANDING_HEIGHT = 3.0
const CROUCH_HEIGHT = 2.2
const STANDING_COLLISION_Y = 1.8451296
const CROUCH_COLLISION_Y = 1.4451296
const STANDING_MESH_Y = 1.7844726
const CROUCH_MESH_Y = 1.3844726
const JUMP_VELOCITY = 4.5

# State Tracking
var was_in_air: bool = false
var is_croutching: bool = false
var is_locked: bool = false
var is_flying: bool = false
var is_sprinting: bool = false

# Head Bob Settings
var BASE_HEIGHT = 2.8
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var bob_t = 1.0

# --- FLY MODE ---
const FLY_SPEED = 117.0
const FLY_VERTICAL_SPEED = 115.0

func _ready():
	is_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cursor_ui.visible = true
	
	target_rotation_y = rotation.y
	target_rotation_x = camera.rotation.x

func _input(event):
	if event.is_action_pressed("pause"):
		is_locked = !is_locked
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if is_locked else Input.MOUSE_MODE_VISIBLE
		cursor_ui.visible = is_locked

	if event.is_action_pressed("fly"):
		is_flying = !is_flying
		velocity.y = 0

	if Input.is_action_just_pressed('run'):
		is_sprinting = !is_sprinting
		walking.pitch_scale = 1.5 if is_sprinting else 1.0

	# 1. CAPTURE MOUSE INPUT
	if is_locked and event is InputEventMouseMotion:
		target_rotation_y -= event.relative.x * mouse_sensitivity
		target_rotation_x -= event.relative.y * mouse_sensitivity
		target_rotation_x = clamp(target_rotation_x, deg_to_rad(-80), deg_to_rad(80))
		
		# Store the horizontal "speed" of the mouse for the tilt
		mouse_velocity_x = event.relative.x

func _process(delta: float) -> void:
	if not is_locked:
		return

	# 2. APPLY SNAPPY ROTATION (X and Y)
	rotation.y = lerp_angle(rotation.y, target_rotation_y, delta * rotation_speed)
	camera.rotation.x = lerp(camera.rotation.x, target_rotation_x, delta * rotation_speed)
	
	# 3. APPLY DIRECTIONAL TILT (Z-Axis)
	# Moving mouse RIGHT (positive X) results in a RIGHT tilt (negative Z)
	var target_tilt = -mouse_velocity_x * mouse_sensitivity * tilt_amount * 10.0
	camera.rotation.z = lerp(camera.rotation.z, target_tilt, delta * tilt_speed)
	
	# 4. RESET MOUSE VELOCITY
	# This ensures the camera straightens out when the mouse stops moving
	mouse_velocity_x = move_toward(mouse_velocity_x, 0, delta * 100.0)

func _physics_process(delta: float) -> void:
	crouching()
	
	if get_tree().paused: return

	if is_on_floor() and was_in_air:
		_on_land()
	
	was_in_air = !is_on_floor()

	if is_flying:
		_handle_fly_movement(delta)
	else:
		_handle_ground_movement(delta)

	move_and_slide()
	_handle_head_bob(delta)
	_handle_audio()

func _handle_fly_movement(_delta):
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity = direction * FLY_SPEED if direction else velocity.move_toward(Vector3.ZERO, FLY_SPEED)
	
	if Input.is_action_pressed("jump"): velocity.y = FLY_VERTICAL_SPEED
	elif Input.is_action_pressed("crouch"): velocity.y = -FLY_VERTICAL_SPEED
	else: velocity.y = 0

func _handle_ground_movement(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func _on_land():
	if not jump.playing: jump.play()

func _handle_audio() -> void:
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.1
	if is_on_floor() and is_moving and not is_flying:
		if not walking.playing: walking.play()
	elif walking.playing:
		walking.stop()

func _handle_head_bob(delta: float) -> void:
	if is_flying: return
	var horizontal_velocity = Vector2(velocity.x, velocity.z)
	if is_on_floor() and horizontal_velocity.length() > 0.1:
		bob_t += delta * horizontal_velocity.length()
	else:
		bob_t = lerp(bob_t, 0.0, delta * 5.0)
	
	var pos = Vector3(0, BASE_HEIGHT, 0)
	pos.y += sin(bob_t * BOB_FREQ) * BOB_AMP
	pos.x += cos(bob_t * BOB_FREQ * 0.5) * (BOB_AMP * 0.6)
	camera.transform.origin = pos

func crouching() -> void:
	is_croutching = Input.is_action_pressed("crouch")
	BASE_HEIGHT = 2.0 if is_croutching else 2.8
	SPEED = CROUCH_SPEED if is_croutching else (SPRINT_SPEED if is_sprinting else WALK_SPEED)
	walking.pitch_scale = 0.59 if is_croutching else (1.5 if is_sprinting else 1.0)

	var body_height := CROUCH_HEIGHT if is_croutching else STANDING_HEIGHT
	if collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = body_height
	collision_shape.position.y = CROUCH_COLLISION_Y if is_croutching else STANDING_COLLISION_Y

	if body_mesh.mesh is CapsuleMesh:
		body_mesh.mesh.height = body_height
	body_mesh.position.y = CROUCH_MESH_Y if is_croutching else STANDING_MESH_Y
