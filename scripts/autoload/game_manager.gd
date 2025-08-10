# scripts/autoload/GameManager.gd
extends Node

## ─────────────────────────────────────────────────────────────────────────────
## Signals
signal round_started(round_number: int)
signal preparation_phase_started()
signal duel_phase_started()
signal game_over(winner: String)
signal coins_changed(amount: int)
signal hp_changed(amount: int)

## ─────────────────────────────────────────────────────────────────────────────
## State
enum GameState { MENU, CHARACTER_SELECTION, PREPARATION, DUEL, ROUND_END, GAME_OVER }

var current_state: GameState = GameState.MENU
var current_round: int = 1
var player_coins: int = 0
var player_hp: int = 50
var win_streak: int = 0

var selected_hero: Dictionary = {}
var opponent_hero: Dictionary = {}

var active_branches: Array[String] = []
var banned_branches: Array[String] = []
var branch_points: Dictionary = {}  # branch_id -> points

var hero_level: int = 1
var cards_inventory: Array[Dictionary] = []
var locked_cards: Array[Dictionary] = []

## ─────────────────────────────────────────────────────────────────────────────
## Data (loaded from JSON)
var economy_data: Dictionary = {}
var branch_logos: Dictionary = {}   # "Assault" -> "res://..."
var heroes_data: Dictionary = {}    # { "heroes": [ {id, name, ...}, ... ] }
var deck_data: Dictionary = {}      # { "cards": [ ... ] }

## Timers
var preparation_timer: float = 20.0
var duel_timer: float = 0.0

## ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	load_game_data()
	initialize_branches()
	set_process(false)

## ─────────────────────────────────────────────────────────────────────────────
## Loading
func load_game_data() -> void:
	economy_data = load_json("res://data/economy.json")
	branch_logos = load_json("res://data/branch_logos.json")
	heroes_data = load_json("res://data/heroes.json")
	deck_data = load_json("res://data/deck.json")

