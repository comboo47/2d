extends Node2D

@export var example_skill_id := "example_firebolt"

@onready var level_runner: LevelRunner = $LevelRunner
@onready var status_label: Label = $CanvasLayer/StatusPanel/StatusLabel

var player: BattleActor
var enemy: BattleActor
var skill_used := false

func _ready() -> void:
	GameplayEventBus.clear_history()
	level_runner.start_level()
	_cache_spawned_actors()
	call_deferred("_use_example_skill")

func _physics_process(_delta: float) -> void:
	_update_status()

func _cache_spawned_actors() -> void:
	if level_runner.spawned_actors.size() >= 2:
		player = level_runner.spawned_actors[0]
		enemy = level_runner.spawned_actors[1]

func _use_example_skill() -> void:
	if player == null or enemy == null:
		return

	var context := GameplayFlowContext.create_attack(player, enemy)
	skill_used = player.use_skill(example_skill_id, context)
	_update_status()

func _update_status() -> void:
	if status_label == null:
		return

	var enemy_hp := _attribute_value(enemy, AttributeConfig.AttributeName.Hp)
	var player_atk := _attribute_value(player, AttributeConfig.AttributeName.Atk)
	var burn_stack := 0
	if enemy and enemy.buffManager:
		var burn := enemy.buffManager.find_buff("example_burn")
		if burn:
			burn_stack = burn.stack

	status_label.text = "Gameplay Example Level\n"
	status_label.text += "Player: example_firebolt skill, Atk %.1f\n" % player_atk
	status_label.text += "Enemy HP: %.1f\n" % enemy_hp
	status_label.text += "Burn buff stack: %d\n" % burn_stack
	status_label.text += "Skill cast on start: %s" % str(skill_used)

func _attribute_value(actor: BattleActor, attribute_name: AttributeConfig.AttributeName) -> float:
	if actor == null or actor.GetAttributes() == null:
		return 0.0
	var attribute := actor.GetAttributes().find_attribute(attribute_name)
	return attribute.get_value() if attribute else 0.0
