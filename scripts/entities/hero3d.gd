# scripts/entities/hero3d.gd
extends Node3D

signal attack_started()
signal attack_finished()
signal death_started()
signal took_damage(amount: int)
signal healed(amount: int)

# Stati dell'eroe
enum HeroState {
	IDLE,
	ATTACKING,
	DEFENDING,
	DEAD,
	VICTORY
}

# Dati eroe
var hero_data: Dictionary = {}
var hero_id: String = ""
var hero_name: String = ""
var current_state: HeroState = HeroState.IDLE

# Statistiche runtime
var current_hp: float = 50.0
var max_hp: float = 50.0
var current_mana: float = 0.0
var max_mana: float = 100.0
var attack_speed: float = 1.0

# Effetti visivi attivi
var active_effects: Array = []
var effect_stacks: Dictionary = {
	"shield": 0,
	"rage": 0,
	"toxin": 0,
	"ice": 0,
	"wound": 0
}

# Riferimenti nodi
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hp_bar: ProgressBar = $HPBar3D/SubViewport/HPBar
@onready var mana_bar: ProgressBar = $HPBar3D/SubViewport/ManaBar
@onready var name_label: Label3D = $NameLabel3D
@onready var effects_container: Node3D = $EffectsContainer
@onready var damage_numbers_container: Node3D = $DamageNumbers

# Materiali per stati
var material_normal: Material
var material_rage: Material
var material_ice: Material
var material_shield: Material

# Timer attacco
var attack_timer: float = 0.0
var attack_cooldown: float = 1.0

func _ready() -> void:
	setup_materials()
	setup_ui()
	
	# Imposta animazione idle di default
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func setup_materials() -> void:
	# Materiale normale
	material_normal = StandardMaterial3D.new()
	material_normal.albedo_color = Color.WHITE
	
	# Materiale rage (rosso)
	material_rage = StandardMaterial3D.new()
	material_rage.albedo_color = Color(1.0, 0.3, 0.3)
	material_rage.emission_enabled = true
	material_rage.emission = Color(0.5, 0.1, 0.1)
	material_rage.emission_energy = 0.3
	
	# Materiale ice (blu)
	material_ice = StandardMaterial3D.new()
	material_ice.albedo_color = Color(0.5, 0.8, 1.0)
	material_ice.emission_enabled = true
	material_ice.emission = Color(0.2, 0.4, 0.6)
	material_ice.emission_energy = 0.2
	material_ice.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_ice.albedo_color.a = 0.8
	
	# Materiale shield (verde)
	material_shield = StandardMaterial3D.new()
	material_shield.albedo_color = Color(0.3, 1.0, 0.3)
	material_shield.emission_enabled = true
	material_shield.emission = Color(0.1, 0.3, 0.1)
	material_shield.emission_energy = 0.2

func setup_ui() -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
		hp_bar.modulate = Color(0.8, 0.2, 0.2)
	
	if mana_bar:
		mana_bar.max_value = max_mana
		mana_bar.value = current_mana
		mana_bar.modulate = Color(0.2, 0.4, 0.8)
	
	if name_label:
		name_label.text = hero_name

func initialize_hero(data: Dictionary) -> void:
	hero_data = data
	hero_id = data.get("id", "")
	hero_name = data.get("name", "Unknown")
	
	# Carica statistiche base
	var stats = data.get("stats", {})
	max_hp = stats.get("max_health", 1200)
	current_hp = max_hp
	max_mana = stats.get("max_mana", 100)
	current_mana = 0
	attack_speed = stats.get("attack_speed", 1.0)
	attack_cooldown = 1.0 / attack_speed
	
	# Carica modello 3D
	load_hero_model()
	
	# Aggiorna UI
	setup_ui()
	
	# Applica branch visivo
	var branch = data.get("branch", "")
	apply_branch_visual(branch)

