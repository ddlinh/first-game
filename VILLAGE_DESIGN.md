# REKINDLED — Village & Buildings Review + Design Proposal

*A focused critic's review of the **village-building layer** — the weakest part of the current loop —
followed by a concrete design proposal built around the team's direction: **a rescued survivor brings
the knowledge, the hero supplies the labour**. The farm is the worked flagship example.*

**Reviewed build:** `main` (Godot 4.7). Companion to `CRITIQUE.md` (whole-game review) and
`QA_REPORT.md` (engineering tracker). Severity legend: 🔴 Critical · 🟠 Major · 🟡 Minor.

---

## 0. Executive Summary

Right now the village is a **placement puzzle, not a settlement.** There are only three building
types, and each one is a **vending machine**: you pay resources once, it emits a fixed amount of
warmth and a single run-boon (hard-capped at 3), and then it sits inert forever. Buildings don't
produce anything over time, don't depend on each other, don't employ anyone, can't be upgraded, and
carry no spatial meaning. Worst of all, **the farm exists before you earn it** — a Crop Bed is
pre-placed on the first visit (`village.gd` `_seed_and_rebuild`), so farming is decoupled from
rescuing the Farmer, which quietly throws away both the rescue payoff and the game's own thesis that
*"civilisation is carried in people and knowledge."*

**The fix that most changes the game** — and the direction the team wants — is to make buildings
**survivor-gated (knowledge) and resource-gated (labour):** you rescue the person who *knows* the
craft, they lay out the work from that knowledge, they tell you what materials they lack, and that
becomes a **quest** that turns the building on. The farm is the ideal first case and is specced in
§4. This single pattern converts buildings from freebies into an earned, evolving civilisation ladder.

---

## 1. Current State — what a building actually is

The whole catalogue lives in `village.gd BUILDINGS` (3 entries):

| Building | Cost | Warmth (GWI) | What it gives the run |
|---|---|---|---|
| **Cabin** | 5 wood, 2 stone | +0.18 | +1 Max HP per cabin, capped at 3 (`player.gd:848`, `main.gd:391`) |
| **Forge** | 4 stone, 2 iron | +0.15 | +8% damage per forge, capped at 3 |
| **Crop Bed** | 3 wood | +0.05 | +1 Provision (mid-run heal) per bed, capped at 3 |

Plus **Expand Clearing** (spend to tend one more ring of buildable land) and the diminishing-warmth
rule (the Nth duplicate gives `base/N`, `village.gd finish_building`) that discourages spamming one type.

Farming: a Crop Bed hosts a `CropPlot` — plant a seed, wait 4 growth stages, harvest for 2 food + 1
seed. **A Crop Bed is pre-seeded at cell (2,1) on the very first visit** so farming is reachable turn
one, *independent of whether the Farmer has been rescued.*

Villagers (`farmer`/`smith`/`builder`): give one one-off quest each, and — as of the recent UX pass —
a repeatable materials-for-warmth **commission** afterward.

That is the entire village-building layer.

---

## 2. Limitations / Weaknesses (the review)

### 🔴 V1 — Buildings are "fire-and-forget," not operational
Every building is a one-time purchase that emits a static effect. Nothing **runs**: no production
over time, no state, no upkeep, no worker inside it. A finished Forge is visually lit (`village.gd
_add_building_sprite`) but mechanically it is a number that was added once. A settlement should be a
system that *does things while you're away*, not a shelf of trophies.

### 🔴 V2 — The farm is decoupled from the Farmer (thesis + payoff both lost)
The pre-seeded Crop Bed means you farm before rescuing anyone. So rescuing the Farmer — which the
game frames as the emotional heart of a run — currently only grants a **combat buff** (Bramble Ward,
+2 HP) and a Codex entry; it has **no effect on the farm at all.** The one mechanic that should
*belong* to the Farmer is handed out for free at the start. This is the single biggest missed
opportunity in the village and is exactly what §4 fixes.

### 🟠 V3 — Only three buildings, all stat-vending
Three types, and all three do the same *kind* of thing (add a capped run-stat + warmth). There is no
building that produces a resource, stores one, defends the village, houses a survivor, unlocks another
building, or changes how a later run plays. The "rebuild civilisation" fantasy has a vocabulary of three words.

### 🟠 V4 — The run-boon cap makes buildings stop mattering
Each building line is capped at 3 (`mini(forges, 3)` etc., `player.gd:849-854`). After 3 cabins, 3
forges, 3 crop beds, **every further build contributes only a sliver of warmth and nothing else.**
There is no long-tail reason to keep constructing — the village's growth ceiling is ~9 meaningful
buildings, then it's warmth-only.

### 🟠 V5 — No interdependence / no production chains
City- and settlement-builders live on chains: raw → refined → product (ore→ingot→tool; grain→flour→
bread). Here every building is an island that consumes raw resources and emits a stat. There is no
"the Granary lets the Farm store a surplus," no "the Forge needs the Carpenter first." Nothing composes.

