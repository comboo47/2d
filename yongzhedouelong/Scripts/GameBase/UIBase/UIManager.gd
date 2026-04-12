extends CanvasLayer
## Autoload: UIManager
## 用法: UIManager.instance.method() 或 UIManager.method()

# 单例实例
static var instance: UIManager

# 三层 CanvasLayer 索引
const LAYER_BATTLE := 0      # 战斗 HUD 层
const LAYER_MENU := 1        # 菜单层
const LAYER_OVERLAY := 2     # 叠加层（伤害数字、提示等）

# 信号
signal hp_changed(actor: BattleActor, old_value: float, new_value: float, max_value: float)
signal energy_changed(actor: BattleActor, current: float, max: float)
signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)
signal pause_state_changed(is_paused: bool)

# UI 层引用
var _layers: Array[CanvasLayer] = []
var battle_layer: CanvasLayer
var menu_layer: CanvasLayer
var overlay_layer: CanvasLayer

# 活动面板追踪
var _active_panels: Dictionary = {}  # panel_name -> UIPanel
var _current_menu: String = ""

# 伤害数字组件池
var _damage_widget_pool: Array[Control] = []
const DAMAGE_POOL_SIZE := 20

# 绑定的角色引用
var _bound_actor: BattleActor = null

# HUD 组件引用
var hp_bar_widget: Control
var energy_bar_widget: Control

#region 生命周期
func _init():
	instance = self

func _ready():
	_setup_layers()
	_setup_widget_pool()
	_setup_input()
	ui_initialized.emit()

signal ui_initialized

func _setup_layers():
	# 创建三层 CanvasLayer
	for i in range(3):
		var layer = CanvasLayer.new()
		layer.name = "UILayer_%d" % i
		layer.layer = 10 + i * 5  # 确保渲染顺序
		add_child(layer)
		_layers.append(layer)

	battle_layer = _layers[LAYER_BATTLE]
	menu_layer = _layers[LAYER_MENU]
	overlay_layer = _layers[LAYER_OVERLAY]

func _setup_widget_pool():
	# 预创建伤害数字池
	var damage_scene = UIConfig.get_scene(UIConfig.SceneType.POP_DAMAGE)
	if damage_scene:
		for i in range(DAMAGE_POOL_SIZE):
			var widget = damage_scene.instantiate()
			widget.set_process(false)
			overlay_layer.add_child(widget)
			_damage_widget_pool.append(widget)

func _setup_input():
	# ESC 键暂停菜单
	# 在 _input 中处理，需要设置 process_mode
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()
#endregion

#region 公共 API - 伤害反馈
func show_damage(actor: BattleActor, damage: float, position_offset: Vector2 = Vector2.ZERO) -> void:
	var widget = _get_damage_widget()
	if widget:
		widget.init(actor, abs(damage))
		widget.global_position = actor.global_position + Vector2(0, -12) + position_offset
		widget.global_position += Vector2(randf() * 7.5, randf() * 7.5)
		widget.pop_damage()

func _get_damage_widget() -> Control:
	for widget in _damage_widget_pool:
		if not widget.is_active():
			return widget
	# 池耗尽时动态创建
	var damage_scene = UIConfig.get_scene(UIConfig.SceneType.POP_DAMAGE)
	if damage_scene:
		var new_widget = damage_scene.instantiate()
		overlay_layer.add_child(new_widget)
		_damage_widget_pool.append(new_widget)
		return new_widget
	return null

func _return_damage_widget(widget: Control) -> void:
	widget.reset()
	widget.set_process(false)
#endregion

#region 公共 API - 战斗 UI 绑定
func bind_actor(actor: BattleActor) -> void:
	if _bound_actor == actor:
		return

	# 解绑旧角色
	if _bound_actor:
		unbind_actor(_bound_actor)

	_bound_actor = actor

	# 绑定 HP 监听
	var attr_comp = actor.GetAttributes()
	if attr_comp:
		var hp_attr = attr_comp.find_attribute(AttributeConfig.AttributeName.Hp)
		if hp_attr and hp_attr.has_signal("attribute_changed"):
			if not hp_attr.attribute_changed.is_connected(_on_actor_hp_changed):
				hp_attr.attribute_changed.connect(_on_actor_hp_changed)

	# 创建/显示 HUD
	_create_battle_hud(actor)

