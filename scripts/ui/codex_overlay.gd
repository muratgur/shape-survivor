extends Control

signal codex_closed

const CodexRegistry = preload("res://scripts/ui/codex_registry.gd")

const INK = Color(0.07, 0.06, 0.05)
const PAPER = Color(0.96, 0.91, 0.80)
const PAPER_DARK = Color(0.88, 0.80, 0.65)
const TEAL = Color(0.31, 0.84, 0.72)
const ORANGE = Color(0.87, 0.48, 0.23)
const RED = Color(0.91, 0.12, 0.18)
const YELLOW = Color(0.98, 0.89, 0.24)
const BLUE = Color(0.25, 0.52, 0.91)
const PURPLE = Color(0.57, 0.28, 0.78)
const GREEN = Color(0.34, 0.86, 0.56)

var categories: Array = []
var category_index: int = 0
var entry_index: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	categories = CodexRegistry.categories()
	visible = false


func show_codex() -> void:
	category_index = clamp(category_index, 0, max(categories.size() - 1, 0))
	entry_index = clamp(entry_index, 0, max(_entries().size() - 1, 0))
	visible = true
	queue_redraw()


func hide_codex() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	accept_event()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _close_rect().has_point(event.position) or not _book_rect().has_point(event.position):
			_request_close()
			return
		for i in range(categories.size()):
			if _tab_rect(i).has_point(event.position):
				_select_category(i)
				return
		var clicked_entry = _entry_index_at(event.position)
		if clicked_entry >= 0:
			entry_index = clicked_entry
			queue_redraw()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_TAB, KEY_E:
				_select_category((category_index + 1) % max(categories.size(), 1))
				return
			KEY_Q:
				_select_category((category_index - 1 + categories.size()) % max(categories.size(), 1))
				return
			KEY_BACKSPACE:
				_request_close()
				return
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_select_category((category_index + 1) % max(categories.size(), 1))
			return
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_select_category((category_index - 1 + categories.size()) % max(categories.size(), 1))
			return
		if event.button_index == JOY_BUTTON_B:
			_request_close()
			return
	if event.is_action_pressed("pause_game"):
		_request_close()
	elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		entry_index = max(0, entry_index - 1)
		queue_redraw()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		entry_index = min(max(_entries().size() - 1, 0), entry_index + 1)
		queue_redraw()


func _request_close() -> void:
	codex_closed.emit()


func _select_category(index: int) -> void:
	category_index = clamp(index, 0, max(categories.size() - 1, 0))
	entry_index = 0
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var viewport_size = get_viewport_rect().size
	var font = get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, viewport_size), PAPER)
	for x in range(24, int(viewport_size.x), 24):
		for y in range(24, int(viewport_size.y), 24):
			draw_circle(Vector2(float(x), float(y)), 1.0, Color(0.42, 0.36, 0.28, 0.10))
	var book = _book_rect()
	draw_rect(book, INK)
	draw_rect(book.grow(-5.0), Color(0.98, 0.93, 0.76))
	draw_line(Vector2(book.position.x + 388.0, book.position.y + 18.0), Vector2(book.position.x + 388.0, book.end.y - 18.0), Color(0.07, 0.06, 0.05, 0.24), 3.0)
	draw_string(font, book.position + Vector2(26.0, 42.0), "SKETCHBOOK CODEX", HORIZONTAL_ALIGNMENT_LEFT, 340.0, 25, INK)
	draw_string(font, book.position + Vector2(26.0, 67.0), "Observed geometric phenomena.", HORIZONTAL_ALIGNMENT_LEFT, 340.0, 14, Color(0.07, 0.06, 0.05, 0.62))
	_draw_tabs(font)
	_draw_entries(font)
	_draw_detail(font)
	_draw_close(font)


func _draw_tabs(font: Font) -> void:
	for i in range(categories.size()):
		var rect = _tab_rect(i)
		var active = i == category_index
		var fill = INK if active else Color(0.07, 0.06, 0.05, 0.10)
		var text_color = PAPER if active else INK
		draw_rect(rect, fill)
		draw_string(font, rect.position + Vector2(0.0, 17.0), str(categories[i].get("name", "")), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, text_color)


