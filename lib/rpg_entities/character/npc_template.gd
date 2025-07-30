@tool
@icon("res://resources/class_icons/character_spawner.svg")

class_name NpcTemplate
extends Resource

@export var parameters: CharacterParameters

@export var identity: CharacterIdentity

@export var visuals: CharacterVisuals

# todo: use alignments or something instead
@export var default_is_enemy: bool


## Create GameCharacter instance based on this template's settings
##
## Accept some NpcTemplateOverrides instance so spawner can create unique
## characters based on existing template
func make_game_character() -> NpcCharacter:
	var npc := NpcCharacter.new()
	npc.identity = identity if identity else CharacterIdentity.new()
	npc.parameters = parameters if parameters else CharacterParameters.new()
	npc.visuals = visuals.duplicate() if visuals else null
	return npc
