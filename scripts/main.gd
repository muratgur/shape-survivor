extends Node2D

const ARENA_SIZE = Vector2(1600.0, 900.0)
const PAPER = Color(0.96, 0.91, 0.80)
const PAPER_DOT = Color(0.42, 0.36, 0.28, 0.16)
const INK = Color(0.07, 0.06, 0.05)

const PlayerScene = preload("res://scripts/entities/player.gd")
const EnemyScene = preload("res://scripts/entities/enemy.gd")
const ProjectileScene = preload("res://scripts/entities/projectile.gd")
const PickupScene = preload("res://scripts/entities/pickup.gd")
const EffectScene = preload("res://scripts/entities/effect.gd")
const CharacterSelectScene = preload("res://scripts/ui/character_select.gd")
const HudScene = preload("res://scripts/ui/hud.gd")
const UpgradeDraftScene = preload("res://scripts/ui/upgrade_draft.gd")
const ResultScreenScene = preload("res://scripts/ui/result_screen.gd")
const PauseOverlayScene = preload("res://scripts/ui/pause_overlay.gd")
const ShopScene = preload("res://scripts/ui/shop.gd")

enum GameState { SELECT, COMBAT, DRAFT, RESULT, PAUSED, SHOP }

var rng = RandomNumberGenerator.new()
var camera: Camera2D
var pickups_container: Node2D
var enemies_container: Node2D
var projectiles_container: Node2D
var effects_container: Node2D
var player
var character_select
var hud
var upgrade_draft
var result_screen
var pause_overlay
var shop

var game_state = GameState.SELECT
var previous_state = GameState.SELECT
var character_roster = []
var selected_character_id = "balanced_blob"
var waves = []
var upgrade_pool = []
var current_wave_index = 0
var wave_time_left = 45.0
var spawn_timer = 0.0
var weapons = {}
var active_sweeps = []
var pending_volunteer_shots = []
var enemies = []
var projectiles = []
var pickups = []
var effects = []

var ink_this_wave = 0
var ink_total = 0
var ink_bank = 0
var score = 0
var enemies_popped = 0
var upgrades_chosen = 0
var waves_cleared = 0
var survived_time = 0.0
var base_damage_multiplier = 1.0
var side_bonus_per_extra_side = 0.0
var camera_base_position = ARENA_SIZE * 0.5
var camera_shake_time = 0.0
var camera_shake_duration = 0.0
var camera_shake_amplitude = 0.0
var camera_shake_direction = Vector2.RIGHT


func _ready() -> void:
	rng.randomize()
	_register_default_inputs()
	_build_character_roster()
	_build_wave_data()
	_build_upgrade_pool()
	_create_scene_graph()
	_show_character_select()
	queue_redraw()


func _process(delta: float) -> void:
	_update_camera_shake(delta)
	match game_state:
		GameState.COMBAT:
			_update_combat(delta)
		GameState.RESULT:
			_update_effects(delta)
		GameState.PAUSED:
			pass
		_:
			_update_effects(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
			if game_state == GameState.COMBAT:
				_pause_game()
			elif game_state == GameState.PAUSED:
				_resume_game()
	elif event.is_action_pressed("restart"):
		if game_state == GameState.RESULT or game_state == GameState.PAUSED:
			_show_character_select()
	elif game_state == GameState.RESULT and event.is_action_pressed("confirm"):
		_show_character_select()


func _create_scene_graph() -> void:
	camera = Camera2D.new()
	camera.name = "ArenaCamera"
	camera_base_position = ARENA_SIZE * 0.5
	camera.position = camera_base_position
	add_child(camera)
	camera.make_current()
	_update_camera_zoom()
	get_viewport().size_changed.connect(_update_camera_zoom)

	pickups_container = Node2D.new()
	pickups_container.name = "Pickups"
	add_child(pickups_container)
	enemies_container = Node2D.new()
	enemies_container.name = "Enemies"
	add_child(enemies_container)
	projectiles_container = Node2D.new()
	projectiles_container.name = "Projectiles"
	add_child(projectiles_container)
	effects_container = Node2D.new()
	effects_container.name = "Effects"
	add_child(effects_container)

	player = PlayerScene.new()
	player.name = "Player"
	player.arena_size = ARENA_SIZE
	player.died.connect(_on_player_died)
	add_child(player)
	player.visible = false

	var ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	add_child(ui_layer)

	character_select = CharacterSelectScene.new()
	character_select.name = "CharacterSelect"
	character_select.set_anchors_preset(Control.PRESET_FULL_RECT)
	character_select.character_selected.connect(_on_character_selected)
	ui_layer.add_child(character_select)

	hud = HudScene.new()
	hud.name = "HUD"
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(hud)

	upgrade_draft = UpgradeDraftScene.new()
	upgrade_draft.name = "UpgradeDraft"
	upgrade_draft.set_anchors_preset(Control.PRESET_FULL_RECT)
	upgrade_draft.choice_selected.connect(_on_upgrade_selected)
	ui_layer.add_child(upgrade_draft)

	result_screen = ResultScreenScene.new()
	result_screen.name = "ResultScreen"
	result_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(result_screen)

	pause_overlay = PauseOverlayScene.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(pause_overlay)

	shop = ShopScene.new()
	shop.name = "Shop"
	shop.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop.item_purchased.connect(_on_shop_item_purchased)
	shop.shop_closed.connect(_on_shop_closed)
	ui_layer.add_child(shop)


func _update_camera_zoom() -> void:
	if not is_instance_valid(camera):
		return
	var viewport_size = get_viewport_rect().size
	var zoom = min(viewport_size.x / ARENA_SIZE.x, viewport_size.y / ARENA_SIZE.y)
	camera.zoom = Vector2(zoom, zoom)


func _start_camera_shake(source_position: Vector2) -> void:
	var direction = (player.position - source_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	camera_shake_direction = direction
	camera_shake_duration = 0.10
	camera_shake_time = camera_shake_duration
	camera_shake_amplitude = 5.5


func _update_camera_shake(delta: float) -> void:
	if not is_instance_valid(camera):
		return
	if camera_shake_time <= 0.0:
		camera.position = camera_base_position
		return
	camera_shake_time = max(0.0, camera_shake_time - delta)
	var t = camera_shake_time / max(camera_shake_duration, 0.001)
	var side = Vector2(-camera_shake_direction.y, camera_shake_direction.x)
	var offset = camera_shake_direction * sin(t * TAU * 2.0) * camera_shake_amplitude * t
	offset += side * cos(t * TAU * 3.0) * camera_shake_amplitude * 0.42 * t
	camera.position = camera_base_position + offset


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, ARENA_SIZE), PAPER)
	for x in range(40, int(ARENA_SIZE.x), 40):
		for y in range(40, int(ARENA_SIZE.y), 40):
			draw_circle(Vector2(float(x), float(y)), 1.5, PAPER_DOT)
	draw_line(Vector2(92.0, 0.0), Vector2(92.0, ARENA_SIZE.y), Color(0.72, 0.22, 0.20, 0.22), 3.0)
	draw_line(Vector2(0.0, 78.0), Vector2(ARENA_SIZE.x, 78.0), Color(0.22, 0.32, 0.62, 0.15), 2.0)
	draw_rect(Rect2(Vector2.ZERO, ARENA_SIZE), INK, false, 8.0)


