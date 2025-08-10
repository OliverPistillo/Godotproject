# scripts/gameplay/duel_phase.gd
extends Node

signal duel_started(player_hero: Dictionary, enemy_hero: Dictionary)
signal duel_ended(winner: String, hp_lost: int)
signal attack_executed(attacker: String, target: String, damage: float, is_crit: bool)
signal effect_applied(target: String, effect: String, stacks: int)

# Riferimenti eroi
var player_hero_node: Node3D
var enemy_hero_node: Node3D
var player_data: Dictionary = {}
var enemy_data: Dictionary = {}

# Stato duello
var duel_active: bool = false
var duel_time: float = 0.0
var max_duel_time: float = 60.0
var sudden_death_time: float = 45.0

# Timer attacchi
var player_attack_timer: float = 0.0
var enemy_attack_timer: float = 0.0

# Statistiche runtime
var player_stats: Dictionary = {}
var enemy_stats: Dictionary = {}

# Riferimenti UI
@export var hp_bar_player_path: NodePath
@export var hp_bar_enemy_path: NodePath
@export var timer_label_path: NodePath

var hp_bar_player: ProgressBar
var hp_bar_enemy: ProgressBar
var timer_label: Label

func _ready() -> void:
	set_process(false)
	setup_ui_references()

func setup_ui_references() -> void:
	if hp_bar_player_path:
		hp_bar_player = get_node(hp_bar_player_path)
	if hp_bar_enemy_path:
		hp_bar_enemy = get_node(hp_bar_enemy_path)
	if timer_label_path:
		timer_label = get_node(timer_label_path)

func start_duel(player_hero: Node3D, enemy_hero: Node3D, player_info: Dictionary, enemy_info: Dictionary) -> void:
	player_hero_node = player_hero
	enemy_hero_node = enemy_hero
	player_data = player_info
	enemy_data = enemy_info
	
	# Inizializza statistiche
	initialize_combat_stats()
	
	# Posiziona eroi
	position_heroes()
	
	# Reset timer
	duel_time = 0.0
	player_attack_timer = 0.0
	enemy_attack_timer = 0.0
	
	# Avvia duello
	duel_active = true
	set_process(true)
	
	emit_signal("duel_started", player_data, enemy_data)
	
	print("Duello iniziato: ", player_data.get("name", "Player"), " vs ", enemy_data.get("name", "Enemy"))

func initialize_combat_stats() -> void:
	# Copia stats base e applica bonus carte
	player_stats = player_data.get("stats", {}).duplicate(true)
	enemy_stats = enemy_data.get("stats", {}).duplicate(true)
	
	# Applica bonus dal CardSystem per il player
	if has_node("/root/CardSystem"):
		var card_system = get_node("/root/CardSystem")
		for card_id in card_system.player_cards:
			var card_info = card_system.player_cards[card_id]
			var effects = card_system.apply_card_effects(
				card_info["card_data"], 
				card_info["level"]
			)
			apply_stat_bonuses(player_stats, effects)
	
	# Inizializza HP correnti
	if player_hero_node:
		player_hero_node.current_hp = player_stats.get("max_health", 1200)
		player_hero_node.max_hp = player_stats.get("max_health", 1200)
	
	if enemy_hero_node:
		enemy_hero_node.current_hp = enemy_stats.get("max_health", 1200)
		enemy_hero_node.max_hp = enemy_stats.get("max_health", 1200)

func apply_stat_bonuses(stats: Dictionary, bonuses: Dictionary) -> void:
	for key in bonuses:
		match key:
			"base_damage":
				stats["attack_damage"] = stats.get("attack_damage", 24) + bonuses[key]
			"attack_speed":
				stats["attack_speed"] = stats.get("attack_speed", 1.0) + bonuses[key]
			"crit_chance":
				stats["crit_chance"] = stats.get("crit_chance", 15) + bonuses[key]
			"dodge_chance":
				stats["dodge_chance"] = stats.get("dodge_chance", 12) + bonuses[key]
			"max_hp":
				stats["max_health"] = stats.get("max_health", 1200) + bonuses[key]
			"hp_regen":
				stats["hp_regen"] = stats.get("hp_regen", 0) + bonuses[key]
			"mana_regen":
				stats["mana_regen"] = stats.get("mana_regen", 9) + bonuses[key]
			"physical_damage":
				stats["physical_damage"] = stats.get("physical_damage", 0) + bonuses[key]
			"magic_damage":
				stats["magic_damage"] = stats.get("magic_damage", 0) + bonuses[key]

func position_heroes() -> void:
	if player_hero_node:
		player_hero_node.set_position_for_duel(true)  # Posizione sinistra
	if enemy_hero_node:
		enemy_hero_node.set_position_for_duel(false)  # Posizione destra

