extends Control

signal start_requested
signal continue_requested
signal name_confirmed(value: String)
signal resume_requested
signal save_requested
signal title_requested

class TitleBackdrop:
	extends Control
	var sweep := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		sweep = fmod(sweep + delta * 0.055, 1.0)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), MarsUI.VOID, true)
		for y in range(0, int(size.y), 32):
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.32, 0.52, 0.55, 0.045), 1.0)
		for x in range(0, int(size.x), 64):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.32, 0.52, 0.55, 0.035), 1.0)
		var center := Vector2(size.x * 0.84, size.y * 0.92)
		for radius in range(430, 300, -10):
			var depth := float(430 - radius) / 130.0
			var color := MarsUI.MARS_DARK.lerp(MarsUI.MARS, depth * 0.55)
			draw_circle(center, float(radius), Color(color, 0.95))
		for i in range(13):
			var radius := 315.0 + i * 9.0
			draw_arc(center, radius, PI * 1.08, PI * 1.88, 70, Color(0.98, 0.58, 0.35, 0.10), 1.0)
		var terrain := PackedVector2Array([
			Vector2(size.x * 0.58, size.y * 0.72), Vector2(size.x * 0.63, size.y * 0.68),
			Vector2(size.x * 0.69, size.y * 0.70), Vector2(size.x * 0.74, size.y * 0.63),
			Vector2(size.x * 0.79, size.y * 0.66), Vector2(size.x * 0.85, size.y * 0.57),
			Vector2(size.x * 0.90, size.y * 0.60), Vector2(size.x * 0.96, size.y * 0.50),
			Vector2(size.x, size.y * 0.53),
		])
		draw_polyline(terrain, Color(MarsUI.AMBER, 0.48), 2.0)
		var scan_y := size.y * (0.19 + sweep * 0.62)
		draw_line(Vector2(size.x * 0.55, scan_y), Vector2(size.x, scan_y), Color(MarsUI.CYAN, 0.24), 2.0)
		draw_arc(Vector2(size.x * 0.82, size.y * 0.37), 86.0, 0, TAU, 64, Color(MarsUI.CYAN, 0.22), 1.0)
		draw_arc(Vector2(size.x * 0.82, size.y * 0.37), 64.0, -PI * 0.25, PI * 0.58, 32, Color(MarsUI.CYAN, 0.62), 2.0)
		draw_line(Vector2(size.x * 0.82 - 104, size.y * 0.37), Vector2(size.x * 0.82 + 104, size.y * 0.37), Color(MarsUI.CYAN, 0.16), 1.0)
		draw_line(Vector2(size.x * 0.82, size.y * 0.37 - 104), Vector2(size.x * 0.82, size.y * 0.37 + 104), Color(MarsUI.CYAN, 0.16), 1.0)


var title_screen: Control
var name_screen: Control
var pause_screen: Control
var continue_button: Button
var continue_note: Label
var name_input: LineEdit
var name_error: Label
var pause_status: Label
var start_button: Button
var resume_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_title()
	_build_name()
	_build_pause()
	hide_all()


func hide_all() -> void:
	title_screen.visible = false
	name_screen.visible = false
	pause_screen.visible = false


func show_title(can_continue: bool, legacy_save_exists: bool) -> void:
	hide_all()
	visible = true
	title_screen.visible = true
	continue_button.disabled = not can_continue
	if can_continue:
		continue_note.text = "检测到 F-47 任务检查点"
		continue_note.add_theme_color_override("font_color", MarsUI.SUCCESS)
	elif legacy_save_exists:
		continue_note.text = "旧试玩存档与新版舱体不兼容 · 原文件已保留"
		continue_note.add_theme_color_override("font_color", MarsUI.AMBER)
	else:
		continue_note.text = "未检测到新版任务检查点"
		continue_note.add_theme_color_override("font_color", MarsUI.MUTED)
	start_button.grab_focus()


func show_name() -> void:
	hide_all()
	visible = true
	name_screen.visible = true
	name_input.text = ""
	name_error.text = " "
	name_input.grab_focus()


func show_pause() -> void:
	pause_status.text = " "
	pause_screen.visible = true
	visible = true
	resume_button.grab_focus()


func hide_pause() -> void:
	pause_screen.visible = false


func set_name_error(message: String) -> void:
	name_error.text = message
	name_input.grab_focus()


func set_pause_status(message: String, success := true) -> void:
	pause_status.text = message
	pause_status.add_theme_color_override("font_color", MarsUI.SUCCESS if success else MarsUI.DANGER)


