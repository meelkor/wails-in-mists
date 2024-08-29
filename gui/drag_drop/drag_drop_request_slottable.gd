## Drag and drop request used for dragging slottable resource from one
## SlotContainer to another
class_name DragDropRequestSlottable
extends DragDropRequest


## Item container we are dragging from
var container: SlotContainer

## The exact slot in the container the dragged entity is in
var slot_i: int


func get_entity() -> Slottable:
	return container.get_entity(slot_i)