### 🟠 V6 — No building upgrades or tiers
A Cabin is a Cabin forever. There is no path from a lean-to → cabin → longhouse, or field → irrigated
field → granary-backed farm. Upgrade tiers are the cheapest way to give a small catalogue enormous depth.

### 🟡 V7 — No population / housing / worker model
Survivors wander and give quests but don't **staff** anything, don't need homes, and don't scale
output. Buildings have no capacity. Rescuing your 4th survivor is mechanically identical to your 1st.

### 🟡 V8 — No storage, caps, or economy pressure
Resources are one flat unbounded pool (`GameState.resources`). No granary, no stockpile caps, no
spoilage, no logistics — so there's never a reason to build economic infrastructure.

### 🟡 V9 — No stakes at the village
Nothing threatens the settlement, so building has no *protective* purpose (no walls, no watchtower
worth raising). Warmth is the only pressure, and it only ever goes up.

### 🟡 V10 — Placement carries no spatial gameplay
Any tended tile is interchangeable. No adjacency bonuses, no zones, no roads, no "the Well must be
near the Farm." The grid + ghost UX is nice, but placement is decoration, not decision.

---

## 3. The Design Direction — "Rescue the knowledge, supply the labour"

The team's instinct is the right spine for the whole layer. State it as a reusable **building
lifecycle** every structure moves through:

```
   DORMANT ──rescue the survivor──▶ BLUEPRINT ──deliver the resource quest──▶ OPERATIONAL ──tier quests──▶ UPGRADED
 (no one knows       (they lay it out from        (it runs: produces /            (irrigation, granary,
  this craft yet)     knowledge, but lack           provides, employs them)         new crops, walls…)
                      materials → a QUEST)
```

- **Knowledge** comes from **people you rescue** (matches the Codex/VISION thesis exactly).
- **Labour/materials** come from **the hero's runs**, funnelled through a **quest** the survivor issues.
- Every building is therefore *earned twice* — once by saving a person, once by supplying them — and
  each step is a concrete goal that gives a run a reason.

This directly repairs V1, V2, V3, V6 and V9-adjacent gaps, and it is a single pattern reused for
every structure, so it scales cheaply.

---

## 4. Flagship Example — The Farmer → Farm quest chain

This is the team's farm idea, fully specced. It replaces the free turn-one Crop Bed.

### 4.1 The chain

| Stage | Trigger | What happens in the village | Player-facing goal |
|---|---|---|---|
| **1. Fallow** | Start of game | A bare, untilled plot sits in the clearing with a marker: *"Untilled ground — no one here remembers how to work it."* Farming is **locked**. | (Go run; rescue people.) |
| **2. Knowledge arrives** | **Rescue the Farmer** in a run | On return the Farmer walks to the fallow ground and, from his knowledge, **lays out the farm** — tills the soil, stakes the beds (a visible "he initialises it" beat). But it's inert. The Ember speaks the Agriculture line (already in `lore.gd EMBER_LINE.agriculture`). | — |
| **3. He lacks resources → new quest** | Immediately after | The Farmer: *"I can read this soil, but I've nothing to work it with — bring me **6 wood** for raised beds and **4 seeds** to sow."* This **spawns a quest for the hero.** | **Bring the Farmer 6 wood + 4 seeds** (gathered from ruins) |
| **4. Operational** | Deliver the materials | The farm **activates**: plots become plantable, and the Farmer **auto-tends and harvests over time**, producing **food** (and Provisions for the next descent). Codex "Agriculture" confirmed. | — |
| **5. Upgrades (repeatable)** | Farmer proposes projects | Each is knowledge(✓ have Farmer) + a **new resource quest**: **Irrigation** (needs stone + a Well) → faster growth; **Granary** (needs wood/stone) → food cap + surplus warmth; **New crops** (seeds from deeper ruins) → higher-value yields. | Tiered "bring N of X" quests |

### 4.2 Why this is the right first build
- **The rescue finally matters** — saving the Farmer *is* how farming exists (fixes V2 and the
  rescue-payoff gap flagged in `CRITIQUE.md`).
- **It creates a genuine reason to descend** — you run to gather the exact materials the Farmer named.
- **It's a resource sink with a payoff curve**, not a one-time purchase (fixes V1/V4).
- **It's on-thesis** — people (knowledge) + hero (labour) = a working farm = the first step of civilisation.
- **It reuses systems that already exist**: the rescue flow (`survivor.gd`), the quest/turn-in state
  machine (`village.gd Villager`, `GameState.quests`), the CropPlot, and the Agriculture Codex hook.

### 4.3 Implementation sketch (for the devs)
- **Remove the turn-one pre-seed** in `village.gd _seed_and_rebuild` (drop the seeded Crop Bed at
  cell (2,1)); replace with a **Fallow marker** node that is inert until the Farmer is home.
