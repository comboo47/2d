extends Node2D
@export var bullet: PackedScene
signal player_fired_bullet(bullet,_position,_rotation,direction,type)

var mousePos = Vector2()

@export var subSpeed = float(0)
@export var refreshSpeed = float(3)
@export var MaxEnerge = float(100)
var currentEnerge = float(0)

var holdTime = 0
var needHoldTime = 0.7
var direction = Vector2.ZERO
var stepX
var stepY
var defaultSpeed
var positionList:Array

var deltaIndex = float(0)

var hold = false
# Called when the node enters the scene tree for the first time.
func _enter_tree():
	$".".get_parent().set_meta("CurrentWeapon",self)

func _ready():
	var b = bullet.instantiate()
	defaultSpeed = b.speed
	currentEnerge = MaxEnerge
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$".".look_at(mousePos)
	mousePos = get_viewport().get_mouse_position()
	direction = mousePos - get_parent().position
	direction = direction.normalized() * defaultSpeed
	if hold:
		holdTime += delta
		if holdTime >= needHoldTime:
			$Sprite2D2.rotation = 0
			if	!$RefreshTimer.is_stopped():
				$RefreshTimer.stop()
			if $SubTimer.is_stopped():
				$SubTimer.start()
			deltaIndex += delta
			if deltaIndex >= 0.1:
				if currentEnerge>0:
					realfire()
		else:
			$Sprite2D2.rotation += 0.25
	#get_parent().position
	pass
func holdFire():
	hold = true

func fire():
	if hold == false:
		realfire()
	elif hold == true && holdTime >= needHoldTime:
		if !$SubTimer.is_stopped():
			$SubTimer.stop()
		if	$RefreshTimer.is_stopped():
			$RefreshTimer.start()
		hold = false
		holdTime = 0
		deltaIndex = 0
		#realfire()
	else:
		hold = false
		holdTime = 0
		deltaIndex = 0
		$Sprite2D2.rotation = 0
		realfire()
		

func realfire():
	deltaIndex = 0
	if get_parent():
		var _bullet = bullet.instantiate()
		emit_signal("player_fired_bullet",_bullet,$Marker2D.global_position,$Marker2D.global_rotation,direction,1)
func refreshEnerge():
	currentEnerge += refreshSpeed
	currentEnerge = clamp(currentEnerge,0,MaxEnerge)
func subEnerge():
	var subedvalue = currentEnerge - subSpeed
	subedvalue = clamp(subedvalue,0,MaxEnerge)
	currentEnerge = subedvalue
	#currentEnerge = clamp(currentEnerge,0,MaxEnerge)
	if currentEnerge <= 0:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN)
		var oriColor = $Sprite2D2.modulate
		tween.tween_property($Sprite2D2,"modulate",Color.FIREBRICK,0.05)
		tween.tween_property($Sprite2D2,"modulate",oriColor,0.05)
	
func getWeaponEnerge() ->float:
	return currentEnerge
