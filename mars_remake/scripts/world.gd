extends Node2D

const FLOOR := Color("172127")
const FLOOR_ALT := Color("1d2a30")
const WALL := Color("3c4b50")
const WALL_LIT := Color("68767a")
const PANEL_LINE := Color("2c3c42")
const PIPE := Color("718086")
const SHADOW := Color(0.01, 0.015, 0.018, 0.72)

var pulse := 0.0
var interactables := [
	{"id": "medical", "title": "医疗舱 / 希娜", "position": Vector2(392, 222)},
	{"id": "life_support", "title": "生命保障主回路", "position": Vector2(700, 220)},
	{"id": "console", "title": "驾驶舱飞行日志", "position": Vector2(154, 365)},
	{"id": "greenhouse", "title": "货舱与温室模块", "position": Vector2(610, 502)},
	{"id": "airlock", "title": "右舷气闸", "position": Vector2(1006, 392)},
]

var walkable_areas := [
	Rect2(58, 300, 220, 200),
	Rect2(250, 118, 286, 190),
	Rect2(548, 118, 326, 190),
	Rect2(254, 308, 656, 132),
	Rect2(328, 438, 498, 136),
	Rect2(908, 286, 178, 236),
	Rect2(177, 335, 154, 92),
	Rect2(372, 276, 88, 78),
	Rect2(666, 274, 88, 80),
	Rect2(530, 409, 116, 72),
	Rect2(870, 344, 82, 94),
]


func _ready() -> void:
	_build_collision()
	GameState.state_changed.connect(_on_state_changed)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	pulse = fmod(pulse + delta, TAU)
	queue_redraw()


func _on_state_changed() -> void:
	queue_redraw()


func nearest_interaction(player_position: Vector2, max_distance := 76.0) -> Dictionary:
	var nearest := {}
	var best_distance := max_distance
	for item in interactables:
		var distance := player_position.distance_to(item["position"])
		if distance < best_distance:
			best_distance = distance
			nearest = item
	return nearest


func is_walkable(point: Vector2) -> bool:
	for rect in walkable_areas:
		var margin := 9.0 if rect.size.x < 160 or rect.size.y < 100 else 15.0
		if rect.grow(-margin).has_point(point):
			return true
	return false


func interaction_status(id: String) -> String:
	match id:
		"medical":
			return "状态已读取" if GameState.has_flag("medical_checked") else "优先级：紧急"
		"life_support":
			return "主回路稳定" if GameState.has_flag("life_support_repaired") else "故障 / 需要诊断"
		"console":
			return "信标已定位" if GameState.has_flag("console_read") else "本地黑匣在线"
		"greenhouse":
			return "货物已核对" if GameState.has_flag("greenhouse_checked") else "运输锁定"
		"airlock":
			return "EVA 准备完成" if GameState.has_flag("eva_ready") else "气密状态待检"
	return "可互动"


func _draw() -> void:
	_draw_mars_surface()
	_draw_ship_shadow()
	_draw_ship_floor()
	_draw_hull()
	_draw_details()
	_draw_equipment()
	_draw_interactions()
	_draw_labels()


func _draw_mars_surface() -> void:
	draw_rect(Rect2(0, 0, 1152, 648), Color("351b18"), true)
	for y in range(96, 648, 32):
		var alpha := 0.04 + float((y / 32) % 3) * 0.012
		draw_line(Vector2(0, y), Vector2(1152, y - 54), Color(0.83, 0.39, 0.22, alpha), 1.0)
	for i in range(18):
		var x := float((i * 79 + 31) % 1152)
		var y := float(108 + (i * 113) % 510)
		var r := float(3 + (i * 5) % 12)
		_draw_oval(Vector2(x, y), Vector2(r * 1.8, r), Color(0.12, 0.055, 0.045, 0.45))
	for i in range(12):
		var drift := fmod(float(i * 101) + pulse * 13.0, 1250.0) - 50.0
		var y := 122.0 + float((i * 47) % 480)
		draw_line(Vector2(drift, y), Vector2(drift + 72, y - 9), Color(0.95, 0.55, 0.34, 0.06), 2.0)


