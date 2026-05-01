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

---

## Calendar

- **Year structure:** 4 seasons × 28 days = 112 days per year.
- **"Months" are the seasons themselves** — Spring, Summer, Autumn, Winter. Format: `Spring 12, Y2`.
- **Day tick:** 1 in-game minute per real second by default (24-min real day). Adjustable via `GameState.time_speed`.
- **Sunrise:** 6 AM. **Sunset:** 8 PM. **"1 hour before sunset" = 7 PM** (the trigger for the lighting tutorial mission).

---

## Lighting + Monster Spawn Rules

Light is the foundation of safety. Without it, monsters spawn at night.

### Spawn rules

- **Daytime (6 AM – 8 PM):** monsters do **not** spawn anywhere except the **Mines** and **Ancient Temples**. Wild animals (bears, wolves, etc.) can spawn during the day.
- **Nighttime (8 PM – 6 AM):** monsters spawn anywhere there is **no light source within range**.
- **Lit zones never spawn monsters,** night or day:
  - Town Centre (always lit)
  - Wizard Tower (magical ward — no monsters on that land at all)
  - Pier (lights)
  - Player's farm once they've placed the required lights
  - Other map locations: TBD per area (designer's call)
- **Storms:** monsters can spawn even **during the day** during a storm.

### Player-placed lighting on the farm

- Initially the farm has **zero lights** — the player doesn't know this yet.
- **1 hour before sunset on Spring 1**, an NPC visitor rushes in with the line:
  > *"Are you mental?! You have no lights — you're going to be eaten alive by them creatures!"*
- This activates the **"Light the Farm"** quest:
  - Find 3 lights scattered around the farm
  - Place them in 3 predefined spots
  - Quest completes when all 3 are placed
- Visitor also gifts a **Rusted Sword** with the warning:
  > *"After 50 animal kills it'll snap. Blacksmith might sell better ones — but no one goes into the mines anymore since the flood swamped it all. Needs recovering."*
- As the farm expands, the player must place **additional lights** to cover new areas.

### Farming curfew

- After **7 PM** the player **cannot use farming tools**.
- Unlocked by the **"Monster Extermination"** skill, which permanently bans monsters from the farm (and therefore lifts the curfew).

---

## Combat + Death

### Weapons

- **Tier ladder (cheapest → strongest):** Rusted → Bronze → Silver → Gold → Diamond.
- Each tier has its own durability (HP) — Rusted Sword is the worst (snaps after 50 animal kills).
- **Equipment Master skill** (purchasable) grants permanent access to all weapons + tools at any tier with no durability decay.

### Death

- If a monster kills the player → wakes up at the **Doctors Hub** (new location).
- Penalty: **money is deducted** (TBD: scaling formula or flat fee).
- **Wake time: 2 PM**. HP and Energy clamped to **50% of max** (same penalty as a 3 AM pass-out).

---

## Storms + Weather

### Day 1–3: tutorial weather

- Spring 1, 2, 3: always sunny.
- **Spring 4: cloudy → storm**.
  - Player wakes to a knock at the door — the Mayor:
    > *"Storm's coming. Any crops not protected by fencing could wither away. Get wood and have the Blacksmith craft fence panels, or buy them at the General Store."*
  - This is the **Build Your First Fence** quest.

### Storm rules

- **No NPCs are outside** during a storm.
- **Tools and farming equipment are disabled** — only weapons can be used.
- **Most animals stay sheltered** (hardly any wild animals around).
- **Monsters can spawn during the day** during a storm.
- **Shops still serve** the player during storms but greet with:
  > *"They're out — be careful."*

### Per-season weather rules

| Weather | When it can occur |
|---------|------------------|
| Sunny   | Any season |
| Cloudy  | Any season |
| Rainy   | Any season |
| Windy   | Any season — **higher chance of better-rarity crops** when harvested |
| Snowy   | First 15 days of Spring, last 15 days of Autumn, all of Winter |
| Hot     | Summer only — see below |
| Stormy  | Any season |

### Hot days (Summer only)

- **Cannot enter the Mines or Desert** while it's hot — too dangerous. Lifted by the **Weather Immune** skill.
- Crops **must be watered 3 times** that day.
  - 1 watering: 20% chance of survival.
  - 2 waterings: ~50% chance.
  - 3 waterings: 100% survival.
  - Zero waterings on a hot day: crop dies.

### Temperature gauge

- HUD shows a **per-location temperature** that drifts depending on:
  - Current season + weather
  - Player's current area (mines = cool, desert = hot, snowy peaks = freezing)
- Drives the Weather Immune / Winter Jacket gates.

### Winter Jacket

- Required to enter **Snowy Peaks**.
- **Cannot be obtained until Autumn 1** (clothing store quest must be done first).
- Sold at a new **Clothing Store** that's only built after the *"Build a Clothing Store"* town-restoration quest.

---

## Radio (inside the cottage)

- Place a **Radio** prop inside the cottage.
- Picks up a city station that broadcasts:
  - **3-day weather forecast** (current day + next 2)
  - **Daily new recipe** (cooking system, future)
- Interacting with the radio opens a small UI panel.

---

## Mines

- **50 floors** total, ascending difficulty.
- Each floor has its own monster mix and ore/product table.
- **Every 10 floors = a "tier"** with unique resources (Floors 1–10 copper, 11–20 iron, etc.)
- **Pickaxe required to enter.**
- Mines are **locked at game start** — currently flooded.
- Unlocked by the **"Unswamp the Mines"** quest (involves the Blacksmith story).
- Hot summer days block entry unless Weather Immune is unlocked.

---

## Electric Bill + Generator

- **Day 15** (Spring 15): Mayor approaches the player.
  > *"Thanks for what you've been doing. Here's your bill for this month."*
  > *Player: "Wait — what? I thought it was free."*
  > *Mayor laughs: "Everyone has to pay,"* and walks off.
- An NPC then turns up:
  > *"Oh — first electric bill? How much?"*
  > *Player looks: "5,000 g."*
  > *"Tip: mine 50 ore and pump it into the generator behind your farm — that covers it. Still 5,000 g due this time, but you're set going forward."*
- **Generator** prop appears behind the cottage (becomes interactable).
- **Bill is due Summer 1.** If unpaid, the Mayor locks the player up.

---

## Prison System

- Located in the **Desert** (so it's far away — long walk back, lost days).
- **Get locked up by:**
  - Failing to pay the electric bill (or future recurring bills) by the deadline
  - Stealing from shops (future)
  - Trespassing on locked NPC properties
  - Attacking NPCs (future)
  - TBD: more triggers
- **Effects of being locked up:**
  - Skip ahead N days (depends on offence)
  - Tools / weapons confiscated until release
  - Reputation drop with all NPCs
- **Days are precious.** Multi-day jail time can wreck quest deadlines, crop schedules, electric-bill cycles.

---

## Game Opening (no save detected)

The player lands directly into the **Town Centre**, near the Mayor.

- **Mayor:** *"What has you here? We haven't had visitors in years."*
- **Player:** *"I got a letter from the Wizard — to restore the farm and the town."*
- **Mayor (huge reaction):** *"The Wizard? He's still alive? We haven't seen him since the great… flood."*
- Mayor directs the player to the farm and gives them a **minimap**.

When the player walks onto the farm:
- **Greeted by the Inn Master** (Lily). She:
  - Tells the history of the town
  - Explains how the farm works
  - Hands over the **Quest Book** ("from the Wizard — complete it and he'll meet you. This restores the whole town.")
  - Gives **basic tools** (rusted hoe, watering can, axe, pickaxe).
    - **Warning: rusted tools die on Summer 1.** Player must replace at the Blacksmith before then.
- The Inn Master returns periodically at major quest milestones with help/explanations.

---

## Crafting

- **Blacksmith has a crafting bench.**
- Crafts: better weapons, equipment, tools, and intermediate products (wood log piles, fence panels, etc.) for quests.
- Recipes are unlocked progressively (some via quests, some via radio broadcasts, some via finding scrolls in the mines).

---

## Implementation roadmap (rough order)

This is months of work. Suggested order so each phase is shippable:

1. **Foundations** (now-ish):
   - Switch GameState to season-month calendar (4 × 28).
   - HP/Energy already done. Add Temperature gauge (location-driven).
   - Save/load infrastructure already done.
2. **Opening cinematic + intro NPCs** (Mayor in town, Inn Master on farm).
3. **Quest book UI** (replaces the static quest panel; supports Wizard's quest log).
4. **Lighting system** + the 7 PM visitor quest + Rusted Sword.
5. **Weather expansion** (Spring 4 storm, weather signals, fence-from-storm quest, hot day mechanics).
6. **Tool durability + tier ladder** (rusted → diamond) + Blacksmith crafting bench.
7. **Mines** (Unswamp quest, 50 floors, ore tiers, pickaxe gating).
8. **Electric bill + generator + prison.**
9. **Doctors Hub + death penalty.**
10. **Snowy Peaks + Winter Jacket + Clothing Store quest.**
11. **Radio + recipe system.**
12. **Endgame** (Wizard Tower, final trial).
