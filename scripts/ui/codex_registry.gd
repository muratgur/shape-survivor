extends RefCounted


static func categories() -> Array:
	return [
		{"id": "actors", "name": "ACTORS", "entries": _actors()},
		{"id": "antagonists", "name": "ANTAGONISTS", "entries": _antagonists()},
		{"id": "instruments", "name": "INSTRUMENTS", "entries": _instruments()},
		{"id": "residue", "name": "RESIDUE", "entries": _residue()},
		{"id": "adjustments", "name": "ADJUSTMENTS", "entries": _adjustments()}
	]


static func _entry(name: String, icon: String, observation: String, truth: String, note: String, flavor: String) -> Dictionary:
	return {
		"name": name,
		"icon": icon,
		"observation": observation,
		"truth": truth,
		"note": note,
		"flavor": flavor
	}


static func _actors() -> Array:
	return [
		_entry("BALANCED BLOB", "actor_balanced_blob", "It adapts without drama.", "Standard health, speed, and body size. Starts with Volunteer Dot.", "5 HP. 260 speed. 18 radius. See VOLUNTEER DOT.", "It was here first."),
		_entry("QUICK DOT", "actor_quick_dot", "Tiny runaway mark.", "Moves faster than the others and has less room for mistakes. Starts with Panic Pinwheel.", "4 HP. 285 speed. 16 radius. See PANIC PINWHEEL.", "A dot with plans."),
		_entry("STURDY SQUARE", "actor_sturdy_square", "Serious little block.", "Has more health and a larger body. Moves slowly. Starts with Corner Cannon.", "6 HP. 235 speed. 20 radius. See CORNER CANNON.", "It believes in corners."),
		_entry("FANCY HEX", "actor_fancy_hex", "Six sides. Somehow smug.", "Starts with extra sides and Dot Swarm, making the page busier early.", "5 HP. 250 speed. 6 sides. See DOT SWARM.", "More angles than necessary."),
		_entry("TIMID TRIANGLE", "actor_timid_triangle", "Technically a threat.", "Hits harder and moves quickly, but has very little health. Starts with Rude Triangle.", "3 HP. 300 speed. More damage. See RUDE TRIANGLE.", "It points away from responsibility."),
		_entry("GRUMPY WEDGE", "actor_grumpy_wedge", "Done with this.", "Hits harder than most and moves at a careful pace. Starts with Apology Orb.", "4 HP. 245 speed. More damage. See APOLOGY ORB.", "It has chosen a direction.")
	]


static func _antagonists() -> Array:
	return [
		_entry("WOBBLE CIRCLE", "enemy_wobble_circle", "Yellow and direct.", "Chases with a slight side-to-side wobble.", "Common. Soft shape, steady pressure.", "It arrives eventually."),
		_entry("SMUG SQUARE", "enemy_smug_square", "It moves like a rule.", "Advances in strict horizontal or vertical steps.", "Blue. Tougher than it looks.", "It expects you to move first."),
		_entry("POINTY TRIANGLE", "enemy_pointy_triangle", "It aims with intent.", "Pauses, lines up, then charges toward you.", "Red. Avoid the sharp end.", "It does not like being ignored."),
		_entry("NEEDLE LINE", "enemy_needle_line", "Very fast. Very thin.", "Telegraphs, then dashes hard in one direction.", "Purple. Drops speed when it feels like it.", "It does not apologize for the contact."),
		_entry("DIZZY SPIRAL", "enemy_dizzy_spiral", "It has a circular problem.", "Roams toward ink clusters, winds up, then bursts outward.", "Green. Watch the windup.", "It found the wrong center."),
		_entry("CHUNK POLYGON", "enemy_chunk_polygon", "A large orange conclusion.", "Final boss. Chases, slams, sheds enemies, and refuses to be tidy.", "High health. Contact hurts more.", "The page had to put it somewhere.")
	]


static func _instruments() -> Array:
	return [
		_entry("VOLUNTEER DOT", "weapon_volunteer_dot", "It was here when we started.", "Fires yellow dots at the nearest enemy.", "Starter weapon. Reliable enough.", "It has nothing else to do."),
		_entry("PANIC PINWHEEL", "weapon_panic_pinwheel", "Spinning bars rake the room.", "Creates rotating bars around the player.", "Earned after The Proof or improved later.", "Panic, organized radially."),
		_entry("CORNER CANNON", "weapon_corner_cannon", "Squares leave in four directions.", "Fires square shots up, down, left, and right.", "Good when the room agrees to line up.", "A square's idea of generosity."),
		_entry("DOT SWARM", "weapon_dot_swarm", "Dots orbit, then abandon you.", "Creates several dots that launch toward enemies.", "More levels means more dots.", "Temporary loyalty."),
		_entry("RUDE TRIANGLE", "weapon_rude_triangle", "A wedge interrupts someone.", "Cuts forward in a short piercing wedge.", "Sharp hits can become more meaningful.", "It enters the conversation sideways."),
		_entry("ORBIT RULER", "weapon_orbit_ruler", "A rectangle sweeps the room.", "Rotates around you, damaging what it touches.", "Slow cooldown. Wide coverage.", "Measuring the distance between us."),
		_entry("APOLOGY ORB", "weapon_apology_orb", "A soft pulse says move.", "Emits a broad pulse that damages and pushes nearby enemies.", "Large area. Polite name.", "The apology arrives after the impact.")
	]


