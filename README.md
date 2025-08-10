# Hero Smash

**Hero Smash** è un gioco mobile multiplayer a turni in cui 8 giocatori si sfidano in duelli 1vs1, potenziando il proprio eroe tramite carte e strategie di gioco.  
Il progetto è sviluppato in **Godot Engine 4.3+** e ottimizzato per dispositivi **iOS** e **Android**.

![Godot Engine](https://img.shields.io/badge/Godot-4.3+-blue)
![Status](https://img.shields.io/badge/Status-Playable-green)
![Platform](https://img.shields.io/badge/Platform-PC%20%7C%20Mobile-green)
![Completion](https://img.shields.io/badge/Core%20Systems-100%25-success)

---

## 🚀 Quick Start

### Prerequisiti
- **Godot Engine 4.3+** ([Download](https://godotengine.org))
- Git (opzionale)
- Blender 3.0+ (opzionale, per modelli custom)

### Avvio Rapido
```bash
# 1. Clona il repository (o scarica lo ZIP)
git clone https://github.com/tuousername/hero-smash.git

# 2. Apri Godot Engine

# 3. Importa il progetto selezionando 'project.godot'

# 4. Premi F5 per giocare!
```

---

## 🎮 Come Giocare

### Obiettivo
Sopravvivi più a lungo possibile in una battaglia royale a turni contro 7 altri giocatori. Potenzia il tuo eroe con carte strategiche e rimani l'ultimo in vita!

### Fasi di Gioco

#### 📋 **Preparation Phase** (20 secondi)
- Ricevi **300 coins** per round (cumulabili)
- **Acquista carte** dal market per potenziare il tuo eroe
- **Reroll** (20 coins): Cambia le carte disponibili
- **Random Card** (100 coins): Ottieni una carta casuale
- **Lock**: Blocca carte per il prossimo round
- **Ready**: Termina la preparazione in anticipo

#### ⚔️ **Duel Phase**
- Combattimento **automatico** 1vs1
- Il vincitore è determinato da:
  - Statistiche dell'eroe
  - Carte acquistate
  - RNG (critico, schivata)
- **Sudden Death** dopo 45 secondi
- Perdita HP basata sulla win streak dell'avversario

---

## 🃏 Sistema Carte

### Rarità
| Rarità | Punti Ramo | Costo | Sblocco |
|--------|------------|-------|---------|
| **Normale** (Blu) | +1 | 100 🪙 | Sempre |
| **Epica** (Viola) | +2 | 200 🪙 | Livello 10+ |
| **Leggendaria** (Oro) | +3 | 300 🪙 | Livello 20+ |

### Branches (Rami)
- **12 rami totali**: Wound, Essence, Rage, Ice, Toxin, Shield, Healing, Power, Precision, Guardian, Assault, Dodge
- **8 attivi** e **4 bannati** casualmente ogni partita
- Ogni carta appartiene a 1-2 rami

### Livelli Eroe
| Livello | Punti Richiesti | Bonus |
|---------|----------------|-------|
| 1 | 0 | Base |
| 2 | 4 | +Stats |
| 3 | 10 | +Stats, Carte Epiche |
| 4 | 20 | +Stats, Carte Leggendarie |
| 5 | 40 | Max Power |

---

## 💰 Sistema Economico

### Guadagno Coins
| Fonte | Importo | Condizione |
|-------|---------|------------|
| **Round Base** | 300 🪙 | Ogni round |
| **Interesse** | +10 per 100 🪙 | Max +100 |
| **Vittoria** | +50 🪙 | Vinci il duello |
| **Win Streak** | +20 per vittoria | Max +100 |
| **Sconfitta** | +15 per HP perso | Compensazione |
| **Lose Streak** | +15 per sconfitta | Max +60 |

**💡 Strategia**: Mantieni 1000+ coins per massimizzare gli interessi!

---

## 🦸 Sistema Eroi

### Statistiche Base
- **Max Health**: 900-1250 HP
- **Attack Damage**: 22-28
- **Attack Speed**: 0.87-1.16
- **Critical Chance**: 8-22%
- **Dodge Chance**: 7-20%
- **Mana Regen**: 9-12/s

### Eroi Disponibili (16)
Fireheart, Frostfang, Bloodthorn, Stormblade, Duskwhisper, Windrider, Darkbane, Nightshade, Emberforge, Ironfist, Darion Starseer, Shadowflame, Steelbane, Voidwalker, Blackthorn, Skydancer

---

## ⚔️ Sistema Combattimento

### Tipi di Danno
| Tipo | Evitabile | Critico | Influenzato da Scudi |
|------|-----------|---------|---------------------|
| **Fisico** | ✅ | ✅ | ✅ |
| **Magico** | ❌ | ✅ | ✅ |
| **Puro** | ❌ | ❌ | ❌ |
| **Toxin** | ❌ | ❌ | ✅ |
| **Chaos** | ❌ | ❌ | ❌ |

### Effetti Stack
- **🛡️ Shield**: Riduce danni ricevuti (0.2% per stack)
- **🔥 Rage**: Aumenta velocità attacco (0.1% per stack)
- **❄️ Ice**: Rallenta nemico (0.2% per stack)
- **☠️ Toxin**: DoT (0.3 danno per stack ogni 0.5s)
- **🩸 Wound**: Amplifica danni subiti (0.1% per stack)

---

## 📂 Struttura Progetto

```
GodotProject/
├── 📄 project.godot           # Configurazione principale
├── 📁 scenes/                 # Scene Godot (.tscn)
│   ├── ui/                   # Menu, Market, HUD
│   ├── entities/              # Hero3D, Card3D
│   └── game/                  # Battle, Arena
├── 📁 scripts/                # Codice GDScript
│   ├── autoload/              # GameManager, EconomyManager
│   ├── gameplay/              # BattleManager, DuelPhase
│   └── ui/                    # Menu, Market scripts
├── 📁 data/                   # Configurazioni JSON
│   ├── heroes.json            # Dati eroi
│   ├── deck.json              # Dati carte
│   └── economy.json           # Economia
└── 📁 assets/                 # Grafica e Audio
    ├── models/                # Modelli 3D (.glb)
    ├── textures/              # Icone e UI
    └── audio/                 # Musica e SFX
```

---

## 🛠️ Stato Sviluppo

### ✅ Completato (100%)
- [x] **Core Gameplay**: Round, Fasi, Matchmaking
- [x] **Sistema Carte**: Acquisto, Rarità, Branches
- [x] **Sistema Economico**: Coins, Interessi, Streak
- [x] **Combattimento**: Danni, Effetti, Critico/Schivata
- [x] **UI Funzionale**: Menu, Market, HUD
- [x] **Autoload System**: Manager centralizzati
- [x] **Scene Structure**: Tutte le scene necessarie

### 🚧 In Sviluppo
- [ ] **Grafica 3D**: Modelli eroi e carte
- [ ] **Audio**: Musica e effetti sonori
- [ ] **Bilanciamento**: Testing statistiche
- [ ] **Particelle**: Effetti visivi combattimento
- [ ] **Animazioni**: Idle, Attack, Death, Victory

### 📋 Pianificato
- [ ] **Multiplayer Online**: Server dedicato
- [ ] **Ranking System**: Classifiche globali
- [ ] **Shop**: Skin e personalizzazioni
- [ ] **Battle Pass**: Sistema progressione
- [ ] **Tornei**: Eventi speciali

---

## 📱 Build & Export

### Android
```bash
# Requisiti: Android SDK, JDK 11+
# In Godot: Project → Export → Android
# Configura keystore e firma
# Export APK/AAB
```

### iOS
```bash
# Requisiti: macOS, Xcode, Apple Developer Account
# In Godot: Project → Export → iOS
# Export progetto Xcode
# Build e firma in Xcode
```

### Configurazioni Export
- **Package Name**: `com.herosmash.game`
- **Version**: 0.1.0
- **Min SDK**: Android 21 / iOS 12.0
- **Orientamento**: Landscape
- **Permissions**: Internet (multiplayer futuro)

---

## 🎨 Assets Necessari

### Priorità Alta
1. **Font UI**: Kenney Future Narrow ([Download](https://kenney.nl))
2. **Icone Branches**: 12 PNG 32x32 per ogni ramo
3. **Placeholder Heroes**: Almeno 3 modelli base

### Priorità Media
- Texture carte (background per rarità)
- Effetti particellari
- UI icons (coins, health, mana)

### Priorità Bassa
- Musica menu
- SFX combattimento
- Animazioni complesse

---

## 🐛 Troubleshooting

| Problema | Soluzione |
|----------|-----------|
| **"Script not found"** | Ricarica progetto: Project → Reload |
| **"File not found"** | Verifica percorsi in .tscn files |
| **Autoload mancanti** | Project Settings → Autoload → Aggiungi scripts |
| **Performance bassa** | Disabilita ombre in Project Settings |
| **Build fallita** | Verifica export templates installati |

---

## 📊 Tabelle Dati Gioco

### Danno per Win Streak
| Streak | Danno HP |
|--------|----------|
| 0-1 | 2-3 |
| 2-3 | 4-5 |
| 4-5 | 7-10 |
| 6-7 | 13-16 |
| 8+ | 20 |

### Economia per Round
| Round | Coins Base | Max Interesse | Coins Totali Possibili |
|-------|------------|---------------|----------------------|
| 1 | 300 | 0 | 300 |
| 2 | 300 | 30 | 630 |
| 3 | 300 | 60 | 960 |
| 4 | 300 | 90 | 1290 |
| 5+ | 300 | 100 | 1400+ |

---

## 🤝 Contributing

1. Fork il progetto
2. Crea un branch (`git checkout -b feature/AmazingFeature`)
3. Commit modifiche (`git commit -m 'Add AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Apri una Pull Request

---

## 📜 Licenza

Questo progetto è distribuito sotto licenza MIT. Vedi `LICENSE` per maggiori informazioni.

---

## 👥 Team

- **Game Design**: [Il tuo nome]
- **Programming**: [Il tuo nome]
- **Art**: Asset Kenney (placeholder)
- **Testing**: Community

---

## 📞 Contatti

- **Email**: herosmash@example.com
- **Discord**: [Link Discord Server]
- **Twitter**: @HeroSmashGame

---

## 🙏 Ringraziamenti

- **Godot Community** per il supporto
- **Kenney.nl** per gli asset placeholder
- **OpenGameArt** per risorse gratuite
- Tutti i beta tester

---

## 📈 Changelog

### v0.1.0 (2024-01-XX) - Initial Playable
- ✅ Core gameplay loop completo
- ✅ Sistema carte funzionante
- ✅ UI navigabile
- ✅ Combattimento automatico
- ✅ 16 eroi giocabili
- ✅ Export Android/iOS ready

### Roadmap v0.2.0
- 🎨 Asset grafici definitivi
- 🔊 Audio e musica
- ⚖️ Bilanciamento gameplay
- 🌐 Multiplayer base

---

**Made with ❤️ using Godot Engine**

*Hero Smash - Battle for Glory!* ⚔️🏆