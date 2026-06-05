extends Node2D

var kind = "fragment"
var duration = 0.35
var age = 0.0
var velocity = Vector2.ZERO
var color = Color.BLACK
var size = 10.0
var rotation_speed = 0.0
var data = {}
var follow_target: Node2D = null


func setup_fragment(start_position: Vector2, start_velocity: Vector2, fragment_color: Color, fragment_size: float, fragment_kind: String, fragment_duration: float = 0.35) -> void:
	kind = fragment_kind
	position = start_position
	velocity = start_velocity
	color = fragment_color
	size = fragment_size
	duration = fragment_duration
	rotation_speed = randf_range(-8.0, 8.0)


func setup_attack(attack_kind: String, attack_position: Vector2, attack_duration: float, attack_data: Dictionary, target: Node2D = null) -> void:
	kind = attack_kind
	position = attack_position
	duration = attack_duration
	data = attack_data
	follow_target = target
	color = data.get("color", Color.BLACK)
	size = data.get("size", 32.0)


func update_effect(delta: float) -> bool:
	age += delta
	if is_instance_valid(follow_target):
		position = follow_target.position
	else:
		position += velocity * delta
	rotation += rotation_speed * delta
	queue_redraw()
	return age >= duration


func _draw() -> void:
	var t = clamp(age / max(duration, 0.001), 0.0, 1.0)
	var alpha = 1.0 - t
	match kind:
		"fragment_circle":
			draw_circle(Vector2.ZERO, size * (1.0 - t * 0.45), Color(color.r, color.g, color.b, alpha))
		"fragment_square":
			var half = size * (1.0 - t * 0.45)
			draw_rect(Rect2(Vector2(-half, -half), Vector2(half * 2.0, half * 2.0)), Color(color.r, color.g, color.b, alpha))
		"fragment_triangle":
			var points = PackedVector2Array([
				Vector2(0.0, -size),
				Vector2(size * 0.85, size * 0.75),
				Vector2(-size * 0.85, size * 0.75)
			])
			draw_colored_polygon(points, Color(color.r, color.g, color.b, alpha))
		"pinwheel":
			_draw_pinwheel(t, alpha)
		"wedge":
			_draw_wedge(t, alpha)
		"pulse":
			_draw_pulse(t, alpha)
		"ruler":
			_draw_ruler(t, alpha)
		"volunteer_aim":
			_draw_volunteer_aim(t, alpha)
		"volunteer_trail":
			_draw_volunteer_trail(t, alpha)
		"volunteer_bonk":
			_draw_volunteer_bonk(t, alpha)
		"ink_birth":
			_draw_ink_birth(t, alpha)
		"ink_collect":
			_draw_ink_collect(t, alpha)
		"tremor_warning":
			_draw_tremor_warning(t, alpha)
		_:
			draw_circle(Vector2.ZERO, size, Color(color.r, color.g, color.b, alpha))


func _draw_pinwheel(t: float, alpha: float) -> void:
	var bar_count: int = data.get("bar_count", 4)
	var attack_range: float = data.get("range", 82.0)
	var thickness: float = data.get("thickness", 13.0)
	var base_angle: float = data.get("base_angle", 0.0) + t * 0.9
	var ink = Color(0.07, 0.06, 0.05, alpha)
	var fill = Color(0.98, 0.72, 0.20, alpha * 0.9)
	for i in range(bar_count):
		var angle = base_angle + TAU * float(i) / float(bar_count)
		draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
		draw_rect(Rect2(Vector2(18.0, -thickness * 0.5), Vector2(attack_range, thickness)), ink)
		draw_rect(Rect2(Vector2(21.0, -thickness * 0.32), Vector2(attack_range - 6.0, thickness * 0.64)), fill)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_wedge(t: float, alpha: float) -> void:
	var attack_range: float = data.get("range", 110.0)
	var angle: float = data.get("angle", 0.0)
	var width: float = data.get("width", 0.55)
	var p1 = Vector2.RIGHT.rotated(angle) * (24.0 + attack_range * t * 0.1)
	var p2 = Vector2.RIGHT.rotated(angle + width) * attack_range
	var p3 = Vector2.RIGHT.rotated(angle - width) * attack_range
	var points = PackedVector2Array([p1, p2, p3])
	draw_colored_polygon(points, Color(0.98, 0.38, 0.24, alpha * 0.8))
	draw_polyline(PackedVector2Array([p1, p2, p3, p1]), Color(0.07, 0.06, 0.05, alpha), 4.0)


func _draw_pulse(t: float, alpha: float) -> void:
	var max_radius: float = data.get("radius", 150.0)
	var pulse_radius = lerp(22.0, max_radius, t)
	draw_arc(Vector2.ZERO, pulse_radius, 0.0, TAU, 96, Color(0.07, 0.06, 0.05, alpha), 6.0, true)
	draw_arc(Vector2.ZERO, pulse_radius * 0.82, 0.0, TAU, 96, Color(0.85, 0.93, 1.0, alpha * 0.55), 10.0, true)