static func _residue() -> Array:
	return [
		_entry("INK DROP", "pickup_ink", "It is black. It is useful.", "Currency for shops and wave thresholds.", "You will want more than you have.", "The medium is the message."),
		_entry("HEALTH BLOB", "pickup_health", "A red thing trying to help.", "Restores one health when collected.", "Smaller magnet pull than ink.", "It is not a heart. It is close enough."),
		_entry("SPARE MARGIN", "pickup_speed_burst", "A dash with somewhere to be.", "Briefly increases movement speed.", "Needle Lines sometimes leave it behind.", "A little room. For a moment."),
		_entry("SHIELD FRAGMENT", "pickup_shield_fragment", "A small defensive corner.", "Adds one shield charge, up to three.", "Blocks the next contact hit.", "It is useful until proven otherwise."),
		_entry("INK MAGNET PULSE", "pickup_magnet_pulse", "A circle insisting on company.", "Briefly increases magnet radius.", "Dizzy Spirals can leave it behind.", "The ink comes back if asked correctly."),
		_entry("DAMAGE BURST", "pickup_damage_burst", "A jagged orange suggestion.", "Briefly increases outgoing damage.", "Smug Squares sometimes produce it.", "Everything becomes a little less negotiable."),
		_entry("JITTERY FRAGMENT", "pickup_jittery_fragment", "It spins because it can.", "Explodes on collection and pushes you away.", "No magnet pull. Walk over it deliberately.", "It has plans. Not yours.")
	]


static func _adjustments() -> Array:
	return [
		_entry("BIGGER SCRIBBLE", "upgrade_blob", "Weapons draw wider trouble.", "Increases weapon size.", "Good for arcs, pulses, and projectiles.", "Taking up more space than necessary."),
		_entry("FASTER PANIC", "upgrade_pinwheel", "Everything fires less politely.", "Reduces weapon cooldowns.", "More attacks. Less waiting.", "Efficiency, but nervous."),
		_entry("MEANER CORNERS", "upgrade_triangle", "Your outline gets judgmental.", "Increases base damage.", "Simple and useful.", "The page notices."),
		_entry("COMFY BLOB", "upgrade_heart", "A spare lobe appears.", "Raises max health and heals one.", "Survival, plainly stated.", "Comfort is a shape."),
		_entry("POCKET MAGNET", "upgrade_orb", "Ink drops get clingy.", "Increases pickup and magnet reach.", "A quiet economy improvement.", "Nothing wants to be left behind."),
		_entry("SIDE HUSTLE", "upgrade_blob", "More sides, more opinions.", "Adds a side and improves side-based damage.", "Best with angular confidence.", "Geometry has ambitions."),
		_entry("CORNER APPLAUSE", "upgrade_square", "Sharp hits get cheers.", "Enables extra damage on corner hits.", "Rewards precise angles.", "A small audience forms."),
		_entry("SCOOT MARKS", "upgrade_blob", "The blob leaves nervous dashes.", "Increases movement speed.", "Good for not being where the trouble is.", "Motion, documented after the fact."),
		_entry("VERY SERIOUS RECTANGLE", "upgrade_ruler", "Enemies take the hint.", "Increases knockback.", "More distance after contact.", "A rectangle with boundaries."),
		_entry("ROUGH DRAFT HP", "upgrade_heart", "More room on the line.", "Raises maximum health.", "Shop adjustment.", "The margin expands."),
		_entry("ANXIOUS ZIGZAG", "upgrade_blob", "Faster when crowded.", "Increases movement speed.", "Shop adjustment.", "Concern, weaponized."),
		_entry("BLUNT CORNER", "upgrade_triangle", "Hits without finesse.", "Slightly increases base damage.", "Shop adjustment.", "Still counts."),
		_entry("HELPFUL BLOB", "upgrade_heart", "Heals one. That's it.", "Restores one health.", "Shop adjustment.", "No mystery today.")
	]
