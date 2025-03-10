extends Node3D

@onready var pivot: SpringArm3D = $Pivot

@export var sens = 0.005

var velocity:= Vector3.ZERO
var zoom = 0
var allow_rotation = false

var prev_position: Vector3

signal on_trasform(pos: Vector3)

const SPEED = 30.0

func _process(delta: float) -> void:

	var input_dir := Input.get_vector("A", "D", "W", "S")
	var direction = (pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	position += velocity * delta

	allow_rotation = Input.is_action_pressed("M_MIDDLE")

	if prev_position != transform.origin:
		on_trasform.emit(transform.origin)
		prev_position = transform.origin

	


func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			pivot.spring_length += clamp(1, 2, 50)
			pass
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			pivot.spring_length -= clamp(1, 2, 50)
			pass

	
	if event is InputEventMouseMotion && allow_rotation:

		var s:= 0.005

		pivot.rotation.y -= event.relative.x * s
		# spring.rotation.y = wrapf(rotation.y, 0.0, TAU)

		pivot.rotation.x -= event.relative.y * s
		# pivot.rotation.x = clamp(pivot.rotation.x, -PI/2, -0.01)

	pass