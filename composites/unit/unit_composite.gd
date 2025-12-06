extends RapierRigidBody2D
class_name UnitComposite

@export var data: UnitData

@onready var state_machine: StateComponent = $StateComponent
@onready var modifiers: ModifiersComponent = $ModifiersComponent
@onready var action_handler: ActionComponent = $ActionComponent
@onready var sight: SightComponent = $SightComponent
@onready var audio: AudioComponent = $AudioComponent
@onready var visual: VisualComponent = $VisualComponent

var facing: Vector2 = Vector2.LEFT

func load_data(new_data: UnitData):
	data = new_data

func _process(delta: float) -> void:
	state_machine.tick_frame(delta)
	pass

func _physics_process(delta: float) -> void:
	if linear_velocity.length() > 0:
		facing = linear_velocity
	state_machine.tick_physics(delta)
