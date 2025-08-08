# ============================
# SISTEMAZIONE PROGETTO GODOT
# ============================

Write-Host ">>> Creazione struttura cartelle..." -ForegroundColor Cyan
# 1) Struttura base
mkdir assets\fonts -Force
mkdir assets\icons -Force
mkdir assets\images -Force
mkdir assets\logos\branches -Force
mkdir assets\shaders -Force
mkdir data -Force
mkdir docs -Force
mkdir scenes\ui -Force
mkdir scripts\autoload -Force
mkdir scripts\gameplay -Force
mkdir scripts\characters -Force
mkdir scripts\ui -Force
mkdir ui\themes -Force

Write-Host ">>> Spostamento scene..." -ForegroundColor Cyan
# 2) Scene principali
Move-Item -Path main_menu.tscn -Destination scenes\ -Force -ErrorAction SilentlyContinue
Move-Item -Path character_selection.tscn -Destination scenes\ -Force -ErrorAction SilentlyContinue
Move-Item -Path battle_scene.tscn -Destination scenes\ -Force -ErrorAction SilentlyContinue

Write-Host ">>> Spostamento script..." -ForegroundColor Cyan
# 3) Script
Move-Item -Path main_menu.gd -Destination scripts\ui\MainMenu.gd -Force -ErrorAction SilentlyContinue
Move-Item -Path panel_branch.gd -Destination scripts\ui\PanelBranch.gd -Force -ErrorAction SilentlyContinue
Move-Item -Path market_card.gd -Destination scripts\gameplay\MarketCard.gd -Force -ErrorAction SilentlyContinue
Move-Item -Path card_management.gd -Destination scripts\gameplay\CardManagement.gd -Force -ErrorAction SilentlyContinue
Move-Item -Path preparation_phase.gd -Destination scripts\gameplay\PreparationPhase.gd -Force -ErrorAction SilentlyContinue
Move-Item -Path CharacterSelection.gd -Destination scripts\characters\CharacterSelection.gd -Force -ErrorAction SilentlyContinue
Move-Item -Path character_movement.gd -Destination scripts\characters\CharacterMovement.gd -Force -ErrorAction SilentlyContinue
Move-Item -Path hero_stats.gd -Destination scripts\autoload\HeroStats.gd -Force -ErrorAction SilentlyContinue

Write-Host ">>> Spostamento asset..." -ForegroundColor Cyan
# 4) Asset vari
Move-Item -Path CardImage.gdshader -Destination assets\shaders\ -Force -ErrorAction SilentlyContinue
Move-Item -Path icon.svg -Destination assets\icons\ -Force -ErrorAction SilentlyContinue
Move-Item -Path icon.svg.import -Destination assets\icons\ -Force -ErrorAction SilentlyContinue

Write-Host ">>> Spostamento documenti..." -ForegroundColor Cyan
# 5) Documentazione
Move-Item -Path Economy.txt -Destination docs\ -Force -ErrorAction SilentlyContinue
Move-Item -Path lista_rami.txt -Destination docs\ -Force -ErrorAction SilentlyContinue
Move-Item -Path "schermata iniziale.png" -Destination docs\ -Force -ErrorAction SilentlyContinue
Move-Item -Path struttura_Godot_project.txt -Destination docs\ -Force -ErrorAction SilentlyContinue
Move-Item -Path "Hero Smash.docx" -Destination docs\ -Force -ErrorAction SilentlyContinue

Write-Host ">>> Creazione JSON base..." -ForegroundColor Cyan
# 6) JSON di configurazione
@"
{
  "active_count": 8,
  "all": [
    { "key": "Assault",  "icon": "res://assets/logos/branches/assault.png",  "order": 0 },
    { "key": "Guardian", "icon": "res://assets/logos/branches/guardian.png", "order": 0 },
    { "key": "Healing",  "icon": "res://assets/logos/branches/healing.png",  "order": 0 },
    { "key": "Ice",      "icon": "res://assets/logos/branches/ice.png",      "order": 0 },
    { "key": "Toxin",    "icon": "res://assets/logos/branches/toxin.png",    "order": 0 },
    { "key": "Power",    "icon": "res://assets/logos/branches/power.png",    "order": 0 },
    { "key": "Precision","icon": "res://assets/logos/branches/precision.png","order": 0 },
    { "key": "Rage",     "icon": "res://assets/logos/branches/rage.png",     "order": 0 },
    { "key": "Dodge",    "icon": "res://assets/logos/branches/dodge.png",    "order": 0 },
    { "key": "Essence",  "icon": "res://assets/logos/branches/essence.png",  "order": 0 },
    { "key": "Wound",    "icon": "res://assets/logos/branches/wound.png",    "order": 0 },
    { "key": "Shield",   "icon": "res://assets/logos/branches/shield.png",   "order": 0 }
  ]
}
"@ | Set-Content -Encoding UTF8 data\branches.json

@"
{
  "coins_per_round": 300,
  "roll_cost": 20,
  "starting_hp": 50,
  "card_costs": { "common": 100, "epic": 200, "legendary": 300 },
  "level_thresholds": [4, 10, 20, 40],
  "rarity_points": { "common": 1, "epic": 2, "legendary": 3 }
}
"@ | Set-Content -Encoding UTF8 data\economy.json

@"
{
  "cards": [
    { "id": "assault_slash", "name": "Assault Slash", "branch": "Assault", "rarity": "common", "cost": 100, "effects": {"atk_pct": 5} },
    { "id": "ice_spike", "name": "Ice Spike", "branch": "Ice", "rarity": "epic", "cost": 200, "effects": {"slow": 20} }
  ]
}
"@ | Set-Content -Encoding UTF8 data\deck.json

@"
{
  "heroes": [
    { "id": "hero1", "name": "Warrior", "stats": { "hp": 50, "atk": 10, "def": 5, "crit": 0.1, "dodge": 0.05 } },
    { "id": "hero2", "name": "Mage", "stats": { "hp": 40, "atk": 15, "def": 3, "crit": 0.15, "dodge": 0.08 } }
  ]
}
"@ | Set-Content -Encoding UTF8 data\heroes.json

Write-Host ">>> Struttura completata con successo!" -ForegroundColor Green
