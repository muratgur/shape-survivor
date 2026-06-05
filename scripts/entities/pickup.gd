extends Node2D

const INK = Color(0.07, 0.06, 0.05)
const PAPER = Color(0.96, 0.91, 0.80)
const TEAL = Color(0.31, 0.84, 0.72)
const ORANGE = Color(0.87, 0.48, 0.23)
const RED = Color(0.91, 0.12, 0.18)

var pickup_kind = "ink"
var value = 1
var radius = 8.0
var magnet_radius = 90.0
var collect_radius = 38.0
var magnet_speed = 420.0
var _bob_time = 0.0
var _birth_time = 0.18
var _birth_duration = 0.18
var _age = 0.0
var _spin = 0.0


func setup(kind: String, start_position: Vector2) -> void:
	pickup_kind = kind
	position = start_position
	_birth_time = _birth_duration
	match pickup_kind:
		"health":
			value = 1
			radius = 12.0
			magnet_radius = 65.0
		"speed_burst", "shield_fragment", "magnet_pulse", "damage_burst":
			value = 0
			radius = 8.0
			magnet_radius = 90.0
		"jittery_fragment":
			value = 0
			radius = 9.0
			magnet_radius = 0.0
		_:
			value = 1
			radius = 7.0
			magnet_radius = 90.0
	queue_redraw()


func update_pickup(delta: float, player: Node2D) -> bool:
	_age += delta
	if pickup_kind != "jittery_fragment":
		_bob_time += delta
	else:
		_spin += min(2.0 * PI + _age * 0.8, 15.0) * delta
	if _birth_time > 0.0:
		_birth_time -= delta
	match pickup_kind:
		"health":
			collect_radius = 28.0
			magnet_radius = 65.0
		"jittery_fragment":
			collect_radius = player.pickup_radius
			magnet_radius = 0.0
		_:
			collect_radius = player.pickup_radius
			magnet_radius = player.magnet_radius
	var distance = position.distance_to(player.position)
	if magnet_radius > 0.0 and distance <= magnet_radius:
		var direction = (player.position - position).normalized()
		position += direction * magnet_speed * delta * (1.0 + (1.0 - distance / max(magnet_radius, 1.0)))
	if position.distance_to(player.position) <= collect_radius:
		return true
	queue_redraw()
	return false


func _draw() -> void:
	var birth_t = 1.0 - clamp(_birth_time / max(_birth_duration, 0.001), 0.0, 1.0)
	var birth_scale = 1.0
	if _birth_time > 0.0:
		birth_scale = 0.70 + sin(birth_t * PI) * 0.38 + birth_t * 0.08
	match pickup_kind:
		"health":
			_draw_health(birth_scale)
		"speed_burst":
			_draw_speed_burst(birth_scale)
		"shield_fragment":
			_draw_shield_fragment(birth_scale)
		"magnet_pulse":
			_draw_magnet_pulse(birth_scale)
		"damage_burst":
			_draw_damage_burst(birth_scale)
		"jittery_fragment":
			_draw_jittery_fragment(birth_scale)
		_:
			_draw_ink(birth_scale)


