extends BoxContainer
class_name CharacterDialog

# Signal emitted when the dialog wants to be closed
signal close()

var di := DI.new(self)

const SlotLinesButton := preload("res://gui/slot_button/slot_lines_button.gd")

@onready var _controlled_characters: ControlledCharacters = di.inject(ControlledCharacters)

var _character: PlayableCharacter

@onready var _attr_value_labels := {
	CharacterAttributes.FLESH: %FleshAttrValue,
	CharacterAttributes.WILL: %WillAttrValue,
	CharacterAttributes.FINESSE: %FinesseAttrValue,
	CharacterAttributes.INSIGHT: %InsightAttrValue,
	CharacterAttributes.FAITH: %FaithAttrValue,
}

@onready var _name_label: Label = %CharacterNameLabel

@onready var _ability_grid := %AbilityGrid as GridContainer

@onready var _equipped_talents := %EquippedTalents as VBoxContainer

@onready var _available_talents := %AvailableTalents as VBoxContainer

func _ready() -> void:
	# Slot nodes should have their slotI already set
	for slot: SlotButton in find_children("", "SlotButton"):
		slot.container = _character.equipment
	_character.changed.connect(_update_content)
	_character.abilities.changed.connect(_update_content)
	_controlled_characters.select(_character)
	_update_content()


## Set inputs, should be called before adding node to tree
func setup(character: PlayableCharacter) -> void:
	_character = character


# Escape handler
func _input(event: InputEvent) -> void:
	if event.is_action("dialog_close"):
		close.emit()


func _update_content() -> void:
	_name_label.text = _character.name
	for attr in CharacterAttributes.get_all():
		var label: Label = _attr_value_labels.get(attr)
		label.text = str(_character.get_attribute(attr))
	# todo: reuse slot nodes
	Utils.Nodes.clear_children(_ability_grid)
	for i in range(_character.abilities.size()):
		var slot_button: SlotButton = preload("res://gui/slot_button/slottable_icon_button.tscn").instantiate()
		slot_button.container = _character.abilities
		slot_button.slot_i = i
		_ability_grid.add_child(slot_button)

	Utils.Nodes.clear_children(_available_talents)
	var available_talents := _character.available_talents.get_all()
	for slot_i in available_talents.size():
		var slot_button: SlotLinesButton = preload("res://gui/slot_button/slot_lines_button.tscn").instantiate()
		slot_button.use_on_doubleclick = true
		slot_button.slot_i = slot_i
		slot_button.container = _character.available_talents
		slot_button.used.connect(_auto_equip_available_talent.bind(slot_i), CONNECT_DEFERRED)
		_available_talents.add_child(slot_button)

	Utils.Nodes.clear_children(_equipped_talents)
	for slot_i in range(_character.get_talent_slot_count()):
		var slot_button: SlotLinesButton = preload("res://gui/slot_button/slot_lines_button.tscn").instantiate()
		slot_button.use_on_doubleclick = true
		slot_button.slot_i = slot_i
		slot_button.container = _character.talents
		slot_button.used.connect(_character.talents.erase.bind(slot_i), CONNECT_DEFERRED)
		_equipped_talents.add_child(slot_button)


## Try to equip available talent if enough space
func _auto_equip_available_talent(slot_i: int) -> void:
	# todo: should be handled by the talentlist instance itself, but currently
	# has no idea about the max number of talents.
	if _character.get_talent_slot_count() > _character.talents.size():
		_character.talents.add_entity(_character.available_talents.get_entity(slot_i))
