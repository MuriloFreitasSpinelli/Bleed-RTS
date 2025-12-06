extends Node2D
class_name Spawner

@export var siege_ui: SiegeUiManager
@export var base_unit_scene: PackedScene = preload("res://composites/unit/unit_composite.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Check which button was pressed (e.g., BUTTON_LEFT for left click)
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Get the mouse position in global coordinates
			var mouse_global_position: Vector2 = get_global_mouse_position()
			var unit_data: UnitData = siege_ui.unit_selector.selected_data
			if unit_data == null:
				return
			var unit: UnitComposite = base_unit_scene.instantiate()
			unit.load_data(unit_data)
			unit.position = mouse_global_position
			print("CREATED")
			add_child(unit)
