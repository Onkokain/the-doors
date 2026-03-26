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

# --- CAMERA SETTINGS (MINECRAFT STYLE - DIRECT INPUT) ---
@export var mouse_sensitivity: float = 0.005 
# Removed rotation_speed, target variables, and head bob variables

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

		# 1:1 MINECRAFT MOUSE MOVEMENT (Instant rotation, no lerping)
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			# Prevent breaking the neck (looking too far up/down)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

# _process() WAS COMPLETELY DELETED. WE DON'T NEED SMOOTHING.

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

# --- HELPER FUNCTIONS ---

func _toggle_pause():
	is_locked = !is_locked
	get_tree().paused = !is_locked
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if is_locked else Input.MOUSE_MODE_VISIBLE
	cursor_ui.visible = is_locked
	if is_locked:
		settings_menu.visible = false

func _on_settings_pressed() -> void:
	if settings_menu:
		settings_menu.visible = true
		container.visible = false
		for child in settings_menu.find_children("*", "Control", true):
			child.mouse_filter = Control.MOUSE_FILTER_PASS

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

func crouching() -> void:
	is_croutching = Input.is_action_pressed("crouch")
	
	# DIRECT CAMERA HEIGHT OVERRIDE (Replaces head bob offset)
	camera.position.y = 2.0 if is_croutching else 2.8
	
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
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity = direction * FLY_SPEED if direction else velocity.move_toward(Vector3.ZERO, FLY_SPEED)
	if Input.is_action_pressed("jump"): velocity.y = FLY_VERTICAL_SPEED
	elif Input.is_action_pressed("crouch"): velocity.y = -FLY_VERTICAL_SPEED
	else: velocity.y = 0

func _on_land():
	if not jump.playing: jump.play()

func _handle_audio() -> void:
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.1
	if is_on_floor() and is_moving and not is_flying:
		if not walking.playing: walking.play()
	elif walking.playing:
		walking.stop()
