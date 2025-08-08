extends Control

# Percorso del file JSON degli eroi
const HEROES_FILE := "res://data/heroes.json"

# Array con i dati caricati dal JSON
var heroes: Array = []

# Eroe selezionato
var selected_hero: Dictionary = {}

# Riferimenti ai nodi UI
@onready var hero_grid: GridContainer = $HeroGrid
@onready var hero_name_label: Label = $HeroInfo/HeroName
@onready var hero_stats_label: Label = $HeroInfo/HeroStats
@onready var select_button: Button = $HeroInfo/SelectButton

func _ready() -> void:
	# Carica gli eroi dal file
	load_heroes()

	# Popola la griglia con i bottoni eroe
	populate_hero_grid()

	# Disabilita il bottone finché non viene selezionato un eroe
	select_button.disabled = true
	select_button.connect("pressed", Callable(self, "_on_select_pressed"))

func load_heroes() -> void:
	var file := FileAccess.open(HEROES_FILE, FileAccess.READ)
	if file:
		var json := JSON.new()
		var error := json.parse(file.get_as_text())
		if error == OK:
			var data = json.data
			if data.has("heroes"):
				heroes = data["heroes"]
			else:
				push_error("Il file JSON non contiene la chiave 'heroes'.")
		else:
			push_error("Errore parsing JSON: %s" % json.get_error_message())
		file.close()
	else:
		push_error("Impossibile aprire il file: %s" % HEROES_FILE)

func populate_hero_grid() -> void:
	# Pulisce eventuali nodi esistenti
	for child in hero_grid.get_children():
		child.queue_free()

	# Crea un pulsante per ogni eroe
	for hero in heroes:
		var btn := Button.new()
		btn.text = hero["name"]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.connect("pressed", Callable(self, "_on_hero_selected").bind(hero))
		hero_grid.add_child(btn)

func _on_hero_selected(hero: Dictionary) -> void:
	selected_hero = hero
	hero_name_label.text = hero["name"]

	# Mostra le statistiche formattate
	var stats_text := ""
	for key in hero["stats"].keys():
		stats_text += "%s: %s\n" % [key.capitalize(), hero["stats"][key]]
	hero_stats_label.text = stats_text.strip_edges()

	select_button.disabled = false

func _on_select_pressed() -> void:
	# Salva nei dati globali
	if has_node("/root/Global"):
		Global.selected_hero = selected_hero

	# Cambia scena
	get_tree().change_scene_to_file("res://scenes/game/BattleScene.tscn")
