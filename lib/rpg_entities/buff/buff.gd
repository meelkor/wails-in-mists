## Class representing any status effect be it buff or debuff, (didn't wanna
## call it status effect 'coz too long lol).
##
## Buffs may be either:
##  - combat-round-limited: those may be only granted during combat and
##    disappear the moment combat ends (almost sounds like those should be
##    stored in the combat, todo consider...)
##  - permanent: usually removable with some special trigger such as injuries
##    are removable by rest
##  - TODO area-specifc: auras and things like difficult terrain - dunno yet
##    how to implement well lol
##
## No buffs should be based on real time.
class_name Buff
extends Resource

## Whether this is buff or debuf. Should be used only for visual purposes I
## guess?
@export var positive: bool:
	get = _get_positive

## Text describing the buff's effect with all the numeric details
@export var description: String:
	get = _get_description

@export var name: String:
	get = _get_buff_name

@export var icon: Texture2D
## When end_trigger is COMBAT_TIME, this buff is limited to a combat and ends
## after number of this number of rounds since character gained the buff. The
## counting of turns and rounds should happen outside this class so those
## resources can be constant.
@export var round_duration: int
## Defined when the buff ends
@export var end_trigger: EndTrigger = EndTrigger.NONE

## Defines the actual effect the same way talents do
@export var modifiers: Array[Modifier]


func is_injury() -> bool:
	return end_trigger == EndTrigger.INJURY


func to_source() -> ModifierSource:
	var src := ModifierSource.new()
	src.name = name
	src.entity = self
	return src


func _get_positive() -> bool:
	return positive


func _get_description() -> String:
	return description


func _get_buff_name() -> String:
	return name


## Structure that should be as key when storing buffs for characters, so we can
## store details about when the buff was gained
class Onset:
	extends Resource

	## Combat round on which the buff was granted
	@export var starting_round: int = -1
	## Turn on which the buff was granted so e.g. when characters grants itself
	## defense buff for 1 round at the end of round, it should stay active until the
	@export var starting_turn: int = -1


	func is_combat() -> bool:
		return starting_round != -1


enum EndTrigger {
	NONE = -1,
	## Cannot be removed in current run
	PERMANENT = 0,
	## Number of rounds defined by the buffs
	COMBAT_TIME = 1,
	## Removed whenever injury should be healed up, usually when resting in
	## safe location
	INJURY = 2,
}