func unbind_actor(actor: BattleActor) -> void:
	if _bound_actor != actor:
		return

	var attr_comp = actor.GetAttributes()
	if attr_comp:
		var hp_attr = attr_comp.find_attribute(AttributeConfig.AttributeName.Hp)
		if hp_attr and hp_attr.attribute_changed.is_connected(_on_actor_hp_changed):
			hp_attr.attribute_changed.disconnect(_on_actor_hp_changed)

	_bound_actor = null
	_destroy_battle_hud()

func _bind_weapon_energy(weapon: Node) -> void:
	# 监听武器能量变化（如果武器支持）
	if weapon.has_signal("energy_changed"):
		if not weapon.energy_changed.is_connected(_on_weapon_energy_changed):
			weapon.energy_changed.connect(_on_weapon_energy_changed)
#endregion

#region 公共 API - 菜单系统
func open_menu(menu_name: String) -> void:
	if _current_menu != "":
		close_menu(_current_menu)

	var scene_path = UIConfig.get_menu_scene_path(menu_name)
	if scene_path == "":
		push_error("未找到菜单场景: %s" % menu_name)
		return

	var menu_scene = load(scene_path)
	if not menu_scene:
		push_error("无法加载菜单场景: %s" % scene_path)
		return

	var panel = menu_scene.instantiate()
	panel.name = menu_name

	menu_layer.add_child(panel)
	_active_panels[menu_name] = panel
	_current_menu = menu_name

	# 调用面板的 open 方法
	if panel.has_method("open"):
		panel.open()

	menu_opened.emit(menu_name)
	get_tree().paused = true
	pause_state_changed.emit(true)

func close_menu(menu_name: String) -> void:
	if not _active_panels.has(menu_name):
		return

	var panel = _active_panels[menu_name]

	# 调用面板的 close 方法
	if panel.has_method("close"):
		panel.close()

	panel.queue_free()
	_active_panels.erase(menu_name)

	if _current_menu == menu_name:
		_current_menu = ""

	menu_closed.emit(menu_name)

	if _active_panels.is_empty():
		get_tree().paused = false
		pause_state_changed.emit(false)

func toggle_pause_menu() -> void:
	if _current_menu == "PauseMenu":
		close_menu("PauseMenu")
	else:
		open_menu("PauseMenu")

func load_main_menu() -> void:
	# 切换到主菜单场景
	close_menu("PauseMenu")
	get_tree().change_scene_to_file("res://art/UIResource/UI/Menu/MainMenu.tscn")
#endregion

#region 内部事件处理
func _on_actor_hp_changed(attr: Attribute, old_value: float, new_value: float) -> void:
	var max_hp = attr.base_value
	hp_changed.emit(_bound_actor, old_value, new_value, max_hp)

	# 更新 HP 条
	if hp_bar_widget and hp_bar_widget.has_method("update_value"):
		hp_bar_widget.update_value(new_value, max_hp)

	# 显示伤害数字（如果是伤害）
	if new_value < old_value:
		show_damage(_bound_actor, old_value - new_value)

func _on_weapon_energy_changed(current: float, max_energy: float) -> void:
	energy_changed.emit(_bound_actor, current, max_energy)

	if energy_bar_widget and energy_bar_widget.has_method("update_value"):
		energy_bar_widget.update_value(current, max_energy)
#endregion

#region HUD 创建/销毁
func _create_battle_hud(actor: BattleActor) -> void:
	var hud_scene = UIConfig.get_scene(UIConfig.SceneType.BATTLE_HUD)
	if not hud_scene:
		push_warning("BattleHUD 场景未配置，创建默认 HUD")
		_create_default_hud()
		return

	var hud = hud_scene.instantiate()
	battle_layer.add_child(hud)

	# 获取组件引用
	hp_bar_widget = hud.get_node_or_null("HPBar")
	energy_bar_widget = hud.get_node_or_null("EnergyBar")

	# 初始化数值
	var attr_comp = actor.GetAttributes()
	if attr_comp:
		var hp_attr = attr_comp.find_attribute(AttributeConfig.AttributeName.Hp)
		if hp_attr and hp_bar_widget and hp_bar_widget.has_method("update_value"):
			hp_bar_widget.update_value(hp_attr.computed_value, hp_attr.base_value)

func _create_default_hud() -> void:
	# 创建简单的默认 HP 条
	var hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.position = Vector2(10, 10)
	hp_bar.size = Vector2(100, 20)
	hp_bar.max_value = 100
	hp_bar.value = 100
	battle_layer.add_child(hp_bar)
	hp_bar_widget = hp_bar

func _destroy_battle_hud() -> void:
	for child in battle_layer.get_children():
		child.queue_free()
	hp_bar_widget = null
	energy_bar_widget = null
#endregion