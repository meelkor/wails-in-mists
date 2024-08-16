class_name ItemEquipment
extends Item

enum Slot {
	MAIN = 0,
	OFF = 1,
	ARMOR = 2,
	ACCESSORY = 3,
}

@export var modifiers: Array[Modifier]

@export var slot: Array[Slot] = []

# TODO: Following properties related to visuals should be encapsulated into
# some new scene, so they are reusable, since often many items will share the
# same set of visual properties.
@export var model: PackedScene

# Name of the bone this weapon should attach to. See AttachableBone enum. If
# not provided, mesh model mesh is expected to be rigged to the character
# skeleton.
@export var model_bone: String

# Resource path of the image texture which should be applied on character's
# skin while this item is equipped
@export var character_texture: String
