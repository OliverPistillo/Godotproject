# scripts/utils/constants.gd
extends Node

# ===== GAME SETTINGS =====
const GAME_VERSION = "0.1.0"
const MAX_PLAYERS = 8
const MAX_ROUNDS = 10
const STARTING_HP = 50

# ===== TIMING =====
const PREPARATION_TIME = 20.0
const DUEL_MAX_TIME = 60.0
const SUDDEN_DEATH_TIME = 45.0
const TRANSITION_TIME = 2.0
const ANIMATION_SPEED = 0.3

# ===== ECONOMY =====
const COINS_PER_ROUND = 300
const BASE_INCOME = 250
const ROLL_COST = 20
const RANDOM_CARD_COST = 100
const INTEREST_RATE = 10  # Coins per 100 possedute
const INTEREST_MAX = 100
const WIN_BONUS = 50
const WIN_STREAK_BONUS = 20
const WIN_STREAK_MAX = 100
const HP_LOSS_BONUS = 15
const LOSE_STREAK_BONUS = 15
const LOSE_STREAK_MAX = 60

# ===== CARDS =====
const CARD_COST_NORMAL = 100
const CARD_COST_EPIC = 200
const CARD_COST_LEGENDARY = 300
const CARDS_IN_MARKET = 3
const MAX_CARD_LEVEL = 5

# Punti ramo per rarità
const BRANCH_POINTS = {
	"normal": 1,
	"epic": 2,
	"legendary": 3
}

# Soglie livello eroe
const HERO_LEVEL_THRESHOLDS = {
	1: 0,
	2: 4,
	3: 10,
	4: 20,
	5: 40
}

# Sblocco rarità per livello
const RARITY_UNLOCK_LEVEL = {
	"normal": 0,
	"epic": 10,
	"legendary": 20
}

# ===== BRANCHES =====
const TOTAL_BRANCHES = 12
const ACTIVE_BRANCHES_PER_GAME = 8
const BANNED_BRANCHES_PER_GAME = 4

const BRANCH_NAMES = [
	"Wound", "Essence", "Rage", "Ice", "Toxin", "Shield",
	"Healing", "Power", "Precision", "Guardian", "Assault", "Dodge"
]

# Colori dei rami
const BRANCH_COLORS = {
	"Wound": Color(0.7, 0.2, 0.2),
	"Essence": Color(0.5, 0.2, 0.8),
	"Rage": Color(0.9, 0.3, 0.2),
	"Ice": Color(0.3, 0.7, 0.9),
	"Toxin": Color(0.3, 0.8, 0.3),
	"Shield": Color(0.2, 0.4, 0.8),
	"Healing": Color(0.9, 0.6, 0.7),
	"Power": Color(0.9, 0.6, 0.2),
	"Precision": Color(0.9, 0.9, 0.3),
	"Guardian": Color(0.5, 0.5, 0.6),
	"Assault": Color(0.8, 0.2, 0.2),
	"Dodge": Color(0.4, 0.6, 0.9)
}

# ===== COMBAT =====
const BASE_ATTACK_DAMAGE = 24
const BASE_ATTACK_SPEED = 1.0
const BASE_CRIT_CHANCE = 15
const BASE_CRIT_MULTIPLIER = 1.5
const BASE_DODGE_CHANCE = 12
const MAX_DODGE_CHANCE = 75
const BASE_MANA_REGEN = 9
const MAX_MANA = 100

# ===== EFFECTS =====
const MAX_EFFECT_STACKS = 999

# Decadimento effetti (per secondo)
const EFFECT_DECAY_RATES = {
	"ice": 2.0,
	"rage": 1.0,
	"toxin": 0.0,  # Decade solo con tick
	"wound": 0.0,  # Non decade
	"shield": 0.0  # Decade solo quando colpito
}

# Modificatori effetti
const EFFECT_MODIFIERS = {
	"ice_slow_per_stack": 0.002,  # 0.2% rallentamento per stack
	"rage_speed_per_stack": 0.001,  # 0.1% velocità per stack
	"toxin_damage_per_stack": 0.3,
	"toxin_tick_interval": 0.5,
	"wound_amplification_per_stack": 0.001,  # 0.1% amplificazione per stack
	"shield_reduction_per_stack": 0.002,  # 0.2% riduzione danno per stack
	"shield_loss_on_hit": 5
}

