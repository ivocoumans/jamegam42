extends AudioStreamPlayer


var JumpSound = preload("res://assets/jump.wav")
var ShootSound = preload("res://assets/shoot.wav")
var ShootChargedSound = preload("res://assets/shoot_charged.wav")
var HitDecaySound = preload("res://assets/hit_decay.wav")
var HitGroundSound = preload("res://assets/hit_ground.wav")
var RechargedSound = preload("res://assets/recharged.wav")
var ChargedSound = preload("res://assets/charged.wav")
var GameOverSound = preload("res://assets/game_over.wav")


func mute(mute: bool) -> void:
	var volume_db = -12
	if mute:
		volume_db = -80
	SFX.volume_db = volume_db


func play_jump():
	_play_sound(JumpSound)


func play_shoot():
	_play_sound(ShootSound)


func play_shoot_charged():
	_play_sound(ShootChargedSound)


func play_hit_decay():
	_play_sound(HitDecaySound)


func play_hit_ground():
	_play_sound(HitGroundSound)


func play_recharged():
	_play_sound(RechargedSound)


func play_charged():
	_play_sound(ChargedSound)


func play_game_over():
	_play_sound(GameOverSound)


func _play_sound(stream):
	SFX.stop()
	SFX.stream = stream
	SFX.play()

