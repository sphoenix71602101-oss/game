extends CharacterBody2D

@export var speed := 175.0
var can_move := false
var facing := Vector2.DOWN
var walk_phase := 0.0


func _ready() -> void:
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length() > 0.05:
		facing = input_vector.normalized()
		walk_phase += _delta * 10.0
	velocity = input_vector.normalized() * speed
	var previous_position := global_position
	move_and_slide()
	if get_parent().has_method("is_walkable") and not get_parent().call("is_walkable", global_position):
		global_position = previous_position
		velocity = Vector2.ZERO
	global_position.x = clampf(global_position.x, 48.0, 1104.0)
	global_position.y = clampf(global_position.y, 120.0, 578.0)
	queue_redraw()


func _draw() -> void:
	# 这是可读性优先的程序化占位宇航员，正式像素角色后续可直接替换。
	var bob := sin(walk_phase) * 1.3 if velocity.length() > 1.0 else 0.0
	draw_oval(Vector2(2, 18), Vector2(17, 7), Color(0.01, 0.015, 0.02, 0.58))
	draw_rect(Rect2(-12, -3 + bob, 24, 29), Color("cfd9dc"), true)
	draw_rect(Rect2(-10, 1 + bob, 20, 15), Color("b75836"), true)
	draw_rect(Rect2(-8, 4 + bob, 16, 4), Color("f0b35c"), true)
	draw_line(Vector2(-8, 17 + bob), Vector2(-10, 28 + bob), Color("8f9da2"), 5.0)
	draw_line(Vector2(8, 17 + bob), Vector2(10, 28 + bob), Color("8f9da2"), 5.0)
	draw_circle(Vector2(0, -10 + bob), 13, Color("dfe6e8"))
	draw_circle(Vector2(0, -10 + bob), 9, Color("1f3944"))
	draw_arc(Vector2(0, -10 + bob), 8, PI * 1.05, PI * 1.72, 16, Color("79ced2"), 2.0)
	draw_circle(Vector2(-9, -1 + bob), 2.5, Color("79ced2"))
	draw_line(Vector2.ZERO + Vector2(0, bob), facing * 13.0 + Vector2(0, bob), Color("f0b35c"), 2.0)


func draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

