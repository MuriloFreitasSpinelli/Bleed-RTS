extends HBoxContainer
class_name UnitSelector

var army_data: ArmyData
var selected_data: UnitData
var selected_button: Button

func setup(ad: ArmyData):
	army_data = ad
	for u in army_data.units:
		print("creating")
		var button = Button.new()
		button.toggle_mode = true
		button.text = u.name
		button.custom_minimum_size.x = 150
		button.toggled.connect(on_toggle.bind(button))
		add_child(button)
		button.visible = true

func on_toggle(on_toggle: bool, b: Button):
	if selected_button == b:
		selected_button = null
		selected_data = null
	if selected_button != b:
		selected_button = b
		selected_data = army_data.units.get(b.get_index())
	print(selected_data.name)
