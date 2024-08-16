## Represents drag and drop "process" of given Control. This class shouldn't be
## used directly and instead use one of the subclasses that provide additional
## information about what's being dragged, since this class only handles the
## visual part.
class_name DragDropRequest
extends RefCounted

## Emitted at the end of the drag and drop. Should be primarily used by the
## drag initiator to indicate in the source that the content is no longer
## dragged.
signal dropped()

## Control node which should follow the mouse while dragging
var control: Control


func _init(ctrl: Control):
	control = ctrl
