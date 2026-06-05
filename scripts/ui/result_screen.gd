extends Control

const INK = Color(0.07, 0.06, 0.05)
const PAPER = Color(0.96, 0.91, 0.80)

var result_data = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func show_result(data: Dictionary) -> void:
	result_data = data
	visible = true
	queue_redraw()


func hide_result() -> void:
	visible = false


func _draw() -> void:
	if not visible:
		return
	var viewport_size = get_viewport_rect().size
	var font = get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, viewport_size), PAPER)
	for i in range(18):
		var x = fmod(float(i) * 91.0 + 33.0, viewport_size.x)
		draw_line(Vector2(x, 0.0), Vector2(x + 140.0, viewport_size.y), Color(0.48, 0.42, 0.34, 0.08), 2.0)
	var won = bool(result_data.get("won", false))
	var title = "Still Technically A Shape" if won else "Flattened Into A Lesson"
	draw_string(font, Vector2(viewport_size.x * 0.5 - 300.0, 160.0), title, HORIZONTAL_ALIGNMENT_CENTER, 600.0, 34, INK)
	var rows = [
		"Survived: " + _format_time(float(result_data.get("survived_time", 0.0))),
		"Waves cleared: " + str(result_data.get("waves_cleared", 0)),
		"Shapes popped: " + str(result_data.get("enemies_popped", 0)),
		"Ink gathered: " + str(result_data.get("ink_total", 0)),
		"Upgrades chosen: " + str(result_data.get("upgrades_chosen", 0))
	]
	for i in range(rows.size()):
		draw_string(font, Vector2(viewport_size.x * 0.5 - 180.0, 230.0 + float(i) * 34.0), rows[i], HORIZONTAL_ALIGNMENT_CENTER, 360.0, 20, INK)
	draw_string(font, Vector2(viewport_size.x * 0.5 - 240.0, viewport_size.y - 110.0), "Press R or Enter for character select", HORIZONTAL_ALIGNMENT_CENTER, 480.0, 20, Color(0.07, 0.06, 0.05, 0.72))


func _format_time(seconds: float) -> String:
	var total = int(max(seconds, 0.0))
	return str(total / 60) + ":" + str(total % 60).pad_zeros(2)
