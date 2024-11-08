## Button which may hold single entity, displaying its icon and opening its
## tooltip on hover. For use inside inventory, containers etc.
##
## This node contains no entity-specific logic (e.g. what entities can be
## dragged here etc.), this is general UI node, all logic is handled by the
## provided SlotContainer instance which this node then accesses.
class_name SlotButton
extends Control

## Emits when player doubleclicks or otherwise uses the slot
signal used()

const ItemTooltip = preload("res://gui/rich_tooltip/item_tooltip/item_tooltip.gd")

var di := DI.new(self)

@onready var _drag_drop_host: DragDropHost = di.inject(DragDropHost)

@onready var _drag_drop_bridge := _drag_drop_host.create_listener(self)

## Ignore mouse (incl. dragging into) events when disabled
@export var disabled: bool = false

## SlotContainer instance for which this node represents single slot
@export var container: SlotContainer

## Slot number in the source map
@export var slot_i: int

@onready var _icon := %EntityIcon as SlottableIcon

@export var use_on_doubleclick: bool = false

var _mouse_press_event: InputEventMouseButton

var entity: Slottable:
	get:
		return container.get_entity(slot_i) if container else null

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_drag_drop_bridge.hovered.connect(_on_drag_hover)

	_drag_drop_bridge.dropped.connect(_on_drag_drop)


func _on_drag_hover(request: DragDropRequest) -> void:
	_icon.hovered = _validate_request(request) != null


func _on_drag_drop(any_request: DragDropRequest) -> void:
	var request := _validate_request(any_request)
	if request:
		var result := container.add_entity(request.get_entity(), slot_i)
		if result.ok and not request.container.is_static():
			var back_result := request.container.add_entity(result.entity, request.slot_i)
			if not back_result.ok:
				if container.add_entity(result.entity).ok:
					request.container.erase(request.slot_i)
				else:
					push_warning("Could not switch items, item disappeared for good")
					# todo: drop the item on the ground or something
					# somehow??


## Check whether this button accepts the dragged entity and return the typed
## request if it does
func _validate_request(any_request: DragDropRequest) -> DragDropRequestSlottable:
	var request := any_request as DragDropRequestSlottable
	if request and not disabled and container.is_taker():
		var dragged_entity := request.container.get_entity(request.slot_i)
		if container.can_assign(dragged_entity, slot_i):
			return request
	return null


func _process(_delta: float) -> void:
	_icon.icon = entity.icon if entity else null
	_icon.dimmed = disabled


func _on_mouse_entered() -> void:
	if entity and not disabled and not _drag_drop_host.active:
		_icon.hovered = true
		_open_tooltip()


func _on_mouse_exited() -> void:
	if entity and not disabled:
		_icon.hovered = false
		_close_tooltip()


func _gui_input(e: InputEvent) -> void:
	if entity:
		var e_btn := e as InputEventMouseButton
		var e_motion := e as InputEventMouseMotion
		if e_btn and e_btn.button_index == MOUSE_BUTTON_LEFT:
			if e_btn.double_click:
				if use_on_doubleclick:
					used.emit()
			elif e_btn.pressed:
				_mouse_press_event = e
			elif not e_btn.pressed and _mouse_press_event != null:
				if not use_on_doubleclick:
					used.emit()
				_mouse_press_event = null
			else:
				_mouse_press_event = null
		elif e_motion:
			if _mouse_press_event != null:
				if e_motion.position.distance_to(_mouse_press_event.position) > 5:
					_start_drag_and_drop()
					_mouse_press_event = null


func _open_tooltip() -> void:
	if not _drag_drop_host.active:
		var ref := entity as ItemRef
		if ref:
			var item_tooltip := preload("res://gui/rich_tooltip/item_tooltip/item_tooltip.tscn").instantiate() as ItemTooltip
			item_tooltip.ref = entity
			FloatingTooltipSpawner.open_tooltip(self, item_tooltip)


func _close_tooltip() -> void:
	FloatingTooltipSpawner.close_tooltip()


func _start_drag_and_drop() -> void:
	var dragged_icon := _icon.duplicate() as Control
	_icon.ghost = true
	var dd_request := DragDropRequestSlottable.new(dragged_icon)
	dd_request.container = container
	dd_request.slot_i = slot_i
	_drag_drop_host.drag(dd_request)
	var moved: bool = await dd_request.dropped
	if not moved and container.can_remove():
		container.erase(slot_i)
	_icon.ghost = false
