extends Node2D


export (int) var speed = 100


var direction = Vector2.ZERO


func move(delta):
	direction = Vector2.ZERO
	direction.x = -1
	position += direction.normalized() * speed * delta
	
	if position.x < -1024:
		position.x = 0

