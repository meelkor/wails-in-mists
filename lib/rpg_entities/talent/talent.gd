## Main class for talents. The actual affect is defined by its modifiers.
## Talent subclasses may be introduced for more specific talents that require
## extra inputs out of which the modifiers or name/icon is computed..
class_name Talent
extends Resource

@export var name: String:
	get = _get_talent_name

@export var icon: Texture2D:
	get = _get_icon

@export var description: String:
	get = _get_description

## Defines the actual effects of the talent
@export var modifiers: Array[Modifier] = []


## Called when player tries to equip the talent. Should check whether given
## character has all the requirements.
func allowed(_char: GameCharacter) -> bool:
	return true


## Create Source instance for modifers so they can read name of the parent
## entity.
func to_source() -> ModifierSource:
	var src := ModifierSource.new()
	src.name = name
	src.entity = self
	return src


## Visible name for subclasses to override
func _get_talent_name() -> String:
	return name if name else _compute_name()


## Visible icon for cubclasses to override in case of "generated" icon
func _get_icon() -> Texture2D:
	return PlaceholderTexture2D.new()


## Describing text that is by default computed from its modifiers.
func _get_description() -> String:
	return description if description.length() > 0 else _compute_description()


func _compute_name() -> String:
	var labels := modifiers.map(func (mod: Modifier) -> String: return mod.get_label())
	return "\n".join(labels)


## todo: descriptions for tooltip should be interactive but dunno how to define
## them yet
func _compute_description() -> String:
	var contents := modifiers.map(func (mod: Modifier) -> String: return mod.get_description())
	return "\n".join(contents)
