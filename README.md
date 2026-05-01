# Harvest & Horizons

Cozy 2.5D farming + adventure prototype, inspired by Stardew Valley with modern lighting and depth. Built in **Godot 4.3**.

---

## Story

The player is a farmer chosen by a mysterious **Wizard**, who sends a letter inviting them to take over an abandoned farm near **Greenfield Valley**. Restore the farm, help the townsfolk, unlock new areas, discover magical secrets, and prepare for the Wizard's final trial.

### Rank progression
1. New Arrival
2. Local Helper
3. Trusted Farmer
4. Town Restorer
5. Valley Hero
6. Chosen Guardian

Ranks unlock through main quests, townsfolk help, building restoration, area discovery, farm growth, combat, and seasonal events. Areas are gated by rank + quest flags (see `data/areas.json`).

---

## Run it

Godot 4.3 is installed at `~/.local/bin/godot`.

```bash
# editor
~/.local/bin/godot --path /home/vpcommunityorganisation/clawd/harvest-horizons

# headless run (for smoke-test)
cd /home/vpcommunityorganisation/clawd/harvest-horizons
~/.local/bin/godot
```

**Controls:** WASD to move. Other inputs come online in later phases.

---

## Project layout

```
harvest-horizons/
├── project.godot           # Engine config + input map + autoloads
├── scenes/                 # World/level scenes
│   ├── main.tscn           # Phase 1 farm scene (player + ground + camera + HUD)
│   ├── player.tscn         # CharacterBody3D + capsule + collider
│   └── camera_rig.tscn     # Tilted orthographic follow camera
├── scripts/                # Gameplay scripts
│   ├── game_state.gd       # Autoload: time, money, weather, rank, quest flags
│   ├── main.gd             # Drives sun rotation from time-of-day
│   ├── player.gd           # WASD movement
│   └── camera_rig.gd       # Smooth follow
├── ui/                     # UI scenes + scripts
│   ├── hud.tscn / hud.gd   # Top-bar money / weather / date / time
├── systems/                # Reusable subsystems (inventory, farming, economy…)
├── data/                   # JSON game data
│   ├── areas.json          # Area unlock gating
│   └── quests.json         # Main story quests
└── assets/                 # Placeholder art / textures
```

---

## Phase plan

| Phase | Status | Scope |
|-------|--------|-------|
| **1a — Core scene & HUD** | ✅ Done | Project scaffold, GameState autoload, player + camera + ground, HUD, day/night sun, rank/quest data shape |
| **1b — Inventory & farming loop** | ⏳ Next | Tool hotbar (1-6), inventory grid, till/plant/water/grow/harvest |
| **2 — Economy** | ⏳ | Shop UI (buy/sell/specials/buyback), dynamic pricing, market trends, daily restock |
| **3a — Story spine** | ⏳ | Wizard letter intro scene, quest log UI, rank-up notifications, area unlock checks |
| **3b — Skills & house upgrades** | ⏳ | Skill XP + perk trees (5 skills), 5-tier house upgrade flow via Blacksmith |
| **3c — Animals** | ⏳ | Coop/Barn/Pigpen, 6 starter animals, daily product drops, happiness |
| **4 — World & combat** | ⏳ | Scene switching (Town/Forest/Mines/Beach), enemy AI + combat, loot drops |
| **5 — Endgame** | ⏳ | Ancient Ruins, Wizard Tower, final trial quest |

Each phase ends in a runnable build.

---

## Data-driven by design

Crops, animals, items, shop stock, quests, and area unlocks all live in `data/*.json` so designers can iterate without touching code. Systems load these at startup into typed dictionaries.
