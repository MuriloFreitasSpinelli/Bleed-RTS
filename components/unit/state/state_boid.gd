extends State
class_name BoidState

func enter(unit: UnitComposite):
	var boid_data: BoidData = unit.data.boid_data
	var initial_push = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * unit.data.stats_data.speed/10
	unit.apply_impulse(initial_push * unit.data.stats_data.speed)

func tick_frame(delta: float, unit: UnitComposite) -> String:
	return ""

func tick_physics(delta: float, unit: UnitComposite) -> String:
	simulate_boid(delta, unit)
	return ""

func exit(unit: UnitComposite):
	pass

func simulate_boid(delta: float, unit: UnitComposite):
	var boid_data: BoidData = unit.data.boid_data
	var velocity: Vector2 = unit.linear_velocity
	
	# Calculate steering forces using sight queries
	var c_vector: Vector2 = cohesion(unit)
	var s_vector: Vector2 = separation(unit)
	var a_vector: Vector2 = alignment(unit)
	#var n_vector: Vector2 = correct_direction(unit, boid_data)
	
	var steering = c_vector + s_vector + a_vector# + n_vector
	
	# Limit steering force
	if steering.length() > boid_data.max_force:
		steering = steering.normalized() * boid_data.max_force
	
	
	# Apply the steering force
	unit.apply_central_force(steering)
	
	# Speed limiting: gradually adjust velocity if too fast/slow
	var current_speed = velocity.length()
	if current_speed > 0:
		if current_speed > unit.data.stats_data.speed:
			# Dampen if too fast
			var reduction = (current_speed - unit.data.stats_data.speed) / current_speed
			unit.linear_velocity = velocity * (1.0 - reduction * 0.1)
		elif current_speed < unit.data.stats_data.speed * 0.5:
			# Boost if too slow
			unit.apply_central_force(velocity.normalized() * boid_data.max_force)

func cohesion(unit: UnitComposite) -> Vector2:
	var boid_data: BoidData = unit.data.boid_data
	
	var neighbors = unit.sight.get_cone_units(
		boid_data.cohesion_range,
		boid_data.view_cone,
		false,
		unit.data.body_data.team  # ✓ CORRECT
	)
	
	if neighbors.is_empty():
		return Vector2.ZERO
	
	var center_of_mass = Vector2.ZERO
	for n in neighbors:
		center_of_mass += n.global_position
	center_of_mass /= neighbors.size()
	
	var direction = (center_of_mass - unit.global_position).normalized()
	return direction * boid_data.cohesion_multiplier

func separation(unit: UnitComposite) -> Vector2:
	var boid_data: BoidData = unit.data.boid_data
	
	var neighbors = unit.sight.get_close_units(
		boid_data.separation_range,
		TAU,
		false,
		unit.data.body_data.team  # ✓ CORRECT
	)
	
	if neighbors.is_empty():
		return Vector2.ZERO
	
	var separation_vector = Vector2.ZERO
	var close_neighbors = 0
	
	for n in neighbors:
		var distance = unit.global_position.distance_to(n.global_position)
		if distance > 0:
			var direction = (unit.global_position - n.global_position).normalized()
			# Inverse square falloff for more natural separation
			separation_vector += direction / (distance * distance)
			close_neighbors += 1
	
	if close_neighbors > 0:
		separation_vector /= close_neighbors
		if separation_vector.length() > 0:
			return separation_vector.normalized() * boid_data.separation_multiplier
	
	return Vector2.ZERO
func alignment(unit: UnitComposite) -> Vector2:
	var boid_data: BoidData = unit.data.boid_data
	
	var neighbors = unit.sight.get_cone_units(
		boid_data.alignment_range,
		boid_data.view_cone,
		false,
		unit.data.body_data.team  # ✓ CORRECT
	)
	
	if neighbors.is_empty():
		return Vector2.ZERO
	
	var average_velocity = Vector2.ZERO
	for n in neighbors:
		average_velocity += n.linear_velocity
	average_velocity /= neighbors.size()
	
	if average_velocity.length() > 0:
		return average_velocity.normalized() * boid_data.alignment_multiplier
	
	return Vector2.ZERO

func correct_direction(unit: UnitComposite, boid_data: BoidData) -> Vector2:
	var normal_force: Vector2 = boid_data.normal_force
	
	if unit.linear_velocity.length() < 10:
		# If barely moving, just push in target direction
		return normal_force * boid_data.correction_multiplier
	
	# Calculate how aligned we are with target direction
	var velocity_normalized = unit.linear_velocity.normalized()
	var alignment = velocity_normalized.dot(normal_force)
	
	# alignment ranges from -1 (opposite) to 1 (aligned)
	# When alignment < threshold, apply correction
	if alignment < 0.4:
		# Calculate correction multiplier (stronger when going wrong way)
		var correction_strength = 1.0
		if alignment < 0:
			# Going backwards - apply strong correction
			correction_strength = lerp(1.0, 3.0, abs(alignment))
		else:
			# Going sideways - apply moderate correction
			correction_strength = lerp(1.0, 1.5, (0.4 - alignment) / 0.4)
		
		return normal_force * boid_data.correction_multiplier * correction_strength
	
	# When well-aligned, apply gentle guiding force
	return normal_force * boid_data.correction_multiplier * 0.3
