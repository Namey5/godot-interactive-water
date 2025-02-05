extends MeshInstance3D


@export var water_size := Vector2(1, 1)

@onready var _simulation: TextureRect = $WaterSimulation/SimulationTex


func _process(_delta: float) -> void:
	var mouse_pos := -Vector2.ONE
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		mouse_pos = get_viewport().get_mouse_position()
		var camera := get_viewport().get_camera_3d();
		var plane := Plane(global_basis.y, global_position)
		var hit = plane.intersects_ray(
			camera.project_ray_origin(mouse_pos),
			camera.project_ray_normal(mouse_pos)
		)
		if hit:
			var local_hit := transform.inverse() * (hit as Vector3)
			mouse_pos = Vector2(local_hit.x, local_hit.z) / water_size * 0.5 + 0.5 * Vector2.ONE
		else:
			mouse_pos = -Vector2.ONE
	_simulation.material.set("shader_parameter/mouse_pos", mouse_pos)
