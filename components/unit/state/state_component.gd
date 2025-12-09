extends Node
class_name StateComponent

var unit: UnitComposite
@export var states: Dictionary[String, State]
@export var starting_state: String
var current_state: State

func _ready() -> void:
	unit = get_parent()
	print(unit)
	current_state = states.get(starting_state)
	current_state.enter(unit)

func tick_frame(delta: float) -> void:
	var next_state_key = current_state.tick_frame(delta, unit)
	if next_state_key == "":
		return
	if states.find_key(next_state_key) == null:
		print("Dont know the state")
		return
	current_state.exit(unit)
	current_state = states.get(next_state_key)
	current_state.enter(unit)

func tick_physics(delta: float) -> void:
	var next_state_key = current_state.tick_physics(delta, unit)
	if next_state_key == "":
		return
	if states.find_key(next_state_key) == null:
		print("Dont know the state")
		return
	current_state.exit(unit)
	current_state = states.get(next_state_key)
	current_state.enter(unit)
