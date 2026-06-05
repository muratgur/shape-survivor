extends Control

signal resume_requested
signal quit_requested

const INK = Color(0.07, 0.06, 0.05)
const PAPER = Color(0.96, 0.91, 0.80)

var selected_index = 0
var options = ["RESUME", "QUIT TO MENU"]
var option_rects = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	process_mode = PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("pause_game"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("move_up"):
		selected_index = (selected_index - 1 + options.size()) % options.size()
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		selected_index = (selected_index + 1) % options.size()
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_confirm_selection()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			for i in range(option_rects.size()):
				if option_rects[i].has_point(event.position):
					selected_index = i
					_confirm_selection()
					accept_event()
					return


func _process(_delta: float) -> void:
	if not visible:
		return
	
	var mouse_pos = get_local_mouse_position()
	for i in range(option_rects.size()):
		if option_rects[i].has_point(mouse_pos):
			if selected_index != i:
				selected_index = i
				queue_redraw()
			break


func _confirm_selection() -> void:
	if selected_index == 0:
		resume_requested.emit()
	else:
		quit_requested.emit()


func show_overlay() -> void:
	selected_index = 0
	visible = true
	queue_redraw()


func hide_overlay() -> void:
	visible = false


func _draw() -> void:
	if not visible:
		return
		
	var viewport_size = get_viewport_rect().size
	var font = get_theme_default_font()
	
	# Background Dim
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(INK.r, INK.g, INK.b, 0.38))
	
	# Menu Box
	var box_size = Vector2(360.0, 220.0)
	var box = Rect2(viewport_size * 0.5 - box_size * 0.5, box_size)
	draw_rect(box, INK)
	draw_rect(box.grow(-5.0), PAPER)
	
	# Title
	draw_string(font, box.position + Vector2(0.0, 60.0), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 32, INK)
	
	# Options
	option_rects.clear()
	var start_y = box.position.y + 110.0
	var spacing = 50.0
	
	for i in range(options.size()):
		var text = options[i]
		var pos = Vector2(box.position.x, start_y + i * spacing)
		var size = Vector2(box.size.x, 40.0)
		var rect = Rect2(pos, size)
		option_rects.append(rect)
		
		if selected_index == i:
			# Selection Indicator (Underline)
			var text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 24).x
			var line_y = pos.y + 30.0
			var line_x_start = box.position.x + (box.size.x - text_width) * 0.5 - 8.0
			var line_x_end = line_x_start + text_width + 16.0
			
			# Slightly irregular double line
			draw_line(Vector2(line_x_start, line_y), Vector2(line_x_end, line_y), INK, 4.0)
			draw_line(Vector2(line_x_start + 2.0, line_y + 2.5), Vector2(line_x_end - 3.0, line_y + 1.5), INK, 2.0)
		
		draw_string(font, pos + Vector2(0.0, 24.0), text, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 24, INK)
