extends Node


var Bullet = preload("res://objects/Bullet.tscn")


var bullet = null
var score_timer = 0
var is_paused = false


func _input(event):
	if event.is_action_pressed("pause"):
		is_paused = !is_paused
		$Decay.pause()
		$Player.pause()


func _process(delta):
	if is_paused:
		return
	
	$World.move(delta)
	score_timer += delta
	if score_timer > 1:
		$UI/ScoreDisplay.increase_score()
		score_timer = 0


func _on_Player_shoot():
	_spawn_bullet(false)


func _on_Player_shoot_charged():
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
		bullet.remove()


func _on_Bullet_intersects(body):
	if body == $World/Environment:
		bullet.is_spent = true
		bullet.remove()


func _on_Player_is_recharging():
	$UI/WandStatus.recharging()


func _on_Player_is_recharged():
	$UI/WandStatus.recharged()


func _on_Player_is_charging():
	$UI/WandStatus.charging()


func _on_Player_is_charged():
	$UI/WandStatus.charged()


func _on_Decay_grown(size_x):
	$World.decay_size_x = size_x

