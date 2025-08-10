# scripts/gameplay/round_manager.gd
extends Node

signal round_started(round_number: int)
signal round_ended(round_number: int)
signal preparation_started()
signal preparation_ended()
signal duel_started()
signal duel_ended(winner: String)
signal game_over(final_placement: int)
signal player_eliminated(player_id: String)

# Stati round
enum RoundState {
	WAITING,
	PREPARATION,
	TRANSITIONING,
	DUEL,
	ROUND_END
}

# Configurazione round
const MAX_ROUNDS = 10
const PREPARATION_TIME = 20.0
const TRANSITION_TIME = 2.0

# Stato corrente
var current_round: int = 1
var current_state: RoundState = RoundState.WAITING
var players_alive: int = 8
var eliminated_players: Array = []

# Timer
var state_timer: float = 0.0
var preparation_timer: float = 0.0

# Giocatori simulati (per testing)
var all_players: Array = []
var player_data: Dictionary = {}
var current_opponent: Dictionary = {}

# Matchmaking
var matchups: Array = []
var current_matchup_index: int = 0

# Riferimenti scene
@export var preparation_scene_path: String = "res://scenes/game/preparation_scene.tscn"
@export var duel_scene_path: String = "res://scenes/game/duel_scene.tscn"

var preparation_manager: Node
var duel_manager: Node

func _ready() -> void:
	initialize_players()
	set_process(false)

func initialize_players() -> void:
	# Crea 8 giocatori simulati per testing
	for i in range(8):
		var player = {
			"id": "player_" + str(i),
			"name": "Player " + str(i + 1),
			"hp": 50,
			"max_hp": 50,
			"coins": 0,
			"win_streak": 0,
			"lose_streak": 0,
			"hero": {},
			"cards": [],
			"is_human": i == 0  # Il primo è il giocatore umano
		}
		all_players.append(player)
	
	# Imposta il giocatore principale
	player_data = all_players[0]
	players_alive = all_players.size()

func start_game() -> void:
	current_round = 1
	current_state = RoundState.WAITING
	eliminated_players.clear()
	
	# Reset HP di tutti i giocatori
	for player in all_players:
		player["hp"] = player["max_hp"]
		player["win_streak"] = 0
		player["lose_streak"] = 0
	
	start_round()

func start_round() -> void:
	if current_round > MAX_ROUNDS:
		end_game()
		return
	
	emit_signal("round_started", current_round)
	print("=== ROUND ", current_round, " INIZIATO ===")
	print("Giocatori rimasti: ", players_alive)
	
	# Genera matchup
	generate_matchups()
	
	# Distribuisci coins
	distribute_round_coins()
	
	# Inizia fase preparazione
	start_preparation_phase()

func generate_matchups() -> void:
	matchups.clear()
	var available_players = []
	
	# Filtra solo giocatori vivi
	for player in all_players:
		if player["hp"] > 0:
			available_players.append(player)
	
	# Mescola per matchmaking casuale
	available_players.shuffle()
	
	# Crea coppie
	for i in range(0, available_players.size(), 2):
		if i + 1 < available_players.size():
			matchups.append({
				"player1": available_players[i],
				"player2": available_players[i + 1]
			})
		else:
			# Giocatore dispari - combatte contro un "fantasma"
			matchups.append({
				"player1": available_players[i],
				"player2": create_ghost_player()
			})
	
	# Trova matchup del giocatore
	for i in range(matchups.size()):
		var matchup = matchups[i]
		if matchup["player1"]["id"] == player_data["id"]:
			current_opponent = matchup["player2"]
			current_matchup_index = i
			break
		elif matchup["player2"]["id"] == player_data["id"]:
			current_opponent = matchup["player1"]
			current_matchup_index = i
			break

func create_ghost_player() -> Dictionary:
	# Crea un avversario "fantasma" per giocatore dispari
	return {
		"id": "ghost",
		"name": "Ghost",
		"hp": 1,
		"max_hp": 1,
		"hero": {},
		"win_streak": 0,
		"is_ghost": true
	}

func distribute_round_coins() -> void:
	# Distribuisci coins base
	if has_node("/root/EconomyManager"):
		var economy = get_node("/root/EconomyManager")
		economy.start_new_round()
	
	# Coins per tutti i giocatori simulati
	for player in all_players:
		if player["hp"] > 0 and not player["is_human"]:
			player["coins"] += 300  # Coins base del round

