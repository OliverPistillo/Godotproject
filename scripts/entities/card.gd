# scripts/entities/card.gd
extends Node3D

signal card_clicked(card_data: Dictionary)
signal card_hovered()
signal card_unhovered()
signal purchase_requested(card_data: Dictionary)
signal lock_toggled(locked: bool)

@export var rotation_speed: float = 1.0
@export var hover_scale: float = 1.2
@export var click_animation_duration: float = 0.3

# Dati della carta
var card_data: Dictionary = {}
var card_id: int = -1
var is_locked: bool = false
var is_hovering: bool = false
var cost: int = 100

# Riferimenti nodi
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_area: Area3D = $Area3D
@onready var label_3d: Label3D = $Label3D
@onready var cost_label: Label3D = $CostLabel3D
@onready var rarity_indicator: Node3D = $RarityIndicator
@onready var lock_indicator: Node3D = $LockIndicator
@onready var branches_container: Node3D = $BranchesContainer

# Materiali per rarità
var material_normal: Material
var material_epic: Material
var material_legendary: Material

# Animazione
var original_position: Vector3
var original_scale: Vector3
var tween: Tween

func _ready() -> void:
	setup_materials()
	setup_interactions()
	original_position = position
	original_scale = scale
	
	if lock_indicator:
		lock_indicator.visible = false

func setup_materials() -> void:
	# Crea materiali per diverse rarità
	material_normal = preload("res://resources/materials/card_normal.tres")
	material_epic = preload("res://resources/materials/card_epic.tres")
	material_legendary = preload("res://resources/materials/card_legendary.tres")
	
	# Se i materiali non esistono, crea dei placeholder
	if not material_normal:
		material_normal = StandardMaterial3D.new()
		material_normal.albedo_color = Color(0.3, 0.3, 0.7)  # Blu
	
	if not material_epic:
		material_epic = StandardMaterial3D.new()
		material_epic.albedo_color = Color(0.6, 0.3, 0.7)  # Viola
		material_epic.emission_enabled = true
		material_epic.emission = Color(0.3, 0.1, 0.3)
		material_epic.emission_energy = 0.3
	
	if not material_legendary:
		material_legendary = StandardMaterial3D.new()
		material_legendary.albedo_color = Color(0.9, 0.7, 0.2)  # Oro
		material_legendary.emission_enabled = true
		material_legendary.emission = Color(0.5, 0.4, 0.1)
		material_legendary.emission_energy = 0.5
		material_legendary.metallic = 0.8
		material_legendary.roughness = 0.2

func setup_interactions() -> void:
	if collision_area:
		collision_area.input_event.connect(_on_input_event)
		collision_area.mouse_entered.connect(_on_mouse_entered)
		collision_area.mouse_exited.connect(_on_mouse_exited)

func setup_card(data: Dictionary) -> void:
	card_data = data
	card_id = data.get("id", -1)
	cost = data.get("cost", 100)
	
	# Imposta nome
	if label_3d:
		label_3d.text = data.get("name", "")
	
	# Imposta costo
	if cost_label:
		cost_label.text = str(cost) + " 🪙"
	
	# Imposta rarità
	var rarity = data.get("rarity", "normal").to_lower()
	apply_rarity_visuals(rarity)
	
	# Imposta branches
	setup_branches(data)
	
	# Mostra effetto della carta
	show_card_effect(data.get("effect", ""))

func apply_rarity_visuals(rarity: String) -> void:
	if not mesh_instance:
		return
	
	match rarity:
		"normal":
			mesh_instance.material_override = material_normal
			if rarity_indicator:
				rarity_indicator.modulate = Color(0.3, 0.3, 0.7)
		"epic":
			mesh_instance.material_override = material_epic
			if rarity_indicator:
				rarity_indicator.modulate = Color(0.6, 0.3, 0.7)
		"legendary":
			mesh_instance.material_override = material_legendary
			if rarity_indicator:
				rarity_indicator.modulate = Color(0.9, 0.7, 0.2)
			# Aggiungi particelle per le leggendarie
			add_legendary_particles()

func setup_branches(data: Dictionary) -> void:
	if not branches_container:
		return
	
	# Pulisci branches esistenti
	for child in branches_container.get_children():
		child.queue_free()
	
	# Parse branches dalla carta
	var branches = []
	var branch_data = data.get("branch", "")
	
	if typeof(branch_data) == TYPE_STRING:
		if "," in branch_data:
			# Multipli branches separati da virgola
			var parts = branch_data.split(",")
			for part in parts:
				branches.append(part.strip_edges())
		else:
			branches.append(branch_data)
	elif typeof(branch_data) == TYPE_ARRAY:
		branches = branch_data
	
	# Crea indicatori per ogni branch
	var angle_step = TAU / max(branches.size(), 1)
	var radius = 0.5
	
	for i in range(branches.size()):
		var branch_indicator = create_branch_indicator(branches[i])
		if branch_indicator:
			branches_container.add_child(branch_indicator)
			# Posiziona in cerchio attorno alla carta
			var angle = i * angle_step
			branch_indicator.position = Vector3(
				cos(angle) * radius,
				0.1,
				sin(angle) * radius
			)