func _show_character_select() -> void:
	_clear_all_runtime_nodes()
	game_state = GameState.SELECT
	previous_state = GameState.SELECT
	result_screen.hide_result()
	upgrade_draft.hide_draft()
	shop.hide_shop()
	pause_overlay.visible = false
	hud.visible = false
	player.visible = false
	character_select.show_select(character_roster, selected_character_id)


func _start_run(character_id: String = "") -> void:
	_clear_all_runtime_nodes()
	game_state = GameState.COMBAT
	previous_state = GameState.COMBAT
	if character_id != "":
		selected_character_id = character_id
	result_screen.hide_result()
	upgrade_draft.hide_draft()
	shop.hide_shop()
	character_select.hide_select()
	pause_overlay.visible = false
	hud.visible = true
	player.visible = true

	player.reset(ARENA_SIZE * 0.5, _character_by_id(selected_character_id))
	base_damage_multiplier = 1.0
	side_bonus_per_extra_side = 0.0
	weapons = {
		"volunteer_dot": {"level": 1, "timer": 0.30}
	}
	active_sweeps.clear()
	pending_volunteer_shots.clear()
	ink_this_wave = 0
	ink_total = 0
	ink_bank = 0
	score = 0
	enemies_popped = 0
	upgrades_chosen = 0
	waves_cleared = 0
	survived_time = 0.0
	_refresh_player_damage_multiplier()
	_refresh_weapon_visuals()
	_start_wave(0)


func _clear_all_runtime_nodes() -> void:
	for list in [enemies, projectiles, pickups, effects]:
		for node in list.duplicate():
			if is_instance_valid(node):
				node.queue_free()
		list.clear()
	active_sweeps.clear()
	pending_volunteer_shots.clear()
	if is_instance_valid(enemies_container):
		for child in enemies_container.get_children():
			child.queue_free()
	if is_instance_valid(projectiles_container):
		for child in projectiles_container.get_children():
			child.queue_free()
	if is_instance_valid(pickups_container):
		for child in pickups_container.get_children():
			child.queue_free()
	if is_instance_valid(effects_container):
		for child in effects_container.get_children():
			child.queue_free()


func _start_wave(index: int) -> void:
	current_wave_index = index
	var wave = waves[current_wave_index]
	wave_time_left = float(wave["duration"])
	spawn_timer = 0.75
	ink_this_wave = 0
	game_state = GameState.COMBAT
	hud.visible = true
	if bool(wave.get("boss", false)):
		_spawn_enemy("chunk_polygon", ARENA_SIZE * 0.5 + Vector2(0.0, -245.0))
	_update_hud()


func _update_combat(delta: float) -> void:
	survived_time += delta
	wave_time_left -= delta
	player.update_player(delta, true)
	_update_weapons(delta)
	_update_pending_volunteer_shots(delta)
	_update_active_sweeps(delta)
	_update_projectiles(delta)
	_update_enemies(delta)
	_update_pickups(delta)
	_update_effects(delta)
	_check_contact_damage()
	_update_spawning(delta)

	if bool(waves[current_wave_index].get("boss", false)):
		if wave_time_left <= 0.0:
			_finish_run(true)
	else:
		if wave_time_left <= 0.0:
			_complete_regular_wave()
	_update_hud()


func _update_spawning(delta: float) -> void:
	var wave = waves[current_wave_index]
	if _regular_enemy_count() >= 80:
		return
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	if not _wave_allows_spawn(wave):
		return
	spawn_timer = float(wave["spawn_rate"])
	var mix: Array = wave["mix"]
	if mix.is_empty():
		return
	var spawned = _spawn_enemy(str(mix[rng.randi_range(0, mix.size() - 1)]))
	if spawned != null and str(wave.get("spawn_pattern", "steady")) == "pulse":
		_spawn_attack_effect("tremor_warning", 0.18, {"position": spawned.position, "angle": (player.position - spawned.position).angle()})


func _update_enemies(delta: float) -> void:
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			enemies.erase(enemy)
			continue
		var pickup_target = null
		if enemy.kind == "dizzy_spiral":
			pickup_target = _best_ink_pickup_cluster_target(enemy.position)
		enemy.update_enemy(delta, player.position, pickup_target)


func _update_projectiles(delta: float) -> void:
	for projectile in projectiles.duplicate():
		if not is_instance_valid(projectile):
			projectiles.erase(projectile)
			continue
		var expired = projectile.update_projectile(delta)
		if expired or not Rect2(Vector2(-120.0, -120.0), ARENA_SIZE + Vector2(240.0, 240.0)).has_point(projectile.position):
			_remove_projectile(projectile)
			continue
		for enemy in enemies.duplicate():
			if not is_instance_valid(enemy) or not enemy.is_active():
				continue
			if projectile.position.distance_to(enemy.position) <= projectile.radius + enemy.radius:
				var hit_position = enemy.position - projectile.direction * enemy.radius
				_damage_enemy(enemy, projectile.damage, projectile.position, projectile.knockback, projectile.corner_hit)
				if projectile.projectile_kind == "volunteer_dot":
					_spawn_attack_effect("volunteer_bonk", 0.16, {"position": hit_position, "radius": projectile.radius * 2.0, "color": projectile.color, "angle": projectile.direction.angle()})
					_spawn_directed_hit_fragments(hit_position, projectile.direction, Color(0.07, 0.06, 0.05), 1, 0.16)
				_remove_projectile(projectile)
				break


func _update_pickups(delta: float) -> void:
	for pickup in pickups.duplicate():
		if not is_instance_valid(pickup):
			pickups.erase(pickup)
			continue
		if pickup.update_pickup(delta, player):
			var collect_position = pickup.position
			if pickup.pickup_kind == "health":
				player.heal(pickup.value)
			else:
				ink_this_wave += pickup.value
				ink_total += pickup.value
				ink_bank += pickup.value
				_spawn_attack_effect("ink_collect", 0.12, {"position": collect_position, "target": player.position})
			pickups.erase(pickup)
			pickup.queue_free()


