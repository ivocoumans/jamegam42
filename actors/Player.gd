extends KinematicBody2D


signal shoot
signal shoot_charged


onready var gravity = ProjectSettings.get("physics/2d/default_gravity")


export (int) var speed = 400
export (int) var jump_speed = 1000
export (int) var max_fall_speed = 950


const COYOTE_TIME = 0.065
const RECHARGE_TIME = 2
const CHARGE_TIME = 1


var velocity = Vector2.ZERO
var is_grounded = false
var is_jumping = false
var is_shooting = false
var is_charging = false
var jump_buffer = 0
var recharge_timer = 0
var charge_timer = 0


func get_rect():
	var size = $Sprite.get_rect().size
	return Rect2(position - (size / 2), size)


func _input(event):
	if is_shooting:
		return
	
	if event.is_action_pressed("shoot") and is_charging == false:
		is_charging = true
		charge_timer = 0
	elif event.is_action_released("shoot"):
		if charge_timer > CHARGE_TIME:
			emit_signal("shoot_charged")
		else:
			emit_signal("shoot")
		charge_timer = 0
		is_shooting = true


func _physics_process(delta):
	velocity.x = 0
	
#	if Input.is_action_pressed("move_left"):
#		velocity.x -= speed
#	if Input.is_action_pressed("move_right"):
#		velocity.x += speed
	
	is_grounded = is_on_floor()
	if !is_grounded and !is_jumping:
		# track a jump buffer while we are falling
		jump_buffer += delta
	elif is_grounded:
		# we've landed, reset the buffer
		is_jumping = false
		jump_buffer = 0
	
	# apply gravity when we've exceeded the jump buffer
	if !is_grounded and (jump_buffer > COYOTE_TIME or jump_buffer <= 0):
		velocity.y += gravity
	
	# allow jumping while we're within the jump buffer
	if !is_jumping and jump_buffer < COYOTE_TIME and Input.is_action_pressed("jump"):
		is_jumping = true
		velocity.y = -jump_speed
		jump_buffer = 0
	
	# clamp falling speed to prevent endless acceleration?
	if velocity.y > max_fall_speed:
		velocity.y = max_fall_speed
	
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if is_shooting:
		recharge_timer += delta
		if recharge_timer >= RECHARGE_TIME:
			recharge_timer = 0
			is_shooting = false
	
	if !is_shooting and is_charging:
		charge_timer += delta

