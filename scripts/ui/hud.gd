extends Control

const INK = Color(0.07, 0.06, 0.05)
const PAPER_LINE = Color(0.48, 0.42, 0.34, 0.38)
const ORANGE = Color(0.87, 0.48, 0.23)

signal pause_clicked

var hp = 5
var max_hp = 5
var time_left = 45.0
var wave_label = "Wave 1/6"
var ink_count = 0
var ink_threshold = 18
var score = 0
var state_note = ""
var shield_charges = 0
var difficulty_label = "EASY"
var difficulty_id = "easy"

var show_pause_button = false
var is_hovering_pause = false
var pause_invert_timer = 0.0
var pause_button: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_pause_button()


func _create_pause_button() -> void:
	pause_button = Control.new()
	pause_button.name = "PauseButton"
	pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.anchor_left = 1.0
	pause_button.anchor_right = 1.0
	pause_button.anchor_top = 0.0
	pause_button.anchor_bottom = 0.0
	pause_button.offset_left = -68
	pause_button.offset_right = -20
	pause_button.offset_top = 20
	pause_button.offset_bottom = 68
	pause_button.mouse_entered.connect(_on_pause_hover.bind(true))
	pause_button.mouse_exited.connect(_on_pause_hover.bind(false))
	pause_button.gui_input.connect(_on_pause_input)
	add_child(pause_button)
	pause_button.visible = false


func _on_pause_hover(hovering: bool) -> void:
	is_hovering_pause = hovering
	queue_redraw()


func _on_pause_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pause_invert_timer = 0.1
		pause_clicked.emit()
		queue_redraw()


func _process(delta: float) -> void:
	if pause_invert_timer > 0.0:
		pause_invert_timer -= delta
		if pause_invert_timer <= 0.0:
			queue_redraw()


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
	difficulty_label = data.get("difficulty_label", difficulty_label)
	difficulty_id = data.get("difficulty_id", difficulty_id)
	show_pause_button = data.get("show_pause_button", false)
	if pause_button:
		pause_button.visible = show_pause_button
	queue_redraw()


func _draw() -> void:
	var viewport_size = get_viewport_rect().size
	var font = get_theme_default_font()
	_draw_health(font)
	_draw_shield_charges(font)
	_draw_timer(font, viewport_size)
	_draw_ink_meter(font, viewport_size)
	_draw_wave_label(font, viewport_size)
	_draw_difficulty_rule(font)
	_draw_pause_button(font, viewport_size)


func _draw_pause_button(font: Font, viewport_size: Vector2) -> void:
	if not show_pause_button:
		return
	
	var rect = Rect2(viewport_size.x - 68, 20, 48, 48)
	var center = rect.get_center()
	var scale = 1.1 if is_hovering_pause else 1.0
	var thickness = 4.0 if is_hovering_pause else 2.0
	
	var draw_ink = INK
	var draw_paper = Color(0.96, 0.91, 0.80)
	
	if pause_invert_timer > 0.0:
		draw_ink = draw_paper
		draw_paper = INK
	
	var frame_rect = Rect2(center - Vector2(20, 20) * scale, Vector2(40, 40) * scale)
	_draw_wobbly_rect(frame_rect, draw_ink, thickness)
	
	var bar_w = 6.0 * scale
	var bar_h = 24.0 * scale
	var spacing = 10.0 * scale
	var bar1_rect = Rect2(center + Vector2(-spacing * 0.5 - bar_w, -bar_h * 0.5), Vector2(bar_w, bar_h))
	var bar2_rect = Rect2(center + Vector2(spacing * 0.5, -bar_h * 0.5), Vector2(bar_w, bar_h))
	
	_draw_wobbly_rect(bar1_rect, draw_ink, 1.0, true, draw_ink)
	_draw_wobbly_rect(bar2_rect, draw_ink, 1.0, true, draw_ink)
	
	if is_hovering_pause:
		draw_string(font, rect.position + Vector2(0, 60), "ESC", HORIZONTAL_ALIGNMENT_CENTER, 48, 12, Color(INK.r, INK.g, INK.b, 0.6))


func _draw_wobbly_rect(rect: Rect2, color: Color, thickness: float, fill: bool = false, fill_color: Color = Color.TRANSPARENT) -> void:
	if fill:
		draw_rect(rect, fill_color)
	
	var p1 = rect.position
	var p2 = Vector2(rect.end.x, rect.position.y)
	var p3 = rect.end
	var p4 = Vector2(rect.position.x, rect.end.y)
	
	var jitter = 1.0
	var points = [p1, p2, p3, p4, p1]
	for i in range(points.size() - 1):
		var start = points[i]
		var end = points[i+1]
		var j_start = start + Vector2(randf_range(-jitter, jitter), randf_range(-jitter, jitter))
		var j_end = end + Vector2(randf_range(-jitter, jitter), randf_range(-jitter, jitter))
		draw_line(j_start, j_end, color, thickness)


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
	draw_string(font, Vector2(viewport_size.x - 378.0, 31.0), wave_label, HORIZONTAL_ALIGNMENT_RIGHT, 290.0, 18, INK)
	draw_string(font, Vector2(viewport_size.x - 378.0, 56.0), "Popped " + str(score), HORIZONTAL_ALIGNMENT_RIGHT, 290.0, 15, Color(0.07, 0.06, 0.05, 0.78))
	if state_note != "":
		draw_string(font, Vector2(viewport_size.x * 0.5 - 180.0, 71.0), state_note, HORIZONTAL_ALIGNMENT_CENTER, 360.0, 15, Color(0.07, 0.06, 0.05, 0.72))


func _draw_difficulty_rule(font: Font) -> void:
	var offset = Vector2.ZERO
	var color = Color(0.07, 0.06, 0.05, 0.54)
	if difficulty_id == "impossible":
		var jitter_step = int(Time.get_ticks_msec() / 90) % 4
		var jitter_offsets = [Vector2(-1.0, 0.0), Vector2(1.0, -1.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0)]
		offset = jitter_offsets[jitter_step]
		color = Color(ORANGE.r, ORANGE.g, ORANGE.b, 0.78)
	draw_string(font, Vector2(24.0, 60.0) + offset, "RULE: " + difficulty_label, HORIZONTAL_ALIGNMENT_LEFT, 220.0, 12, color)
