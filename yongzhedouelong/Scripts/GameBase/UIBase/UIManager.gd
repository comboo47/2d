extends CanvasLayer

signal hp_changed(actor: BattleActor, old_value: float, new_value: float, max_value: float)
signal energy_changed(actor: BattleActor, current: float, max: float)
signal screen_opened(screen_id: String)
signal screen_closed(screen_id: String)
signal popup_opened(popup_id: String)
signal popup_closed(popup_id: String)
signal overlay_shown(overlay_id: String)
signal overlay_hidden(overlay_id: String)
signal ui_initialized

signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)

static var instance

const LAYER_BATTLE := 0
const LAYER_SCREEN := 1
const LAYER_POPUP := 2
const LAYER_OVERLAY := 3
const DAMAGE_POOL_SIZE := 20

var _layers: Array[CanvasLayer] = []
var battle_layer: CanvasLayer
var screen_layer: CanvasLayer
var popup_layer: CanvasLayer
var overlay_layer: CanvasLayer

var menu_layer: CanvasLayer

var _screen_stack: Array[String] = []
var _active_screens: Dictionary = {}
var _active_popups: Dictionary = {}
var _popup_stack: Array[String] = []
var _active_overlays: Dictionary = {}
var _active_huds: Dictionary = {}

var _damage_widget_pool: Array[Control] = []
var _bound_actor: BattleActor = null

var hp_bar_widget: Control
var energy_bar_widget: Control

func _init() -> void:
	instance = self

func _ready() -> void:
	_setup_layers()
	_setup_widget_pool()
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_initialized.emit()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if InputManager._is_locked:
		return

	if not _popup_stack.is_empty():
		close_top_popup()
		get_viewport().set_input_as_handled()
		return

	var current_screen: String = get_current_screen_id()
	if current_screen == UIConfig.MENU_PAUSE:
		return

	if GameManager.is_in_game():
		get_viewport().set_input_as_handled()
		GameManager.toggle_pause()

func _setup_layers() -> void:
	for i in range(4):
		var layer := CanvasLayer.new()
		layer.name = "UILayer_%d" % i
		layer.layer = 10 + i * 5
		add_child(layer)
		_layers.append(layer)

	battle_layer = _layers[LAYER_BATTLE]
	screen_layer = _layers[LAYER_SCREEN]
	popup_layer = _layers[LAYER_POPUP]
	overlay_layer = _layers[LAYER_OVERLAY]
	menu_layer = screen_layer

func _setup_widget_pool() -> void:
	var damage_scene := UIConfig.get_scene_by_id(UIConfig.WIDGET_POP_DAMAGE)
	if damage_scene:
		for i in range(DAMAGE_POOL_SIZE):
			var widget := damage_scene.instantiate() as Control
			if not widget:
				continue
			widget.set_process(false)
			overlay_layer.add_child(widget)
			_damage_widget_pool.append(widget)

func get_current_screen_id() -> String:
	if _screen_stack.is_empty():
		return ""
	return _screen_stack[_screen_stack.size() - 1]

func open_screen(screen_id: String, data: Dictionary = {}) -> void:
	_clear_screen_stack()
	_show_screen(screen_id, data)

func push_screen(screen_id: String, data: Dictionary = {}) -> void:
	var current_screen_id: String = get_current_screen_id()
	if current_screen_id == screen_id:
		return

	if current_screen_id != "":
		var current_screen: Control = _active_screens.get(current_screen_id) as Control
		if current_screen:
			if current_screen.has_method("on_blur"):
				current_screen.on_blur()
			current_screen.hide()

	_show_screen(screen_id, data)

func back_screen(fallback: String = UIConfig.MENU_MAIN) -> void:
	var current_screen_id: String = get_current_screen_id()
	if current_screen_id != "":
		_close_screen(current_screen_id)
		_screen_stack.pop_back()

	var target_screen_id: String = fallback
	if not _screen_stack.is_empty():
		target_screen_id = get_current_screen_id()
		var target_screen: Control = _active_screens.get(target_screen_id) as Control
		if target_screen:
			target_screen.show()
			if target_screen.has_method("on_focus"):
				target_screen.on_focus()
			screen_opened.emit(target_screen_id)
			menu_opened.emit(target_screen_id)
			return

	if get_tree().current_scene and get_tree().current_scene.name == target_screen_id:
		return

	_show_screen(target_screen_id, {})

