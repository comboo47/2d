extends FlowLeaf
class_name FlowLeaf_EnemySpawn
## 样例敌人出生脚本叶子（第十三期，取代 Flow_EnemySpawn）。
## 由 spawn graph 的 INSTANT Duration 执行一次：打标记 + 播放出生特效（演示宿主机制）。

func run(ctx: GameplayFlowContext, _host = null) -> void:
	var who = ctx.source.name if ctx.source else "?"
	print("[FlowLeaf_EnemySpawn] run: %s 出生" % who)
	FlowActions.play_vfx(ctx, {"vfx_type": VfxConfig.VfxType.HIT_IMPACT})
