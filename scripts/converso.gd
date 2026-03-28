extends Area3D
@onready var collisionshape: CollisionShape3D = $CollisionShape3D


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		Global.is_conversio=true
