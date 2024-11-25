## Listen to all given signals and emit whenever any of them emits. Those
## signals are expected to be parameterless. Used to add timeout to another
## signal.
class_name SignalMerge
extends RefCounted

signal any()

signal fake()


func _init(a: Signal, b: Signal, c: Signal = fake) -> void:
	a.connect(any.emit)
	b.connect(any.emit)
	c.connect(any.emit)