- **Gate the farm on rescue**: when `GameState.has_rescued("farmer")` becomes true, have the Farmer
  (or the Village on spawn) convert the Fallow marker into a laid-out-but-locked farm and register a
  new quest (extend the `QUESTS`/state machine already in `village.gd`, or a dedicated `farm_setup`
  quest key). Reuse the existing `quest_progress` / turn-in flow.
- **Activation**: on turn-in, spawn the `CropPlot`(s) and flip the farm to operational; optionally add
  a slow **auto-harvest** tick to the Farmer's `Villager._process` so it produces food while away.
- **Provisions** already flow from crop-bed count (`player.gd apply_village`) — repoint that to the
  farm's operational tier so Provisions become an *earned* reward of the farm chain.

---

## 5. Generalising the pattern — a fuller building catalogue

Apply the same **survivor → blueprint quest → operate → upgrade** lifecycle to a richer set. Each new
survivor archetype gates a building line, which is also more reasons to rescue people.

| Building (survivor gate) | Blueprint quest (example) | Operates as | Upgrades |
|---|---|---|---|
| **Farm** (Farmer) | 6 wood + 4 seeds | Produces food + Provisions over time | Irrigation, Granary, new crops |
| **Forge** (Smith) | ore + stone | Refines iron→tools; +damage tier | Bellows (faster), Steel (higher tier) |
| **Carpenter's Workshop** (Builder) | wood + stone | **Unlocks / speeds other buildings**; +HP/armour | Sawmill, scaffolding upgrades |
| **Granary** (Farmer + Builder) | wood + stone | **Raises resource caps**, preserves food (warmth) | Silo, root cellar |
| **Well / Cistern** (Mason) | stone | New resource **water** → farm & needs | Aqueduct |
| **Apothecary** (Healer) | herbs + wood | Provisions/healing tiers | Tinctures, field kit |
| **Watchtower / Palisade** (Builder) | wood + stone | **Village defence** (if raids are added, §6) | Stone walls, gate |
| **Library / Hearth-shrine** (Scholar) | relics from ruins | Codex/knowledge, boon rerolls, warmth | Archive |

Even shipping **two or three** of these (Carpenter, Granary, Well) alongside the farm chain gives the
village a real progression ladder and interdependence (Granary needs Carpenter; Farm-tier-2 needs Well).

---

## 6. Prioritised Recommendations

| # | Recommendation | Fixes | Effort |
|---|---|---|:---:|
| **P1** | **The Farmer → Farm quest chain** (§4) — remove the free farm, gate it on rescuing the Farmer, and issue his resource quest. The flagship. | V2, V1, thesis | M |
| **P2** | **Building lifecycle framework** (Dormant→Blueprint→Operational→Upgraded, §3) as reusable state, so every building is earned + upgradable. | V1, V6 | M |
| **P3** | **Add 2–3 operational buildings** (Carpenter, Granary, Well) with the same gate pattern + light interdependence. | V3, V5 | M–L |
| **P4** | **Production-over-time + worker assignment** — survivors staff buildings; output scales with population. | V1, V7 | L |
| **P5** | **Storage caps + a soft economy** (Granary raises caps; food feeds survivors → more workers). | V4, V8 | M |
| **P6** | **Village stakes** (optional) — occasional threat the walls/watchtower defend against, giving defensive buildings a purpose. | V9 | L |

**Dependencies to note honestly:** P4/P5 assume a population model; P6 assumes a threat system (new
content, larger scope). P1–P3 stand alone and are the highest value-to-effort — start there.

---

## 7. Appendix — mapping to existing code & docs

- **Where the village lives:** `godot/scripts/village.gd` (`BUILDINGS`, `QUESTS`, `COMMISSIONS`,
  `_seed_and_rebuild`, `finish_building`, inner classes `CropPlot`/`Villager`/`Scaffold`).
- **Building→run coupling:** `player.gd apply_village` (`:848`) + `main.gd _apply_village_boons` (`:379`).
- **Rescue + knowledge:** `survivor.gd`, `GameState.add_rescued` / `has_rescued`, `lore.gd`
  (`PILLAR_ENTRY`, `EMBER_LINE.agriculture`) — the Codex hook the farm chain should reuse.
- **Quest state machine:** `village.gd Villager` (`_state`/`do_interact`) + `GameState.quests` — extend this.
- **Related findings:** ties to `QA_REPORT.md` **F-14** (village inert) and `CRITIQUE.md` **B9**
  (content dead-ends) and **A2** (survivors mechanically, not narratively, meaningful); advances the
  `VISION.md` invention-ladder and `PROGRESSION_DESIGN.md` EMBERGROWTH goals.

---

*Bottom line: the village is currently three vending machines on a lawn. The team's "rescue the
knowledge, supply the labour" instinct — with the Farmer→Farm chain as the first case — is the change
that turns it into a settlement you rebuild, and it does so by reusing systems the game already has.*
