class_name BuildingView
extends PanelContainer
## Контрол для просмотра и изменения жилища.


## Жилище, отображаемое в данный момент.
@export var building: Building:
	set(value):
		if is_instance_valid(building):
			building.changed.disconnect(_update)
		building = value
		for child in _stats.get_children():
			child.building = building
		if is_instance_valid(building):
			building.changed.connect(_update)
		_update()

var _stats: VBoxContainer
var _storage: RichTextLabel


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_stats = %Stats
		_storage = %Storage


func _update() -> void:
	_storage.clear()

	if not is_instance_valid(building):
		return

	_storage.push_table(2)
	var storage_size: int = building.get_storage_size()
	for res_type in Building.ResourceType.size():
		_storage.push_cell()
		_storage.add_image(Building.get_resource_icon(res_type))
		_storage.add_text(" " + Building.get_resource_name(res_type))
		_storage.pop() # cell
		_storage.push_cell()
		_storage.push_paragraph(HORIZONTAL_ALIGNMENT_RIGHT)
		_storage.add_text("%d/%d" % [building.get_resource_amount(res_type), storage_size])
		_storage.pop() # paragraph
		_storage.pop() # cell
	_storage.pop() # table


func _on_close_button_pressed() -> void:
	hide()
