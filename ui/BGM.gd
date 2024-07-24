extends AudioStreamPlayer


func mute(mute: bool) -> void:
	var volume_db = -8
	if mute:
		volume_db = -80
	BGM.volume_db = volume_db


func play_title():
	BGM.stop()
	BGM.play()

