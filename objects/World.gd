extends Node2D


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
var rendered = 0


func move(delta):
	direction = Vector2.ZERO
	direction.x = -1
	var movement = direction.normalized() * speed * delta
	position += movement
	pixels_moved += -movement.x
	
	if pixels_moved > SCREEN_SIZE_X:
		pixels_moved = 0
		_generate_next_screen()
	
	if -position.x >= RESET_X:
		position.x = 0
		_reset()


func _ready():
	randomize()
	_reset(true)
	_generate_next_screen()


func _reset(skip_copy = false):
	# copy the last part of the tilemap
	var tiles_environment = []
	var tiles_props = []
	if !skip_copy:
		tiles_environment = _copy_last_screen($Environment)
		tiles_props = _copy_last_screen($Props)
	
	# clear the tilemap and draw the ground
	$Environment.clear()
	$Props.clear()
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


func _generate_next_screen():
	var x_min = rendered / TILE_SIZE
	var x_max = (rendered + SCREEN_SIZE_X) / TILE_SIZE
	
	print("Render next screen at ", x_min, ",", x_max)
	
	rendered += SCREEN_SIZE_X
	
	_generate_features(x_min, x_max, 3)
	_generate_props(x_min, x_max, 10)


func _generate_features(x_min, x_max, amount = 1):
	for i in amount:
		_generate_feature(x_min, x_max)


func _generate_feature(x_min, x_max):
	var type = randi() % 3
	if type == 2:
		_generate_hole(x_min, x_max)
	elif type == 1:
		_generate_pillar(x_min, x_max)
	else:
		_generate_platform(x_min, x_max)


func _generate_platform(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = floor(rand_range(PLATFORM_Y_BEGIN, PLATFORM_Y_END))
	var width = floor(rand_range(1, 4))
	var height = 2
	
	# prevent features from overlapping or touching
	if _find_feature_in_vicinity(x, y, width, height):
		return

	for x_offset in width + 1:
		for y_offset in height:
			var tile = 0
			if y_offset > 0:
				tile = 1
			$Environment.set_cell(x + x_offset, y + y_offset, tile)


func _generate_pillar(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN
	
	var width = floor(rand_range(3, 5))
	var height = floor(rand_range(2, 4))
	
	y -= height
	
	# prevent features from overlapping or touching
	if _find_feature_in_vicinity(x, y, width, height):
		return
	
	for x_offset in width + 1:
		for y_offset in height:
			var tile = 0
			if y_offset > 0:
				tile = 1
			$Environment.set_cell(x + x_offset, y + y_offset, tile)
		$Environment.set_cell(x + x_offset, GROUND_Y_BEGIN, 1)


func _generate_hole(x_min, x_max):
	var x = floor(rand_range(x_min, x_max))
	var y = GROUND_Y_BEGIN
	var width = floor(rand_range(3, 5))
	var height = 3
	
	# prevent features from overlapping or touching
	if _find_feature_in_vicinity(x, y, width, height):
		return
	
	for x_offset in width + 1:
		for y_offset in height:
			$Environment.set_cell(x + x_offset, y + y_offset, -1)


func _find_feature_in_vicinity(cell_x, _cell_y, cells_width, _cells_height):
	var range_x = range(cell_x - FEATURE_MARGIN, cell_x + cells_width + FEATURE_MARGIN)
	var range_y = range(PLATFORM_Y_BEGIN, GROUND_Y_END)
	for x in range_x:
		for y in range_y:
			var cell_index = $Environment.get_cell(x, y)
			if (y < GROUND_Y_BEGIN and cell_index >= 0) or (y >= GROUND_Y_BEGIN and y <= GROUND_Y_END and cell_index == -1):
				return true
	return false


func _generate_props(x_min, x_max, amount = 1):
	for i in amount:
		_generate_prop(x_min, x_max)


func _generate_prop(x_min, x_max):
	var type = randi() % 10
	if type >= 6:
		_generate_tree(x_min, x_max)
	if type <= 3:
		_generate_grass(x_min, x_max)
	elif type == 4:
		_generate_bush(x_min, x_max)
	elif type == 5:
		_generate_small_tree(x_min, x_max)


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
		return
	
	# prevent props from overlapping or touching
	if _find_prop_in_vicinity(x, y, TREE_WIDTH, TREE_HEIGHT) != null or _find_feature_in_vicinity(x, y, TREE_WIDTH, TREE_HEIGHT):
		return
	
	var subtype = randi() % 3
	var subtype_base = TILE_SIZE * subtype
	
	var start_x = x
	var start_y = y - TREE_HEIGHT
	for tile_x in TREE_WIDTH:
		var tile = TREES_TILE_INDEX + subtype_base + tile_x
		$Props.set_cell(start_x + tile_x, start_y, tile + 12)
		$Props.set_cell(start_x + tile_x, start_y + 1, tile + 8)
		$Props.set_cell(start_x + tile_x, start_y + 2, tile + 4)
		$Props.set_cell(start_x + tile_x, start_y + 3, tile)


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
		return
	
	# prevent props from overlapping or touching
	if _find_prop_in_vicinity(x, y, GRASS_WIDTH, GRASS_HEIGHT) != null or _find_feature_in_vicinity(x, y, GRASS_WIDTH, GRASS_HEIGHT):
		return
	
	var subtype = randi() % 3
	var subtype_base = (GRASS_WIDTH * GRASS_HEIGHT) * 2 * subtype
	
	var start_x = x
	var start_y = y - GRASS_HEIGHT
	for tile_x in GRASS_WIDTH:
		$Props.set_cell(start_x + tile_x, start_y, GRASS_TILE_INDEX + subtype_base + tile_x)


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
		return
	
	# prevent props from overlapping or touching
	if _find_prop_in_vicinity(x, y, BUSH_WIDTH, BUSH_HEIGHT) != null or _find_feature_in_vicinity(x, y, BUSH_WIDTH, BUSH_HEIGHT):
		return
	
	var subtype = randi() % 2
	var subtype_base = (BUSH_WIDTH * BUSH_HEIGHT) * 2 * subtype
	
	var start_x = x
	var start_y = y - BUSH_HEIGHT
	for tile_x in BUSH_WIDTH:
		var tile = BUSH_TILE_INDEX + subtype_base + tile_x
		$Props.set_cell(start_x + tile_x, start_y, tile)


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
		return
	
	# prevent props from overlapping or touching
	if _find_prop_in_vicinity(x, y, SMALL_TREE_WIDTH, SMALL_TREE_HEIGHT) != null or _find_feature_in_vicinity(x, y, SMALL_TREE_WIDTH, SMALL_TREE_HEIGHT):
		return
	
	var start_x = x
	var start_y = y - SMALL_TREE_HEIGHT
	for tile_x in SMALL_TREE_WIDTH:
		var tile = SMALL_TREE_TILE_INDEX + tile_x
		$Props.set_cell(start_x + tile_x, start_y, tile + 2)
		$Props.set_cell(start_x + tile_x, start_y + 1, tile)


func _find_prop_in_vicinity(cell_x, cell_y, cells_width, cells_height):
	var range_x = range(cell_x - PROP_MARGIN, cell_x + cells_width + PROP_MARGIN)
	var range_y = range(cell_y - PROP_MARGIN, cell_y + cells_height + PROP_MARGIN)
	for x in range_x:
		for y in range_y:
			var cell_index = $Props.get_cell(x, y)
			if cell_index >= 0:
				return Vector2(x, y)
	return null

