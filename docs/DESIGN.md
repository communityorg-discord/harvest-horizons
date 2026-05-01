# Harvest & Horizons — Design Doc

Living spec. Implementation arrives in phases; each rule below is normative for the system listed.

---

## Sleep + Save System

The bed is the only save point. The player must walk to the cottage at the end of each day and click the bed to sleep.

| Bedtime | Wake time | Penalty |
|---------|-----------|---------|
| Anywhere up to 10:59 PM | 5:00 AM | None |
| 11:00 PM | 5:00 AM | None |
| 12:00 AM | 6:00 AM | None |
| 1:00 AM | 7:00 AM | None |
| 2:00 AM | 8:00 AM | None |
| Stay up past 3:00 AM | Pass out, wake at 2:00 PM | **−50% max HP, −50% max Energy** |

Rules:
- Player always wakes **at the side of the bed**, regardless of where they collapsed if they passed out elsewhere.
- Clicking the bed = `sleep()` action: auto-saves the game, advances time to wake hour, restores HP and Energy to full (unless pass-out, see below).
- If the player has not slept by 3:00 AM, the game forces a `pass_out` event: time skips to 2:00 PM next day, HP and Energy clamped to 50% of max.
- Save format: single JSON file in user-data dir, written atomically.

### Implementation notes (for later)

- `GameState.sleep()` — call from a `BedInteractable` Area3D when clicked
- `GameState._process()` — check if `hour >= 3 and not has_slept_today` → trigger pass-out
- `GameState.save_game()` / `load_game()` — JSON of money, time, day, weather, rank, quest_flags, inventory, current_tool, hp, energy
- Wake-at-bed: cottage_interior scene spawns the player at a `BedSide` Marker3D, not at the scene default position.

---

## Story / progression

(See `data/quests.json` and `data/areas.json` for the data shapes. Below is the prose summary.)

The player is a farmer chosen by the **Wizard**. Mysterious letter → arrive at abandoned farm → restore it → help townsfolk → unlock new areas → discover magical secrets → final trial.

### Rank progression
1. New Arrival
2. Local Helper
3. Trusted Farmer
4. Town Restorer
5. Valley Hero
6. Chosen Guardian (endgame)

### Early quest cadence

- **Storm Quest** — early-game weather event. Gates the appearance of the picket fence around the farm patch (the fence does not exist before this quest completes).
- **First Harvest** — gates the existence of soil tiles. The player must pick up the hoe and till tiles themselves; the farm grid is not pre-built.

These quests should NOT auto-fire — they're triggered by Wizard letters / NPC dialogue.

---

## Areas

(See `data/areas.json` for the gating rules.)

- **Farm** — start area. Cottage + ground decor + perimeter cliff walls.
- **Town Centre** — east of farm. Plaza + 4 shops + fountain. NPCs to be added.
- **Forest, Mines, Beach, Mountain Pass, Ancient Ruins, Wizard Tower** — locked behind rank + quest flags.

---

## Look & feel

- **Style:** low-poly 3D + isometric ¾ camera + warm cozy lighting. Inspired by Stardew Valley and Tiny Glade.
- **Camera:** 35° pitch, 45° yaw, orthographic, smooth follow.
- **Asset packs:** Kenney Nature Kit + Survival Kit (CC0). See `assets/models/CREDITS.md`.
- **Procedural decor density:** trees, rocks, stumps, flowers, grass tufts seeded so layouts stay consistent across runs.
