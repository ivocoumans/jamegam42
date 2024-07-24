extends Control


const COLOR_RECHARGING = Color8(215, 35, 35)
const COLOR_CHARGED = Color8(255, 125, 0)
const COLOR_CHARGING = Color8(255, 235, 0)
const COLOR_RECHARGED = Color8(50, 175, 50)


var is_recharging = false
var is_recharged = false
var is_charging = false
var is_charged = false


func reset():
	is_recharging = false
	is_recharged = false
	is_charging = false
	is_charged = false
	recharged()


func _ready():
	recharged()


func recharging():
	is_recharging = true
	is_recharged = false
	is_charging = false
	is_charged = false
	_set_color()


func recharged():
	is_recharging = false
	is_recharged = true
	is_charging = false
	is_charged = false
	_set_color()


func charging():
	if !is_recharged:
		return
	is_recharging = false
	is_recharged = true
	is_charging = true
	is_charged = false
	_set_color()


func charged():
	if !is_recharged:
		return
	
	is_recharging = false
	is_recharged = true
	is_charging = false
	is_charged = true
	_set_color()


func _set_color():
	if is_recharging:
		$Background.modulate = COLOR_RECHARGING
	elif is_charged:
		$Background.modulate = COLOR_CHARGED
	elif is_charging:
		$Background.modulate = COLOR_CHARGING
	elif is_recharged:
		$Background.modulate = COLOR_RECHARGED

