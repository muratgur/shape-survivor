extends Node2D

const INK = Color(0.07, 0.06, 0.05)

var pickup_kind = "ink"
var value = 1
var radius = 8.0
var magnet_radius = 90.0
var collect_radius = 38.0
var magnet_speed = 420.0
var _bob_time = 0.0
var _birth_time = 0.18
var _birth_duration = 0.18


func setup(kind: String, start_position: Vector2) -> void:
	pickup_kind = kind
	position = start_position
	_birth_time = _birth_duration
	if pickup_kind == "health":
		value = 1
		radius = 12.0
		magnet_radius = 65.0
	else:
		value = 1
		radius = 7.0
		magnet_radius = 90.0
	queue_redraw()


func update_pickup(delta: float, player: Node2D) -> bool:
	_bob_time += delta
	if _birth_time > 0.0:
		_birth_time -= delta
	var distance = position.distance_to(player.position)
	collect_radius = player.pickup_radius if pickup_kind == "ink" else 28.0
	magnet_radius = player.magnet_radius if pickup_kind == "ink" else 65.0
	if distance <= magnet_radius:
		var direction = (player.position - position).normalized()
		position += direction * magnet_speed * delta * (1.0 + (1.0 - distance / max(magnet_radius, 1.0)))
	if position.distance_to(player.position) <= collect_radius:
		return true
	queue_redraw()
	return false


func _draw() -> void:
	var y_offset = sin(_bob_time * 5.0) * 1.8
	var birth_t = 1.0 - clamp(_birth_time / max(_birth_duration, 0.001), 0.0, 1.0)
	var birth_scale = 1.0
	if _birth_time > 0.0:
		birth_scale = 0.70 + sin(birth_t * PI) * 0.38 + birth_t * 0.08
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(birth_scale, birth_scale))
	if pickup_kind == "health":
		var points = PackedVector2Array([
			Vector2(-9.0, -2.0 + y_offset),
			Vector2(-3.0, -10.0 + y_offset),
			Vector2(5.0, -8.0 + y_offset),
			Vector2(11.0, -1.0 + y_offset),
			Vector2(5.0, 9.0 + y_offset),
			Vector2(-7.0, 8.0 + y_offset),
			Vector2(-12.0, 2.0 + y_offset)
		])
		draw_colored_polygon(points, INK)
		var inner = PackedVector2Array()
		for p in points:
			inner.append(Vector2(p.x * 0.74, p.y * 0.74 + y_offset * 0.1))
		draw_colored_polygon(inner, Color(0.91, 0.12, 0.18))
	else:
		draw_circle(Vector2(0.0, y_offset), radius, INK)
		draw_circle(Vector2(2.5, -2.5 + y_offset), 2.1, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
