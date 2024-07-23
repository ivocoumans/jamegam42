extends Control


func _ready():
	recharged()


func recharging():
	$Background.modulate = Color8(215, 35, 35)


func recharged():
	$Background.modulate = Color8(50, 175, 50)


func charging():
	$Background.modulate = Color8(255, 235, 0)


func charged():
	$Background.modulate = Color8(255, 125, 0)