func open_popup(popup_id: String, data: Dictionary = {}) -> Control:
	var popup := _instantiate_window(popup_id)
	if not popup:
		return null

	popup_layer.add_child(popup)
	_active_popups[popup_id] = popup
	_popup_stack.append(popup_id)
	_connect_panel_signals(popup_id, popup, UIConfig.UILayerType.POPUP)
	_call_open(popup, data)
	popup_opened.emit(popup_id)
	return popup

func close_popup(popup_id: String) -> void:
	if not _active_popups.has(popup_id):
		return

	var popup: Control = _active_popups[popup_id] as Control
	_call_close(popup)
	popup.queue_free()
	_active_popups.erase(popup_id)
	_popup_stack.erase(popup_id)
	popup_closed.emit(popup_id)

func close_top_popup() -> void:
	if _popup_stack.is_empty():
		return
	close_popup(_popup_stack[_popup_stack.size() - 1])

func show_overlay(overlay_id: String, data: Dictionary = {}) -> Control:
	if _active_overlays.has(overlay_id):
		var active_overlay: Control = _active_overlays[overlay_id] as Control
		_call_open(active_overlay, data)
		return active_overlay

	var overlay := _instantiate_window(overlay_id)
	if not overlay:
		return null

	overlay_layer.add_child(overlay)
	_active_overlays[overlay_id] = overlay
	_connect_panel_signals(overlay_id, overlay, UIConfig.UILayerType.OVERLAY)
	_call_open(overlay, data)
	overlay_shown.emit(overlay_id)
	return overlay

func hide_overlay(overlay_id: String) -> void:
	if not _active_overlays.has(overlay_id):
		return

	var overlay: Control = _active_overlays[overlay_id] as Control
	_call_close(overlay)
	overlay.queue_free()
	_active_overlays.erase(overlay_id)
	overlay_hidden.emit(overlay_id)

func show_hud(hud_id = UIConfig.HUD_BATTLE, data: Dictionary = {}) -> Control:
	if hud_id is BattleActor:
		var actor: BattleActor = hud_id
		return show_hud_for_actor(actor)

	var id: String = str(hud_id)
	if _active_huds.has(id):
		return _active_huds[id]

	var hud := _instantiate_window(id)
	if not hud:
		return null

	battle_layer.add_child(hud)
	_active_huds[id] = hud
	_connect_panel_signals(id, hud, UIConfig.UILayerType.HUD)
	_call_open(hud, data)
	return hud

func hide_hud(hud_id = UIConfig.HUD_BATTLE) -> void:
	if hud_id is BattleActor:
		if _bound_actor == hud_id:
			unbind_actor(hud_id)
		return

	var id: String = str(hud_id)
	if id == UIConfig.HUD_BATTLE and _bound_actor:
		unbind_actor(_bound_actor)
		return

	if not _active_huds.has(id):
		if id == UIConfig.HUD_BATTLE:
			_destroy_battle_hud()
		return

	var hud: Control = _active_huds[id] as Control
	_call_close(hud)
	hud.queue_free()
	_active_huds.erase(id)

func show_hud_for_actor(actor: BattleActor) -> Control:
	bind_actor(actor)
	return _active_huds.get(UIConfig.HUD_BATTLE) as Control

func show_damage(actor: BattleActor, damage: float, position_offset: Vector2 = Vector2.ZERO) -> void:
	var widget := _get_damage_widget()
	if widget:
		widget.init(actor, abs(damage))
		widget.global_position = actor.global_position + Vector2(0, -12) + position_offset
		widget.global_position += Vector2(randf() * 7.5, randf() * 7.5)
		widget.pop_damage()

func bind_actor(actor: BattleActor) -> void:
	if _bound_actor == actor:
		return

	if _bound_actor:
		unbind_actor(_bound_actor)

	_bound_actor = actor

	var attr_comp = actor.GetAttributes()
	if attr_comp:
		var hp_attr = attr_comp.find_attribute(AttributeConfig.AttributeName.Hp)
		if hp_attr and hp_attr.has_signal("attribute_changed"):
			if not hp_attr.attribute_changed.is_connected(_on_actor_hp_changed):
				hp_attr.attribute_changed.connect(_on_actor_hp_changed)

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

