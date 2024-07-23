class_name Prop


var rect = Rect2(Vector2.ZERO, Vector2.ZERO)
# 3 = Tree, 2 = Grass, 1 = Bush, 0 = Small Tree
var type = 0
var subtype = 0
var has_decayed = false


func _init(x, y, width, height, init_type, init_subtype):
	rect = Rect2(Vector2(x, y), Vector2(width, height))
	type = init_type
	subtype = init_subtype

