## Idea stolen from
## https://github.com/godotengine/godot-proposals/issues/6851#issuecomment-2322179983
class_name StaticSignal
extends Object

static var static_signal_id: int = 0


static func make() -> Signal:
	var signal_name: String = "StaticSignal-%s" % static_signal_id
	var owner_class := (StaticSignal as Object)
	owner_class.add_user_signal(signal_name)
	static_signal_id += 1
	return Signal(owner_class, signal_name)
