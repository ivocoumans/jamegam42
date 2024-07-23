extends Control


var _score = 0


func increase_score():
	_score += 1
	_set_score_text()


func _ready():
	var _score = 0
	$Score.text = "0"


func _set_score_text():
	$Score.text = str(_score)

