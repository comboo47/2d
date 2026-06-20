@tool
extends Control
## GPManager —— Gameplay 内容管理面板（统一编辑器）。
## 左侧树列出 Actors / Weapons / Bullets / Skills / Buffs / Traits 六类 .tres；
## 顶部动作栏负责新建/复制/模板/删除/校验；选中或点「编辑」把资源路由到 Godot
## 主 Inspector 编辑（方案 B）。
##
## 设计要点：
## - 不自绘字段编辑控件（Godot 原生 Inspector 对 Array/子资源/枚举/分组支持最好）。
## - Actor/Weapon 节点下用「引用关系」展示其拥有/引用的 Skill/Buff/Flow（非目录）。
## - Buff 节点展示第八期双轨（BuffFlow + effects）；Skill 节点展示 flow_refs。
## - 物理文件全部平铺在各自全局目录；新建时按类型固定落盘，用户不关心路径。
## - 校验只用静态注册表 + DirAccess/ResourceLoader，不依赖运行时 autoload 单例。

const ACTOR_DIR := "res://resources/gameplay/actors/"
const WEAPON_DIR := "res://resources/gameplay/weapons/"
const BULLET_DIR := "res://resources/gameplay/bullets/"
const SKILL_DIR := "res://resources/gameplay/skills/"
const BUFF_DIR := "res://resources/gameplay/buffs/"
const TRAIT_DIR := "res://resources/gameplay/traits/"

const TYPE_ACTOR := "actor"
const TYPE_WEAPON := "weapon"
const TYPE_BULLET := "bullet"
const TYPE_SKILL := "skill"
const TYPE_BUFF := "buff"
const TYPE_TRAIT := "trait"

# 各类型的目录、id 前缀、分类标题
const TYPE_META := {
	"actor": {"dir": ACTOR_DIR, "prefix": "actor_", "label": "Actors"},
	"weapon": {"dir": WEAPON_DIR, "prefix": "w_", "label": "Weapons"},
	"bullet": {"dir": BULLET_DIR, "prefix": "b_", "label": "Bullets"},
	"skill": {"dir": SKILL_DIR, "prefix": "s_", "label": "Skills"},
	"buff": {"dir": BUFF_DIR, "prefix": "bf_", "label": "Buffs"},
	"trait": {"dir": TRAIT_DIR, "prefix": "trait_", "label": "Traits"},
}

var _tree: Tree
var _status: RichTextLabel
var _templates_btn: MenuButton

var _root_item: TreeItem
var _type_roots := {}  # type -> TreeItem

# 模板菜单项 id -> 处理函数名
var _template_actions := {}

func _ready() -> void:
	_build_ui()
	refresh()

#region UI 构建
func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(280, 340)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	# --- 动作栏第 1 行：新建各类内容 ---
	var row1 := HBoxContainer.new()
	vbox.add_child(row1)
	row1.add_child(_make_button("＋角色", _on_new_actor))
	row1.add_child(_make_button("＋武器", _on_new_weapon))
	row1.add_child(_make_button("＋子弹", _on_new_bullet))
	row1.add_child(_make_button("＋技能", _on_new_skill))
	row1.add_child(_make_button("＋Buff", _on_new_buff))
	row1.add_child(_make_button("＋特质", _on_new_trait))

	# --- 动作栏第 2 行：模板 + 操作选中项 ---
	var row2 := HBoxContainer.new()
	vbox.add_child(row2)
	_templates_btn = MenuButton.new()
	_templates_btn.text = "模板▾"
	_templates_btn.tooltip_text = "从模板新建（预填合理默认值）"
	_build_templates_menu()
	row2.add_child(_templates_btn)
	row2.add_child(_make_button("复制", _on_duplicate))
	row2.add_child(_make_button("删除", _on_delete))
	row2.add_child(_make_button("校验", _on_validate))
	row2.add_child(_make_button("编辑", _on_edit_in_inspector))
	row2.add_child(_make_button("刷新", refresh))

	# --- 资源树 ---
	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.hide_root = true
	_tree.allow_rmb_select = true
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_activated.connect(_on_edit_in_inspector)
	vbox.add_child(_tree)

	# --- 状态/校验输出 ---
	_status = RichTextLabel.new()
	_status.fit_content = true
	_status.custom_minimum_size = Vector2(0, 84)
	_status.bbcode_enabled = true
	_status.scroll_active = true
	vbox.add_child(_status)

