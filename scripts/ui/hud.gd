extends Control

const INK = Color(0.07, 0.06, 0.05)
const PAPER_LINE = Color(0.48, 0.42, 0.34, 0.38)

var hp = 5
var max_hp = 5
var time_left = 45.0
var wave_label = "Wave 1/6"
var ink_count = 0
var ink_threshold = 18
var score = 0
var state_note = ""
var shield_charges = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func update_hud(data: Dictionary) -> void:
	hp = data.get("hp", hp)
	max_hp = data.get("max_hp", max_hp)
	time_left = data.get("time_left", time_left)
	wave_label = data.get("wave_label", wave_label)
	ink_count = data.get("ink_count", ink_count)
	ink_threshold = data.get("ink_threshold", ink_threshold)
	score = data.get("score", score)
	state_note = data.get("state_note", state_note)
	shield_charges = data.get("shield_charges", shield_charges)
	queue_redraw()


func _draw() -> void:
	var viewport_size = get_viewport_rect().size
	var font = get_theme_default_font()
	_draw_health(font)
	_draw_shield_charges(font)
	_draw_timer(font, viewport_size)
	_draw_ink_meter(font, viewport_size)
	_draw_wave_label(font, viewport_size)


func _draw_shield_charges(font: Font) -> void:
	if shield_charges <= 0:
		return
	var origin_x = 68.0 + float(max_hp) * 28.0 + 14.0
	var y = 27.0
	for i in range(3):
		var cx = origin_x + float(i) * 14.0
		var filled = i < shield_charges
		var diamond = PackedVector2Array([
			Vector2(cx, y - 7.0),
			Vector2(cx + 6.0, y),
			Vector2(cx, y + 7.0),
			Vector2(cx - 6.0, y)
		])
		draw_colored_polygon(diamond, INK)
		var inner = PackedVector2Array()
		for p in diamond:
			inner.append(Vector2(cx, y) + (p - Vector2(cx, y)) * 0.62)
		draw_colored_polygon(inner, Color(0.31, 0.84, 0.72) if filled else Color(0.96, 0.91, 0.80))


func _draw_health(font: Font) -> void:
	draw_string(font, Vector2(24.0, 31.0), "HP", HORIZONTAL_ALIGNMENT_LEFT, 80.0, 18, INK)
	for i in range(max_hp):
		var x = 68.0 + float(i) * 28.0
		var filled = i < hp
		var points = PackedVector2Array([
			Vector2(x - 8.0, 25.0),
			Vector2(x - 2.0, 17.0),
			Vector2(x + 7.0, 19.0),
			Vector2(x + 11.0, 27.0),
			Vector2(x + 4.0, 36.0),
			Vector2(x - 7.0, 34.0),
			Vector2(x - 12.0, 29.0)
		])
		draw_colored_polygon(points, INK)
		var inner = PackedVector2Array()
		for p in points:
			inner.append(Vector2(x, 27.0) + (p - Vector2(x, 27.0)) * 0.70)
		draw_colored_polygon(inner, Color(0.92, 0.13, 0.18) if filled else Color(0.96, 0.91, 0.80))


func _draw_timer(font: Font, viewport_size: Vector2) -> void:
	var center = Vector2(viewport_size.x * 0.5, 36.0)
	var seconds = max(0, int(ceil(time_left)))
	draw_arc(center, 30.0, PI, TAU * 2.0, 48, PAPER_LINE, 4.0, true)
	draw_string(font, center + Vector2(-55.0, 8.0), str(seconds), HORIZONTAL_ALIGNMENT_CENTER, 110.0, 28, INK)


func _draw_ink_meter(font: Font, viewport_size: Vector2) -> void:
	var width = min(520.0, viewport_size.x - 220.0)
	var origin = Vector2((viewport_size.x - width) * 0.5, viewport_size.y - 38.0)
	var has_threshold = ink_threshold > 0
	var fill = clamp(float(ink_count) / max(float(ink_threshold), 1.0), 0.0, 1.0) if has_threshold else 0.0
	var label = "INK " + str(ink_count) + "/" + str(ink_threshold) if has_threshold else "INK " + str(ink_count)
	draw_line(origin, origin + Vector2(width, 0.0), Color(0.07, 0.06, 0.05, 0.28), 10.0, true)
	draw_line(origin, origin + Vector2(width * fill, 0.0), INK, 10.0, true)
	draw_circle(origin + Vector2(width * fill, 0.0), 8.0, INK)
	draw_string(font, origin + Vector2(0.0, -10.0), label, HORIZONTAL_ALIGNMENT_CENTER, width, 16, INK)


func _draw_wave_label(font: Font, viewport_size: Vector2) -> void:
	draw_string(font, Vector2(viewport_size.x - 320.0, 31.0), wave_label, HORIZONTAL_ALIGNMENT_RIGHT, 290.0, 18, INK)
	draw_string(font, Vector2(viewport_size.x - 320.0, 56.0), "Popped " + str(score), HORIZONTAL_ALIGNMENT_RIGHT, 290.0, 15, Color(0.07, 0.06, 0.05, 0.78))
	if state_note != "":
		draw_string(font, Vector2(viewport_size.x * 0.5 - 180.0, 71.0), state_note, HORIZONTAL_ALIGNMENT_CENTER, 360.0, 15, Color(0.07, 0.06, 0.05, 0.72))
