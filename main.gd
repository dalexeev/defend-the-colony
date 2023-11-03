extends Node


@onready var _building_view: BuildingView = $BuildingView


func _ready() -> void:
	get_tree().root.min_size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"),
	)


func _on_main_building_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"click"):
		_building_view.show()
