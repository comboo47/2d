class_name Flow_EnemyDeath extends GameplayFlowBase
## 敌人死亡流程
## 演示 Flow 如何定义死亡逻辑和掉落

## 是否掉落物品
@export var enable_drop: bool = true

## 掉落 Buff ID（击杀者获得的奖励）
@export var kill_reward_buff_id: String = ""

func _execute_flow(context: GameplayFlowContext) -> void:
	var dead_enemy = context.source
	var killer = context.event_data.get("killer", null)

	# 1. 播放死亡特效（Action: 播放 VFX）
	if VfxManager.instance:
		VfxManager.instance.play_vfx(VfxConfig.VfxType.DEATH_EFFECT, dead_enemy.global_position)

	# 2. 处理击杀奖励（分支逻辑）
	if killer != null and not kill_reward_buff_id.is_empty():
		# 给击杀者应用奖励 Buff
		BattleManager.ApplyBuff(dead_enemy, killer, kill_reward_buff_id)

	# 3. 处理掉落（Action: 生成物品）
	if enable_drop:
		_process_drop(dead_enemy)

func _process_drop(dead_enemy: BattleActor) -> void:
	# Action: 调用 DropManager 处理掉落
	if DropManager.instance:
		DropManager.handle_enemy_death(dead_enemy)