## Listen to all given signals and emit whenever any of them emits. Those
## signals are expected to be parameterless. Used to add timeout to another
## signal.
##
## Not refcounted so needs to be manually freed!
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
		# lambda to add support for signals with values
		s.connect(func (_a: Variant = null) -> void:
			any.emit()
		)
