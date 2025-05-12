class_name GlobalTimeScale
extends Object


static var scale: float = 1.:
	set(n_scale):
		scale = n_scale
		_update_controlled()

static var _controlled_tweens: Array[WeakRef]

static var _controlled_trees: Array[WeakRef]


static func register(tween_or_tree: Variant) -> void:
	if tween_or_tree is Tween:
		_controlled_tweens.append(weakref(tween_or_tree))
	elif tween_or_tree is AnimationTree:
		_controlled_trees.append(weakref(tween_or_tree))


static func _update_controlled() -> void:
	_controlled_tweens = _controlled_tweens.filter(func (ref: WeakRef) -> bool: return !!ref.get_ref())
	for ref in _controlled_tweens:
		var tween := ref.get_ref() as Tween
		tween.set_speed_scale(scale)
	_controlled_trees = _controlled_trees.filter(func (ref: WeakRef) -> bool: return !!ref.get_ref())
	for ref in _controlled_trees:
		var tree := ref.get_ref() as AnimationTree
		tree.set("parameters/TimeScale/scale", scale)
