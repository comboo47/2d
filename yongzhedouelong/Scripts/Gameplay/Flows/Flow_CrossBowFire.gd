class_name Flow_CrossBowFire extends GameplayFlowBase
## 弩枪射击流程
## 演示 Flow 如何调用 Action 触发 Effect

func _execute_flow(context: GameplayFlowContext) -> void:
	# 获取射击参数
	var shooter = context.source
	var target_position = context.get_position()
	var direction = context.event_data.get("direction", Vector2.RIGHT)

	# 流程逻辑：射击 → 播放特效 → 消耗能量

	# 1. 播放射击特效（Action: 播放 VFX）
	if VfxManager.instance:
		VfxManager.instance.play_vfx(VfxConfig.VfxType.BULLET_HIT, target_position)

	# 2. 消耗能量（Action: 修改属性）
	if shooter and shooter.has_meta("CurrentWeapon"):
		var weapon = shooter.get_meta("CurrentWeapon")
		if weapon and weapon.has_method("consume_energy"):
			weapon.consume_energy(10.0)

	# 3. 后续逻辑（如击中判定等）
	# 可以在此添加分支逻辑
	_check_hit_result(context)

func _check_hit_result(context: GameplayFlowContext) -> void:
	# 分支逻辑示例：检查是否有命中目标
	var target = context.target

	if target == null:
		# 未命中：播放落空特效
		if VfxManager.instance:
			VfxManager.instance.play_vfx(VfxConfig.VfxType.MISS_EFFECT, context.get_position())
		return

	# 命中：应用伤害 Buff
	BattleManager.ApplyBuff(context.source, target, "buff_damage_001")