# ===== DAMAGE TYPES =====
const DAMAGE_TYPES = {
	"physical": {
		"evadable": true,
		"critable": true,
		"affected_by_shields": true
	},
	"magic": {
		"evadable": false,
		"critable": true,
		"affected_by_shields": true
	},
	"pure": {
		"evadable": false,
		"critable": false,
		"affected_by_shields": false
	},
	"toxin": {
		"evadable": false,
		"critable": false,
		"affected_by_shields": true
	},
	"chaos": {
		"evadable": false,
		"critable": false,
		"affected_by_shields": false
	}
}

# ===== WIN STREAK DAMAGE =====
const WINSTREAK_DAMAGE = {
	0: 2,
	1: 3,
	2: 4,
	3: 5,
	4: 7,
	5: 10,
	6: 13,
	7: 16,
	8: 20
}

# ===== UI =====
const UI_ANIMATION_DURATION = 0.2
const UI_HOVER_SCALE = 1.1
const DAMAGE_NUMBER_DURATION = 1.0
const DAMAGE_NUMBER_RISE_HEIGHT = 2.0

# ===== COLORS =====
const COLOR_HEALTH = Color(0.8, 0.2, 0.2)
const COLOR_MANA = Color(0.2, 0.4, 0.8)
const COLOR_EXPERIENCE = Color(0.8, 0.7, 0.2)
const COLOR_COIN = Color(0.9, 0.7, 0.2)

# Colori rarità
const RARITY_COLORS = {
	"normal": Color(0.3, 0.3, 0.7),
	"epic": Color(0.6, 0.3, 0.7),
	"legendary": Color(0.9, 0.7, 0.2)
}

# ===== PATHS =====
const PATH_HEROES_DATA = "res://data/heroes.json"
const PATH_CARDS_DATA = "res://data/deck.json"
const PATH_ECONOMY_DATA = "res://data/economy.json"
const PATH_BRANCHES_DATA = "res://data/branch_logos.json"

const PATH_HERO_MODELS = "res://assets/models/heroes/"
const PATH_CARD_MODELS = "res://assets/models/cards/"
const PATH_BRANCH_ICONS = "res://assets/textures/cards/icons/branches/"
const PATH_CARD_BACKGROUNDS = "res://assets/textures/cards/backgrounds/"

# ===== SCENES =====
const SCENE_MAIN_MENU = "res://scenes/ui/main_menu.tscn"
const SCENE_CHARACTER_SELECT = "res://scenes/ui/character_selection.tscn"
const SCENE_BATTLE = "res://scenes/game/battle_scene.tscn"
const SCENE_MARKET = "res://scenes/ui/market.tscn"

# ===== NETWORK =====
const DEFAULT_PORT = 7000
const MAX_CLIENTS = 8
const NETWORK_TIMEOUT = 10.0

# ===== DEBUG =====
const DEBUG_MODE = true
const SHOW_FPS = true
const SHOW_STATS = true
const GOD_MODE = false
const UNLIMITED_COINS = false

# ===== FUNCTIONS =====
func get_damage_for_winstreak(streak: int) -> int:
	return WINSTREAK_DAMAGE.get(min(streak, 8), 20)

func get_hero_level_from_points(points: int) -> int:
	if points >= 40:
		return 5
	elif points >= 20:
		return 4
	elif points >= 10:
		return 3
	elif points >= 4:
		return 2
	else:
		return 1

func get_rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity.to_lower(), Color.WHITE)

func get_branch_color(branch: String) -> Color:
	return BRANCH_COLORS.get(branch, Color.WHITE)

func can_show_rarity(rarity: String, hero_level: int) -> bool:
	var required_level = RARITY_UNLOCK_LEVEL.get(rarity.to_lower(), 0)
	return hero_level >= required_level

func format_time(seconds: float) -> String:
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]

func format_coins(amount: int) -> String:
	if amount >= 1000:
		return "%.1fk" % (amount / 1000.0)
	return str(amount)