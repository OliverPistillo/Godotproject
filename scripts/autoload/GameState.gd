extends Node

var round: int = 1
var coins: int = 0
var hp: int = 50
var selected_hero: String = ""
var active_branches: Array = []
var card_counts: Dictionary = {}

func _ready():
    reset_game()

func reset_game():
    round = 1
    coins = CardDB.economy.get("coins_per_round", 300)
    hp = CardDB.economy.get("starting_hp", 50)
    card_counts.clear()

func next_round():
    round += 1
    coins += CardDB.economy.get("coins_per_round", 300)

func add_card(branch: String, rarity: String):
    var rarity_points = CardDB.economy["rarity_points"].get(rarity, 1)
    card_counts[branch] = card_counts.get(branch, 0) + rarity_points
