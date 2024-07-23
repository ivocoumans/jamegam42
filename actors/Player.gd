extends KinematicBody2D


signal shoot
signal shoot_charged
signal is_recharging
signal is_recharged
signal is_charging
signal is_charged


const COYOTE_TIME = 0.065
const RECHARGE_TIME = 3
const CHARGE_TIME = 1.5


export (int) var jump_speed = 800
export (int) var max_fall_speed = 750
export (int) var catch_up_speed = 600


onready var gravity = ProjectSettings.get("physics/2d/default_gravity")


var velocity = Vector2.ZERO
var is_grounded = false
var is_jumping = false
var allow_jumping = true
var is_recharging = false
var is_charging = false
var is_charged = false
var jump_buffer = 0
var recharge_timer = 0
var charge_timer = 0
var initial_x = 0


func get_rect():
	var size = $Sprite.get_rect().size
	return Rect2(position - (size / 2), size)


func _ready():
	initial_x = position.x


func _input(event):
	if event.is_action_pressed("shoot") and is_charging == false:
		is_charging = true
		charge_timer = 0
		emit_signal("is_charging")
	
	if is_recharging:
		return
	
	if event.is_action_released("shoot"):
		if is_charged:
			emit_signal("shoot_charged")
		else:
			emit_signal("shoot")
		charge_timer = 0
		is_recharging = true
		is_charging = false
		is_charged = false
		emit_signal("is_recharging")


func _physics_process(delta):
	velocity.x = 0
	
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
	if allow_jumping and !is_jumping and jump_buffer < COYOTE_TIME and Input.is_action_pressed("jump"):
		allow_jumping = false
		is_jumping = true
		velocity.y = -jump_speed
		jump_buffer = 0
	if Input.is_action_just_released("jump"):
		allow_jumping = true
	
	# clamp falling speed to prevent endless acceleration?
	if velocity.y > max_fall_speed:
		velocity.y = max_fall_speed
	
	# catch up when we're not in the air
	if !is_jumping and is_grounded:
		if position.x > initial_x:
			position.x = initial_x
		if position.x < initial_x:
			velocity.x = catch_up_speed
	
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if is_recharging:
		recharge_timer += delta
		if recharge_timer >= RECHARGE_TIME:
			recharge_timer = 0
			is_recharging = false
			print("Shot ready")
			emit_signal("is_recharged")
	
	if !is_recharging and is_charging:
		charge_timer += delta
		if charge_timer >= CHARGE_TIME:
			if is_charged == false:
				print("Shot fully charged")
			is_charged = true
			emit_signal("is_charged")

