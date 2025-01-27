class_name ItemWeapon
extends ItemEquipment

const WeaponProficiencyAbilities := preload("res://gui/weapon_proficiency_abilities/weapon_proficiency_abilities.gd")

@export var damage_dice: int

@export var type: WeaponMeta.TypeL3Id


func get_heading() -> String:
	return "Weapon: %s" % WeaponMeta.get_l3_type(type).name


func make_tooltip_content() -> RichTooltip.Content:
	var content := super.make_tooltip_content()
	var title := RichTooltip.StyledLabel.new("Grants proficincy abilities", Config.Palette.TOOLTIP_TEXT_SECONDARY)
	title.size = Config.FontSize.SMALL
	content.blocks.insert(1, title)
	var abilities := TooltipProficiencyAbilities.new()
	abilities.weapon = self
	content.blocks.insert(2, abilities)
	return content


@warning_ignore("missing_tool")
class TooltipProficiencyAbilities:
	extends RichTooltip.TooltipBlock

	@export var weapon: ItemWeapon


	func _render() -> Control:
		var ability := preload("res://game_resources/playground/a_spark.tres")
		var ability_line := RichTooltip.TooltipHeader.new()
		ability_line.icon = ability.icon
		ability_line.icon_size = 32
		ability_line.link = ability.make_tooltip_content()
		var prof_line := preload("res://gui/weapon_proficiency_abilities/weapon_proficiency_abilities.tscn").instantiate() as WeaponProficiencyAbilities
		prof_line.weapon = weapon
		return prof_line
