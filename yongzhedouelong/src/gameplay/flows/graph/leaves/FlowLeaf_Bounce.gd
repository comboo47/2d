extends FlowLeaf
class_name FlowLeaf_Bounce
## 弹射特质脚本叶子（第十三期，取代 TraitFlow_Bounce）。
## 由 trait graph 的 Trigger(BULLET_HIT, NEVER) 在每次命中时执行。
## 读 ctx.gameplay_event.event_data（TraitContainer.dispatch 塞入的 trait_bag/trait_holder/trait_result）：
##   bounce_count>0 → 否决销毁（veto_release）+ 递减 + 水平反射方向；
##   bounce_count<=0 → 不否决，子弹正常销毁。
## 第一版水平反射（vx 取反）够验证「命中不销毁+改向+弹N次」；按法线/朝最近敌人折返留后续。

func run(ctx: GameplayFlowContext, _host = null) -> void:
	var event := ctx.gameplay_event
	if event == null:
		return
	var bag = event.event_data.get("trait_bag")
	var bullet = event.event_data.get("trait_holder")
	var result = event.event_data.get("trait_result")
	if bag == null or bullet == null or result == null:
		return
	if bag.get_value("bounce_count", 0.0) <= 0.0:
		return  # 弹射耗尽：不否决，子弹正常走销毁
	result.veto_release = true
	bag.decrement_base("bounce_count", 1.0)
	if "linear_velocity" in bullet:
		var v: Vector2 = bullet.linear_velocity
		bullet.linear_velocity = Vector2(-v.x, v.y)
		if "rotation" in bullet:
			bullet.rotation = bullet.linear_velocity.angle()
