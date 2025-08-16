## Static utility which translates short paths for "standard" resources with
## expected location such as skills from short path "skill:initiative" to the
## full resource path.
class_name ShortPath
extends Object

const SOURCES := {
	"attr": "res://game_resources/character_attributes/",
	"trait": "res://game_resources/traits/",
	"skill": "res://game_resources/skills/",
}


## Resolve the short path and laod the resource, providing placeholder if it
## fails.
static func load(short_path: String) -> Resource:
	# how tf this work lmao, but not mad
	var res := load(resolve(short_path))
	if res:
		return res
	else:
		push_error("Invalid short path %s" % short_path)
		return preload("res://lib/utils/short_name_placeholder.tres")


# Try to find full path for given short path and return it. Returns empty
# string if unsuccessful.
static func resolve(short_path: String) -> String:
	var full_path: String
	if short_path.begins_with("res://"):
		full_path = short_path
	else:
		var regex := RegEx.new()
		regex.compile("^(\\w+):(\\w+)$")
		var result := regex.search(short_path)
		if result:
			var prefix := result.get_string(1)
			var res_name := result.get_string(2)
			if SOURCES.has(prefix):
				full_path = "%s%s_%s.tres" % [SOURCES.get(prefix), prefix, res_name]

	return full_path
