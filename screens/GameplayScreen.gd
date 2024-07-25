extends Node


var Bullet = preload("res://objects/Bullet.tscn")


var bullet = null
var score_timer = 0
var is_paused = false


func _ready():
	_start_game()


func _input(event):
	var is_game_start = $UI/GameStartModal.visible
	var is_game_over = $UI/GameOverModal.visible
	var is_game_pause = $UI/GamePauseModal.visible
	
	if !is_game_start and !is_game_over and !is_game_pause and event.is_action_pressed("pause"):
		$UI/GamePauseModal.visible = true
		_pause_game(true)
		
	if event.is_action_pressed("accept"):
		if is_game_start:
			$UI/GameStartModal.visible = false
			_pause_game(false)
			if !BGM.is_playing() and !OS.is_debug_build():
				BGM.play_title()
		elif is_game_over:
			$UI/GameOverModal.visible = false
			_start_game()
		elif is_game_pause:
			$UI/GamePauseModal.visible = false
			_pause_game(false)


func _process(delta):
	if is_paused:
		return
	
	$World.move(delta)
	score_timer += delta
	if score_timer > 1:
		$UI/ScoreDisplay.increase_score()
		score_timer = 0


func _start_game():
	$UI/GameStartModal.visible = true
	
	$Decay.reset()
	$World.reset()
	$Player.reset()
	$UI/WandStatus.reset()
	$UI/ScoreDisplay.reset()
	
	_pause_game(true)


func _game_over():
	$UI/GameOverModal.visible = true
	$UI/GameOverModal.set_score($UI/ScoreDisplay.get_score())
	_pause_game(true)
	SFX.play_game_over()


func _pause_game(paused):
	is_paused = paused
	$Decay.pause(paused)
	$Player.pause(paused)
	if bullet != null and is_instance_valid(bullet):
		bullet.pause(paused)


func _on_Player_shoot():
	_spawn_bullet(false)


func _on_Player_shoot_charged():
	_spawn_bullet(true)


func _spawn_bullet(is_charged):
	bullet = Bullet.instance()
	bullet.position = $Player.position
	bullet.is_charged = is_charged
	bullet.connect("intersects", self, "_on_Bullet_intersects")
	if is_charged:
		bullet.scale_multiplier = 1.25
		SFX.play_shoot_charged()
	else:
		SFX.play_shoot()
	add_child(bullet)


func _on_Decay_intersects(body):
	if body == $Player:
		_game_over()
		return
	
	if body == bullet and !bullet.is_spent:
		bullet.is_spent = true
		if bullet.is_charged:
			$Decay.push_back()
		else:
			$Decay.slow()
		SFX.play_hit_decay()
		bullet.remove()


func _on_Bullet_intersects(body):
	if body == $World/Environment and !bullet.is_spent:
		bullet.is_spent = true
		bullet.remove()
		SFX.play_hit_ground()


func _on_Player_is_recharging():
	$UI/WandStatus.recharging()


func _on_Player_is_recharged():
	$UI/WandStatus.recharged()
	SFX.play_recharged()


func _on_Player_is_charging():
	$UI/WandStatus.charging()


func _on_Player_is_charged():
	$UI/WandStatus.charged()
	SFX.play_charged()


func _on_Decay_grown(size_x):
	$World.decay_size_x = size_x


func _on_Player_fallen():
	_game_over()