func _draw_ship_shadow() -> void:
	var shadow_poly := PackedVector2Array([
		Vector2(35, 348), Vector2(84, 254), Vector2(222, 252), Vector2(240, 101),
		Vector2(882, 101), Vector2(902, 266), Vector2(1102, 300), Vector2(1120, 524),
		Vector2(826, 596), Vector2(326, 596), Vector2(304, 548), Vector2(82, 500),
	])
	for point_index in range(shadow_poly.size()):
		shadow_poly[point_index] += Vector2(9, 12)
	draw_colored_polygon(shadow_poly, SHADOW)


func _draw_ship_floor() -> void:
	_draw_floor_area(Rect2(58, 300, 220, 200), Color("18242a"))
	_draw_floor_area(Rect2(250, 118, 286, 190), Color("1b282e"))
	_draw_floor_area(Rect2(548, 118, 326, 190), Color("17272c"))
	_draw_floor_area(Rect2(254, 308, 656, 132), FLOOR)
	_draw_floor_area(Rect2(328, 438, 498, 136), Color("202a2d"))
	_draw_floor_area(Rect2(908, 286, 178, 236), Color("242728"))
	# Connectors make the ship read as one damaged pressure vessel.
	draw_rect(Rect2(177, 335, 154, 92), FLOOR, true)
	draw_rect(Rect2(372, 276, 88, 78), FLOOR, true)
	draw_rect(Rect2(666, 274, 88, 80), FLOOR, true)
	draw_rect(Rect2(530, 409, 116, 72), FLOOR, true)
	draw_rect(Rect2(870, 344, 82, 94), FLOOR, true)


func _draw_floor_area(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color, true)
	for x in range(int(rect.position.x) + 24, int(rect.end.x), 32):
		draw_line(Vector2(x, rect.position.y + 5), Vector2(x, rect.end.y - 5), Color(PANEL_LINE, 0.62), 1.0)
	for y in range(int(rect.position.y) + 24, int(rect.end.y), 32):
		draw_line(Vector2(rect.position.x + 5, y), Vector2(rect.end.x - 5, y), Color(PANEL_LINE, 0.55), 1.0)


func _draw_hull() -> void:
	_draw_room_hull(Rect2(58, 300, 220, 200), [Vector2(278, 350), Vector2(278, 418)])
	_draw_room_hull(Rect2(250, 118, 286, 190), [Vector2(372, 308), Vector2(458, 308)])
	_draw_room_hull(Rect2(548, 118, 326, 190), [Vector2(666, 308), Vector2(754, 308)])
	_draw_room_hull(Rect2(254, 308, 656, 132), [Vector2(254, 350), Vector2(254, 418), Vector2(530, 440), Vector2(646, 440), Vector2(910, 346), Vector2(910, 432)])
	_draw_room_hull(Rect2(328, 438, 498, 136), [Vector2(530, 438), Vector2(646, 438)])
	_draw_room_hull(Rect2(908, 286, 178, 236), [Vector2(908, 346), Vector2(908, 432)])
	# Crushed left-side bow and torn upper plating.
	draw_polyline(PackedVector2Array([Vector2(58, 300), Vector2(39, 328), Vector2(53, 352), Vector2(42, 389)]), MarsUI.DANGER, 4.0)
	draw_line(Vector2(246, 119), Vector2(267, 101), WALL_LIT, 5.0)
	draw_line(Vector2(267, 101), Vector2(303, 112), MarsUI.MARS, 3.0)
	draw_line(Vector2(300, 111), Vector2(323, 96), WALL_LIT, 4.0)
	# Airlock outer frame.
	draw_rect(Rect2(1054, 344, 46, 120), Color("11191d"), true)
	draw_rect(Rect2(1054, 344, 46, 120), WALL_LIT, false, 5.0)
	for y in range(354, 459, 18):
		draw_line(Vector2(1061, y), Vector2(1093, y + 10), Color(MarsUI.AMBER, 0.52), 3.0)


