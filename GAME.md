# REKINDLED — Game Content

*A post-apocalyptic roguelite: descend into cold ruins, carry survivors and
materials home, and rebuild a warm village. Built in Godot 4.7 (GDScript).*

This document summarises **what the game contains** — its story, loop, systems,
and content. For engineering details see `DESIGN.md`; for editing art see
`godot/art/README.md`.

---

## 1. Premise

The world went cold. You are a ginger cat who kept a single **Ember** alive
through the long dark. That ember is nearly spent — but not yet. From a ruined
settlement you descend into subterranean ruins to fight the **husks** (hollow
things the fire left behind), free trapped **survivors**, and haul back the
**materials** to rebuild. As the village grows, its warmth returns and the world
thaws. Civilisation lives in **people and knowledge**, not loot — rescuing a
survivor is the emotional beat.

The **Ember** also narrates: a mentor voice that teaches and reacts as you play.

---

## 2. The core loop

```
        VILLAGE (sanctuary)                    RUINS (roguelite run)
   ┌───────────────────────────┐        ┌──────────────────────────────┐
   │ build · farm · expand      │  E at  │ locked arenas: clear husks    │
   │ villagers work & give      │ Supply │ rescue a survivor, grab loot  │
   │ quests · warmth rises      │ Gate → │ choose a path (Tab map)       │
   │                            │        │ push DEEPER or take a gate    │
   │  ← bank loot, rescues home │ ←──────│ HOME to bank the run          │
   └───────────────────────────┘        └──────────────────────────────┘
```

1. **Prepare** in the village (build, farm, expand, take quests).
2. **Descend** at the Supply Gate.
3. **Run** the ruins: clear locked combat rooms, rescue a survivor, gather loot,
   and choose your path through a branching map — deeper for richer, harder rooms,
   or the **home gate** to bank everything.
4. **Return home**: rescued survivors settle in and start working; spend materials
   to build and expand; complete quests. **Warmth** rises.
5. **Repeat**, going deeper and warmer each time.

---

## 3. Controls

