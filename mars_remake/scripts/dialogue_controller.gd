extends Control

signal finished
signal flag_requested(key: String, value: Variant)

class SignalPortrait:
	extends Control
	var code := "LOG"
	var accent := MarsUI.CYAN
	var pulse := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func set_profile(new_code: String, new_accent: Color) -> void:
		code = new_code
		accent = new_accent
		queue_redraw()

	func _process(delta: float) -> void:
		pulse = fmod(pulse + delta, TAU)
		queue_redraw()

	func _draw() -> void:
		var center := size * Vector2(0.5, 0.46)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.035, 0.045, 0.92), true)
		for y in range(10, int(size.y), 16):
			draw_line(Vector2(10, y), Vector2(size.x - 10, y), Color(accent, 0.045), 1.0)
		draw_arc(center, 62.0, 0, TAU, 64, Color(accent, 0.22), 1.0)
		draw_arc(center, 47.0, -PI * 0.25, PI * (0.85 + sin(pulse) * 0.03), 42, Color(accent, 0.76), 2.0)
		draw_circle(center + Vector2(0, -20), 17, Color(accent, 0.16))
		draw_arc(center + Vector2(0, -20), 17, 0, TAU, 32, Color(accent, 0.58), 2.0)
		draw_arc(center + Vector2(0, 37), 36, PI, TAU, 32, Color(accent, 0.58), 2.0)
		draw_line(Vector2(center.x - 82, center.y), Vector2(center.x - 54, center.y), Color(accent, 0.45), 1.0)
		draw_line(Vector2(center.x + 54, center.y), Vector2(center.x + 82, center.y), Color(accent, 0.45), 1.0)
		var font := MarsUI.data_font()
		draw_string(font, Vector2(16, size.y - 18), code, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, accent)


var overlay: Control
var panel: PanelContainer
var portrait: SignalPortrait
var channel_label: Label
var speaker_label: Label
var dialogue_label: Label
var progress_label: Label
var hint_label: Label
var choices_box: VBoxContainer
var lines: Array = []
var line_index := 0
var id_map := {}
var player_name := "航天员"
var current_text := ""
var revealed := 0.0
var typing := false
var choice_active := false
var step_count := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false
	set_process(true)


func start_dialogue(source_lines: Array, new_player_name: String) -> void:
	player_name = new_player_name
	lines = _paginate(source_lines)
	line_index = 0
	id_map.clear()
	step_count = 0
	for index in range(lines.size()):
		var entry = lines[index]
		if entry is Dictionary and entry.has("id"):
			id_map[str(entry["id"])] = index
	visible = true
	_show_line()


func advance() -> void:
	if not visible:
		return
	if typing:
		revealed = current_text.length()
		dialogue_label.visible_characters = -1
		typing = false
		_show_choices_if_needed()
		return
	if choice_active:
		return
	_go_next()


func is_choice_active() -> bool:
	return choice_active


func _process(delta: float) -> void:
	if not visible or not typing:
		return
	revealed += delta * 34.0
	dialogue_label.visible_characters = int(revealed)
	if revealed >= current_text.length():
		dialogue_label.visible_characters = -1
		typing = false
		_show_choices_if_needed()


func _show_line() -> void:
	step_count += 1
	if step_count > 1000:
		_show_data_error("对白跳转次数超过安全限制")
		return
	if line_index < 0 or line_index >= lines.size():
		_end_dialogue()
		return
	_clear_choices()
	var line = lines[line_index]
	if not line is Dictionary:
		_show_data_error("对白条目不是对象")
		return
	_apply_flags(line.get("set_flags", {}))
	var speaker := str(line.get("speaker", "旁白"))
	if speaker == "PLAYER":
		speaker = player_name
	current_text = str(line.get("text", "")).replace("PLAYER", player_name)
	if current_text.strip_edges().is_empty():
		current_text = "[对白数据缺失：空文本]"
	var presentation := str(line.get("presentation", "character"))
	var effect := str(line.get("effect", ""))
	_apply_presentation(speaker, presentation, effect)
	speaker_label.text = speaker
	dialogue_label.text = current_text
	dialogue_label.visible_characters = 0
	revealed = 0.0
	typing = true
	progress_label.text = "%03d / %03d" % [line_index + 1, lines.size()]
	hint_label.text = "SPACE / ENTER / LEFT CLICK   显示全文" if typing else "SPACE / ENTER / LEFT CLICK   继续"


func _go_next() -> void:
	var line: Dictionary = lines[line_index]
	var next_value = line.get("next", null)
	if next_value == null:
		line_index += 1
	elif next_value is float or next_value is int:
		line_index = int(next_value)
	else:
		var target := str(next_value)
		if target == "END":
			_end_dialogue()
			return
		if not id_map.has(target):
			_show_data_error("找不到对白跳转目标：" + target)
			return
		line_index = int(id_map[target])
	_show_line()


func _show_choices_if_needed() -> void:
	if line_index < 0 or line_index >= lines.size():
		return
	var line: Dictionary = lines[line_index]
	var choices = line.get("choices", [])
	if not choices is Array or choices.is_empty():
		hint_label.text = "SPACE / ENTER / LEFT CLICK   继续"
		return
	choice_active = true
	dialogue_label.custom_minimum_size.y = 62
	hint_label.text = "选择回应 / 主线结果不会改变"
	for index in range(choices.size()):
		var choice = choices[index]
		if not choice is Dictionary:
			continue
		var button := Button.new()
		button.text = "%02d   %s" % [index + 1, str(choice.get("text", "未命名回应"))]
		button.custom_minimum_size.y = 44
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select_choice.bind(choice))
		choices_box.add_child(button)
	if choices_box.get_child_count() > 0:
		(choices_box.get_child(0) as Button).grab_focus()