func _update_effects(delta: float) -> void:
	for effect in effects.duplicate():
		if not is_instance_valid(effect):
			effects.erase(effect)
			continue
		if effect.update_effect(delta):
			effects.erase(effect)
			effect.queue_free()


func _check_contact_damage() -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_active():
			continue
		var enemy_contact_radius = enemy.radius
		if enemy.has_method("get_contact_radius"):
			enemy_contact_radius = enemy.get_contact_radius()
		if player.position.distance_to(enemy.position) <= player.radius + enemy_contact_radius:
			var did_hit: bool = player.take_damage(enemy.contact_damage, enemy.position)
			if did_hit:
				var away = (player.position - enemy.position).normalized()
				_spawn_directed_hit_fragments(player.position, away, Color.WHITE, 4, 0.20)
				_start_camera_shake(enemy.position)


func _update_weapons(delta: float) -> void:
	if _nearest_enemy() == null:
		return
	for weapon_id in weapons.keys():
		var weapon: Dictionary = weapons[weapon_id]
		weapon["timer"] = float(weapon.get("timer", 0.0)) - delta
		if float(weapon["timer"]) <= 0.0:
			var fired = _fire_weapon(weapon_id, int(weapon.get("level", 1)))
			if fired:
				weapon["timer"] = _weapon_cooldown(weapon_id)
			else:
				weapon["timer"] = 0.0


func _fire_weapon(weapon_id: String, level: int) -> bool:
	match weapon_id:
		"volunteer_dot":
			return _fire_volunteer_dot(level)
		"panic_pinwheel":
			_fire_panic_pinwheel(level)
			return true
		"corner_cannon":
			_fire_corner_cannon(level)
			return true
		"dot_swarm":
			return _fire_dot_swarm(level)
		"rude_triangle":
			return _fire_rude_triangle(level)
		"orbit_ruler":
			_fire_orbit_ruler(level)
			return true
		"apology_orb":
			_fire_apology_orb(level)
			return true
	return false


func _weapon_cooldown(weapon_id: String) -> float:
	var base = {
		"volunteer_dot": 0.80,
		"panic_pinwheel": 1.00,
		"corner_cannon": 1.20,
		"dot_swarm": 1.60,
		"rude_triangle": 1.40,
		"orbit_ruler": 2.40,
		"apology_orb": 3.20
	}
	return float(base.get(weapon_id, 1.0)) * player.cooldown_multiplier


func _fire_volunteer_dot(level: int) -> bool:
	var target = _nearest_enemy()
	if target == null:
		return false
	var dir = (target.position - player.position).normalized()
	if dir == Vector2.ZERO:
		return false
	var projectile_radius = (12.0 + floor(float(max(0, level - 1)) / 2.0)) * player.weapon_size_multiplier
	pending_volunteer_shots.append({
		"age": 0.0,
		"duration": 0.18,
		"direction": dir,
		"level": level,
		"radius": projectile_radius
	})
	_spawn_attack_effect("volunteer_aim", 0.18, {"angle": dir.angle(), "radius": projectile_radius}, player)
	return true


func _fire_panic_pinwheel(level: int) -> void:
	var bar_count = 4 + max(0, level - 1)
	var attack_range = 76.0 * player.weapon_size_multiplier
	var base_angle = survived_time * 2.3
	_spawn_attack_effect("pinwheel", 0.18, {"bar_count": bar_count, "range": attack_range, "thickness": 14.0, "base_angle": base_angle}, player)
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or not enemy.is_active():
			continue
		var offset = enemy.position - player.position
		var distance = offset.length()
		if distance > attack_range + enemy.radius + player.radius:
			continue
		var hit = false
		for i in range(bar_count):
			var angle = base_angle + TAU * float(i) / float(bar_count)
			var diff = abs(angle_difference(angle, offset.angle()))
			if diff <= 0.34:
				hit = true
				break
		if hit:
			_damage_enemy(enemy, 4.0, player.position, 95.0, false)


func _fire_corner_cannon(level: int) -> void:
	var damage = 8.0 + float(level - 1) * 2.0
	var dirs = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	for dir in dirs:
		_spawn_projectile("square", player.position + dir * 28.0, dir, damage, 430.0, 1.5, 10.0 * player.weapon_size_multiplier, Color(0.25, 0.52, 0.91), 150.0, true)


func _fire_dot_swarm(level: int) -> bool:
	var count = 3 + max(0, level - 1)
	var targets = _nearest_enemies(count)
	if targets.is_empty():
		return false
	for i in range(count):
		var angle = TAU * float(i) / float(count) + survived_time
		var dir = Vector2.RIGHT.rotated(angle)
		if i < targets.size() and is_instance_valid(targets[i]):
			dir = (targets[i].position - player.position).normalized()
		_spawn_projectile("dot", player.position + Vector2.RIGHT.rotated(angle) * 38.0, dir, 5.0, 470.0, 1.35, 7.5 * player.weapon_size_multiplier, Color(0.97, 0.89, 0.24), 100.0, false)
	return true


func _fire_rude_triangle(level: int) -> bool:
	var target = _nearest_enemy(260.0)
	if target == null:
		return false
	var dir = (target.position - player.position).normalized()
	var angle = dir.angle()
	var attack_range = (108.0 + float(level - 1) * 22.0) * player.weapon_size_multiplier
	_spawn_attack_effect("wedge", 0.16, {"angle": angle, "range": attack_range, "width": 0.50}, player)
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or not enemy.is_active():
			continue
		var offset = enemy.position - player.position
		if offset.length() <= attack_range + enemy.radius and abs(angle_difference(angle, offset.angle())) <= 0.52:
			_damage_enemy(enemy, 10.0, player.position, 210.0, true)
	return true


func _fire_orbit_ruler(level: int) -> void:
	var duration = 0.9 * (1.0 + float(level - 1) * 0.15)
	var length = 128.0 * player.weapon_size_multiplier
	var width = 18.0 * player.weapon_size_multiplier
	var start_angle = survived_time * 1.2
	active_sweeps.append({
		"age": 0.0,
		"duration": duration,
		"length": length,
		"width": width,
		"damage": 3.0,
		"start_angle": start_angle,
		"hit_timers": {}
	})
	_spawn_attack_effect("ruler", duration, {"length": length, "width": width, "start_angle": start_angle}, player)


func _fire_apology_orb(level: int) -> void:
	var pulse_radius = (145.0 + float(level - 1) * 28.0) * player.weapon_size_multiplier
	_spawn_attack_effect("pulse", 0.42, {"radius": pulse_radius}, player)
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or not enemy.is_active():
			continue
		var distance = enemy.position.distance_to(player.position)
		if distance <= pulse_radius + enemy.radius:
			_damage_enemy(enemy, 6.0, player.position, 330.0, false)


