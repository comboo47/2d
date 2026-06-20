extends SceneTree
## 武器/子弹数据驱动系统的回归测试。
## 运行：godot --headless --path . -s res://tests/WeaponSystemTest.gd
## 与 GameplayCoreTest 同风格：每个 _test_* 返回 true 或错误字符串。

var _failures := 0
var _nodes: Array[Node] = []

func _initialize() -> void:
	_run("bow_shot_speed_scales_with_charge", _test_bow_shot_speed)
	_run("weapon_driver_has_node_contract", _test_weapon_driver_contract)
	_run("bullet_apply_definition_sets_stats", _test_bullet_apply_definition_sets_stats)
	_run("bullet_definition_resolve_scene_fallback", _test_bullet_definition_resolve_scene_fallback)
	_run("motion_registry_has_and_create", _test_motion_registry_has_and_create)
	_run("weapon_definition_validate_reports_errors", _test_weapon_definition_validate_reports_errors)
	_run("bullet_definition_validate_reports_errors", _test_bullet_definition_validate_reports_errors)
	_run("registry_get_definition_returns_deep_copy", _test_registry_get_definition_returns_deep_copy)
	quit(_failures)

func _run(test_name: String, test_callable: Callable) -> void:
	var result = test_callable.call()
	if result is bool and result == true:
		print("PASS ", test_name)
	else:
		_failures += 1
		push_error("FAIL %s: %s" % [test_name, str(result)])
	_cleanup()

#region 第十二期 武器开火=skill 激活
func _test_bow_shot_speed() -> Variant:
	# FlowLeaf_BowShot：速度随 charge_ratio 在 base..max_charge 之间 lerp（取代旧 charged_speed）
	var shot = load("res://src/gameplay/flows/graph/leaves/FlowLeaf_BowShot.gd").new()
	shot.base_speed = 250.0
	shot.max_charge_speed = 650.0
	# ratio=0 → base
	var ctx0 := GameplayFlowContext.new()
	ctx0.event_data["charge_ratio"] = 0.0
	if not is_equal_approx(shot._speed_for(ctx0), 250.0):
		return "ratio=0 应为 base 250，得到 %s" % shot._speed_for(ctx0)
	# ratio=1 → max
	var ctx1 := GameplayFlowContext.new()
	ctx1.event_data["charge_ratio"] = 1.0
	if not is_equal_approx(shot._speed_for(ctx1), 650.0):
		return "ratio=1 应为 max 650，得到 %s" % shot._speed_for(ctx1)
	# ratio=0.5 → 中点
	var ctxh := GameplayFlowContext.new()
	ctxh.event_data["charge_ratio"] = 0.5
	if not is_equal_approx(shot._speed_for(ctxh), 450.0):
		return "ratio=0.5 应为 450，得到 %s" % shot._speed_for(ctxh)
	return true

func _test_weapon_driver_contract() -> Variant:
	# WeaponDriver 应实现 WeaponRoot/Player 调用的节点契约方法
	var drv = load("res://src/gameplay/weapons/WeaponDriver.gd").new()
	_track(drv)
	for m in ["on_weapon_enter", "on_weapon_exit", "hold_fire", "fire", "get_spawn_position", "trigger_skill_by_type"]:
		if not drv.has_method(m):
			return "WeaponDriver 缺少契约方法 %s" % m
	return true
#endregion

#region 子弹 apply_definition
func _test_bullet_apply_definition_sets_stats() -> Variant:
	var d := BulletDefinition.new()
	d.bullet_id = "b_test"
	d.base_damage = 21.0
	d.damage_buff_id = "burn"
	d.speed = 410.0

	# 运行时 load（此时 autoload 已注册，BulletBase 引用的 BattleManager 可编译）。
	# 与 GameplayCoreTest 对 BattleManager 的处理同理。
	var bullet_base_script = load("res://src/gameplay/bullets/BulletBase.gd")
	var b = bullet_base_script.new()
	_track(b)
	b.apply_definition(d)

	if not is_equal_approx(b.base_damage, 21.0):
		return "base_damage 未应用，得到 %s" % b.base_damage
	if b.damagebuffid != "burn":
		return "damagebuffid 未应用，得到 %s" % b.damagebuffid
	return true

