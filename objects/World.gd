extends Node2D


var Feature = preload("res://objects/feature.gd")
var Prop = preload("res://objects/prop.gd")


const RESET_X = 3072
const SCREEN_SIZE_X = 1024
const SCREEN_TILES_X = 32
const SCREEN_TILES_Y = 20
const TILE_SIZE = 32
const FEATURE_MARGIN = 3
const PROP_MARGIN = 3
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


func _apply_decay():
	var start_cell_x = ceil(abs(position.x) / TILE_SIZE)
	var end_cell_x = ceil((abs(position.x) + decay_size_x) / TILE_SIZE)
	
	for prop in props:
		var x = prop.rect.position.x
		if x >= start_cell_x and x <= end_cell_x and !prop.has_decayed:
			prop.has_decayed = true
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


func _render_tree(rect, subtype, decayed = false):
	var decay_offset = 0
	if decayed:
		decay_offset = 16
	
	var subtype_base = TILE_SIZE * subtype
	var start_x = rect.position.x
	var start_y = rect.position.y
	for tile_x in TREE_WIDTH:
		var tile = TREES_TILE_INDEX + subtype_base + tile_x + decay_offset
		$Props.set_cell(start_x + tile_x, start_y, tile + 12)
		$Props.set_cell(start_x + tile_x, start_y + 1, tile + 8)
		$Props.set_cell(start_x + tile_x, start_y + 2, tile + 4)
		$Props.set_cell(start_x + tile_x, start_y + 3, tile)


func _render_grass(rect, subtype, decayed = false):
	var decay_offset = 0
	if decayed:
		decay_offset = 2

	var subtype_base = (GRASS_WIDTH * GRASS_HEIGHT) * 2 * subtype
	var start_x = rect.position.x
	var start_y = rect.position.y
	for tile_x in GRASS_WIDTH:
		var tile = GRASS_TILE_INDEX + subtype_base + tile_x + decay_offset
		$Props.set_cell(start_x + tile_x, start_y, tile)


func _render_bush(rect, subtype, decayed = false):
	var decay_offset = 0
	if decayed:
		decay_offset = 2
	
	var subtype_base = (BUSH_WIDTH * BUSH_HEIGHT) * 2 * subtype
	var start_x = rect.position.x
	var start_y = rect.position.y
	for tile_x in rect.size.x:
		var tile = BUSH_TILE_INDEX + subtype_base + tile_x + decay_offset
		$Props.set_cell(start_x + tile_x, start_y, tile)


func _render_small_tree(rect, decayed = false):
	var decay_offset = 0
	if decayed:
		decay_offset = 4
	
	var start_x = rect.position.x
	var start_y = rect.position.y
	for tile_x in rect.size.x:
		var tile = SMALL_TREE_TILE_INDEX + tile_x + decay_offset
		$Props.set_cell(start_x + tile_x, start_y, tile + 2)
		$Props.set_cell(start_x + tile_x, start_y + 1, tile)


func _ready():
	reset()


func _reset(skip_copy = false):
	# copy the last part of the tilemap
	var tiles_environment = []
	var tiles_props = []
	var copied_features = []
	var copied_props = []
	if !skip_copy:
		tiles_environment = _copy_last_screen($Environment)
		tiles_props = _copy_last_screen($Props)
		copied_features = _copy_last_screen_array(features)
		copied_props = _copy_last_screen_array(props)
	
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
		_paste_last_screen(tiles_environment, $Environment)
		_paste_last_screen(tiles_props, $Props)
		features = _paste_last_screen_array(copied_features)
		props = _paste_last_screen_array(copied_props)


func _copy_last_screen(tilemap):
	var tiles = []
	for x_offset in SCREEN_TILES_X:
		for y_offset in SCREEN_TILES_Y:
			var index = tilemap.get_cell(x_offset + SCREEN_TILES_X * 3, y_offset)
			tiles.append(Vector3(x_offset, y_offset, index))
	return tiles


