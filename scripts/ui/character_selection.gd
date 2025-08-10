# scripts/ui/character_selection.gd
extends Control

signal hero_selected(hero_data: Dictionary)

# Percorsi file
const HEROES_FILE := "res://data/heroes_converted.json"
const HEROES_FALLBACK := "res://data/heroes.json"

# Array con i dati caricati dal JSON
var all_heroes: Array = []
var available_heroes: Array = []  # 3 eroi casuali disponibili
var selected_hero: Dictionary = {}
var reroll_used: bool = false

# Riferimenti UI
@onready var heroes_container: HBoxContainer = $VBoxContainer/HeroesContainer
@onready var hero_name_label: Label = $VBoxContainer/InfoPanel/HeroName
@onready var hero_stats_panel: PanelContainer = $VBoxContainer/InfoPanel/StatsPanel
@onready var stats_container: VBoxContainer = $VBoxContainer/InfoPanel/StatsPanel/StatsContainer
@onready var select_button: Button = $VBoxContainer/ButtonsContainer/SelectButton
@onready var reroll_button: Button = $VBoxContainer/ButtonsContainer/RerollButton
@onready var back_button: Button = $VBoxContainer/ButtonsContainer/BackButton
@onready var hero_preview: Node3D = $ViewportContainer/SubViewport/HeroPreview

# Template hero card
var hero_card_scene = preload("res://scenes/ui/hero_card.tscn") if FileAccess.file_exists("res://scenes/ui/hero_card.tscn") else null

func _ready() -> void:
	setup_ui()
	load_heroes()
	select_random_heroes()
	connect_signals()
	animate_entrance()

func setup_ui() -> void:
	# Imposta stili
	select_button.disabled = true
	select_button.text = "Seleziona Eroe"
	reroll_button.text = "Cambia Eroi (1 uso)"
	back_button.text = "Indietro"
	
	# Nascondi pannello stats inizialmente
	if hero_stats_panel:
		hero_stats_panel.visible = false

func load_heroes() -> void:
	# Prova prima heroes_converted.json (con le nuove statistiche)
	var file_path = HEROES_FILE
	if not FileAccess.file_exists(file_path):
		file_path = HEROES_FALLBACK
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json := JSON.new()
		var error := json.parse(file.get_as_text())
		if error == OK:
			var data = json.data
			if data.has("heroes"):
				# Converti da dizionario ad array se necessario
				if typeof(data["heroes"]) == TYPE_DICTIONARY:
					for hero_name in data["heroes"]:
						var hero = data["heroes"][hero_name]
						hero["id"] = hero_name.to_lower().replace(" ", "_")
						hero["name"] = hero_name
						all_heroes.append(hero)
				else:
					all_heroes = data["heroes"]
				print("Caricati ", all_heroes.size(), " eroi")
			else:
				push_error("Il file JSON non contiene la chiave 'heroes'")
		else:
			push_error("Errore parsing JSON: %s" % json.get_error_message())
		file.close()
	else:
		push_error("Impossibile aprire il file: %s" % file_path)
		# Crea eroi di default per testing
		create_default_heroes()

func create_default_heroes() -> void:
	# Eroi di fallback se il file non esiste
	var default_heroes = [
		{
			"id": "warrior",
			"name": "Warrior",
			"max_health": 1200,
			"attack_damage": 26,
			"attack_speed": 0.95,
			"crit_chance": 15,
			"dodge_chance": 10,
			"mana_regen": 9,
			"branch": "assault"
		},
		{
			"id": "mage",
			"name": "Mage",
			"max_health": 1000,
			"attack_damage": 22,
			"attack_speed": 1.04,
			"crit_chance": 20,
			"dodge_chance": 12,
			"mana_regen": 12,
			"branch": "essence"
		},
		{
			"id": "assassin",
			"name": "Assassin",
			"max_health": 900,
			"attack_damage": 28,
			"attack_speed": 1.15,
			"crit_chance": 25,
			"dodge_chance": 18,
			"mana_regen": 10,
			"branch": "precision"
		}
	]
	all_heroes = default_heroes

func select_random_heroes() -> void:
	available_heroes.clear()
	
	# Seleziona 3 eroi casuali
	var shuffled = all_heroes.duplicate()
	shuffled.shuffle()
	
	for i in range(min(3, shuffled.size())):
		available_heroes.append(shuffled[i])
	
	display_heroes()

func display_heroes() -> void:
	# Pulisci container
	for child in heroes_container.get_children():
		child.queue_free()
	
	# Crea card per ogni eroe disponibile
	for i in range(available_heroes.size()):
		var hero = available_heroes[i]
		var card = create_hero_card(hero, i)
		heroes_container.add_child(card)

func create_hero_card(hero: Dictionary, index: int) -> Control:
	var card_container = PanelContainer.new()
	card_container.custom_minimum_size = Vector2(300, 400)
	
	# Stile card
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.4)
	card_container.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card_container.add_child(vbox)
	
	# Nome eroe
	var name_label = Label.new()
	name_label.text = hero.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", get_branch_color(hero.get("branch", "")))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# Immagine/Placeholder
	var image_rect = TextureRect.new()
	image_rect.custom_minimum_size = Vector2(250, 200)
	image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var image_path = "res://assets/images/heroes/" + hero.get("id", "") + ".png"
	if FileAccess.file_exists(image_path):
		image_rect.texture = load(image_path)
	else:
		# Placeholder colorato
		var placeholder = PlaceholderTexture2D.new()
		placeholder.size = Vector2(250, 200)
		image_rect.texture = placeholder
		image_rect.modulate = get_branch_color(hero.get("branch", ""))
	vbox.add_child(image_rect)
	
	# Branch
	var branch_label = Label.new()
	branch_label.text = "Branch: " + hero.get("branch", "None")
	branch_label.add_theme_font_size_override("font_size", 16)
	branch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(branch_label)
	
	# Stats principali
	var stats_label = Label.new()
	stats_label.text = format_hero_stats_brief(hero)
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(stats_label)
	
	# Button select
	var select_btn = Button.new()
	select_btn.text = "Scegli"
	select_btn.custom_minimum_size = Vector2(0, 40)
	select_btn.pressed.connect(func(): _on_hero_card_selected(hero, card_container))
	vbox.add_child(select_btn)
	
	# Animazione hover
	card_container.mouse_entered.connect(func(): _on_card_hover(card_container, true))
	card_container.mouse_exited.connect(func(): _on_card_hover(card_container, false))
	
	return card_container

