class_name Math
extends Object

# Basically: vec3.xz
static func vec3_xz(vector: Vector3) -> Vector2:
	return Vector2(vector.x, vector.z)

static func sum(arr: Array) -> int:
	return arr.reduce(func (total, v): return total + v, 0)
