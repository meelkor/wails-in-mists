## Bridge between droppable area (e.g. ItemSlotButton) and the DragDropHost
## which handles the actual dragging.
##
## Returned by the DragDropHost when registering new control as drop target
class_name DragDropListener
extends RefCounted


## Signal emitted whenever the source control becomes hovered or unhovered
## so it can update its visuals. The request is provided so it can check
## whether the control even supports the dragged entity (e.g. so inventory
## doesn't react to dragging abilities)
signal hovered(result: DragDropRequest)

## Emitted when some request is dropped into the source control
signal dropped(result: DragDropRequest)