func start_preparation_phase() -> void:
	current_state = RoundState.PREPARATION
	preparation_timer = PREPARATION_TIME
	state_timer = 0.0
	
	emit_signal("preparation_started")
	
	# Carica scena preparazione se necessario
	if preparation_scene_path != "":
		load_preparation_scene()
	
	# Mostra market
	show_market()
	
	set_process(true)

func load_preparation_scene() -> void:
	# Implementa caricamento scena preparazione
	pass

func show_market() -> void:
	# Mostra UI market
	if has_node("/root/BattleScene/CanvasLayer/Market"):
		var market = get_node("/root/BattleScene/CanvasLayer/Market")
		market.visible = true
		market.time_remaining = PREPARATION_TIME

func end_preparation_phase() -> void:
	current_state = RoundState.TRANSITIONING
	state_timer = 0.0
	
	emit_signal("preparation_ended")
	
	# Nascondi market
	if has_node("/root/BattleScene/CanvasLayer/Market"):
		var market = get_node("/root/BattleScene/CanvasLayer/Market")
		market.visible = false
	
	# Simula acquisti AI
	simulate_ai_purchases()

func simulate_ai_purchases() -> void:
	# Simula acquisti carte per giocatori AI
	for player in all_players:
		if player["hp"] > 0 and not player.get("is_human", false):
			# Logica semplice: spendi 200-300 coins in carte casuali
			var coins_to_spend = randi_range(200, min(300, player["coins"]))
			player["coins"] = max(0, player["coins"] - coins_to_spend)
			# Qui si potrebbero aggiungere carte simulate all'inventario AI

func start_duel_phase() -> void:
	current_state = RoundState.DUEL
	state_timer = 0.0
	
	emit_signal("duel_started")
	
	print("Duello: ", player_data["name"], " vs ", current_opponent["name"])
	
	# Avvia duello per il giocatore
	if has_node("/root/DuelPhase"):
		var duel_phase = get_node("/root/DuelPhase")
		
		# Ottieni nodi hero 3D
		var player_hero = get_player_hero_node()
		var enemy_hero = get_enemy_hero_node()
		
		duel_phase.start_duel(
			player_hero,
			enemy_hero,
			player_data,
			current_opponent
		)
		
		# Connetti al segnale di fine duello
		if not duel_phase.is_connected("duel_ended", _on_duel_ended):
			duel_phase.duel_ended.connect(_on_duel_ended)
	else:
		# Fallback: simula risultato duello
		simulate_duel_result()

func get_player_hero_node() -> Node3D:
	# Ottieni il nodo 3D dell'eroe del giocatore
	if has_node("/root/BattleScene/PlayerHero"):
		return get_node("/root/BattleScene/PlayerHero")
	return null

func get_enemy_hero_node() -> Node3D:
	# Ottieni il nodo 3D dell'eroe nemico
	if has_node("/root/BattleScene/EnemyHero"):
		return get_node("/root/BattleScene/EnemyHero")
	return null

func simulate_duel_result() -> void:
	# Simula risultato per testing
	await get_tree().create_timer(3.0).timeout
	
	var player_won = randf() > 0.5
	_on_duel_ended(player_won if "player" else "enemy", 0)

func _on_duel_ended(winner: String, hp_lost: int) -> void:
	current_state = RoundState.ROUND_END
	
	# Aggiorna risultati
	process_duel_results(winner, hp_lost)
	
	# Simula altri duelli
	simulate_other_duels()
	
	# Controlla eliminazioni
	check_eliminations()
	
	emit_signal("duel_ended", winner)
	
	# Passa al round successivo dopo un delay
	await get_tree().create_timer(2.0).timeout
	end_round()

func process_duel_results(winner: String, hp_lost: int) -> void:
	var player_won = winner == "player"
	
	if player_won:
		# Giocatore ha vinto
		player_data["win_streak"] += 1
		player_data["lose_streak"] = 0
		
		# L'avversario perde HP
		if not current_opponent.get("is_ghost", false):
			var damage = calculate_winstreak_damage(player_data["win_streak"])
			current_opponent["hp"] = max(0, current_opponent["hp"] - damage)
	else:
		# Giocatore ha perso
		player_data["lose_streak"] += 1
		player_data["win_streak"] = 0
		player_data["hp"] = max(0, player_data["hp"] - hp_lost)
		
		# L'avversario vince
		if not current_opponent.get("is_ghost", false):
			current_opponent["win_streak"] += 1
			current_opponent["lose_streak"] = 0
	
	# Aggiorna economia
	if has_node("/root/EconomyManager"):
		var economy = get_node("/root/EconomyManager")
		economy.process_duel_result(player_won, hp_lost)

