# scripts/gameplay/MarketCard.gd
extends Node

## Riferimento al nodo gestione carte
@export var card_manager_path: NodePath
var card_manager: Node

## Stato del market aperto/chiuso
var market_open: bool = true

func _ready() -> void:
    if card_manager_path != NodePath():
        card_manager = get_node(card_manager_path)
    else:
        push_error("MarketCard.gd: manca il riferimento a CardManagement.gd")
    
    # Collega i pulsanti
    connect_buttons()

## Collega i pulsanti della UI
func connect_buttons() -> void:
    if has_node("/root/BattleScene/CanvasLayer/VBoxContainer/rollcard"):
        get_node("/root/BattleScene/CanvasLayer/VBoxContainer/rollcard").connect("pressed", Callable(self, "_on_roll_cards_pressed"))
    if has_node("/root/BattleScene/CanvasLayer/VBoxContainer/randomcard"):
        get_node("/root/BattleScene/CanvasLayer/VBoxContainer/randomcard").connect("pressed", Callable(self, "_on_random_card_pressed"))
    if has_node("/root/BattleScene/CanvasLayer/VBoxContainer/MarketCardButton"):
        get_node("/root/BattleScene/CanvasLayer/VBoxContainer/MarketCardButton").connect("pressed", Callable(self, "_on_toggle_market_pressed"))

## Toggle market ON/OFF
func _on_toggle_market_pressed() -> void:
    market_open = !market_open
    var market_node_path = "/root/BattleScene/CanvasLayer/HBoxContainer"
    if has_node(market_node_path):
        get_node(market_node_path).visible = market_open

## Rimescola le carte mostrate (pagando coin)
func _on_roll_cards_pressed() -> void:
    if card_manager:
        var roll_cost = card_manager.economy_data.get("roll_cost", 20)
        if card_manager.player_coins >= roll_cost:
            card_manager.player_coins -= roll_cost
            card_manager.update_coin_label()
            card_manager.roll_cards()
        else:
            print("Coin insufficienti per rimescolare le carte.")

## Compra una carta casuale direttamente dal mazzo
func _on_random_card_pressed() -> void:
    if card_manager:
        var random_cost = card_manager.economy_data.get("random_card_cost", 100)
        if card_manager.player_coins >= random_cost:
            var available_cards = []
            for c in card_manager.deck:
                if c["branch"] in card_manager.active_branches:
                    available_cards.append(c)
            if available_cards.size() > 0:
                var card = available_cards[randi() % available_cards.size()]
                card_manager.player_coins -= random_cost
                card_manager.update_coin_label()
                card_manager.emit_signal("card_acquired", card)
                HeroStats.apply_card_bonus(card["effects"])
        else:
            print("Coin insufficienti per acquistare una carta casuale.")
