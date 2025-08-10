# scripts/ui/main_menu.gd
extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var credits_button: Button = $VBoxContainer/CreditsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var version_label: Label = $VersionLabel
@onready var title_label: Label = $TitleLabel
@onready var background: TextureRect = $Background

# Animazioni
var tween: Tween
var menu_ready: bool = false

func _ready() -> void:
	setup_ui()
	connect_signals()
	animate_menu_entrance()
	
	# Mostra versione
	if version_label:
		version_label.text = "v" + Constants.GAME_VERSION
	
	# Setup musica menu
	play_menu_music()

func setup_ui() -> void:
	# Imposta titolo
	if title_label:
		title_label.text = "HERO SMASH"
		title_label.add_theme_font_size_override("font_size", 72)
	
	# Stile pulsanti
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_left = 10
	button_style.corner_radius_bottom_right = 10
	button_style.content_margin_left = 20
	button_style.content_margin_right = 20
	button_style.content_margin_top = 10
	button_style.content_margin_bottom = 10
	
	for button in [play_button, options_button, credits_button, exit_button]:
		if button:
			button.add_theme_stylebox_override("normal", button_style)
			button.add_theme_font_size_override("font_size", 24)
			setup_button_hover(button)

func connect_signals() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	if credits_button:
		credits_button.pressed.connect(_on_credits_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)

func setup_button_hover(button: Button) -> void:
	button.mouse_entered.connect(func(): _on_button_hover(button, true))
	button.mouse_exited.connect(func(): _on_button_hover(button, false))
	button.focus_entered.connect(func(): _on_button_hover(button, true))
	button.focus_exited.connect(func(): _on_button_hover(button, false))

func _on_button_hover(button: Button, entered: bool) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	if entered:
		tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2)
		tween.parallel().tween_property(button, "modulate", Color(1.2, 1.2, 1.2), 0.2)
		play_hover_sound()
	else:
		tween.tween_property(button, "scale", Vector2.ONE, 0.2)
		tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.2)

func animate_menu_entrance() -> void:
	# Anima l'entrata del menu
	if title_label:
		title_label.modulate.a = 0
		title_label.position.y -= 50
	
	var buttons = [play_button, options_button, credits_button, exit_button]
	for i in range(buttons.size()):
		if buttons[i]:
			buttons[i].modulate.a = 0
			buttons[i].position.x -= 100
	
	# Animazione sequenziale
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# Titolo
	if title_label:
		tween.tween_property(title_label, "modulate:a", 1.0, 0.5)
		tween.parallel().tween_property(title_label, "position:y", title_label.position.y + 50, 0.5)
	
	# Pulsanti con delay
	for i in range(buttons.size()):
		if buttons[i]:
			tween.tween_property(buttons[i], "modulate:a", 1.0, 0.3)
			tween.parallel().tween_property(buttons[i], "position:x", buttons[i].position.x + 100, 0.3)
			if i < buttons.size() - 1:
				tween.tween_interval(0.1)
	
	tween.finished.connect(func(): menu_ready = true)

func _on_play_pressed() -> void:
	if not menu_ready:
		return
	
	play_click_sound()
	
	# Animazione uscita
	animate_menu_exit()
	
	# Aspetta che l'animazione finisca
	await get_tree().create_timer(0.5).timeout
	
	# Vai alla selezione personaggio
	get_tree().change_scene_to_file(Constants.SCENE_CHARACTER_SELECT)

func _on_options_pressed() -> void:
	if not menu_ready:
		return
	
	play_click_sound()
	show_options_popup()

func _on_credits_pressed() -> void:
	if not menu_ready:
		return
	
	play_click_sound()
	show_credits_popup()

func _on_exit_pressed() -> void:
	if not menu_ready:
		return
	
	play_click_sound()
	
	# Conferma uscita
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Sei sicuro di voler uscire?"
	dialog.title = "Conferma Uscita"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(_confirm_exit)
	dialog.canceled.connect(dialog.queue_free)