func calculate_winstreak_damage(streak: int) -> int:
	# Tabella danni da win streak
	var damage_table = {
		0: 2, 1: 3, 2: 4, 3: 5,
		4: 7, 5: 10, 6: 13, 7: 16, 8: 20
	}
	return damage_table.get(min(streak, 8), 20)

func simulate_other_duels() -> void:
	# Simula risultati degli altri duelli
	for matchup in matchups:
		if matchup["player1"]["id"] == player_data["id"] or matchup["player2"]["id"] == player_data["id"]:
			continue  # Skip duello del giocatore
		
		# Simula vincitore casuale
		var p1_wins = randf() > 0.5
		
		if p1_wins:
			matchup["player1"]["win_streak"] += 1
			matchup["player1"]["lose_streak"] = 0
			
			var damage = calculate_winstreak_damage(matchup["player1"]["win_streak"])
			matchup["player2"]["hp"] = max(0, matchup["player2"]["hp"] - damage)
			matchup["player2"]["win_streak"] = 0
			matchup["player2"]["lose_streak"] += 1
		else:
			matchup["player2"]["win_streak"] += 1
			matchup["player2"]["lose_streak"] = 0
			
			var damage = calculate_winstreak_damage(matchup["player2"]["win_streak"])
			matchup["player1"]["hp"] = max(0, matchup["player1"]["hp"] - damage)
			matchup["player1"]["win_streak"] = 0
			matchup["player1"]["lose_streak"] += 1

func check_eliminations() -> void:
	var newly_eliminated = []
	
	for player in all_players:
		if player["hp"] <= 0 and not player["id"] in eliminated_players:
			eliminated_players.append(player["id"])
			newly_eliminated.append(player)
			players_alive -= 1
			
			emit_signal("player_eliminated", player["id"])
			print(player["name"], " è stato eliminato!")
	
	# Controlla se il giocatore è stato eliminato
	if player_data["hp"] <= 0:
		var placement = players_alive + 1
		end_game_for_player(placement)

func end_round() -> void:
	emit_signal("round_ended", current_round)
	
	current_round += 1
	
	# Controlla condizioni fine partita
	if players_alive <= 1:
		end_game()
	elif current_round > MAX_ROUNDS:
		end_game()
	else:
		# Inizia nuovo round
		start_round()

func end_game() -> void:
	print("=== PARTITA TERMINATA ===")
	
	# Calcola piazzamento finale
	var final_placement = calculate_final_placement()
	
	emit_signal("game_over", final_placement)
	
	# Torna al menu principale
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if final_placement == 1:
			gm.victory()
		else:
			gm.game_over()

func end_game_for_player(placement: int) -> void:
	print("Giocatore eliminato! Piazzamento: #", placement)
	
	emit_signal("game_over", placement)
	
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		gm.game_over()

func calculate_final_placement() -> int:
	# Conta quanti giocatori hanno più HP del giocatore
	var players_with_more_hp = 0
	
	for player in all_players:
		if player["id"] != player_data["id"] and player["hp"] > player_data["hp"]:
			players_with_more_hp += 1
	
	return players_with_more_hp + 1

func _process(delta: float) -> void:
	state_timer += delta
	
	match current_state:
		RoundState.PREPARATION:
			preparation_timer -= delta
			if preparation_timer <= 0:
				end_preparation_phase()
		
		RoundState.TRANSITIONING:
			if state_timer >= TRANSITION_TIME:
				start_duel_phase()
		
		RoundState.DUEL:
			# Il duello è gestito da DuelPhase
			pass
		
		RoundState.ROUND_END:
			# Gestito da end_round()
			pass

func skip_preparation() -> void:
	# Permette al giocatore di saltare la preparazione
	if current_state == RoundState.PREPARATION:
		preparation_timer = 0.0

func get_round_info() -> Dictionary:
	return {
		"round": current_round,
		"max_rounds": MAX_ROUNDS,
		"players_alive": players_alive,
		"state": RoundState.keys()[current_state],
		"opponent": current_opponent.get("name", ""),
		"player_hp": player_data["hp"],
		"player_placement": calculate_final_placement()
	}

func get_all_players_info() -> Array:
	var info = []
	for player in all_players:
		info.append({
			"name": player["name"],
			"hp": player["hp"],
			"eliminated": player["hp"] <= 0,
			"win_streak": player["win_streak"]
		})
	return info