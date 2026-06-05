extends Node2D

signal died

const BASE_BODY_COLOR = Color(0.31, 0.84, 0.72)
const INK = Color(0.07, 0.06, 0.05)

var arena_size = Vector2(1600.0, 900.0)
var character_id = "balanced_blob"
var body_color = BASE_BODY_COLOR
var radius = 18.0
var move_speed = 260.0
var max_hp = 5
var hp = 5
var pickup_radius = 38.0
var magnet_radius = 90.0
var side_count = 4
var base_damage_mult = 1.0
var damage_multiplier = 1.0
var cooldown_multiplier = 1.0
var weapon_size_multiplier = 1.0
var knockback_multiplier = 1.0
var corner_bonus_enabled = false
var visual_tags = {}
var weapon_visuals = {}

var _move_velocity = Vector2.ZERO
var _knockback_velocity = Vector2.ZERO
var _invulnerable_time = 0.0
var _flash_time = 0.0
var _blink_phase = 0.0
var _wobble_phase = 0.0


func reset(start_position: Vector2, character_stats: Dictionary = {}) -> void:
	position = start_position
	_move_velocity = Vector2.ZERO
	_knockback_velocity = Vector2.ZERO
	_invulnerable_time = 0.0
	_flash_time = 0.0
	_blink_phase = 0.0
	_wobble_phase = 0.0
	character_id = str(character_stats.get("id", "balanced_blob"))
	body_color = character_stats.get("color", BASE_BODY_COLOR)
	radius = float(character_stats.get("radius", 18.0))
	move_speed = float(character_stats.get("move_speed", 260.0))
	max_hp = int(character_stats.get("max_hp", 5))
	hp = max_hp
	pickup_radius = 38.0
	magnet_radius = 90.0
	side_count = int(character_stats.get("side_count", 4))
	base_damage_mult = float(character_stats.get("base_damage_mult", 1.0))
	damage_multiplier = 1.0
	cooldown_multiplier = 1.0
	weapon_size_multiplier = 1.0
	knockback_multiplier = 1.0
	corner_bonus_enabled = false
	visual_tags.clear()
	weapon_visuals.clear()
	queue_redraw()


func update_player(delta: float, accepting_input: bool) -> void:
	if _invulnerable_time > 0.0:
		_invulnerable_time -= delta
	if _flash_time > 0.0:
		_flash_time -= delta
	_blink_phase += delta * 9.0
	_wobble_phase += delta * (4.0 + (2.0 if hp <= 2 else 0.0))

	var input_vector = Vector2.ZERO
	if accepting_input:
		input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		if input_vector.length_squared() > 1.0:
			input_vector = input_vector.normalized()

	var target_velocity = input_vector * move_speed
	var accel = move_speed / 0.08
	var decel = move_speed / 0.10
	if input_vector.length_squared() > 0.001:
		_move_velocity = _move_velocity.move_toward(target_velocity, accel * delta)
	else:
		_move_velocity = _move_velocity.move_toward(Vector2.ZERO, decel * delta)

	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	position += (_move_velocity + _knockback_velocity) * delta
	position.x = clamp(position.x, radius, arena_size.x - radius)
	position.y = clamp(position.y, radius, arena_size.y - radius)
	queue_redraw()


func take_damage(amount: int, source_position: Vector2) -> bool:
	if _invulnerable_time > 0.0 or hp <= 0:
		return false
	hp = max(hp - amount, 0)
	_invulnerable_time = 0.70
	_flash_time = 0.08
	var push_direction = (position - source_position).normalized()
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.RIGHT
	_knockback_velocity += push_direction * 420.0
	queue_redraw()
	if hp <= 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	queue_redraw()


func add_visual_tag(tag: String, amount: int = 1) -> void:
	visual_tags[tag] = int(visual_tags.get(tag, 0)) + amount
	queue_redraw()


func set_weapon_visuals(weapons: Dictionary) -> void:
	weapon_visuals = weapons.duplicate(true)
	queue_redraw()


func is_invulnerable() -> bool:
	return _invulnerable_time > 0.0


