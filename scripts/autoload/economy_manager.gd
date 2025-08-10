# scripts/autoload/EconomyManager.gd
extends Node

signal coins_changed(new_amount: int)
signal interest_calculated(amount: int)
signal streak_bonus(type: String, amount: int)

# Dati economia caricati da JSON
var economy_data: Dictionary = {}

# Stato corrente
var player_coins: int = 0
var win_streak: int = 0
var lose_streak: int = 0
var last_hp_lost: int = 0

# Costanti economia (da economy.json)
var coins_per_round: int = 300
var roll_cost: int = 20
var random_card_cost: int = 100
var base_income: int = 250
var interest_rate: int = 10
var interest_max: int = 100
var win_bonus: int = 50
var win_streak_bonus: int = 20
var win_streak_max: int = 100
var hp_loss_bonus: int = 15
var lose_streak_bonus: int = 15
var lose_streak_max: int = 60

func _ready() -> void:
	load_economy_data()
	reset_economy()

func load_economy_data() -> void:
	var file_path = "res://data/economy.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			economy_data = json.data
			parse_economy_values()
			print("Economy data caricati con successo")
		else:
			push_error("Errore parsing economy.json")
	else:
		push_error("File economy.json non trovato")

func parse_economy_values() -> void:
	coins_per_round = economy_data.get("coins_per_round", 300)
	roll_cost = economy_data.get("roll_cost", 20)
	random_card_cost = economy_data.get("random_card_cost", 100)
	
	# Valori non presenti nel JSON originale ma descritti nel documento
	base_income = 250  # Reddito base post-duello
	interest_rate = 10  # 10 coins per 100 possedute
	interest_max = 100  # Max interesse
	win_bonus = 50
	win_streak_bonus = 20
	win_streak_max = 100
	hp_loss_bonus = 15
	lose_streak_bonus = 15
	lose_streak_max = 60

func reset_economy() -> void:
	player_coins = economy_data.get("starting_coins", 0)
	win_streak = 0
	lose_streak = 0
	last_hp_lost = 0
	emit_signal("coins_changed", player_coins)

func start_new_round() -> void:
	# Aggiungi coins base del round
	add_coins(coins_per_round)
	
	# Calcola e aggiungi interesse
	var interest = calculate_interest()
	if interest > 0:
		add_coins(interest)
		emit_signal("interest_calculated", interest)

func calculate_interest() -> int:
	# 10 coins ogni 100 possedute, max 100
	var interest = (player_coins / 100) * interest_rate
	return min(interest, interest_max)

func process_duel_result(won: bool, hp_lost: int = 0) -> void:
	# Reddito base post-duello
	add_coins(base_income)
	
	if won:
		process_victory()
	else:
		process_defeat(hp_lost)
	
	last_hp_lost = hp_lost

func process_victory() -> void:
	# Bonus vittoria
	add_coins(win_bonus)
	
	# Incrementa win streak e resetta lose streak
	win_streak += 1
	lose_streak = 0
	
	# Calcola bonus win streak
	var streak_bonus = min(win_streak * win_streak_bonus, win_streak_max)
	if streak_bonus > 0:
		add_coins(streak_bonus)
		emit_signal("streak_bonus", "win", streak_bonus)

func process_defeat(hp_lost: int) -> void:
	# Bonus per HP persi
	var hp_bonus = hp_lost * hp_loss_bonus
	add_coins(hp_bonus)
	
	# Incrementa lose streak e resetta win streak
	lose_streak += 1
	win_streak = 0
	
	# Calcola bonus lose streak
	var streak_bonus = min(lose_streak * lose_streak_bonus, lose_streak_max)
	if streak_bonus > 0:
		add_coins(streak_bonus)
		emit_signal("streak_bonus", "lose", streak_bonus)

func add_coins(amount: int) -> void:
	player_coins += amount
	player_coins = max(0, player_coins)  # Non può andare sotto zero
	emit_signal("coins_changed", player_coins)

func spend_coins(amount: int) -> bool:
	if can_afford(amount):
		player_coins -= amount
		emit_signal("coins_changed", player_coins)
		return true
	return false

func can_afford(amount: int) -> bool:
	return player_coins >= amount

func get_coins() -> int:
	return player_coins

func get_win_streak() -> int:
	return win_streak

func get_lose_streak() -> int:
	return lose_streak

func get_damage_table() -> Dictionary:
	# Tabella danni basata su win streak dell'avversario
	return economy_data.get("damage_per_winstreak", {
		"0": 2,
		"1": 3,
		"2": 4,
		"3": 5,
		"4": 7,
		"5": 10,
		"6": 13,
		"7": 16,
		"8": 20
	})

func get_damage_for_winstreak(streak: int) -> int:
	var damage_table = get_damage_table()
	var key = str(min(streak, 8))  # Max 8 streak
	return damage_table.get(key, 5)  # Default 5 se non trovato

# Funzioni helper per il market
func can_roll() -> bool:
	return can_afford(roll_cost)

func can_buy_random() -> bool:
	return can_afford(random_card_cost)

func roll_cards() -> bool:
	return spend_coins(roll_cost)

func buy_random_card() -> bool:
	return spend_coins(random_card_cost)

func buy_card(cost: int) -> bool:
	return spend_coins(cost)

# Funzione per calcolare il guadagno totale previsto
func calculate_expected_income(won: bool, hp_lost: int = 0) -> int:
	var total = base_income
	
	# Interesse
	total += calculate_interest()
	
	if won:
		total += win_bonus
		total += min((win_streak + 1) * win_streak_bonus, win_streak_max)
	else:
		total += hp_lost * hp_loss_bonus
		total += min((lose_streak + 1) * lose_streak_bonus, lose_streak_max)
	
	return total

# Info per UI
func get_economy_info() -> Dictionary:
	return {
		"coins": player_coins,
		"interest": calculate_interest(),
		"win_streak": win_streak,
		"lose_streak": lose_streak,
		"next_income": calculate_expected_income(false, 0)
	}

# Debug
func _to_string() -> String:
	return "Coins: %d | Interest: %d | Win: %d | Lose: %d" % [
		player_coins, 
		calculate_interest(),
		win_streak,
		lose_streak
	]