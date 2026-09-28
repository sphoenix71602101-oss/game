extends Control

var sol_label: Label
var phase_label: Label
var objective_label: Label
var objective_code: Label
var oxygen_bar: ProgressBar
var power_bar: ProgressBar
var water_bar: ProgressBar
var oxygen_value: Label
var power_value: Label
var water_value: Label
var prompt_panel: PanelContainer
var prompt_label: Label
var prompt_state: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = false


func refresh_from_state(state: Node) -> void:
	sol_label.text = "SOL %02d" % state.sol
	phase_label.text = str(state.get_phase_name()).to_upper()
	objective_code.text = "TASK / %02d" % (int(state.task_stage) + 1)
	objective_label.text = str(state.objective)
	_set_meter(oxygen_bar, oxygen_value, int(state.resources.get("oxygen", 0)), "%", "氧气")
	_set_meter(power_bar, power_value, int(state.resources.get("power", 0)), "%", "电力")
	_set_meter(water_bar, water_value, int(state.resources.get("water", 0)), " L", "储水")


func show_prompt(title: String, status_text := "可互动") -> void:
	prompt_label.text = "[ E ]   " + title
	prompt_state.text = status_text
	prompt_panel.visible = true


func hide_prompt() -> void:
	prompt_panel.visible = false


func _set_meter(bar: ProgressBar, value_label: Label, value: int, suffix: String, label_text: String) -> void:
	bar.value = value
	value_label.text = "%s  %d%s" % [label_text, value, suffix]
	var color := MarsUI.CYAN
	if value <= 20:
		color = MarsUI.DANGER
	elif value <= 40:
		color = MarsUI.AMBER
	value_label.add_theme_color_override("font_color", color)
	bar.add_theme_stylebox_override("fill", MarsUI.panel(color, color, 2, 0, 1))


func _build() -> void:
	var top_left := PanelContainer.new()
	top_left.position = Vector2(22, 18)
	top_left.size = Vector2(530, 76)
	top_left.add_theme_stylebox_override("panel", MarsUI.panel(Color(0.025, 0.05, 0.065, 0.94), Color(MarsUI.CYAN, 0.42), 3, 1, 13))
	add_child(top_left)
	var task_row := HBoxContainer.new()
	task_row.add_theme_constant_override("separation", 16)
	top_left.add_child(task_row)
	var time_box := VBoxContainer.new()
	time_box.custom_minimum_size.x = 92
	time_box.add_theme_constant_override("separation", -3)
	task_row.add_child(time_box)
	sol_label = Label.new()
	sol_label.theme_type_variation = &"TelemetryLabel"
	sol_label.add_theme_font_size_override("font_size", 20)
	sol_label.add_theme_color_override("font_color", MarsUI.CYAN)
	time_box.add_child(sol_label)
	phase_label = Label.new()
	phase_label.theme_type_variation = &"TelemetryLabel"
	phase_label.add_theme_font_size_override("font_size", 12)
	phase_label.add_theme_color_override("font_color", MarsUI.MUTED)
	time_box.add_child(phase_label)
	var divider := VSeparator.new()
	task_row.add_child(divider)
	var objective_box := VBoxContainer.new()
	objective_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_box.add_theme_constant_override("separation", -1)
	task_row.add_child(objective_box)
	objective_code = Label.new()
	objective_code.theme_type_variation = &"TelemetryLabel"
	objective_code.add_theme_font_size_override("font_size", 11)
	objective_code.add_theme_color_override("font_color", MarsUI.AMBER)
	objective_box.add_child(objective_code)
	objective_label = Label.new()
	objective_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	objective_label.add_theme_font_size_override("font_size", 16)
	objective_box.add_child(objective_label)
	var resources := PanelContainer.new()
	resources.position = Vector2(566, 18)
	resources.size = Vector2(564, 76)
	resources.add_theme_stylebox_override("panel", MarsUI.panel(Color(0.025, 0.05, 0.065, 0.94), Color(MarsUI.CYAN, 0.26), 3, 1, 11))
	add_child(resources)
	var resource_row := HBoxContainer.new()
	resource_row.add_theme_constant_override("separation", 18)
	resources.add_child(resource_row)
	var oxygen := _make_meter("O₂ LOOP", 100)
	oxygen_value = oxygen[0]
	oxygen_bar = oxygen[1]
	resource_row.add_child(oxygen[2])
	var power := _make_meter("PWR BUS", 100)
	power_value = power[0]
	power_bar = power[1]
	resource_row.add_child(power[2])
	var water := _make_meter("H₂O", 10)
	water_value = water[0]
	water_bar = water[1]
	resource_row.add_child(water[2])
	prompt_panel = PanelContainer.new()
	prompt_panel.position = Vector2(354, 548)
	prompt_panel.size = Vector2(444, 70)
	prompt_panel.add_theme_stylebox_override("panel", MarsUI.panel(Color(0.025, 0.05, 0.065, 0.96), MarsUI.CYAN, 3, 2, 10))
	prompt_panel.visible = false
	add_child(prompt_panel)
	var prompt_box := VBoxContainer.new()
	prompt_box.add_theme_constant_override("separation", -2)
	prompt_panel.add_child(prompt_box)
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.theme_type_variation = &"TelemetryLabel"
	prompt_label.add_theme_font_size_override("font_size", 17)
	prompt_label.add_theme_color_override("font_color", MarsUI.TEXT)
	prompt_box.add_child(prompt_label)
	prompt_state = Label.new()
	prompt_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_state.theme_type_variation = &"TelemetryLabel"
	prompt_state.add_theme_font_size_override("font_size", 11)
	prompt_state.add_theme_color_override("font_color", MarsUI.CYAN)
	prompt_box.add_child(prompt_state)
	var controls := Label.new()
	controls.text = "WASD  移动     E  调查     ESC  系统菜单"
	controls.position = Vector2(24, 611)
	controls.size = Vector2(420, 24)
	controls.theme_type_variation = &"TelemetryLabel"
	controls.add_theme_font_size_override("font_size", 12)
	controls.add_theme_color_override("font_color", MarsUI.MUTED)
	add_child(controls)
	var mission_stamp := Label.new()
	mission_stamp.text = "F-47 / LOCAL HABITAT NETWORK"
	mission_stamp.position = Vector2(836, 611)
	mission_stamp.size = Vector2(290, 24)
	mission_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mission_stamp.theme_type_variation = &"TelemetryLabel"
	mission_stamp.add_theme_font_size_override("font_size", 11)
	mission_stamp.add_theme_color_override("font_color", MarsUI.MUTED)
	add_child(mission_stamp)


func _make_meter(code: String, maximum: float) -> Array:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	var code_label := Label.new()
	code_label.text = code
	code_label.theme_type_variation = &"TelemetryLabel"
	code_label.add_theme_font_size_override("font_size", 10)
	code_label.add_theme_color_override("font_color", MarsUI.MUTED)
	box.add_child(code_label)
	var value_label := Label.new()
	value_label.theme_type_variation = &"TelemetryLabel"
	value_label.add_theme_font_size_override("font_size", 14)
	box.add_child(value_label)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = maximum
	bar.custom_minimum_size = Vector2(150, 5)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bar)
	return [value_label, bar, box]
