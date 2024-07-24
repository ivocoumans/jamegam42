extends Area2D


signal intersects(body)


export (int) var speed_x = 350
export (int) var speed_y = 200
export (int) var bullet_gravity = 5
export (float) var charged_multiplier = 1.25
export (float) var scale_multiplier = 1.0


var velocity = Vector2.ZERO
var is_charged = false
var is_spent = false
var emitting_timer = 0
var is_paused = false


func pause(paused):
	is_paused = paused


func remove():
	$Sprite.visible = false
	$Trail.visible = false
	$Explode.visible = true
	$Explode.emitting = true


func _ready():
	velocity = Vector2(-speed_x, -speed_y)
	if is_charged:
		velocity.x *= charged_multiplier
		velocity.y *= charged_multiplier
		$Trail.scale_amount = 0.75
		$Trail.speed_scale = 3
	scale = Vector2(0.5, 0.5) * scale_multiplier


func _process(delta):
	if is_paused:
		return
	
	if $Explode.emitting == true:
		emitting_timer += delta
		if emitting_timer > 1:
			queue_free()
			return
	velocity.y += bullet_gravity
	position += velocity * delta


func _on_Bullet_body_entered(body):
	emit_signal("intersects", body)

