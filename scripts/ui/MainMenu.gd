extends Control

func _ready():
	# Collegamento dei pulsanti
	$Background/Play.pressed.connect(self._on_PlayButton_pressed)
	$Background/Options.pressed.connect(self._on_OptionsButton_pressed)
	$Background/Exit.pressed.connect(self._on_ExitButton_pressed)

func _on_PlayButton_pressed():
	print("Play button pressed")
	var next_scene = load("res://character_selection.tscn").instance()
	get_tree().change_scene(next_scene)

func _on_OptionsButton_pressed():
	print("Options button pressed")
	# Implementa le opzioni qui

func _on_ExitButton_pressed():
	print("Exit button pressed")
	get_tree().quit()