func _update_pending_volunteer_shots(delta: float) -> void:
	for shot in pending_volunteer_shots.duplicate():
		shot["age"] = float(shot.get("age", 0.0)) + delta
		if float(shot["age"]) >= float(shot.get("duration", 0.18)):
			_spawn_volunteer_dot_projectile(shot)
			pending_volunteer_shots.erase(shot)


func _spawn_volunteer_dot_projectile(shot: Dictionary) -> void:
	var dir: Vector2 = shot.get("direction", Vector2.RIGHT)
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var level = int(shot.get("level", 1))
	var projectile_radius = float(shot.get("radius", 12.0))
	var damage = 8.0 + float(max(0, level - 1)) * 2.0
	var start_position = player.position + dir * (player.radius + projectile_radius + 4.0)
	_spawn_attack_effect("volunteer_trail", 0.16, {"position": start_position, "angle": dir.angle(), "radius": projectile_radius})
	_spawn_projectile("volunteer_dot", start_position, dir, damage, 560.0, 0.86, projectile_radius, Color(0.98, 0.89, 0.24), 120.0, false)


func _update_active_sweeps(delta: float) -> void:
	for sweep in active_sweeps.duplicate():
		sweep["age"] = float(sweep["age"]) + delta
		var hit_timers: Dictionary = sweep["hit_timers"]
		for key in hit_timers.keys():
			hit_timers[key] = float(hit_timers[key]) - delta
			if float(hit_timers[key]) <= 0.0:
				hit_timers.erase(key)
		var t = clamp(float(sweep["age"]) / max(float(sweep["duration"]), 0.001), 0.0, 1.0)
		var angle = float(sweep["start_angle"]) + t * TAU * 1.35
		var dir = Vector2.RIGHT.rotated(angle)
		var a = player.position + dir * 28.0
		var b = player.position + dir * (28.0 + float(sweep["length"]))
		for enemy in enemies.duplicate():
			if not is_instance_valid(enemy) or not enemy.is_active():
				continue
			var key = enemy.get_instance_id()
			if hit_timers.has(key):
				continue
			if _distance_to_segment(enemy.position, a, b) <= enemy.radius + float(sweep["width"]) * 0.5:
				hit_timers[key] = 0.18
				_damage_enemy(enemy, float(sweep["damage"]), player.position, 115.0, true)
		if float(sweep["age"]) >= float(sweep["duration"]):
			active_sweeps.erase(sweep)


func _spawn_enemy(kind: String, start_position: Vector2 = Vector2(-100000.0, -100000.0)):
	if kind != "chunk_polygon" and _regular_enemy_count() >= 80:
		return null
	var spawn_position = start_position
	if spawn_position.x < -90000.0:
		spawn_position = _pick_spawn_position()
	var enemy = EnemyScene.new()
	enemy.setup(kind, spawn_position, player.position, ARENA_SIZE)
	enemies_container.add_child(enemy)
	enemies.append(enemy)
	if kind == "chunk_polygon":
		enemy.boss_shed.connect(_on_boss_shed)
		enemy.boss_health_drop.connect(_on_boss_health_drop)
	return enemy


func _pick_spawn_position() -> Vector2:
	for i in range(16):
		var side = rng.randi_range(0, 3)
		var pos = Vector2.ZERO
		match side:
			0:
				pos = Vector2(rng.randf_range(60.0, ARENA_SIZE.x - 60.0), 28.0)
			1:
				pos = Vector2(ARENA_SIZE.x - 28.0, rng.randf_range(60.0, ARENA_SIZE.y - 60.0))
			2:
				pos = Vector2(rng.randf_range(60.0, ARENA_SIZE.x - 60.0), ARENA_SIZE.y - 28.0)
			_:
				pos = Vector2(28.0, rng.randf_range(60.0, ARENA_SIZE.y - 60.0))
		if pos.distance_to(player.position) >= 220.0:
			return pos
	var fallback = ARENA_SIZE - player.position
	fallback.x = clamp(fallback.x, 40.0, ARENA_SIZE.x - 40.0)
	fallback.y = clamp(fallback.y, 40.0, ARENA_SIZE.y - 40.0)
	return fallback


func _best_ink_pickup_cluster_target(enemy_position: Vector2):
	var best_position = null
	var best_score = -999999.0
	for pickup in pickups:
		if not is_instance_valid(pickup) or pickup.pickup_kind != "ink":
			continue
		var cluster_count = 0
		for other in pickups:
			if not is_instance_valid(other) or other.pickup_kind != "ink":
				continue
			if pickup.position.distance_to(other.position) <= 96.0:
				cluster_count += 1
		var distance = pickup.position.distance_to(enemy_position)
		if distance > 520.0 and cluster_count <= 1:
			continue
		var score = float(cluster_count) * 145.0 - distance
		if score > best_score:
			best_score = score
			best_position = pickup.position
	return best_position


func _spawn_projectile(kind: String, start_position: Vector2, direction: Vector2, damage: float, speed: float, life: float, radius: float, color: Color, knockback: float, corner_hit: bool) -> void:
	var projectile = ProjectileScene.new()
	projectile.setup(kind, start_position, direction, damage, speed, life, radius, color, knockback, corner_hit)
	projectiles_container.add_child(projectile)
	projectiles.append(projectile)


func _spawn_pickup(kind: String, pickup_position: Vector2) -> void:
	var pickup = PickupScene.new()
	pickup.setup(kind, pickup_position)
	pickups_container.add_child(pickup)
	pickups.append(pickup)
	if kind == "ink":
		_spawn_attack_effect("ink_birth", 0.18, {"position": pickup_position})


func _spawn_attack_effect(kind: String, duration: float, data: Dictionary, target = null) -> void:
	var effect = EffectScene.new()
	effect.setup_attack(kind, player.position if target != null else data.get("position", Vector2.ZERO), duration, data, target)
	effects_container.add_child(effect)
	effects.append(effect)


func _spawn_fragments(source, count: int = 5) -> void:
	var fragment_color: Color = source.color
	for i in range(count):
		var effect = EffectScene.new()
		var dir = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
		var kind_options = ["fragment_circle", "fragment_square", "fragment_triangle"]
		effect.setup_fragment(source.position + dir * rng.randf_range(2.0, 10.0), dir * rng.randf_range(80.0, 210.0), fragment_color, rng.randf_range(4.0, 9.0), kind_options[rng.randi_range(0, kind_options.size() - 1)])
		effects_container.add_child(effect)
		effects.append(effect)