func _process(delta: float) -> void:
	if not duel_active:
		return
	
	# Aggiorna timer duello
	duel_time += delta
	update_timer_display()
	
	# Controlla sudden death
	if duel_time >= sudden_death_time:
		apply_sudden_death(delta)
	
	# Controlla timeout
	if duel_time >= max_duel_time:
		force_duel_end()
		return
	
	# Aggiorna timer attacco
	update_attack_timers(delta)
	
	# Processa rigenerazione
	process_regeneration(delta)
	
	# Esegui attacchi
	check_and_execute_attacks()
	
	# Controlla condizioni vittoria
	check_victory_conditions()

func update_attack_timers(delta: float) -> void:
	var player_attack_speed = player_stats.get("attack_speed", 1.0)
	var enemy_attack_speed = enemy_stats.get("attack_speed", 1.0)
	
	# Applica modificatori velocità (ice/rage)
	if player_hero_node and player_hero_node.effect_stacks.get("ice", 0) > 0:
		player_attack_speed *= (1.0 - player_hero_node.effect_stacks["ice"] * 0.002)
	if player_hero_node and player_hero_node.effect_stacks.get("rage", 0) > 0:
		player_attack_speed *= (1.0 + player_hero_node.effect_stacks["rage"] * 0.001)
	
	if enemy_hero_node and enemy_hero_node.effect_stacks.get("ice", 0) > 0:
		enemy_attack_speed *= (1.0 - enemy_hero_node.effect_stacks["ice"] * 0.002)
	if enemy_hero_node and enemy_hero_node.effect_stacks.get("rage", 0) > 0:
		enemy_attack_speed *= (1.0 + enemy_hero_node.effect_stacks["rage"] * 0.001)
	
	player_attack_timer += delta * player_attack_speed
	enemy_attack_timer += delta * enemy_attack_speed

func check_and_execute_attacks() -> void:
	# Player attacca
	if player_attack_timer >= 1.0 and player_hero_node and player_hero_node.can_attack():
		execute_attack("player", "enemy")
		player_attack_timer = 0.0
	
	# Enemy attacca
	if enemy_attack_timer >= 1.0 and enemy_hero_node and enemy_hero_node.can_attack():
		execute_attack("enemy", "player")
		enemy_attack_timer = 0.0

func execute_attack(attacker: String, target: String) -> void:
	var attacker_node = player_hero_node if attacker == "player" else enemy_hero_node
	var target_node = enemy_hero_node if target == "enemy" else player_hero_node
	var attacker_stats = player_stats if attacker == "player" else enemy_stats
	var target_stats = enemy_stats if target == "enemy" else player_stats
	
	if not attacker_node or not target_node:
		return
	
	# Animazione attacco
	attacker_node.perform_attack(target_node)
	
	# Controlla schivata
	var dodge_chance = target_stats.get("dodge_chance", 0)
	if randf() * 100 < dodge_chance:
		print(target + " schiva l'attacco!")
		# Mostra effetto schivata
		if target_node.has_method("show_dodge_effect"):
			target_node.show_dodge_effect()
		return
	
	# Calcola danno
	var damage = calculate_damage(attacker_stats, target_stats)
	
	# Controlla critico
	var crit_chance = attacker_stats.get("crit_chance", 0)
	var is_crit = randf() * 100 < crit_chance
	if is_crit:
		damage *= 1.5  # Moltiplicatore critico base
		print(attacker + " colpo critico!")
	
	# Applica danno
	target_node.take_damage(damage, "physical")
	
	# Applica effetti on-hit
	apply_on_hit_effects(attacker, target, attacker_stats)
	
	emit_signal("attack_executed", attacker, target, damage, is_crit)

func calculate_damage(attacker_stats: Dictionary, target_stats: Dictionary) -> float:
	# Danno base
	var base_damage = attacker_stats.get("attack_damage", 24)
	
	# Aggiungi danno fisico bonus
	base_damage += attacker_stats.get("physical_damage", 0)
	
	# Applica difesa del target (riduzione percentuale)
	var defense = target_stats.get("physical_defense", 0)
	var damage_reduction = defense / (defense + 100.0)  # Formula armor
	base_damage *= (1.0 - damage_reduction)
	
	# Minimo 1 danno
	return max(1.0, base_damage)

