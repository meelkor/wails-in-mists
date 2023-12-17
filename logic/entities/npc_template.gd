@icon("res://class_icons/character_spawner.svg")

class_name NpcTemplate
extends Resource

@export var template_id: String
@export var default_name: String
@export var default_is_enemy: bool
@export var attributes: CharacterAttributes
# Test properties, should be part of visuals thing
@export var hair_color: Color

# Create GameCharacter instance based on this template's settings
#
# Accept some NpcTemplateOverrides instance so spawner can create unique
# characters based on existing template
func make_game_character() -> NpcCharacter:
	var npc = NpcCharacter.new()
	npc.name = default_name
	# TODO: create stuff like this should be in some HumanNpcTemplate sub-class
	# resource
	#
	# TODO: try to create import script which creates some hair resource
	# chara.hair = load("res://models/hair0.glb").instantiate()
	npc.hair = load("res://models/hair0.glb")
	npc.hair_color = hair_color
	npc.is_enemy = default_is_enemy
	return npc
