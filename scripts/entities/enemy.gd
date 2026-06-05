extends Node2D

signal boss_shed(source_position)
signal boss_health_drop(source_position)

const INK = Color(0.07, 0.06, 0.05)

var kind = "wobble_circle"
var hp = 8.0
var max_hp = 8.0
var radius = 15.0
var speed = 120.0
var contact_damage = 1
var arena_size = Vector2(1600.0, 900.0)
var active_delay = 0.4
var velocity = Vector2.ZERO
var knockback_velocity = Vector2.ZERO
var color = Color(0.95, 0.82, 0.20)
var score_value = 10

var _phase = "chase"
var _phase_time = 0.0
var _wobble_seed = 0.0
var _charge_dir = Vector2.RIGHT
var _flash_time = 0.0
var _boss_vertices = PackedVector2Array()
var _boss_drop_gate = false
var _spiral_body_radius = 20.0
var _spiral_burst_radius = 82.0
var _spiral_spin = 0.0


func setup(enemy_kind: String, start_position: Vector2, target_position: Vector2, world_size: Vector2) -> void:
	kind = enemy_kind
	position = start_position
	arena_size = world_size
	_wobble_seed = randf_range(0.0, TAU)
	_charge_dir = (target_position - start_position).normalized()
	if _charge_dir == Vector2.ZERO:
		_charge_dir = Vector2.RIGHT

	match kind:
		"pointy_triangle":
			hp = 10.0
			radius = 18.0
			speed = 230.0
			color = Color(0.93, 0.21, 0.16)
			_phase = "aim"
			_phase_time = 0.0
			score_value = 14
		"smug_square":
			hp = 18.0
			radius = 22.0
			speed = 86.0
			color = Color(0.25, 0.52, 0.91)
			score_value = 18
		"needle_line":
			hp = 12.0
			radius = 24.0
			speed = 320.0
			color = Color(0.57, 0.28, 0.78)
			_phase = "telegraph"
			_phase_time = 0.0
			score_value = 22
		"dizzy_spiral":
			hp = 14.0
			radius = 20.0
			speed = 105.0
			color = Color(0.34, 0.86, 0.56)
			_phase = "spiral_roam"
			_phase_time = 0.0
			_spiral_body_radius = radius
			_spiral_burst_radius = 82.0
			score_value = 26
		"chunk_polygon":
			hp = 250.0
			radius = 52.0
			speed = 95.0
			contact_damage = 2
			color = Color(0.87, 0.48, 0.23)
			_phase = "boss_chase"
			_phase_time = 0.0
			active_delay = 0.8
			score_value = 500
			_build_boss_vertices()
		_:
			hp = 8.0
			radius = 15.0
			speed = 120.0
			color = Color(0.95, 0.82, 0.20)
			score_value = 10
	max_hp = hp
	queue_redraw()


func update_enemy(delta: float, player_position: Vector2, pickup_target = null) -> void:
	if _flash_time > 0.0:
		_flash_time -= delta
	if active_delay > 0.0:
		active_delay -= delta
		queue_redraw()
		return

	match kind:
		"pointy_triangle":
			_update_triangle(delta, player_position)
		"smug_square":
			_update_square(delta, player_position)
		"needle_line":
			_update_line(delta, player_position)
		"dizzy_spiral":
			_update_spiral(delta, player_position, pickup_target)
		"chunk_polygon":
			_update_boss(delta, player_position)
		_:
			_update_circle(delta, player_position)

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 780.0 * delta)
	position += knockback_velocity * delta
	position.x = clamp(position.x, radius, arena_size.x - radius)
	position.y = clamp(position.y, radius, arena_size.y - radius)
	queue_redraw()


func is_active() -> bool:
	return active_delay <= 0.0


func get_contact_radius() -> float:
	if kind == "dizzy_spiral" and _phase == "spiral_burst":
		return _spiral_burst_radius
	return radius


