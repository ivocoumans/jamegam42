extends ColorRect


const SLOW_TIME = 3


var grow_speed = 50
var is_slowed = false
var is_push_back = false
var slow_timer = 0
var grow_direction = 1


func _process(delta):
	if is_slowed:
		slow_timer += delta
		if slow_timer >= SLOW_TIME:
			is_slowed = false
			print("no longer slowed")
	
	if grow_direction != 0:
		var size = get_size()
		var speed = grow_speed * grow_direction
		
		if is_push_back:
			speed *= 250
			size.x += speed * delta
			is_push_back = false
			grow_direction = 1
			
		if is_slowed:
			speed *= 0.05
		
		size.x += speed * delta
		set_size(size)


func slow():
	slow_timer = 0
	is_slowed = true


func push_back():
	is_push_back = true
	grow_direction = -1
	slow()