func show_main_menu() -> void:
	hide_loading()
	hide_hud()
	_clear_screen_stack()
	if get_tree().current_scene and get_tree().current_scene.name == UIConfig.MENU_MAIN:
		return
	open_screen(UIConfig.MENU_MAIN)

func show_pause_menu() -> void:
	push_screen(UIConfig.MENU_PAUSE)

func hide_all_menus() -> void:
	hide_all_screens()

func hide_all_screens() -> void:
	_clear_screen_stack()

func open_menu(menu_name: String, remember_current: bool = true) -> void:
	if remember_current:
		push_screen(menu_name)
	else:
		open_screen(menu_name)
	menu_opened.emit(menu_name)

func back_menu(fallback_menu: String = UIConfig.MENU_MAIN) -> void:
	back_screen(fallback_menu)

func close_menu(menu_name: String) -> void:
	if not _active_screens.has(menu_name):
		return
	_close_screen(menu_name)
	_screen_stack.erase(menu_name)

func show_loading(title: String = "Loading", hint: String = "") -> void:
	var data := {
		"title": title,
		"hint": hint,
	}
	var loading := show_overlay(UIConfig.OVERLAY_LOADING, data)
	if loading and loading.has_method("set_loading_text"):
		loading.set_loading_text(title, hint)

func set_loading_progress(value: float) -> void:
	var loading := _active_overlays.get(UIConfig.OVERLAY_LOADING) as Control
	if loading and loading.has_method("set_progress"):
		loading.set_progress(value)

func hide_loading() -> void:
	hide_overlay(UIConfig.OVERLAY_LOADING)

func _show_screen(screen_id: String, data: Dictionary = {}) -> Control:
	var screen: Control = _active_screens.get(screen_id) as Control
	if not screen:
		screen = _instantiate_window(screen_id)
		if not screen:
			return null
		screen_layer.add_child(screen)
		_active_screens[screen_id] = screen
		_connect_panel_signals(screen_id, screen, UIConfig.UILayerType.SCREEN)

	if not _screen_stack.has(screen_id):
		_screen_stack.append(screen_id)

	screen.show()
	_call_open(screen, data)
	screen_opened.emit(screen_id)
	menu_opened.emit(screen_id)
	return screen

func _close_screen(screen_id: String) -> void:
	if not _active_screens.has(screen_id):
		return

	var screen: Control = _active_screens[screen_id] as Control
	_call_close(screen)
	screen.queue_free()
	_active_screens.erase(screen_id)
	screen_closed.emit(screen_id)
	menu_closed.emit(screen_id)

func _clear_screen_stack() -> void:
	for screen_id in _screen_stack.duplicate():
		_close_screen(screen_id)
	_screen_stack.clear()

func _instantiate_window(id: String) -> Control:
	var scene := UIConfig.get_scene_by_id(id)
	if not scene:
		return null

	var window_node := scene.instantiate()
	if not window_node is Control:
		push_error("UIManager: UI scene root must be Control: %s" % id)
		window_node.queue_free()
		return null

	var window := window_node as Control
	window.name = id
	return window

func _connect_panel_signals(id: String, panel: Control, layer_type: int) -> void:
	if panel.has_signal("request_close"):
		panel.request_close.connect(_on_panel_request_close.bind(id, layer_type))
	if panel.has_signal("panel_action"):
		panel.panel_action.connect(_on_panel_action.bind(id, layer_type))

func _call_open(panel: Control, data: Dictionary) -> void:
	if panel.has_method("open"):
		panel.open(data)
	else:
		panel.show()

func _call_close(panel: Control) -> void:
	if panel.has_method("close"):
		panel.close()
	else:
		panel.hide()

func _on_panel_request_close(id: String, layer_type: int) -> void:
	match layer_type:
		UIConfig.UILayerType.SCREEN:
			if id == UIConfig.MENU_PAUSE and GameManager.is_paused():
				InputManager.lock_inputs(0.15)
				GameManager.change_state(GameManager.GameState.PLAYING)
				GameManager.game_resumed.emit()
				return
			back_screen()
		UIConfig.UILayerType.POPUP:
			close_popup(id)
		UIConfig.UILayerType.OVERLAY:
			hide_overlay(id)
		UIConfig.UILayerType.HUD:
			hide_hud(id)
		_:
			pass

