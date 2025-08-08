extends Node3D

# Riferimenti ai personaggi
@onready var character1 = $PlayerCharacter
@onready var character2 = $OpponentCharacter
@onready var card_management_script = $CanvasLayer/VBoxContainer  # Collegato allo script della gestione delle carte

# Posizioni per la preparazione e il duello
var prep_position = Vector3(0, 0, 0)  # Centro del ring
var left_position = Vector3(-5, 0, 0)  # Posizione sinistra del ring
var right_position = Vector3(5, 0, 0)  # Posizione destra del ring

func start_preparation():
	# Sposta entrambi i personaggi al centro durante la fase di preparazione
	character1.global_transform.origin = prep_position
	character2.global_transform.origin = prep_position
	# Aggiungi 300 coin per il nuovo round
	card_management_script.add_coins(300)

func start_duel():
	# Sposta i personaggi sui lati per il duello
	character1.global_transform.origin = left_position
	character2.global_transform.origin = right_position


func _on_market_card_button_pressed():
	pass # Replace with function body.
