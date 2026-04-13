extends Node
## Autoload: SkillRegistry
## 技能资源注册表
## 管理 Skill 资源的加载、缓存和获取

## 单例实例（不使用类型声明，因为是 autoload）
static var instance

## 显式加载依赖类（避免 GDScript 方法冲突）
const SkillConfigClass = preload("res://Scripts/GameBase/BattleSystemBase/SkillSystem/SkillConfig.gd")
const SkillBaseClass = preload("res://Scripts/GameBase/BattleSystemBase/SkillSystem/SkillBase.gd")

## 技能缓存字典 {skill_id: SkillBase}
var _skill_cache: Dictionary = {}

## 按类型分类
var _active_skills: Array[SkillBase] = []
var _passive_skills: Array[SkillBase] = []
var _triggered_skills: Array[SkillBase] = []

## 初始化完成信号
signal skill_registry_initialized

func _init():
	instance = self

func _ready():
	# 扫描并注册所有 Skill 资源
	_scan_and_register_skills()

	skill_registry_initialized.emit()

#region 公共 API - Skill 获取
## 根据 ID 获取技能模板（返回深拷贝实例）
func get_skill(skill_id: String) -> SkillBase:
	if not _skill_cache.has(skill_id):
		push_warning("SkillRegistry: 未找到 Skill ID='%s'" % skill_id)
		return null

	var skill_template = _skill_cache[skill_id]
	return skill_template.duplicate(true)

## 获取所有主动技能模板
func get_all_active_skills() -> Array[SkillBase]:
	return _duplicate_skill_list(_active_skills)

## 获取所有被动技能模板
func get_all_passive_skills() -> Array[SkillBase]:
	return _duplicate_skill_list(_passive_skills)

## 获取所有触发技能模板
func get_all_triggered_skills() -> Array[SkillBase]:
	return _duplicate_skill_list(_triggered_skills)

## 检查技能是否存在
func has_skill(skill_id: String) -> bool:
	return _skill_cache.has(skill_id)

## 获取所有已注册的技能 ID
func get_all_skill_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _skill_cache.keys():
		ids.append(id)
	return ids
#endregion

#region 公共 API - Skill 注册
## 注册技能（手动添加）
func register_skill(skill: SkillBase) -> void:
	if skill == null or skill.skill_id.is_empty():
		push_warning("SkillRegistry: 无法注册空 Skill 或无 ID 的 Skill")
		return

	_skill_cache[skill.skill_id] = skill

	# 按类型分类
	match skill.skill_type:
		SkillConfigClass.SkillType.ACTIVE: _active_skills.append(skill)
		SkillConfigClass.SkillType.PASSIVE: _passive_skills.append(skill)
		SkillConfigClass.SkillType.TRIGGERED: _triggered_skills.append(skill)

## 扫描并注册 prefab/Skills/ 目录下的所有技能资源
func _scan_and_register_skills() -> void:
	var skill_dir = "res://prefab/Skills/"

	var dir = DirAccess.open(skill_dir)
	if dir == null:
		push_warning("SkillRegistry: 无法打开目录 %s" % skill_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path = skill_dir + file_name
			_load_and_register_skill(full_path)
		file_name = dir.get_next()

	dir.list_dir_end()

## 加载并注册单个技能
func _load_and_register_skill(path: String) -> void:
	if not ResourceLoader.exists(path):
		return

	var resource = load(path)
	if resource is SkillBase:
		register_skill(resource)
	else:
		push_warning("SkillRegistry: %s 不是 SkillBase 类型" % path)
#endregion

#region 公共 API - 创建技能实例
## 创建技能实例并初始化
func create_skill_instance(skill_id: String, owner: BattleActor) -> SkillBase:
	var skill_template = get_skill(skill_id)
	if skill_template == null:
		return null

	# 初始化技能
	skill_template.initialize(owner)
	return skill_template

## 为 BattleActor 创建 SkillManager 并添加指定技能
func setup_skill_manager(actor: BattleActor, skill_ids: Array[String]) -> SkillManager:
	var manager = SkillManager.new()
	actor.add_child(manager)

	for skill_id in skill_ids:
		var skill = create_skill_instance(skill_id, actor)
		if skill:
			manager.add_skill(skill)

	return manager
#endregion

#region 内部方法
## 深拷贝技能列表
func _duplicate_skill_list(skill_list: Array[SkillBase]) -> Array[SkillBase]:
	var result: Array[SkillBase] = []
	for skill in skill_list:
		result.append(skill.duplicate(true))
	return result
#endregion