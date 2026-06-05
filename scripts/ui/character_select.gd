extends Control

signal character_selected(character)
signal codex_requested
signal difficulty_changed(difficulty_id)

const INK = Color(0.07, 0.06, 0.05)
const PAPER = Color(0.96, 0.91, 0.80)
const PAPER_DARK = Color(0.88, 0.80, 0.65)
const ORANGE = Color(0.87, 0.48, 0.23)

var characters = []
var difficulties = []
var selected_index = 0
var selected_difficulty_index = 0
var focus_target = "characters"
var _pulse = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process(true)


func show_select(new_characters: Array, initial_id: String = "balanced_blob", new_difficulties: Array = [], initial_difficulty_id: String = "easy") -> void:
	characters = new_characters.duplicate(true)
	difficulties = new_difficulties.duplicate(true)
	selected_index = 0
	selected_difficulty_index = 0
	for i in range(characters.size()):
		if str(characters[i].get("id", "")) == initial_id:
			selected_index = i
			break
	for i in range(difficulties.size()):
		if str(difficulties[i].get("id", "")) == initial_difficulty_id:
			selected_difficulty_index = i
			break
	focus_target = "characters"
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
		var difficulty_index = _difficulty_index_at(event.position)
		if difficulty_index >= 0:
			focus_target = "difficulty"
			selected_difficulty_index = difficulty_index
		else:
			var index = _card_index_at(event.position)
			if index >= 0:
				focus_target = "characters"
				selected_index = index
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _codex_button_rect().has_point(event.position):
			accept_event()
			codex_requested.emit()
			return
		var difficulty_index = _difficulty_index_at(event.position)
		if difficulty_index >= 0:
			focus_target = "difficulty"
			_set_difficulty_index(difficulty_index)
			return
		var index = _card_index_at(event.position)
		if index >= 0:
			focus_target = "characters"
			selected_index = index
			_select_current()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		if focus_target == "difficulty":
			_set_difficulty_index(max(0, selected_difficulty_index - 1))
		else:
			selected_index = max(0, selected_index - 1)
		queue_redraw()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		if focus_target == "difficulty":
			_set_difficulty_index(min(difficulties.size() - 1, selected_difficulty_index + 1))
		else:
			selected_index = min(characters.size() - 1, selected_index + 1)
		queue_redraw()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		focus_target = "difficulty"
		queue_redraw()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		focus_target = "characters"
		queue_redraw()
	elif event.is_action_pressed("confirm"):
		if focus_target == "difficulty":
			focus_target = "characters"
			queue_redraw()
		else:
			_select_current()
	elif event.is_action_pressed("open_codex"):
		accept_event()
		codex_requested.emit()


func _select_current() -> void:
	if selected_index >= 0 and selected_index < characters.size():
		character_selected.emit(characters[selected_index])


func _set_difficulty_index(index: int) -> void:
	if difficulties.is_empty():
		return
	selected_difficulty_index = clamp(index, 0, difficulties.size() - 1)
	difficulty_changed.emit(str(difficulties[selected_difficulty_index].get("id", "easy")))
	queue_redraw()


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
	draw_string(font, Vector2(viewport_size.x * 0.5 - 330.0, 106.0), "Left/right changes the focused row. Up/down moves between rule and doodle.", HORIZONTAL_ALIGNMENT_CENTER, 660.0, 15, Color(0.07, 0.06, 0.05, 0.68))
	_draw_difficulty_row(font, viewport_size)
	for i in range(characters.size()):
		_draw_card(i, _card_rect(i), characters[i], font)
	_draw_codex_button(font)


func _draw_card(index: int, rect: Rect2, character: Dictionary, font: Font) -> void:
	var selected = index == selected_index and focus_target == "characters"
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
	var starter_id = _safe_starter_id(str(character.get("starter_weapon_id", "volunteer_dot")))
	draw_string(font, card_rect.position + Vector2(14.0, 172.0), name, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 28.0, 22, INK)
	draw_string(font, card_rect.position + Vector2(18.0, 207.0), line, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 36.0, 15, Color(0.07, 0.06, 0.05, 0.86))
	draw_string(font, card_rect.position + Vector2(16.0, 242.0), stats, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 32.0, 16, INK)
	_draw_starter_icon(starter_id, card_rect.position + Vector2(38.0, card_rect.size.y - 47.0), selected)
	draw_string(font, card_rect.position + Vector2(62.0, card_rect.size.y - 39.0), "START: " + _starter_name(starter_id), HORIZONTAL_ALIGNMENT_LEFT, card_rect.size.x - 78.0, 13, Color(0.07, 0.06, 0.05, 0.72))
	if selected:
		draw_string(font, card_rect.position + Vector2(16.0, card_rect.size.y - 14.0), "ENTER / CLICK", HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 32.0, 12, Color(0.07, 0.06, 0.05, 0.58))


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
	var y = max(180.0, viewport_size.y * 0.5 - card_size.y * 0.32)
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


