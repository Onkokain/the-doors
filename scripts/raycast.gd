extends RayCast3D




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_colliding():
		var hitobj=get_collider()
		if hitobj.has_method("interact") && Input.is_action_just_pressed('interact'):
			hitobj.interact()
			Global.room_change_counter+=1