| Input | Action |
|---|---|
| **WASD** | Move (full 8-way) |
| **Left mouse** | Attack — a wide melee sweep (hits all husks in the arc) |
| **Right mouse (hold)** | Guard — blocks a blow (costs guard meter); a *just-in-time* raise parries. You move slowly and can't attack |
| **Space** | Dash — a fast burst with i-frames that **phases through enemies** (not walls) |
| **E** | Interact (free survivors, hammer, plant/harvest, talk to villagers, descend) |
| **B** | Build menu |
| **Tab** | Run map (overview of the current run's branches) |
| **C** | Character sheet (succession stage, stats, boons, attunements) |
| **K** | Codex — recovered knowledge ("the Ember's memories") |
| **L** | Language — toggle **English / Tiếng Việt** (saved between sessions) |
| **Mouse wheel** | Zoom |
| **Esc** | Cancel (build placement / menus) |

---

## 4. The hero & combat  ("Kindled Claws")

- **The cat**: 6 HP, brisk momentum-based movement (ramps in, coasts out), an ember
  scarf. Front/back sprites + left/right mirroring give a full turnaround; every
  action is an analytic three-phase pose (anticipation → strike → recovery) so it
  stays smooth under hit-stop and fast-forward.
- **Combo chain** (left-click): a flowing **3-hit** string — a right crescent, a
  left backhand that sweeps *back* across, and a **CÀN QUÉT** finisher: a full 360°
  spin that hits **everything around you** and knocks husks flying. Hold to flow
  through the chain; the finisher is a deliberate capstone (one per press).
  - **Crits** (~22%): double damage, a bigger gold-hot arc, shockwave ring, crunch,
    "CRIT!" and a camera kick. Floating damage numbers on every hit.
- **Dodge** (Space): a fast i-frame roll that slips **through husks** (walls still
  stop you), glides out with momentum, and leaves a trail.
- **Pounce** (attack during/just after a dodge): a committed lunging stab that flows
  straight into the backhand → finisher — dash → pounce → sweep is one string.
- **Guard & Parry** (hold right-click): a raised guard **blocks**; raising it *just*
  as a blow lands is a **PERFECT PARRY** — the hardest freeze in the game, a radial
  **stagger + knockback** of the husks around you, and an **empowered riposte** (your
  next strike is a guaranteed crit). Guard is **not free**: it draws on a **guard
  meter** (shown under the hearts) that drains while raised and on each blocked blow;
  empty it and the guard **shatters** (a brief lockout) — a perfect parry refunds it.
- **Attunements** (rescue buffs): each survivor rescued grants a permanent
  **attunement** — Bramble Ward (+2 Max HP, *Flora*), Ember Fang (+25% damage,
  *Thermal*), or Gale Step (+25% speed, *Wind*) — re-applied at the start of every
  descent. A banner announces each one; the element tags seed the planned
  progression system (see below).

### Kindling & Blooms — the run's build (EMBERGROWTH Phase 0)

Progression happens **inside a run**. Every husk you fell releases its stored fuel
as **Kindle**; enough Kindle crosses a threshold and you **Bloom** — climbing the
five real stages of **ecological succession** (Ash → Pioneer → Herb → Thicket →
Canopy). A Bloom is a gilded moment (ring burst, camera kick, the hero's ember aura
swelling one notch as you *visibly burn hotter*) and it does two things:

- a **flat succession step** (+12% damage, +4% speed per Bloom; +1 Max HP at two of
  the stages), and
- a **pick-1-of-3 boon** — the run's build choice. A paused card offers three
  draftable boons (e.g. *Ember Fang* +20% damage, *Fleetfoot* +12% speed, *Bramble
  Heart* +2 HP, *Keen Eye* +7% crit); pick one and it applies at once. Blooms and
  boons **reset every descent**, so no two runs play the same.

A slim **Kindle bar** with the five succession notches sits under the hearts in the
ruins, its label naming your current stage. Press **C** for a **character sheet** —
your succession stage, every derived stat (HP / damage / speed / crit), the boons
you've drafted, and your attunements.

**Soil (the head-start).** A warm, populous village lets each descent **begin
further up the succession**: banked warmth (GWI) and settled survivors accumulate as
**Soil**, which seeds your starting stage — so the world you rebuild makes the next
run stronger from the first room. (Soil is shown at home as the meter under the
hearts.) This is the shipped first layer of the deeper **EMBERGROWTH** system in
[`PROGRESSION_DESIGN.md`](PROGRESSION_DESIGN.md) — later phases add the heat-transfer
Modes, ecological Kingdoms, and the honest Mode×Family interaction matrix.

> Design note: this **replaces** an earlier persistent kill-XP "Ember Level" that
> scaled the hero *forever* on top of the husks' own depth scaling — two systems
> double-scaling (PROGRESSION_DESIGN §8.0). Run-scoped Kindle + Soil is the fix:
> per-run challenge is designed, and getting stronger *is* rekindling the world.

---

## 5. The ruins (roguelite runs)

Each descent is a **branching run** of self-contained rooms — Hades-style locked
arenas laid over a Cult-of-the-Lamb node map.

**Locked arenas.** Enter a room and the **exits seal** until every husk is cleared.
Braziers throw flickering firelight, a warm light rides with you, and the rest of
the hall stays near-dark — lit islands in the black. Clearing the room throws a
fanfare and opens the gates.

**The run map (Tab).** A run rolls a layered node graph, boss at the end. On clear,
one **gate opens per reachable node**, each colour-coded and previewing its room
type, plus a **HOME gate** to bank and leave. Walking through a gate commits to that
path; carry your HP and loot forward. Press **Tab** any time to see the whole map,
where you are, and the branches ahead.

**Room types**

| Type | What's inside |
|---|---|
| **Combat** | Husks + loot (the staple) |
| **Treasure** | Few/no husks, a loot hoard |
| **Rescue** | A caged survivor + husks |
| **Rest / Hearth** | A hearth that heals you (+3), light danger |
| **Boss (The Warden)** | A heavy **brute** that must fall to open the way |

**Enemies.** Every blow is **telegraphed** — a husk winds up (a swelling glow) *and
paints a **red danger zone** on the floor* showing exactly where the blow will land
(a lunge lane, a slam ring, a bomb blast), filling in as the strike nears — so there
is always something to read and dodge; standing next to a husk is safe until it
strikes. Crucially, **only a couple of husks commit at once** — the
rest circle and menace, then take their turn — so even a crowded room stays a fight
you can *read* rather than a wall of simultaneous lunges. Difficulty scales with
**both** room depth and how many runs deep you are (capped so kiting stays viable),
so a fresh descent isn't the same every time.

- **Husk** — hunts you, then lunges after a short wind-up. Dissolves into ash on death.
- **Charger** — lines up from across the room and **rushes**; if it slams a wall it
  **stuns itself** (your punish window). Appears deeper in.
- **Lobber** — hangs back and **arcs a blast** onto a red-marked spot — leave the marker.
- **Bomber** — a kamikaze: rushes in, swells a **red blast ring**, then **self-destructs**.
  Pop it early or step out of the circle. Appears deeper in.
- **Warden (brute)** — the boss: a heavy lunge plus a **shockwave** on landing.

Each kind reads apart at a glance — distinct size and body colour (the charger a big
angry red, the lobber a small cold caster, the bomber small and glowing hot).

**Loot & survivors — the run satchel.** Husks and rooms drop **materials** (wood /
stone / iron) into your **run satchel** (shown bottom-left in the ruins). Loot is
**not yours until you bank it**: take a **home gate** alive and it all merges into
the village stockpile; **fall in the dark and you forfeit most of it** (only a
fraction is salvaged). That gamble — bank now or push one room deeper — is the point
of the run. A caged **survivor** waits to be freed (press E); once freed they **trail
you through the rest of the run** — room to room, deeper gate after deeper gate —
and only when you take a **home gate** do they settle into the village to live and
work. (Their rescue and attunement are banked the moment you free them.)

---

## 6. The village (open-air sanctuary)

Home is a large, **sunlit, open-air field** centred on a **bonfire hearth** — warm
daylight even when cold, brightening toward golden as the settlement warms. Natural
elements dress it: a **stream with a plank bridge**, reeds on the banks, and
**trees, bushes, wildflowers and rocks** scattered through the wild grass.

The place **breathes**: the trees, bushes, reeds and flowers all **sway in a
travelling wind**, the **stream flows** with rippling glints, and finished buildings
show they're **lived-in** — a cabin's chimney trails smoke, a forge throws sparks.

**Expandable clearing (no fixed map).** Only the tended **clearing** around the
hearth is buildable. Spend resources on **"Expand Clearing"** in the build menu to
reclaim another ring of the wild — the buildable area grows with the run rather than
being a fixed grid.

**Building.** Open the menu (B), pick a structure, place its frame on tended grass,
then **hammer it up** (E). Finished buildings raise **warmth** — **and each is a
recovered invention that changes how your next descent plays** (the village finally
feeds the run):

| Building | Cost | Warmth (GWI) | Invention → run effect |
|---|---|---|---|
| Cabin | 5 wood, 2 stone | +0.18 | **Construction** — Shelter: +1 Max HP per cabin |
| Forge | 4 stone, 2 iron | +0.15 | **Metallurgy** — sharper claws: +8% damage per forge |
| Crop Bed | 3 wood | +0.05 | **Agriculture** — carry a **Provision** down per bed |
| *Expand Clearing* | rising (wood/stone) | — (grows buildable land) | — |

Each run effect is **capped (3)**, and **duplicate buildings give diminishing
warmth**, so a *diverse* village beats spamming one kind — building choice is a real
decision, not a solved one. **Provisions** are the farm's yield carried underground:
each is a heal charge the cat auto-eats the moment it's badly hurt.

**Farming.** A **crop plot** on a crop bed cycles seed → sprout → leafy → **ripe**;
plant a seed (E), return later to **harvest** food (and a seed back).

### Knowledge — the Codex ("the Ember's memories")

The first time you raise a craft — or rescue the survivor who carries it — its
**invention is recovered**: the Ember says *why it changed the world*, and it enters
your **Codex** (press **K**). Each entry is a real, honest paragraph — the actual
mechanism, ordered by impact, with every game liberty flagged (agriculture and the
Neolithic surplus, metallurgy as applied thermodynamics, the load-bearing arch).
Collecting them is the visible measure of how much of the dead world you've
*remembered*. Civilisation lives in people and knowledge — this is where the game
finally says so out loud.

---

## 7. Villagers & quests

Every survivor brought home becomes a **living villager** who **wanders and works**
the clearing (a farmer, a smith, a builder). Each offers a **one-off quest** —
accept it (E), meet the goal, and turn it in for **warmth + materials**:

| Villager | Quest | Reward |
|---|---|---|
| **Farmer** | Fill the larder — hold 6 food | +2 seeds, +2 wood, +warmth |
| **Smith** | Stoke the forge — bring 5 iron | +4 stone, +warmth |
| **Builder** | Raise the roofs — 3 buildings | +5 wood, +warmth |

This makes the rescue payoff tangible: save someone → they settle and work → they
send you back down for specific loot → turning it in warms the world.

---

## 8. Warmth (Global Warmth Index)

**GWI (0 → 1)** is the game's progress bar. Buildings and completed quests raise it,
and as it climbs the whole sanctuary **warms from cool daylight toward golden hour**
and the bonfire grows. A warm village is the goal — the world reignited.

**Resources**: `wood`, `stone`, `iron` (from the ruins), `food` and `seeds` (from
farming). Materials are spent building and expanding; food/seeds sustain the loop.

---

## 9. Onboarding & guidance

- **The Ember** speaks a guided intro (typewriter dialogue) on your first village
  visit and first descent, with interactive beats ("walk with WASD", "try a dash").
- **Just-in-time tips** teach each activity the first time you meet it — freeing a
  survivor, picking up loot, building, hammering, planting/harvesting, the map, and
  warmth.
- A **guidance beacon** hovers over your current objective, with an **off-screen
  arrow** pointing the way when the target is out of frame.
- A persistent **objective line**, a **controls card**, and **run-depth banner**
  keep you oriented.
- **Language.** The whole interface — dialogue, tips, menus, the character sheet and
  the Codex's real facts — is available in **English** and **Tiếng Việt**, toggled
  live with **L** and remembered between sessions (it defaults to your OS language on
  first run). Combat call-outs (CRIT!, CÀN QUÉT!) stay stylised in both.

### Context-aware HUD

The interface wears **two skins driven by where you are**, so each screen shows only
what it needs (Hades-clean in the ruins, Cult-of-the-Lamb-cozy at home):

- **In the village** — the full economy chrome: resource chips (top-left), the
  **warmth** meter and rescued-survivor roster (top-right), and your hearts
  (bottom-left).
- **In the ruins** — a lean combat frame: the economy chrome folds away, the corners
  dim, and up come a **husk tally** (top-left, ticking down to a gold *CLEARED*), your
  hearts with two **ability pips** beneath them — a **dash** cooldown wedge and a
  **riposte** flare that lights when a parry is armed — and the run-depth banner.
- **In a boss room** — the depth banner gives way to a centred **Warden health bar**
  with a name plate and a lagging "chunk" chip that shows the damage you just dealt.
- Hearts **throb** an ember red when life is critical.

---

## 10. Look & feel

A **2.5D presentation** (a Hades-style floor tilted away from the camera) with
upright, feet-anchored characters, contact shadows, dynamic point lights, and a
cinematic camera (dead-zone follow synced to physics, gentle trauma shake, zoom
punch). Screen effects — embers, slashes, shockwave rings, crunch bursts, dust,
brief hit-stop — give combat weight. The art register is **Cult of the Lamb**: bold
flat fills, thick sticker outlines, soft rounded shapes, a cute animal cast.

**Art is file-based**: every sprite is a PNG in `godot/art/` that the game renders
directly, so the art can be repainted without touching code (the code-drawn versions
serve as regenerable defaults). See `godot/art/README.md`.

---

## 11. Running it & tools

- **Play**: `./play.sh`
- **Watch it play itself**: `./play.sh autoplay` — a hands-off bot runs the full
  loop (build → farm → quests → expand → descend → fight → rescue → choose paths →
  home) so you can observe the game's progress.
- Dev tools (not shipped): `capture` (screenshots), `export_art` (regenerate art
  files), `sheet` (art contact sheet), `bench` (bake timings).

---

## 12. Status

A working **vertical slice** proving the full core loop end-to-end: village →
descent → locked-arena combat with crits/dash/guard → branching run map with typed
rooms and a boss → rescue → home → build/farm/expand → villager quests → rising
warmth → repeat. Engine: **Godot 4.7.1**, GDScript, code-first with file-based art.
