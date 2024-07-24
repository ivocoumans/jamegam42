extends Control


var _score = 0


func get_score():
	return _score


func reset():
	_score = 0
	_set_score_text()


func increase_score():
	_score += 1
	_set_score_text()


func _ready():
	_score = 0
	_set_score_text()


func _set_score_text():
	$Score.text = str(_score)

