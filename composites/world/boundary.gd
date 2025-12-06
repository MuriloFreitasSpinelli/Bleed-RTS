extends RapierArea2D
class_name Boundary

@export var impulse_gain: float = 10.0
@export var max_impulse: float = 80.0
@export var buffer_zone: float = 50.0  # Distance before applying force

@onready var bounds: CollisionShape2D = $Bounds

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	# Get all bodies currently outside the boundary
	var overlapping = get_overlapping_bodies()
	
	for body in overlapping:
		if body is RigidBody2D:
			_apply_boundary_force(body)

func _get_boundary_rect() -> Rect2:
	"""Get the actual boundary rectangle in world space"""
	if not bounds or not bounds.shape is RectangleShape2D:
		return Rect2()
	
	var shape_size = bounds.shape.size
	var shape_pos = bounds.global_position
	
	# Create rect centered on the collision shape's global position
	return Rect2(
		shape_pos.x - shape_size.x / 2,
		shape_pos.y - shape_size.y / 2,
		shape_size.x,
		shape_size.y
	)

func _apply_boundary_force(body: RigidBody2D) -> void:
	"""Apply force to push body back inside boundary"""
	var body_pos = body.global_position
	var rect = _get_boundary_rect()
	
	# Calculate distances from each edge (positive = inside, negative = outside)
	var left_edge = rect.position.x
	var right_edge = rect.position.x + rect.size.x
	var top_edge = rect.position.y
	var bottom_edge = rect.position.y + rect.size.y
	
	var dist_from_left = body_pos.x - left_edge
	var dist_from_right = right_edge - body_pos.x
	var dist_from_top = body_pos.y - top_edge
	var dist_from_bottom = bottom_edge - body_pos.y
	
	# Find the closest edge
	var min_dist = min(dist_from_left, dist_from_right, dist_from_top, dist_from_bottom)
	
	# Only apply force if within buffer zone
	if min_dist < buffer_zone:
		var direction = Vector2.ZERO
		var penetration = buffer_zone - min_dist
		
		if min_dist == dist_from_left:
			direction = Vector2.RIGHT
		elif min_dist == dist_from_right:
			direction = Vector2.LEFT
		elif min_dist == dist_from_top:
			direction = Vector2.DOWN
		elif min_dist == dist_from_bottom:
			direction = Vector2.UP
		
		# Calculate force strength based on how far into buffer zone
		var force_strength = clamp(penetration * impulse_gain, 0, max_impulse)
		
		# Apply force away from boundary
		body.apply_central_force(direction * force_strength)

func _on_body_entered(_body: Node2D) -> void:
	# Body entered the boundary area (inside the boundary)
	pass

func _on_body_exited(_body: Node2D) -> void:
	# Body exited the boundary area (outside the boundary)
	pass

func is_inside_boundary(pos: Vector2) -> bool:
	"""Check if a position is inside the boundary"""
	var rect = _get_boundary_rect()
	return rect.has_point(pos)

func get_nearest_point_inside(pos: Vector2) -> Vector2:
	"""Get the nearest point inside the boundary from a given position"""
	var rect = _get_boundary_rect()
	
	return Vector2(
		clamp(pos.x, rect.position.x, rect.position.x + rect.size.x),
		clamp(pos.y, rect.position.y, rect.position.y + rect.size.y)
	)

func get_distance_to_edge(pos: Vector2) -> float:
	"""Get the minimum distance from a position to any boundary edge"""
	var rect = _get_boundary_rect()
	
	var dist_x = min(
		abs(pos.x - rect.position.x), 
		abs(pos.x - (rect.position.x + rect.size.x))
	)
	var dist_y = min(
		abs(pos.y - rect.position.y), 
		abs(pos.y - (rect.position.y + rect.size.y))
	)
	
	return min(dist_x, dist_y)
