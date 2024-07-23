extends ColorRect


signal intersects(body)


const SLOW_TIME = 2.5
const AREA_SIZE_X = 64


export (int) var grow_speed = 12
export (int) var pushback_speed = 350
export (float) var slow_multiplier = 0.2


var is_slowed = false
var is_push_back = false
var slow_timer = 0
var grow_direction = 1

 
func slow():
	slow_timer = 0
	is_slowed = true


func push_back():
	is_push_back = true
	grow_direction = -1
	slow()


func _process(delta):
	if is_slowed:
		slow_timer += delta
		if slow_timer >= SLOW_TIME:
			is_slowed = false
	
	if grow_direction != 0:
		var size = get_size()
		var speed = grow_speed * grow_direction
		
		if is_push_back:
			speed *= pushback_speed
			size.x += speed * delta
			is_push_back = false
			grow_direction = 1
			
		if is_slowed:
			speed *= slow_multiplier
		
		size.x += speed * delta
		set_size(size)
		
		# move the Area2D with the resizing ColorRect
		var rect = get_rect()
		var x = rect.position.x + rect.size.x - AREA_SIZE_X
		$Area2D.position.x = x


func _on_Area2D_body_entered(body):
	emit_signal("intersects", body)


func _on_Area2D_area_entered(area):
	emit_signal("intersects", area)