func _draw_ink(birth_scale: float) -> void:
	var y_offset = sin(_bob_time * 5.0) * 1.8
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(birth_scale, birth_scale))
	draw_circle(Vector2(0.0, y_offset), radius, INK)
	draw_circle(Vector2(2.5, -2.5 + y_offset), 2.1, PAPER)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_health(birth_scale: float) -> void:
	var heartbeat = 1.0 + max(0.0, sin(_bob_time * TAU * 1.5)) * 0.12
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(birth_scale * heartbeat, birth_scale * heartbeat))
	var points = PackedVector2Array([
		Vector2(0.0, 11.0),
		Vector2(-10.5, 1.5),
		Vector2(-11.0, -5.5),
		Vector2(-5.8, -10.0),
		Vector2(-0.8, -6.8),
		Vector2(4.8, -10.0),
		Vector2(11.0, -5.2),
		Vector2(10.0, 2.5)
	])
	draw_colored_polygon(points, INK)
	draw_polyline(_closed_points(points), PAPER, 2.2, true)
	var inner = PackedVector2Array()
	for p in points:
		inner.append(p * 0.62)
	draw_colored_polygon(inner, RED)
	draw_circle(Vector2(3.0, -4.2), 1.7, PAPER)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_speed_burst(birth_scale: float) -> void:
	var x_offset = sin(_bob_time * TAU * 3.0) * 5.0
	draw_set_transform(Vector2(x_offset, 0.0), 0.0, Vector2(birth_scale, birth_scale))
	draw_rect(Rect2(Vector2(-11.0, -3.0), Vector2(20.0, 6.0)), INK)
	draw_rect(Rect2(Vector2(-10.0, -2.0), Vector2(18.0, 4.0)), TEAL)
	draw_circle(Vector2(12.5, 0.0), 5.5, INK)
	draw_circle(Vector2(12.5, 0.0), 3.6, TEAL)
	draw_circle(Vector2(14.0, -1.4), 1.3, PAPER)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_shield_fragment(birth_scale: float) -> void:
	var orbit = Vector2(cos(_bob_time * TAU * 1.35), sin(_bob_time * TAU * 1.35)) * 4.0
	draw_set_transform(orbit, PI * 0.25, Vector2(birth_scale, birth_scale))
	draw_rect(Rect2(Vector2(-9.0, -9.0), Vector2(18.0, 18.0)), INK)
	draw_rect(Rect2(Vector2(-6.0, -6.0), Vector2(12.0, 12.0)), TEAL)
	draw_circle(Vector2(2.5, -3.0), 1.4, PAPER)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_magnet_pulse(birth_scale: float) -> void:
	var y_offset = sin(_bob_time * 5.0) * 1.8
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(birth_scale, birth_scale))
	draw_arc(Vector2(0.0, y_offset), 14.0, 0.0, TAU, 32, INK, 1.6, true)
	draw_arc(Vector2(0.0, y_offset), 10.5, PI * 0.15, PI * 1.65, 24, PAPER, 1.0, true)
	draw_circle(Vector2(0.0, y_offset), 7.0, INK)
	draw_circle(Vector2(2.5, -2.5 + y_offset), 2.1, PAPER)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_damage_burst(birth_scale: float) -> void:
	var pulse = 1.0 + sin(_bob_time * TAU * 3.0) * 0.14
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(birth_scale * pulse, birth_scale * pulse))
	var outer = _star_points(12.0, 6.0, 6)
	draw_colored_polygon(outer, INK)
	var inner = _star_points(8.0, 3.7, 6)
	draw_colored_polygon(inner, ORANGE)
	draw_circle(Vector2(2.3, -2.7), 1.4, PAPER)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_jittery_fragment(birth_scale: float) -> void:
	draw_set_transform(Vector2.ZERO, _spin, Vector2(birth_scale, birth_scale))
	var points = PackedVector2Array([
		Vector2(0.0, -11.0),
		Vector2(10.0, 7.0),
		Vector2(-10.0, 7.0)
	])
	draw_colored_polygon(points, INK)
	var inner = PackedVector2Array([
		Vector2(0.0, -7.0),
		Vector2(6.5, 5.0),
		Vector2(-6.5, 5.0)
	])
	draw_colored_polygon(inner, ORANGE)
	var flicker_alpha = 0.52 + 0.48 * max(0.0, sin(_age * TAU * 4.0))
	draw_circle(Vector2(1.6, -1.6), 1.7, Color(PAPER.r, PAPER.g, PAPER.b, flicker_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed = PackedVector2Array(points)
	if points.size() > 0:
		closed.append(points[0])
	return closed


func _star_points(outer_radius: float, inner_radius: float, point_count: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(point_count * 2):
		var radius_to_use = outer_radius if i % 2 == 0 else inner_radius
		var angle = -PI * 0.5 + TAU * float(i) / float(point_count * 2)
		points.append(Vector2(cos(angle), sin(angle)) * radius_to_use)
	return points
