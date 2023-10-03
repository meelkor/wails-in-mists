class_name TerrainController
extends Node

signal terrain_clicked(pos: Vector3)

var selecting_from: Vector2 = Vector2.ZERO

func _on_terrain_input_event(_camera, event: InputEvent, position: Vector3, _normal, _idx):
	if event is InputEventMouseButton:
		if event.is_released():
			if event.button_index == MOUSE_BUTTON_RIGHT:
				terrain_clicked.emit(position)
