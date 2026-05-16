class_name SettingsPanel extends UIPanel

var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var back_button: Button

func _ready() -> void:
	super._ready()
	panel_type = PanelType.MENU
	pause_game = false
	close_on_escape = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	master_slider = get_node_or_null("Panel/VBoxContainer/MasterRow/MasterSlider")
	music_slider = get_node_or_null("Panel/VBoxContainer/MusicRow/MusicSlider")
	sfx_slider = get_node_or_null("Panel/VBoxContainer/SfxRow/SfxSlider")
	back_button = get_node_or_null("Panel/VBoxContainer/BackButton")

	_setup_slider(master_slider, "Master")
	_setup_slider(music_slider, "Music")
	_setup_slider(sfx_slider, "SFX")

	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _setup_slider(slider: HSlider, bus_name: String) -> void:
	if not slider:
		return

	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = _get_bus_volume(bus_name)
	slider.value_changed.connect(_on_volume_changed.bind(bus_name))

func _get_bus_volume(bus_name: String) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return 1.0

	var db := AudioServer.get_bus_volume_db(bus_index)
	return db_to_linear(db)

func _on_volume_changed(value: float, bus_name: String) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	var normalized: float = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, normalized <= 0.0)
	if normalized > 0.0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(normalized))

func _on_back_pressed() -> void:
	get_viewport().set_input_as_handled()
	perform_action("back")
