# scripts/characters/Hero3D.gd
extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer
var hero_id: String = ""
var attack_speed: float = 1.0
var hp: int = 50

func _ready() -> void:
    # Recupera l'eroe selezionato da HeroStats autoload
    hero_id = HeroStats.selected_hero_id
    if hero_id != "":
        var stats = HeroStats.get_stats()
        attack_speed = stats.get("attack_speed", 1.0)
        hp = stats.get("max_hp", 50)
    start_idle()

func start_idle() -> void:
    anim.play("Idle")

func perform_attack() -> void:
    anim.play("Attack")
    anim.queue("Idle") # Torna a Idle dopo l’attacco

func take_damage(damage: int) -> void:
    hp -= damage
    if hp <= 0:
        die()

func die() -> void:
    anim.play("Death")

func start_attack_cycle() -> void:
    start_idle()
    var timer = Timer.new()
    timer.wait_time = 1.0 / attack_speed
    timer.autostart = true
    timer.timeout.connect(perform_attack)
    add_child(timer)