func _draw() -> void:
	var blink_alpha = 1.0
	if _invulnerable_time > 0.0:
		blink_alpha = 0.42 + 0.58 * abs(sin(_blink_phase * 2.0))
	var fill = body_color
	if _flash_time > 0.0:
		fill = Color.WHITE
	fill.a = blink_alpha

	_draw_attachment_rings(blink_alpha)
	_draw_body(fill, blink_alpha)
	_draw_eyes(blink_alpha)
	_draw_weapon_idle_marks(blink_alpha)


func _draw_body(fill: Color, alpha: float) -> void:
	match character_id:
		"quick_dot":
			_draw_quick_dot_body(fill, alpha)
		"sturdy_square":
			_draw_sturdy_square_body(fill, alpha)
		"fancy_hex":
			_draw_fancy_hex_body(fill, alpha)
		"timid_triangle":
			_draw_timid_triangle_body(fill, alpha)
		"grumpy_wedge":
			_draw_grumpy_wedge_body(fill, alpha)
		_:
			_draw_balanced_blob_body(fill, alpha)
	_draw_corner_nubs(alpha)


func _draw_balanced_blob_body(fill: Color, alpha: float) -> void:
	var point_count = max(10, side_count + 6)
	var body_points = PackedVector2Array()
	for i in range(point_count):
		var a = -PI * 0.5 + TAU * float(i) / float(point_count)
		var wobble = sin(a * 3.0 + _wobble_phase) * 0.08 + cos(a * 5.0 - 0.7) * 0.04
		var hp_wobble = 0.06 if hp <= 2 else 0.0
		var r = radius * (1.0 + wobble + hp_wobble * sin(_wobble_phase + a * 2.0))
		if i % 3 == 0:
			r += float(visual_tags.get("soft_lobe", 0)) * 1.3
		body_points.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(body_points, fill)
	var outline_width = 6.0 if _flash_time > 0.0 else 4.0
	draw_polyline(_closed_points(body_points), Color(INK.r, INK.g, INK.b, alpha), outline_width, true)


func _draw_quick_dot_body(fill: Color, alpha: float) -> void:
	var trail_dir = _move_velocity.normalized()
	if trail_dir == Vector2.ZERO:
		trail_dir = Vector2.LEFT
	for i in range(3):
		var distance = radius + 8.0 + float(i) * 10.0
		var p = -trail_dir * distance + Vector2(-trail_dir.y, trail_dir.x) * sin(_wobble_phase + float(i)) * 3.0
		draw_circle(p, max(3.0, radius * (0.32 - float(i) * 0.06)), Color(INK.r, INK.g, INK.b, alpha * (0.28 - float(i) * 0.06)))
	draw_circle(Vector2.ZERO, radius + 7.0, Color(INK.r, INK.g, INK.b, alpha * 0.12))
	draw_circle(Vector2.ZERO, radius, Color(INK.r, INK.g, INK.b, alpha))
	draw_circle(Vector2.ZERO, radius - 5.0, fill)


func _draw_sturdy_square_body(fill: Color, alpha: float) -> void:
	var outer = Rect2(Vector2(-radius, -radius), Vector2(radius * 2.0, radius * 2.0))
	draw_rect(outer, Color(INK.r, INK.g, INK.b, alpha))
	draw_rect(outer.grow(-4.5), fill)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var p = Vector2(sx, sy) * (radius - 5.0)
			draw_circle(p, 3.5, Color(1.0, 0.78, 0.32, alpha))


func _draw_fancy_hex_body(fill: Color, alpha: float) -> void:
	var body_points = PackedVector2Array()
	for i in range(6):
		var a = -PI * 0.5 + TAU * float(i) / 6.0
		var corner_wobble = sin(_wobble_phase * 1.6 + float(i) * 1.7) * 0.05
		var proud_lift = 0.04 if i == 0 else 0.0
		var r = radius * (1.0 + corner_wobble + proud_lift)
		body_points.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(body_points, fill)
	draw_polyline(_closed_points(body_points), Color(INK.r, INK.g, INK.b, alpha), 4.8, true)
	for point in body_points:
		var p = point * 0.76
		draw_circle(p, 2.7, Color(INK.r, INK.g, INK.b, alpha))
		draw_circle(p, 1.45, Color(1.0, 0.95, 0.45, alpha))


