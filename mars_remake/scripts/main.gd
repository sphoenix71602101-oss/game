extends Node

enum Mode { TITLE, NAME_INPUT, DIALOGUE, PLAYING, PAUSED }

@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $World/Player
@onready var music: AudioStreamPlayer = $Music
@onready var ui_layer: CanvasLayer = $UI
@onready var menu: Control = $UI/Menu
@onready var hud: Control = $UI/HUD
@onready var dialogue: Control = $UI/Dialogue

var mode := Mode.TITLE
var current_interaction := {}
var content: Dictionary = {}
var dialogue_finished_callback := Callable()


func _ready() -> void:
	_setup_input_actions()
	var shared_theme := MarsUI.make_theme()
	menu.theme = shared_theme
	hud.theme = shared_theme
	dialogue.theme = shared_theme
	_load_content()
	menu.start_requested.connect(_show_name_input)
	menu.continue_requested.connect(_continue_game)
	menu.name_confirmed.connect(_confirm_name)
	menu.resume_requested.connect(_resume_game)
	menu.save_requested.connect(_save_current_game)
	menu.title_requested.connect(_show_title)
	dialogue.finished.connect(_on_dialogue_finished)
	dialogue.flag_requested.connect(_on_dialogue_flag_requested)
	GameState.state_changed.connect(_refresh_hud)
	_show_title()


func _process(_delta: float) -> void:
	if mode != Mode.PLAYING:
		hud.hide_prompt()
		return
	current_interaction = world.nearest_interaction(player.position)
	if current_interaction.is_empty():
		hud.hide_prompt()
	else:
		var id := str(current_interaction.get("id", ""))
		hud.show_prompt(str(current_interaction.get("title", "调查")), world.interaction_status(id))


func _unhandled_input(event: InputEvent) -> void:
	if mode == Mode.DIALOGUE:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
			dialogue.advance()
			get_viewport().set_input_as_handled()
	elif mode == Mode.PLAYING:
		if event.is_action_pressed("interact") and not current_interaction.is_empty():
			_handle_interaction(str(current_interaction.get("id", "")))
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			_show_pause()
			get_viewport().set_input_as_handled()
	elif mode == Mode.PAUSED and event.is_action_pressed("ui_cancel"):
		_resume_game()
		get_viewport().set_input_as_handled()
	elif mode == Mode.NAME_INPUT and event.is_action_pressed("ui_cancel"):
		_show_title()
		get_viewport().set_input_as_handled()


func _setup_input_actions() -> void:
	_bind_key("move_left", KEY_A)
	_bind_key("move_left", KEY_LEFT)
	_bind_key("move_right", KEY_D)
	_bind_key("move_right", KEY_RIGHT)
	_bind_key("move_up", KEY_W)
	_bind_key("move_up", KEY_UP)
	_bind_key("move_down", KEY_S)
	_bind_key("move_down", KEY_DOWN)
	_bind_key("interact", KEY_E)


func _bind_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey and existing.physical_keycode == keycode:
			return
	var input_event := InputEventKey.new()
	input_event.physical_keycode = keycode
	InputMap.action_add_event(action, input_event)


func _load_content() -> void:
	var parsed = _load_json("res://data/dialogue/interactions.json")
	content = parsed if parsed is Dictionary else {}


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())


func get_dialogue(key: String) -> Array:
	var value = content.get(key, null)
	if value is Array:
		return value
	return [{"speaker": "系统", "presentation": "alert", "text": "[对白数据缺失] " + key}]


func _show_title() -> void:
	mode = Mode.TITLE
	player.can_move = false
	world.visible = false
	hud.visible = false
	dialogue.visible = false
	menu.show_title(GameState.has_save(), GameState.has_legacy_save())
	_play_music("res://assets/audio/title_placeholder.mp3", -13.0)


func _show_name_input() -> void:
	mode = Mode.NAME_INPUT
	menu.show_name()


func _confirm_name(value: String) -> void:
	var clean := value.strip_edges()
	if clean.is_empty():
		menu.set_name_error("姓名不能为空。")
		return
	if clean.length() > 9:
		menu.set_name_error("姓名不能超过 9 个字符。")
		return
	GameState.new_game(clean)
	menu.hide_all()
	var prologue = _load_json("res://data/dialogue/prologue.json")
	if not prologue is Array:
		prologue = [{"speaker": "系统", "presentation": "alert", "text": "[对白数据错误] 无法读取序幕。"}]
	_start_dialogue(prologue, _enter_new_game)


func _continue_game() -> void:
	if not GameState.load_game():
		menu.show_title(false, GameState.has_legacy_save())
		return
	_enter_world(true)


func _enter_new_game() -> void:
	_enter_world(false)
	_start_dialogue(get_dialogue("arrival"))


