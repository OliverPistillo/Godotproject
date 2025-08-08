extends Node

var cards: Array = []
var branches_data: Dictionary = {}
var economy: Dictionary = {}
var active_branches: Array = []

func _ready():
    load_branches()
    load_economy()
    load_cards()

func load_branches():
    var file_path = "res://data/branches.json"
    if FileAccess.file_exists(file_path):
        var data = JSON.parse_string(FileAccess.get_file_as_string(file_path))
        if typeof(data) == TYPE_DICTIONARY:
            branches_data = data
        else:
            push_error("Errore parsing branches.json")
    else:
        push_error("branches.json non trovato")

func load_economy():
    var file_path = "res://data/economy.json"
    if FileAccess.file_exists(file_path):
        var data = JSON.parse_string(FileAccess.get_file_as_string(file_path))
        if typeof(data) == TYPE_DICTIONARY:
            economy = data
        else:
            push_error("Errore parsing economy.json")

func load_cards():
    var file_path = "res://data/deck.json"
    if FileAccess.file_exists(file_path):
        var data = JSON.parse_string(FileAccess.get_file_as_string(file_path))
        if typeof(data) == TYPE_DICTIONARY and data.has("cards"):
            cards = data["cards"]
        else:
            push_error("Errore parsing deck.json")

func filter_active_cards() -> Array:
    return cards.filter(func(c):
        return active_branches.has(c["branch"])
    )

func get_random_cards(count: int) -> Array:
    var available = filter_active_cards()
    available.shuffle()
    return available.slice(0, min(count, available.size()))
