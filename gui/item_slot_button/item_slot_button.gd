## Button which may hold single item, displaying its icon and opening its
## tooltip on hover. For use inside inventory, containers etc.
##
## todo: very similar to ability bar button, how to consolidate those two?
class_name ItemSlotButton
extends Control

## Emits when player doubleclicks or otherwise uses the slot
signal used()

var di = DI.new(self)

@onready var _drag_drop_host: DragDropHost = di.inject(DragDropHost)

@onready var _drag_drop_bridge = _drag_drop_host.create_listener(self)

## Ignore mouse (incl. dragging into) events when disabled
@export var disabled: bool = false

## ItemContainer instance for which this node represents single slot
@export var container: ItemContainer

## Slot number in the source map
@export var slot_i: int

@onready var _entity_icon = %EntityIcon

var _mouse_press_event: InputEventMouseButton

var item: Item:
	get:
		return container.items.get(slot_i, null) if container else null

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_drag_drop_bridge.hovered.connect(func (request):
		if request is DragDropRequestItem and not disabled:
			_entity_icon.hovered = true
		else:
			_entity_icon.hovered = false
	)

	_drag_drop_bridge.dropped.connect(func (request: DragDropRequest):
		if request is DragDropRequestItem: if not disabled:
			var to_add = request.container.items[request.slot_i]
			var result = container.add_item(to_add, slot_i)
			if result.ok:
				var back_result = request.container.add_item(result.item, request.slot_i)
				if not back_result.ok:
					if container.add_item(result.item).ok:
						request.container.items.erase(request.slot_i)
					else:
						push_warning("Could not switch items, item disappeared for good")
						# todo: drop the item on the ground or something
						# somehow??

	)


func _process(_delta: float) -> void:
	_entity_icon.icon = item.icon if item else null
	_entity_icon.dimmed = disabled


func _on_mouse_entered() -> void:
	if item and not disabled:
		_entity_icon.hovered = true
		_open_tooltip()


func _on_mouse_exited() -> void:
	if item and not disabled:
		_entity_icon.hovered = false
		_close_tooltip()


func _gui_input(e: InputEvent):
	if item:
		if e is InputEventMouseButton:
			if e.double_click:
				used.emit()
			elif e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_mouse_press_event = e
			else:
				_mouse_press_event = null
		elif e is InputEventMouseMotion:
			if _mouse_press_event != null:
				if e.position.distance_to(_mouse_press_event.position) > 5:
					_start_drag_and_drop()
					_mouse_press_event = null


func _open_tooltip() -> void:
	if not _drag_drop_host.active:
		var item_tooltip = preload("res://gui/rich_tooltip/item_tooltip/item_tooltip.tscn").instantiate()
		item_tooltip.item = item
		FloatingTooltipSpawner.open_tooltip(self, item_tooltip)


func _close_tooltip() -> void:
	FloatingTooltipSpawner.close_tooltip()


func _start_drag_and_drop() -> void:
	var dragged_icon = _entity_icon.duplicate()
	_entity_icon.ghost = true
	var dd_request = DragDropRequestItem.new(dragged_icon)
	dd_request.container = container
	dd_request.slot_i = slot_i
	_drag_drop_host.drag(dd_request)
	await dd_request.dropped
	_entity_icon.ghost = false