func _spawn_hit_fragments(source_position: Vector2, fragment_color: Color, count: int) -> void:
	for i in range(count):
		var effect = EffectScene.new()
		var dir = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
		effect.setup_fragment(source_position + dir * 8.0, dir * rng.randf_range(90.0, 170.0), fragment_color, rng.randf_range(3.0, 6.0), "fragment_circle")
		effects_container.add_child(effect)
		effects.append(effect)


func _spawn_directed_hit_fragments(source_position: Vector2, base_direction: Vector2, fragment_color: Color, count: int, duration: float) -> void:
	var direction = base_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
	for i in range(count):
		var effect = EffectScene.new()
		var dir = direction.rotated(rng.randf_range(-0.55, 0.55))
		effect.setup_fragment(source_position + dir * rng.randf_range(4.0, 9.0), dir * rng.randf_range(105.0, 185.0), fragment_color, rng.randf_range(2.6, 5.2), "fragment_square", duration)
		effects_container.add_child(effect)
		effects.append(effect)


func _damage_enemy(enemy, raw_damage: float, source_position: Vector2, knockback: float, corner_hit: bool) -> void:
	if not is_instance_valid(enemy):
		return
	var final_damage = raw_damage * player.damage_multiplier
	if corner_hit and player.corner_bonus_enabled:
		final_damage *= 1.30
	var push_direction = enemy.position - source_position
	var died: bool = enemy.take_damage(final_damage, push_direction, knockback * player.knockback_multiplier)
	if died:
		_kill_enemy(enemy, true)


func _kill_enemy(enemy, reward: bool) -> void:
	if not is_instance_valid(enemy):
		return
	var was_boss = enemy.kind == "chunk_polygon"
	_spawn_fragments(enemy, 9 if was_boss else rng.randi_range(3, 6))
	if reward:
		score += enemy.score_value
		enemies_popped += 1
		if was_boss:
			for i in range(12):
				_spawn_pickup("ink", enemy.position + Vector2.RIGHT.rotated(TAU * float(i) / 12.0) * rng.randf_range(12.0, 44.0))
		else:
			var drop_count = int(round(float(waves[current_wave_index].get("drop_rate", 1.0))))
			for i in range(drop_count):
				_spawn_pickup("ink", enemy.position + Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-8.0, 8.0)))
			if player.hp < player.max_hp and rng.randf() < 0.05:
				_spawn_pickup("health", enemy.position + Vector2(rng.randf_range(-16.0, 16.0), rng.randf_range(-16.0, 16.0)))
	enemies.erase(enemy)
	enemy.queue_free()
	if was_boss and reward:
		_finish_run(true)


func _remove_projectile(projectile) -> void:
	if is_instance_valid(projectile):
		projectiles.erase(projectile)
		projectile.queue_free()


func _complete_regular_wave() -> void:
	waves_cleared = max(waves_cleared, current_wave_index + 1)
	_clear_enemies_without_rewards()
	if bool(waves[current_wave_index].get("has_shop", false)):
		game_state = GameState.SHOP
		shop.show_shop(ink_bank, _build_shop_offers(), current_wave_index + 1, min(current_wave_index + 2, waves.size()))
		_update_hud("SHOP")
		return
	_begin_post_wave_draft()


func _begin_post_wave_draft() -> void:
	if not bool(waves[current_wave_index].get("draft_after", true)):
		_start_wave(min(current_wave_index + 1, waves.size() - 1))
		return
	var threshold = int(waves[current_wave_index]["threshold"])
	var small_power = ink_this_wave < threshold
	var choices = _build_draft_choices(small_power)
	var next_wave_number = min(current_wave_index + 2, waves.size())
	game_state = GameState.DRAFT
	upgrade_draft.show_choices(choices, next_wave_number, small_power)
	_update_hud("CHOOSE")


func _on_shop_item_purchased(item: Dictionary) -> void:
	var price = int(item.get("price", 0))
	if ink_bank < price:
		return
	ink_bank = max(0, ink_bank - price)
	upgrades_chosen += 1
	_apply_upgrade(item)
	_refresh_player_damage_multiplier()
	_refresh_weapon_visuals()
	shop.set_balance(ink_bank)


func _on_shop_closed() -> void:
	shop.hide_shop()
	_begin_post_wave_draft()


func _build_shop_offers() -> Array:
	var pool = _shop_pool()
	pool.shuffle()
	return pool.slice(0, min(3, pool.size()))


func _shop_pool() -> Array:
	return [
		{"id": "corner_cannon",      "name": "CORNER CANNON",      "line": "Squares leave in four directions.",   "price": 22, "icon": "square"},
		{"id": "dot_swarm",          "name": "DOT SWARM",          "line": "Dots orbit, then abandon you.",       "price": 22, "icon": "dot"},
		{"id": "rude_triangle",      "name": "RUDE TRIANGLE",      "line": "A wedge interrupts someone.",         "price": 20, "icon": "triangle"},
		{"id": "orbit_ruler",        "name": "ORBIT RULER",        "line": "A rectangle sweeps the room.",        "price": 26, "icon": "ruler"},
		{"id": "volunteer_dot_plus", "name": "VOLUNTEER DOT+",     "line": "The anxious dot practices bonking.",  "price": 14, "icon": "volunteer_dot"},
		{"id": "meaner_corners",     "name": "MEANER CORNERS",     "line": "Your outline gets judgmental.",       "price": 16, "icon": "triangle"},
		{"id": "bigger_scribble",    "name": "BIGGER SCRIBBLE",    "line": "Weapons draw wider trouble.",         "price": 12, "icon": "blob"},
		{"id": "faster_panic",       "name": "FASTER PANIC",       "line": "Everything fires less politely.",     "price": 14, "icon": "pinwheel"},
		{"id": "blunt_corner",       "name": "BLUNT CORNER",       "line": "Hits without finesse. Still counts.", "price": 10, "icon": "triangle"},
		{"id": "comfy_blob",         "name": "COMFY BLOB",         "line": "A spare lobe appears.",               "price": 16, "icon": "heart"},
		{"id": "helpful_blob",       "name": "HELPFUL BLOB",       "line": "Heals one. That's it.",               "price": 8,  "icon": "heart"},
		{"id": "rough_draft_hp",     "name": "ROUGH DRAFT HP",     "line": "More room on the line.",              "price": 10, "icon": "blob"},
		{"id": "scoot_marks",        "name": "SCOOT MARKS",        "line": "The blob leaves nervous dashes.",     "price": 12, "icon": "blob"},
		{"id": "anxious_zigzag",     "name": "ANXIOUS ZIGZAG",     "line": "Faster when things get crowded.",     "price": 14, "icon": "blob"},
		{"id": "pocket_magnet",      "name": "POCKET MAGNET",      "line": "Ink drops get clingy.",               "price": 16, "icon": "orb"},
		{"id": "side_hustle",        "name": "SIDE HUSTLE",        "line": "More sides, more opinions.",          "price": 18, "icon": "blob"},
		{"id": "corner_applause",    "name": "CORNER APPLAUSE",    "line": "Sharp hits get cheers.",              "price": 18, "icon": "square"},
		{"id": "apology_orb",        "name": "APOLOGY ORB",        "line": "A soft pulse says move.",             "price": 24, "icon": "orb"}
	]