func _make_button(text: String, handler: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(handler)
	return b

func _build_templates_menu() -> void:
	var popup := _templates_btn.get_popup()
	popup.clear()
	_template_actions.clear()
	var entries := [
		["角色：基础敌人", "_template_actor_basic"],
		["武器：弓 (bow)", "_template_weapon_bow"],
		["武器：瓶 (bottle)", "_template_weapon_bottle"],
		["武器：弩 (crossbow)", "_template_weapon_crossbow"],
		["子弹：普通 (gravity)", "_template_bullet_normal"],
		["子弹：直射 (straight)", "_template_bullet_straight"],
		["子弹：追踪 (homing)", "_template_bullet_homing"],
	]
	for i in entries.size():
		popup.add_item(entries[i][0], i)
		_template_actions[i] = entries[i][1]
	if not popup.id_pressed.is_connected(_on_template_selected):
		popup.id_pressed.connect(_on_template_selected)
#endregion

#region 树构建
## 重建资源树（公共，供插件菜单/刷新按钮调用）。
func refresh() -> void:
	if _tree == null:
		return
	var selected_path := _get_selected_path()
	_tree.clear()
	_type_roots.clear()
	_root_item = _tree.create_item()

	for type in ["actor", "weapon", "bullet", "skill", "buff", "trait"]:
		var root := _tree.create_item(_root_item)
		root.set_text(0, TYPE_META[type]["label"])
		root.set_selectable(0, false)
		_type_roots[type] = root
		_populate_type(root, type)

	if not selected_path.is_empty():
		_select_by_path(selected_path)
	_set_status("[i]六类 Gameplay 内容。选中后点「编辑」在主 Inspector 修改；Actor/Weapon 节点下显示引用的技能/Buff，子弹显示携带特质，Buff 显示 BuffFlow/效果，技能显示使用Flow。[/i]")

func _populate_type(parent: TreeItem, type: String) -> void:
	var dir_path: String = TYPE_META[type]["dir"]
	for file_name in _list_tres(dir_path):
		var full := dir_path + file_name
		var res = load(full)
		if res == null:
			continue
		var item := _tree.create_item(parent)
		item.set_text(0, _make_label(res, type, file_name))
		item.set_metadata(0, {"type": type, "path": full, "id": _res_id(res, type)})
		# Actor / Weapon 节点下展示引用的技能/Buff
		if type == TYPE_ACTOR:
			_add_owned_group(item, "拥有技能", res.skills, TYPE_SKILL)
			_add_owned_group(item, "拥有Buff", res.buffs, TYPE_BUFF)
		elif type == TYPE_WEAPON:
			_add_weapon_skill_refs(item, res)
		elif type == TYPE_BULLET:
			_add_bullet_trait_refs(item, res)
		elif type == TYPE_TRAIT:
			_add_trait_property_info(item, res)
		elif type == TYPE_BUFF:
			_add_buff_refs(item, res)
		elif type == TYPE_SKILL:
			_add_skill_refs(item, res)

## 在宿主节点下加一个分组，列出引用的资源（点击可跳到该资源编辑）。
func _add_owned_group(parent: TreeItem, group_label: String, refs: Array, ref_type: String) -> void:
	if refs == null or refs.is_empty():
		return
	var group := _tree.create_item(parent)
	group.set_text(0, "%s (%d)" % [group_label, refs.size()])
	group.set_selectable(0, false)
	for r in refs:
		if r == null:
			continue
		_add_ref_item(group, r, ref_type)

func _add_weapon_skill_refs(parent: TreeItem, weapon) -> void:
	# 输入模式
	if "input_mode" in weapon and weapon.input_mode != null:
		var im := _tree.create_item(parent)
		im.set_text(0, "⌨ 输入模式: %s" % _input_mode_name(weapon.input_mode.mode))
		im.set_selectable(0, false)
	# 技能槽 / 被动引用的技能
	var skills := []
	for slot in [weapon.primary_skill_slot, weapon.secondary_skill_slot, weapon.ultimate_skill_slot]:
		if slot != null and slot.skill != null:
			skills.append(slot.skill)
	for s in weapon.passive_skills:
		if s != null:
			skills.append(s)
	_add_owned_group(parent, "引用技能", skills, TYPE_SKILL)

## 子弹节点下展示携带的特质（traits 是 id 字符串数组，解析到 trait .tres 可点开编辑）。
func _add_bullet_trait_refs(parent: TreeItem, bullet) -> void:
	if not ("traits" in bullet) or bullet.traits == null or bullet.traits.is_empty():
		return
	var group := _tree.create_item(parent)
	group.set_text(0, "携带特质 (%d)" % bullet.traits.size())
	group.set_selectable(0, false)
	for tid in bullet.traits:
		var item := _tree.create_item(group)
		var path := "%s%s.tres" % [TRAIT_DIR, tid]
		if ResourceLoader.exists(path):
			item.set_text(0, "↳ %s" % tid)
			item.set_metadata(0, {"type": TYPE_TRAIT, "path": path, "id": tid, "ref": true})
		else:
			item.set_text(0, "↳ %s [缺失]" % tid)
			item.set_selectable(0, false)

## 特质节点下展示它声明的属性（名→默认值），直观看 trait 数据。
func _add_trait_property_info(parent: TreeItem, trait_def) -> void:
	if not ("declared_properties" in trait_def) or trait_def.declared_properties.is_empty():
		return
	var group := _tree.create_item(parent)
	group.set_text(0, "声明属性 (%d)" % trait_def.declared_properties.size())
	group.set_selectable(0, false)
	for key in trait_def.declared_properties:
		var item := _tree.create_item(group)
		item.set_text(0, "• %s = %s" % [key, trait_def.declared_properties[key]])
		item.set_selectable(0, false)

## Buff 节点下展示第八期双轨：⏳ BuffFlow（常驻 flow）+ 效果列表 effects（ModifierEffect/StateEffect）。
func _add_buff_refs(parent: TreeItem, buff) -> void:
	# 轨道一：BuffFlow
	if "buff_flow" in buff and buff.buff_flow != null:
		_add_flow_row(parent, "⏳ BuffFlow", buff.buff_flow)
	# 轨道二：effects 列表（内联子资源，只读展示其类型名 + 描述）
	if "effects" in buff and buff.effects != null and not buff.effects.is_empty():
		var group := _tree.create_item(parent)
		group.set_text(0, "效果 effects (%d)" % buff.effects.size())
		group.set_selectable(0, false)
		for eff in buff.effects:
			var item := _tree.create_item(group)
			if eff == null:
				item.set_text(0, "• (空)")
			else:
				var cls: String = eff.get_class()
				var scr = eff.get_script()
				if scr and scr.get_global_name() != "":
					cls = scr.get_global_name()
				var desc := ""
				if eff.has_method("get_description"):
					desc = eff.get_description()
				item.set_text(0, "• %s: %s" % [cls, desc])
			item.set_selectable(0, false)

## Skill 节点下展示使用的 Flow（flow_refs 可点开 + on_use_flow_id 只读）。
func _add_skill_refs(parent: TreeItem, skill) -> void:
	if "flow_refs" in skill and skill.flow_refs != null and not skill.flow_refs.is_empty():
		var group := _tree.create_item(parent)
		group.set_text(0, "使用Flow flow_refs (%d)" % skill.flow_refs.size())
		group.set_selectable(0, false)
		for flow in skill.flow_refs:
			if flow != null:
				_add_flow_row(group, "↳", flow)
	if "on_use_flow_id" in skill and not String(skill.on_use_flow_id).is_empty():
		var item := _tree.create_item(parent)
		item.set_text(0, "on_use_flow_id: %s" % skill.on_use_flow_id)
		item.set_selectable(0, false)

## 展示一个 flow 行（共用）：有独立文件则可点开编辑，内联/脚本类则只读。
func _add_flow_row(parent: TreeItem, prefix: String, flow) -> void:
	var item := _tree.create_item(parent)
	var fname: String = flow.flow_name if not flow.flow_name.is_empty() else flow.flow_id
	if fname.is_empty():
		fname = "(未命名)"
	item.set_text(0, "%s: %s" % [prefix, fname])
	var fpath: String = flow.resource_path
	if not fpath.is_empty():
		item.set_metadata(0, {"type": "flow", "path": fpath, "id": flow.flow_id, "ref": true})
	else:
		item.set_selectable(0, false)

## 引用项：metadata 指向被引资源的 path，点击即编辑该资源；标记 ref=true 禁止从此处删除。
func _add_ref_item(parent: TreeItem, res, ref_type: String) -> void:
	var item := _tree.create_item(parent)
	var id := _res_id(res, ref_type)
	var name := _res_name(res, ref_type)
	item.set_text(0, "↳ %s" % (name if not name.is_empty() else id))
	item.set_metadata(0, {"type": ref_type, "path": res.resource_path, "id": id, "ref": true})

func _list_tres(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir = DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var f = dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.ends_with(".tres"):
			out.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out

## 取资源的主键 id（各类型字段名不同）。
func _res_id(res, type: String) -> String:
	match type:
		TYPE_WEAPON: return res.weapon_id
		TYPE_BULLET: return res.bullet_id
		TYPE_SKILL: return res.skill_id
		TYPE_BUFF: return res.buff_id
		TYPE_ACTOR: return str(res.actor_id)
		TYPE_TRAIT: return res.trait_id
	return ""

## 取资源的显示名。
func _res_name(res, type: String) -> String:
	match type:
		TYPE_WEAPON, TYPE_BULLET, TYPE_ACTOR, TYPE_TRAIT: return res.display_name
		TYPE_SKILL: return res.skill_name
		TYPE_BUFF: return res.buff_name
	return ""

func _make_label(res, type: String, file_name: String) -> String:
	var id := _res_id(res, type)
	var name := _res_name(res, type)
	if name.is_empty():
		name = file_name.get_basename()
	return "%s  (%s)" % [name, id]
#endregion

#region 选中/编辑（方案 B）
func _on_item_selected() -> void:
	var meta := _get_selected_meta()
	if meta.is_empty():
		return
	var suffix := "（引用项）" if meta.get("ref", false) else ""
	_set_status("已选中 [b]%s[/b]%s\n%s" % [meta.get("id", "?"), suffix, meta.get("path", "")])

## 把选中资源路由到 Godot 主 Inspector（方案 B 核心）。
func _on_edit_in_inspector() -> void:
	var meta := _get_selected_meta()
	if meta.is_empty():
		_set_status("[color=orange]请先在树里选中一个资源[/color]")
		return
	var path: String = meta.get("path", "")
	if path.is_empty():
		_set_status("[color=orange]该引用项无独立文件（可能是内联资源），无法单独编辑[/color]")
		return
	var res = load(path)
	if res == null:
		_set_status("[color=red]加载失败：%s[/color]" % path)
		return
	EditorInterface.edit_resource(res)
	_set_status("已在主 Inspector 打开 [b]%s[/b]，编辑后记得 Ctrl+S 保存。" % meta.get("id", ""))
#endregion

#region 新建 / 复制 / 模板 / 删除
func _on_new_actor() -> void:
	var def := ActorDefinition.new()
	var aid := _next_actor_id()
	def.actor_id = aid
	def.display_name = "新角色 %d" % aid
	_save_new(def, ACTOR_DIR, "actor_%d" % aid, TYPE_ACTOR)

func _on_new_weapon() -> void:
	var def := WeaponDefinition.new()
	var id := _next_id(WEAPON_DIR, "w_")
	def.weapon_id = id
	def.display_name = id
	_save_new(def, WEAPON_DIR, id, TYPE_WEAPON)

func _on_new_bullet() -> void:
	var def := BulletDefinition.new()
	var id := _next_id(BULLET_DIR, "b_")
	def.bullet_id = id
	def.display_name = id
	_save_new(def, BULLET_DIR, id, TYPE_BULLET)

func _on_new_skill() -> void:
	var def := SkillBase.new()
	var id := _next_id(SKILL_DIR, "s_")
	def.skill_id = id
	def.skill_name = id
	_save_new(def, SKILL_DIR, id, TYPE_SKILL)

func _on_new_buff() -> void:
	var def := AttributeBuff.new()
	var id := _next_id(BUFF_DIR, "bf_")
	def.buff_id = id
	def.buff_name = id
	_save_new(def, BUFF_DIR, id, TYPE_BUFF)

func _on_new_trait() -> void:
	var def := TraitDefinition.new()
	var id := _next_id(TRAIT_DIR, "trait_")
	def.trait_id = id
	def.display_name = id
	_save_new(def, TRAIT_DIR, id, TYPE_TRAIT)

func _on_template_selected(menu_id: int) -> void:
	var fn = _template_actions.get(menu_id, "")
	if fn != "" and has_method(fn):
		call(fn)

func _on_duplicate() -> void:
	var meta := _get_selected_meta()
	if meta.is_empty():
		_set_status("[color=orange]请先选中要复制的资源[/color]")
		return
	if meta.get("ref", false):
		_set_status("[color=orange]引用项不可复制，请到对应分类下复制源资源[/color]")
		return
	var src = load(meta["path"])
	if src == null:
		return
	var type: String = meta["type"]
	var dup = src.duplicate(true)
	if type == TYPE_ACTOR:
		var aid := _next_actor_id()
		dup.actor_id = aid
		dup.display_name = "%s_copy" % src.display_name
		_save_new(dup, ACTOR_DIR, "actor_%d" % aid, TYPE_ACTOR)
	else:
		var prefix: String = TYPE_META[type]["prefix"]
		var dir: String = TYPE_META[type]["dir"]
		var id := _next_id(dir, prefix)
		_set_res_id(dup, type, id)
		_save_new(dup, dir, id, type)

func _on_delete() -> void:
	var meta := _get_selected_meta()
	if meta.is_empty():
		_set_status("[color=orange]请先选中要删除的资源[/color]")
		return
	if meta.get("ref", false):
		_set_status("[color=orange]这是引用项，请到对应分类（Skills/Buffs）下删除源文件[/color]")
		return
	var path: String = meta["path"]
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if err != OK:
		var d = DirAccess.open(path.get_base_dir())
		if d:
			d.remove(path.get_file())
	_rescan_fs()
	refresh()
	_set_status("已删除 [b]%s[/b]" % meta.get("id", path))
#endregion

#region 模板工厂
func _template_actor_basic() -> void:
	var d := ActorDefinition.new()
	var aid := _next_actor_id()
	d.actor_id = aid
	d.display_name = "基础敌人 %d" % aid
	d.description = "模板生成的基础敌人，请补充 prefab 与属性。"
	d.attributes = {"max_hp": 10.0, "attack": 1.0, "armor": 0.0, "speed": 50.0}
	_save_new(d, ACTOR_DIR, "actor_%d" % aid, TYPE_ACTOR)

func _template_weapon_bow() -> void:
	var d := WeaponDefinition.new()
	var id := _next_id(WEAPON_DIR, "w_")
	d.weapon_id = id
	d.display_name = "新弓 %s" % id
	d.weapon_type = WeaponConfig.WeaponType.BOW
	d.bullet_type = WeaponConfig.BulletType.NORMAL
	d.base_speed = 250.0
	d.max_charge_speed = 650.0
	d.charge_rate = 5.0
	d.input_mode = _make_input_mode(WeaponInputMode.Mode.CHARGE)
	# 第十二期：开火走 input_bindings + skill；模板暂不预挂（作者在 Inspector 配 bindings）。
	_save_new(d, WEAPON_DIR, id, TYPE_WEAPON)

func _template_weapon_bottle() -> void:
	var d := WeaponDefinition.new()
	var id := _next_id(WEAPON_DIR, "w_")
	d.weapon_id = id
	d.display_name = "新瓶 %s" % id
	d.weapon_type = WeaponConfig.WeaponType.BOTTLE
	d.bullet_type = WeaponConfig.BulletType.NORMAL
	d.base_speed = 300.0
	d.charge_time = 0.7
	d.extra_params = {"spread_angle": 0.25}
	d.input_mode = _make_input_mode(WeaponInputMode.Mode.CHARGE)
	_save_new(d, WEAPON_DIR, id, TYPE_WEAPON)

func _template_weapon_crossbow() -> void:
	var d := WeaponDefinition.new()
	var id := _next_id(WEAPON_DIR, "w_")
	d.weapon_id = id
	d.display_name = "新弩 %s" % id
	d.weapon_type = WeaponConfig.WeaponType.CROSSBOW
	d.bullet_type = WeaponConfig.BulletType.STRAIGHT
	d.base_speed = 250.0
	d.max_energy = 100.0
	d.energy_cost = 10.0
	d.energy_regen = 3.0
	d.charge_time = 0.7
	d.extra_params = {"fire_interval": 0.1}
	d.input_mode = _make_input_mode(WeaponInputMode.Mode.HOLD)
	_save_new(d, WEAPON_DIR, id, TYPE_WEAPON)

func _template_bullet_normal() -> void:
	var d := BulletDefinition.new()
	var id := _next_id(BULLET_DIR, "b_")
	d.bullet_id = id
	d.display_name = "普通弹 %s" % id
	d.bullet_type = WeaponConfig.BulletType.NORMAL
	d.motion_key = &"gravity"
	d.speed = 250.0
	d.base_damage = 10.0
	_save_new(d, BULLET_DIR, id, TYPE_BULLET)

func _template_bullet_straight() -> void:
	var d := BulletDefinition.new()
	var id := _next_id(BULLET_DIR, "b_")
	d.bullet_id = id
	d.display_name = "直射弹 %s" % id
	d.bullet_type = WeaponConfig.BulletType.STRAIGHT
	d.motion_key = &"straight"
	d.gravity_scale_override = 0.0
	d.speed = 350.0
	d.base_damage = 8.0
	_save_new(d, BULLET_DIR, id, TYPE_BULLET)

func _template_bullet_homing() -> void:
	var d := BulletDefinition.new()
	var id := _next_id(BULLET_DIR, "b_")
	d.bullet_id = id
	d.display_name = "追踪弹 %s" % id
	d.bullet_type = WeaponConfig.BulletType.STRAIGHT
	d.motion_key = &"homing"
	d.gravity_scale_override = 0.0
	d.speed = 300.0
	d.base_damage = 12.0
	_save_new(d, BULLET_DIR, id, TYPE_BULLET)
#endregion

#region 校验
func _on_validate() -> void:
	var meta := _get_selected_meta()
	if meta.is_empty():
		_validate_all()
		return
	var res = load(meta["path"]) if not meta.get("path", "").is_empty() else null
	if res == null or not res.has_method("validate"):
		_validate_all()
		return
	var errs: Array = res.validate()
	if errs.is_empty():
		_set_status("[color=green]✔ %s 校验通过[/color]" % meta.get("id", ""))
	else:
		_set_status("[color=red]✘ %s 有 %d 个问题：[/color]\n• %s" % [meta.get("id", ""), errs.size(), "\n• ".join(errs)])

func _validate_all() -> void:
	var lines := []
	var total_err := 0
	for type in ["actor", "weapon", "bullet", "skill", "buff", "trait"]:
		var dir: String = TYPE_META[type]["dir"]
		for f in _list_tres(dir):
			var res = load(dir + f)
			if res == null or not res.has_method("validate"):
				continue
			var errs: Array = res.validate()
			if not errs.is_empty():
				total_err += errs.size()
				lines.append("[color=red]%s[/color]: %s" % [f, ", ".join(errs)])
	if total_err == 0:
		_set_status("[color=green]✔ 全部资源校验通过[/color]")
	else:
		_set_status("发现 %d 个问题：\n%s" % [total_err, "\n".join(lines)])
#endregion

#region 工具
## 构造一个内联 WeaponInputMode（模板用）。
func _make_input_mode(mode: int) -> WeaponInputMode:
	var im := WeaponInputMode.new()
	im.mode = mode
	return im

## 输入模式枚举 → 名称（内联，不调用资源方法，避免 @tool placeholder 问题）。
func _input_mode_name(mode: int) -> String:
	match mode:
		0: return "CLICK 点击"
		1: return "HOLD 长按连发"
		2: return "CHARGE 蓄力"
	return "未知"

## 生成下一个未占用的 id（前缀 + 递增序号），用于 weapon/bullet/skill/buff。
func _next_id(dir_path: String, prefix: String) -> String:
	var existing := {}
	for f in _list_tres(dir_path):
		existing[f.get_basename()] = true
	var n := 1
	while existing.has("%s%d" % [prefix, n]):
		n += 1
	return "%s%d" % [prefix, n]

## 生成下一个 actor_id（int，从现有最大值 +1，最小 1001 沿用项目约定）。
func _next_actor_id() -> int:
	var max_id := 1000
	for f in _list_tres(ACTOR_DIR):
		var res = load(ACTOR_DIR + f)
		if res is ActorDefinition and res.actor_id > max_id:
			max_id = res.actor_id
	return max_id + 1

## 按类型写回资源 id 字段（用于复制时改名）。
func _set_res_id(res, type: String, id: String) -> void:
	match type:
		TYPE_WEAPON: res.weapon_id = id
		TYPE_BULLET: res.bullet_id = id
		TYPE_SKILL: res.skill_id = id
		TYPE_BUFF: res.buff_id = id
		TYPE_TRAIT: res.trait_id = id

## 落地新资源：确保目录存在 → ResourceSaver.save → 重扫文件系统 → 刷新树 → 选中并编辑。
func _save_new(res: Resource, dir_path: String, id: String, type: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var path := "%s%s.tres" % [dir_path, id]
	var err := ResourceSaver.save(res, path)
	if err != OK:
		_set_status("[color=red]保存失败（err=%d）：%s[/color]" % [err, path])
		return
	res.take_over_path(path)
	_rescan_fs()
	refresh()
	_select_by_path(path)
	EditorInterface.edit_resource(res)
	_set_status("已创建 [b]%s[/b]（%s），已在主 Inspector 打开。" % [id, TYPE_META[type]["label"]])

func _rescan_fs() -> void:
	var fs := EditorInterface.get_resource_filesystem()
	if fs:
		fs.scan()

func _get_selected_meta() -> Dictionary:
	var item := _tree.get_selected() if _tree else null
	if item == null:
		return {}
	var m = item.get_metadata(0)
	return m if m is Dictionary else {}

func _get_selected_path() -> String:
	var m := _get_selected_meta()
	return m.get("path", "")

## 在所有分类根下递归查找指定 path 的项并选中。
func _select_by_path(path: String) -> void:
	if path.is_empty():
		return
	for type in _type_roots:
		var found := _find_item_by_path(_type_roots[type], path)
		if found != null:
			found.select(0)
			_tree.scroll_to_item(found)
			return

func _find_item_by_path(node: TreeItem, path: String) -> TreeItem:
	var child: TreeItem = node.get_first_child()
	while child != null:
		var m = child.get_metadata(0)
		if m is Dictionary and m.get("path", "") == path and not m.get("ref", false):
			return child
		var deeper := _find_item_by_path(child, path)
		if deeper != null:
			return deeper
		child = child.get_next()
	return null

func _set_status(bbcode: String) -> void:
	if _status:
		_status.text = bbcode
#endregion
