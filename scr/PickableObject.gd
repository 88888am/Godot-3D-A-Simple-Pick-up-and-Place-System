class_name PickableObj
extends RigidBody3D

var init_pos : Vector3
var init_rotate : Vector3


## The reset height for objects dropped into the ground
@export var reset_Height : float = -10

func _ready() -> void:
	init_pos = self.global_position
	init_rotate = self.global_rotation
	
func _physics_process(delta: float) -> void:
	if self.global_position.y <= reset_Height:
		reset(init_pos, init_rotate)

func reset(init_pos:Vector3 , init_rotate:Vector3):
	self.linear_velocity = Vector3.ZERO
	self.angular_velocity = Vector3.ZERO
	self.global_position = init_pos
	self.global_rotation = init_rotate
