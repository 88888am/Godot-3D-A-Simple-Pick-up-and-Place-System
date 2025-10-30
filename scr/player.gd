extends CharacterBody3D

var ActiveObj = null
var pickObj = null
var original_object_scale : Vector3
var original_collision_layer : int
var original_collision_mask : int
var can_place :bool = false

var init_pos :Vector3
var init_rotation : Vector3

var aabb = null
var max_horizontal_area = 0.0


@onready var head = $head
@onready var placePos = $head/Camera3D/Placer
@onready var collision_body = $body
@onready var collision_foot = $foot
@onready var SPEED = walk_speed
@onready var placeRay :RayCast3D
@onready var can_place_material = StandardMaterial3D.new()
@onready var cannot_place_material = StandardMaterial3D.new()



@export_category("Pick-up and Place Settings")
## Used to limit the maximum size of handheld items（NOT USED)
@export var max_held_size : float = 1.0
## Rotation speed of the held item (Fast rotate)
@export var fast_rotate_speed : float = 3.0
## Precise rotation angle
@export var snap_angle_degrees : float = 15.0
## Transparency of held item (0 is completely opaque and 1 is completely transparent)
@export_range(0, 0.9) var pickObj_transparency :float = 0.5
## The duration of physics processing after the object is placed
@export var sleep_delay : float = 0.5

@export_category("Player Movement Settings")
## Jump vlocity
@export var JUMP_VELOCITY = 4
## Run speed
@export var run_speed : float = 8.0
## Walk speed
@export var walk_speed : float = 5.0
## The length of the ray in front of the character's camera used to detect interactive objects (positive number)
@export var lookat_distance : float = 4.0
## The length of the ray shot downward from the Marker3D node where the object is placed to detect collision with the ground
@export var ground_ray_length : float = 3.0

@export_category("Node Path Settings")
## The node path of "AimPoint"
@export var ObjNameUI : NodePath
## The node path of the outline camera
@export var outlineCam : Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	init_pos = self.global_position
	init_rotation = self.global_rotation
		
	$head/Camera3D/lookat.target_position.z = - lookat_distance
	
	can_place_material.albedo_color = Color(0, 1, 0, 0.5) # 绿色半透明
	cannot_place_material.albedo_color = Color(1, 0, 0, 0.5) # 红色半透明


func _process(delta: float) -> void:
	if outlineCam != null:
		outlineCam.transform = $head/Camera3D.global_transform


func _physics_process(delta: float) -> void:
	if pickObj != null:
		var space_state = get_world_3d().direct_space_state
		
		var safe_origin = self.global_position
		var ideal_origin = placePos.global_position
		var motion = ideal_origin - safe_origin
		var adjusted_start_point: Vector3
		
		if motion.length_squared() < 0.0001:
			adjusted_start_point = ideal_origin
		else:
			var motion_query = PhysicsShapeQueryParameters3D.new()
			var motion_shape = SphereShape3D.new()
			var horizontal_radius = min(aabb.size.x, aabb.size.z) / 2.0
			motion_shape.radius = max(horizontal_radius, 0.01)

			motion_query.shape = motion_shape
			motion_query.transform = Transform3D(Basis(), safe_origin)
			motion_query.motion = motion
			motion_query.exclude = [self, pickObj]

			var result = space_state.cast_motion(motion_query)
		

			if result[0] < 1.0:
				var collision_point = safe_origin + motion * result[0]
				var collision_normal = (safe_origin - collision_point).normalized()
				var ray_query_for_normal = PhysicsRayQueryParameters3D.create(ideal_origin, collision_point)
				var normal_result = space_state.intersect_ray(ray_query_for_normal)
				if normal_result:
					collision_normal = normal_result.normal
			
				var safe_offset = 0.02
				adjusted_start_point = collision_point + collision_normal * safe_offset
			else:
				adjusted_start_point = ideal_origin
				
		var ray_end = adjusted_start_point + Vector3.DOWN * ground_ray_length
		var ray_query = PhysicsRayQueryParameters3D.create(adjusted_start_point, ray_end)
		ray_query.exclude = [self, pickObj]
		var ray_result = space_state.intersect_ray(ray_query)

		if ray_result:
			pickObj.visible = true
			var ground_collider = ray_result.collider
			var ground_point = ray_result.position
			var potential_transform = Transform3D(pickObj.global_transform.basis, ground_point)
			
			potential_transform.origin.y += aabb.size.y / 2
			var collision_shape_node = pickObj.get_node_or_null("CollisionShape3D")
			
			var shape_resource = collision_shape_node.shape
			var shape_query = PhysicsShapeQueryParameters3D.new()
			shape_query.shape = shape_resource
			shape_query.transform = potential_transform
			shape_query.exclude = [self, pickObj, ground_collider]
			var overlaps = space_state.intersect_shape(shape_query)
			if overlaps.is_empty():
				can_place = true
				pickObj.get_node("MeshInstance3D").set_surface_override_material(0, can_place_material)
				pickObj.get_node("MeshInstance3D").set_transparency(pickObj_transparency)
			else:
				can_place = false
				pickObj.get_node("MeshInstance3D").set_surface_override_material(0, cannot_place_material)
				pickObj.get_node("MeshInstance3D").set_transparency(pickObj_transparency)
			pickObj.global_transform = potential_transform
			
		else:
			can_place = false
			pickObj.visible = true
			pickObj.get_node("MeshInstance3D").set_surface_override_material(0, cannot_place_material)
			pickObj.get_node("MeshInstance3D").set_transparency(pickObj_transparency)
			pickObj.global_position = placePos.global_position
			
		if Input.is_action_pressed("fast_left_rotate_item"):
			pickObj.rotate_y(deg_to_rad(fast_rotate_speed * delta * 10))
		elif Input.is_action_pressed("fast_right_rotate_item"):
			pickObj.rotate_y(deg_to_rad(-fast_rotate_speed * delta * 10))
			
		elif Input.is_action_just_pressed("left_rotate_item"):
			pickObj.rotate_y(deg_to_rad(snap_angle_degrees))
		elif Input.is_action_just_pressed("right_rotate_item"):
			pickObj.rotate_y(deg_to_rad(-snap_angle_degrees))
		pickObj.global_rotation.x = 0
		pickObj.global_rotation.z = 0

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()	
	if $head/Camera3D/lookat.is_colliding():
		var collider = $head/Camera3D/lookat.get_collider()
		if ActiveObj != collider:
			if ActiveObj != null:
				set_all_meshes_layer(ActiveObj, 20, false)
			ActiveObj = collider
			if ActiveObj is RigidBody3D:
				get_node(ObjNameUI).get_node("ObjName").text = '“E" to pick up: ' + ActiveObj.name
				set_all_meshes_layer(ActiveObj, 20, true)

	else:
		if ActiveObj != null:
			set_all_meshes_layer(ActiveObj, 20, false)
			ActiveObj = null
			get_node(ObjNameUI).get_node("ObjName").text = ""
		
	if self.global_position.y <= -10:
		self.global_position = init_pos
		self.global_rotation = init_rotation


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x) * 0.1)
		var new_rotation_x = head.rotation.x + deg_to_rad(-event.relative.y) * 0.1
		head.rotation.x = clamp(new_rotation_x, deg_to_rad(-90), deg_to_rad(90))

	if Input.is_action_just_pressed("pick"):
		if pickObj == null:
			PickObj()
		else:
			RemoveObj()

	if Input.is_action_pressed("run") and self.is_on_floor():
		SPEED = run_speed
	if Input.is_action_just_released("run"):
		SPEED = walk_speed