func create_branch_indicator(branch_name: String) -> Node3D:
	var indicator = Node3D.new()
	
	# Crea sprite 3D per l'icona del branch
	var sprite = Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = 0.002
	
	# Carica texture del branch
	var texture_path = "res://assets/textures/cards/icons/branches/" + branch_name.to_lower() + ".png"
	if FileAccess.file_exists(texture_path):
		sprite.texture = load(texture_path)
	else:
		# Fallback a un colore
		sprite.modulate = get_branch_color(branch_name)
	
	indicator.add_child(sprite)
	return indicator

func get_branch_color(branch_name: String) -> Color:
	match branch_name.to_lower():
		"assault": return Color.RED
		"ice": return Color.CYAN
		"toxin": return Color.GREEN
		"shield": return Color.BLUE
		"healing": return Color.PINK
		"power": return Color.ORANGE
		"precision": return Color.YELLOW
		"guardian": return Color.GRAY
		"rage": return Color.DARK_RED
		"essence": return Color.PURPLE
		"dodge": return Color.LIGHT_BLUE
		"wound": return Color.DARK_RED
		_: return Color.WHITE

func show_card_effect(effect_text: String) -> void:
	# Crea tooltip 3D per mostrare l'effetto quando hover
	if not has_node("EffectTooltip"):
		var tooltip = Label3D.new()
		tooltip.name = "EffectTooltip"
		tooltip.text = effect_text
		tooltip.font_size = 12
		tooltip.position = Vector3(0, 1.5, 0)
		tooltip.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tooltip.visible = false
		add_child(tooltip)

func _on_input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				# Click sinistro - acquista
				emit_signal("card_clicked", card_data)
				emit_signal("purchase_requested", card_data)
				animate_purchase()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# Click destro - blocca/sblocca
				toggle_lock()

func _on_mouse_entered() -> void:
	is_hovering = true
	emit_signal("card_hovered")
	animate_hover(true)
	
	# Mostra tooltip effetto
	if has_node("EffectTooltip"):
		$EffectTooltip.visible = true

func _on_mouse_exited() -> void:
	is_hovering = false
	emit_signal("card_unhovered")
	animate_hover(false)
	
	# Nascondi tooltip
	if has_node("EffectTooltip"):
		$EffectTooltip.visible = false

func animate_hover(enter: bool) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	if enter:
		tween.tween_property(self, "scale", original_scale * hover_scale, 0.2)
		tween.parallel().tween_property(self, "position:y", original_position.y + 0.3, 0.2)
	else:
		tween.tween_property(self, "scale", original_scale, 0.2)
		tween.parallel().tween_property(self, "position:y", original_position.y, 0.2)

func animate_purchase() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	
	# Animazione di acquisto
	tween.tween_property(self, "scale", original_scale * 1.5, 0.1)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.2)
	tween.tween_callback(queue_free)

func toggle_lock() -> void:
	is_locked = !is_locked
	emit_signal("lock_toggled", is_locked)
	
	if lock_indicator:
		lock_indicator.visible = is_locked
	
	# Animazione lock
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	
	if is_locked:
		tween.tween_property(self, "rotation:y", rotation.y + PI/8, 0.3)
		tween.tween_property(self, "modulate", Color(0.7, 0.7, 0.7), 0.2)
	else:
		tween.tween_property(self, "rotation:y", rotation.y - PI/8, 0.3)
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func add_legendary_particles() -> void:
	if has_node("Particles"):
		return
	
	var particles = GPUParticles3D.new()
	particles.name = "Particles"
	particles.amount = 20
	particles.lifetime = 2.0
	particles.emitting = true
	
	# Configura processo materiale
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.initial_velocity_min = 0.5
	process_material.initial_velocity_max = 1.0
	process_material.angular_velocity_min = -180.0
	process_material.angular_velocity_max = 180.0
	process_material.orbit_velocity_min = 0.1
	process_material.orbit_velocity_max = 0.2
	process_material.scale_min = 0.1
	process_material.scale_max = 0.3
	process_material.color = Color(1.0, 0.8, 0.2, 0.6)
	
	particles.process_material = process_material
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radial_segments = 4
	particles.draw_pass_1.height = 0.1
	particles.draw_pass_1.radius = 0.05
	
	add_child(particles)

func _process(delta: float) -> void:
	if is_hovering:
		# Rotazione quando in hover
		rotation.y += rotation_speed * delta

func get_is_locked() -> bool:
	return is_locked

func set_locked(locked: bool) -> void:
	if is_locked != locked:
		toggle_lock()

func flash_insufficient_funds() -> void:
	# Effetto visivo quando non ci sono abbastanza coins
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_loops(2)
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)