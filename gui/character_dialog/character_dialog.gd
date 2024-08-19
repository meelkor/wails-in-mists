extends BoxContainer
class_name CharacterDialog

# Signal emitted when the dialog wants to be closed
signal close()

var _character: PlayableCharacter


func _ready():
	# Slot nodes should have their slotI already set
	var slots = find_children("", "ItemSlotButton")
	for slot in slots:
		if slot is ItemSlotButton:
			slot.container = _character.equipment


## Set inputs, should be called before adding node to tree
func setup(character: PlayableCharacter):
	_character = character


# Escape handler
func _input(event: InputEvent) -> void:
	if event.is_action("dialog_close"):
		close.emit()