func _select_choice(choice: Dictionary) -> void:
	_apply_flags(choice.get("set_flags", {}))
	choice_active = false
	var target = choice.get("next", null)
	if target == null:
		line_index += 1
	else:
		var target_id := str(target)
		if target_id == "END":
			_end_dialogue()
			return
		if not id_map.has(target_id):
			_show_data_error("找不到选项跳转目标：" + target_id)
			return
		line_index = int(id_map[target_id])
	_show_line()


func _apply_flags(value: Variant) -> void:
	if not value is Dictionary:
		return
	for key in value.keys():
		flag_requested.emit(str(key), value[key])


func _apply_presentation(speaker: String, presentation: String, effect: String) -> void:
	var accent := MarsUI.CYAN
	var code := "LOG"
	channel_label.text = "MISSION TRANSCRIPT"
	if speaker == "米多莉·希娜":
		accent = Color("e5a6a0")
		code = "HN / GEO"
		channel_label.text = "CREW CHANNEL / GEOLOGY"
	elif speaker == player_name:
		accent = MarsUI.AMBER
		code = "01 / ENG"
		channel_label.text = "CREW CHANNEL / LIFE SUPPORT"
	elif speaker == "系统" or presentation == "system":
		accent = MarsUI.CYAN
		code = "F-47 / SYS"
		channel_label.text = "F-47 SYSTEM MESSAGE"
	elif speaker == "旁白" or presentation == "narration":
		accent = MarsUI.MUTED
		code = "REC / LOG"
		channel_label.text = "MISSION RECORD"
	if presentation == "alert" or effect == "alert":
		accent = MarsUI.DANGER
		channel_label.text = "PRIORITY ALERT / RECORDED"
	panel.add_theme_stylebox_override("panel", MarsUI.panel(Color(0.02, 0.045, 0.06, 0.98), Color(accent, 0.78), 3, 2, 18))
	portrait.set_profile(code, accent)
	speaker_label.add_theme_color_override("font_color", accent)
	channel_label.add_theme_color_override("font_color", accent)


func _show_data_error(message: String) -> void:
	lines = [{"speaker": "系统", "text": "[对白数据错误] " + message, "presentation": "alert"}]
	line_index = 0
	id_map.clear()
	step_count = 0
	_show_line()


func _end_dialogue() -> void:
	visible = false
	typing = false
	choice_active = false
	_clear_choices()
	finished.emit()


func _clear_choices() -> void:
	choice_active = false
	dialogue_label.custom_minimum_size.y = 98
	for child in choices_box.get_children():
		child.queue_free()


func _paginate(source: Array) -> Array:
	var result: Array = []
	for raw in source:
		if not raw is Dictionary:
			result.append(raw)
			continue
		var entry: Dictionary = raw.duplicate(true)
		var text := str(entry.get("text", ""))
		if text.length() <= 96:
			result.append(entry)
			continue
		var chunks: Array[String] = []
		var remaining := text
		while remaining.length() > 96:
			var cut := 96
			for marker in ["。", "！", "？", "；", "……"]:
				var found := remaining.rfind(marker, 78)
				if found >= 52:
					cut = maxi(cut if cut < 96 else 0, found + marker.length())
			if cut <= 0 or cut > 96:
				cut = 96
			chunks.append(remaining.left(cut))
			remaining = remaining.substr(cut)
		chunks.append(remaining)
		for chunk_index in range(chunks.size()):
			var page: Dictionary = entry.duplicate(true)
			page["text"] = chunks[chunk_index]
			if chunk_index < chunks.size() - 1:
				page.erase("choices")
				page.erase("next")
				page.erase("set_flags")
				if chunk_index > 0:
					page.erase("id")
			elif chunk_index > 0:
				page.erase("id")
			result.append(page)
	return result


func _build() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.01, 0.015, 0.34)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	panel = PanelContainer.new()
	panel.position = Vector2(28, 322)
	panel.size = Vector2(1096, 294)
	overlay.add_child(panel)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	panel.add_child(layout)
	portrait = SignalPortrait.new()
	portrait.custom_minimum_size = Vector2(190, 248)
	layout.add_child(portrait)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 7)
	layout.add_child(body)
	var meta := HBoxContainer.new()
	body.add_child(meta)
	channel_label = Label.new()
	channel_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	channel_label.theme_type_variation = &"TelemetryLabel"
	channel_label.add_theme_font_size_override("font_size", 11)
	meta.add_child(channel_label)
	progress_label = Label.new()
	progress_label.theme_type_variation = &"TelemetryLabel"
	progress_label.add_theme_font_size_override("font_size", 11)
	progress_label.add_theme_color_override("font_color", MarsUI.MUTED)
	meta.add_child(progress_label)
	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 22)
	body.add_child(speaker_label)
	dialogue_label = Label.new()
	dialogue_label.custom_minimum_size.y = 98
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 20)
	body.add_child(dialogue_label)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 7)
	body.add_child(choices_box)
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.theme_type_variation = &"TelemetryLabel"
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", MarsUI.MUTED)
	body.add_child(hint_label)