func _draw_room_hull(rect: Rect2, door_points: Array) -> void:
	draw_rect(rect, WALL, false, 8.0)
	draw_rect(rect.grow(-7), Color(WALL_LIT, 0.36), false, 2.0)
	for index in range(0, door_points.size(), 2):
		if index + 1 >= door_points.size():
			break
		var a: Vector2 = door_points[index]
		var b: Vector2 = door_points[index + 1]
		draw_line(a, b, FLOOR, 13.0)
		draw_circle(a, 5, MarsUI.AMBER)
		draw_circle(b, 5, MarsUI.AMBER)


func _draw_details() -> void:
	# Overhead pipes and cable runs.
	draw_line(Vector2(292, 325), Vector2(854, 325), Color(PIPE, 0.72), 5.0)
	draw_line(Vector2(292, 334), Vector2(854, 334), Color(MarsUI.CYAN_DIM, 0.72), 3.0)
	for x in range(310, 850, 64):
		draw_line(Vector2(x, 319), Vector2(x, 340), WALL_LIT, 2.0)
	# Emergency beacons pulse without flashing the whole screen.
	var beacon_alpha := 0.35 + (sin(pulse * 2.0) + 1.0) * 0.2
	for p in [Vector2(282, 334), Vector2(866, 334), Vector2(942, 318)]:
		draw_circle(p, 7, Color(MarsUI.DANGER, beacon_alpha))
		draw_arc(p, 12, 0, TAU, 24, Color(MarsUI.DANGER, 0.22), 2.0)
	# Debris and impact scratches.
	for i in range(8):
		var x := 84.0 + i * 19.0
		var y := 462.0 + float((i * 11) % 25)
		draw_line(Vector2(x, y), Vector2(x + 10, y - 8), Color("738086"), 3.0)
	draw_line(Vector2(94, 316), Vector2(181, 355), Color(MarsUI.MARS, 0.58), 3.0)
	draw_line(Vector2(78, 329), Vector2(172, 371), Color(MarsUI.MARS, 0.32), 2.0)


func _draw_equipment() -> void:
	# Cockpit seats and damaged instrument crescent.
	draw_arc(Vector2(153, 365), 70, PI * 0.72, PI * 2.28, 44, Color("607078"), 10.0)
	draw_rect(Rect2(122, 397, 32, 52), Color("2b363c"), true)
	draw_rect(Rect2(174, 397, 32, 52), Color("2b363c"), true)
	draw_line(Vector2(88, 344), Vector2(211, 328), Color(MarsUI.CYAN, 0.46), 3.0)
	# Medical pod.
	draw_rect(Rect2(316, 166, 154, 82), Color("101a1f"), true)
	draw_rect(Rect2(316, 166, 154, 82), Color("7a8b90"), false, 5.0)
	draw_arc(Vector2(392, 207), 50, PI, TAU, 36, Color("8bbdc2"), 4.0)
	draw_line(Vector2(336, 232), Vector2(448, 232), Color(MarsUI.CYAN, 0.52), 2.0)
	draw_polyline(PackedVector2Array([Vector2(410, 183), Vector2(418, 190), Vector2(426, 177), Vector2(434, 196), Vector2(443, 187)]), MarsUI.SUCCESS if GameState.has_flag("medical_checked") else MarsUI.DANGER, 2.0)
	# Life support cylinders and diagnostic display.
	for x in [610.0, 650.0, 690.0]:
		draw_rect(Rect2(x, 162, 26, 92), Color("263238"), true)
		draw_arc(Vector2(x + 13, 162), 13, PI, TAU, 18, WALL_LIT, 3.0)
	draw_rect(Rect2(738, 162, 82, 70), Color("091419"), true)
	draw_rect(Rect2(738, 162, 82, 70), MarsUI.CYAN_DIM, false, 3.0)
	var life_color := MarsUI.SUCCESS if GameState.has_flag("life_support_repaired") else MarsUI.DANGER
	for y in range(176, 218, 11):
		draw_line(Vector2(750, y), Vector2(806 - (y % 17), y), Color(life_color, 0.72), 2.0)
	# Cargo / greenhouse transport cradles.
	for x in [390.0, 512.0, 634.0, 756.0]:
		draw_rect(Rect2(x, 474, 90, 58), Color("263033"), true)
		draw_rect(Rect2(x, 474, 90, 58), Color("69767a"), false, 3.0)
		draw_line(Vector2(x + 8, 487), Vector2(x + 82, 487), Color(MarsUI.AMBER, 0.54), 2.0)
	# Airlock inner door.
	draw_rect(Rect2(952, 340, 104, 124), Color("121b1f"), true)
	draw_rect(Rect2(952, 340, 104, 124), WALL_LIT, false, 5.0)
	draw_circle(Vector2(1004, 402), 28, Color("25343a"))
	draw_arc(Vector2(1004, 402), 28, 0, TAU, 32, MarsUI.AMBER if GameState.has_flag("eva_ready") else WALL_LIT, 4.0)
	draw_line(Vector2(1004, 374), Vector2(1004, 430), WALL_LIT, 2.0)


