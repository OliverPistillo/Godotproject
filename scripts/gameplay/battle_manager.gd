# scripts/autoload/BattleManager.gd
extends Node

signal attack_performed(attacker: String, damage: int, is_crit: bool)
signal damage_taken(target: String, damage: int)
signal battle_ended(winner: String)
signal hp_updated(hero: String, hp: int)

# Riferimenti agli eroi in battaglia
var player_hero: Dictionary = {}
var enemy_hero: Dictionary = {}

# Statistiche runtime
var player_current_hp: float = 0.0
var enemy_current_hp: float = 0.0
var player_current_mana: float = 0.0
var enemy_current_mana: float = 0.0

# Timer attacco
var player_attack_timer: float = 0.0
var enemy_attack_timer: float = 0.0

# Stato battaglia
var battle_active: bool = false
var battle_time: float = 0.0

# Effetti attivi
var player_effects: Array = []
var enemy_effects: Array = []

func _ready() -> void:
	set_process(false)

func start_duel(p_hero: Dictionary, e_hero: Dictionary) -> void:
	player_hero = p_hero.duplicate(true)
	enemy_hero = e_hero.duplicate(true)
	
	# Applica bonus carte del giocatore
	apply_card_bonuses()
	
	# Inizializza HP e Mana
	player_current_hp = player_hero["stats"]["max_hp"]
	enemy_current_hp = enemy_hero["stats"]["max_hp"]
	player_current_mana = 0
	enemy_current_mana = 0
	
	# Reset timer attacco
	player_attack_timer = 0.0
	enemy_attack_timer = 0.0
	
	# Reset effetti
	player_effects.clear()
	enemy_effects.clear()
	
	# Inizia battaglia
	battle_active = true
	battle_time = 0.0
	set_process(true)
	
	emit_signal("hp_updated", "player", player_current_hp)
	emit_signal("hp_updated", "enemy", enemy_current_hp)

func apply_card_bonuses() -> void:
	# Recupera bonus dalle carte del GameManager
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		for card in gm.cards_inventory:
			var effects = card.get("effects", {})
			for stat in effects:
				if stat in player_hero["stats"]:
					player_hero["stats"][stat] += effects[stat]

func _process(delta: float) -> void:
	if not battle_active:
		return
	
	battle_time += delta
	
	# Aggiorna timer attacco
	player_attack_timer += delta * player_hero["stats"]["attack_speed"]
	enemy_attack_timer += delta * enemy_hero["stats"]["attack_speed"]
	
	# Rigenera mana
	player_current_mana = min(100, player_current_mana + delta * player_hero["stats"]["mana_regen"])
	enemy_current_mana = min(100, enemy_current_mana + delta * enemy_hero["stats"]["mana_regen"])
	
	# Rigenera HP
	player_current_hp = min(player_hero["stats"]["max_hp"], 
		player_current_hp + delta * player_hero["stats"]["hp_regen"])
	enemy_current_hp = min(enemy_hero["stats"]["max_hp"], 
		enemy_current_hp + delta * enemy_hero["stats"]["hp_regen"])
	
	# Processa effetti attivi (veleno, sanguinamento, etc)
	process_effects(delta)
	
	# Controlla attacchi
	if player_attack_timer >= 1.0:
		perform_attack("player", "enemy")
		player_attack_timer = 0.0
	
	if enemy_attack_timer >= 1.0:
		perform_attack("enemy", "player")
		enemy_attack_timer = 0.0
	
	# Controlla fine battaglia
	check_battle_end()

func perform_attack(attacker: String, target: String) -> void:
	var attacker_stats = player_hero["stats"] if attacker == "player" else enemy_hero["stats"]
	var target_stats = enemy_hero["stats"] if target == "enemy" else player_hero["stats"]
	
	# Schivata
	if randf() * 100.0 < float(target_stats.get("dodge_chance", 0)):
		print(target + " schiva l'attacco!")
		return
	
	# Danno base
	var damage: float = calculate_damage(attacker_stats, target_stats)
	
	# Critico
	var is_crit: bool = randf() * 100.0 < float(attacker_stats.get("crit_chance", 0))
	if is_crit:
		damage *= 1.5
		if attacker_stats.has("crit_damage"):
			damage *= (1.0 + float(attacker_stats["crit_damage"]) / 100.0)
	
	# Applica danno
	apply_damage(target, damage)
	
	# Effetti ON-HIT (passiamo il danno calcolato)
	apply_attack_effects(attacker, target, attacker_stats, damage)
	
	emit_signal("attack_performed", attacker, int(round(damage)), is_crit)