func take_damage(amount: float, push_direction: Vector2, push_strength: float) -> bool:
	hp -= amount
	_flash_time = 0.08
	if push_direction.length_squared() > 0.001:
		knockback_velocity += push_direction.normalized() * push_strength
	if kind == "chunk_polygon" and not _boss_drop_gate and hp <= max_hp * 0.45:
		_boss_drop_gate = true
		boss_health_drop.emit(position)
	queue_redraw()
	return hp <= 0.0


func _update_circle(delta: float, player_position: Vector2) -> void:
	_phase_time += delta
	var to_player = (player_position - position).normalized()
	var side = Vector2(-to_player.y, to_player.x) * sin(_phase_time * 3.3 + _wobble_seed) * 0.55
	velocity = (to_player + side).normalized() * speed
	position += velocity * delta


func _update_square(delta: float, player_position: Vector2) -> void:
	var diff = player_position - position
	var dir = Vector2.ZERO
	if abs(diff.x) > abs(diff.y):
		dir.x = sign(diff.x)
	else:
		dir.y = sign(diff.y)
	velocity = dir * speed
	position += velocity * delta


func _update_triangle(delta: float, player_position: Vector2) -> void:
	_phase_time += delta
	if _phase == "aim":
		_charge_dir = (player_position - position).normalized()
		if _charge_dir == Vector2.ZERO:
			_charge_dir = Vector2.RIGHT
		position += _charge_dir * 52.0 * delta
		if _phase_time >= 0.45:
			_phase = "charge"
			_phase_time = 0.0
	elif _phase == "charge":
		position += _charge_dir * speed * delta
		if _phase_time >= 0.62:
			_phase = "recover"
			_phase_time = 0.0
	else:
		position += _charge_dir * 45.0 * delta
		if _phase_time >= 0.35:
			_phase = "aim"
			_phase_time = 0.0


func _update_line(delta: float, player_position: Vector2) -> void:
	_phase_time += delta
	if _phase == "telegraph":
		_charge_dir = (player_position - position).normalized()
		if _charge_dir == Vector2.ZERO:
			_charge_dir = Vector2.RIGHT
		position += _charge_dir * 35.0 * delta
		if _phase_time >= 0.65:
			_phase = "dash"
			_phase_time = 0.0
	elif _phase == "dash":
		position += _charge_dir * speed * delta
		if _phase_time >= 0.32:
			_phase = "recover"
			_phase_time = 0.0
	else:
		position += (player_position - position).normalized() * 55.0 * delta
		if _phase_time >= 0.55:
			_phase = "telegraph"
			_phase_time = 0.0


