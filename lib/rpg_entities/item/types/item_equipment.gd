class_name ItemEquipment
extends Item

enum Slot {
	MAIN = 0,
	OFF = 1,
	ARMOR = 2,
	ACCESSORY = 3,
}

## Defines the actual bonuses the equipment grants
@export var modifiers: Array[Modifier]

@export var slot: Array[Slot] = []

## TODO: Following properties related to visuals should be encapsulated into
## some new scene, so they are reusable, since often many items will share the
## same set of visual properties.
@export var model: PackedScene

## Name of the bone this weapon should attach to when not in combat. See
## AttachableBone constants. If not provided, the is expected to be rigged to
## the character skeleton.
@export var free_bone: String

## Same as free_bone but in combat
@export var combat_bone: String

## Image texture which should be applied on character's skin while this item is
## equipped
##
## todo: find out whether referencing the image diractly is feasible (whether
## the image is loaded into memory when working with this resource... in which
## case I'd need to use just string path I guess)
@export var character_texture: Image


## Create Source instance for modifers so they can read name of the parent
## entity.
func to_source() -> ModifierSource:
	var src := ModifierSource.new()
	src.name = name
	src.entity = self
	return src