func load_hero_model() -> void:
	# Carica il modello GLB dell'eroe
	var model_path = "res://assets/models/heroes/" + hero_name.to_lower() + ".glb"
	
	if FileAccess.file_exists(model_path):
		var model = load(model_path)
		if model and mesh_instance:
			# Sostituisci mesh con il modello caricato
			if model is PackedScene:
				var instance = model.instantiate()
				if instance:
					# Trasferisci mesh e animazioni
					for child in instance.get_children():
						if child is MeshInstance3D:
							mesh_instance.mesh = child.mesh
						elif child is AnimationPlayer:
							# Copia animazioni
							animation_player = child
							child.reparent(self)
					instance.queue_free()

func apply_branch_visual(branch: String) -> void:
	# Applica colore/effetto basato sul branch principale
	if not mesh_instance:
		return
	
	var color_overlay = Color.WHITE
	
	match branch.to_lower():
		"rage":
			color_overlay = Color(1.0, 0.8, 0.8)
		"ice":
			color_overlay = Color(0.8, 0.9, 1.0)
		"toxin":
			color_overlay = Color(0.8, 1.0, 0.8)
		"shield":
			color_overlay = Color(0.8, 0.8, 1.0)
		"healing":
			color_overlay = Color(1.0, 0.9, 0.9)
		"power":
			color_overlay = Color(1.0, 0.9, 0.8)
		"precision":
			color_overlay = Color(1.0, 1.0, 0.9)
		"guardian":
			color_overlay = Color(0.9, 0.9, 0.9)
		"assault":
			color_overlay = Color(1.0, 0.8, 0.8)
		"dodge":
			color_overlay = Color(0.9, 0.9, 1.0)
		"wound":
			color_overlay = Color(0.9, 0.8, 0.8)
		"essence":
			color_overlay = Color(0.9, 0.8, 1.0)
	
	# Applica tinta al materiale
	if mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = color_overlay
	else:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_overlay
		mesh_instance.material_override = mat

func _process(delta: float) -> void:
	if current_state == HeroState.DEAD:
		return
	
	# Aggiorna timer attacco
	if attack_timer > 0:
		attack_timer -= delta
	
	# Rigenera mana
	if current_mana < max_mana:
		var mana_regen = hero_data.get("stats", {}).get("mana_regen", 9)
		current_mana = min(max_mana, current_mana + mana_regen * delta)
		update_mana_bar()
	
	# Processa effetti attivi
	process_effects(delta)
	
	# Aggiorna animazioni basate sullo stato
	update_animation_state()

func process_effects(delta: float) -> void:
	# Decadimento stack effetti
	for effect in effect_stacks:
		if effect_stacks[effect] > 0:
			match effect:
				"ice":
					effect_stacks[effect] -= 2 * delta  # 2 stack/sec
				"shield":
					# Shield decade solo quando colpito
					pass
				"toxin":
					# Applica danno poison
					if fmod(Engine.get_physics_frames(), 30) == 0:  # Ogni 0.5 sec
						var damage = effect_stacks[effect] * 0.3
						take_damage(damage, "toxin")
						effect_stacks[effect] -= 1
				"wound":
					# Wound non decade
					pass
				"rage":
					effect_stacks[effect] -= 1 * delta
			
			# Rimuovi se arriva a 0
			if effect_stacks[effect] <= 0:
				effect_stacks[effect] = 0
				remove_effect_visual(effect)
	
	# Aggiorna visuale effetti
	update_effects_visual()

func update_effects_visual() -> void:
	# Applica material override basato sull'effetto dominante
	if not mesh_instance:
		return
	
	var dominant_effect = ""
	var max_stacks = 0
	
	for effect in effect_stacks:
		if effect_stacks[effect] > max_stacks:
			max_stacks = effect_stacks[effect]
			dominant_effect = effect
	
	match dominant_effect:
		"rage":
			mesh_instance.material_overlay = material_rage
		"ice":
			mesh_instance.material_overlay = material_ice
		"shield":
			mesh_instance.material_overlay = material_shield
		_:
			mesh_instance.material_overlay = null

func can_attack() -> bool:
	return attack_timer <= 0 and current_state != HeroState.DEAD

