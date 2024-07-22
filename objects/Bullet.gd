extends Area2D


signal intersects(body)


export (int) var speed_x = 350
export (int) var speed_y = 200
export (int) var bullet_gravity = 5


var velocity = Vector2.ZERO
var is_charged = false
var is_spent = false


func _ready():
	velocity = Vector2(-speed_x, -speed_y)
	scale = Vector2(0.5, 0.5)


func _process(delta):
	velocity.y += bullet_gravity
	position += velocity * delta


func _on_Bullet_body_entered(body):
	emit_signal("intersects", body)