func _clear_enemies_without_rewards() -> void:
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy):
			_spawn_fragments(enemy, 3)
			enemy.queue_free()
	enemies.clear()
	active_sweeps.clear()
	for projectile in projectiles.duplicate():
		_remove_projectile(projectile)


func _finish_run(won: bool) -> void:
	if game_state == GameState.RESULT:
		return
	game_state = GameState.RESULT
	hud.visible = false
	upgrade_draft.hide_draft()
	shop.hide_shop()
	pause_overlay.visible = false
	if won:
		waves_cleared = waves.size()
	_clear_enemies_without_rewards()
	result_screen.show_result({
		"won": won,
		"survived_time": survived_time,
		"waves_cleared": waves_cleared,
		"enemies_popped": enemies_popped,
		"ink_total": ink_total,
		"upgrades_chosen": upgrades_chosen
	})


func _pause_game() -> void:
	previous_state = game_state
	game_state = GameState.PAUSED
	pause_overlay.visible = true
	pause_overlay.queue_redraw()


func _resume_game() -> void:
	game_state = previous_state
	pause_overlay.visible = false


func _on_player_died() -> void:
	_spawn_hit_fragments(player.position, Color(0.31, 0.84, 0.72), 10)
	_finish_run(false)


func _on_character_selected(character: Dictionary) -> void:
	_start_run(str(character.get("id", "balanced_blob")))


func _on_upgrade_selected(choice: Dictionary) -> void:
	upgrades_chosen += 1
	_apply_upgrade(choice)
	upgrade_draft.hide_draft()
	_refresh_player_damage_multiplier()
	_refresh_weapon_visuals()
	_start_wave(min(current_wave_index + 1, waves.size() - 1))


func _on_boss_shed(source_position: Vector2) -> void:
	var spawn_circles = rng.randf() < 0.65
	var count = 4 if spawn_circles else 2
	var kind = "wobble_circle" if spawn_circles else "smug_square"
	for i in range(count):
		var offset = Vector2.RIGHT.rotated(TAU * float(i) / float(count) + rng.randf_range(-0.2, 0.2)) * rng.randf_range(42.0, 72.0)
		_spawn_enemy(kind, source_position + offset)
	for i in range(5):
		_spawn_pickup("ink", source_position + Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(18.0, 54.0))
	if player.hp <= 2:
		_spawn_pickup("health", source_position + Vector2(0.0, 58.0))


func _on_boss_health_drop(source_position: Vector2) -> void:
	if player.hp <= 2:
		_spawn_pickup("health", source_position)


func _apply_upgrade(choice: Dictionary) -> void:
	var id = str(choice.get("id", ""))
	var small = bool(choice.get("small", false))
	var scale = 0.65 if small else 1.0
	match id:
		"bigger_scribble":
			player.weapon_size_multiplier += 0.20 * scale
			player.add_visual_tag("outline_pulse")
		"faster_panic":
			player.cooldown_multiplier = max(0.60, player.cooldown_multiplier - 0.12 * scale)
			player.add_visual_tag("orbit_ticks")
		"meaner_corners":
			base_damage_multiplier += 0.15 * scale
			player.add_visual_tag("corner_nubs", 2)
		"comfy_blob":
			player.max_hp += 1
			player.heal(1)
			player.add_visual_tag("soft_lobe")
		"pocket_magnet":
			player.pickup_radius = min(180.0, player.pickup_radius * (1.0 + 0.35 * scale))
			player.magnet_radius = min(220.0, player.magnet_radius * (1.0 + 0.20 * scale))
			player.add_visual_tag("magnet_ring")
		"side_hustle":
			player.side_count += 1
			side_bonus_per_extra_side += 0.05
			player.add_visual_tag("corner_nubs", 1)
		"corner_applause":
			player.corner_bonus_enabled = true
			player.add_visual_tag("corner_nubs", 3)
		"volunteer_dot_plus":
			_upgrade_weapon("volunteer_dot")
		"corner_cannon", "dot_swarm", "rude_triangle", "orbit_ruler", "apology_orb", "panic_pinwheel":
			_upgrade_weapon(id)
			if id == "apology_orb":
				player.add_visual_tag("pulse_ring")
			elif id == "orbit_ruler":
				player.add_visual_tag("ruler_halo")
			elif id == "panic_pinwheel":
				player.add_visual_tag("orbit_ticks")
		"scoot_marks":
			player.move_speed *= 1.0 + 0.12 * scale
		"very_serious_rectangle":
			player.knockback_multiplier *= 1.0 + 0.18 * scale
			player.add_visual_tag("rectangle_badge")
		"blunt_corner":
			base_damage_multiplier += 0.08
			player.add_visual_tag("corner_nubs", 1)
		"helpful_blob":
			player.heal(1)
		"rough_draft_hp":
			player.max_hp += 2
		"anxious_zigzag":
			player.move_speed *= 1.08
			player.add_visual_tag("orbit_ticks")


func _upgrade_weapon(weapon_id: String) -> void:
	if weapons.has(weapon_id):
		weapons[weapon_id]["level"] = int(weapons[weapon_id].get("level", 1)) + 1
	else:
		weapons[weapon_id] = {"level": 1, "timer": 0.25}


func _refresh_player_damage_multiplier() -> void:
	var run_multiplier = base_damage_multiplier + max(0, player.side_count - 4) * side_bonus_per_extra_side
	player.damage_multiplier = run_multiplier * player.base_damage_mult


func _refresh_weapon_visuals() -> void:
	var visual_levels = {}
	for weapon_id in weapons.keys():
		visual_levels[weapon_id] = int(weapons[weapon_id].get("level", 1))
	player.set_weapon_visuals(visual_levels)


