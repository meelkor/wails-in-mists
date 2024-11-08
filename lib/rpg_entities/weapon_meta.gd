## Various enums and metadata which are used to describe weapons but are not
## stored as resources. That way the internal implementation in this file
## doesn't affect the rest of the game since all the game uses are the enum
## IDs.
class_name WeaponMeta
extends Object

enum TypeL1Id {
	MELEE,
	RANGED,
	CASTING,
}

enum TypeL2Id {
	ONE_HANDED,
}

enum TypeL3Id {
	SHORT_SWORD,
}

enum WpnMaterial {
	IRON,
	STEEL,
	SCORCHING_STEEL,
}

enum Quality {
	 ## Special default value for unique weapon templates not affected by
	 ## quality
	NONE = 0,
	MIST_TOUCHED = 10,
	POOR = 20,
	REGULAR = 30,
	FINE = 40,
	EXCELLENT = 50,
}

static var _L1_TYPES: Array[TypeL1] = [
	TypeL1.new({
		"id": TypeL1Id.MELEE,
		"name": "Melee"
	}),
	TypeL1.new({
		"id": TypeL1Id.RANGED,
		"name": "Ranged"
	}),
	TypeL1.new({
		"id": TypeL1Id.CASTING,
		"name": "Casting"
	}),
]

static var _L2_TYPES: Array[TypeL2] = [
	TypeL2.new({
		"id": TypeL2Id.ONE_HANDED,
		"parent": TypeL1Id.MELEE,
		"name": "One handed",
	}),
]

static var _L3_TYPES: Array[TypeL3] = [
	TypeL3.new({
		"id": TypeL3Id.SHORT_SWORD,
		"parent": TypeL2Id.ONE_HANDED,
		"name": "Short sword",
	}),
]

static var _l1_dict := {}
static var _l2_dict := {}
static var _l3_dict := {}


static func get_l1_type(id: TypeL1Id) -> TypeL1:
	if _l1_dict.is_empty():
		for type in _L1_TYPES:
			_l1_dict[type.id] = type
	return _l1_dict[id]


static func get_l2_type(id: TypeL2Id) -> TypeL2:
	if _l2_dict.is_empty():
		for type in _L2_TYPES:
			_l2_dict[type.id] = type
	return _l2_dict[id]


static func get_l3_type(id: TypeL3Id) -> TypeL3:
	if _l3_dict.is_empty():
		for type in _L3_TYPES:
			_l3_dict[type.id] = type
	return _l3_dict[id]


class TypeL1:
	extends Object

	var id: TypeL1Id
	var name: String

	func _init(src: Dictionary) -> void:
		Utils.Dict.assign(self, src)


class TypeL2:
	extends Object

	var id: TypeL2Id
	var name: String
	var parent: TypeL1

	func _init(src: Dictionary) -> void:
		Utils.Dict.assign(self, src)


class TypeL3:
	extends Object

	var id: TypeL3Id
	var name: String
	var parent: TypeL2

	func _init(src: Dictionary) -> void:
		Utils.Dict.assign(self, src)
