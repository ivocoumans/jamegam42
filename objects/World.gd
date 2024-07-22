extends Node2D


const RESET_X = -3072
const FEATURE_MARGIN = 3
const PLATFORM_Y_BEGIN = 3
const PLATFORM_Y_END = 8
const GROUND_Y_BEGIN = 13
const GROUND_Y_END = 15


export (int) var speed = 400


var direction = Vector2.ZERO
var pixels_moved = 0


func _ready():
	randomize()
	_reset(true)


func _copy_last_screen():
	var tiles = []
	for x_offset in 32:
		for y_offset in 20:
			var index = $TileMap.get_cell(x_offset + 96, y_offset)
			if y_offset <= PLATFORM_Y_END and index >= 0:
				tiles.append(Vector3(x_offset, y_offset, index))
			elif y_offset >= GROUND_Y_BEGIN and index == -1:
				tiles.append(Vector3(x_offset, y_offset, index))
	return tiles


func _paste_last_screen(tiles):
	# paste the copied part to the first part of the tilemap
	for tile in tiles:
		$TileMap.set_cell(tile.x, tile.y, tile.z)


func _reset(skip_copy = false):
	# copy the last part of the tilemap
	var tiles = []
	if !skip_copy:
		tiles = _copy_last_screen()
	
	# clear the tilemap and draw the ground
	$TileMap.clear()
	var y = GROUND_Y_BEGIN
	for x in 4096:
		$TileMap.set_cell(x, y, 0)
		$TileMap.set_cell(x, y + 1, 1)
		$TileMap.set_cell(x, y + 2, 1)
	
	if !skip_copy:
		_paste_last_screen(tiles)


func move(delta):
	direction = Vector2.ZERO
	direction.x = -1
	var movement = direction.normalized() * speed * delta
	position += movement
	pixels_moved += movement.x
	
	if -pixels_moved > (32 * 6):
		_generate_feature()
		pixels_moved = 0
	
	if position.x < RESET_X:
		position.x = 0
		_reset()


func _find_feature_in_vicinity(cell_x, cell_y, cells_width, cells_height):
	var range_x = range(cell_x - FEATURE_MARGIN, cell_x + cells_width + FEATURE_MARGIN)
	var range_y = range(cell_y - FEATURE_MARGIN, cell_y + cells_height + FEATURE_MARGIN)
	for x in range_x:
		for y in range_y:
			var cell_index = $TileMap.get_cell(x, y)
			if (y < GROUND_Y_BEGIN and cell_index >= 0) or (y >= GROUND_Y_BEGIN and y <= GROUND_Y_END and cell_index == -1):
				return true
	return false

func _generate_feature():
	var type = randi() % 3
	if type == 2:
		_generate_hole()
	else:
		_generate_platform()


func _generate_platform():
	var world_x_min = floor((-position.x / 32) + 32)
	var world_x_max = world_x_min + 32
	
	var x = floor(rand_range(world_x_min, world_x_max))
	var y = floor(rand_range(PLATFORM_Y_BEGIN, PLATFORM_Y_END))
	var width = floor(rand_range(1, 4))
	var height = 2
	
	# prevent platforms from overlapping or touching
	if _find_feature_in_vicinity(x, y, width, height):
		return

	for x_offset in width + 1:
		for y_offset in height:
			var tile = 0
			if y_offset > 0:
				tile = 1
			$TileMap.set_cell(x + x_offset, y + y_offset, tile)


func _generate_pillar():
	# TODO later: generate a pillar from the ground up
	pass


func _generate_hole():
	var world_x_min = floor((-position.x / 32) + 32)
	var world_x_max = world_x_min + 32
	
	var x = floor(rand_range(world_x_min, world_x_max))
	var y = GROUND_Y_BEGIN
	var width = floor(rand_range(3, 5))
	var height = 3
	
	# prevent holes from overlapping or touching
	if _find_feature_in_vicinity(x, y, width, height):
		return
	
	for x_offset in width + 1:
		for y_offset in height:
			$TileMap.set_cell(x + x_offset, y + y_offset, -1)