func _build_draft_choices(small_power: bool) -> Array:
	var wave = waves[current_wave_index]
	var pool = upgrade_pool.duplicate(true)
	pool.shuffle()
	var choices = []
	var desired_ids: Array = wave.get("draft_offers", [])
	var has_explicit_offers = desired_ids.size() > 0
	if not has_explicit_offers:
		if current_wave_index == 0:
			desired_ids = ["corner_cannon", "pocket_magnet", "meaner_corners"]
		elif current_wave_index == 1:
			desired_ids = ["dot_swarm", "comfy_blob", "side_hustle"]
		elif current_wave_index == 2:
			desired_ids = ["apology_orb", "orbit_ruler", "very_serious_rectangle"]
		else:
			desired_ids = ["volunteer_dot_plus", "comfy_blob", "pocket_magnet"]
	for id in desired_ids:
		var upgrade = _upgrade_by_id(str(id))
		if not upgrade.is_empty():
			choices.append(upgrade)
	if not has_explicit_offers:
		for upgrade in pool:
			if choices.size() >= 3:
				break
			var upgrade_id = str(upgrade.get("id", ""))
			if upgrade_id == "panic_pinwheel":
				continue
			if not _choice_list_has_id(choices, upgrade_id):
				choices.append(upgrade)
	if small_power and not choices.is_empty():
		choices[0] = choices[0].duplicate(true)
		choices[0]["small"] = true
		choices[0]["stat"] = "Small " + str(choices[0].get("stat", "boost"))
	if has_explicit_offers:
		return choices
	return choices.slice(0, 3)


func _choice_list_has_id(list: Array, id: String) -> bool:
	for entry in list:
		if str(entry.get("id", "")) == id:
			return true
	return false


func _upgrade_by_id(id: String) -> Dictionary:
	for upgrade in upgrade_pool:
		if str(upgrade.get("id", "")) == id:
			var result: Dictionary = upgrade.duplicate(true)
			if _is_weapon_id(id) and weapons.has(id):
				result["name"] = str(result["name"]) + "+"
				result["line"] = "The shape gets more insistent."
				result["stat"] = "+1 weapon level"
			if id == "volunteer_dot_plus" and weapons.has("volunteer_dot"):
				result["stat"] = "+2 damage, later +radius"
			return result
	return {}


func _is_weapon_id(id: String) -> bool:
	return id in ["volunteer_dot", "corner_cannon", "dot_swarm", "rude_triangle", "orbit_ruler", "apology_orb", "panic_pinwheel"]


