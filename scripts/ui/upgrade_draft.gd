extends Control

signal choice_selected(choice)

const INK = Color(0.07, 0.06, 0.05)
const PAPER = Color(0.96, 0.91, 0.80)
const PAPER_DARK = Color(0.88, 0.80, 0.65)

var choices = []
var selected_index = 0
var small_power = false
var wave_number = 1
var _pulse = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process(true)


func show_choices(new_choices: Array, next_wave_number: int, is_small_power: bool) -> void:
	choices = new_choices
	selected_index = 0
	wave_number = next_wave_number
	small_power = is_small_power
	visible = true
	queue_redraw()


func hide_draft() -> void:
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
		var index = _card_index_at(event.position)
		if index >= 0:
			selected_index = index
			_select_current()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		selected_index = max(0, selected_index - 1)
		queue_redraw()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		selected_index = min(choices.size() - 1, selected_index + 1)
		queue_redraw()
	elif event.is_action_pressed("confirm"):
		_select_current()


func _select_current() -> void:
	if selected_index >= 0 and selected_index < choices.size():
		choice_selected.emit(choices[selected_index])


func _draw() -> void:
	if not visible:
		return
	var viewport_size = get_viewport_rect().size
	var font = get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.96, 0.91, 0.80, 0.78))
	draw_string(font, Vector2(viewport_size.x * 0.5 - 210.0, 90.0), "PICK ONE STRANGE IMPROVEMENT", HORIZONTAL_ALIGNMENT_CENTER, 420.0, 24, INK)
	var subtitle = "Ink was shy this wave. One card is smaller." if small_power else "Wave " + str(wave_number) + " is waiting."
	draw_string(font, Vector2(viewport_size.x * 0.5 - 220.0, 118.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, 440.0, 16, Color(0.07, 0.06, 0.05, 0.72))
	for i in range(choices.size()):
		_draw_card(i, _card_rect(i), choices[i], font)


func _draw_card(index: int, rect: Rect2, choice: Dictionary, font: Font) -> void:
	var selected = index == selected_index
	var grow = 7.0 + sin(_pulse * 5.0) * 2.0 if selected else 0.0
	var card_rect = rect.grow(grow)
	draw_rect(card_rect, INK)
	draw_rect(card_rect.grow(-5.0), PAPER if not selected else Color(1.0, 0.94, 0.74))
	draw_rect(card_rect.grow(-16.0), PAPER_DARK, false, 2.0)
	_draw_icon(choice.get("icon", choice.get("id", "")), card_rect.position + Vector2(card_rect.size.x * 0.5, 80.0), selected)
	var name = str(choice.get("name", "UNKNOWN"))
	var effect = str(choice.get("line", "Something changes."))
	var stat = str(choice.get("stat", ""))
	draw_string(font, card_rect.position + Vector2(14.0, 168.0), name, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 28.0, 21, INK)
	draw_string(font, card_rect.position + Vector2(16.0, 202.0), effect, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 32.0, 15, Color(0.07, 0.06, 0.05, 0.88))
	draw_string(font, card_rect.position + Vector2(16.0, 230.0), stat, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 32.0, 16, INK)
	if selected:
		draw_string(font, card_rect.position + Vector2(16.0, card_rect.size.y - 24.0), "ENTER / CLICK", HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x - 32.0, 13, Color(0.07, 0.06, 0.05, 0.64))


func _draw_icon(icon: String, center: Vector2, selected: bool) -> void:
	var wobble = sin(_pulse * 4.0) * (0.08 if selected else 0.03)
	match icon:
		"pinwheel":
			for i in range(5):
				var angle = wobble + TAU * float(i) / 5.0
				draw_set_transform(center, angle, Vector2.ONE)
				draw_rect(Rect2(Vector2(0.0, -5.0), Vector2(54.0, 10.0)), INK)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"volunteer_dot":
			draw_circle(center, 35.0, INK)
			draw_circle(center, 25.0 + sin(_pulse * 5.0) * 2.0, Color(0.98, 0.89, 0.24))
			draw_circle(center + Vector2(-8.0, -8.0), 5.0, Color.WHITE)
		"square":
			draw_rect(Rect2(center - Vector2(34.0, 34.0), Vector2(68.0, 68.0)), INK)
			draw_rect(Rect2(center - Vector2(25.0, 25.0), Vector2(50.0, 50.0)), Color(0.25, 0.52, 0.91))
		"dot":
			for i in range(4):
				var p = center + Vector2.RIGHT.rotated(wobble + TAU * float(i) / 4.0) * 34.0
				draw_circle(p, 11.0, INK)
				draw_circle(p, 7.0, Color(0.97, 0.89, 0.24))
		"triangle":
			var points = PackedVector2Array([center + Vector2(0.0, -42.0), center + Vector2(40.0, 36.0), center + Vector2(-40.0, 36.0)])
			draw_colored_polygon(points, INK)
			draw_colored_polygon(PackedVector2Array([center + Vector2(0.0, -30.0), center + Vector2(28.0, 28.0), center + Vector2(-28.0, 28.0)]), Color(0.93, 0.21, 0.16))
		"ruler":
			draw_set_transform(center, wobble + 0.2, Vector2.ONE)
			draw_rect(Rect2(Vector2(-48.0, -10.0), Vector2(96.0, 20.0)), INK)
			draw_rect(Rect2(Vector2(-42.0, -5.0), Vector2(84.0, 10.0)), Color(0.66, 0.91, 0.62))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"orb":
			draw_arc(center, 38.0 + sin(_pulse * 3.0) * 5.0, 0.0, TAU, 64, INK, 7.0, true)
			draw_arc(center, 24.0, 0.0, TAU, 64, Color(0.45, 0.70, 1.0), 6.0, true)
		"heart":
			var blob = PackedVector2Array([center + Vector2(-32.0, -6.0), center + Vector2(-12.0, -32.0), center + Vector2(20.0, -26.0), center + Vector2(38.0, 2.0), center + Vector2(16.0, 35.0), center + Vector2(-26.0, 29.0), center + Vector2(-42.0, 5.0)])
			draw_colored_polygon(blob, INK)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-23.0, -3.0), center + Vector2(-8.0, -21.0), center + Vector2(14.0, -17.0), center + Vector2(26.0, 2.0), center + Vector2(11.0, 24.0), center + Vector2(-18.0, 20.0), center + Vector2(-28.0, 4.0)]), Color(0.91, 0.12, 0.18))
		_:
			draw_circle(center, 34.0, INK)
			draw_circle(center, 25.0, Color(0.31, 0.84, 0.72))


func _card_rect(index: int) -> Rect2:
	var viewport_size = get_viewport_rect().size
	var card_size = Vector2(245.0, 300.0)
	var gap = 28.0
	var total_width = card_size.x * 3.0 + gap * 2.0
	var start_x = (viewport_size.x - total_width) * 0.5
	var y = max(155.0, viewport_size.y * 0.5 - card_size.y * 0.35)
	return Rect2(Vector2(start_x + float(index) * (card_size.x + gap), y), card_size)


func _card_index_at(point: Vector2) -> int:
	for i in range(choices.size()):
		if _card_rect(i).has_point(point):
			return i
	return -1