func _draw_timid_triangle_body(fill: Color, alpha: float) -> void:
	var flinch = Vector2(-1.0, -1.0).normalized() * sin(_wobble_phase * 0.7) * 1.8
	var body_points = PackedVector2Array()
	for i in range(3):
		var a = -PI * 0.5 + TAU * float(i) / 3.0
		var r = radius * (1.0 + sin(_wobble_phase * 2.2 + float(i) * 1.1) * 0.04)
		body_points.append(flinch + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(body_points, fill)
	draw_polyline(_closed_points(body_points), Color(INK.r, INK.g, INK.b, alpha), 5.0, true)


func _draw_grumpy_wedge_body(fill: Color, alpha: float) -> void:
	var verts = PackedVector2Array([
		Vector2(radius * 0.92, 0.0),
		Vector2(radius * 0.15, -radius * 0.72),
		Vector2(-radius * 0.82, -radius * 0.52),
		Vector2(-radius * 0.82, radius * 0.52),
		Vector2(radius * 0.15, radius * 0.72)
	])
	var body_points = PackedVector2Array()
	for i in range(verts.size()):
		var scale = 1.0 + sin(_wobble_phase * 1.8 + float(i) * 1.3) * 0.025
		body_points.append(verts[i] * scale)
	draw_colored_polygon(body_points, fill)
	draw_polyline(_closed_points(body_points), Color(INK.r, INK.g, INK.b, alpha), 4.8, true)


func _draw_corner_nubs(alpha: float) -> void:
	var corner_count = int(visual_tags.get("corner_nubs", 0))
	for i in range(corner_count):
		var a = TAU * float(i) / max(float(corner_count), 1.0) + _wobble_phase * 0.12
		var p = Vector2(cos(a), sin(a)) * (radius + 9.0)
		draw_circle(p, 4.0, Color(INK.r, INK.g, INK.b, alpha))
		draw_circle(p, 2.4, Color(0.98, 0.65, 0.20, alpha))


func _draw_eyes(alpha: float) -> void:
	if character_id == "timid_triangle":
		var eye_y = -4.0 + sin(_wobble_phase) * 0.5
		draw_line(Vector2(-4.5, eye_y), Vector2(-1.5, eye_y + 0.5), Color(INK.r, INK.g, INK.b, alpha), 2.0)
		var wide = 1.0 + (0.4 if _flash_time > 0.0 else 0.0)
		draw_circle(Vector2(3.5, eye_y + sin(_wobble_phase + 0.8) * 0.5), 2.4 * wide, Color(INK.r, INK.g, INK.b, alpha))
		return
	if character_id == "grumpy_wedge":
		var eye_y = -3.5 + sin(_wobble_phase) * 0.3
		draw_line(Vector2(-9.5, eye_y - 3.0), Vector2(-3.0, eye_y - 5.5), Color(INK.r, INK.g, INK.b, alpha), 2.2)
		draw_line(Vector2(3.0, eye_y - 5.5), Vector2(9.5, eye_y - 3.0), Color(INK.r, INK.g, INK.b, alpha), 2.2)
		draw_circle(Vector2(-5.5, eye_y), 2.0, Color(INK.r, INK.g, INK.b, alpha))
		draw_circle(Vector2(5.5, eye_y + sin(_wobble_phase + 0.9) * 0.4), 2.0, Color(INK.r, INK.g, INK.b, alpha))
		return
	if character_id == "sturdy_square":
		var eye_y = -5.0 + sin(_wobble_phase) * 0.4
		draw_line(Vector2(-10.0, eye_y), Vector2(-3.0, eye_y), Color(INK.r, INK.g, INK.b, alpha), 3.0)
		draw_line(Vector2(4.0, eye_y), Vector2(11.0, eye_y), Color(INK.r, INK.g, INK.b, alpha), 3.0)
		return
	if character_id == "fancy_hex":
		var eye_y = -5.5 + sin(_wobble_phase * 1.4) * 0.45
		draw_circle(Vector2(-6.0, eye_y), 2.6, Color(INK.r, INK.g, INK.b, alpha))
		draw_circle(Vector2(6.0, eye_y), 2.6, Color(INK.r, INK.g, INK.b, alpha))
		draw_line(Vector2(-9.0, eye_y - 5.0), Vector2(-3.0, eye_y - 3.0), Color(INK.r, INK.g, INK.b, alpha), 2.0)
		draw_line(Vector2(3.0, eye_y - 3.0), Vector2(9.0, eye_y - 5.0), Color(INK.r, INK.g, INK.b, alpha), 2.0)
		return
	var eye_offset = 6.0 + (3.0 if hp <= 2 else 0.0)
	if character_id == "quick_dot":
		eye_offset = 4.5
	if _flash_time > 0.0:
		eye_offset += 2.4
	var eye_y = -4.0 + sin(_wobble_phase) * 0.8
	var eye_scale = 1.0 + (0.35 if hp <= 2 else 0.0) + (0.25 if _flash_time > 0.0 else 0.0)
	draw_circle(Vector2(-eye_offset, eye_y), 2.3 * eye_scale, Color(INK.r, INK.g, INK.b, alpha))
	draw_circle(Vector2(eye_offset, eye_y + sin(_wobble_phase + 1.4) * 0.8), 2.3 * eye_scale, Color(INK.r, INK.g, INK.b, alpha))


func _draw_attachment_rings(alpha: float) -> void:
	if int(visual_tags.get("magnet_ring", 0)) > 0:
		for i in range(20):
			var a = TAU * float(i) / 20.0 + _wobble_phase * 0.3
			var p = Vector2(cos(a), sin(a)) * (radius + 19.0)
			draw_circle(p, 1.7, Color(0.07, 0.06, 0.05, alpha * 0.8))
	if int(visual_tags.get("pulse_ring", 0)) > 0:
		draw_arc(Vector2.ZERO, radius + 25.0 + sin(_wobble_phase) * 2.0, 0.0, TAU, 72, Color(0.24, 0.48, 0.82, alpha * 0.6), 3.0, true)
	if int(visual_tags.get("ruler_halo", 0)) > 0:
		draw_arc(Vector2.ZERO, radius + 30.0, -0.4, PI + 0.4, 40, Color(0.14, 0.36, 0.18, alpha * 0.55), 5.0, true)


func _draw_weapon_idle_marks(alpha: float) -> void:
	if weapon_visuals.has("volunteer_dot"):
		var level = int(weapon_visuals["volunteer_dot"])
		var angle = -0.45 + sin(_wobble_phase * 2.1) * 0.16
		var p = Vector2.RIGHT.rotated(angle) * (radius + 15.0)
		var dot_radius = 5.2 + min(2.0, float(level - 1) * 0.35) + sin(_wobble_phase * 7.0) * 0.45
		draw_circle(p, dot_radius + 3.2, Color(INK.r, INK.g, INK.b, alpha))
		draw_circle(p, dot_radius, Color(0.98, 0.89, 0.24, alpha))
		draw_circle(p + Vector2(-1.8, -1.8), max(1.2, dot_radius * 0.24), Color(1.0, 1.0, 1.0, alpha * 0.85))
	if weapon_visuals.has("dot_swarm"):
		var count = 3 + int(weapon_visuals["dot_swarm"]) - 1
		for i in range(count):
			var a = _wobble_phase * 1.4 + TAU * float(i) / float(count)
			var p = Vector2(cos(a), sin(a)) * (radius + 33.0)
			draw_circle(p, 4.0, Color(0.97, 0.92, 0.25, alpha))
			draw_arc(p, 4.4, 0.0, TAU, 18, Color(INK.r, INK.g, INK.b, alpha), 2.0, true)
	if weapon_visuals.has("corner_cannon"):
		draw_rect(Rect2(Vector2(radius + 1.0, -7.0), Vector2(12.0, 14.0)), Color(INK.r, INK.g, INK.b, alpha))
		draw_rect(Rect2(Vector2(-radius - 13.0, -7.0), Vector2(12.0, 14.0)), Color(INK.r, INK.g, INK.b, alpha))
	if weapon_visuals.has("rude_triangle"):
		var points = PackedVector2Array([
			Vector2(0.0, -radius - 17.0),
			Vector2(8.0, -radius - 3.0),
			Vector2(-8.0, -radius - 3.0)
		])
		draw_colored_polygon(points, Color(0.94, 0.27, 0.18, alpha))
		draw_polyline(_closed_points(points), Color(INK.r, INK.g, INK.b, alpha), 2.5, true)


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed = PackedVector2Array(points)
	if points.size() > 0:
		closed.append(points[0])
	return closed