func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("File non trovato: " + path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var txt: String = f.get_as_text()
	f.close()

	var json := JSON.new()
	var ok: int = json.parse(txt)
	if ok != OK:
		push_error("Errore parsing JSON: " + path + " (" + str(ok) + ")")
		return {}
	var data: Variant = json.data
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {"data": data}

## ─────────────────────────────────────────────────────────────────────────────
## Branches
func initialize_branches() -> void:
	var all_branches: Array[String] = []
	for k in branch_logos.keys():
		all_branches.append(str(k))
	all_branches.shuffle()

	var banned_count: int = 4
	var active_count: int = 8

	banned_branches.clear()
	active_branches.clear()
	branch_points.clear()

	for i in range(min(banned_count, all_branches.size())):
		banned_branches.append(all_branches[i])

	for i in range(banned_count, min(banned_count + active_count, all_branches.size())):
		var b: String = all_branches[i]
		active_branches.append(b)
		branch_points[b] = 0

func is_branch_active(branch: String) -> bool:
	var norm: String = _normalize_branch_single(branch)
	return norm in active_branches

## ─────────────────────────────────────────────────────────────────────────────
## Game flow
func start_new_game(hero_id: String) -> void:
	current_state = GameState.CHARACTER_SELECTION
	current_round = 1
	player_coins = economy_data.get("starting_coins", 0)
	player_hp = economy_data.get("starting_hp", 50)
	win_streak = 0
	hero_level = 1
	cards_inventory.clear()
	locked_cards.clear()

	selected_hero.clear()
	for hero in heroes_data.get("heroes", []):
		if hero.get("id", "") == hero_id:
			selected_hero = hero
			break

	if selected_hero.is_empty():
		push_warning("Hero con id '%s' non trovato: uso il primo disponibile." % hero_id)
		var list: Array = heroes_data.get("heroes", [])
		if list.size() > 0:
			selected_hero = list[0]

	start_new_round()

func start_new_round() -> void:
	emit_signal("round_started", current_round)
	add_coins(economy_data.get("coins_per_round", 300))
	select_random_opponent()
	start_preparation_phase()

func start_preparation_phase() -> void:
	current_state = GameState.PREPARATION
	preparation_timer = float(economy_data.get("preparation_phase", {}).get("duration", 20))
	emit_signal("preparation_phase_started")
	set_process(true)

func start_duel_phase() -> void:
	current_state = GameState.DUEL
	emit_signal("duel_phase_started")
	set_process(false)

	if has_node("/root/BattleManager"):
		get_node("/root/BattleManager").start_duel(selected_hero, opponent_hero)

func _process(delta: float) -> void:
	if current_state == GameState.PREPARATION:
		preparation_timer -= delta
		if preparation_timer <= 0.0:
			start_duel_phase()

## ─────────────────────────────────────────────────────────────────────────────
## Opponents
func select_random_opponent() -> void:
	var heroes: Array = heroes_data.get("heroes", [])
	var pool: Array = []
	for h in heroes:
		if h.get("id", "") != selected_hero.get("id", ""):
			pool.append(h)
	if pool.size() > 0:
		opponent_hero = pool[randi() % pool.size()]
	else:
		opponent_hero.clear()

## ─────────────────────────────────────────────────────────────────────────────
## Currency / HP
func add_coins(amount: int) -> void:
	player_coins += amount
	emit_signal("coins_changed", player_coins)

func spend_coins(amount: int) -> bool:
	if player_coins >= amount:
		player_coins -= amount
		emit_signal("coins_changed", player_coins)
		return true
	return false

func take_damage(damage: int) -> void:
	player_hp = maxi(0, player_hp - damage)
	emit_signal("hp_changed", player_hp)

	if player_hp <= 0:
		trigger_game_over()

## ─────────────────────────────────────────────────────────────────────────────
## Cards / Branch points / Levels
func add_card(card: Dictionary) -> void:
	cards_inventory.append(card)

	var branch_raw: String = str(card.get("branch", ""))
	var branch: String = _normalize_branch_single(branch_raw)
	var rarity: String = _normalize_rarity(str(card.get("rarity", "normal")))

	if branch in branch_points:
		var points_table: Dictionary = economy_data.get("rarity_points", {})
		var add_points: int = int(points_table.get(rarity, 1))
		branch_points[branch] += add_points
		check_hero_level()

func check_hero_level() -> void:
	var total_points: int = 0
	for b in branch_points.keys():
		total_points += int(branch_points[b])

	var levels: Dictionary = economy_data.get("hero_level_thresholds", {})
	if total_points >= int(levels.get("level_5", 40)):
		hero_level = 5
	elif total_points >= int(levels.get("level_4", 20)):
		hero_level = 4
	elif total_points >= int(levels.get("level_3", 10)):
		hero_level = 3
	elif total_points >= int(levels.get("level_2", 4)):
		hero_level = 2
	else:
		hero_level = 1

## ─────────────────────────────────────────────────────────────────────────────
## Duel results
func win_duel() -> void:
	win_streak += 1
	current_round += 1

	var max_rounds: int = int(economy_data.get("rounds", {}).get("max_rounds", 10))
	if current_round <= max_rounds:
		start_new_round()
	else:
		victory()

func lose_duel() -> void:
	var damage_table: Dictionary = economy_data.get("damage_per_winstreak", {})
	var opp_ws: int = int(opponent_hero.get("win_streak", 0))
	var damage: int = int(damage_table.get(str(opp_ws), 5))
	take_damage(damage)

	win_streak = 0
	current_round += 1

	var max_rounds: int = int(economy_data.get("rounds", {}).get("max_rounds", 10))
	if player_hp > 0 and current_round <= max_rounds:
		start_new_round()

## ─────────────────────────────────────────────────────────────────────────────
## End game
func trigger_game_over() -> void:
	current_state = GameState.GAME_OVER
	emit_signal("game_over", "defeat")
	_change_to_main_menu()

func victory() -> void:
	current_state = GameState.GAME_OVER
	emit_signal("game_over", "victory")
	_change_to_main_menu()

func reset_game() -> void:
	current_state = GameState.MENU
	current_round = 1
	player_coins = 0
	player_hp = 50
	win_streak = 0
	selected_hero.clear()
	opponent_hero.clear()
	cards_inventory.clear()
	locked_cards.clear()
	branch_points.clear()
	hero_level = 1

## ─────────────────────────────────────────────────────────────────────────────
## Helpers
func _change_to_main_menu() -> void:
	if Engine.is_editor_hint():
		return
	if ResourceLoader.exists("res://scenes/ui/MainMenu.tscn"):
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	else:
		push_warning("Scene MainMenu.tscn non trovata.")

func _normalize_branch_single(raw: String) -> String:
	var s: String = raw.strip_edges()
	if s.is_empty():
		return s
	return s.substr(0, 1).to_upper() + s.substr(1).to_lower()

func _normalize_rarity(r: String) -> String:
	var rr: String = r.to_lower()
	if rr == "common" or rr == "normale":
		return "normal"
	return rr
