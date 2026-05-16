class_name LoadingPanel extends UIPanel

var title_label: Label
var hint_label: Label
var progress_bar: ProgressBar

func _ready() -> void:
	super._ready()
	panel_type = PanelType.POPUP
	close_on_escape = false
	pause_game = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	title_label = get_node_or_null("Panel/VBoxContainer/Title")
	hint_label = get_node_or_null("Panel/VBoxContainer/Hint")
	progress_bar = get_node_or_null("Panel/VBoxContainer/ProgressBar")
	set_progress(0.0)

func open(data: Dictionary = {}) -> void:
	super.open(data)
	set_loading_text(str(data.get("title", "Loading")), str(data.get("hint", "")))
	set_progress(float(data.get("progress", 0.0)))

func set_loading_text(title: String, hint: String = "") -> void:
	if title_label:
		title_label.text = title
	if hint_label:
		hint_label.text = hint

func set_progress(value: float) -> void:
	if progress_bar:
		progress_bar.value = clampf(value, 0.0, 1.0) * 100.0
