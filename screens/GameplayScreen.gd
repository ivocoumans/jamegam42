extends Node2D


func _process(delta):
	if $Decay.get_rect().intersects($Player.get_rect()):
		print("Game over")
	
	$World.move(delta)


func _on_Player_shoot():
	print("shoot")
	$Decay.slow()


func _on_Player_shoot_charged():
	print("shoot_charged")
	$Decay.push_back()

