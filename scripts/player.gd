extends CharacterBody3D

@onready var jump: AudioStreamPlayer3D = $jump
@onready var walking: AudioStreamPlayer3D = $walking
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $MeshInstance3D

# Preload your custom cursor image
var custom_cursor = preload("res://assets/images/cursor.png")

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

# Tracking landing state	
var was_in_air = false
var is_croutching=false
# Head Bob Settings
var BASE_HEIGHT = 2.8
const BOB_FREQ = 2.4
const BOB_AMP = 0.3
var bob_t = 1.0

# Camera / Mouse Settings
@export var mouse_sensitivity = 0.002
@onready var camera = $Camera3D

var is_locked = false
@onready var cursor_ui: TextureRect = $UI/CustomCursor

# --- FLY MODE ---
var is_flying = false
var is_sprinting = false
const FLY_SPEED = 117.0
const FLY_VERTICAL_SPEED = 115.0


func _ready():
	
	# Start locked and hide the system mouse
	is_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cursor_ui.visible = true


func _input(event):
	if event.is_action_pressed("pause"):
		is_locked = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		cursor_ui.visible = false

	# --- FLY TOGGLE ---
	if event.is_action_pressed("fly"):
		is_flying = !is_flying
		velocity.y = 0

	# 1. HANDLE MOUSE TOGGLE (Minecraft Mode)

		
		# We update the mouse mode IMMEDIATELY when the toggle happens
		if is_locked:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			cursor_ui.visible = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			cursor_ui.visible = false
			# Returns to system default arrow
			Input.set_custom_mouse_cursor(null)

	# 2. HANDLE RUNNING SPEED (Sprint)
	if Input.is_action_just_pressed('run'):
		is_sprinting = !is_sprinting
		if is_sprinting:
			walking.pitch_scale = 1.5
		else:
			walking.pitch_scale = 1.0

	# 3. HANDLE CAMERA ROTATION
	# This only runs if we are locked and actually moving the mouse
	if is_locked and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))


func _physics_process(delta: float) -> void:
	crouching()
	if get_tree().paused:
		return
	else:
		is_locked=true
		cursor_ui.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	# Check for landing BEFORE move_and_slide updates is_on_floor
	if is_on_floor() and was_in_air:
		_on_land()
	
	# Update air state for the next frame
	was_in_air = !is_on_floor()

	# --- FLY LOGIC ---
	if is_flying:
		var input_dir := Input.get_vector("left", "right", "forward", "backward")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		if direction:
			velocity.x = direction.x * FLY_SPEED
			velocity.z = direction.z * FLY_SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, FLY_SPEED)
			velocity.z = move_toward(velocity.z, 0, FLY_SPEED)

		# Vertical movement
		if Input.is_action_pressed("jump"):
			velocity.y = FLY_VERTICAL_SPEED
		elif Input.is_action_pressed("crouch"):
			velocity.y = -FLY_VERTICAL_SPEED
			BASE_HEIGHT=2.5
		else:
			velocity.y = 0

	else:
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

	move_and_slide()
	
	_handle_head_bob(delta)
	_handle_audio()


func _on_land():
	if not jump.playing:
		jump.play()


func _handle_audio() -> void:
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.1
	if is_on_floor() and is_moving and not is_flying:
		if not walking.playing:
			walking.play()
	else:
		if walking.playing:
			walking.stop()


func _handle_head_bob(delta: float) -> void:
	if is_flying:
		return

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
	var capsule_shape := collision_shape.shape as CapsuleShape3D
	if capsule_shape != null:
		capsule_shape.height = body_height
	collision_shape.position.y = CROUCH_COLLISION_Y if is_croutching else STANDING_COLLISION_Y

	var capsule_mesh := body_mesh.mesh as CapsuleMesh
	if capsule_mesh != null:
		capsule_mesh.height = body_height
	body_mesh.position.y = CROUCH_MESH_Y if is_croutching else STANDING_MESH_Y