func _test_bullet_definition_resolve_scene_fallback() -> Variant:
	var d := BulletDefinition.new()
	# 无 bullet_scene 时应回退到 fallback。
	var fallback := PackedScene.new()
	if BulletDefinition.resolve_scene(d, fallback) != fallback:
		return "无 bullet_scene 时应返回 fallback"
	if BulletDefinition.resolve_scene(null, fallback) != fallback:
		return "def 为 null 时应返回 fallback"
	return true
#endregion

#region 扩展点注册表
func _test_motion_registry_has_and_create() -> Variant:
	if not BulletMotionRegistry.has(&"homing"):
		return "homing 应已注册"
	if not BulletMotionRegistry.has("straight"):
		return "字符串 key 'straight' 也应识别"
	if BulletMotionRegistry.has(&"does_not_exist"):
		return "未注册 key 应返回 false"
	var m = BulletMotionRegistry.create(&"homing")
	if m == null or not (m is BulletMotionBase):
		return "create(homing) 应返回 BulletMotionBase 实例"
	if BulletMotionRegistry.create(&"nope") != null:
		return "create 未注册 key 应返回 null"
	return true
#endregion

#region 校验
func _test_weapon_definition_validate_reports_errors() -> Variant:
	var d := WeaponDefinition.new()
	# 空 weapon_id + 缺 bullet_def + 无开火方式（input_bindings 空且无 fire_flow）
	var errs := d.validate()
	if errs.is_empty():
		return "应报告 weapon_id/bullet_def/开火方式 错误"
	var joined := ", ".join(errs)
	if not joined.contains("weapon_id"):
		return "应报告 weapon_id 为空"
	if not joined.contains("bullet_def") and not joined.contains("BulletDefinition"):
		return "应报告缺少 bullet_def"
	if not joined.contains("input_bindings") and not joined.contains("fire_flow"):
		return "应报告缺少开火方式"

	# 修好后应通过：填 weapon_id + bullet_def + 一条完整 input_binding
	d.weapon_id = "ok"
	var bd := BulletDefinition.new()
	bd.bullet_id = "ok_b"
	bd.bullet_scene = PackedScene.new()
	d.bullet_def = bd
	var binding := WeaponInputBinding.new()
	binding.cadence = WeaponCadence.new()
	binding.skill = SkillBase.new()
	d.input_bindings = [binding]
	if not d.validate().is_empty():
		return "修复后应校验通过，仍有：%s" % ", ".join(d.validate())
	return true

func _test_bullet_definition_validate_reports_errors() -> Variant:
	var d := BulletDefinition.new()
	d.motion_key = &"bogus_motion"
	var errs := d.validate()
	var joined := ", ".join(errs)
	if not joined.contains("bullet_id"):
		return "应报告 bullet_id 为空"
	if not joined.contains("外观") and not joined.contains("bullet_scene"):
		return "应报告缺少外观来源"
	if not joined.contains("motion_key"):
		return "应报告坏的 motion_key"
	return true
#endregion

#region 注册表深拷贝
func _test_registry_get_definition_returns_deep_copy() -> Variant:
	# 直接验证 duplicate(true) 语义：改动返回值不应影响源模板。
	var template := WeaponDefinition.new()
	template.weapon_id = "src"
	template.base_damage = 10.0
	var copy: WeaponDefinition = template.duplicate(true)
	copy.base_damage = 999.0
	if not is_equal_approx(template.base_damage, 10.0):
		return "深拷贝后改动副本不应影响源模板"
	return true
#endregion

#region 工具
func _track(n: Node) -> void:
	if n and not _nodes.has(n):
		_nodes.append(n)

func _cleanup() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()
#endregion
