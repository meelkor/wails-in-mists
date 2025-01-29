## Modifier which sets weapon's WeaponType and grants predefined abilities
## based that type, since every weapon (possibly excluding some unique weapons)
## should grant basic attacks. Number of granted variants of the basic attack
## is based on character's proficiency in the weapon type and the weapon's
## quality
##
## As an experiment I've moved WeaponType from weapon's properties into
## modifier so type-less weapons are now possible. Might have been a moronic
## idea and I'll move it back soon tho.
class_name ModifierWeaponType
extends Modifier

const WeaponProficiencyAbilities := preload("res://gui/weapon_proficiency_abilities/weapon_proficiency_abilities.gd")

@export var type: WeaponType


func get_abilities(character: GameCharacter, _source: ModifierSource) -> Array[AbilityGrant]:
	var wpn := character.equipment.get_entity(ItemEquipment.Slot.MAIN) as WeaponRef
	if wpn:
		var out: Array[AbilityGrant] = []
		var proficiency := character.get_proficiency(type)
		for ability in type.l1_abilities:
			out.append(AbilityGrant.new(ability, proficiency >= 1))
		for ability in type.l2_abilities:
			out.append(AbilityGrant.new(ability, proficiency >= 2))
		for ability in type.l3_abilities:
			out.append(AbilityGrant.new(ability, proficiency >= 3))
		return out
	else:
		push_warning("ModifierWeaponType used without weapon")
		return []


func make_tooltip_blocks() -> Array[RichTooltip.TooltipBlock]:
	var abilities := TooltipProficiencyAbilities.new()
	abilities.type = type
	return [
		RichTooltip.StyledLabel.new("Grants proficincy abilities", Config.Palette.TOOLTIP_TEXT_SECONDARY),
		abilities,
	]


# todo: ditch tooltip blocks (or at least allow using control nodes instead of
# block wrappers directly)
@warning_ignore("missing_tool")
class TooltipProficiencyAbilities:
	extends RichTooltip.TooltipBlock

	@export var type: WeaponType


	func _render() -> Control:
		var prof_line := preload("res://gui/weapon_proficiency_abilities/weapon_proficiency_abilities.tscn").instantiate() as WeaponProficiencyAbilities
		prof_line.type = type
		return prof_line
