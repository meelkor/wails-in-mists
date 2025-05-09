@icon("res://resources/class_icons/character_spawner.svg")

class_name NpcTemplate
extends Resource

@export var template_id: String
@export var default_name: String
@export var default_is_enemy: bool
@export var attributes: Dictionary[CharacterAttribute, int]
## Talents to grant the created characters. TalentPack is then automatically
## creatd for each talent, since for NPCs it doesn't really matter how talents
## are organized.q
##
## TODO: after I do the character visuals/props/position split thing, it should
## be wrapped in some CharacterProperties class which would then be just
## duplicated
@export var talents: Array[Talent]
## Test properties, should be part of visuals thing
@export var hair_color: Color

## Create GameCharacter instance based on this template's settings
##
## Accept some NpcTemplateOverrides instance so spawner can create unique
## characters based on existing template
func make_game_character() -> NpcCharacter:
	var npc := NpcCharacter.new()
	npc.name = default_name
	# TODO: create stuff like this should be in some HumanNpcTemplate sub-class
	# resource
	#
	# TODO: try to create import script which creates some hair resource
	# chara.hair = load("res://models/hair0.glb").instantiate()
	npc.hair = load("res://models/hair0.glb")
	npc.hair_color = hair_color
	npc.enemy = default_is_enemy
	npc.attributes = attributes
	for talent in talents:
		var pack := TalentPack.new([talent])
		npc.talents.add_entity(pack)
	# todo: for now until separate structure for character variables
	# implemented
	npc.equipment.add_entity(WeaponRef.new(preload("res://game_resources/playground/short_sword.tres")), ItemEquipment.Slot.MAIN)
	npc.equipment.add_entity(WeaponRef.new(preload("res://game_resources/playground/medium_armor.tres")), ItemEquipment.Slot.ARMOR)
	return npc