func _build_title() -> void:
	title_screen = Control.new()
	title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(title_screen)
	var backdrop := TitleBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(backdrop)
	var top_rule := ColorRect.new()
	top_rule.color = MarsUI.MARS
	top_rule.position = Vector2(0, 0)
	top_rule.size = Vector2(1152, 5)
	title_screen.add_child(top_rule)
	var mission := Label.new()
	mission.text = "F-47 // ELYSIUM PLANITIA // CREWED ADVANCE MISSION"
	mission.position = Vector2(54, 28)
	mission.size = Vector2(720, 30)
	mission.theme_type_variation = &"TelemetryLabel"
	mission.add_theme_font_size_override("font_size", 15)
	mission.add_theme_color_override("font_color", MarsUI.CYAN)
	title_screen.add_child(mission)
	var status := Label.new()
	status.text = "DESCENT WINDOW  04:17:26  ·  LINK DELAY  04m 08s"
	status.position = Vector2(750, 28)
	status.size = Vector2(350, 30)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.theme_type_variation = &"TelemetryLabel"
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", MarsUI.MUTED)
	title_screen.add_child(status)
	var left := VBoxContainer.new()
	left.position = Vector2(64, 112)
	left.size = Vector2(450, 470)
	left.add_theme_constant_override("separation", 10)
	title_screen.add_child(left)
	var marker := Label.new()
	marker.text = "MISSION ARCHIVE / 6202"
	marker.theme_type_variation = &"TelemetryLabel"
	marker.add_theme_font_size_override("font_size", 14)
	marker.add_theme_color_override("font_color", MarsUI.AMBER)
	left.add_child(marker)
	var title := Label.new()
	title.text = "MARS"
	title.theme_type_variation = &"TelemetryLabel"
	title.add_theme_font_size_override("font_size", 92)
	title.add_theme_color_override("font_color", MarsUI.TEXT)
	left.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "把彼此写进未来"
	subtitle.add_theme_font_size_override("font_size", 23)
	subtitle.add_theme_color_override("font_color", MarsUI.MUTED)
	left.add_child(subtitle)
	var divider := ColorRect.new()
	divider.color = MarsUI.STEEL
	divider.custom_minimum_size = Vector2(430, 1)
	left.add_child(divider)
	var logline := Label.new()
	logline.text = "两名先遣成员。一艘受损登陆器。\n距离下一次支援窗口：60 个火星日。"
	logline.custom_minimum_size.y = 66
	logline.add_theme_font_size_override("font_size", 16)
	logline.add_theme_color_override("font_color", MarsUI.MUTED)
	left.add_child(logline)
	start_button = Button.new()
	start_button.text = "开始任务   /   NEW MISSION"
	start_button.custom_minimum_size = Vector2(430, 54)
	start_button.pressed.connect(func(): start_requested.emit())
	left.add_child(start_button)
	continue_button = Button.new()
	continue_button.text = "继续检查点   /   RESUME"
	continue_button.custom_minimum_size = Vector2(430, 54)
	continue_button.pressed.connect(func(): continue_requested.emit())
	left.add_child(continue_button)
	continue_note = Label.new()
	continue_note.custom_minimum_size = Vector2(430, 26)
	continue_note.add_theme_font_size_override("font_size", 13)
	left.add_child(continue_note)
	var quit := Button.new()
	quit.text = "退出   /   EXIT"
	quit.custom_minimum_size = Vector2(430, 48)
	quit.pressed.connect(func(): get_tree().quit())
	left.add_child(quit)
	var telemetry := PanelContainer.new()
	telemetry.position = Vector2(768, 132)
	telemetry.size = Vector2(316, 218)
	telemetry.add_theme_stylebox_override("panel", MarsUI.panel(Color(0.03, 0.06, 0.08, 0.78), Color(MarsUI.CYAN, 0.28), 2, 1, 18))
	title_screen.add_child(telemetry)
	var readout := Label.new()
	readout.text = "LANDING VECTOR\n37.2° N   148.8° E\n\nALTITUDE       18,420 m\nSURFACE TEMP     −67 °C\nWIND             18.7 m/s\nHABITAT LINK      STANDBY"
	readout.theme_type_variation = &"TelemetryLabel"
	readout.add_theme_font_size_override("font_size", 15)
	readout.add_theme_color_override("font_color", MarsUI.CYAN)
	telemetry.add_child(readout)