func _draw_entries(font: Font) -> void:
	var entries = _entries()
	for i in range(entries.size()):
		var rect = _entry_rect(i)
		if i == entry_index:
			draw_rect(rect.grow(2.0), Color(0.07, 0.06, 0.05, 0.08))
			draw_line(rect.position + Vector2(0.0, rect.size.y - 2.0), rect.position + Vector2(rect.size.x - 12.0, rect.size.y - 2.0), INK, 2.0)
		draw_string(font, rect.position + Vector2(4.0, 20.0), str(entries[i].get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8.0, 14, INK)


func _draw_detail(font: Font) -> void:
	var entry = _current_entry()
	var book = _book_rect()
	var right = Rect2(book.position + Vector2(420.0, 36.0), Vector2(book.size.x - 456.0, book.size.y - 78.0))
	var icon_center = right.position + Vector2(right.size.x * 0.5, 112.0)
	_draw_icon(str(entry.get("icon", "")), icon_center, 1.0)
	draw_string(font, right.position + Vector2(0.0, 242.0), str(entry.get("name", "UNKNOWN")), HORIZONTAL_ALIGNMENT_CENTER, right.size.x, 28, INK)
	draw_string(font, right.position + Vector2(0.0, 282.0), str(entry.get("observation", "")), HORIZONTAL_ALIGNMENT_CENTER, right.size.x, 18, Color(0.07, 0.06, 0.05, 0.82))
	draw_line(right.position + Vector2(28.0, 308.0), right.position + Vector2(right.size.x - 28.0, 308.0), Color(0.07, 0.06, 0.05, 0.28), 2.0)
	var y = _draw_wrapped(font, "MECHANICAL TRUTH: " + str(entry.get("truth", "")), right.position + Vector2(36.0, 348.0), right.size.x - 72.0, 16, INK, 24.0)
	y = _draw_wrapped(font, "NOTE: " + str(entry.get("note", "")), Vector2(right.position.x + 36.0, y + 16.0), right.size.x - 72.0, 15, Color(0.07, 0.06, 0.05, 0.76), 22.0)
	_draw_wrapped(font, str(entry.get("flavor", "")), Vector2(right.position.x + 36.0, y + 24.0), right.size.x - 72.0, 16, Color(0.07, 0.06, 0.05, 0.58), 23.0)


func _draw_close(font: Font) -> void:
	var rect = _close_rect()
	draw_rect(rect, PAPER)
	draw_rect(rect, INK, false, 2.0)
	draw_string(font, rect.position + Vector2(0.0, 23.0), "CLOSE", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, INK)


func _draw_wrapped(font: Font, text: String, start: Vector2, width: float, size: int, color: Color, line_height: float) -> float:
	var words = text.split(" ")
	var line = ""
	var y = start.y
	for word in words:
		var candidate = word if line == "" else line + " " + word
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x > width and line != "":
			draw_string(font, Vector2(start.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, size, color)
			y += line_height
			line = word
		else:
			line = candidate
	if line != "":
		draw_string(font, Vector2(start.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, size, color)
		y += line_height
	return y


func _draw_icon(icon: String, center: Vector2, scale: float) -> void:
	draw_set_transform(center, 0.0, Vector2(scale, scale))
	match icon:
		"actor_quick_dot":
			draw_circle(Vector2.ZERO, 42.0, Color(INK.r, INK.g, INK.b, 0.14))
			draw_circle(Vector2.ZERO, 34.0, INK)
			draw_circle(Vector2.ZERO, 24.0, Color(0.92, 0.78, 1.0))
			draw_circle(Vector2(-8.0, -6.0), 2.8, INK)
			draw_circle(Vector2(7.0, -6.0), 2.8, INK)
		"actor_sturdy_square", "enemy_smug_square":
			var color = Color(1.0, 0.62, 0.34) if icon == "actor_sturdy_square" else BLUE
			draw_rect(Rect2(Vector2(-42.0, -42.0), Vector2(84.0, 84.0)), INK)
			draw_rect(Rect2(Vector2(-32.0, -32.0), Vector2(64.0, 64.0)), color)
		"actor_fancy_hex":
			_draw_regular_polygon(Vector2.ZERO, 6, 42.0, Color(0.36, 0.92, 0.48), 5.0)
		"actor_timid_triangle", "enemy_pointy_triangle":
			_draw_regular_polygon(Vector2.ZERO, 3, 44.0, Color(0.98, 0.53, 0.75) if icon == "actor_timid_triangle" else Color(0.93, 0.21, 0.16), 5.0)
		"actor_grumpy_wedge":
			var pts = PackedVector2Array([Vector2(43.0, 0.0), Vector2(6.0, -34.0), Vector2(-38.0, -25.0), Vector2(-38.0, 25.0), Vector2(6.0, 34.0)])
			draw_colored_polygon(pts, Color(0.92, 0.72, 0.22))
			draw_polyline(_closed_points(pts), INK, 5.0, true)
		"enemy_wobble_circle", "actor_balanced_blob", "upgrade_blob":
			_draw_wobble_blob(Vector2.ZERO, 42.0, YELLOW if icon == "enemy_wobble_circle" else TEAL)
		"enemy_needle_line":
			draw_set_transform(center, -0.35, Vector2(scale, scale))
			draw_rect(Rect2(Vector2(-54.0, -8.0), Vector2(108.0, 16.0)), INK)
			draw_rect(Rect2(Vector2(-48.0, -4.0), Vector2(96.0, 8.0)), PURPLE)
		"enemy_dizzy_spiral":
			for i in range(4):
				draw_arc(Vector2.ZERO, 14.0 + float(i) * 8.0, 0.3 + float(i) * 0.4, PI * 1.4 + float(i) * 0.4, 36, GREEN if i % 2 == 0 else INK, 4.0, true)
		"enemy_chunk_polygon":
			_draw_regular_polygon(Vector2.ZERO, 7, 54.0, ORANGE, 6.0)
		"weapon_volunteer_dot", "pickup_ink":
			draw_circle(Vector2.ZERO, 34.0, INK)
			draw_circle(Vector2(9.0, -10.0), 5.0, PAPER)
			if icon == "weapon_volunteer_dot":
				draw_circle(Vector2.ZERO, 24.0, YELLOW)
		"weapon_panic_pinwheel", "upgrade_pinwheel":
			for i in range(5):
				draw_set_transform(center, TAU * float(i) / 5.0, Vector2(scale, scale))
				draw_rect(Rect2(Vector2(0.0, -5.0), Vector2(58.0, 10.0)), INK)
			draw_set_transform(center, 0.0, Vector2(scale, scale))
		"weapon_corner_cannon", "upgrade_square":
			draw_rect(Rect2(Vector2(-34.0, -34.0), Vector2(68.0, 68.0)), INK)
			draw_rect(Rect2(Vector2(-25.0, -25.0), Vector2(50.0, 50.0)), BLUE)
		"weapon_dot_swarm":
			for i in range(5):
				var p = Vector2.RIGHT.rotated(TAU * float(i) / 5.0) * 38.0
				draw_circle(p, 10.0, INK)
				draw_circle(p, 6.0, YELLOW)
		"weapon_rude_triangle", "upgrade_triangle":
			_draw_regular_polygon(Vector2.ZERO, 3, 46.0, Color(0.93, 0.21, 0.16), 5.0)
		"weapon_orbit_ruler", "upgrade_ruler":
			draw_set_transform(center, 0.24, Vector2(scale, scale))
			draw_rect(Rect2(Vector2(-56.0, -9.0), Vector2(112.0, 18.0)), INK)
			draw_rect(Rect2(Vector2(-50.0, -4.0), Vector2(100.0, 8.0)), Color(0.66, 0.91, 0.62))
		"weapon_apology_orb", "upgrade_orb", "pickup_magnet_pulse":
			draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 64, INK, 6.0, true)
			draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 64, Color(0.45, 0.70, 1.0), 5.0, true)
		"pickup_health", "upgrade_heart":
			var heart = PackedVector2Array([Vector2(0.0, 38.0), Vector2(-36.0, 5.0), Vector2(-32.0, -22.0), Vector2(-9.0, -34.0), Vector2(0.0, -22.0), Vector2(18.0, -34.0), Vector2(38.0, -20.0), Vector2(34.0, 8.0)])
			draw_colored_polygon(heart, INK)
			draw_polyline(_closed_points(heart), PAPER, 3.0, true)
			draw_colored_polygon(_scaled_points(heart, 0.58), RED)
		"pickup_speed_burst":
			draw_rect(Rect2(Vector2(-45.0, -8.0), Vector2(76.0, 16.0)), INK)
			draw_rect(Rect2(Vector2(-40.0, -4.0), Vector2(68.0, 8.0)), TEAL)
			draw_circle(Vector2(42.0, 0.0), 15.0, INK)
			draw_circle(Vector2(42.0, 0.0), 10.0, TEAL)
		"pickup_shield_fragment":
			draw_set_transform(center, PI * 0.25, Vector2(scale, scale))
			draw_rect(Rect2(Vector2(-32.0, -32.0), Vector2(64.0, 64.0)), INK)
			draw_rect(Rect2(Vector2(-22.0, -22.0), Vector2(44.0, 44.0)), TEAL)
		"pickup_damage_burst":
			var star = _star_points(46.0, 22.0, 6)
			draw_colored_polygon(star, INK)
			draw_colored_polygon(_star_points(31.0, 13.0, 6), ORANGE)
		"pickup_jittery_fragment":
			_draw_regular_polygon(Vector2.ZERO, 3, 46.0, ORANGE, 5.0)
		_:
			draw_circle(Vector2.ZERO, 36.0, INK)
			draw_circle(Vector2.ZERO, 25.0, TEAL)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _book_rect() -> Rect2:
	var viewport_size = get_viewport_rect().size
	var size = Vector2(min(1120.0, viewport_size.x - 72.0), min(680.0, viewport_size.y - 64.0))
	return Rect2((viewport_size - size) * 0.5, size)


func _tab_rect(index: int) -> Rect2:
	var book = _book_rect()
	var tab_width = 67.0
	return Rect2(book.position + Vector2(24.0 + float(index) * (tab_width + 4.0), 92.0), Vector2(tab_width, 24.0))


func _entry_rect(index: int) -> Rect2:
	var book = _book_rect()
	return Rect2(book.position + Vector2(30.0, 134.0 + float(index) * 27.0), Vector2(320.0, 24.0))


func _entry_index_at(point: Vector2) -> int:
	for i in range(_entries().size()):
		if _entry_rect(i).has_point(point):
			return i
	return -1


func _close_rect() -> Rect2:
	var book = _book_rect()
	return Rect2(book.end - Vector2(118.0, 50.0), Vector2(86.0, 32.0))


func _entries() -> Array:
	if categories.is_empty():
		return []
	return categories[category_index].get("entries", [])


func _current_entry() -> Dictionary:
	var entries = _entries()
	if entries.is_empty():
		return {}
	entry_index = clamp(entry_index, 0, entries.size() - 1)
	return entries[entry_index]


func _draw_regular_polygon(center: Vector2, sides: int, radius: float, fill: Color, outline_width: float) -> void:
	var points = PackedVector2Array()
	for i in range(sides):
		var angle = -PI * 0.5 + TAU * float(i) / float(sides)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, INK)
	draw_colored_polygon(_scaled_points(points, 0.78), fill)
	draw_polyline(_closed_points(points), INK, outline_width, true)


func _draw_wobble_blob(center: Vector2, radius: float, fill: Color) -> void:
	var points = PackedVector2Array()
	for i in range(12):
		var angle = -PI * 0.5 + TAU * float(i) / 12.0
		var r = radius * (1.0 + sin(angle * 3.0) * 0.08 + cos(angle * 5.0) * 0.05)
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, fill)
	draw_polyline(_closed_points(points), INK, 5.0, true)


func _scaled_points(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var result = PackedVector2Array()
	for point in points:
		result.append(point * amount)
	return result


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