func _draw_ruler(t: float, alpha: float) -> void:
	var length: float = data.get("length", 138.0)
	var width: float = data.get("width", 18.0)
	var angle: float = data.get("start_angle", 0.0) + t * TAU * 1.35
	draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
	draw_rect(Rect2(Vector2(28.0, -width * 0.5), Vector2(length, width)), Color(0.07, 0.06, 0.05, alpha))
	draw_rect(Rect2(Vector2(32.0, -width * 0.28), Vector2(length - 8.0, width * 0.56)), Color(0.75, 0.93, 0.72, alpha * 0.85))
	for i in range(5):
		var x = 45.0 + float(i) * 22.0
		draw_line(Vector2(x, -width * 0.35), Vector2(x, width * 0.35), Color(0.07, 0.06, 0.05, alpha), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_volunteer_aim(t: float, alpha: float) -> void:
	var angle: float = data.get("angle", 0.0)
	var dot_radius: float = data.get("radius", 12.0)
	var dir = Vector2.RIGHT.rotated(angle)
	var dot_pos = dir * 34.0
	draw_line(dot_pos - dir * 14.0, dot_pos + dir * 12.0, Color(0.07, 0.06, 0.05, alpha * 0.45), 2.5)
	var squash = 1.0 + sin(t * PI) * 0.22
	draw_set_transform(dot_pos, angle, Vector2(1.0 + squash * 0.12, 0.82 + squash * 0.08))
	draw_circle(Vector2.ZERO, dot_radius * 0.62 + 3.0, Color(0.07, 0.06, 0.05, alpha))
	draw_circle(Vector2.ZERO, dot_radius * 0.62, Color(0.98, 0.89, 0.24, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_volunteer_trail(t: float, alpha: float) -> void:
	var angle: float = data.get("angle", 0.0)
	var dot_radius: float = data.get("radius", 12.0)
	var dir = Vector2.RIGHT.rotated(angle)
	for i in range(4):
		var step = float(i) / 3.0
		var p = -dir * (10.0 + step * 42.0)
		var r = lerp(dot_radius * 0.34, dot_radius * 0.12, step)
		draw_circle(p, r + 1.8, Color(0.07, 0.06, 0.05, alpha * (1.0 - step * 0.6)))
		draw_circle(p, r, Color(0.98, 0.89, 0.24, alpha * (1.0 - step * 0.55)))


func _draw_volunteer_bonk(t: float, alpha: float) -> void:
	var max_radius: float = data.get("radius", 28.0)
	var bonk_radius = lerp(max_radius * 0.35, max_radius, t)
	draw_arc(Vector2.ZERO, bonk_radius, 0.0, TAU, 40, Color(0.07, 0.06, 0.05, alpha), 4.0, true)
	draw_set_transform(Vector2.ZERO, data.get("angle", 0.0), Vector2(1.0 + sin(t * PI) * 0.30, 0.72 + t * 0.28))
	draw_circle(Vector2.ZERO, max_radius * 0.18 * (1.0 - t * 0.25), Color(0.07, 0.06, 0.05, alpha))
	draw_circle(Vector2.ZERO, max_radius * 0.12 * (1.0 - t * 0.30), Color(0.98, 0.89, 0.24, alpha * 0.85))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ink_birth(t: float, alpha: float) -> void:
	var ring_radius = lerp(4.0, 16.0, t)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, Color(0.07, 0.06, 0.05, alpha * 0.70), 2.5, true)
	var shine = max(0.0, 1.0 - t * 1.35)
	draw_circle(Vector2(4.0, -4.0), 2.0 + t * 2.5, Color(1.0, 1.0, 1.0, alpha * shine))


func _draw_ink_collect(t: float, alpha: float) -> void:
	var target: Vector2 = data.get("target", Vector2.ZERO)
	var offset = target - position
	var snap = 1.0 - pow(1.0 - t, 2.0)
	var p = offset * snap
	draw_arc(p, lerp(11.0, 4.0, t), 0.0, TAU, 28, Color(0.07, 0.06, 0.05, alpha * 0.75), 2.5, true)
	if offset.length() <= 92.0 and offset.length() > 10.0:
		draw_line(Vector2.ZERO, offset * min(0.82, snap + 0.12), Color(0.07, 0.06, 0.05, alpha * 0.20), 2.0)
		draw_line(Vector2.ZERO, offset * min(0.70, snap), Color(1.0, 1.0, 1.0, alpha * 0.28), 1.0)


func _draw_tremor_warning(t: float, alpha: float) -> void:
	var angle: float = data.get("angle", 0.0)
	var ink = Color(0.07, 0.06, 0.05, alpha * 0.35)
	var warn = Color(0.87, 0.48, 0.23, alpha * 0.32)
	for i in range(3):
		var local_angle = angle + (float(i) - 1.0) * 0.58
		var dir = Vector2.RIGHT.rotated(local_angle)
		var side = Vector2(-dir.y, dir.x)
		var center = dir * (18.0 + t * 12.0) + side * (float(i) - 1.0) * 9.0
		draw_line(center - side * 8.0, center + side * 8.0, ink, 3.0)
		draw_line(center - side * 5.0, center + side * 5.0, warn, 1.5)
