class_name TraitDefinition extends Resource
## 特质定义（数据模板，存 res://resources/gameplay/traits/）。
## 特质 = 它声明的一组属性（注入 holder 的 TraitPropertyBag）+ 一段持久 Flow（挂逻辑钩子）。
## 各系统（子弹/角色/武器/技能）按 trait_id 引用同一批特质。
## 本身是无运行时状态的模板；TraitRegistry.get_trait 返回 duplicate(true) 副本。

#region 标识
@export_group("标识")
## 【特质ID】注册表主键，必填且唯一。各系统按它引用。
@export var trait_id: String = ""
## 【显示名称】编辑器/UI 可读名。
@export var display_name: String = ""
#endregion

#region 声明的属性
@export_group("声明的属性")
## 【声明属性】此特质引入到 holder 属性袋的属性（名→基础值）。
## 如弹射特质声明 {"bounce_count": 3.0}。其他特质可操作这些属性名（共享黑板）。
@export var declared_properties: Dictionary = {}
#endregion

#region 逻辑
@export_group("逻辑")
## 【特质Flow】特质逻辑的 FlowGraph 节点树（第十三期：从 GameplayFlowBase 改为 FlowGraph）。
## 通常是 FOREVER Duration + Trigger(关心事件, NEVER) → FlowLeaf（如 FlowLeaf_Bounce）。
## 由 TraitContainer 经 FlowInterpreter 驱动（add 时 start、dispatch 时 deliver_event、stop 时 cancel）。
@export var trait_flow: FlowGraph
## 【关心事件】此特质响应的事件类型（GameplayEvent.EventType 的 int）。
## TraitContainer 据此过滤，把匹配事件 deliver_event 给 trait_flow 的解释器。
@export var listen_events: Array[int] = []
#endregion

## 校验定义完整性，返回错误描述列表（空 = 通过）。供编辑器 Validate 用。
func validate() -> Array[String]:
	var errors: Array[String] = []
	if trait_id.strip_edges().is_empty():
		errors.append("trait_id 不能为空")
	if trait_flow == null:
		errors.append("未设置 trait_flow（特质逻辑 Flow）")
	for key in declared_properties:
		if not (typeof(declared_properties[key]) in [TYPE_FLOAT, TYPE_INT]):
			errors.append("declared_properties['%s'] 必须是数值" % key)
	return errors
