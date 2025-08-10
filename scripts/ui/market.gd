# scripts/ui/Market.gd
extends Control

signal market_closed()
signal coins_updated(amount: int)

@onready var card_container: HBoxContainer = $CardContainer
@onready var coin_label: Label = $TopBar/CoinLabel
@onready var roll_button: Button = $Actions/RollButton
@onready var random_button: Button = $Actions/RandomButton
@onready var lock_button: Button = $Actions/LockButton
@onready var ready_button: Button = $Actions/ReadyButton
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var branch_panel: VBoxContainer = $BranchPanel

# Carte attualmente mostrate
var current_cards: Array = []
var locked_indices: Array = []

# Economia
var player_coins: int = 300
var roll_cost: int = 20
var random_cost: int = 100
var hero_level: int = 1

# Timer preparazione
var preparation_time: float = 20.0
var time_remaining: float = 20.0

func _ready() -> void:
	setup_ui()
	connect_signals()
	refresh_market()
	update_branch_display()

func setup_ui() -> void:
	# Imposta testi pulsanti
	roll_button.text = "Reroll (%d)" % roll_cost
	random_button.text = "Random (%d)" % random_cost
	lock_button.text = "Lock Cards"
	ready_button.text = "Ready"
	
	# Aggiorna display
	update_coin_display()
	update_timer_display()

func connect_signals() -> void:
	roll_button.pressed.connect(_on_roll_pressed)
	random_button.pressed.connect(_on_random_pressed)
	lock_button.pressed.connect(_on_lock_pressed)
	ready_button.pressed.connect(_on_ready_pressed)

func _process(delta: float) -> void:
	# Aggiorna timer
	if time_remaining > 0:
		time_remaining -= delta
		update_timer_display()
		
		if time_remaining <= 0:
			_on_timer_expired()

func refresh_market() -> void:
	# Pulisci carte non bloccate
	for i in range(card_container.get_child_count() - 1, -1, -1):
		if not i in locked_indices:
			card_container.get_child(i).queue_free()
	
	# Ottieni nuove carte dal sistema
	if has_node("/root/CardSystem"):
		var card_system = get_node("/root/CardSystem")
		current_cards = card_system.get_random_market_cards(3, hero_level)
		
		# Mostra le carte
		for i in range(current_cards.size()):
			if not i in locked_indices:
				display_card(current_cards[i], i)

func display_card(card_data: Dictionary, index: int) -> Control:
	# Crea display carta
	var card_display = preload("res://scenes/ui/CardDisplay.tscn").instantiate()
	card_container.add_child(card_display)
	card_container.move_child(card_display, index)
	
	# Configura carta
	setup_card_display(card_display, card_data)
	
	# Connetti segnali
	card_display.gui_input.connect(_on_card_clicked.bind(index))
	
	return card_display

func setup_card_display(display: Control, card_data: Dictionary) -> void:
	# Nome carta
	if display.has_node("Name"):
		display.get_node("Name").text = card_data.get("name", "")
	
	# Effetto
	if display.has_node("Effect"):
		var effect_label = display.get_node("Effect")
		effect_label.text = card_data.get("effect", "")
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Costo
	if display.has_node("Cost"):
		display.get_node("Cost").text = str(card_data.get("cost", 100))
	
	# Rarità e background
	var rarity = card_data.get("rarity", "Normal")
	if display.has_node("Background"):
		var bg = display.get_node("Background")
		var bg_texture = load(card_data.get("image_background", ""))
		if bg_texture:
			bg.texture = bg_texture
		else:
			# Colore default per rarità
			match rarity.to_lower():
				"normal":
					bg.modulate = Color(0.5, 0.5, 0.7)  # Blu
				"epic":
					bg.modulate = Color(0.6, 0.3, 0.7)  # Viola
				"legendary":
					bg.modulate = Color(0.8, 0.7, 0.3)  # Oro
	
	# Immagine carta
	if display.has_node("CardImage"):
		var img = load(card_data.get("image_card", ""))
		if img:
			display.get_node("CardImage").texture = img
	
	# Livelli disponibili
	var levels = card_data.get("levels", [])
	if display.has_node("LevelIndicator"):
		var level_node = display.get_node("LevelIndicator")
		if levels.size() > 0:
			# Mostra primo livello
			var level_img = load(levels[0].get("level_card", ""))
			if level_img:
				level_node.texture = level_img
		level_node.visible = levels.size() > 0
	
	# Branches
	if display.has_node("Branches"):
		var branches_container = display.get_node("Branches")
		show_card_branches(branches_container, card_data)

