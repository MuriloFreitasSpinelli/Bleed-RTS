extends RapierArea2D
class_name SightComponent

var neighbors: Array[UnitComposite] = []
var neighbors_by_team: Dictionary = {}  # team_id -> Array[UnitComposite]
var neighbors_by_layer: Dictionary = {}  # layer_id -> Array[UnitComposite]

# Query configuration structure
class QueryConfig:
	var radius_min: float = 0.0
	var radius_max: float = INF
	var angle_min: float = 0.0
	var angle_max: float = TAU
	var use_raycast: bool = false
	var raycast_mask: int = 1
	var filter_team: int = -1  # -1 means no filter
	var filter_layer: int = -1  # -1 means no filter

# Pre-computed data for optimization
var _cached_positions: Dictionary = {}
var _cached_distances: Dictionary = {}
var _cached_angles: Dictionary = {}

func _ready() -> void:
	if get_child_count() > 0 and get_child(0) is CollisionShape2D:
		var shape = get_child(0).shape
		if shape is CircleShape2D:
			shape.radius = get_parent().data.sight_data.view_range

func _physics_process(_delta: float) -> void:
	_update_neighbors()
	_update_cached_data()

func _update_neighbors() -> void:
	"""Scan for overlapping units and update neighbor lists"""
	var new_neighbors: Array[UnitComposite] = []
	var new_by_team: Dictionary = {}
	var new_by_layer: Dictionary = {}
	
	# Check overlapping bodies
	for body in get_overlapping_bodies():
		if body is UnitComposite and body != get_parent():
			new_neighbors.append(body)
			_index_unit(body, new_by_team, new_by_layer)
	
	# Check overlapping areas (in case units use Area2D children)
	for area in get_overlapping_areas():
		if area.get_parent() is UnitComposite:
			var unit = area.get_parent()
			if unit != get_parent() and unit not in new_neighbors:
				new_neighbors.append(unit)
				_index_unit(unit, new_by_team, new_by_layer)
	
	# Update the arrays
	neighbors = new_neighbors
	neighbors_by_team = new_by_team
	neighbors_by_layer = new_by_layer

func _index_unit(unit: UnitComposite, by_team: Dictionary, by_layer: Dictionary) -> void:
	"""Add unit to team and layer dictionaries"""
	if unit.data:
		var team: int = unit.data.body_data.team
		var layer: int = unit.data.body_data.layer
		
		# Add to team array
		if not by_team.has(team):
			by_team[team] = []
		by_team[team].append(unit)
		
		# Add to layer array
		if not by_layer.has(layer):
			by_layer[layer] = []
		by_layer[layer].append(unit)

func _update_cached_data() -> void:
	"""Pre-compute positions, distances, and angles once per frame"""
	var parent_pos: Vector2 = global_position
	var parent_vel: Vector2 = get_parent().facing
	
	# Clear old cache entries
	_cached_positions.clear()
	_cached_distances.clear()
	_cached_angles.clear()
	
	for unit in neighbors:
		if not is_instance_valid(unit):
			continue
		
		var rel_pos: Vector2 = unit.global_position - parent_pos
		var dist: float = rel_pos.length()
		
		_cached_positions[unit] = rel_pos
		_cached_distances[unit] = dist
		
		# Calculate angle relative to facing direction
		if dist > 0.001:  # Avoid division by zero
			var angle: float = parent_vel.angle_to(rel_pos)
			_cached_angles[unit] = abs(angle)

