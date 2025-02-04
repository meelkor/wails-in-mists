## Listen to all given signals and emit whenever any of them emits. Those
## signals are expected to be parameterless. Used to add timeout to another
## signal.
class_name SignalMerge
extends RefCounted

signal any()

signal fake()


func _init(a: Signal = fake, b: Signal = fake, c: Signal = fake) -> void:
	add(a)
	add(b)
	add(c)


func add(s: Signal) -> void:
	if s != fake:
		s.connect(any.emit)
