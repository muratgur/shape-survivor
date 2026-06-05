extends Control

const INK = Color(0.07, 0.06, 0.05)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _draw() -> void:
	if not visible:
		return
	var viewport_size = get_viewport_rect().size
	var font = get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.07, 0.06, 0.05, 0.38))
	var box = Rect2(viewport_size * 0.5 - Vector2(165.0, 70.0), Vector2(330.0, 140.0))
	draw_rect(box, INK)
	draw_rect(box.grow(-5.0), Color(0.96, 0.91, 0.80))
	draw_string(font, box.position + Vector2(0.0, 55.0), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 28, INK)
	draw_string(font, box.position + Vector2(0.0, 95.0), "Esc resumes. R returns to select.", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 16, Color(0.07, 0.06, 0.05, 0.72))
