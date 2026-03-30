extends SpotLight3D

# The maximum energy of your light when looking at a distance
@export var max_energy: float = 10.0
# The minimum energy allowed so it's never pitch black at your feet
@export var min_energy: float = 0.5
# The distance at which the light starts dimming (increase this for an earlier dim)
@export var dim_threshold: float = 3.0
# How quickly the light adjusts (higher = snappier, lower = smoother)
@export var smooth_speed: float = 16.0

@onready var ray_cast: RayCast3D = RayCast3D.new()

func _ready() -> void:
	# Setup a RayCast3D programmatically to detect the floor
	add_child(ray_cast)
	# Increased distance to ensure it hits the floor even from high up
	ray_cast.target_position = Vector3(0, 0, -15) 
	ray_cast.enabled = true

func _process(delta: float) -> void:
	# Default to max energy if no collision
	var target_energy: float = max_energy
	
	if ray_cast.is_colliding():
		var collision_point: Vector3 = ray_cast.get_collision_point()
		var distance: float = global_position.distance_to(collision_point)
		
		if distance < dim_threshold:
			# Calculate the linear ratio (0.0 to 1.0)
			var ratio: float = distance / dim_threshold
			
			# SQUARING the ratio (ratio * ratio) makes the light dim much faster
			# Cubing it (ratio * ratio * ratio) would make it even more aggressive
			target_energy = max_energy * (ratio * ratio)
			
			# Ensure we don't go below our minimum visibility floor
			# We use clamp or max to ensure target_energy is at least min_energy
			if target_energy < min_energy:
				target_energy = min_energy
	
	# Smoothly transition the energy to avoid jarring pops in brightness
	light_energy = lerp(light_energy, target_energy, delta * smooth_speed)