func apply_on_hit_effects(attacker: String, target: String, attacker_stats: Dictionary) -> void:
	var target_node = enemy_hero_node if target == "enemy" else player_hero_node
	
	if not target_node:
		return
	
	# Applica effetti basati sul branch dell'attaccante
	var branch = attacker_stats.get("branch", "")
	
	match branch.to_lower():
		"rage":
			# Applica stack rage all'attaccante
			var attacker_node = player_hero_node if attacker == "player" else enemy_hero_node
			if attacker_node:
				attacker_node.add_effect_stack("rage", 5)
				emit_signal("effect_applied", attacker, "rage", 5)
		
		"ice":
			# Applica slow al target
			target_node.add_effect_stack("ice", 10)
			emit_signal("effect_applied", target, "ice", 10)
		
		"toxin":
			# Applica poison al target
			target_node.add_effect_stack("toxin", 3)
			emit_signal("effect_applied", target, "toxin", 3)
		
		"wound":
			# Applica vulnerabilità al target
			target_node.add_effect_stack("wound", 2)
			emit_signal("effect_applied", target, "wound", 2)
		
		"shield":
			# Applica shield all'attaccante
			var attacker_node = player_hero_node if attacker == "player" else enemy_hero_node
			if attacker_node:
				attacker_node.add_effect_stack("shield", 5)
				emit_signal("effect_applied", attacker, "shield", 5)

func process_regeneration(delta: float) -> void:
	# Rigenera HP player
	if player_hero_node and player_stats.get("hp_regen", 0) > 0:
		var regen = player_stats["hp_regen"] * delta
		player_hero_node.heal(regen)
	
	# Rigenera HP enemy
	if enemy_hero_node and enemy_stats.get("hp_regen", 0) > 0:
		var regen = enemy_stats["hp_regen"] * delta
		enemy_hero_node.heal(regen)
	
	# Rigenera mana (già gestito in hero3d.gd)

func apply_sudden_death(delta: float) -> void:
	# Aumenta danno progressivamente dopo sudden death
	var sudden_death_multiplier = 1.0 + (duel_time - sudden_death_time) * 0.1
	
	# Applica danno crescente a entrambi
	if player_hero_node:
		player_hero_node.take_damage(5 * sudden_death_multiplier * delta, "pure")
	if enemy_hero_node:
		enemy_hero_node.take_damage(5 * sudden_death_multiplier * delta, "pure")

func check_victory_conditions() -> void:
	var player_dead = player_hero_node and player_hero_node.current_hp <= 0
	var enemy_dead = enemy_hero_node and enemy_hero_node.current_hp <= 0
	
	if player_dead and enemy_dead:
		# Pareggio
		end_duel("draw")
	elif player_dead:
		# Enemy vince
		end_duel("enemy")
	elif enemy_dead:
		# Player vince
		end_duel("player")

func force_duel_end() -> void:
	# Timeout - vince chi ha più HP percentuale
	var player_hp_pct = 0.0
	var enemy_hp_pct = 0.0
	
	if player_hero_node:
		player_hp_pct = player_hero_node.get_hp_percentage()
	if enemy_hero_node:
		enemy_hp_pct = enemy_hero_node.get_hp_percentage()
	
	if player_hp_pct > enemy_hp_pct:
		end_duel("player")
	elif enemy_hp_pct > player_hp_pct:
		end_duel("enemy")
	else:
		end_duel("draw")

func end_duel(winner: String) -> void:
	duel_active = false
	set_process(false)
	
	# Calcola HP persi
	var hp_lost = 0
	if winner == "enemy" and player_hero_node:
		# Player ha perso - calcola danno basato su win streak nemico
		if has_node("/root/EconomyManager"):
			var economy = get_node("/root/EconomyManager")
			var enemy_winstreak = enemy_data.get("win_streak", 0)
			hp_lost = economy.get_damage_for_winstreak(enemy_winstreak)
	
	# Mostra animazioni vittoria/sconfitta
	if winner == "player" and player_hero_node:
		player_hero_node.victory()
	elif winner == "enemy" and enemy_hero_node:
		enemy_hero_node.victory()
	
	emit_signal("duel_ended", winner, hp_lost)
	
	print("Duello terminato! Vincitore: ", winner)
	
	# Notifica GameManager
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if winner == "player":
			gm.win_duel()
		else:
			gm.lose_duel()

func update_timer_display() -> void:
	if timer_label:
		var time_left = max(0, max_duel_time - duel_time)
		timer_label.text = "%02d:%02d" % [int(time_left) / 60, int(time_left) % 60]
		
		# Cambia colore se sudden death
		if duel_time >= sudden_death_time:
			timer_label.modulate = Color(1.0, 0.3, 0.3)
		else:
			timer_label.modulate = Color.WHITE

func get_duel_progress() -> Dictionary:
	return {
		"time": duel_time,
		"player_hp": player_hero_node.get_hp_percentage() if player_hero_node else 0,
		"enemy_hp": enemy_hero_node.get_hp_percentage() if enemy_hero_node else 0,
		"is_sudden_death": duel_time >= sudden_death_time
	}