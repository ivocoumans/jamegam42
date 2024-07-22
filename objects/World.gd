extends Node2D


const RESET_X = -1024


export (int) var speed = 150


var direction = Vector2.ZERO


func move(delta):
	direction = Vector2.ZERO
	direction.x = -1
	position += direction.normalized() * speed * delta
	
	if position.x < RESET_X:
		position.x = 0

