class_name Feature


var rect = Rect2(Vector2.ZERO, Vector2.ZERO)
# 2 = Pillar, 1 = Hole, 0 = Platform
var type = 0


func _init(x, y, width, height, init_type):
	rect = Rect2(Vector2(x, y), Vector2(width, height))
	type = init_type

