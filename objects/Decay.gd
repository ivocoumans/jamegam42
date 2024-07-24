extends TextureRect


signal intersects(body)
signal grown(size_x)


const SLOW_TIME = 2.5
const AREA_SIZE_X = 64


export (int) var grow_speed = 12
export (int) var pushback_speed = 350
export (float) var slow_multiplier = 0.2


var is_slowed = false
var is_push_back = false
var slow_timer = 0
var grow_direction = 1
var is_paused = false


func reset():
	is_slowed = false
	is_push_back = false
	slow_timer = 0
	grow_direction = 1
	is_paused = false
	set_size(Vector2(64, 512))
	$Area2D.position.x = 32
	$Particles.position.x = 64


func pause(paused):
	is_paused = paused

 
func slow():
	slow_timer = 0
	is_slowed = true


func push_back():
	is_push_back = true
	grow_direction = -1
	slow()


func _process(delta):
	if is_paused:
		return
	
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
		emit_signal("grown", size.x)
		
		# move the Area2D with the resizing ColorRect
		var rect = get_rect()
		var x = rect.position.x + rect.size.x - AREA_SIZE_X
		$Area2D.position.x = x
		$Particles.position.x = x + 64


func _on_Area2D_body_entered(body):
	emit_signal("intersects", body)


func _on_Area2D_area_entered(area):
	emit_signal("intersects", area)

