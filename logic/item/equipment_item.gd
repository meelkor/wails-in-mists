extends GeneralItem
class_name EquipmentItem

var model_path: String

var modifiers: Array[ItemModifier]

var slot: Array[Equipment.Slot] = []


# TODO: Following properties related to visuals should be encapsulated into
# some new scene, so they are reusable, since often many items will share the
# same set of visual properties.

# Resource path of the mesh (GLB)
var model: String

# Name of the bone this weapon should attach to. See AttachableBone enum. If
# not provided, mesh model mesh is expected to be rigged to the character
# skeleton.
var model_bone: String

# Resource path of the image texture which should be applied on character's
# skin while this item is equipped
var character_texture: String
