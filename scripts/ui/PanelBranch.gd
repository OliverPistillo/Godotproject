# scripts/ui/PanelBranch.gd
extends VBoxContainer

## Lista rami attivi
var active_branches: Array = []

## Dizionario punti per ramo
var branch_points := {
	"Wound": 0, "Essence": 0, "Rage": 0, "Ice": 0, "Toxin": 0, "Shield": 0,
	"Healing": 0, "Power": 0, "Precision": 0, "Guardian": 0, "Assault": 0, "Dodge": 0
}

## Loghi caricati da JSON
var branch_logos: Dictionary = {}

## Livello eroe
var hero_level: int = 1

## Riferimenti UI per ogni ramo
var branch_labels := {}

## UI livello eroe
@onready var hero_level_label: Label = $HBoxContainer/HeroLevelLabel
@onready var hero_level_texture: TextureRect = $HBoxContainer/HeroLevels

func _ready() -> void:
	load_branch_logos()
	connect_card_signal()
	initialise_game()

## Carica loghi rami dal JSON
func load_branch_logos() -> void:
	var path := "res://data/branch_logos.json"
	if not FileAccess.file_exists(path):
		push_error("File branch_logos.json mancante.")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var data := JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		branch_logos = data
	else:
		push_error("Formato branch_logos.json non valido.")

## Collega al segnale card_acquired di CardManagement
func connect_card_signal() -> void:
	var card_manager_path = "/root/BattleScene/CanvasLayer"
	if has_node(card_manager_path):
		var card_manager = get_node(card_manager_path)
		if card_manager.has_signal("card_acquired"):
			card_manager.connect("card_acquired", Callable(self, "_on_card_acquired"))

## Inizializza gioco
func initialise_game() -> void:
	select_active_branches()
	cache_branch_labels()
	update_branch_labels()
	update_hero_level_label()

## Seleziona 8 rami attivi casuali
func select_active_branches() -> void:
	var keys = branch_points.keys()
	keys.shuffle()
	active_branches = keys.slice(0, 8)

## Salva riferimenti alle label e texture per rami attivi
func cache_branch_labels() -> void:
	for branch in branch_points.keys():
		var label_path = "HBoxContainer" + branch + "/Label"
		var texture_path = "HBoxContainer" + branch + "/TextureRect"
		if has_node(label_path) and has_node(texture_path):
			branch_labels[branch] = {
				"label": get_node(label_path),
				"texture": get_node(texture_path)
			}

## Aggiorna label e loghi rami
func update_branch_labels() -> void:
	for branch in branch_labels.keys():
		var label = branch_labels[branch]["label"]
		var texture = branch_labels[branch]["texture"]
		if branch in active_branches:
			label.visible = true
			label.text = str(branch_points[branch]) + "/" + str(get_level_threshold(branch_points[branch]))
			var logo_path = branch_logos.get(branch, "")
			if logo_path != "":
				var img = load(logo_path)
				if img:
					texture.texture = img
			texture.visible = true
		else:
			label.visible = false
			texture.visible = false
	sort_branches_by_level()

## Ricezione carta acquistata
func _on_card_acquired(card: Dictionary) -> void:
	var branch = card.get("branch", "")
	var rarity = card.get("rarity", "normale")
	if branch in active_branches:
		branch_points[branch] += get_points_based_on_rarity(rarity)
		update_branch_labels()
		check_for_hero_level_up()
	else:
		print("Carta di ramo non attivo:", branch)

## Punti in base alla rarità
func get_points_based_on_rarity(rarity: String) -> int:
	match rarity:
		"normale": return 1
		"epica": return 2
		"leggendaria": return 3
		_: return 0

## Aggiorna livello eroe in base ai punti totali
func check_for_hero_level_up() -> void:
	var total_points = 0
	for branch in active_branches:
		total_points += branch_points[branch]
	if total_points >= 40:
		hero_level = 4
	elif total_points >= 20:
		hero_level = 3
	elif total_points >= 10:
		hero_level = 2
	else:
		hero_level = 1
	update_hero_level_label()

## Aggiorna grafica livello eroe
func update_hero_level_label() -> void:
	if hero_level_label:
		hero_level_label.text = "LV."
	var img_path = "res://assets/images/hero_levels/" + str(hero_level) + ".png"
	if FileAccess.file_exists(img_path):
		hero_level_texture.texture = load(img_path)

## Ordina rami per punti e poi alfabeticamente
func sort_branches_by_level() -> void:
	var sorted = active_branches.duplicate()
	sorted.sort_custom(func(a, b):
		var pa = branch_points[a]
		var pb = branch_points[b]
		return pa == pb ? a < b : pb - pa
	)
	for i in range(sorted.size()):
		var branch_name = sorted[i]
		var hbox = branch_labels.get(branch_name, {}).get("label", null)
		if hbox:
			var parent_hbox = hbox.get_parent()
			move_child(parent_hbox, i)

## Soglia punti per livello
func get_level_threshold(points: int) -> int:
	if points >= 40: return 40
	elif points >= 20: return 20
	elif points >= 10: return 10
	else: return 4

## Ritorna lista rami attivi (per CardManagement)
func get_active_branches() -> Array:
	return active_branches
