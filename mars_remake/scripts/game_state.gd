extends Node

signal state_changed

const SAVE_VERSION := 2
const SAVE_PATH := "user://mars_save_v2.json"
const LEGACY_SAVE_PATH := "user://mars_save_v1.json"
const PHASES := ["清晨", "白昼", "黄昏", "夜晚"]
const SAFE_SPAWN := Vector2(520, 384)

var player_name := "航天员"
var sol := 0
var phase_index := 2
var task_stage := 0
var objective := "前往医疗区，确认希娜的生命体征"
var resources := {"oxygen": 34, "power": 46, "water": 3}
var flags := {}
var saved_player_position := SAFE_SPAWN


func new_game(new_name: String) -> void:
	player_name = new_name.strip_edges()
	if player_name.is_empty():
		player_name = "航天员"
	sol = 0
	phase_index = 2
	task_stage = 0
	objective = "前往医疗区，确认希娜的生命体征"
	resources = {"oxygen": 34, "power": 46, "water": 3}
	flags = {}
	saved_player_position = SAFE_SPAWN
	state_changed.emit()


func get_phase_name() -> String:
	return PHASES[phase_index]


func set_task(stage: int, value: String) -> void:
	task_stage = maxi(stage, 0)
	objective = value
	state_changed.emit()


func set_objective(value: String) -> void:
	objective = value
	state_changed.emit()


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value
	state_changed.emit()


func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))


func get_flag(key: String, default_value: Variant = null) -> Variant:
	return flags.get(key, default_value)


func change_resource(key: String, amount: int) -> void:
	var maximum := 10 if key == "water" else 100
	resources[key] = clampi(int(resources.get(key, 0)) + amount, 0, maximum)
	state_changed.emit()


func advance_phase() -> void:
	phase_index += 1
	if phase_index >= PHASES.size():
		phase_index = 0
		sol += 1
	state_changed.emit()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func has_legacy_save() -> bool:
	return FileAccess.file_exists(LEGACY_SAVE_PATH)


func save_game(player_position: Vector2) -> bool:
	saved_player_position = player_position
	var data := {
		"version": SAVE_VERSION,
		"player_name": player_name,
		"sol": sol,
		"phase_index": phase_index,
		"task_stage": task_stage,
		"objective": objective,
		"resources": resources,
		"flags": flags,
		"player_position": {"x": player_position.x, "y": player_position.y},
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", 0)) != SAVE_VERSION:
		return false
	player_name = str(parsed.get("player_name", "航天员"))
	sol = maxi(int(parsed.get("sol", 0)), 0)
	phase_index = clampi(int(parsed.get("phase_index", 2)), 0, PHASES.size() - 1)
	task_stage = maxi(int(parsed.get("task_stage", 0)), 0)
	objective = str(parsed.get("objective", "前往医疗区，确认希娜的生命体征"))
	var loaded_resources = parsed.get("resources", {})
	resources = {
		"oxygen": clampi(int(loaded_resources.get("oxygen", 34)), 0, 100),
		"power": clampi(int(loaded_resources.get("power", 46)), 0, 100),
		"water": clampi(int(loaded_resources.get("water", 3)), 0, 10),
	}
	flags = parsed.get("flags", {}) if parsed.get("flags", {}) is Dictionary else {}
	var pos = parsed.get("player_position", {})
	saved_player_position = Vector2(float(pos.get("x", SAFE_SPAWN.x)), float(pos.get("y", SAFE_SPAWN.y)))
	if not Rect2(42, 112, 1068, 474).has_point(saved_player_position):
		saved_player_position = SAFE_SPAWN
	state_changed.emit()
	return true
