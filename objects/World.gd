extends Node2D


var Feature = preload("res://objects/feature.gd")
var Prop = preload("res://objects/prop.gd")


const RESET_X = 3072
const SCREEN_SIZE_X = 1024
const SCREEN_TILES_X = 32
const SCREEN_TILES_Y = 20
const TILE_SIZE = 32
const PROP_TO_FEATURE_MARGIN = 1
const PROP_TO_PROP_MARGIN = 1
const FEATURE_TO_FEATURE_MARGIN = 3
const PLATFORM_Y_BEGIN = 3
const PLATFORM_Y_END = 8
const GROUND_Y_BEGIN = 13
const GROUND_Y_END = 15
const SMALL_TREE_WIDTH = 2
const SMALL_TREE_HEIGHT = 2
const BUSH_WIDTH = 2
const BUSH_HEIGHT = 1
const GRASS_WIDTH = 2
const GRASS_HEIGHT = 1
const TREE_WIDTH = 4
const TREE_HEIGHT = 4
const SMALL_TREE_TILE_INDEX = 0
const BUSH_TILE_INDEX = 8
const GRASS_TILE_INDEX = 16
const TREES_TILE_INDEX = 28


export (int) var speed = 400


var direction = Vector2.ZERO
var pixels_moved = 0
var pixels_moved_decay = 0
var rendered = 0
var features = []
var props = []
var decay_size_x = 0


# resets the World before the game starts
func reset():
	direction = Vector2.ZERO
	pixels_moved = 0
	pixels_moved_decay = 0
	rendered = 0
	features = []
	props = []
	decay_size_x = 0
	position.x = 0
	
	# clear the environment and props
	$Environment.clear()
	$Props.clear()
	features.clear()
	props.clear()
	
	# draw the ground
	var y = GROUND_Y_BEGIN
	for x in 4096:
		$Environment.set_cell(x, y, 0)
		$Environment.set_cell(x, y + 1, 1)
		$Environment.set_cell(x, y + 2, 1)
	
	randomize()
	_reset(true)
	_generate_next_screen()


# move the World
func move(delta):
	direction = Vector2.ZERO
	direction.x = -1
	var movement = direction.normalized() * speed * delta
	position += movement
	pixels_moved += -movement.x
	pixels_moved_decay += -movement.x
	
	if pixels_moved > SCREEN_SIZE_X:
		pixels_moved = 0
		_generate_next_screen()
	
	if -position.x >= RESET_X:
		position.x = 0
		_reset()
	
	if pixels_moved_decay > TILE_SIZE:
		pixels_moved_decay = 0
		_apply_decay()


# resets the World to its initial position, looping around the tilemap
func _reset(skip_copy = false):
	var copied_features = []
	var copied_props = []
	
	if !skip_copy:
	# copy the last screen
		copied_features = _copy_last_screen(features)
		copied_props = _copy_last_screen(props)
	
	# clear the environment and props
	$Environment.clear()
	$Props.clear()
	features.clear()
	props.clear()
	
	# draw the ground
	var y = GROUND_Y_BEGIN
	for x in 4096:
		$Environment.set_cell(x, y, 0)
		$Environment.set_cell(x, y + 1, 1)
		$Environment.set_cell(x, y + 2, 1)
	
	# render next screen
	rendered = SCREEN_SIZE_X
	
	if !skip_copy:
		# paste the last screen
		features = _paste_last_screen(copied_features)
		props = _paste_last_screen(copied_props)
		
		for feature in features:
			var rect = feature.rect
			if feature.type == 0:
				_render_platform(rect)
			if feature.type == 1:
				_render_hole(rect)
			if feature.type == 2:
				_render_pillar(rect)
		
		for prop in props:
			var rect = prop.rect
			var subtype = prop.subtype
			var is_decayed = prop.is_decayed
			if prop.type == 0:
				_render_small_tree(rect, is_decayed)
			if prop.type == 1:
				_render_bush(rect, subtype, is_decayed)
			if prop.type == 2:
				_render_grass(rect, subtype, is_decayed)
			if prop.type == 3:
				_render_tree(rect, subtype, is_decayed)


var rejects = 0
# screen rendering
func _generate_next_screen():
	rejects = 0
	var x_min = rendered / TILE_SIZE
	var x_max = (rendered + SCREEN_SIZE_X) / TILE_SIZE
	
	rendered += SCREEN_SIZE_X
	
	_generate_features(x_min, x_max, 4)
	_generate_props(x_min, x_max, 7)


func _copy_last_screen(arr):
	var copied = []
	for item in arr:
		if item.rect.position.x >= SCREEN_TILES_X * 3 - 5:
			copied.append(item)
	return copied


func _paste_last_screen(arr):
	var pasted = []
	for item in arr:
		item.rect.position.x -= SCREEN_TILES_X * 3
		pasted.append(item)
	return pasted


# features
func _generate_features(x_min, x_max, amount):
	for i in amount:
		_generate_feature(x_min, x_max)


func _generate_feature(x_min, x_max):
	var type = randi() % 7
	if type < 4:
		_generate_platform(x_min, x_max)
	elif type == 4:
		_generate_hole(x_min, x_max)
	elif type > 4:
		_generate_pillar(x_min, x_max)