func _build_name() -> void:
	name_screen = ColorRect.new()
	name_screen.color = MarsUI.SPACE
	name_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(name_screen)
	var mars_band := ColorRect.new()
	mars_band.color = MarsUI.MARS_DARK
	mars_band.position = Vector2(0, 470)
	mars_band.size = Vector2(1152, 178)
	name_screen.add_child(mars_band)
	var manifest := PanelContainer.new()
	manifest.position = Vector2(112, 106)
	manifest.size = Vector2(928, 432)
	manifest.add_theme_stylebox_override("panel", MarsUI.panel(Color(0.035, 0.065, 0.08, 0.98), MarsUI.STEEL, 3, 1, 28))
	name_screen.add_child(manifest)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 34)
	manifest.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 270
	left.add_theme_constant_override("separation", 13)
	row.add_child(left)
	var id_title := Label.new()
	id_title.text = "CREW\nMANIFEST"
	id_title.theme_type_variation = &"TelemetryLabel"
	id_title.add_theme_font_size_override("font_size", 32)
	id_title.add_theme_color_override("font_color", MarsUI.CYAN)
	left.add_child(id_title)
	var id_copy := Label.new()
	id_copy.text = "F-47 / CREW 01\n\n职责\n导航 · 生命保障 · 维修\n\n权限\n任务关键系统 / LEVEL 4"
	id_copy.theme_type_variation = &"TelemetryLabel"
	id_copy.add_theme_font_size_override("font_size", 14)
	id_copy.add_theme_color_override("font_color", MarsUI.MUTED)
	left.add_child(id_copy)
	var divider := VSeparator.new()
	row.add_child(divider)
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 15)
	row.add_child(form)
	var eyebrow := Label.new()
	eyebrow.text = "身份登记 / IDENTITY CONFIRMATION"
	eyebrow.theme_type_variation = &"TelemetryLabel"
	eyebrow.add_theme_font_size_override("font_size", 14)
	eyebrow.add_theme_color_override("font_color", MarsUI.AMBER)
	form.add_child(eyebrow)
	var heading := Label.new()
	heading.text = "登记任务成员"
	heading.add_theme_font_size_override("font_size", 31)
	form.add_child(heading)
	var copy := Label.new()
	copy.text = "请输入主角姓名。姓名只改变游戏中的称呼，不改变固定职业、经历或人物性格。"
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_color_override("font_color", MarsUI.MUTED)
	form.add_child(copy)
	var input_label := Label.new()
	input_label.text = "姓名 / CALLSIGN"
	input_label.theme_type_variation = &"TelemetryLabel"
	input_label.add_theme_font_size_override("font_size", 14)
	input_label.add_theme_color_override("font_color", MarsUI.CYAN)
	form.add_child(input_label)
	name_input = LineEdit.new()
	name_input.placeholder_text = "1–9 个字符"
	name_input.max_length = 9
	name_input.custom_minimum_size.y = 54
	name_input.text_submitted.connect(func(_value): _emit_name())
	form.add_child(name_input)
	name_error = Label.new()
	name_error.text = " "
	name_error.custom_minimum_size.y = 24
	name_error.add_theme_color_override("font_color", MarsUI.DANGER)
	name_error.add_theme_font_size_override("font_size", 14)
	form.add_child(name_error)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	form.add_child(buttons)
	var back := Button.new()
	back.text = "返回"
	back.custom_minimum_size = Vector2(140, 50)
	back.pressed.connect(func(): title_requested.emit())
	buttons.add_child(back)
	var confirm := Button.new()
	confirm.text = "确认并进入下降段"
	confirm.custom_minimum_size = Vector2(260, 50)
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.pressed.connect(_emit_name)
	buttons.add_child(confirm)


func _build_pause() -> void:
	pause_screen = ColorRect.new()
	pause_screen.color = Color(0.01, 0.02, 0.025, 0.86)
	pause_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(pause_screen)
	var panel := PanelContainer.new()
	panel.position = Vector2(650, 72)
	panel.size = Vector2(422, 504)
	panel.add_theme_stylebox_override("panel", MarsUI.panel(Color("0d171d"), MarsUI.STEEL, 3, 2, 26))
	pause_screen.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var eyebrow := Label.new()
	eyebrow.text = "F-47 LOCAL SYSTEM"
	eyebrow.theme_type_variation = &"TelemetryLabel"
	eyebrow.add_theme_font_size_override("font_size", 14)
	eyebrow.add_theme_color_override("font_color", MarsUI.CYAN)
	box.add_child(eyebrow)
	var heading := Label.new()
	heading.text = "任务暂停"
	heading.add_theme_font_size_override("font_size", 34)
	box.add_child(heading)
	var copy := Label.new()
	copy.text = "本地任务时钟已冻结\n生命保障模拟保持当前状态"
	copy.add_theme_color_override("font_color", MarsUI.MUTED)
	copy.add_theme_font_size_override("font_size", 15)
	box.add_child(copy)
	var line := HSeparator.new()
	box.add_child(line)
	resume_button = Button.new()
	resume_button.text = "返回任务"
	resume_button.custom_minimum_size.y = 54
	resume_button.pressed.connect(func(): resume_requested.emit())
	box.add_child(resume_button)
	var save := Button.new()
	save.text = "写入本地检查点"
	save.custom_minimum_size.y = 54
	save.pressed.connect(func(): save_requested.emit())
	box.add_child(save)
	var title := Button.new()
	title.text = "返回主菜单"
	title.custom_minimum_size.y = 54
	title.pressed.connect(func(): title_requested.emit())
	box.add_child(title)
	pause_status = Label.new()
	pause_status.text = " "
	pause_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_status.add_theme_font_size_override("font_size", 14)
	box.add_child(pause_status)


func _emit_name() -> void:
	name_confirmed.emit(name_input.text.strip_edges())