func format_hero_stats_brief(hero: Dictionary) -> String:
	var stats_text = ""
	stats_text += "HP: " + str(hero.get("max_health", 1000)) + "\n"
	stats_text += "ATK: " + str(hero.get("attack_damage", 20)) + "\n"
	stats_text += "SPD: " + str(hero.get("attack_speed", 1.0)) + "\n"
	stats_text += "CRIT: " + str(hero.get("crit_chance", 15)) + "%"
	return stats_text

func _on_hero_card_selected(hero: Dictionary, card: Control) -> void:
	selected_hero = hero
	
	# Evidenzia card selezionata
	for child in heroes_container.get_children():
		if child.has_method("set_selected"):
			child.set_selected(false)
		else:
			# Modifica stile manualmente
			var style = child.get_theme_stylebox("panel")
			if style:
				style.border_color = Color(0.3, 0.3, 0.4)
	
	# Evidenzia questa card
	var style = card.get_theme_stylebox("panel")
	if style:
		style.border_color = Color(0.8, 0.6, 0.2)
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
	
	# Mostra dettagli
	show_hero_details(hero)
	
	# Abilita pulsante selezione
	select_button.disabled = false
	
	# Aggiorna preview 3D se disponibile
	update_hero_preview(hero)

func show_hero_details(hero: Dictionary) -> void:
	hero_name_label.text = hero.get("name", "Unknown")
	hero_stats_panel.visible = true
	
	# Pulisci stats precedenti
	for child in stats_container.get_children():
		child.queue_free()
	
	# Mostra tutte le stats
	var stats = [
		{"name": "Max Health", "value": hero.get("max_health", 1000), "suffix": " HP"},
		{"name": "Attack Damage", "value": hero.get("attack_damage", 20), "suffix": ""},
		{"name": "Attack Speed", "value": hero.get("attack_speed", 1.0), "suffix": "/s"},
		{"name": "Critical Chance", "value": hero.get("crit_chance", 15), "suffix": "%"},
		{"name": "Dodge Chance", "value": hero.get("dodge_chance", 10), "suffix": "%"},
		{"name": "Mana Regen", "value": hero.get("mana_regen", 9), "suffix": "/s"},
		{"name": "Branch", "value": hero.get("branch", "None"), "suffix": ""}
	]
	
	for stat in stats:
		var stat_line = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = stat["name"] + ":"
		name_label.custom_minimum_size.x = 150
		stat_line.add_child(name_label)
		
		var value_label = Label.new()
		value_label.text = str(stat["value"]) + stat["suffix"]
		value_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))
		stat_line.add_child(value_label)
		
		stats_container.add_child(stat_line)

func update_hero_preview(hero: Dictionary) -> void:
	if not hero_preview:
		return
	
	# Carica modello 3D dell'eroe se disponibile
	var model_path = "res://assets/models/heroes/" + hero.get("id", "") + ".glb"
	if FileAccess.file_exists(model_path):
		# Implementa caricamento modello 3D
		pass

func _on_card_hover(card: Control, entered: bool) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	if entered:
		tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.2)
		play_hover_sound()
	else:
		tween.tween_property(card, "scale", Vector2.ONE, 0.2)

func connect_signals() -> void:
	select_button.pressed.connect(_on_select_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_select_pressed() -> void:
	if selected_hero.is_empty():
		return
	
	play_click_sound()
	
	# Salva nei dati globali
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		gm.selected_hero = selected_hero
	
	if has_node("/root/HeroStats"):
		var hero_stats = get_node("/root/HeroStats")
		hero_stats.select_hero(selected_hero.get("id", ""))
	
	emit_signal("hero_selected", selected_hero)
	
	# Animazione uscita
	animate_exit()
	await get_tree().create_timer(0.5).timeout
	
	# Cambia scena
	get_tree().change_scene_to_file(Constants.SCENE_BATTLE)

func _on_reroll_pressed() -> void:
	if reroll_used:
		return
	
	play_click_sound()
	reroll_used = true
	reroll_button.disabled = true
	reroll_button.text = "Reroll Usato"
	
	# Animazione reroll
	animate_reroll()
	
	# Seleziona nuovi eroi
	select_random_heroes()
	
	# Reset selezione
	selected_hero.clear()
	select_button.disabled = true
	hero_stats_panel.visible = false

func _on_back_pressed() -> void:
	play_click_sound()
	animate_exit()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file(Constants.SCENE_MAIN_MENU)

func animate_entrance() -> void:
	modulate.a = 0
	position.y = 50
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(self, "position:y", 0, 0.5)

func animate_exit() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2(0.9, 0.9), 0.5)

func animate_reroll() -> void:
	for child in heroes_container.get_children():
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(child, "rotation", TAU, 0.3)
		tween.parallel().tween_property(child, "modulate:a", 0.0, 0.2)

func get_branch_color(branch: String) -> Color:
	return Constants.get_branch_color(branch)

func play_hover_sound() -> void:
	# Implementa suono hover
	pass

func play_click_sound() -> void:
	# Implementa suono click
	pass