func _enter_world(from_save: bool) -> void:
	mode = Mode.PLAYING
	menu.hide_all()
	menu.visible = false
	dialogue.visible = false
	world.visible = true
	hud.visible = true
	player.can_move = true
	var target_position: Vector2 = GameState.saved_player_position if from_save else GameState.SAFE_SPAWN
	player.position = target_position if world.is_walkable(target_position) else GameState.SAFE_SPAWN
	_play_music("res://assets/audio/base_placeholder.mp3", -16.0)
	_refresh_hud()


func _show_pause() -> void:
	mode = Mode.PAUSED
	player.can_move = false
	hud.hide_prompt()
	menu.visible = true
	menu.show_pause()


func _resume_game() -> void:
	mode = Mode.PLAYING
	menu.hide_pause()
	menu.visible = false
	player.can_move = true


func _save_current_game() -> void:
	if GameState.save_game(player.position):
		menu.set_pause_status("检查点已写入本地存档。")
	else:
		menu.set_pause_status("保存失败：无法写入本地存档目录。", false)


func _start_dialogue(lines: Array, finished_callback := Callable()) -> void:
	if lines.is_empty():
		if finished_callback.is_valid():
			finished_callback.call_deferred()
		return
	dialogue_finished_callback = finished_callback
	mode = Mode.DIALOGUE
	player.can_move = false
	hud.hide_prompt()
	dialogue.start_dialogue(lines, GameState.player_name)


func _on_dialogue_finished() -> void:
	var callback := dialogue_finished_callback
	dialogue_finished_callback = Callable()
	if callback.is_valid():
		callback.call_deferred()
	else:
		mode = Mode.PLAYING
		player.can_move = true


func _on_dialogue_flag_requested(key: String, value: Variant) -> void:
	GameState.set_flag(key, value)


func _handle_interaction(id: String) -> void:
	match id:
		"medical":
			if GameState.has_flag("medical_checked"):
				_start_dialogue(get_dialogue("medical_repeat"))
			else:
				_start_dialogue(get_dialogue("medical_first"), _complete_medical)
		"life_support":
			if GameState.has_flag("life_support_repaired"):
				_start_dialogue(get_dialogue("life_repeat"))
			elif not GameState.has_flag("medical_checked"):
				_start_dialogue(get_dialogue("life_locked"))
			else:
				_start_dialogue(get_dialogue("life_first"), _complete_life_support)
		"console":
			if GameState.has_flag("console_read"):
				_start_dialogue(get_dialogue("console_repeat"))
			elif not GameState.has_flag("life_support_repaired"):
				_start_dialogue(get_dialogue("console_locked"))
			else:
				_start_dialogue(get_dialogue("console_first"), _complete_console)
		"greenhouse":
			if GameState.has_flag("greenhouse_checked"):
				_start_dialogue(get_dialogue("greenhouse_repeat"))
			elif not GameState.has_flag("console_read"):
				_start_dialogue(get_dialogue("greenhouse_locked"))
			else:
				_start_dialogue(get_dialogue("greenhouse_first"), _complete_greenhouse)
		"airlock":
			if GameState.has_flag("eva_ready"):
				_start_dialogue(get_dialogue("airlock_repeat"))
			elif not GameState.has_flag("greenhouse_checked"):
				_start_dialogue(get_dialogue("airlock_locked"))
			else:
				_start_dialogue(get_dialogue("airlock_first"), _complete_airlock)


func _complete_medical() -> void:
	GameState.set_flag("medical_checked")
	GameState.set_task(1, "诊断生命保障主回路，恢复医疗舱供电")
	_checkpoint()
	_return_to_play()


func _complete_life_support() -> void:
	GameState.set_flag("life_support_repaired")
	GameState.change_resource("power", -7)
	GameState.change_resource("oxygen", 26)
	GameState.advance_phase()
	GameState.set_task(2, "读取驾驶舱黑匣，定位前哨站和货舱信标")
	_checkpoint()
	_return_to_play()


func _complete_console() -> void:
	GameState.set_flag("console_read")
	GameState.set_task(3, "核对货舱与温室模块，整理 EVA 装备")
	_checkpoint()
	_return_to_play()


func _complete_greenhouse() -> void:
	GameState.set_flag("greenhouse_checked")
	GameState.change_resource("water", 1)
	GameState.set_task(4, "检查右舷气闸，完成第一次 EVA 前检")
	_checkpoint()
	_return_to_play()


func _complete_airlock() -> void:
	GameState.set_flag("eva_ready")
	GameState.set_task(5, "气闸已解锁：准备进入火星地表")
	_checkpoint()
	_return_to_play()


func _checkpoint() -> void:
	GameState.save_game(player.position)
	world.queue_redraw()


func _return_to_play() -> void:
	mode = Mode.PLAYING
	player.can_move = true
	_refresh_hud()


func _refresh_hud() -> void:
	if hud != null:
		hud.refresh_from_state(GameState)


func _play_music(path: String, volume_db: float) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if music.stream == stream and music.playing:
		return
	music.stop()
	music.stream = stream
	music.volume_db = volume_db
	music.play()
