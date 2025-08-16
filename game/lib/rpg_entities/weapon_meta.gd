## Various enums and metadata which are used to describe weapons but are not
## stored as resources. Probably everything will become resources tho.
class_name WeaponMeta
extends Object

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
