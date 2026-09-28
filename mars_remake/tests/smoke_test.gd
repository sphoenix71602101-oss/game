extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_dialogue_files()
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert(scene != null, "Main scene must load")
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var state := root.get_node("GameState")
	var dialogue = main.get_node("UI/Dialogue")

	assert(main.get_node("World") != null, "World node must exist")
	assert(main.get_node("World/Player/CollisionShape2D") != null, "Player collision must exist")
	assert(main.get_node("World").call("is_walkable", Vector2(520, 384)), "Safe spawn must be walkable")
	assert(not main.get_node("World").call("is_walkable", Vector2(40, 160)), "Mars exterior must not be walkable")
	assert(main.get_node("UI/Menu") != null, "Menu controller must exist")
	assert(main.get_node("UI/HUD") != null, "HUD controller must exist")
	assert(main.get("mode") == 0, "Title screen must be active on boot")

	main.call("_show_name_input")
	main.call("_confirm_name", "测试员")
	assert(state.player_name == "测试员", "Player name must be stored")
	await _drain_dialogue(dialogue)
	await process_frame
	await process_frame
	if dialogue.visible:
		await _drain_dialogue(dialogue)
	assert(main.get_node("World").visible, "World must be visible after prologue")
	assert(main.get_node("World/Player").can_move, "Player must move after arrival sequence")

	main.call("_handle_interaction", "life_support")
	await _drain_dialogue(dialogue)
	assert(not state.has_flag("life_support_repaired"), "Life support must stay locked before medical check")

	main.call("_handle_interaction", "medical")
	await _drain_dialogue(dialogue)
	await process_frame
	await process_frame
	assert(state.has_flag("medical_checked"), "Medical interaction must set its flag")
	assert(["promise", "report"].has(state.get_flag("medical_tone")), "Medical response choice must persist")

	var oxygen_before := int(state.resources["oxygen"])
	main.call("_handle_interaction", "life_support")
	await _drain_dialogue(dialogue)
	await process_frame
	await process_frame
	assert(state.has_flag("life_support_repaired"), "Repair must set its flag")
	assert(int(state.resources["oxygen"]) > oxygen_before, "Repair must improve oxygen")

	main.call("_handle_interaction", "console")
	await _drain_dialogue(dialogue)
	await process_frame
	await process_frame
	assert(state.has_flag("console_read"), "Console must reveal the outpost beacon")

	main.call("_handle_interaction", "greenhouse")
	await _drain_dialogue(dialogue)
	await process_frame
	await process_frame
	assert(state.has_flag("greenhouse_checked"), "Cargo check must complete")

	main.call("_handle_interaction", "airlock")
	await _drain_dialogue(dialogue)
	await process_frame
	await process_frame
	assert(state.has_flag("eva_ready"), "Airlock must unlock at the milestone ending")
	assert(state.task_stage == 5, "Final task stage must be EVA ready")
	assert(state.has_save(), "Milestone must create a v2 checkpoint")

	var save_path := ProjectSettings.globalize_path(state.SAVE_PATH)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	main.queue_free()
	await process_frame
	print("MARS_REMAKE_SMOKE_TEST_OK")
	quit(0)


func _drain_dialogue(dialogue: Control) -> void:
	var safety := 0
	while dialogue.visible and safety < 1200:
		if dialogue.call("is_choice_active"):
			var choices_box = dialogue.get("choices_box")
			assert(choices_box.get_child_count() > 0, "Choice state must expose buttons")
			(choices_box.get_child(0) as Button).pressed.emit()
		else:
			dialogue.call("advance")
		await process_frame
		safety += 1
	assert(safety < 1200, "Dialogue must terminate without a loop")


func _validate_dialogue_files() -> void:
	var prologue = _read_json("res://data/dialogue/prologue.json")
	var interactions = _read_json("res://data/dialogue/interactions.json")
	assert(prologue is Array and prologue.size() >= 50, "Prologue must contain the expanded descent sequence")
	assert(interactions is Dictionary, "Interaction dialogue must be a dictionary")
	var total: int = int(prologue.size())
	for key in interactions.keys():
		var sequence = interactions[key]
		assert(sequence is Array and not sequence.is_empty(), "Dialogue sequence must not be empty: " + str(key))
		total += sequence.size()
		_validate_sequence(sequence, str(key))
	assert(total >= 120, "First milestone must contain at least 120 narrative units")


func _validate_sequence(sequence: Array, key: String) -> void:
	var ids := {}
	for line in sequence:
		assert(line is Dictionary, "Dialogue entry must be an object: " + key)
		assert(not str(line.get("text", "")).strip_edges().is_empty(), "Dialogue text must not be empty: " + key)
		if line.has("id"):
			ids[str(line["id"])] = true
	for line in sequence:
		if line.has("next") and str(line["next"]) != "END":
			assert(ids.has(str(line["next"])), "Dialogue next target must exist: " + key)
		for choice in line.get("choices", []):
			if choice.has("next") and str(choice["next"]) != "END":
				assert(ids.has(str(choice["next"])), "Choice next target must exist: " + key)


func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "Dialogue file must open: " + path)
	return JSON.parse_string(file.get_as_text())
