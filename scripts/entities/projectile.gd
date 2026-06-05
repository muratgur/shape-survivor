extends Node2D

const INK = Color(0.07, 0.06, 0.05)

var projectile_kind = "dot"
var direction = Vector2.RIGHT
var speed = 420.0
var damage = 5.0
var life = 1.4
var radius = 8.0
var color = Color(0.95, 0.88, 0.20)
var knockback = 120.0
var corner_hit = false


func setup(kind: String, start_position: Vector2, travel_direction: Vector2, projectile_damage: float, projectile_speed: float, projectile_life: float, projectile_radius: float, projectile_color: Color, projectile_knockback: float, is_corner_hit: bool) -> void:
	projectile_kind = kind
	position = start_position
	direction = travel_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	damage = projectile_damage
	speed = projectile_speed
	life = projectile_life
	radius = projectile_radius
	color = projectile_color
	knockback = projectile_knockback
	corner_hit = is_corner_hit
	rotation = direction.angle()
	queue_redraw()


func update_projectile(delta: float) -> bool:
	life -= delta
	position += direction * speed * delta
	queue_redraw()
	return life <= 0.0


func _draw() -> void:
	match projectile_kind:
		"volunteer_dot":
			draw_circle(Vector2.ZERO, radius + 1.5, INK)
			draw_circle(Vector2.ZERO, radius - 2.5, color)
			draw_circle(Vector2(-radius * 0.28, -radius * 0.28), max(1.8, radius * 0.22), Color.WHITE)
		"square":
			var rect = Rect2(Vector2(-radius, -radius), Vector2(radius * 2.0, radius * 2.0))
			draw_rect(rect, INK)
			draw_rect(rect.grow(-3.0), color)
		"triangle":
			var points = PackedVector2Array([
				Vector2(radius + 5.0, 0.0),
				Vector2(-radius, radius),
				Vector2(-radius, -radius)
			])
			draw_colored_polygon(points, INK)
			draw_colored_polygon(PackedVector2Array([Vector2(radius, 0.0), Vector2(-radius + 4.0, radius - 4.0), Vector2(-radius + 4.0, -radius + 4.0)]), color)
		_:
			draw_circle(Vector2.ZERO, radius, INK)
			draw_circle(Vector2.ZERO, radius - 3.0, color)