func _draw_difficulty_row(font: Font, viewport_size: Vector2) -> void:
	if difficulties.is_empty():
		return
	var total_width = 640.0
	var start_x = (viewport_size.x - total_width) * 0.5
	var y = 136.0
	for i in range(difficulties.size()):
		var rect = _difficulty_rect(i)
		var selected = i == selected_difficulty_index
		var impossible = str(difficulties[i].get("id", "")) == "impossible"
		var focus = focus_target == "difficulty"
		var alpha = 1.0 if selected else 0.42
		var color = ORANGE if impossible and selected else Color(INK.r, INK.g, INK.b, alpha)
		var offset = Vector2.ZERO
		if impossible and selected:
			var jitter_step = int(_pulse * 12.0) % 4
			var jitter_offsets = [Vector2(-1.0, 0.0), Vector2(1.0, -1.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0)]
			offset = jitter_offsets[jitter_step]
		var label = str(difficulties[i].get("label", "EASY"))
		var descriptor = str(difficulties[i].get("description", ""))
		draw_string(font, rect.position + Vector2(0.0, 22.0) + offset, label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 18 if selected and focus else 16, color)
		draw_string(font, rect.position + Vector2(0.0, 42.0), descriptor, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, Color(0.07, 0.06, 0.05, 0.50 if selected else 0.30))
		if selected:
			var underline_y = y + 28.0
			var line_color = ORANGE if impossible else INK
			if impossible:
				draw_rect(Rect2(Vector2(rect.position.x + 14.0, underline_y - 2.0), Vector2(rect.size.x - 28.0, 6.0)), Color(line_color.r, line_color.g, line_color.b, 0.92))
				draw_line(Vector2(rect.position.x + 19.0, underline_y + 5.0), Vector2(rect.end.x - 17.0, underline_y + 3.0), INK, 2.0)
			else:
				draw_line(Vector2(rect.position.x + 18.0, underline_y), Vector2(rect.end.x - 18.0, underline_y + sin(_pulse * 3.0) * 1.2), line_color, 4.0)
	if focus_target == "difficulty":
		draw_string(font, Vector2(start_x, y + 62.0), "RULE ROW", HORIZONTAL_ALIGNMENT_CENTER, total_width, 11, Color(0.07, 0.06, 0.05, 0.46))


func _difficulty_rect(index: int) -> Rect2:
	var viewport_size = get_viewport_rect().size
	var total_width = 640.0
	var item_width = total_width / max(float(difficulties.size()), 1.0)
	var start_x = (viewport_size.x - total_width) * 0.5
	return Rect2(Vector2(start_x + item_width * float(index), 120.0), Vector2(item_width, 58.0))


func _difficulty_index_at(point: Vector2) -> int:
	for i in range(difficulties.size()):
		if _difficulty_rect(i).has_point(point):
			return i
	return -1


func _codex_button_rect() -> Rect2:
	var viewport_size = get_viewport_rect().size
	return Rect2(Vector2(viewport_size.x - 152.0, 28.0), Vector2(116.0, 34.0))


func _safe_starter_id(starter_id: String) -> String:
	if starter_id in ["volunteer_dot", "panic_pinwheel", "corner_cannon", "dot_swarm", "rude_triangle", "orbit_ruler", "apology_orb"]:
		return starter_id
	return "volunteer_dot"


func _starter_name(starter_id: String) -> String:
	match starter_id:
		"panic_pinwheel":
			return "PANIC PINWHEEL"
		"corner_cannon":
			return "CORNER CANNON"
		"dot_swarm":
			return "DOT SWARM"
		"rude_triangle":
			return "RUDE TRIANGLE"
		"orbit_ruler":
			return "ORBIT RULER"
		"apology_orb":
			return "APOLOGY ORB"
	return "VOLUNTEER DOT"


func _draw_starter_icon(starter_id: String, center: Vector2, selected: bool) -> void:
	var wobble = sin(_pulse * 4.0) * (0.08 if selected else 0.03)
	match starter_id:
		"panic_pinwheel":
			for i in range(4):
				draw_set_transform(center, wobble + TAU * float(i) / 4.0, Vector2.ONE)
				draw_rect(Rect2(Vector2(0.0, -2.4), Vector2(18.0, 4.8)), INK)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"corner_cannon":
			draw_rect(Rect2(center - Vector2(10.0, 10.0), Vector2(20.0, 20.0)), INK)
			draw_rect(Rect2(center - Vector2(6.5, 6.5), Vector2(13.0, 13.0)), Color(0.25, 0.52, 0.91))
		"dot_swarm":
			for i in range(4):
				var p = center + Vector2.RIGHT.rotated(wobble + TAU * float(i) / 4.0) * 11.0
				draw_circle(p, 4.0, INK)
				draw_circle(p, 2.3, Color(0.97, 0.89, 0.24))
		"rude_triangle":
			var points = PackedVector2Array([center + Vector2(0.0, -13.0), center + Vector2(12.0, 10.0), center + Vector2(-12.0, 10.0)])
			draw_colored_polygon(points, INK)
			draw_colored_polygon(PackedVector2Array([center + Vector2(0.0, -8.5), center + Vector2(7.5, 6.5), center + Vector2(-7.5, 6.5)]), Color(0.93, 0.21, 0.16))
		"orbit_ruler":
			draw_set_transform(center, 0.22 + wobble, Vector2.ONE)
			draw_rect(Rect2(Vector2(-16.0, -3.5), Vector2(32.0, 7.0)), INK)
			draw_rect(Rect2(Vector2(-13.0, -1.5), Vector2(26.0, 3.0)), Color(0.66, 0.91, 0.62))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"apology_orb":
			draw_arc(center, 12.0, 0.0, TAU, 28, INK, 2.5, true)
			draw_arc(center, 7.0, 0.0, TAU, 24, Color(0.45, 0.70, 1.0), 2.0, true)
		_:
			draw_circle(center, 10.0, INK)
			draw_circle(center, 6.5, Color(0.98, 0.89, 0.24))
			draw_circle(center + Vector2(2.5, -3.0), 1.3, PAPER)


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed = PackedVector2Array(points)
	if points.size() > 0:
		closed.append(points[0])
	return closed