func find_node_in_group(node, group_name):
	for child in node.get_children():
		if child.is_in_group(group_name):
			return child
	return null

func PickObj():
	var pickCollider = $head/Camera3D/lookat.get_collider()
	if pickCollider is RigidBody3D and pickCollider != null:
		pickObj = pickCollider
		set_all_meshes_layer(ActiveObj, 20, false)
		original_collision_layer = pickObj.collision_layer
		original_collision_mask = pickObj.collision_mask
		pickObj.collision_layer = 0
		pickObj.collision_mask = 0
		pickObj.freeze = true
		
		# Scale held item (NOT USED)
		#original_object_scale = pickObj.scale
		#var visual_node = find_node_in_group(pickObj, "Pickable Items (Mesh)")
		#if visual_node and visual_node.has_method("get_aabb"):
			#var aabb = visual_node.get_aabb()
			#var current_size = aabb.get_longest_axis_size() * original_object_scale.x
			#if current_size > max_held_size:
				#var new_scale_ratio = max_held_size / current_size
				#pickObj.scale = original_object_scale * new_scale_ratio
		

		var original_parent = pickObj.get_parent()
		original_parent.remove_child(pickObj)
		placePos.add_child(pickObj)
		
		pickObj.position = Vector3.ZERO
		pickObj.rotation = Vector3.ZERO
		
		var visual_node = pickObj.get_children()
		for i in visual_node:
			if i is MeshInstance3D:
				var current_aabb = i.get_aabb()
				var current_area = current_aabb.size.x * current_aabb.size.z
				if current_area > max_horizontal_area:
					max_horizontal_area = current_area
					aabb = current_aabb
		# Keep held item show on screen (NOT USED)
		#if visual_node and visual_node is MeshInstance3D:
			#for i in range(visual_node.get_surface_override_material_count()):
				#var mat = visual_node.get_surface_override_material(i)
				#if not mat:
					#mat = visual_node.mesh.surface_get_material(i)
				#if mat is StandardMaterial3D:
					#var unique_mat = mat.duplicate()
					#unique_mat.no_depth_test = true
					#unique_mat.render_priority = 1
					#visual_node.set_surface_override_material(i, unique_mat)


func RemoveObj():
	if pickObj and can_place:

		pickObj.freeze = false
		pickObj.collision_layer = original_collision_layer
		pickObj.collision_mask = original_collision_mask
		
		var pick_obj_global_transform = pickObj.global_transform
		var current_rotation_y = pickObj.global_rotation.y
		placePos.remove_child(pickObj)
		get_tree().get_root().add_child(pickObj)
		pickObj.global_transform = pick_obj_global_transform
		pickObj.global_rotation.x = 0
		pickObj.global_rotation.z = 0
		pickObj.global_rotation.y = current_rotation_y
		
		pickObj.can_sleep = false
		_wait_and_resume_sleep(pickObj)
		
		var mesh_instance = pickObj.get_node_or_null("MeshInstance3D")
		if mesh_instance:
			mesh_instance.set_surface_override_material(0, null)
			mesh_instance.set_transparency(0)
		
		pickObj = null
		
		
# Activate object handling after object placement
func _wait_and_resume_sleep(Obj):
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = sleep_delay
	timer.one_shot = true
	timer.start()

	await timer.timeout
	Obj.can_sleep = true


func set_all_meshes_layer(parent_node: Node, layer_number: int, value: bool) -> void:
	if parent_node != null:
		var mesh_nodes: Array[Node] = parent_node.find_children("*", "MeshInstance3D", true)
		for mesh in mesh_nodes:
			mesh.set_layer_mask_value(layer_number, value)
			
