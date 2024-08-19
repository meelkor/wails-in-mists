## Control which displays dragged and serves as a bridge between the various
## controls allowing drag and dropping.
##
## To start drag and drop call `drag` with dragged entity-specific requrest.
##
## To listen to drops on control, create listener using create_listener in the
## control and listen to its signals. The listener should handle all the logic
## related to finished drag and drop (including removal of the entity from its
## source if needed).
class_name DragDropHost
extends Control

var _request: DragDropRequest

## Currently hovered bridge that we'll drop into when mouse btn unpressed
var _hovered_listener: DragDropListener

## Whether player is currently dragging some object
var active: bool:
	get:
		return !!_request

## Start a drag and drop process. Aside from the control node that should
## follow mouse cursor, the request should contain everything the target
## listener may need to resolve the drag and drop.
func drag(dd_request: DragDropRequest) -> void:
	_request = dd_request
	_request.control.top_level = true
	_request.control.visible = false
	add_child(_request.control)


## Register given control node as "droppable area" and return DragDropListener
## which the control should use to listen to drop events.
func create_listener(node: Control) -> DragDropListener:
	var bridge = DragDropListener.new()
	node.mouse_entered.connect(func ():
		if _request:
			bridge.hovered.emit(_request)
			_hovered_listener = bridge
	)
	node.mouse_exited.connect(func ():
		if _request:
			bridge.hovered.emit(null)
			_hovered_listener = null
	)
	return bridge


## Move the dragged control if request is active whenever the mouse moves
func _input(event: InputEvent) -> void:
	if _request:
		_request.control.visible = true
		if event is InputEventMouseMotion:
			_request.control.global_position = event.position - Vector2(8, 8)
		elif event is InputEventMouseButton:
			if not event.pressed:
				if _hovered_listener:
					_hovered_listener.hovered.emit(null)
					_hovered_listener.dropped.emit(_request)
				_request.dropped.emit()
				remove_child(_request.control)
				_request = null
