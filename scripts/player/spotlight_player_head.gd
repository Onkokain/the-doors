extends SpotLight3D
@export var max_energy: float = 10.0
@export var min_energy: float = 0.5
@export var dim_threshold: float = 3.0
@export var smooth_speed: float = 16.0

@onready var ray_cast: RayCast3D = RayCast3D.new()

func _ready() -> void:
	add_child(ray_cast)
	ray_cast.target_position = Vector3(0, 0, -15) 
	ray_cast.enabled = true

func _process(delta: float) -> void:
	var target_energy: float = max_energy
	
	if ray_cast.is_colliding():
		var collision_point: Vector3 = ray_cast.get_collision_point()
		var distance: float = global_position.distance_to(collision_point)
		
		if distance < dim_threshold:
			var ratio: float = distance / dim_threshold
			
			target_energy = max_energy * (ratio * ratio)
			
			if target_energy < min_energy:
				target_energy = min_energy
	
	light_energy = lerp(light_energy, target_energy, delta * smooth_speed)