func calculate_damage(attacker_stats: Dictionary, target_stats: Dictionary) -> float:
	var base_damage = 10.0  # Danno base
	
	# Aggiungi danno fisico
	if attacker_stats.has("physical_damage"):
		base_damage += attacker_stats["physical_damage"]
	
	# Aggiungi danno magico
	if attacker_stats.has("magic_damage"):
		base_damage += attacker_stats["magic_damage"]
	
	# Applica difese
	var physical_reduction = target_stats.get("physical_defense", 0) / 100.0
	var magic_reduction = target_stats.get("magic_defense", 0) / 100.0
	var avg_reduction = (physical_reduction + magic_reduction) / 2.0
	
	base_damage *= (1.0 - avg_reduction)
	
	# Riduzione danno generale
	if target_stats.has("damage_reduction"):
		base_damage *= (1.0 - target_stats["damage_reduction"] / 100.0)
	
	return max(1, base_damage)  # Minimo 1 danno

func apply_damage(target: String, damage: float) -> void:
	if target == "player":
		player_current_hp = max(0, player_current_hp - damage)
		emit_signal("hp_updated", "player", player_current_hp)
	else:
		enemy_current_hp = max(0, enemy_current_hp - damage)
		emit_signal("hp_updated", "enemy", enemy_current_hp)
	
	emit_signal("damage_taken", target, damage)

func apply_attack_effects(attacker: String, target: String, stats: Dictionary, dealt_damage: float) -> void:
	var target_effects = enemy_effects if target == "enemy" else player_effects

	# Veleno
	if stats.has("poison_damage") and stats["poison_damage"] > 0:
		if randf() < 0.3:
			add_effect(target_effects, "poison", float(stats["poison_damage"]), 3.0)

	# Sanguinamento
	if stats.has("bleed_chance") and randf() * 100.0 < float(stats["bleed_chance"]):
		add_effect(target_effects, "bleed", 2.0, 5.0)

	# Rallentamento (ghiaccio)
	if stats.has("slow_on_hit") and randf() < float(stats["slow_on_hit"]):
		add_effect(target_effects, "slow", 0.5, 2.0)

	# Rubavita
	if stats.has("lifesteal") and float(stats["lifesteal"]) > 0.0:
		var heal: float = dealt_damage * (float(stats["lifesteal"]) / 100.0)
		if attacker == "player":
			player_current_hp = min(player_hero["stats"]["max_hp"], player_current_hp + heal)
			emit_signal("hp_updated", "player", player_current_hp)
		else:
			enemy_current_hp = min(enemy_hero["stats"]["max_hp"], enemy_current_hp + heal)
			emit_signal("hp_updated", "enemy", enemy_current_hp)

func add_effect(effects_array: Array, type: String, value: float, duration: float) -> void:
	# Rimuovi effetto esistente dello stesso tipo
	for i in range(effects_array.size() - 1, -1, -1):
		if effects_array[i]["type"] == type:
			effects_array.remove_at(i)
	
	# Aggiungi nuovo effetto
	effects_array.append({
		"type": type,
		"value": value,
		"duration": duration,
		"time_left": duration
	})

func process_effects(delta: float) -> void:
	# Processa effetti giocatore
	for i in range(player_effects.size() - 1, -1, -1):
		var effect = player_effects[i]
		effect["time_left"] -= delta
		
		if effect["time_left"] <= 0:
			player_effects.remove_at(i)
			continue
		
		match effect["type"]:
			"poison":
				apply_damage("player", effect["value"] * delta)
			"bleed":
				apply_damage("player", effect["value"] * delta)
			"slow":
				# Applicato direttamente alle stats temporaneamente
				pass
	
	# Processa effetti nemico
	for i in range(enemy_effects.size() - 1, -1, -1):
		var effect = enemy_effects[i]
		effect["time_left"] -= delta
		
		if effect["time_left"] <= 0:
			enemy_effects.remove_at(i)
			continue
		
		match effect["type"]:
			"poison":
				apply_damage("enemy", effect["value"] * delta)
			"bleed":
				apply_damage("enemy", effect["value"] * delta)
			"slow":
				# Applicato direttamente alle stats temporaneamente
				pass

func check_battle_end() -> void:
	if player_current_hp <= 0:
		end_battle("enemy")
	elif enemy_current_hp <= 0:
		end_battle("player")

func end_battle(winner: String) -> void:
	battle_active = false
	set_process(false)
	
	emit_signal("battle_ended", winner)
	
	# Notifica GameManager
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if winner == "player":
			gm.win_duel()
		else:
			gm.lose_duel()

func get_player_hp_percentage() -> float:
	if player_hero.is_empty():
		return 0.0
	return (player_current_hp / player_hero["stats"]["max_hp"]) * 100.0

func get_enemy_hp_percentage() -> float:
	if enemy_hero.is_empty():
		return 0.0
	return (enemy_current_hp / enemy_hero["stats"]["max_hp"]) * 100.0
