## Script which be applied on either VBoxContainer or HBoxContainer to display
## grid of provided character's buffs.
extends BoxContainer

const BuffIcon = preload("./buff_icon.gd")
const BUFF_ICON = preload("./buff_icon.tscn")
const ROWS = 4

@export var character: GameCharacter:
	set(v):
		if character != v:
			character = v
			if is_inside_tree():
				_ready()

@export var icon_size: float

## Separation in child rows/columns
@export var separation: int = 8

@export var row_first: bool = false

var _buffs_state := State.new()


func _ready() -> void:
	if character:
		# non deferred makes game crash, probably changed emitted at some
		# moment when we shouldn't touch tree
		character.changed.connect(_update_buffs, CONNECT_DEFERRED)
		_update_buffs()


func _update_buffs() -> void:
	if character:
		var buffs := character.get_buffs()
		if _buffs_state.changed(buffs):
			Utils.Nodes.clear_children(self)
			var current_col: BoxContainer = null
			var i: int
			for onset in buffs:
				if i == 0:
					current_col = HBoxContainer.new() as BoxContainer if row_first else VBoxContainer.new() as BoxContainer
					current_col.add_theme_constant_override("separation", separation)
					add_child(current_col)
				var icon := BUFF_ICON.instantiate() as BuffIcon
				icon.custom_minimum_size = Vector2(icon_size, icon_size)
				icon.buff = buffs[onset]
				icon.onset = onset
				icon.count = 1 # todo: group by buff and get count
				current_col.add_child(icon)
				i = (i + 1) % ROWS
