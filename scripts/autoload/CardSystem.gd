# scripts/autoload/CardSystem.gd
extends Node

signal card_purchased(card_data: Dictionary)
signal card_upgraded(card_data: Dictionary, new_level: int)

# Dati caricati dai JSON
var all_cards: Array[Dictionary] = []          # <- elenco carte dal deck.json
var branches_data: Dictionary = {}             # <- branch_logos.json
var active_branches: Array[String] = []
var banned_branches: Array[String] = []

# Carte del giocatore
var player_cards: Dictionary = {}              # card_id:String -> {card_data, level, stacks}
var locked_cards: Array[String] = []

func _ready() -> void:
	load_card_data()
	load_branches_data()
	initialize_branches()

# --- Loading ------------------------------------------------------------------
func load_card_data() -> void:
	var file_path := "res://data/deck.json"
	if not FileAccess.file_exists(file_path):
		push_error("File deck.json non trovato")
		return

	var f := FileAccess.open(file_path, FileAccess.READ)
	var json_string: String = f.get_as_text()
	f.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		push_error("Errore parsing deck.json")
		return

	var cards_array: Array = []
	if typeof(json.data) == TYPE_DICTIONARY and json.data.has("cards"):
		cards_array = json.data["cards"]
	elif typeof(json.data) == TYPE_ARRAY:
		cards_array = json.data
	else:
		push_error("Formato deck.json non valido")
		return

	# qui forzi il tipo con sicurezza
	all_cards = cards_array.duplicate() as Array[Dictionary]
	print("Caricato deck con ", all_cards.size(), " carte")



func load_branches_data() -> void:
	var file_path := "res://data/branch_logos.json"
	if not FileAccess.file_exists(file_path):
		push_warning("branch_logos.json non trovato: uso elenco hardcoded")
		branches_data = {}
		return

	var f := FileAccess.open(file_path, FileAccess.READ)
	branches_data = JSON.parse_string(f.get_as_text())
	f.close()

# --- Branches -----------------------------------------------------------------
func initialize_branches() -> void:
	active_branches.clear()
	banned_branches.clear()

	# Se abbiamo il file, prendi le chiavi; altrimenti fallback alla lista fissa
	var all_branches: Array[String] = []
	if branches_data.size() > 0:
		for k in branches_data.keys():
			all_branches.append(str(k))
	else:
		all_branches = [
			"Assault","Essence","Rage","Ice","Toxin","Shield",
			"Healing","Power","Precision","Guardian","Dodge","Wound"
		]

	all_branches.shuffle()

	# 4 bannati, 8 attivi (limita se meno di 12)
	var banned_count: int = min(4, all_branches.size())
	for i in range(banned_count):
		banned_branches.append(all_branches[i])

	for i in range(banned_count, min(banned_count + 8, all_branches.size())):
		active_branches.append(all_branches[i])

	print("Rami attivi: ", active_branches)
	print("Rami bannati: ", banned_branches)

# --- Market / Filtri ----------------------------------------------------------
func get_available_cards(rarity_filter: String = "") -> Array[Dictionary]:
	var available: Array[Dictionary] = []

	for card in all_cards:
		# rami
		var card_branches := parse_card_branches(card)
		var has_active_branch := false
		for b in card_branches:
			if b in active_branches:
				has_active_branch = true
				break
		if not has_active_branch:
			continue

		# rarità (normalizza "common" -> "normal")
		var rarity := _normalize_rarity(card.get("rarity", "normal"))
		if rarity_filter != "" and rarity != _normalize_rarity(rarity_filter):
			continue

		available.append(card)

	return available

func parse_card_branches(card: Dictionary) -> Array[String]:
	var branches: Array[String] = []
	var branch_data: Variant = card.get("branch", [])  # << tipata esplicitamente

	if typeof(branch_data) == TYPE_ARRAY:
		for b in branch_data:
			branches.append(_cap(b))
	elif typeof(branch_data) == TYPE_STRING:
		for part in String(branch_data).split(","):
			var s := part.strip_edges()
			if not s.is_empty():
				branches.append(_cap(s))
	return branches

func can_show_card_rarity(rarity: String, player_level: int) -> bool:
	match _normalize_rarity(rarity):
		"normal":
			return true
		"epic":
			return player_level >= 10
		"legendary":
			return player_level >= 20
		_:
			return false

