## Generic structure which provides information about the entity owning the
## modifier.
##
## todo: if gdscript ever supports traits/interfaces, have all talents, items,
## buffs use the same interface and pass them directly. Until then provide the
## information is general class like this, that needs to be created for each by
## each of those classes..
class_name ModifierSource
extends RefCounted

## Entity this source represents. Should be supported by rich tooltip thing.
##
## todo: maybe replace with generic tooltip content representation
var entity: Object

var name: String
