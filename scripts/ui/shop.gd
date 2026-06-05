extends Control

signal item_purchased(item)
signal shop_closed

const INK = Color(0.07, 0.06, 0.05)
const PAPER = Color(0.96, 0.91, 0.80)
const PAPER_DARK = Color(0.88, 0.80, 0.65)

var shop_items: Array = []
var purchased_ids: Array = []
var ink_balance: int = 0
var selected_index: int = 0
var cleared_wave_number: int = 0
var next_wave_number: int = 0
var _pulse: float = 0.0
var _continue_hover: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process(true)


func show_shop(starting_balance: int, items: Array, cleared_number: int = 0, next_number: int = 0) -> void:
	shop_items = items
	purchased_ids = []
	ink_balance = starting_balance
	selected_index = 0
	cleared_wave_number = cleared_number
	next_wave_number = next_number
	visible = true
	queue_redraw()


func hide_shop() -> void:
	visible = false


func set_balance(amount: int) -> void:
	ink_balance = amount
	queue_redraw()


func _process(delta: float) -> void:
	if visible:
		_pulse += delta
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseMotion:
		var idx = _card_index_at(event.position)
		if idx >= 0:
			selected_index = idx
		_continue_hover = _continue_button_rect().has_point(event.position)
		queue_redraw()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var idx = _card_index_at(event.position)
		if idx >= 0:
			selected_index = idx
			_try_purchase()
			return
		if _continue_button_rect().has_point(event.position):
			_emit_close()
			return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		if not shop_items.is_empty():
			selected_index = max(0, selected_index - 1)
			queue_redraw()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		if not shop_items.is_empty():
			selected_index = min(shop_items.size() - 1, selected_index + 1)
			queue_redraw()
	elif event.is_action_pressed("confirm"):
		_try_purchase()
	elif event.is_action_pressed("pause_game"):
		_emit_close()


func _try_purchase() -> void:
	if selected_index < 0 or selected_index >= shop_items.size():
		return
	var item: Dictionary = shop_items[selected_index]
	var price = int(item.get("price", 0))
	if ink_balance < price:
		return
	ink_balance -= price
	var item_id = str(item.get("id", ""))
	if not purchased_ids.has(item_id):
		purchased_ids.append(item_id)
	item_purchased.emit(item)
	queue_redraw()


func _emit_close() -> void:
	shop_closed.emit()


func _draw() -> void:
	if not visible:
		return
	var viewport_size = get_viewport_rect().size
	var font = get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.96, 0.91, 0.80, 0.92))
	for x in range(40, int(viewport_size.x), 40):
		for y in range(120, int(viewport_size.y - 80), 40):
			draw_circle(Vector2(float(x), float(y)), 1.2, Color(0.42, 0.36, 0.28, 0.10))
	_draw_header(font, viewport_size)
	_draw_ink_counter(font, viewport_size)
	for i in range(shop_items.size()):
		_draw_card(i, _card_rect(i), shop_items[i], font)
	_draw_continue_button(font, viewport_size)


func _draw_header(font: Font, viewport_size: Vector2) -> void:
	var header_rect = Rect2(Vector2(0.0, 0.0), Vector2(viewport_size.x, 78.0))
	draw_rect(header_rect, INK)
	draw_string(font, Vector2(36.0, 46.0), "THINGS THAT SHOWED UP", HORIZONTAL_ALIGNMENT_LEFT, viewport_size.x - 220.0, 24, PAPER)
	var subtitle = "Take what's useful. Leave what isn't."
	if cleared_wave_number > 0 and next_wave_number > 0:
		subtitle = "Wave " + str(cleared_wave_number) + " cleared. Wave " + str(next_wave_number) + " is ready when you are."
	draw_string(font, Vector2(36.0, 108.0), subtitle, HORIZONTAL_ALIGNMENT_LEFT, viewport_size.x - 72.0, 16, Color(0.07, 0.06, 0.05, 0.74))


