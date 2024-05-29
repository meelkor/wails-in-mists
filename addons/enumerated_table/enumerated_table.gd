@tool
## "Database" structure for for storing list of resources of `child_type`
## resource that is then editable using the enumerated table editor
class_name EnumeratedTable
extends Resource

## Name of the final global Object that serves as enum
@export var name: String

## Prefix to add to all managed resource files
@export var prefix: String

@export var child_type: GDScript


func prefix_str(str: String) -> String:
	return "%s_%s" % [prefix, str]
