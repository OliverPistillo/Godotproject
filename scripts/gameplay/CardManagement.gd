# scripts/gameplay/CardManagement.gd
extends Node

signal card_acquired(card_data: Dictionary)

## Mazzo completo dal JSON
var deck: Array = []
## Carte correnti mostrate nel market
var current_cards: Array = []
## Rami attivi (arrivano da PanelBranch)
var active_branches: Array = []
## Coins disponibili del giocatore
var player_coins: int = 0

@onready var economy_data = load_economy_data()

func _ready() -> void:
    load_deck_data()

## Carica dati mazzo da JSON
func load_deck_data() -> void:
    var path := "res://data/deck.json"
    var file := FileAccess.open(path, FileAccess.READ)
    if file:
        var data := JSON.parse_string(file.get_as_text())
        if typeof(data) == TYPE_DICTIONARY and data.has("cards"):
            deck = data["cards"]
        else:
            push_error("deck.json: formato non valido")
    else:
        push_error("Impossibile aprire " + path)

## Carica economia di gioco
func load_economy_data() -> Dictionary:
    var path := "res://data/economy.json"
    var file := FileAccess.open(path, FileAccess.READ)
    if file:
        var data := JSON.parse_string(file.get_as_text())
        if typeof(data) == TYPE_DICTIONARY:
            return data
    push_error("Impossibile aprire economy.json")
    return {}

## Imposta i rami attivi (chiamato da PanelBranch)
func set_active_branches(branches: Array) -> void:
    active_branches = branches

## Imposta i coins iniziali
func set_player_coins(amount: int) -> void:
    player_coins = amount
    update_coin_label()

## Aggiorna la UI della moneta (se esiste CoinLabel)
func update_coin_label() -> void:
    if has_node("/root/BattleScene/CanvasLayer/CoinLabel"):
        var label = get_node("/root/BattleScene/CanvasLayer/CoinLabel")
        label.text = str(player_coins)

## Mostra 3 carte casuali filtrate per rami attivi
func roll_cards() -> void:
    var filtered_deck = []
    for card in deck:
        if card["branch"] in active_branches:
            filtered_deck.append(card)
    filtered_deck.shuffle()
    current_cards = filtered_deck.slice(0, 3)
    update_card_display()

## Aggiorna grafica delle carte
func update_card_display() -> void:
    for i in range(current_cards.size()):
        var card = current_cards[i]
        var bg_path = "/root/BattleScene/CanvasLayer/HBoxContainer/BackgroundCard" + str(i + 1)
        if has_node(bg_path):
            var btn = get_node(bg_path)
            btn.get_node("CardNameLabel" + str(i + 1)).text = card["name"]
            btn.get_node("CardEffectLabel" + str(i + 1)).text = str(card["effects"])
            btn.get_node("CostLabel" + str(i + 1)).text = str(card["cost"])
            btn.get_node("LevelCardLabel" + str(i + 1)).text = card["rarity"]
            var img = load(card.get("image", ""))
            if img:
                btn.get_node("CardImage" + str(i + 1)).texture = img

## Compra una carta
func buy_card(index: int) -> void:
    if index < 0 or index >= current_cards.size():
        return
    var card = current_cards[index]
    var cost = int(card["cost"])
    if player_coins >= cost:
        player_coins -= cost
        update_coin_label()
        emit_signal("card_acquired", card)
        HeroStats.apply_card_bonus(card["effects"])
    else:
        print("Coin insufficienti per acquistare la carta:", card["name"])