func _draw_ink_counter(font: Font, viewport_size: Vector2) -> void:
	var center = Vector2(viewport_size.x - 60.0, 40.0)
	var drop = PackedVector2Array([
		center + Vector2(0.0, -16.0),
		center + Vector2(-10.0, 4.0),
		center + Vector2(10.0, 4.0)
	])
	draw_colored_polygon(drop, PAPER)
	draw_circle(center + Vector2(0.0, 4.0), 10.0, PAPER)
	draw_circle(center + Vector2(-3.5, -2.0), 3.0, Color(0.07, 0.06, 0.05, 0.45))
	draw_string(font, Vector2(viewport_size.x - 220.0, 48.0), str(ink_balance) + " INK", HORIZONTAL_ALIGNMENT_RIGHT, 140.0, 22, PAPER)


func _draw_card(index: int, rect: Rect2, item: Dictionary, font: Font) -> void:
	var item_id = str(item.get("id", ""))
	var price = int(item.get("price", 0))
	var affordable = ink_balance >= price
	var already = purchased_ids.has(item_id)
	var selected = index == selected_index
	var grow = 5.0 + sin(_pulse * 5.0) * 1.6 if selected else 0.0
	var card_rect = rect.grow(grow)
	var alpha = 1.0 if affordable else 0.45
	draw_rect(card_rect, Color(INK.r, INK.g, INK.b, alpha))
	var fill = Color(1.0, 0.94, 0.74, alpha) if selected else Color(PAPER_DARK.r, PAPER_DARK.g, PAPER_DARK.b, alpha)
	draw_rect(card_rect.grow(-4.0), fill)
	draw_rect(card_rect.grow(-12.0), Color(INK.r, INK.g, INK.b, 0.35 * alpha), false, 2.0)
	_draw_icon(str(item.get("icon", item_id)), card_rect.position + Vector2(card_rect.size.x * 0.5, 60.0), selected, alpha)
	var item_name = str(item.get("name", "UNKNOWN"))
	var line = "already here" if already else str(item.get("line", "Something changes."))
	draw_string(font, card_rect.position + Vector2(12.0, 148.0), item_name, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 24.0, 18, Color(INK.r, INK.g, INK.b, alpha))
	draw_string(font, card_rect.position + Vector2(14.0, 180.0), line, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 28.0, 14, Color(INK.r, INK.g, INK.b, 0.88 * alpha))
	var badge_size = Vector2(86.0, 30.0)
	var badge_pos = card_rect.position + Vector2(card_rect.size.x - badge_size.x - 10.0, card_rect.size.y - badge_size.y - 10.0)
	draw_rect(Rect2(badge_pos, badge_size), Color(INK.r, INK.g, INK.b, alpha))
	draw_string(font, badge_pos + Vector2(0.0, 22.0), str(price) + " INK", HORIZONTAL_ALIGNMENT_CENTER, badge_size.x, 16, Color(PAPER.r, PAPER.g, PAPER.b, alpha))
	if already:
		var ly = card_rect.position.y + card_rect.size.y * 0.5
		draw_line(Vector2(card_rect.position.x + 16.0, ly), Vector2(card_rect.position.x + card_rect.size.x - 16.0, ly), Color(INK.r, INK.g, INK.b, alpha), 3.0)


func _draw_continue_button(font: Font, viewport_size: Vector2) -> void:
	var button_rect = _continue_button_rect()
	var border_color = INK if not _continue_hover else Color(0.20, 0.16, 0.12)
	draw_rect(button_rect, PAPER)
	draw_rect(button_rect, border_color, false, 3.0)
	draw_string(font, button_rect.position + Vector2(0.0, 36.0), "CONTINUE", HORIZONTAL_ALIGNMENT_CENTER, button_rect.size.x, 22, INK)


func _continue_button_rect() -> Rect2:
	var viewport_size = get_viewport_rect().size
	var button_size = Vector2(220.0, 56.0)
	var button_pos = Vector2((viewport_size.x - button_size.x) * 0.5, viewport_size.y - button_size.y - 36.0)
	return Rect2(button_pos, button_size)


