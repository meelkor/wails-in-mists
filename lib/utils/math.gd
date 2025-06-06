class_name Math
extends Object


static func sumi(arr: Array) -> int:
	return arr.reduce(func (total: int, v: int) -> int: return total + v, 0)


static func path_length(path: PackedVector3Array) -> float:
	var length := 0.
	for i in range(0, path.size() - 1):
		length += path[i].distance_to(path[i + 1])
	return length
