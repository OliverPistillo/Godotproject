# scripts/utils/helpers.gd
extends Node

# ===== JSON LOADING =====
static func load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("File non trovato: " + path)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Errore parsing JSON in " + path + ": " + json.get_error_message())
		return {}
	
	return json.data

static func save_json_file(path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Impossibile aprire file per scrittura: " + path)
		return false
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	return true

# ===== ARRAY UTILITIES =====
static func shuffle_array(array: Array) -> Array:
	var shuffled = array.duplicate()
	shuffled.shuffle()
	return shuffled

static func get_random_elements(array: Array, count: int) -> Array:
	if count >= array.size():
		return array.duplicate()
	
	var shuffled = shuffle_array(array)
	return shuffled.slice(0, count)

static func weighted_random_choice(choices: Dictionary) -> Variant:
	# choices = {"option1": weight1, "option2": weight2, ...}
	var total_weight = 0.0
	for weight in choices.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	for option in choices:
		cumulative_weight += choices[option]
		if random_value <= cumulative_weight:
			return option
	
	return choices.keys()[0]  # Fallback

# ===== MATH UTILITIES =====
static func lerp_color(from: Color, to: Color, weight: float) -> Color:
	return Color(
		lerp(from.r, to.r, weight),
		lerp(from.g, to.g, weight),
		lerp(from.b, to.b, weight),
		lerp(from.a, to.a, weight)
	)

static func calculate_damage_reduction(defense: float) -> float:
	# Formula armor: riduzione = defense / (defense + 100)
	return defense / (defense + 100.0)

static func calculate_crit_damage(base_damage: float, crit_multiplier: float = 1.5) -> float:
	return base_damage * crit_multiplier

static func clamp_percentage(value: float) -> float:
	return clamp(value, 0.0, 100.0)

# ===== STRING UTILITIES =====
static func format_number_abbreviated(num: int) -> String:
	if num >= 1000000:
		return "%.1fM" % (num / 1000000.0)
	elif num >= 1000:
		return "%.1fK" % (num / 1000.0)
	return str(num)

static func format_percentage(value: float, decimals: int = 1) -> String:
	return ("%." + str(decimals) + "f%%") % value

static func parse_branches_string(branch_string: String) -> Array:
	var branches = []
	if "," in branch_string:
		var parts = branch_string.split(",")
		for part in parts:
			branches.append(part.strip_edges())
	elif ";" in branch_string:
		var parts = branch_string.split(";")
		for part in parts:
			branches.append(part.strip_edges())
	else:
		branches.append(branch_string.strip_edges())
	return branches

static func capitalize_words(text: String) -> String:
	var words = text.split(" ")
	var result = []
	for word in words:
		if word.length() > 0:
			result.append(word[0].to_upper() + word.substr(1).to_lower())
	return " ".join(result)

# ===== NODE UTILITIES =====
static func find_child_by_type(parent: Node, type: String) -> Node:
	for child in parent.get_children():
		if child.get_class() == type:
			return child
		var found = find_child_by_type(child, type)
		if found:
			return found
	return null

static func get_all_children_recursive(node: Node) -> Array:
	var children = []
	for child in node.get_children():
		children.append(child)
		children.append_array(get_all_children_recursive(child))
	return children

static func safe_disconnect(object: Object, signal_name: String, callable: Callable) -> void:
	if object.is_connected(signal_name, callable):
		object.disconnect(signal_name, callable)

# ===== UI UTILITIES =====
static func create_tween_bounce(node: Node, property: String, from_value, to_value, duration: float) -> Tween:
	var tween = node.create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, property, to_value, duration).from(from_value)
	return tween

static func create_tween_pulse(node: Node, scale_amount: float = 1.2, duration: float = 0.3) -> Tween:
	var original_scale = node.scale
	var tween = node.create_tween()
	tween.set_loops()
	tween.tween_property(node, "scale", original_scale * scale_amount, duration / 2)
	tween.tween_property(node, "scale", original_scale, duration / 2)
	return tween

static func flash_node(node: Node, color: Color, duration: float = 0.2) -> void:
	if node.has_property("modulate"):
		var original_color = node.modulate
		var tween = node.create_tween()
		tween.tween_property(node, "modulate", color, duration / 2)
		tween.tween_property(node, "modulate", original_color, duration / 2)

# ===== GAME SPECIFIC =====
static func calculate_hero_level(branch_points: Dictionary) -> int:
	var total_points = 0
	for points in branch_points.values():
		total_points += points
	
	if total_points >= 40:
		return 5
	elif total_points >= 20:
		return 4
	elif total_points >= 10:
		return 3
	elif total_points >= 4:
		return 2
	return 1