func query_neighbors(queries: Array[QueryConfig]) -> Dictionary:
	"""
	Queries neighbors based on multiple filter configurations.
	Returns a Dictionary with query indices as keys and filtered unit arrays as values.
	
	Example:
		var q1 = Sight.QueryConfig.new()
		q1.radius_min = 0.0
		q1.radius_max = 100.0
		q1.angle_min = 0.0
		q1.angle_max = PI / 4
		q1.use_raycast = true
		q1.filter_team = 1
		
		var q2 = Sight.QueryConfig.new()
		q2.radius_min = 100.0
		q2.radius_max = 300.0
		q2.filter_layer = 2
		
		var results = query_neighbors([q1, q2])
		var close_units = results[0]
		var far_units = results[1]
	"""
	var results: Dictionary = {}
	
	# Initialize result arrays
	for i in range(queries.size()):
		results[i] = []
	
	# Single pass through all neighbors
	for unit in neighbors:
		if not is_instance_valid(unit):
			continue
		
		var dist: float = _cached_distances.get(unit, INF)
		var angle: float = _cached_angles.get(unit, TAU)
		
		# Get unit properties once
		var unit_team: int = -1
		var unit_layer: int = -1
		if unit.data and unit.data.body_data:
			unit_team = unit.data.body_data.team
			unit_layer = unit.data.body_data.layer
		
		# Check each query against this unit
		for i in range(queries.size()):
			var q: QueryConfig = queries[i]
			
			# Fast team filter
			if q.filter_team != -1 and unit_team != q.filter_team:
				continue
			
			# Fast layer filter
			if q.filter_layer != -1 and unit_layer != q.filter_layer:
				continue
			
			# Fast radius check
			if dist < q.radius_min or dist > q.radius_max:
				continue
			
			# Fast angle check
			if angle < q.angle_min or angle > q.angle_max:
				continue
			
			# Raycast check (most expensive, do last)
			if q.use_raycast:
				if not _check_line_of_sight(unit, q.raycast_mask):
					continue
			
			results[i].append(unit)
	
	return results

func query_neighbors_single(config: QueryConfig) -> Array[UnitComposite]:
	"""Convenience method for single query"""
	var results = query_neighbors([config])
	var result: Array[UnitComposite] = []
	result.assign(results[0])
	return result

func query_by_radius(min_radius: float, max_radius: float) -> Array[UnitComposite]:
	"""Quick query by radius only"""
	var result: Array[UnitComposite] = []
	
	for unit in neighbors:
		if not is_instance_valid(unit):
			continue
		var dist: float = _cached_distances.get(unit, INF)
		if dist >= min_radius and dist <= max_radius:
			result.append(unit)
	
	return result

func query_by_angle(min_angle: float, max_angle: float) -> Array[UnitComposite]:
	"""Quick query by angle only"""
	var result: Array[UnitComposite] = []
	
	for unit in neighbors:
		if not is_instance_valid(unit):
			continue
		var angle: float = _cached_angles.get(unit, TAU)
		if angle >= min_angle and angle <= max_angle:
			result.append(unit)
	
	return result

func get_neighbors_by_team(team_id: int) -> Array[UnitComposite]:
	"""Get all neighbors of a specific team"""
	if neighbors_by_team.has(team_id):
		return neighbors_by_team[team_id].duplicate()
	return []

func get_neighbors_by_layer(layer_id: int) -> Array[UnitComposite]:
	"""Get all neighbors on a specific layer"""
	if neighbors_by_layer.has(layer_id):
		return neighbors_by_layer[layer_id].duplicate()
	return []

func _check_line_of_sight(unit: UnitComposite, mask: int) -> bool:
	"""Raycast check for line of sight"""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		unit.global_position
	)
	query.collision_mask = mask
	query.exclude = [get_parent()]  # Don't hit self
	
	var result = space_state.intersect_ray(query)
	
	# If we hit something, check if it's our target
	if result:
		return result.collider == unit
	
	# Nothing in the way
	return true

# Helper functions for common query patterns
func get_close_units(radius: float, angle: float = TAU, use_raycast: bool = false, team: int = -1) -> Array[UnitComposite]:
	"""Get units within radius and angle, optionally filtered by team"""
	var q = QueryConfig.new()
	q.radius_max = radius
	q.angle_max = angle
	q.use_raycast = use_raycast
	q.filter_team = team
	return query_neighbors_single(q)

func get_ring_units(min_radius: float, max_radius: float, angle: float = TAU, layer: int = -1) -> Array[UnitComposite]:
	"""Get units in a ring (donut shape), optionally filtered by layer"""
	var q = QueryConfig.new()
	q.radius_min = min_radius
	q.radius_max = max_radius
	q.angle_max = angle
	q.filter_layer = layer
	return query_neighbors_single(q)

func get_cone_units(radius: float, angle: float, use_raycast: bool = false, team: int = -1) -> Array[UnitComposite]:
	"""Get units in a cone in front of the unit, optionally filtered by team"""
	var q = QueryConfig.new()
	q.radius_max = radius
	q.angle_max = angle
	q.use_raycast = use_raycast
	q.filter_team = team
	return query_neighbors_single(q)