func _draw_interactions() -> void:
	for item in interactables:
		var p: Vector2 = item["position"]
		var complete := _is_complete(str(item["id"]))
		var accent := MarsUI.SUCCESS if complete else MarsUI.CYAN
		var ring := 17.0 + sin(pulse * 2.5 + p.x * 0.01) * 2.0
		draw_arc(p, ring, -PI * 0.2, PI * 1.35, 28, Color(accent, 0.85), 2.0)
		draw_line(p + Vector2(-25, 0), p + Vector2(-17, 0), Color(accent, 0.65), 1.0)
		draw_line(p + Vector2(17, 0), p + Vector2(25, 0), Color(accent, 0.65), 1.0)
		draw_circle(p, 3, accent)


func _is_complete(id: String) -> bool:
	match id:
		"medical": return GameState.has_flag("medical_checked")
		"life_support": return GameState.has_flag("life_support_repaired")
		"console": return GameState.has_flag("console_read")
		"greenhouse": return GameState.has_flag("greenhouse_checked")
		"airlock": return GameState.has_flag("eva_ready")
	return false


func _draw_labels() -> void:
	var data_font := MarsUI.data_font()
	var body_font := MarsUI.body_font()
	_draw_zone_label(Vector2(78, 326), "01", "驾驶舱 / FLIGHT DECK", data_font, body_font)
	_draw_zone_label(Vector2(270, 142), "02", "医疗区 / MEDICAL", data_font, body_font)
	_draw_zone_label(Vector2(568, 142), "03", "生命保障 / LIFE SUPPORT", data_font, body_font)
	_draw_zone_label(Vector2(348, 462), "04", "货舱 / HABITAT CARGO", data_font, body_font)
	_draw_zone_label(Vector2(930, 310), "05", "气闸 / EVA LOCK", data_font, body_font)
	draw_string(data_font, Vector2(424, 405), "F-47 PRESSURE SPINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(MarsUI.MUTED, 0.68))


func _draw_zone_label(pos: Vector2, code: String, title: String, data_font: Font, body_font: Font) -> void:
	draw_string(data_font, pos, code, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MarsUI.AMBER)
	draw_string(body_font, pos + Vector2(28, 0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("aebcc0"))


func _build_collision() -> void:
	_add_wall(Rect2(24, 96, 1104, 18))
	_add_wall(Rect2(24, 586, 1104, 20))
	_add_wall(Rect2(24, 96, 18, 510))
	_add_wall(Rect2(1110, 96, 18, 510))
	# Large equipment blocks preserve readable corridors.
	_add_wall(Rect2(310, 154, 168, 38))
	_add_wall(Rect2(592, 148, 238, 35))
	_add_wall(Rect2(378, 462, 456, 24))
	_add_wall(Rect2(940, 328, 128, 32))


func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	shape_node.shape = shape
	shape_node.position = rect.position + rect.size * 0.5
	body.add_child(shape_node)
	add_child(body)


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