func _nearest_enemy(max_distance: float = 999999.0):
	var best = null
	var best_distance = max_distance
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_active():
			continue
		var distance = enemy.position.distance_to(player.position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


func _nearest_enemies(count: int) -> Array:
	var candidates = []
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_active():
			candidates.append(enemy)
	candidates.sort_custom(func(a, b): return a.position.distance_squared_to(player.position) < b.position.distance_squared_to(player.position))
	return candidates.slice(0, count)


func _regular_enemy_count() -> int:
	var count = 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.kind != "chunk_polygon":
			count += 1
	return count


func _wave_allows_spawn(wave: Dictionary) -> bool:
	if str(wave.get("spawn_pattern", "steady")) != "pulse":
		return true
	var elapsed = float(wave.get("duration", 0.0)) - wave_time_left
	for window in wave.get("pulse_windows", []):
		if window is Array and window.size() >= 2:
			if elapsed >= float(window[0]) and elapsed <= float(window[1]):
				return true
	return false


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var denom = max(ab.length_squared(), 0.001)
	var t = clamp((point - a).dot(ab) / denom, 0.0, 1.0)
	return point.distance_to(a + ab * t)


func _update_hud(note: String = "") -> void:
	var wave = waves[current_wave_index]
	hud.update_hud({
		"hp": player.hp,
		"max_hp": player.max_hp,
		"time_left": wave_time_left,
		"wave_label": str(wave["label"]),
		"ink_count": ink_this_wave,
		"ink_threshold": int(wave.get("threshold", 42)),
		"score": enemies_popped,
		"state_note": note
	})


func _build_wave_data() -> void:
	waves = [
		{
			"label": "Wave 1/7",
			"duration": 45.0,
			"spawn_rate": 1.20,
			"threshold": 18,
			"has_shop": true,
			"mix": ["wobble_circle", "wobble_circle", "smug_square"]
		},
		{
			"label": "Wave 2/7",
			"duration": 60.0,
			"spawn_rate": 0.80,
			"threshold": 30,
			"has_shop": true,
			"mix": ["wobble_circle", "smug_square", "pointy_triangle", "pointy_triangle"]
		},
		{
			"label": "Wave 3/7",
			"duration": 75.0,
			"spawn_rate": 0.55,
			"threshold": 42,
			"has_shop": true,
			"mix": ["wobble_circle", "smug_square", "pointy_triangle", "needle_line", "needle_line", "dizzy_spiral"]
		},
		{
			"label": "Wave 4/7: Contested Routes",
			"duration": 65.0,
			"spawn_rate": 0.60,
			"threshold": 48,
			"drop_rate": 1.5,
			"has_shop": true,
			"mix": ["wobble_circle", "needle_line", "needle_line", "dizzy_spiral", "dizzy_spiral", "pointy_triangle"]
		},
		{
			"label": "Wave 5/7: Polygon Tremor",
			"duration": 32.0,
			"spawn_rate": 1.25,
			"threshold": 0,
			"draft_after": false,
			"has_shop": true,
			"spawn_pattern": "pulse",
			"pulse_windows": [[0.0, 8.0], [12.0, 20.0], [25.0, 31.0]],
			"mix": ["wobble_circle", "wobble_circle", "smug_square", "smug_square", "pointy_triangle", "needle_line"]
		},
		{
			"label": "Wave 6/7: The Proof",
			"duration": 40.0,
			"spawn_rate": 0.55,
			"threshold": 0,
			"draft_after": true,
			"draft_offers": ["panic_pinwheel"],
			"drop_rate": 1.0,
			"spawn_pattern": "steady",
			"mix": ["needle_line", "needle_line", "dizzy_spiral"]
		},
		{
			"label": "Boss 7/7",
			"duration": 90.0,
			"spawn_rate": 1.40,
			"threshold": 42,
			"boss": true,
			"mix": ["wobble_circle", "smug_square", "pointy_triangle"]
		}
	]


func _build_character_roster() -> void:
	character_roster = [
		{
			"id": "balanced_blob",
			"name": "BALANCED BLOB",
			"line": "Default scrappy doodle. Adapts without drama.",
			"stat_line": "5 HP / 260 speed / 18 radius",
			"max_hp": 5,
			"move_speed": 260.0,
			"radius": 18.0,
			"color": Color(0.31, 0.84, 0.72)
		},
		{
			"id": "quick_dot",
			"name": "QUICK DOT",
			"line": "Tiny runaway mark. Faster, but less forgiving.",
			"stat_line": "4 HP / 285 speed / 16 radius",
			"max_hp": 4,
			"move_speed": 285.0,
			"radius": 16.0,
			"color": Color(0.92, 0.78, 1.0)
		},
		{
			"id": "sturdy_square",
			"name": "STURDY SQUARE",
			"line": "Serious little block. Safer, slower, easier to tag.",
			"stat_line": "6 HP / 235 speed / 20 radius",
			"max_hp": 6,
			"move_speed": 235.0,
			"radius": 20.0,
			"color": Color(1.0, 0.62, 0.34)
		},
		{
			"id": "fancy_hex",
			"name": "FANCY HEX",
			"line": "Six sides. Somehow smug about it.",
			"stat_line": "5 HP / 250 speed / 6 sides",
			"max_hp": 5,
			"move_speed": 250.0,
			"radius": 18.0,
			"side_count": 6,
			"color": Color(0.36, 0.92, 0.48)
		},
		{
			"id": "timid_triangle",
			"name": "TIMID TRIANGLE",
			"line": "Technically a threat. Emotionally, less certain.",
			"stat_line": "DMG +20% / 3 HP / 300 speed",
			"max_hp": 3,
			"move_speed": 300.0,
			"radius": 13.0,
			"base_damage_mult": 1.20,
			"color": Color(0.98, 0.53, 0.75)
		},
		{
			"id": "grumpy_wedge",
			"name": "GRUMPY WEDGE",
			"line": "Done with this. Ready when you are.",
			"stat_line": "DMG +25% / 4 HP / 245 speed",
			"max_hp": 4,
			"move_speed": 245.0,
			"radius": 17.0,
			"base_damage_mult": 1.25,
			"color": Color(0.92, 0.72, 0.22)
		}
	]


func _character_by_id(character_id: String) -> Dictionary:
	for character in character_roster:
		if str(character.get("id", "")) == character_id:
			return character
	return character_roster[0] if not character_roster.is_empty() else {}


func _build_upgrade_pool() -> void:
	upgrade_pool = [
		{"id": "bigger_scribble", "name": "BIGGER SCRIBBLE", "line": "Weapons draw wider trouble.", "stat": "+20% weapon size", "icon": "blob"},
		{"id": "faster_panic", "name": "FASTER PANIC", "line": "Everything fires less politely.", "stat": "-12% cooldowns", "icon": "pinwheel"},
		{"id": "meaner_corners", "name": "MEANER CORNERS", "line": "Your outline gets judgmental.", "stat": "+15% damage", "icon": "triangle"},
		{"id": "comfy_blob", "name": "COMFY BLOB", "line": "A spare lobe appears.", "stat": "+1 max HP, heal 1", "icon": "heart"},
		{"id": "pocket_magnet", "name": "POCKET MAGNET", "line": "Ink drops get clingy.", "stat": "+35% pickup radius", "icon": "orb"},
		{"id": "side_hustle", "name": "SIDE HUSTLE", "line": "More sides, more opinions.", "stat": "+1 side, side damage", "icon": "blob"},
		{"id": "corner_applause", "name": "CORNER APPLAUSE", "line": "Sharp hits get cheers.", "stat": "+30% corner-hit damage", "icon": "square"},
		{"id": "volunteer_dot_plus", "name": "VOLUNTEER DOT+", "line": "The anxious dot practices bonking.", "stat": "+2 damage, later +radius", "icon": "volunteer_dot"},
		{"id": "panic_pinwheel", "name": "PANIC PINWHEEL", "line": "Spinning bars rake the room.", "stat": "Unlock/upgrade weapon", "icon": "pinwheel"},
		{"id": "corner_cannon", "name": "CORNER CANNON", "line": "Squares leave in four directions.", "stat": "Unlock/upgrade weapon", "icon": "square"},
		{"id": "dot_swarm", "name": "DOT SWARM", "line": "Dots orbit, then abandon you.", "stat": "Unlock/upgrade weapon", "icon": "dot"},
		{"id": "rude_triangle", "name": "RUDE TRIANGLE", "line": "A wedge interrupts someone.", "stat": "Unlock/upgrade weapon", "icon": "triangle"},
		{"id": "orbit_ruler", "name": "ORBIT RULER", "line": "A rectangle sweeps the room.", "stat": "Unlock/upgrade weapon", "icon": "ruler"},
		{"id": "apology_orb", "name": "APOLOGY ORB", "line": "A soft pulse says move.", "stat": "Unlock/upgrade weapon", "icon": "orb"},
		{"id": "scoot_marks", "name": "SCOOT MARKS", "line": "The blob leaves nervous dashes.", "stat": "+12% move speed", "icon": "blob"},
		{"id": "very_serious_rectangle", "name": "VERY SERIOUS RECTANGLE", "line": "Enemies take the hint.", "stat": "+18% knockback", "icon": "ruler"}
	]


func _register_default_inputs() -> void:
	_ensure_action("move_left")
	_ensure_action("move_right")
	_ensure_action("move_up")
	_ensure_action("move_down")
	_ensure_action("confirm")
	_ensure_action("pause_game")
	_ensure_action("restart")
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_key("move_up", KEY_W)
	_add_key("move_up", KEY_UP)
	_add_key("move_down", KEY_S)
	_add_key("move_down", KEY_DOWN)
	_add_key("confirm", KEY_ENTER)
	_add_key("confirm", KEY_SPACE)
	_add_mouse_button("confirm", MOUSE_BUTTON_LEFT)
	_add_key("pause_game", KEY_ESCAPE)
	_add_key("restart", KEY_R)
	_add_key("restart", KEY_ENTER)
	_add_joy_button("confirm", JOY_BUTTON_A)
	_add_joy_button("pause_game", JOY_BUTTON_START)
	_add_joy_button("restart", JOY_BUTTON_A)
	_add_joy_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_button("move_up", JOY_BUTTON_DPAD_UP)
	_add_joy_button("move_down", JOY_BUTTON_DPAD_DOWN)
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)


func _add_key(action: String, physical_keycode) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = physical_keycode
	if not _action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _add_mouse_button(action: String, button_index) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = button_index
	if not _action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _add_joy_button(action: String, button_index) -> void:
	var event = InputEventJoypadButton.new()
	event.button_index = button_index
	if not _action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _add_joy_axis(action: String, axis, value: float) -> void:
	var event = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	if not _action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _action_has_event(action: String, event: InputEvent) -> bool:
	for existing in InputMap.action_get_events(action):
		if existing.as_text() == event.as_text():
			return true
	return false
