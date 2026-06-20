class_name WeaponDefinition extends Resource
## 武器数据定义（第三期 Flow 驱动模型）：武器=数据载体，持有 input_mode（输入模式）
## 与 fire_flow（常驻开火 Flow，逻辑在此）。由 WeaponDriver 在装备时 start fire_flow。
## 一个 .tres = 一把武器；新武器逻辑 = 写一个继承 WeaponFireFlowBase 的 Flow 脚本。
## 存放目录：res://resources/gameplay/weapons/

#region Identity
@export_group("标识")
## 【武器ID】注册表主键，必填且唯一。WeaponRegistry 以此索引这把武器。
@export var weapon_id: String = ""
## 【显示名称】编辑器与调试用的可读名称，例如「长弓·烈焰」。不影响逻辑。
@export var display_name: String = ""
## 【武器类型】武器大类枚举：BOW弓 / BOTTLE瓶 / CROSSBOW弩 / ENEMY敌方。影响默认表现归类。
@export var weapon_type: WeaponConfig.WeaponType = WeaponConfig.WeaponType.BOW
#endregion

#region 开火行为
@export_group("开火行为")
## 【输入模式】描述开火键如何被解读（点击/长按连发/蓄力）。第十二期开火转 skill 后，
## 节奏解读移到 input_bindings 的 WeaponCadence；此字段保留作展示/兼容。
@export var input_mode: WeaponInputMode
## 【输入绑定】（第十二期）一组 {action→节奏→激活的 skill}。主攻/副攻/技能键各一条。
## WeaponDriver 为每条建 WeaponCadenceRunner，节奏到点→门控（CD/能量）→ skill.use(context)。
## 第十三期：旧 fire_flow 回退路径已删，开火统一走 input_bindings。
@export var input_bindings: Array[WeaponInputBinding] = []
## 【射速间隔】两次发射的最短间隔（秒）。射速上限——狂点也不会超过它。
## 0 = 不限制（沿用旧行为）。冷却内的开火会缓冲一发，冷却结束自动补发（跟手）。
@export var min_fire_interval: float = 0.0
#endregion

#region 子弹
@export_group("子弹")
## 【子弹定义】这把武器发射的子弹（引用一个 BulletDefinition）。决定子弹外观/伤害/弹道。
@export var bullet_def: BulletDefinition
## 【子弹类型】传给 BulletManager 的物理类型：NORMAL 受重力 / STRAIGHT 无重力直射。
@export var bullet_type: WeaponConfig.BulletType = WeaponConfig.BulletType.NORMAL
#endregion

#region 基础数值
@export_group("基础数值")
## 【基础速度】未蓄力时的子弹发射初速。
@export var base_speed: float = 250.0
## 【基础伤害】注入子弹的伤害值（命中走 DamageResolver 结算）。
@export var base_damage: float = 10.0
## 【附带BuffID】命中时给目标附加的状态 Buff 的 ID；留空则不附加。
@export var damage_buff_id: String = "1001"
#endregion

#region 能量（弩枪类）
@export_group("能量（弩枪类）")
## 【最大能量】能量上限。连射类武器（弩）用能量限制持续开火。
@export var max_energy: float = 100.0
## 【单发能耗】每次开火消耗的能量。
@export var energy_cost: float = 10.0
## 【能量回复】每秒回复的能量（非蓄力时）。
@export var energy_regen: float = 3.0
#endregion

#region 蓄力
@export_group("蓄力")
## 【蓄力最高速】蓄满时子弹可达到的最大速度（弓的蓄力增速上限）。
@export var max_charge_speed: float = 650.0
## 【蓄力速率】每帧增加的速度，决定蓄力快慢。
@export var charge_rate: float = 5.0
## 【蓄力阈值】秒。蓄力达到此时长才触发特殊效果（如瓶的散射、弩的连射）。
@export var charge_time: float = 0.7
#endregion

#region 变体专属参数
@export_group("变体专属参数")
## 【专属参数】各开火模式子类特有的参数字典，按属性名注入：
## 瓶用 {"spread_angle": 0.25}（散射角弧度）、弩用 {"fire_interval": 0.1}（连射间隔秒）。
@export var extra_params: Dictionary = {}
#endregion

#region 技能
@export_group("技能")
## 【主技能槽】绑定一个 WeaponSkillSlot，配置触发时机（开火/命中/击杀等）与技能。
@export var primary_skill_slot: WeaponSkillSlot
## 【副技能槽】第二个技能槽。
@export var secondary_skill_slot: WeaponSkillSlot
## 【终极技能槽】第三个技能槽。
@export var ultimate_skill_slot: WeaponSkillSlot
## 【被动技能】武器装备时自动生效的被动技能列表。
@export var passive_skills: Array[SkillBase] = []
#endregion

## 校验定义完整性，返回错误描述列表（空 = 通过）。供编辑器 Validate 用。
func validate() -> Array[String]:
	var errors: Array[String] = []
	if weapon_id.strip_edges().is_empty():
		errors.append("weapon_id 不能为空")
	if bullet_def == null:
		errors.append("未引用 BulletDefinition（bullet_def 为空）")
	else:
		for e in bullet_def.validate():
			errors.append("bullet_def: %s" % e)
	# 第十三期：开火统一走 input_bindings（每条需 cadence + skill）。
	if input_bindings.is_empty():
		errors.append("未配置开火方式（input_bindings 为空）")
	for i in input_bindings.size():
		var b: WeaponInputBinding = input_bindings[i]
		if b == null:
			errors.append("input_bindings[%d] 为空" % i)
		elif b.cadence == null or b.skill == null:
			errors.append("input_bindings[%d] 缺 cadence 或 skill" % i)
	return errors
