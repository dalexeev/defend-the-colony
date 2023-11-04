class_name BuildingViewStat
extends HBoxContainer
## Контрол для просмотра и повышения уровня характеристики жилища.


## Жилище, отображаемое в данный момент.
@export var building: Building:
	set(value):
		if is_instance_valid(building):
			building.changed.disconnect(_update)
		building = value
		if is_instance_valid(building):
			building.changed.connect(_update)
		_update()

## Характеристика жилища, отображаемая в данный момент.
@export var stat: Building.Stat

var _info_label: Label
var _upgrade_button: Button
var _upgrade_panel: PanelContainer
var _upgrade_label: RichTextLabel
var _confirmation_dialog: ConfirmationDialog


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_info_label = %InfoLabel
		_upgrade_button = %UpgradeButton
		_upgrade_panel = %UpgradePanel
		_upgrade_label = %UpgradeLabel
		_confirmation_dialog = %ConfirmationDialog


func _update() -> void:
	if not is_instance_valid(building):
		_info_label.text = ""
		_upgrade_button.disabled = true
		_upgrade_panel.hide()
		return

	var level: int = building.get_stat_level(stat)
	var params: Dictionary = Building.get_stat_params(stat, level)

	var info_text: String = "%s  ур. %s" % [Building.get_stat_name(stat).to_upper(), level]
	for param_id in params:
		info_text += "\n%s: %d" % [Building.get_stat_param_name(param_id), params[param_id]]
	_info_label.text = info_text

	_upgrade_button.disabled = not building.can_upgrade(stat)

	_upgrade_label.clear()

	var new_level: int = level + 1
	if new_level >= Building.STAT_MAX_LEVEL:
		_upgrade_label.add_text("Ур. %d - Максимальный уровень!" % level)
	else:
		var new_params: Dictionary = Building.get_stat_params(stat, new_level)
		_upgrade_label.add_text("Ур. %d → " % level)
		_upgrade_label.push_color(Color.GREEN)
		_upgrade_label.add_text(str(new_level))
		_upgrade_label.pop() # color

		for param_id in new_params:
			_upgrade_label.add_text("\n%s: %d → " % [
				Building.get_stat_param_name(param_id),
				params[param_id]],
			)
			_upgrade_label.push_color(Color.GREEN)
			_upgrade_label.add_text(str(new_params[param_id]))
			_upgrade_label.pop() # color

		var cost: Dictionary = Building.get_upgrade_cost(stat, new_level)
		if not cost.is_empty():
			_upgrade_label.add_text("\n\nСтоимость:\n")

			_upgrade_label.push_table(2)
			for res_type in cost:
				_upgrade_label.push_cell()
				_upgrade_label.push_paragraph(HORIZONTAL_ALIGNMENT_RIGHT)
				var res_cost: int = cost[res_type]
				if building.get_resource_amount(res_type) < res_cost:
					_upgrade_label.push_color(Color.RED)
					_upgrade_label.add_text(str(res_cost))
					_upgrade_label.pop() # color
				else:
					_upgrade_label.add_text(str(res_cost))
				_upgrade_label.add_text(" x")
				_upgrade_label.pop() # paragraph
				_upgrade_label.pop() # cell

				_upgrade_label.push_cell()
				_upgrade_label.add_image(Building.get_resource_icon(res_type))
				_upgrade_label.add_text(" " + Building.get_resource_name(res_type))
				_upgrade_label.pop() # cell
			_upgrade_label.pop() # table


func _on_upgrade_button_mouse_entered() -> void:
	if is_instance_valid(building):
		_upgrade_panel.global_position = Vector2(
			_upgrade_button.global_position.x + _upgrade_button.size.x + 4.0,
			_upgrade_button.global_position.y,
		)
		_upgrade_panel.size.y = _upgrade_label.get_content_height() + 16.0
		_upgrade_panel.show()
	else:
		_upgrade_panel.hide()


func _on_upgrade_button_mouse_exited() -> void:
	_upgrade_panel.hide()


func _on_upgrade_button_pressed() -> void:
	_confirmation_dialog.dialog_text = "Вы действительно хотите повысить «%s»?" \
			% Building.get_stat_name(stat)
	_upgrade_panel.hide()
	_confirmation_dialog.popup_centered()


func _on_confirmation_dialog_confirmed() -> void:
	if is_instance_valid(building):
		building.upgrade(stat)
