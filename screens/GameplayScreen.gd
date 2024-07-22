extends Node2D


var Bullet = preload("res://objects/Bullet.tscn")


var bullet = null


func _process(delta):
	$World.move(delta)


func _on_Player_shoot():
	print("shoot")
	_spawn_bullet(false)


func _on_Player_shoot_charged():
	print("shoot_charged")
	_spawn_bullet(true)


func _spawn_bullet(is_charged):
	bullet = Bullet.instance()
	bullet.position = $Player.position
	bullet.is_charged = is_charged
	bullet.connect("intersects", self, "_on_Bullet_intersects")
	add_child(bullet)


func _on_Decay_intersects(body):
	if body == $Player:
		print("Game over")
	if body == bullet and bullet.is_spent == false:
		bullet.is_spent = true
		if bullet.is_charged:
			$Decay.push_back()
		else:
			$Decay.slow()
		print("Bullet")


func _on_Bullet_intersects(body):
	if body == $World/TileMap:
		bullet.is_spent = true
		print("Bullet hit ground")