func _paste_last_screen(tiles, tilemap):
	# paste the copied part to the first part of the tilemap
	for tile in tiles:
		tilemap.set_cell(tile.x, tile.y, tile.z)


func _copy_last_screen_array(arr):
	var copied = []
	for item in arr:
		if item.rect.position.x >= SCREEN_TILES_X * 3:
			copied.append(item)
	return copied


func _paste_last_screen_array(arr):
	var pasted = []
	for item in arr:
		item.rect.position.x -= SCREEN_TILES_X * 3
		pasted.append(item)
	return pasted


func _generate_next_screen():
	var x_min = rendered / TILE_SIZE
	var x_max = (rendered + SCREEN_SIZE_X) / TILE_SIZE
	
	rendered += SCREEN_SIZE_X
	
	_generate_features(x_min, x_max, 3)
	_generate_props(x_min, x_max, 10)


func _generate_features(x_min, x_max, amount):
	for i in amount:
		_generate_feature(x_min, x_max)


func _generate_feature(x_min, x_max):
	var feature = null
	
	var type = randi() % 3
	if type == 2:
		feature = _generate_hole(x_min, x_max)
	elif type == 1:
		feature = _generate_pillar(x_min, x_max)
	else:
		feature = _generate_platform(x_min, x_max)
	
	if feature != null:
		features.append(feature)