func get_card_cost(card: Dictionary) -> int:
	return int(card.get("cost", 100))

# --- Acquisto carte -----------------------------------------------------------
func purchase_card(card_id: String, player_coins: int) -> Dictionary:
	# Trova la carta (id è una String in deck.json)
	var card: Dictionary = {}
	for c in all_cards:
		if String(c.get("id","")) == card_id:
			card = c
			break
	if card.is_empty():
		return {"success": false, "error": "Carta non trovata"}

	var cost := get_card_cost(card)
	if player_coins < cost:
		return {"success": false, "error": "Coins insufficienti"}

	# Aggiungi o aggiorna
	if player_cards.has(card_id):
		var current_level: int = int(player_cards[card_id]["level"])
		var max_level: int = get_max_card_level(card)
		if current_level < max_level:
			var new_level := current_level + 1
			player_cards[card_id]["level"] = new_level
			player_cards[card_id]["stacks"] = get_card_stacks_for_level(card, new_level)
			emit_signal("card_upgraded", card, new_level)
		else:
			return {"success": false, "error": "Carta già al livello massimo"}
	else:
		player_cards[card_id] = {
			"card_data": card,
			"level": 1,
			"stacks": get_card_stacks_for_level(card, 1)
		}
		emit_signal("card_purchased", card)

	return {"success": true, "coins_spent": cost}

func get_max_card_level(card: Dictionary) -> int:
	var levels: Variant = card.get("levels", null)   # << Variant
	return levels.size() if typeof(levels) == TYPE_ARRAY else 1

func get_card_stacks_for_level(card: Dictionary, level: int) -> int:
	var levels: Variant = card.get("levels", null)   # << Variant
	if typeof(levels) == TYPE_ARRAY and level > 0 and level <= levels.size():
		var level_data: Dictionary = levels[level - 1]
		if level_data.has("parameters"):
			return int(level_data["parameters"].get("stacks", 0))
	return 0

# Effetti: per il deck attuale basta restituire il dizionario "effects"
func apply_card_effects(card: Dictionary, _level: int) -> Dictionary:
	if card.has("effects") and typeof(card["effects"]) == TYPE_DICTIONARY:
		return card["effects"]
	return {}

# --- Market utilities ---------------------------------------------------------
func get_random_market_cards(count: int, player_level: int) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var result: Array[Dictionary] = []

	for card in all_cards:
		if not can_show_card_rarity(card.get("rarity", "normal"), player_level):
			continue

		var has_active := false
		for b in parse_card_branches(card):
			if b in active_branches:
				has_active = true
				break
		if has_active:
			available.append(card)

	available.shuffle()
	for i in range(min(count, available.size())):
		result.append(available[i])
	return result

# --- Locking ------------------------------------------------------------------
func lock_card(card_id: String) -> void:
	if not (card_id in locked_cards):
		locked_cards.append(card_id)

func unlock_card(card_id: String) -> void:
	locked_cards.erase(card_id)

func is_card_locked(card_id: String) -> bool:
	return card_id in locked_cards

func clear_locked_cards() -> void:
	locked_cards.clear()

# --- Punti ramo / Livello eroe -----------------------------------------------
func get_branch_points() -> Dictionary:
	var points: Dictionary = {}
	for b in active_branches:
		points[b] = 0

	for card_id in player_cards.keys():
		var card: Dictionary = player_cards[card_id]["card_data"]
		var rarity := _normalize_rarity(card.get("rarity", "normal"))
		var rarity_points := 1
		match rarity:
			"epic":
				rarity_points = 2
			"legendary":
				rarity_points = 3

		for b in parse_card_branches(card):
			if b in active_branches:
				points[b] = int(points.get(b, 0)) + rarity_points

	return points

func calculate_hero_level() -> int:
	var total_points := 0
	var bp := get_branch_points()
	for b in bp.keys():
		total_points += int(bp[b])

	if total_points >= 40:
		return 5
	elif total_points >= 20:
		return 4
	elif total_points >= 10:
		return 3
	elif total_points >= 4:
		return 2
	return 1

# --- Helpers ------------------------------------------------------------------
func _normalize_rarity(r: String) -> String:
	var rr := r.to_lower()
	if rr == "common" or rr == "normale":
		return "normal"
	return rr

func _cap(s: String) -> String:
	if s.is_empty():
		return s
	return s.substr(0,1).to_upper() + s.substr(1).to_lower()
