extends State
class_name StateCombat

func enter(unit: UnitComposite):
	unit.linear_damp = 20
	print("combat")

func tick_frame(delta: float, unit: UnitComposite) -> String:
	return ""

func tick_physics(delta: float, unit: UnitComposite) -> String:
	var targets = unit.sight.get_cone_units(unit.data.combat_data.attack_range, unit.data.sight_data.view_angle)
	if targets.is_empty():
		return "boid"
	return ""

func exit(unit: UnitComposite):
	unit.linear_damp = 0
