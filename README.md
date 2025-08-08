# Hero Smash

**Hero Smash** è un gioco mobile multiplayer a turni in cui 8 giocatori si sfidano in duelli 1vs1, potenziando il proprio eroe tramite carte e strategie di gioco.  
Il progetto è sviluppato in **Godot Engine 4.4.1** e ottimizzato per dispositivi **iOS** e **Android**.

![Godot Engine](https://img.shields.io/badge/Godot-4.x-blue)
![Status](https://img.shields.io/badge/Status-In%20Development-orange)
![Platform](https://img.shields.io/badge/Platform-PC%20%7C%20Mobile-green)
---

## 🎯 Obiettivo del Gioco

Ogni giocatore sceglie un eroe con statistiche uniche e affronta una serie di duelli contro altri avversari.  
Lo scopo è sopravvivere più a lungo possibile, vincere più duelli possibile e rimanere l’ultimo in vita.

---

## 🕹 Modalità di Gioco

- **8 giocatori** in ogni partita
- Struttura a **round**, ogni round composto da:
  1. **Preparation Phase** – durata 20 secondi
     - Il giocatore è al centro del proprio ring
     - Può acquistare carte dal market
     - Può rimescolare le carte
     - Può bloccare le carte per mantenerle nei round successivi
     - Può concludere il turno in anticipo con il tasto "Pronto"
  2. **Duel Phase**
     - Due giocatori vengono abbinati in combattimento
     - La velocità d’attacco, le abilità e le statistiche determinano l’esito
     - Alla sconfitta si perdono punti vita in base alla serie di vittorie dell’avversario

---

## 💰 Economia di Gioco

- Ogni round si ricevono **300 coin** (cumulabili)
- Carte nel market con costo variabile (100, 200, 300 coin)
- Possibilità di:
  - **Reroll** carte (20 coin)
  - **Acquistare** carte casuali
  - **Bloccare** carte visibili

---

## 🃏 Sistema Carte

- **Tipi di carte**:
  - Normali (1 punto ramo)
  - Epiche (2 punti ramo)
  - Leggendarie (3 punti ramo)
- Ogni carta appartiene a uno dei **12 rami** (Attacco, Ultimate, Fuoco, Ghiaccio, Veleno, Scudo, ecc.)
- **4 rami bannati** casualmente all’inizio di ogni partita
- Livelli eroe basati sui punti ramo:
  - Lv 2 → 4 punti
  - Lv 3 → 10 punti
  - Lv 4 → 20 punti
  - Lv 5 → 40 punti
- Sblocco rarità:
  - Epiche dal livello 10
  - Leggendarie dal livello 20
- Effetti carte:
  - Incremento di statistiche base
  - Bonus unici a seconda del ramo

---

## 🦸‍♂️ Sistema Eroi

- **10 eroi** totali, ognuno con statistiche fisse:
  - Velocità d’attacco
  - Probabilità colpo critico
  - Probabilità schivata
  - Rigenerazione mana
  - Rigenerazione salute
  - Salute massima
  - Difesa fisica
  - Difesa magica
- Ogni eroe parte con **50 HP**
- Alla sconfitta in un duello:
  - Si perdono HP proporzionali alla serie di vittorie dell’avversario
- HP persi durante il duello in base ai danni fisici/magici subiti

---

## 🎨 Grafica e Modelli 3D

- **Arena 3D low-poly** stile cartoonesco
- **Eroi low-poly animati**:
  - Animazione Idle
  - Animazione Attack (velocità variabile in base a Attack Speed)
  - Animazione Death
- Modello 3D delle carte per il market
- Colori personalizzati per ogni eroe
- Asset generati in Blender e esportati in formato `.glb` per Godot

---

## 📂 Struttura del Progetto

```
assets/
  models/
    Hero1.glb
    Hero2.glb
    ...
    Arena.glb
    Card3D.glb
  textures/
    card_placeholder.png
data/
  heroes.json
  deck.json
scripts/
  autoload/
    HeroStats.gd
  characters/
    CharacterSelection.gd
  ...
scenes/
  ui/
    CharacterSelection.tscn
    BattleScene.tscn
```

---

## 🛠 Funzioni Implementate

- **HeroStats.gd**: gestione statistiche eroe, bonus carte e caricamento da JSON
- **Selezione personaggio**: 3 eroi casuali su 10, reroll una sola volta
- **Market carte**: apertura/chiusura manuale o automatica a inizio round
- **Conteggio rami**: con icone e progressione livelli
- **Blocco rami bannati**: esclusione carte non attive
- **UI Battle Scene**:
  - Timer
  - Round counter
  - Coin counter
  - Pulsanti carte e azioni
- **Animazioni eroi** sincronizzate agli eventi di battaglia

---

## 📦 Export Mobile

- Build per Android (.apk / .aab) e iOS (.ipa)
- UI adattata a schermi touch
- Performance ottimizzata con asset low-poly

---

### 🔄 In Sviluppo
- [ ] Bilanciamento carte e abilità
- [ ] Sistema di progressione eroi
- [ ] Modalità campagna estesa
- [ ] Ottimizzazione performance
- [ ] Audio e musiche complete
- [ ] Personaggi 3D e animazioni
- [ ] Sistema di battaglia a turni

### 📋 Pianificato
- [ ] Modalità multiplayer online
- [ ] Versione mobile Android/iOS
- [ ] Sistema di classifica globale
- [ ] Tornei ed eventi speciali
- [ ] DLC con nuove classi di eroi
- [ ] Editor custom per carte utente
- [ ] Eventi stagionali e skin cosmetiche
- [ ] Sistema matchmaking con MMR

---

## 📜 Licenza

Progetto sviluppato per uso interno e distribuzione su store mobile.  
Asset originali creati in Blender e Godot, codice GDScript personalizzato.

