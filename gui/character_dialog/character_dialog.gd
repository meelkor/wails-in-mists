extends BoxContainer
class_name CharacterDialog

# Signal emitted when the dialog wants to be closed
signal close()

var _character: PlayableCharacter

@onready var _attr_value_labels = {
	CharacterAttributes.FLESH: %FleshAttrValue,
	CharacterAttributes.WILL: %WillAttrValue,
	CharacterAttributes.FINESSE: %FinesseAttrValue,
	CharacterAttributes.INSIGHT: %InsightAttrValue,
	CharacterAttributes.FAITH: %FaithAttrValue,
}

@onready var _name_label: Label = %CharacterNameLabel

func _ready():
	# Slot nodes should have their slotI already set
	var slots = find_children("", "ItemSlotButton")
	for slot in slots:
		if slot is ItemSlotButton:
			slot.container = _character.equipment
	_character.changed.connect(_update_content)
	_update_content()
	(%RichTextLabel as RichTextLabel).meta_hover_started.connect(func (meta):
		print(meta)
	)


## Set inputs, should be called before adding node to tree
func setup(character: PlayableCharacter):
	_character = character


# Escape handler
func _input(event: InputEvent) -> void:
	if event.is_action("dialog_close"):
		close.emit()


func _update_content():
	_name_label.text = _character.name
	for attr in CharacterAttributes.get_all():
		(_attr_value_labels[attr] as Label).text = str(_character.get_attribute(attr))

