## RichTooltip's child node which contains optional info about the context from
## which the tooltip was created. E.g. when opening a tooltip for weapon and
## the weapon is equipped (or character profile dialog is open), we provide the
## character so we can disply customized content such as abilities player may
## actually use.
##
## There's shitload of todos to think about, how to provide the context:
##  - when opening tooltip? --> useless buttons are very generic
##  - tooltip_spawner injects all related nodes (selected chara, dialog chara)
##    and provides this info to rich tooltip di? I don't like tooltip spawner
##    becoming dependant on everything resulting in cyclic deps
##  - introduce some DI metadata so any node in DI tree can provide metadata
##    under arbitrary keys and can then be injected...
##    di.provide_metadata("tooltip_context", "character", character_res)
##    di.inject_metadata("tooltip_context") -> { "character": character_res }
##    The metadata stays there as long as the source DI is in tree. Also the
##    metadata are shared across whole tree, not just parents...? But then
##    opening info aboout enemy character would then use that chara for all
##    tooltips which is baddddd.
##
## To decide on best impl. I need to find out actual usecases from where I'll
## need to propagate the context:
##  - selected character / active character in combat for ability details
##  - character for which player has dialog open
##  - inspected (enemy) character when viewing their abilities and stuff
class_name TooltipContext
extends Node

var di := DI.new(self)

@onready var _level_gui := di.inject(LevelGui) as LevelGui

## Character (temp solution just to get proficiencies working) (also typing it
## here introduces cyclic dep)
@onready var character: GameCharacter = _level_gui._open_dialog_char
