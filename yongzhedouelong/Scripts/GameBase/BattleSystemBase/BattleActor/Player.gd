extends BattleActor

class_name MainPlayer

var holdFireTime = float(0)
var under_control = true

var mousePosition:Vector2


@onready var hsm: LimboHSM = $LimboHSM
@onready var idle_state: LimboState = $LimboHSM/IdleState
@onready var move_state: LimboState = $LimboHSM/MoveState
@onready var jump_state: LimboState = $LimboHSM/JumpState
@onready var hurt_state: LimboState = $LimboHSM/HurtState
@onready var die_state: LimboState = $LimboHSM/DieState

var screen_size
# Called when the node enters the scene tree for the first time.
func _enter_tree():
	pass
func _ready():
	screen_size = get_viewport_rect().size
	#初始化状态机
	_init_state_machine()

	# 添加技能管理器
	add_skill_manager()

	# 触发生成 Flow
	trigger_spawn_flow()

	# 注意：UIManager 绑定由场景脚本（如 Main.gd）调用
	pass # Replace with function body.
# Called every frame. 'delta' is the elapsed time from the previous frame.
func _process(delta):
	# 通过 InputManager 检查是否可以接收游戏输入
	# InputManager 会同时检查锁定状态和游戏状态
	if not InputManager.can_receive_game_input():
		return

	var _velocity = Vector2.ZERO
	if Input.is_action_just_pressed("interaction"):
		#addPoker(randi()%12+1,randi()%3)
		if $InteractionInterface.interactionItem != null:
			var i = $InteractionInterface.interactionItem
			if i.get_node("canPickUp"):
				i.get_node("canPickUp").pickUp(self)
				#print(i)
	if $".".get_meta("CurrentWeapon") != null:
		var weapon = $".".get_meta("CurrentWeapon")
		# 按下 fire 立即开始蓄力
		if Input.is_action_just_pressed("fire"):
			if weapon.has_method("hold_fire"):
				weapon.hold_fire()
		# 按住 fire 期间（可选：持续调用 hold_fire 或只调用一次）
		if Input.is_action_pressed("fire"):
			holdFireTime += delta
		# 释放 fire 发射
		if Input.is_action_just_released("fire"):
			holdFireTime = 0
			if weapon.has_method("fire"):
				weapon.fire()
	AnimControle()
	position = position.clamp(Vector2.ZERO, screen_size)
	if hsm.get_active_state() != jump_state && self.velocity.y >0:
		hsm.dispatch("falling")
	pass
func _unhandled_input(event: InputEvent) -> void:
	# 通过 InputManager 检查是否可以接收游戏输入
	# InputManager 会同时检查锁定状态和游戏状态
	if not InputManager.can_receive_game_input():
		return

	if event.is_echo():
		return
	if event.is_action_pressed("jump"):
		_process_jump_input()
	if event.is_action_pressed("test"):
		_test_input()
func _process_jump_input() -> void:
	if hsm.get_active_state() == jump_state:
		if jump_state.fallingtime >= 0.1:
			return
		elif jump_state.isfalling:
			jump_state.moveComponent.tryJump(true)
	hsm.dispatch("jump")

func _process_die_input() -> void:
	if hsm.get_active_state() == die_state:
		return
	hsm.dispatch("die")
func _test_input()-> void:
	#stats.printAttr()
	hsm.dispatch("hurt")
	if $WeaponComponent.currentWeapon <2:
		$WeaponComponent.setCurrentWeapon($WeaponComponent.currentWeapon+1)
	else:
		$WeaponComponent.setCurrentWeapon(0)
	return


func _init_state_machine():
	hsm.add_transition(idle_state, move_state, idle_state.EVENT_FINISHED)
	hsm.add_transition(idle_state, jump_state, "jump")
	hsm.add_transition(idle_state, hurt_state, "hurt")
	hsm.add_transition(move_state, idle_state, move_state.EVENT_FINISHED)
	hsm.add_transition(move_state, jump_state, "jump")
	hsm.add_transition(jump_state, idle_state, jump_state.EVENT_FINISHED)
	hsm.add_transition(hurt_state, idle_state, hurt_state.EVENT_FINISHED)
	hsm.add_transition(hsm.ANYSTATE, die_state, "die")
	hsm.add_transition(hsm.ANYSTATE, jump_state, "falling")
	hsm.initialize(self)
	hsm.set_active(true)

func AnimControle():
	if velocity.x:
		if velocity.x >0:
			$AnimatedSprite2D.flip_h = false
		else:
			$AnimatedSprite2D.flip_h = true