func perform_attack(target: Node3D) -> void:
	if not can_attack():
		return
	
	current_state = HeroState.ATTACKING
	attack_timer = attack_cooldown
	
	emit_signal("attack_started")
	
	# Play animazione attacco
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
		animation_player.animation_finished.connect(_on_attack_animation_finished, CONNECT_ONE_SHOT)
	else:
		# Fallback se non c'è animazione
		_on_attack_animation_finished("")
	
	# Orienta verso il target
	if target:
		look_at(target.global_position, Vector3.UP)
		rotation.x = 0  # Mantieni solo rotazione Y

func _on_attack_animation_finished(anim_name: String) -> void:
	if current_state == HeroState.ATTACKING:
		current_state = HeroState.IDLE
		emit_signal("attack_finished")

func take_damage(amount: float, damage_type: String = "physical") -> void:
	if current_state == HeroState.DEAD:
		return
	
	var final_damage = amount
	
	# Applica modificatori basati su shield/vulnerabilità
	if damage_type != "pure" and damage_type != "chaos":
		if effect_stacks["shield"] > 0:
			final_damage *= (1.0 - effect_stacks["shield"] * 0.002)  # 0.2% riduzione per stack
			effect_stacks["shield"] = max(0, effect_stacks["shield"] - 5)  # Perde 5 stack
	
	# Amplificazione wound
	if effect_stacks["wound"] > 0:
		final_damage *= (1.0 + effect_stacks["wound"] * 0.001)  # 0.1% amplificazione per stack
	
	current_hp = max(0, current_hp - final_damage)
	update_hp_bar()
	
	emit_signal("took_damage", final_damage)
	
	# Mostra numero danno
	show_damage_number(final_damage, damage_type)
	
	# Flash rosso
	flash_damage()
	
	# Controlla morte
	if current_hp <= 0:
		die()

func heal(amount: float) -> void:
	if current_state == HeroState.DEAD:
		return
	
	var old_hp = current_hp
	current_hp = min(max_hp, current_hp + amount)
	var healed_amount = current_hp - old_hp
	
	if healed_amount > 0:
		update_hp_bar()
		emit_signal("healed", healed_amount)
		show_damage_number(healed_amount, "heal")
		flash_heal()

func add_effect_stack(effect_type: String, stacks: int) -> void:
	if effect_type in effect_stacks:
		effect_stacks[effect_type] += stacks
		effect_stacks[effect_type] = min(999, effect_stacks[effect_type])  # Max 999 stack
		
		# Gestisci interazioni tra effetti
		match effect_type:
			"rage":
				effect_stacks["ice"] = 0  # Rage annulla Ice
			"ice":
				effect_stacks["rage"] = 0  # Ice annulla Rage
			"shield":
				effect_stacks["wound"] = 0  # Shield annulla vulnerabilità
		
		# Mostra effetto visivo
		add_effect_visual(effect_type)

func add_effect_visual(effect_type: String) -> void:
	if not effects_container:
		return
	
	# Crea particelle per l'effetto
	var particles = GPUParticles3D.new()
	particles.name = effect_type + "_particles"
	particles.amount = 10
	particles.lifetime = 1.0
	particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 1, 0)
	process_material.initial_velocity_min = 0.5
	process_material.initial_velocity_max = 1.0
	
	# Colore basato sul tipo
	match effect_type:
		"rage":
			process_material.color = Color(1.0, 0.2, 0.2, 0.6)
		"ice":
			process_material.color = Color(0.2, 0.6, 1.0, 0.6)
		"toxin":
			process_material.color = Color(0.2, 1.0, 0.2, 0.6)
		"shield":
			process_material.color = Color(0.2, 0.2, 1.0, 0.6)
		"wound":
			process_material.color = Color(0.6, 0.2, 0.2, 0.6)
	
	particles.process_material = process_material
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radius = 0.05
	particles.draw_pass_1.height = 0.1
	
	effects_container.add_child(particles)

func remove_effect_visual(effect_type: String) -> void:
	if not effects_container:
		return
	
	var particles_name = effect_type + "_particles"
	if effects_container.has_node(particles_name):
		effects_container.get_node(particles_name).queue_free()

