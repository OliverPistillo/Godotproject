extends Node3D

@onready var spawn_point: Marker3D = $SpawnPoint

func _ready() -> void:
	if Global.selected_hero:
		var hero = Global.selected_hero
		print("Eroe ricevuto:", hero.name, "- Statistiche:", hero.stats)

		# Istanzia modello placeholder
		var placeholder_scene = preload("res://assets/models/placeholder.glb")
		var instance = placeholder_scene.instantiate()
		instance.position = spawn_point.position
		add_child(instance)
	else:
		print("⚠ Nessun eroe selezionato")
