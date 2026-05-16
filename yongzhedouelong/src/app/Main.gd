extends Node2D

var player: BattleActor

func _ready() -> void:
	player = _find_player()
	if player:
		player.position = $PlayerStart.position
		UIManager.instance.show_hud(player)

	GameManager.enter_game()

func _find_player() -> BattleActor:
	for child in get_children():
		if child is BattleActor and child.has_method("GetAttributes"):
			return child

	var found := get_node_or_null("Player")
	if found and found is BattleActor:
		return found
	return null

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("testButton"):
		var num := randf() * 100
		if player:
			UIManager.instance.show_damage(player, num)