func show_damage_number(amount: float, damage_type: String) -> void:
	if not damage_numbers_container:
		return
	
	var damage_label = Label3D.new()
	damage_label.text = str(int(amount))
	damage_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	damage_label.font_size = 24
	
	# Colore basato sul tipo
	match damage_type:
		"heal":
			damage_label.modulate = Color.GREEN
			damage_label.text = "+" + damage_label.text
		"physical":
			damage_label.modulate = Color.WHITE
		"magic":
			damage_label.modulate = Color.CYAN
		"toxin":
			damage_label.modulate = Color.GREEN
		"pure":
			damage_label.modulate = Color.YELLOW
		_:
			damage_label.modulate = Color.RED
	
	damage_numbers_container.add_child(damage_label)
	
	# Anima il numero
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", 2.0, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(damage_label, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(damage_label.queue_free)

func flash_damage() -> void:
	if not mesh_instance:
		return
	
	var tween = create_tween()
	tween.tween_property(mesh_instance, "modulate", Color(1.5, 0.5, 0.5), 0.1)
	tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.2)

func flash_heal() -> void:
	if not mesh_instance:
		return
	
	var tween = create_tween()
	tween.tween_property(mesh_instance, "modulate", Color(0.5, 1.5, 0.5), 0.1)
	tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.2)

func die() -> void:
	current_state = HeroState.DEAD
	current_hp = 0
	update_hp_bar()
	
	emit_signal("death_started")
	
	# Play animazione morte
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
	else:
		# Fallback: ruota e scala
		var tween = create_tween()
		tween.tween_property(self, "rotation:z", PI/2, 0.5)
		tween.parallel().tween_property(self, "scale", Vector3(0.8, 0.8, 0.8), 0.5)

func victory() -> void:
	current_state = HeroState.VICTORY
	
	# Play animazione vittoria
	if animation_player and animation_player.has_animation("victory"):
		animation_player.play("victory")
	else:
		# Fallback: salta
		var tween = create_tween()
		tween.set_loops(3)
		tween.tween_property(self, "position:y", position.y + 0.5, 0.2)
		tween.tween_property(self, "position:y", position.y, 0.2)

func update_animation_state() -> void:
	if not animation_player or current_state == HeroState.DEAD:
		return
	
	match current_state:
		HeroState.IDLE:
			if not animation_player.is_playing() or animation_player.current_animation != "idle":
				if animation_player.has_animation("idle"):
					animation_player.play("idle")
		HeroState.ATTACKING:
			# L'animazione è già gestita in perform_attack
			pass
		HeroState.DEFENDING:
			if animation_player.has_animation("defend"):
				animation_player.play("defend")
		HeroState.VICTORY:
			if animation_player.has_animation("victory"):
				animation_player.play("victory")

func update_hp_bar() -> void:
	if hp_bar:
		hp_bar.value = current_hp
		# Cambia colore basato su HP
		if current_hp / max_hp > 0.6:
			hp_bar.modulate = Color(0.2, 0.8, 0.2)  # Verde
		elif current_hp / max_hp > 0.3:
			hp_bar.modulate = Color(0.8, 0.8, 0.2)  # Giallo
		else:
			hp_bar.modulate = Color(0.8, 0.2, 0.2)  # Rosso

func update_mana_bar() -> void:
	if mana_bar:
		mana_bar.value = current_mana

func get_hp_percentage() -> float:
	return (current_hp / max_hp) * 100.0

func get_mana_percentage() -> float:
	return (current_mana / max_mana) * 100.0

func set_position_for_duel(is_home: bool) -> void:
	# Posiziona l'eroe per il duello
	if is_home:
		position = Vector3(-2, 0, 0)  # Sinistra
		rotation.y = 0  # Guarda a destra
	else:
		position = Vector3(2, 0, 0)  # Destra
		rotation.y = PI  # Guarda a sinistra

func set_position_for_preparation() -> void:
	# Posiziona l'eroe al centro durante la preparazione
	position = Vector3(0, 0, 0)
	rotation.y = 0