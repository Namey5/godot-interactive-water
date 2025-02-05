extends SpringArm3D


@export var control_smoothing := 0.1
@export var look_sensitivity := Vector2(2.0, 2.0)
@export var zoom_sensitivity := 0.1

@onready var _target_rotation := self.quaternion
@onready var _target_zoom := self.spring_length

var _mouse_input := Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_input += event.relative / 1080.0
	elif event is InputEventMouseButton:
		_target_zoom += zoom_sensitivity if (event.button_index == MOUSE_BUTTON_WHEEL_DOWN) else 0.0;
		_target_zoom -= zoom_sensitivity if (event.button_index == MOUSE_BUTTON_WHEEL_UP) else 0.0;
	elif event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()


func _process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_target_rotation = Quaternion(Vector3.UP, -_mouse_input.x * look_sensitivity.x) \
			* _target_rotation \
			* Quaternion(Vector3.RIGHT, -_mouse_input.y * look_sensitivity.y)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mouse_input = Vector2.ZERO
	
	quaternion = quaternion.slerp(_target_rotation, delta / control_smoothing)
	spring_length = lerpf(spring_length, _target_zoom, delta / control_smoothing)
