## Class for talent book items - consumable which grants assigned talentpack to
## the selected character.
class_name ItemTalentBook
extends ItemConsumable

@export var pack: TalentPack


func make_name() -> String:
	return name if name else ", ".join(pack.get_summary())


func get_heading() -> String:
	return "Talent book"


func on_use(character: GameCharacter) -> bool:
	# todo: show "are you sure character {} should learn this talent?" confirm
	# dialog
	var pc := character as PlayableCharacter
	if pc:
		pc.available_talents.add_entity(pack)
		# todo: play some level-up-like animation
		return true
	return false
