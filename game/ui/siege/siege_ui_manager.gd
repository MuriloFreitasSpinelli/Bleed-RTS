extends Control
class_name SiegeUiManager

@onready var unit_selector: UnitSelector = $VBoxContainer/Footer/UnitSelector

@export var army_data: ArmyData

func _ready() -> void:
	setup(army_data)

func setup(army_data: ArmyData):
	unit_selector.setup(army_data)
	
