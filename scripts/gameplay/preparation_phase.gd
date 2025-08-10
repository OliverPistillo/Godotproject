# scripts/gameplay/PreparationPhase.gd
extends Node

## Durata della preparazione in secondi
@export var preparation_time: int = 20

## Riferimenti UI
@export var timer_label_path: NodePath
@export var round_label_path: NodePath
@export var market_node_path: NodePath
@export var card_manager_path: NodePath

## Riferimenti personaggi
@export var player_path: NodePath
@export var opponent_path: NodePath

var timer_label: Label
var round_label: Label
var market_node: CanvasLayer
var card_manager: Node
var player: Node3D
var opponent: Node3D

## Stato
var current_round: int = 1
var preparation_timer: float = 0.0
var in_preparation: bool = true
var player_ready: bool = false

func _ready() -> void:
    # Recupero nodi
    if timer_label_path != NodePath():
        timer_label = get_node(timer_label_path)
    if round_label_path != NodePath():
        round_label = get_node(round_label_path)
    if market_node_path != NodePath():
        market_node = get_node(market_node_path)
    if card_manager_path != NodePath():
        card_manager = get_node(card_manager_path)
    if player_path != NodePath():
        player = get_node(player_path)
    if opponent_path != NodePath():
        opponent = get_node(opponent_path)

    start_preparation_phase()

## Avvia la fase di preparazione
func start_preparation_phase() -> void:
    in_preparation = true
    preparation_timer = preparation_time
    player_ready = false

    # Aggiorna UI
    round_label.text = "Round " + str(current_round)
    market_node.visible = true

    # Aggiungi coin del round
    if card_manager:
        card_manager.player_coins += 300
        card_manager.update_coin_label()
        card_manager.roll_cards()

    # Sposta personaggio al centro ring
    if player:
        player.global_transform.origin.x = 0
    if opponent:
        opponent.global_transform.origin.x = 0

func _process(delta: float) -> void:
    if in_preparation:
        preparation_timer -= delta
        if timer_label:
            timer_label.text = str(ceil(preparation_timer))
        if preparation_timer <= 0:
            start_duel_phase()

## Imposta pronto manualmente
func set_player_ready() -> void:
    player_ready = true
    # In futuro qui potremo gestire il "tutti pronti" in multiplayer
    start_duel_phase()

## Avvia la fase di duello
func start_duel_phase() -> void:
    in_preparation = false
    market_node.visible = false

    # Sposta il player a sinistra e l'opponent a destra
    if player:
        player.global_transform.origin.x = -2
    if opponent:
        opponent.global_transform.origin.x = 2

    # Qui possiamo lanciare animazioni/AI/combat manager
    print("Duello iniziato!")

## Avvia il round successivo
func next_round() -> void:
    current_round += 1
    start_preparation_phase()