func show_card_branches(container: Control, card_data: Dictionary) -> void:
	# Pulisci branches esistenti
	for child in container.get_children():
		child.queue_free()
	
	# Parse branches
	if has_node("/root/CardSystem"):
		var card_system = get_node("/root/CardSystem")
		var branches = card_system.parse_card_branches(card_data)
		
		for branch in branches:
			var icon = TextureRect.new()
			icon.custom_minimum_size = Vector2(24, 24)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# Carica icona branch
			var icon_path = "res://logos/branches/" + branch.to_lower() + ".png"
			if FileAccess.file_exists(icon_path):
				icon.texture = load(icon_path)
			
			icon.tooltip_text = branch
			container.add_child(icon)

func _on_card_clicked(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Acquista carta
			purchase_card(index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Blocca/sblocca carta
			toggle_lock_card(index)

func purchase_card(index: int) -> void:
	if index >= current_cards.size():
		return
	
	var card = current_cards[index]
	var cost = card.get("cost", 100)
	
	if player_coins >= cost:
		# Acquista tramite CardSystem
		if has_node("/root/CardSystem"):
			var card_system = get_node("/root/CardSystem")
			var result = card_system.purchase_card(card.get("id", -1), player_coins)
			
			if result.get("success", false):
				player_coins -= result.get("coins_spent", 0)
				update_coin_display()
				emit_signal("coins_updated", player_coins)
				
				# Effetto visivo acquisto
				show_purchase_effect(index)
				
				# Rimuovi carta dal market
				var card_display = card_container.get_child(index)
				card_display.queue_free()
				current_cards.remove_at(index)
				
				# Aggiungi nuova carta
				refresh_single_slot(index)
			else:
				show_error_message(result.get("error", "Errore acquisto"))
	else:
		show_insufficient_coins()

func refresh_single_slot(index: int) -> void:
	# Ottieni una nuova carta per lo slot vuoto
	if has_node("/root/CardSystem"):
		var card_system = get_node("/root/CardSystem")
		var new_cards = card_system.get_random_market_cards(1, hero_level)
		
		if new_cards.size() > 0:
			current_cards.insert(index, new_cards[0])
			display_card(new_cards[0], index)

func toggle_lock_card(index: int) -> void:
	if index in locked_indices:
		locked_indices.erase(index)
		# Rimuovi effetto visivo lock
		var card_display = card_container.get_child(index)
		if card_display.has_node("LockOverlay"):
			card_display.get_node("LockOverlay").visible = false
	else:
		locked_indices.append(index)
		# Aggiungi effetto visivo lock
		var card_display = card_container.get_child(index)
		if not card_display.has_node("LockOverlay"):
			var overlay = ColorRect.new()
			overlay.name = "LockOverlay"
			overlay.color = Color(0, 0, 0, 0.3)
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			card_display.add_child(overlay)
			
			var lock_icon = TextureRect.new()
			lock_icon.texture = preload("res://data/images/images_icon_button/lock_icon.png")
			lock_icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			overlay.add_child(lock_icon)
		else:
			card_display.get_node("LockOverlay").visible = true

func _on_roll_pressed() -> void:
	if player_coins >= roll_cost:
		player_coins -= roll_cost
		update_coin_display()
		emit_signal("coins_updated", player_coins)
		
		# Mantieni carte bloccate
		var locked_cards = []
		for i in locked_indices:
			if i < current_cards.size():
				locked_cards.append(current_cards[i])
		
		# Refresh market
		locked_indices.clear()
		refresh_market()
		
		# Ripristina carte bloccate
		for i in range(locked_cards.size()):
			current_cards[i] = locked_cards[i]
			locked_indices.append(i)
			toggle_lock_card(i)  # Riapplica lock visivo
		
		# Effetto visivo roll
		show_roll_effect()
	else:
		show_insufficient_coins()

func _on_random_pressed() -> void:
	if player_coins >= random_cost:
		player_coins -= random_cost
		update_coin_display()
		emit_signal("coins_updated", player_coins)
		
		# Ottieni carta casuale
		if has_node("/root/CardSystem"):
			var card_system = get_node("/root/CardSystem")
			var random_cards = card_system.get_random_market_cards(1, hero_level)
			
			if random_cards.size() > 0:
				var card = random_cards[0]
				var result = card_system.purchase_card(card.get("id", -1), player_coins + random_cost)
				
				if result.get("success", false):
					show_random_card_obtained(card)
	else:
		show_insufficient_coins()

func _on_lock_pressed() -> void:
	# Toggle lock su tutte le carte
	if locked_indices.size() == current_cards.size():
		# Sblocca tutte
		for i in range(current_cards.size() - 1, -1, -1):
			toggle_lock_card(i)
	else:
		# Blocca tutte
		for i in range(current_cards.size()):
			if not i in locked_indices:
				toggle_lock_card(i)

func _on_ready_pressed() -> void:
	# Termina fase preparazione
	emit_signal("market_closed")
	hide()

func _on_timer_expired() -> void:
	# Tempo scaduto, chiudi market
	_on_ready_pressed()

func update_coin_display() -> void:
	coin_label.text = str(player_coins) + " Coins"

func update_timer_display() -> void:
	var seconds = int(time_remaining)
	timer_label.text = "%02d" % seconds
	
	# Cambia colore se poco tempo
	if seconds <= 5:
		timer_label.modulate = Color(1, 0.3, 0.3)
	elif seconds <= 10:
		timer_label.modulate = Color(1, 1, 0.3)
	else:
		timer_label.modulate = Color.WHITE

func update_branch_display() -> void:
	if not has_node("/root/CardSystem"):
		return
	
	var card_system = get_node("/root/CardSystem")
	var branch_points = card_system.get_branch_points()
	
	# Aggiorna display per ogni branch
	for branch in branch_points:
		if branch_panel.has_node(branch):
			var branch_node = branch_panel.get_node(branch)
			if branch_node.has_node("Points"):
				branch_node.get_node("Points").text = str(branch_points[branch])
			
			# Mostra progressione livello
			var total_points = 0
			for b in branch_points:
				total_points += branch_points[b]
			
			update_hero_level_display(total_points)

func update_hero_level_display(total_points: int) -> void:
	# Calcola livello eroe
	if total_points >= 40:
		hero_level = 5
	elif total_points >= 20:
		hero_level = 4
	elif total_points >= 10:
		hero_level = 3
	elif total_points >= 4:
		hero_level = 2
	else:
		hero_level = 1
	
	# Aggiorna display livello
	if branch_panel.has_node("HeroLevel"):
		var level_node = branch_panel.get_node("HeroLevel")
		level_node.text = "Level " + str(hero_level)
		
		# Colore in base al livello
		match hero_level:
			1:
				level_node.modulate = Color(0.7, 0.7, 0.7)
			2:
				level_node.modulate = Color(0.3, 0.8, 0.3)
			3:
				level_node.modulate = Color(0.3, 0.5, 1.0)
			4:
				level_node.modulate = Color(0.7, 0.3, 1.0)
			5:
				level_node.modulate = Color(1.0, 0.8, 0.2)

# Effetti visivi
func show_purchase_effect(index: int) -> void:
	var card = card_container.get_child(index)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(card, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(card, "scale", Vector2(0, 0), 0.2)

func show_roll_effect() -> void:
	for child in card_container.get_children():
		if not locked_indices.has(child.get_index()):
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_BACK)
			tween.tween_property(child, "rotation", TAU, 0.3)

func show_insufficient_coins() -> void:
	# Mostra messaggio errore
	var popup = AcceptDialog.new()
	popup.dialog_text = "Coins insufficienti!"
	popup.title = "Errore"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(popup.queue_free)

func show_error_message(msg: String) -> void:
	var popup = AcceptDialog.new()
	popup.dialog_text = msg
	popup.title = "Errore"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(popup.queue_free)

func show_random_card_obtained(card: Dictionary) -> void:
	var popup = AcceptDialog.new()
	popup.dialog_text = "Hai ottenuto: " + card.get("name", "Carta")
	popup.title = "Carta Random!"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(popup.queue_free)

func set_coins(amount: int) -> void:
	player_coins = amount
	update_coin_display()

func add_coins(amount: int) -> void:
	player_coins += amount
	update_coin_display()
	emit_signal("coins_updated", player_coins)