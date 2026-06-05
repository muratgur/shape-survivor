extends Control

signal character_selected(character)
signal codex_requested

const INK = Color(0.07, 0.06, 0.05)
const PAPER = Color(0.96, 0.91, 0.80)
const PAPER_DARK = Color(0.88, 0.80, 0.65)

var characters = []
var selected_index = 0
var _pulse = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process(true)


func show_select(new_characters: Array, initial_id: String = "balanced_blob") -> void:
	characters = new_characters.duplicate(true)
	selected_index = 0
	for i in range(characters.size()):
		if str(characters[i].get("id", "")) == initial_id:
			selected_index = i
			break
	visible = true
	queue_redraw()


func hide_select() -> void:
	visible = false


func _process(delta: float) -> void:
	if visible:
		_pulse += delta
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseMotion:
		var index = _card_index_at(event.position)
		if index >= 0:
			selected_index = index
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _codex_button_rect().has_point(event.position):
			accept_event()
			codex_requested.emit()
			return
		var index = _card_index_at(event.position)
		if index >= 0:
			selected_index = index
			_select_current()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		selected_index = max(0, selected_index - 1)
		queue_redraw()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		selected_index = min(characters.size() - 1, selected_index + 1)
		queue_redraw()
	elif event.is_action_pressed("confirm"):
		_select_current()
	elif event.is_action_pressed("open_codex"):
		accept_event()
		codex_requested.emit()


func _select_current() -> void:
	if selected_index >= 0 and selected_index < characters.size():
		character_selected.emit(characters[selected_index])


func _draw() -> void:
	if not visible:
		return
	var viewport_size = get_viewport_rect().size
	var font = get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, viewport_size), PAPER)
	for i in range(20):
		var x = fmod(float(i) * 97.0 + 42.0, viewport_size.x)
		draw_line(Vector2(x, 0.0), Vector2(x + 130.0, viewport_size.y), Color(0.48, 0.42, 0.34, 0.07), 2.0)
	draw_string(font, Vector2(viewport_size.x * 0.5 - 260.0, 72.0), "CHOOSE YOUR DOODLE", HORIZONTAL_ALIGNMENT_CENTER, 520.0, 30, INK)
	draw_string(font, Vector2(viewport_size.x * 0.5 - 330.0, 106.0), "Arrow keys, A/D, gamepad, or click. Enter/Space starts. C opens the book.", HORIZONTAL_ALIGNMENT_CENTER, 660.0, 16, Color(0.07, 0.06, 0.05, 0.68))
	for i in range(characters.size()):
		_draw_card(i, _card_rect(i), characters[i], font)
	_draw_codex_button(font)


func _draw_card(index: int, rect: Rect2, character: Dictionary, font: Font) -> void:
	var selected = index == selected_index
	var grow = 8.0 + sin(_pulse * 5.0) * 1.8 if selected else 0.0
	var card_rect = rect.grow(grow)
	draw_rect(card_rect, INK)
	draw_rect(card_rect.grow(-5.0), PAPER if not selected else Color(1.0, 0.94, 0.74))
	draw_rect(card_rect.grow(-16.0), PAPER_DARK, false, 2.0)

	var center = card_rect.position + Vector2(card_rect.size.x * 0.5, 96.0)
	_draw_character_icon(str(character.get("id", "balanced_blob")), center, character.get("color", Color(0.31, 0.84, 0.72)), selected)

	var name = str(character.get("name", "UNKNOWN"))
	var line = str(character.get("line", ""))
	var stats = str(character.get("stat_line", ""))
	draw_string(font, card_rect.position + Vector2(14.0, 172.0), name, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 28.0, 22, INK)
	draw_string(font, card_rect.position + Vector2(18.0, 207.0), line, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 36.0, 15, Color(0.07, 0.06, 0.05, 0.86))
	draw_string(font, card_rect.position + Vector2(16.0, 250.0), stats, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 32.0, 16, INK)
	if selected:
		draw_string(font, card_rect.position + Vector2(16.0, card_rect.size.y - 24.0), "ENTER / CLICK", HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 32.0, 13, Color(0.07, 0.06, 0.05, 0.64))


