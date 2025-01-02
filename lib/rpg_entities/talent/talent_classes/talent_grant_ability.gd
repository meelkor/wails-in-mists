## Talent which grants list of ability
class_name TalentGrantAbility
extends Talent

@export var abilities: Array[Ability]


func name() -> String:
	return "Abilities: %s" % ", ".join(abilities.map(func (a: Ability) -> String: return a.name))


func icon() -> Texture2D:
	return abilities[0].icon


func get_abilities(_char: GameCharacter) -> Array[AbilityGrant]:
	var grants: Array[AbilityGrant] = []
	grants.resize(abilities.size())
	for i in range(abilities.size()):
		# todo: how to define conditions??
		grants[i] = AbilityGrant.new(abilities[i], true)
	return grants