func handle_panel_action(action_name: String, payload: Dictionary = {}, source_id: String = "", layer_type = UIConfig.UILayerType.SCREEN) -> void:
	_handle_panel_action(action_name, payload, source_id, int(layer_type))

func _on_panel_action(action_name: String, payload: Dictionary, id: String, layer_type: int) -> void:
	_handle_panel_action(action_name, payload, id, int(layer_type))

func _handle_panel_action(action_name: String, payload: Dictionary, id: String, layer_type: int) -> void:
	match action_name:
		"open_level_select":
			push_screen(UIConfig.MENU_LEVEL_SELECT)
		"open_settings":
			push_screen(UIConfig.MENU_SETTINGS)
		"back":
			back_screen(UIConfig.MENU_MAIN)
		"start_game":
			var scene_path: String = str(payload.get("scene_path", GameManager.DEFAULT_GAME_SCENE))
			GameManager.start_game(scene_path)
		"resume_game":
			InputManager.lock_inputs(float(payload.get("lock_duration", 0.3)))
			GameManager.change_state(GameManager.GameState.PLAYING)
			GameManager.game_resumed.emit()
		"return_to_main_menu":
			GameManager.return_to_main_menu()
		"quit_game":
			GameManager.quit_game()
		_:
			pass

func _get_damage_widget() -> Control:
	for widget in _damage_widget_pool:
		if widget.has_method("is_active") and not widget.is_active():
			return widget

	var damage_scene := UIConfig.get_scene_by_id(UIConfig.WIDGET_POP_DAMAGE)
	if damage_scene:
		var new_widget := damage_scene.instantiate() as Control
		if not new_widget:
			return null
		overlay_layer.add_child(new_widget)
		_damage_widget_pool.append(new_widget)
		return new_widget
	return null

func _return_damage_widget(widget: Control) -> void:
	if widget.has_method("reset"):
		widget.reset()
	widget.set_process(false)

func _bind_weapon_energy(weapon: Node) -> void:
	if weapon.has_signal("energy_changed"):
		if not weapon.energy_changed.is_connected(_on_weapon_energy_changed):
			weapon.energy_changed.connect(_on_weapon_energy_changed)

func _on_actor_hp_changed(attr: Attribute, old_value: float, new_value: float) -> void:
	var max_hp = attr.base_value
	hp_changed.emit(_bound_actor, old_value, new_value, max_hp)

	if hp_bar_widget and hp_bar_widget.has_method("update_value"):
		hp_bar_widget.update_value(new_value, max_hp)

	if new_value < old_value:
		show_damage(_bound_actor, old_value - new_value)

func _on_weapon_energy_changed(current: float, max_energy: float) -> void:
	energy_changed.emit(_bound_actor, current, max_energy)

	if energy_bar_widget and energy_bar_widget.has_method("update_value"):
		energy_bar_widget.update_value(current, max_energy)

func _create_battle_hud(actor: BattleActor) -> void:
	_destroy_battle_hud()

	var hud := show_hud(UIConfig.HUD_BATTLE, {"actor": actor})
	if not hud:
		push_warning("BattleHUD scene missing. Creating fallback HUD.")
		_create_default_hud()
		return

	hp_bar_widget = hud.get_node_or_null("HPBar")
	energy_bar_widget = hud.get_node_or_null("EnergyBar")

	var attr_comp = actor.GetAttributes()
	if attr_comp:
		var hp_attr = attr_comp.find_attribute(AttributeConfig.AttributeName.Hp)
		if hp_attr and hp_bar_widget and hp_bar_widget.has_method("update_value"):
			hp_bar_widget.update_value(hp_attr.computed_value, hp_attr.base_value)

func _create_default_hud() -> void:
	var hp_bar := ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.position = Vector2(10, 10)
	hp_bar.size = Vector2(100, 20)
	hp_bar.max_value = 100
	hp_bar.value = 100
	battle_layer.add_child(hp_bar)
	hp_bar_widget = hp_bar

func _destroy_battle_hud() -> void:
	if _active_huds.has(UIConfig.HUD_BATTLE):
		var hud: Control = _active_huds[UIConfig.HUD_BATTLE] as Control
		_call_close(hud)
		hud.queue_free()
		_active_huds.erase(UIConfig.HUD_BATTLE)

	for child in battle_layer.get_children():
		if child.name != UIConfig.HUD_BATTLE:
			child.queue_free()

	hp_bar_widget = null
	energy_bar_widget = null
