extends FlowLeaf
class_name FlowLeaf_EnemyDeath
## 样例敌人死亡脚本叶子（第十三期，取代 Flow_EnemyDeath 的 on_start 逻辑）。
## 死亡延迟（原 extra_delay 的 await）改由 graph 的 SECONDS Duration 表达：
## death graph = INSTANT[本叶子: 打标记+死亡特效] + SECONDS(delay)。
## 解释器跑完 SECONDS Duration → is_finished()=true，actor._physics_process 据此门控最终销毁。

func run(ctx: GameplayFlowContext, _host = null) -> void:
	var who = ctx.source.name if ctx.source else "?"
	print("[FlowLeaf_EnemyDeath] run: %s 死亡逻辑开始（延时由 SECONDS Duration 表达）" % who)
	FlowActions.play_vfx(ctx, {"vfx_type": VfxConfig.VfxType.HIT_IMPACT})
