## Drag and drop request used for dragging files from one container
## (ItemContainer instance) to another
class_name DragDropRequestItem
extends DragDropRequest


## Item container we are dragging from
var container: ItemContainer

## The exact slot in the container the dragged item is in
var slot_i: int