func _confirm_exit() -> void:
	# Animazione uscita
	animate_menu_exit()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

func animate_menu_exit() -> void:
	menu_ready = false
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	
	# Fade out tutto
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.5)

func show_options_popup() -> void:
	var popup = AcceptDialog.new()
	popup.title = "Opzioni"
	popup.dialog_text = "Opzioni non ancora implementate"
	popup.add_theme_font_size_override("font_size", 18)
	add_child(popup)
	popup.popup_centered(Vector2(400, 300))
	
	# Aggiungi controlli opzioni base
	var vbox = VBoxContainer.new()
	
	# Volume Master
	var master_volume = create_volume_slider("Volume Master", 1.0)
	vbox.add_child(master_volume)
	
	# Volume Effetti
	var sfx_volume = create_volume_slider("Volume Effetti", 1.0)
	vbox.add_child(sfx_volume)
	
	# Volume Musica
	var music_volume = create_volume_slider("Volume Musica", 0.7)
	vbox.add_child(music_volume)
	
	# Fullscreen
	var fullscreen_check = CheckBox.new()
	fullscreen_check.text = "Schermo Intero"
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(fullscreen_check)
	
	popup.add_child(vbox)

func create_volume_slider(label_text: String, default_value: float) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 120
	container.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.value = default_value
	slider.custom_minimum_size.x = 200
	slider.value_changed.connect(func(value): _on_volume_changed(label_text, value))
	container.add_child(slider)
	
	var value_label = Label.new()
	value_label.text = str(int(default_value * 100)) + "%"
	slider.value_changed.connect(func(value): value_label.text = str(int(value * 100)) + "%")
	container.add_child(value_label)
	
	return container

func _on_volume_changed(bus_name: String, value: float) -> void:
	# Implementa cambio volume
	var bus_index = -1
	
	match bus_name:
		"Volume Master":
			bus_index = AudioServer.get_bus_index("Master")
		"Volume Effetti":
			bus_index = AudioServer.get_bus_index("SFX")
		"Volume Musica":
			bus_index = AudioServer.get_bus_index("Music")
	
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func show_credits_popup() -> void:
	var popup = AcceptDialog.new()
	popup.title = "Credits"
	popup.dialog_text = """Hero Smash
	
Sviluppato con Godot Engine 4.x
	
Design & Programming:
[Il tuo nome]
	
Art & Models:
Assets Low-Poly
	
Music & Sound:
[Crediti Audio]
	
Special Thanks:
Godot Community
	
Version: """ + Constants.GAME_VERSION
	
	popup.add_theme_font_size_override("font_size", 16)
	add_child(popup)
	popup.popup_centered(Vector2(500, 400))

func play_hover_sound() -> void:
	# Implementa suono hover
	var audio = AudioStreamPlayer.new()
	audio.stream = preload("res://assets/audio/sfx/button_hover.ogg") if FileAccess.file_exists("res://assets/audio/sfx/button_hover.ogg") else null
	if audio.stream:
		audio.bus = "SFX"
		audio.volume_db = -10
		add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)

func play_click_sound() -> void:
	# Implementa suono click
	var audio = AudioStreamPlayer.new()
	audio.stream = preload("res://assets/audio/sfx/button_click.ogg") if FileAccess.file_exists("res://assets/audio/sfx/button_click.ogg") else null
	if audio.stream:
		audio.bus = "SFX"
		add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)

func play_menu_music() -> void:
	# Implementa musica menu
	var music = AudioStreamPlayer.new()
	music.stream = preload("res://assets/audio/music/menu_theme.ogg") if FileAccess.file_exists("res://assets/audio/music/menu_theme.ogg") else null
	if music.stream:
		music.bus = "Music"
		music.volume_db = -15
		music.autoplay = true
		add_child(music)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if menu_ready:
			_on_exit_pressed()