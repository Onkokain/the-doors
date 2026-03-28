extends CharacterBody3D

# --- PERMISSIONS ---
const HAS_FLYING_PERMS = true

@onready var jump: AudioStreamPlayer3D = $jump
@onready var walking: AudioStreamPlayer3D = $walking
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $MeshInstance3D
@onready var camera = $Camera3D
@onready var cursor_ui: TextureRect = $UI/CustomCursor
@onready var settings_menu: CenterContainer = $"../settings"
@onready var container: CenterContainer = $"../Panel/CenterContainer"

# --- SETTINGS ---
@export var mouse_sensitivity: float = 0.005

# --- HEAVY TILT & SHAKE SETTINGS ---
@export var tilt_amount: float = 0.08
@export var tilt_speed: float = 8.0
@export var bob_freq: float = 2.4
@export var bob_amp: float = 0.1

# --- VIOLENT MOUSE JOLT ---
@export var shake_intensity: float = 0.2
var mouse_jolt: float = 0.0

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
var is_locked: bool = true
var is_flying: bool = false
var is_sprinting: bool = false
var bob_t: float = 0.0

# --- FLY MODE ---
const FLY_SPEED = 117.0
const FLY_VERTICAL_SPEED = 115.0

func _ready():
	Background.playing = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if settings_menu:
		settings_menu.visible = false
		settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	camera.rotation.z = 0

func _input(event):
	if event.is_action_pressed("pause"):
		_toggle_pause()

	if is_locked:
		if event.is_action_pressed("fly"):
			if HAS_FLYING_PERMS:
				is_flying = !is_flying
				velocity.y = 0
			else:
				is_flying = false

		if Input.is_action_just_pressed('run'):
			is_sprinting = !is_sprinting
			walking.pitch_scale = 1.5 if is_sprinting else 1.0

		if event is InputEventMouseMotion:
			# 1-to-1 Inversion multiplier
			var m_mult : float = -1.0 if Global.is_conversio else 1.0
			
			mouse_jolt += -event.relative.x * mouse_sensitivity * shake_intensity * m_mult
			
			rotate_y(-event.relative.x * mouse_sensitivity * m_mult)
			camera.rotate_x(-event.relative.y * mouse_sensitivity * m_mult)
			
			# UNDO LOGIC: If conversio is on and the player flips the camera upside down, 
			# we turn the effect off.
			if Global.is_conversio and camera.global_transform.basis.y.y < 0:
				Global.is_conversio = false
			
			# CLAMP REMOVED so you can actually perform the "undo" movement

func _process(delta: float) -> void:
	if not is_locked: return
	
	_handle_camera_effects(delta)
	mouse_jolt = lerp(mouse_jolt, 0.0, delta * 10.0)

func _physics_process(delta: float) -> void:
	if get_tree().paused: return
	crouching()
	
	if is_on_floor() and was_in_air:
		_on_land()
	
	was_in_air = !is_on_floor()

	if is_flying and HAS_FLYING_PERMS:
		_handle_fly_movement(delta)
	else:
		is_flying = false
		_handle_ground_movement(delta)

	move_and_slide()
	_handle_audio()

func _handle_camera_effects(delta: float):
	var local_vel = velocity * transform.basis
	var movement_tilt = -local_vel.x * (tilt_amount / SPEED)
	var total_tilt = movement_tilt + mouse_jolt
	camera.rotation.z = lerp_angle(camera.rotation.z, total_tilt, delta * tilt_speed)

	var horizontal_vel = Vector2(velocity.x, velocity.z)
	var base_y = 2.0 if is_croutching else 2.8
	
	if is_on_floor() and horizontal_vel.length() > 0.1:
		bob_t += delta * horizontal_vel.length()
		var target_pos = Vector3.ZERO
		target_pos.y = base_y + sin(bob_t * bob_freq) * bob_amp
		target_pos.x = cos(bob_t * bob_freq * 0.5) * (bob_amp * 0.6)
		camera.transform.origin = target_pos
	else:
		bob_t = 0
		var idle_pos = Vector3(0, base_y, 0)
		camera.transform.origin = camera.transform.origin.lerp(idle_pos, delta * 10.0)

func _toggle_pause():
	is_locked = !is_locked
	get_tree().paused = !is_locked
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if is_locked else Input.MOUSE_MODE_VISIBLE
	cursor_ui.visible = is_locked
	if is_locked:
		settings_menu.visible = false

func _handle_ground_movement(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	
	# Keyboard 1-to-1 inversion
	if Global.is_conversio:
		input_dir *= -1.0
		
	var direction : Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func crouching() -> void:
	is_croutching = Input.is_action_pressed("crouch")
	SPEED = CROUCH_SPEED if is_croutching else (SPRINT_SPEED if is_sprinting else WALK_SPEED)
	walking.pitch_scale = 0.59 if is_croutching else (1.5 if is_sprinting else 1.0)

	var body_height := CROUCH_HEIGHT if is_croutching else STANDING_HEIGHT
	if collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = body_height
	collision_shape.position.y = CROUCH_COLLISION_Y if is_croutching else STANDING_COLLISION_Y

	if body_mesh.mesh is CapsuleMesh:
		body_mesh.mesh.height = body_height
	body_mesh.position.y = CROUCH_MESH_Y if is_croutching else STANDING_MESH_Y

func _handle_fly_movement(_delta):
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	if Global.is_conversio:
		input_dir *= -1.0
		
	var direction : Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity = direction * FLY_SPEED if direction else velocity.move_toward(Vector3.ZERO, FLY_SPEED)
	
	if Input.is_action_pressed("jump"): 
		velocity.y = -FLY_VERTICAL_SPEED if Global.is_conversio else FLY_VERTICAL_SPEED
	elif Input.is_action_pressed("crouch"): 
		velocity.y = FLY_VERTICAL_SPEED if Global.is_conversio else -FLY_VERTICAL_SPEED
	else: 
		velocity.y = 0

func _on_land():
	if not jump.playing: jump.play()

func _handle_audio() -> void:
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.1
	if is_on_floor() and is_moving and not is_flying:
		if not walking.playing: walking.play()
	elif walking.playing:
		walking.stop()