func _draw_icon(icon: String, center: Vector2, selected: bool, alpha: float) -> void:
	var wobble = sin(_pulse * 4.0) * (0.06 if selected else 0.02)
	var ink_a = Color(INK.r, INK.g, INK.b, alpha)
	match icon:
		"pinwheel":
			for i in range(5):
				var angle = wobble + TAU * float(i) / 5.0
				draw_set_transform(center, angle, Vector2.ONE)
				draw_rect(Rect2(Vector2(0.0, -3.5), Vector2(36.0, 7.0)), ink_a)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"volunteer_dot":
			draw_circle(center, 24.0, ink_a)
			draw_circle(center, 17.0 + sin(_pulse * 5.0) * 1.4, Color(0.98, 0.89, 0.24, alpha))
			draw_circle(center + Vector2(-5.0, -5.0), 3.5, Color(1.0, 1.0, 1.0, alpha))
		"square":
			draw_rect(Rect2(center - Vector2(22.0, 22.0), Vector2(44.0, 44.0)), ink_a)
			draw_rect(Rect2(center - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), Color(0.25, 0.52, 0.91, alpha))
		"dot":
			for i in range(4):
				var p = center + Vector2.RIGHT.rotated(wobble + TAU * float(i) / 4.0) * 22.0
				draw_circle(p, 7.5, ink_a)
				draw_circle(p, 4.6, Color(0.97, 0.89, 0.24, alpha))
		"triangle":
			var points = PackedVector2Array([center + Vector2(0.0, -28.0), center + Vector2(26.0, 22.0), center + Vector2(-26.0, 22.0)])
			draw_colored_polygon(points, ink_a)
			var inner = PackedVector2Array([center + Vector2(0.0, -20.0), center + Vector2(18.0, 18.0), center + Vector2(-18.0, 18.0)])
			draw_colored_polygon(inner, Color(0.93, 0.21, 0.16, alpha))
		"ruler":
			draw_set_transform(center, wobble + 0.2, Vector2.ONE)
			draw_rect(Rect2(Vector2(-32.0, -7.0), Vector2(64.0, 14.0)), ink_a)
			draw_rect(Rect2(Vector2(-28.0, -3.5), Vector2(56.0, 7.0)), Color(0.66, 0.91, 0.62, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"orb":
			draw_arc(center, 26.0 + sin(_pulse * 3.0) * 3.0, 0.0, TAU, 64, ink_a, 5.0, true)
			draw_arc(center, 16.0, 0.0, TAU, 64, Color(0.45, 0.70, 1.0, alpha), 4.0, true)
		"heart":
			var blob = PackedVector2Array([center + Vector2(-22.0, -4.0), center + Vector2(-8.0, -22.0), center + Vector2(14.0, -18.0), center + Vector2(26.0, 1.0), center + Vector2(10.0, 24.0), center + Vector2(-18.0, 20.0), center + Vector2(-30.0, 3.0)])
			draw_colored_polygon(blob, ink_a)
			var inner_blob = PackedVector2Array([center + Vector2(-16.0, -2.0), center + Vector2(-5.0, -14.0), center + Vector2(10.0, -11.0), center + Vector2(18.0, 2.0), center + Vector2(7.0, 16.0), center + Vector2(-12.0, 14.0), center + Vector2(-20.0, 3.0)])
			draw_colored_polygon(inner_blob, Color(0.91, 0.12, 0.18, alpha))
		_:
			draw_circle(center, 24.0, ink_a)
			draw_circle(center, 17.0, Color(0.31, 0.84, 0.72, alpha))


func _card_rect(index: int) -> Rect2:
	var viewport_size = get_viewport_rect().size
	var card_size = Vector2(210.0, 265.0)
	var gap = 28.0
	var count = max(shop_items.size(), 1)
	var total_width = card_size.x * float(count) + gap * float(max(count - 1, 0))
	var start_x = (viewport_size.x - total_width) * 0.5
	var y = max(170.0, viewport_size.y * 0.5 - card_size.y * 0.45)
	return Rect2(Vector2(start_x + float(index) * (card_size.x + gap), y), card_size)


func _card_index_at(point: Vector2) -> int:
	for i in range(shop_items.size()):
		if _card_rect(i).has_point(point):
			return i
	return -1