func _find_feature_in_vicinity(x, y, width, height, margin):
	var rect = Rect2(x - margin, y - margin, width + margin, height + margin)
	for feature in features:
		var feature_rect = feature.rect
		feature_rect.position.x -= margin
		feature_rect.size.x += margin
		feature_rect.position.y -= margin
		feature_rect.size.y += margin
		if rect.intersects(feature_rect):
			return true
	return false


# feature: platform
func _render_platform(rect):
	var x = rect.position.x
	var y = rect.position.y
	var width = rect.size.x
	var height = rect.size.y
	
	for x_offset in width + 1:
		for y_offset in height:
			var tile = 0
			if y_offset > 0:
				tile = 1
			$Environment.set_cell(x + x_offset, y + y_offset, tile)


func _generate_platform(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = floor(rand_range(PLATFORM_Y_BEGIN, PLATFORM_Y_END))
	var width = floor(rand_range(1, 4))
	var height = 2
	
	# prevent features and props from overlapping or touching
	var is_prop_in_vicinity = _find_prop_in_vicinity(x, y, width, height, PROP_TO_FEATURE_MARGIN)
	var is_feature_in_vicinity = _find_feature_in_vicinity(x, y, width, height, FEATURE_TO_FEATURE_MARGIN)
	if is_prop_in_vicinity or is_feature_in_vicinity:
		return
	
	var feature = Feature.new(x, y, width, height, 0)
	features.append(feature)
	_render_platform(feature.rect)


# feature: hole
func _render_hole(rect):
	var x = rect.position.x
	var y = rect.position.y
	var width = rect.size.x
	var height = rect.size.y
	
	for x_offset in width:
		for y_offset in height:
			$Environment.set_cell(x + x_offset, y + y_offset, -1)


func _generate_hole(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN
	var width = floor(rand_range(3, 7))
	var height = 3
	
	# prevent features and props from overlapping or touching
	var is_prop_in_vicinity = _find_prop_in_vicinity(x, y, width, height, PROP_TO_FEATURE_MARGIN)
	var is_feature_in_vicinity = _find_feature_in_vicinity(x, y, width, height, FEATURE_TO_FEATURE_MARGIN)
	if is_prop_in_vicinity or is_feature_in_vicinity:
		return
	
	var feature = Feature.new(x, y, width, height, 1)
	features.append(feature)
	_render_hole(feature.rect)


# feature: pillar
func _render_pillar(rect):
	var x = rect.position.x
	var y = rect.position.y
	var width = rect.size.x
	var height = rect.size.y
	
	for x_offset in width + 1:
		for y_offset in height:
			var tile = 0
			if y_offset > 0:
				tile = 1
			$Environment.set_cell(x + x_offset, y + y_offset, tile)
		$Environment.set_cell(x + x_offset, GROUND_Y_BEGIN, 1)


func _generate_pillar(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN
	var width = floor(rand_range(3, 5))
	var height = floor(rand_range(2, 4))
	y -= height
	
	# prevent features and props from overlapping or touching
	var is_prop_in_vicinity = _find_prop_in_vicinity(x, y, width, height, PROP_TO_FEATURE_MARGIN)
	var is_feature_in_vicinity = _find_feature_in_vicinity(x, y, width, height, FEATURE_TO_FEATURE_MARGIN)
	if is_prop_in_vicinity or is_feature_in_vicinity:
		return
	
	var feature = Feature.new(x, y, width, height, 2)
	features.append(feature)
	_render_pillar(feature.rect)


# props
func _generate_props(x_min, x_max, amount):
	for i in amount:
		_generate_prop(x_min, x_max)


func _generate_prop(x_min, x_max):
	var type = randi() % 7
	if type == 6:
		_generate_small_tree(x_min, x_max)
	elif type == 5:
		_generate_bush(x_min, x_max)
	elif type >= 3 and type < 5:
		_generate_grass(x_min, x_max)
	elif type < 3:
		_generate_tree(x_min, x_max)


func _find_prop_in_vicinity(x, y, width, height, margin):
	var rect = Rect2(x - margin, y - margin, width + margin, height + margin)
	for prop in props:
		var prop_rect = prop.rect
		prop_rect.position.x -= margin
		prop_rect.size.x += margin
		prop_rect.position.y -= margin
		prop_rect.size.y += margin
		if rect.intersects(prop_rect):
			return true
	return false


# prop: decay
func _apply_decay():
	var start_cell_x = ceil(abs(position.x) / TILE_SIZE)
	var end_cell_x = ceil((abs(position.x) + decay_size_x) / TILE_SIZE)
	
	for prop in props:
		var x = prop.rect.position.x
		if x >= start_cell_x and x <= end_cell_x and !prop.is_decayed:
			prop.is_decayed = true
			_render_prop_decayed(prop)


func _render_prop_decayed(prop):
	if prop.type == 0:
		_render_small_tree(prop.rect, true)
	elif prop.type == 1:
		_render_bush(prop.rect, prop.subtype, true)
	elif prop.type == 2:
		_render_grass(prop.rect, prop.subtype, true)
	elif prop.type == 3:
		_render_tree(prop.rect, prop.subtype, true)


# prop: small tree
func _render_small_tree(rect, decayed = false):
	var x = rect.position.x
	var y = rect.position.y
	var width = rect.size.x
	
	var decay_offset = 0
	if decayed:
		decay_offset = 4
	
	for x_offset in width:
		var tile = SMALL_TREE_TILE_INDEX + x_offset + decay_offset
		$Props.set_cell(x + x_offset, y, tile + 2)
		$Props.set_cell(x + x_offset, y + 1, tile)


func _generate_small_tree(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN - SMALL_TREE_HEIGHT
	var width = SMALL_TREE_WIDTH
	var height = SMALL_TREE_HEIGHT
	
	# prevent features and props from overlapping or touching
	var is_prop_in_vicinity = _find_prop_in_vicinity(x, y, width, height, PROP_TO_PROP_MARGIN)
	var is_feature_in_vicinity = _find_feature_in_vicinity(x, y, width, height, PROP_TO_FEATURE_MARGIN)
	if is_prop_in_vicinity or is_feature_in_vicinity:
		return

	var prop = Prop.new(x, y, SMALL_TREE_WIDTH, SMALL_TREE_HEIGHT, 0, 0)
	props.append(prop)
	_render_small_tree(prop.rect)


# prop: bush
func _render_bush(rect, subtype, decayed = false):
	var x = rect.position.x
	var y = rect.position.y
	var width = rect.size.x
	
	var decay_offset = 0
	if decayed:
		decay_offset = 2
	
	var subtype_base = (BUSH_WIDTH * BUSH_HEIGHT) * 2 * subtype
	for x_offset in width:
		var tile = BUSH_TILE_INDEX + subtype_base + x_offset + decay_offset
		$Props.set_cell(x + x_offset, y, tile)


func _generate_bush(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN - BUSH_HEIGHT
	var width = BUSH_WIDTH
	var height = BUSH_HEIGHT
	
	# prevent features and props from overlapping or touching
	var is_prop_in_vicinity = _find_prop_in_vicinity(x, y, width, height, PROP_TO_PROP_MARGIN)
	var is_feature_in_vicinity = _find_feature_in_vicinity(x, y, width, height, PROP_TO_FEATURE_MARGIN)
	if is_prop_in_vicinity or is_feature_in_vicinity:
		return
	
	var subtype = randi() % 2
	var prop = Prop.new(x, y, width, height, 1, subtype)
	props.append(prop)
	_render_bush(prop.rect, subtype)


# prop: grass
func _render_grass(rect, subtype, decayed = false):
	var x = rect.position.x
	var y = rect.position.y
	var width = rect.size.x
	
	var decay_offset = 0
	if decayed:
		decay_offset = 2

	var subtype_base = (GRASS_WIDTH * GRASS_HEIGHT) * 2 * subtype
	for x_offset in width:
		var tile = GRASS_TILE_INDEX + subtype_base + x_offset + decay_offset
		$Props.set_cell(x + x_offset, y, tile)


func _generate_grass(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN - GRASS_HEIGHT
	var width = GRASS_WIDTH
	var height = GRASS_HEIGHT
	
	# prevent features and props from overlapping or touching
	var is_prop_in_vicinity = _find_prop_in_vicinity(x, y, width, height, PROP_TO_PROP_MARGIN)
	var is_feature_in_vicinity = _find_feature_in_vicinity(x, y, width, height, PROP_TO_FEATURE_MARGIN)
	if is_prop_in_vicinity or is_feature_in_vicinity:
		return
	
	var subtype = randi() % 3
	var prop = Prop.new(x, y, width, height, 2, subtype)
	props.append(prop)
	_render_grass(prop.rect, subtype)


# prop: tree
func _render_tree(rect, subtype, decayed = false):
	var x = rect.position.x
	var y = rect.position.y
	var width = rect.size.x
	
	var decay_offset = 0
	if decayed:
		decay_offset = 16
	
	var subtype_base = TILE_SIZE * subtype
	for x_offset in width:
		var tile = TREES_TILE_INDEX + subtype_base + x_offset + decay_offset
		$Props.set_cell(x + x_offset, y, tile + 12)
		$Props.set_cell(x + x_offset, y + 1, tile + 8)
		$Props.set_cell(x + x_offset, y + 2, tile + 4)
		$Props.set_cell(x + x_offset, y + 3, tile)


func _generate_tree(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN - TREE_HEIGHT
	var width = TREE_WIDTH
	var height = TREE_HEIGHT
	
	# prevent features and props from overlapping or touching
	var is_prop_in_vicinity = _find_prop_in_vicinity(x, y, width, height, PROP_TO_PROP_MARGIN)
	var is_feature_in_vicinity = _find_feature_in_vicinity(x, y, width, height, PROP_TO_FEATURE_MARGIN)
	if is_prop_in_vicinity or is_feature_in_vicinity:
		return
	
	var subtype = randi() % 3
	var prop = Prop.new(x, y, width, height, 3, subtype)
	props.append(prop)
	_render_tree(prop.rect, subtype)