func _update_spiral(delta: float, player_position: Vector2, pickup_target) -> void:
	_phase_time += delta
	var has_pickup_target = typeof(pickup_target) == TYPE_VECTOR2
	if _phase == "spiral_roam":
		_spiral_spin += delta * 5.2
		var target = pickup_target if has_pickup_target else player_position
		var dir = (target - position).normalized()
		if dir == Vector2.ZERO:
			dir = (player_position - position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT.rotated(_wobble_seed)
		var side = Vector2(-dir.y, dir.x) * sin(_phase_time * 4.1 + _wobble_seed) * 0.38
		velocity = (dir + side).normalized() * speed
		position += velocity * delta
		var near_pickup_cluster = has_pickup_target and position.distance_to(pickup_target) <= _spiral_burst_radius * 0.72
		if near_pickup_cluster or _phase_time >= (2.1 if has_pickup_target else 3.0):
			_phase = "spiral_windup"
			_phase_time = 0.0
			velocity = Vector2.ZERO
	elif _phase == "spiral_windup":
		_spiral_spin += delta * 11.5
		velocity = velocity.move_toward(Vector2.ZERO, 260.0 * delta)
		position += velocity * delta
		if _phase_time >= 0.85:
			_phase = "spiral_burst"
			_phase_time = 0.0
	elif _phase == "spiral_burst":
		_spiral_spin += delta * 8.0
		if _phase_time >= 0.16:
			_phase = "spiral_recover"
			_phase_time = 0.0
	else:
		_spiral_spin += delta * 2.8
		var away = (position - player_position).normalized()
		if away == Vector2.ZERO:
			away = Vector2.RIGHT.rotated(_wobble_seed)
		var wobble = Vector2(-away.y, away.x) * sin(_phase_time * 10.0 + _wobble_seed) * 42.0
		position += (away * 32.0 + wobble) * delta
		if _phase_time >= 0.78:
			_phase = "spiral_roam"
			_phase_time = 0.0


func _update_boss(delta: float, player_position: Vector2) -> void:
	_phase_time += delta
	rotation += delta * (0.45 if _phase == "boss_pause" else 0.18)
	if _phase == "boss_chase":
		position += (player_position - position).normalized() * speed * delta
		if _phase_time >= 5.0:
			_phase = "boss_telegraph"
			_phase_time = 0.0
			_charge_dir = (player_position - position).normalized()
			if _charge_dir == Vector2.ZERO:
				_charge_dir = Vector2.RIGHT
	elif _phase == "boss_telegraph":
		if _phase_time >= 0.78:
			_phase = "boss_slam"
			_phase_time = 0.0
	elif _phase == "boss_slam":
		position += _charge_dir * 360.0 * delta
		if _phase_time >= 0.55:
			_phase = "boss_shed"
			_phase_time = 0.0
			boss_shed.emit(position)
	elif _phase == "boss_shed":
		_phase = "boss_pause"
		_phase_time = 0.0
	else:
		if _phase_time >= 1.0:
			_phase = "boss_chase"
			_phase_time = 0.0


func _draw() -> void:
	var spawn_scale = 1.0
	if active_delay > 0.0:
		spawn_scale = 0.35 + (0.65 * (1.0 - active_delay / (0.8 if kind == "chunk_polygon" else 0.4)))
	var draw_color = Color.WHITE if _flash_time > 0.0 else color
	draw_color.a = 0.45 if active_delay > 0.0 else 1.0
	draw_set_transform(Vector2.ZERO, rotation, Vector2(spawn_scale, spawn_scale))
	match kind:
		"pointy_triangle":
			_draw_triangle(draw_color)
		"smug_square":
			_draw_square(draw_color)
		"needle_line":
			_draw_line_enemy(draw_color)
		"dizzy_spiral":
			_draw_spiral(draw_color)
		"chunk_polygon":
			_draw_boss(draw_color)
		_:
			_draw_circle_enemy(draw_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_circle_enemy(draw_color: Color) -> void:
	draw_circle(Vector2.ZERO, radius, INK)
	draw_circle(Vector2.ZERO, radius - 4.0, draw_color)
	draw_circle(Vector2(4.0, -5.0), 2.2, INK)


func _draw_square(draw_color: Color) -> void:
	var rect = Rect2(Vector2(-radius, -radius), Vector2(radius * 2.0, radius * 2.0))
	draw_rect(rect, INK)
	draw_rect(rect.grow(-4.0), draw_color)
	draw_line(Vector2(-7.0, -4.0), Vector2(7.0, -4.0), INK, 3.0)


func _draw_triangle(draw_color: Color) -> void:
	var angle = _charge_dir.angle() + PI * 0.5
	draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
	var points = PackedVector2Array([
		Vector2(0.0, -radius - 4.0),
		Vector2(radius, radius),
		Vector2(-radius, radius)
	])
	draw_colored_polygon(points, INK)
	draw_colored_polygon(PackedVector2Array([Vector2(0.0, -radius + 2.0), Vector2(radius - 5.0, radius - 3.0), Vector2(-radius + 5.0, radius - 3.0)]), draw_color)
	if _phase == "aim" and active_delay <= 0.0:
		draw_line(Vector2(0.0, -radius - 8.0), Vector2(0.0, -radius - 30.0), Color(INK.r, INK.g, INK.b, 0.55), 3.0)


func _draw_line_enemy(draw_color: Color) -> void:
	var angle = _charge_dir.angle()
	draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
	if _phase == "telegraph" and active_delay <= 0.0:
		draw_line(Vector2(-46.0, 0.0), Vector2(46.0, 0.0), Color(0.57, 0.28, 0.78, 0.35), 8.0)
	draw_rect(Rect2(Vector2(-radius, -5.0), Vector2(radius * 2.0, 10.0)), INK)
	draw_rect(Rect2(Vector2(-radius + 4.0, -2.5), Vector2(radius * 2.0 - 8.0, 5.0)), draw_color)


func _draw_spiral(draw_color: Color) -> void:
	if active_delay <= 0.0 and (_phase == "spiral_windup" or _phase == "spiral_burst"):
		var halo_alpha = 0.16 + 0.06 * sin(_phase_time * 18.0)
		if _phase == "spiral_burst":
			halo_alpha = 0.26
		draw_circle(Vector2.ZERO, _spiral_burst_radius, Color(0.62, 1.0, 0.78, halo_alpha))
		draw_arc(Vector2.ZERO, _spiral_burst_radius, 0.0, TAU, 72, Color(INK.r, INK.g, INK.b, 0.55), 3.0, true)
	var wobble_offset = Vector2.ZERO
	if _phase == "spiral_recover":
		wobble_offset = Vector2(sin(_phase_time * 18.0), cos(_phase_time * 15.0)) * 2.5
	draw_circle(wobble_offset, radius, INK)
	draw_circle(wobble_offset, radius - 4.0, draw_color)
	var points = PackedVector2Array()
	for i in range(28):
		var t = float(i) / 27.0
		var angle = _spiral_spin + t * TAU * 1.85
		var spiral_radius = 3.0 + t * (_spiral_body_radius - 8.0)
		points.append(wobble_offset + Vector2(cos(angle), sin(angle)) * spiral_radius)
	draw_polyline(points, INK, 3.0, true)
	var eye_position = wobble_offset + Vector2(6.5, -5.0).rotated(_spiral_spin * 0.24)
	draw_circle(eye_position, 2.4, INK)


func _draw_boss(draw_color: Color) -> void:
	if _phase == "boss_telegraph" and active_delay <= 0.0:
		draw_set_transform(Vector2.ZERO, _charge_dir.angle(), Vector2.ONE)
		draw_rect(Rect2(Vector2(36.0, -18.0), Vector2(145.0, 36.0)), Color(0.95, 0.23, 0.15, 0.24))
		draw_line(Vector2(36.0, 0.0), Vector2(181.0, 0.0), Color(0.95, 0.23, 0.15, 0.7), 5.0)
		for i in range(4):
			var x = 56.0 + float(i) * 28.0
			draw_line(Vector2(x, -24.0), Vector2(x + 11.0, -13.0), Color(0.07, 0.06, 0.05, 0.45), 2.5)
			draw_line(Vector2(x, 24.0), Vector2(x + 11.0, 13.0), Color(0.07, 0.06, 0.05, 0.45), 2.5)
		draw_set_transform(Vector2.ZERO, rotation, Vector2.ONE)
	draw_colored_polygon(_boss_vertices, INK)
	var inner = PackedVector2Array()
	for p in _boss_vertices:
		inner.append(p * 0.86)
	draw_colored_polygon(inner, draw_color)
	var hp_ratio = clamp(hp / max_hp, 0.0, 1.0)
	draw_arc(Vector2.ZERO, radius + 9.0, -PI * 0.5, -PI * 0.5 + TAU * hp_ratio, 72, Color(0.15, 0.08, 0.04), 5.0, true)


func _build_boss_vertices() -> void:
	_boss_vertices.clear()
	var count = 7
	for i in range(count):
		var a = -PI * 0.5 + TAU * float(i) / float(count)
		var r = radius * (0.82 + 0.24 * abs(sin(float(i) * 1.7 + 0.6)))
		_boss_vertices.append(Vector2(cos(a), sin(a)) * r)
