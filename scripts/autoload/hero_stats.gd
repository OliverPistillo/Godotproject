# scripts/autoload/HeroStats.gd
extends Node

## Dati degli eroi caricati da JSON
var heroes: Dictionary = {}
## ID dell'eroe attualmente selezionato
var selected_hero_id: String = ""
## Statistiche attuali (base + bonus)
var current_stats: Dictionary = {}
## Bonus derivanti dalle carte acquistate
var card_bonuses: Dictionary = {}

func _ready() -> void:
    load_hero_data()

## Carica dati eroi dal JSON
func load_hero_data() -> void:
    var path := "res://data/heroes.json"
    var file := FileAccess.open(path, FileAccess.READ)
    if file:
        var data: Variant = JSON.parse_string(file.get_as_text())
        if typeof(data) == TYPE_DICTIONARY and data.has("heroes"):
            for hero in data["heroes"]:
                heroes[hero["id"]] = hero
        else:
            push_error("heroes.json: formato non valido")
    else:
        push_error("Impossibile aprire " + path)

## Imposta l'eroe selezionato
func select_hero(hero_id: String) -> void:
    if heroes.has(hero_id):
        selected_hero_id = hero_id
        reset_stats()
    else:
        push_error("Eroe non trovato: " + hero_id)

## Reimposta le statistiche attuali a quelle base dell’eroe
func reset_stats() -> void:
    if selected_hero_id == "":
        return
    var base_stats: Dictionary = heroes[selected_hero_id]["stats"].duplicate(true)
    current_stats = base_stats
    card_bonuses.clear()

## Applica un bonus statistico da una carta
func apply_card_bonus(effects: Dictionary) -> void:
    for key in effects.keys():
        if not card_bonuses.has(key):
            card_bonuses[key] = 0
        card_bonuses[key] += effects[key]
    update_current_stats()

## Aggiorna le statistiche attuali sommando i bonus
func update_current_stats() -> void:
    if selected_hero_id == "":
        return
    var base_stats: Dictionary = heroes[selected_hero_id]["stats"]
    for key in base_stats.keys():
        var base_val = base_stats[key]
        var bonus_val = card_bonuses.get(key, 0)
        current_stats[key] = base_val + bonus_val

## Ritorna le statistiche aggiornate
func get_stats() -> Dictionary:
    return current_stats.duplicate(true)

## Ritorna il valore di una statistica specifica
func get_stat(stat_name: String) -> float:
    return current_stats.get(stat_name, 0)