func _draw_character_icon(character_id: String, center: Vector2, color: Color, selected: bool) -> void:
	var wobble = sin(_pulse * 4.0) * (0.10 if selected else 0.04)
	match character_id:
		"quick_dot":
			for i in range(3):
				var p = center + Vector2(-38.0 - float(i) * 14.0, 22.0 + sin(_pulse * 5.0 + float(i)) * 3.0)
				draw_circle(p, 5.0 - float(i), Color(INK.r, INK.g, INK.b, 0.34))
			draw_circle(center, 38.0, Color(INK.r, INK.g, INK.b, 0.16))
			draw_circle(center + Vector2(sin(_pulse * 8.0) * 2.0, 0.0), 31.0, INK)
			draw_circle(center + Vector2(sin(_pulse * 8.0) * 2.0, 0.0), 22.0, color)
			draw_circle(center + Vector2(-7.0, -5.0), 2.5, INK)
			draw_circle(center + Vector2(6.0, -5.0 + wobble * 5.0), 2.5, INK)
		"sturdy_square":
			var outer = Rect2(center - Vector2(42.0, 42.0), Vector2(84.0, 84.0))
			draw_rect(outer, INK)
			draw_rect(outer.grow(-8.0), color)
			for sx in [-1.0, 1.0]:
				for sy in [-1.0, 1.0]:
					draw_circle(center + Vector2(sx, sy) * 32.0, 6.0, Color(1.0, 0.78, 0.32))
			draw_line(center + Vector2(-15.0, -9.0), center + Vector2(-5.0, -9.0), INK, 3.0)
			draw_line(center + Vector2(6.0, -9.0), center + Vector2(16.0, -9.0), INK, 3.0)
		"fancy_hex":
			var points = PackedVector2Array()
			for i in range(6):
				var a = -PI * 0.5 + TAU * float(i) / 6.0
				var r = 38.0 * (1.0 + sin(_pulse * 2.2 + float(i) * 1.5) * 0.05)
				points.append(center + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(points, color)
			draw_polyline(_closed_points(points), INK, 5.0, true)
			for point in points:
				var p = center + (point - center) * 0.76
				draw_circle(p, 3.0, INK)
				draw_circle(p, 1.6, Color(1.0, 0.95, 0.45))
			draw_circle(center + Vector2(-8.0, -7.0), 3.0, INK)
			draw_circle(center + Vector2(8.0, -7.0 + wobble * 4.0), 3.0, INK)
			draw_line(center + Vector2(-13.0, -15.0), center + Vector2(-3.0, -12.0), INK, 2.5)
			draw_line(center + Vector2(3.0, -12.0), center + Vector2(13.0, -15.0), INK, 2.5)
		"timid_triangle":
			var flinch = Vector2(-1.0, -1.0).normalized() * sin(_pulse * 0.7) * 2.5
			var tri_points = PackedVector2Array()
			for i in range(3):
				var a = -PI * 0.5 + TAU * float(i) / 3.0
				var r = 36.0 * (1.0 + sin(_pulse * 2.0 + float(i)) * 0.04)
				tri_points.append(center + flinch + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(tri_points, color)
			draw_polyline(_closed_points(tri_points), INK, 5.0, true)
			draw_line(center + Vector2(-5.0, -9.0), center + Vector2(-2.0, -8.0), INK, 2.5)
			draw_circle(center + Vector2(4.0, -9.0 + wobble * 5.0), 2.8, INK)
		"grumpy_wedge":
			var icon_r = 36.0
			var lean_x = sin(_pulse * 1.2) * 2.2
			var pts = PackedVector2Array([
				center + Vector2(icon_r * 0.92 + lean_x, 0.0),
				center + Vector2(icon_r * 0.15 + lean_x * 0.5, -icon_r * 0.72),
				center + Vector2(-icon_r * 0.82, -icon_r * 0.52),
				center + Vector2(-icon_r * 0.82, icon_r * 0.52),
				center + Vector2(icon_r * 0.15 + lean_x * 0.5, icon_r * 0.72)
			])
			draw_colored_polygon(pts, color)
			draw_polyline(_closed_points(pts), INK, 5.0, true)
			draw_line(center + Vector2(-9.5, -9.5), center + Vector2(-2.5, -12.0), INK, 2.5)
			draw_line(center + Vector2(2.5, -12.0), center + Vector2(9.5, -9.5), INK, 2.5)
			draw_circle(center + Vector2(-5.5, -6.5), 2.2, INK)
			draw_circle(center + Vector2(5.5, -6.5 + wobble * 3.0), 2.2, INK)
		_:
			var points = PackedVector2Array()
			for i in range(13):
				var a = -PI * 0.5 + TAU * float(i) / 13.0
				var r = 35.0 * (1.0 + sin(a * 3.0 + _pulse * 3.0) * 0.08 + cos(a * 5.0) * 0.05)
				points.append(center + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(points, color)
			draw_polyline(_closed_points(points), INK, 5.0, true)
			draw_circle(center + Vector2(-10.0, -5.0), 3.0, INK)
			draw_circle(center + Vector2(8.0, -4.0 + wobble * 5.0), 3.0, INK)


func _card_rect(index: int) -> Rect2:
	var viewport_size = get_viewport_rect().size
	var count = max(characters.size(), 1)
	var gap = 22.0 if count >= 4 else 30.0
	var available_width = max(360.0, viewport_size.x - 120.0)
	var card_width = min(255.0, (available_width - gap * float(count - 1)) / float(count))
	var card_size = Vector2(card_width, 330.0)
	var total_width = card_size.x * float(count) + gap * float(count - 1)
	var start_x = (viewport_size.x - total_width) * 0.5
	var y = max(148.0, viewport_size.y * 0.5 - card_size.y * 0.36)
	return Rect2(Vector2(start_x + float(index) * (card_size.x + gap), y), card_size)


func _card_index_at(point: Vector2) -> int:
	for i in range(characters.size()):
		if _card_rect(i).has_point(point):
			return i
	return -1


func _draw_codex_button(font: Font) -> void:
	var rect = _codex_button_rect()
	draw_rect(rect, PAPER)
	draw_rect(rect, INK, false, 2.0)
	draw_string(font, rect.position + Vector2(0.0, 24.0), "CODEX  C", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, INK)


func _codex_button_rect() -> Rect2:
	var viewport_size = get_viewport_rect().size
	return Rect2(Vector2(viewport_size.x - 152.0, 28.0), Vector2(116.0, 34.0))


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed = PackedVector2Array(points)
	if points.size() > 0:
		closed.append(points[0])
	return closed