func _generate_platform(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = floor(rand_range(PLATFORM_Y_BEGIN, PLATFORM_Y_END))
	var width = floor(rand_range(1, 4))
	var height = 2
	
	# prevent features from overlapping or touching
	if _find_feature_in_vicinity(x, y, width, height):
		return null

	for x_offset in width + 1:
		for y_offset in height:
			var tile = 0
			if y_offset > 0:
				tile = 1
			$Environment.set_cell(x + x_offset, y + y_offset, tile)
	
	return Feature.new(x, y, width, height, 0)


func _generate_pillar(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN
	
	var width = floor(rand_range(3, 5))
	var height = floor(rand_range(2, 4))
	
	y -= height
	
	# prevent features from overlapping or touching
	if _find_feature_in_vicinity(x, y, width, height):
		return null
	
	for x_offset in width + 1:
		for y_offset in height:
			var tile = 0
			if y_offset > 0:
				tile = 1
			$Environment.set_cell(x + x_offset, y + y_offset, tile)
		$Environment.set_cell(x + x_offset, GROUND_Y_BEGIN, 1)
	
	return Feature.new(x, y, width, height, 1)


func _generate_hole(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN
	var width = floor(rand_range(3, 5))
	var height = 3
	
	# prevent features from overlapping or touching
	if _find_feature_in_vicinity(x, y, width, height):
		return null
	
	for x_offset in width + 1:
		for y_offset in height:
			$Environment.set_cell(x + x_offset, y + y_offset, -1)
	
	return Feature.new(x, y, width, height, 2)


func _find_feature_in_vicinity(cell_x, _cell_y, cells_width, _cells_height):
	var range_x = range(cell_x - FEATURE_MARGIN, cell_x + cells_width + FEATURE_MARGIN)
	var range_y = range(PLATFORM_Y_BEGIN, GROUND_Y_END)
	for x in range_x:
		for y in range_y:
			var cell_index = $Environment.get_cell(x, y)
			if (y < GROUND_Y_BEGIN and cell_index >= 0) or (y >= GROUND_Y_BEGIN and y <= GROUND_Y_END and cell_index == -1):
				return true
	return false


func _generate_props(x_min, x_max, amount):
	for i in amount:
		_generate_prop(x_min, x_max)


func _generate_prop(x_min, x_max):
	var prop = null
	
	var type = randi() % 10
	if type >= 6:
		prop = _generate_tree(x_min, x_max)
	if type <= 3:
		prop = _generate_grass(x_min, x_max)
	elif type == 4:
		prop = _generate_bush(x_min, x_max)
	elif type == 5:
		prop = _generate_small_tree(x_min, x_max)
	
	if prop != null:
		props.append(prop)


func _generate_tree(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN
	
	# check proper ground
	var is_allowed = true
	for tile_x in TREE_WIDTH:
		if $Environment.get_cell(x + tile_x, y) != 0:
			is_allowed = false
			break
	if !is_allowed:
		return null
	
	# prevent props from overlapping or touching
	if _find_prop_in_vicinity(x, y, TREE_WIDTH, TREE_HEIGHT) != null or _find_feature_in_vicinity(x, y, TREE_WIDTH, TREE_HEIGHT):
		return null
	
	var subtype = randi() % 3
	var start_x = x
	var start_y = y - TREE_HEIGHT
	_render_tree(Rect2(start_x, start_y, TREE_WIDTH, TREE_HEIGHT), subtype)
	
	return Prop.new(start_x, start_y, TREE_WIDTH, TREE_HEIGHT, 3, subtype)


func _generate_grass(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN
	
	# check proper ground
	var is_allowed = true
	for tile_x in GRASS_WIDTH:
		if $Environment.get_cell(x + tile_x, y) != 0:
			is_allowed = false
			break
	if !is_allowed:
		return null
	
	# prevent props from overlapping or touching
	if _find_prop_in_vicinity(x, y, GRASS_WIDTH, GRASS_HEIGHT) != null or _find_feature_in_vicinity(x, y, GRASS_WIDTH, GRASS_HEIGHT):
		return null
	
	var subtype = randi() % 3
	var start_x = x
	var start_y = y - GRASS_HEIGHT
	_render_grass(Rect2(start_x, start_y, GRASS_WIDTH, GRASS_HEIGHT), subtype)
	
	return Prop.new(start_x, start_y, GRASS_WIDTH, GRASS_HEIGHT, 2, subtype)


func _generate_bush(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN
	
	# check proper ground
	var is_allowed = true
	for tile_x in BUSH_WIDTH:
		if $Environment.get_cell(x + tile_x, y) != 0:
			is_allowed = false
			break
	if !is_allowed:
		return null
	
	# prevent props from overlapping or touching
	if _find_prop_in_vicinity(x, y, BUSH_WIDTH, BUSH_HEIGHT) != null or _find_feature_in_vicinity(x, y, BUSH_WIDTH, BUSH_HEIGHT):
		return null
	
	var subtype = randi() % 2
	var start_x = x
	var start_y = y - BUSH_HEIGHT
	_render_bush(Rect2(start_x, start_y, BUSH_WIDTH, BUSH_HEIGHT), subtype)
	
	return Prop.new(start_x, start_y, BUSH_WIDTH, BUSH_HEIGHT, 1, subtype)


func _generate_small_tree(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN
	
	# check proper ground
	var is_allowed = true
	for tile_x in SMALL_TREE_WIDTH:
		if $Environment.get_cell(x + tile_x, y) != 0:
			is_allowed = false
			break
	if !is_allowed:
		return null
	
	# prevent props from overlapping or touching
	if _find_prop_in_vicinity(x, y, SMALL_TREE_WIDTH, SMALL_TREE_HEIGHT) != null or _find_feature_in_vicinity(x, y, SMALL_TREE_WIDTH, SMALL_TREE_HEIGHT):
		return null

	var start_x = x
	var start_y = y - SMALL_TREE_HEIGHT
	_render_small_tree(Rect2(start_x, start_y, SMALL_TREE_WIDTH, SMALL_TREE_HEIGHT))
	
	return Prop.new(start_x, start_y, SMALL_TREE_WIDTH, SMALL_TREE_HEIGHT, 0, 0)


func _find_prop_in_vicinity(cell_x, cell_y, cells_width, cells_height):
	var range_x = range(cell_x - PROP_MARGIN, cell_x + cells_width + PROP_MARGIN)
	var range_y = range(cell_y - PROP_MARGIN, cell_y + cells_height + PROP_MARGIN)
	for x in range_x:
		for y in range_y:
			var cell_index = $Props.get_cell(x, y)
			if cell_index >= 0:
				return Vector2(x, y)
	return null

