## ItemRef specific for weapons, which holds extra properties so we can use
## single weapon resource for multiple instances of the weapon with values such
## as bonus, quality, material different.
class_name WeaponRef
extends ItemRef


var quality: WeaponMeta.Quality = WeaponMeta.Quality.NONE

var material: int = WeaponMeta.WpnMaterial.IRON

## Maybe the bonus should be contained in quality and it's not really needed
var bonus: int = 0


## Get weapon's damage dice with all weapon reference-specific bonuses counted
## in
func get_damage_dice() -> int:
	return get_weapon().damage_dice


## Just typed access to the referenced item
func get_weapon() -> ItemWeapon:
	return item
