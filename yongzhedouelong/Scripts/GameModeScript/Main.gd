extends Node2D

## Player 实例引用（从场景内获取）
var player: BattleActor

func _ready():
	# 查找场景内的 Player（不再依赖 autoload）
	player = _find_player()
	if player:
		player.position = $PlayerStart.position
		# 绑定到 UIManager
		UIManager.instance.bind_actor(player)

	# 进入游戏状态
	GameManager.enter_game()

func _find_player() -> BattleActor:
	# 查找场景内带有 MainPlayer class_name 的节点
	for child in get_children():
		if child is BattleActor and child.has_method("GetAttributes"):
			return child
	# 尝试按名称查找
	var found = get_node_or_null("Player")
	if found and found is BattleActor:
		return found
	return null

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("testButton"):
		var num = randf() * 100
		if player:
			UIManager.instance.show_damage(player, num)