static func get_rarity_from_cost(cost: int) -> String:
	match cost:
		100:
			return "normal"
		200:
			return "epic"
		300:
			return "legendary"
		_:
			return "normal"

static func get_cost_from_rarity(rarity: String) -> int:
	match rarity.to_lower():
		"normal":
			return 100
		"epic":
			return 200
		"legendary":
			return 300
		_:
			return 100

static func is_branch_active(branch: String, active_branches: Array) -> bool:
	return branch in active_branches

static func calculate_interest(coins: int, rate: int = 10, max_interest: int = 100) -> int:
	var interest = (coins / 100) * rate
	return min(interest, max_interest)

# ===== VALIDATION =====
static func validate_hero_data(hero_data: Dictionary) -> bool:
	var required_fields = ["id", "name", "stats"]
	for field in required_fields:
		if not hero_data.has(field):
			return false
	
	var required_stats = ["max_health", "attack_damage", "attack_speed"]
	var stats = hero_data.get("stats", {})
	for stat in required_stats:
		if not stats.has(stat):
			return false
	
	return true

static func validate_card_data(card_data: Dictionary) -> bool:
	var required_fields = ["id", "name", "branch", "rarity", "cost"]
	for field in required_fields:
		if not card_data.has(field):
			return false
	return true

# ===== EFFECTS =====
static func create_damage_number(parent: Node3D, damage: float, damage_type: String = "physical") -> void:
	var label = Label3D.new()
	label.text = str(int(damage))
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	
	# Colore basato sul tipo
	match damage_type:
		"heal":
			label.modulate = Color.GREEN
			label.text = "+" + label.text
		"crit":
			label.modulate = Color.YELLOW
			label.text = label.text + "!"
		"physical":
			label.modulate = Color.WHITE
		"magic":
			label.modulate = Color.CYAN
		"toxin":
			label.modulate = Color.GREEN
		"pure":
			label.modulate = Color.PURPLE
		_:
			label.modulate = Color.RED
	
	parent.add_child(label)
	
	# Animazione
	var tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", 2.0, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(label.queue_free)

static func create_particle_effect(parent: Node3D, color: Color, amount: int = 20) -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = 2.0
	particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.initial_velocity_min = 0.5
	process_material.initial_velocity_max = 1.0
	process_material.angular_velocity_min = -180.0
	process_material.angular_velocity_max = 180.0
	process_material.scale_min = 0.1
	process_material.scale_max = 0.3
	process_material.color = color
	
	particles.process_material = process_material
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radial_segments = 4
	particles.draw_pass_1.height = 0.1
	particles.draw_pass_1.radius = 0.05
	
	parent.add_child(particles)
	
	# Auto-distruggi dopo l'emissione
	particles.emitting = false
	await particles.finished
	particles.queue_free()
	
	return particles

# ===== DEBUG =====
static func debug_print(message: String, category: String = "DEBUG") -> void:
	if Constants.DEBUG_MODE:
		print("[%s] %s" % [category, message])

static func debug_draw_sphere(position: Vector3, radius: float = 0.5, color: Color = Color.RED, duration: float = 1.0) -> void:
	if not Constants.DEBUG_MODE:
		return
	
	# Implementazione per debug visivo
	# Richiede un DebugDraw singleton configurato nel progetto
	pass

# ===== SAVE/LOAD =====
static func save_game_data(save_path: String, data: Dictionary) -> bool:
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if not save_file:
		return false
	
	save_file.store_var(data)
	save_file.close()
	return true

static func load_game_data(save_path: String) -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	if not save_file:
		return {}
	
	var data = save_file.get_var()
	save_file.close()
	
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	
	return data

# ===== AUDIO =====
static func play_sound_at_position(sound_path: String, position: Vector3, volume: float = 0.0) -> void:
	var audio_stream = load(sound_path)
	if not audio_stream:
		return
	
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = volume
	audio_player.position = position
	audio_player.autoplay = true
	
	# Aggiungi al nodo root
	var root = Engine.get_main_loop().current_scene
	root.add_child(audio_player)
	
	# Auto-distruggi quando finisce
	audio_player.finished.connect(audio_player.queue_free)

# ===== NETWORKING =====
static func is_multiplayer_active() -> bool:
	return Engine.get_main_loop().has_multiplayer_peer() and \
		   Engine.get_main_loop().get_multiplayer_peer().get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

static func get_local_player_id() -> int:
	if is_multiplayer_active():
		return Engine.get_main_loop().get_multiplayer_peer().get_unique_id()
	return 1  # Single player

static func is_server() -> bool:
	return get_local_player_id() == 1
