<!--
  Design doc for REKINDLED's natural-elements character progression.
  Adapts upgrade_design_proposal.html's "Ecosystem Resonance System" into a
  concrete, science-vetted spec. Produced via a multi-lens design workflow
  (4 independent designs -> science + Godot-feasibility critique each -> synthesis)
  and reconciled against the live Ember-Level code added alongside this doc.
  See GAME.md (content) and DESIGN.md (architecture).
-->

# EMBERGROWTH — the Kindling & Succession System
### A unified character-progression design for REKINDLED

---

## 1. Pitch

You are the last Ember, carried in the chest of a ginger cat, walking back into a world the fire abandoned. **Everything cold is fuel.** When you strike a husk you are not "farming XP" — you are a heat engine reclaiming the chemical energy locked in dead matter, converting it to **Kindle** (warmth) that makes you burn hotter, brighter, and stronger the deeper you push. Within a single descent you climb five real **ecological-succession stages** (Ash → Pioneer → Herb → Thicket → Canopy) as life re-establishes on the ember you carry; between descents, the survivors you rescue and the warmth you bank into the village (**GWI**) become **Soil** — accumulated humus that lets each new run begin further up the food web. Your claws deliver that heat through the **three real modes of heat transfer** (Conduction, Radiation, Convection), each honestly strong and weak against the material families the cold preserved. Power is warmth; warmth is visible; getting stronger *is* rekindling the world — the fiction and the mechanics are the same thermodynamic story.

This design deliberately unifies the four proposals: the **heat-transfer-mode elements** and the family matrix from *lean-shippable* (the only element scheme that never contradicts "the cat IS the fire"), the **ecological-role Kingdoms** and **succession spine** from *ecology-pure*, the **Hades boon cadence and feedback discipline** from *hades-boons*, and the **survivor/GWI meta loop** all four converged on — with every scientific error the critiques caught corrected, and the single biggest engineering trap (a progression system *already live in the codebase*) confronted head-on.

---

## 2. Core loop at a glance

```
kill husk → release combustion energy → gain KINDLE
   ↓
KINDLE fills the Warmth bar → cross threshold → BLOOM (succession stage-up)
   ↓                                              ↓
flat stat step (dmg/hp/speed)              pick 1 of 3 BOONS (Hades card)
   ↓
you visibly burn hotter (scarf glow + screen grade warms one notch)
   ↓  ...run ends...
90% of energy you spent radiated as heat → banked as GWI on return home
rescued survivors + GWI → SOIL → next run starts further up the succession
```

Two axes of build identity ride on top:
- **Heat mode** (Conduction / Radiation / Convection) — *how* your claws deliver heat; swap mid-run; drives the interaction matrix.
- **Kingdom** (Flora / Fauna / Fungi) — *what ecological role* your boons lean into; unlocked by rescues; biases the boon pool.

---

## 3. Taxonomy & combat integration

Three data layers. **Modes** and **Kingdoms** are the player's two build axes; **Families** are the enemy axis the matrix resolves against.

### 3.1 Heat-transfer Modes (the "elements" — all fire, one active at a time)

The cat is the Ember, so its damage type is *always thermal*. What varies is the physically real **mode of heat transfer**. This is the design's central resolution of the "ice/water on a fire-cat is incoherent" problem every science critique raised: we never bolt a contradictory element onto the hero. You unlock modes by rescuing survivors and tap a key to swap the active one.

| Mode | Fiction | Combat verb it re-skins | Effect |
|---|---|---|---|
| **CONDUCTION ("Blaze")** | heat by direct contact | **3-hit combo** | each melee hit applies a **burn** stack (DoT); the finisher ignites everything it sweeps |
| **RADIATION ("Sear")** | heat across a gap, no medium | **crit (~22%)** + a passive **radiant aura** (small AoE tick to husks within ~60 px/s) | crits deal a **thermal-shock** bonus and *ignore armour/frost gates* — your anti-Slag answer |
| **CONVECTION ("Draft")** | heat carried by moving air (a fire whirl) | **dash + finisher** | the càn-quét finisher becomes an **updraft** that pulls light husks inward and spreads burn between them; dash lays a hot draft trail |

**Design rationale:** three modes (not four classical elements) keeps the roster Hades-clean, needs *zero new inputs* (each mode re-colours the existing combo/dash/parry/crit rather than adding attacks), and is scientifically airtight — conduction, convection, radiation are *the* three heat-transfer mechanisms, full stop.

### 3.2 Kingdoms (build identity — the boon pools, from real trophic roles)

Kingdoms are **ecological roles**, not a taxonomy mash. Each is unlocked by a rescued survivor and biases which boons appear on level-up. You can mix; nothing is locked.

- **FLORA — Producers (sustain / control).** *Photosynthesis:* regen HP while standing **in the Ember's own light or a brazier's glow** (see science note — light, not warmth). *Entangling Roots:* the finisher roots husks in place; thorns reflect contact damage.
- **FAUNA — Consumers (aggression / crit / lifesteal).** *Predatory Instinct:* **+flat bonus damage** vs low-HP husks (predators cull the weak). *Assimilation:* combo hits lifesteal a fraction. *Pack Momentum:* brief speed spike on kill.
- **FUNGI — Decomposers (spread / loot / soil).** *Saprotrophy:* husks killed while afflicted drop **more materials** and feed the meta Soil bar. *Rhizomorph Network:* a decay status **chains** husk-to-husk through a physical black bootlace network (Armillaria — see science note); rotting husks take a heal-block.

*(A fourth role, **Litho** — abiotic pioneer substrate / chemolithotroph tank — is reserved for a later meta unlock, not a rescue, since there are only three survivor pillars.)*

### 3.3 Husk Families (the enemy axis) + depth status

Set on `Enemy.family` in `configure()`. What the cold preserved of the old ecosystem:

- **BRAMBLE (Flora-husk)** — dry dead vegetation. High-fuel, ignites and carries fire.
- **BEAST (Fauna-husk)** — hollow organic remnants, damp. A **moisture gate** (boil off water before it burns).
- **SLAG (Mineral-husk)** — stone/permafrost-encased, inorganic. Non-combustible; yields ~0 Kindle; you *spend* heat to crack it.

**FROST-ENCASED** is a *depth status*, not a family: deep husks (room_index ≥ 3) spawn with a two-phase cold gate (see §5).

### 3.4 Succession stages (the level track)

Five stages, one visible track, driven by Kindle: **Ash → Pioneer → Herb → Thicket → Canopy.** Each Bloom (stage-up) grants a flat stat step **and** a boon card. This is *secondary* succession (the ruin retains legacy substrate) — see science note.

---

## 4. Acquisition & upgrade

### 4.1 Run-scoped: Kindle → Blooms → Boons (the core new loop, resets each descent)

- **Kindle on kill.** Every husk releases its stored **chemical fuel** as Kindle when it dies. `kindle_gain` is the husk's **heat of combustion**, which *varies by family*: **Bramble high, Beast low (wet), Slag ≈ 0** (see science fix — this replaces the incoherent flat `max_hp` grant). This makes family choice a real Kindle-economy decision *and* stops non-combustible rock from minting energy from nothing.
- **Cold drain (optional, honest tension).** In sub-zero rooms the Ember slowly **radiates Kindle away** (2nd law: heat flows to the cold). Kills replenish it; deeper rooms drain faster; Convection/aura boons reduce the drain. Turns "stand still and win" into "keep the fire fed." *Ship behind a flag; enable once pacing is tuned.*
- **Bloom (level-up).** Crossing a cumulative Kindle threshold (`[0, 8, 20, 40, 70]`) advances a succession stage: `damage_mult += 0.12`, `speed_mult += 0.04`, `+1 max_hp` on stages 2 & 4, **then a Hades pick-1-of-3 boon card.** A ~5-husk room yields ~2 blooms early, so power tracks kills → tracks depth. **This is the fix for "the hero gets weaker deep in a run."**
- **Boons** are drawn 3-at-a-time, weighted by your unlocked **Kingdoms** and active **Mode**. Rarity tiers (Common → Warm → Radiant, ~+40% each); **picking a boon you already hold upgrades its tier** instead of duplicating.

### 4.2 Synergies (Duo boons, unlocked when you hold the prerequisites)

Appear automatically in the offer pool once both prerequisites are held. Kept physics-honest:

- **THERMAL SHOCK** (Conduction/Radiation + a frost-gated target): heat then rapid cooling (dash-away / cold room) → ΔT fractures brittle solids → shatter bonus. *Real.*
- **FIRESTORM** (Convection + Conduction): draft supplies the **oxygen leg** of the fire triangle → any active burn intensifies and self-spreads. *Real combustion.*
- **NUTRIENT BLOOM** (Flora + Fungi): each Fungi-kill releases nutrients that heal you / sprout a thorn. *Real: decomposers recycle N/P/C to producers.*

### 4.3 Meta-progression: Soil (persistent), Survivors, GWI

- **Soil / Humus** = the persistent meta bar. `soil = clamp(gwi*0.6 + rescued.size()*0.05, 0, 1)`. Higher Soil sets your **starting succession stage** (`start_stage = floor(soil*2)`) and starting Kindle — a warm, populous village literally begins each descent further up the food web. *Real ecology: accumulated humus lets richer communities establish sooner.*
- **Rescued survivors** each: (a) keep their **existing permanent stat buff** (armor/damage/speed — no design thrown away); (b) **unlock one Kingdom AND one heat Mode**; (c) raise Soil. The old "capped at 3 buffs forever" bug becomes the clean unlock arc — **3 rescues = all three Modes + all three Kingdoms.** `add_rescued` keeps its dedup (correct — the roster shouldn't double-count); only the *benefit* is uncapped (Soil scales with roster size, GWI keeps rising via quests).
  - **SMITH → Conduction + Fauna** (forge heat, the hunter's edge)
  - **BUILDER → Radiation + Flora** (the hearth's glow across a room; growth)
  - **FARMER → Convection + Fungi** (controlled field burns / drafts; the soil-worker)
- **GWI ties the loop:** villager quests already grant GWI on turn-in → GWI raises Soil → Soil pre-heats the next run. **No new meta-currency; GWI + Soil are the meta XP.** This also gives the rescued NPCs (bug 2, fixed separately) a *reason* to trail you home: they staff village stations that later spend Soil on workshops (Phase 4).

> **Persistence caveat (flagged):** GameState currently has **no save/load layer** — `resources`, `rescued`, `gwi` live in memory and reset on quit. Soil/meta is therefore **session-only** until a `save()/load()` (ConfigFile → `user://`) is added. Scoped explicitly into Phase 4; do not promise cross-launch meta before then.

---

## 5. Interaction matrix (Mode × Family) — scientifically honest

The matrix is **Mode × Family** (heat-delivery vs material) — the one airtight matrix. Kingdoms are the *build* layer and stay out of it. Lives as pure data in `elements.gd` so it's tweakable. `S`=strong, `M`=moderate, `W`=weak.

|  | **BRAMBLE** (dry fuel) | **BEAST** (damp organic) | **SLAG** (inorganic rock) |
|---|---|---|---|
| **CONDUCTION** (contact burn) | **S** ×2 burn, **spreads** to adjacent husks | **M** ×1 — must boil off moisture first (moisture gate) | **W** ×0.4 surface only — rock doesn't combust |
| **RADIATION** (aura + crit) | **M** ×1.3 — radiant preheating dries & lights fuel ahead | **M** ×1.2, falls off with distance (inverse-square) | **S** ×1.6 crit = **thermal-shock spall**, ignores frost gate — *your anti-Slag tool* |
| **CONVECTION** (updraft pull) | **S** ×1.5 firestorm, self-sustaining spread | **S** strong pull/group — updraft lofts light bodies | **W** ×0.6, **cannot be pulled** (too massive) |

**FROST-ENCASED gate (all families, deep rooms):** two real phases before HP can drop.
1. **Sensible-heat phase** — a chilled "temperature" reading climbs to 0 °C. Cost scales with depth/how-cold (`= room_index`). *This is the part that grows with depth* (specific heat of ice ≈ 2.1 kJ/kg·K).
2. **Latent-heat plateau** — a *fixed* melt cost (fusion ≈ 334 kJ/kg) where the bar holds flat while ice→water. Visibly teaches the freezing-point plateau. Higher Kindle stage / sustained burn melts faster; a **Radiation crit skips both** (thermal shock).

**BEAST moisture gate:** mirrors the frost gate — boil off water (latent heat of *vaporisation* ≈ 2260 kJ/kg, the real reason wet fuel resists ignition) before burn takes hold. Clean symmetry: fusion gate (frost) ↔ vaporisation gate (beast) ↔ non-combustible (slag).

---

## 6. Progression feedback — the answer to bug 1

Progression is loud on-screen at **five cadences**, expressed in the game's own visual language (warmth = power), reusing existing Vfx/Main/HUD hooks so it needs almost no new chrome.

**PER-HIT.** Damage numbers are **mode-coloured** (Blaze orange, Sear white-gold, Draft pale cyan-white) via the existing `Vfx.float_text` colour arg. Super-effective hits pop **"IGNITE!" / "SHATTER!" / "FIRESTORM!"**, weak hits show a dull grey **"resist"** number — this *teaches the matrix by feel*, no spreadsheet to memorise. Each husk wears a thin **family glyph/outline** (a billboard the Enemy owns — *not* a modulate tint, which is already contended) so you read the matchup before you swing.

**PER-KILL.** A **Warmth bar** with **5 succession notches** sits under the hearts in the lean combat HUD, drawn in the existing GWI-meter style. Kindle streams in as a **"+heat"** float on every kill. The HUD's existing self-polling `_process` (which already reads the hero by group for the dash/riposte pips) reads `kindle`/`kindle_stage` — the player pushes nothing per frame.

**PER-BLOOM (the level-up moment — Hades-crisp).** On stage-up: hit-stop → `Main.zoom_punch(0.04)` → `Vfx.embers` + `Vfx.ring` burst → **`Main.set_grade(warm↑)` and the hero's scarf/light glow up one notch** (the single strongest "I am stronger" cue — the *screen itself warms*) → a toast **"PIONEER BLOOM +DMG"** → an Ember voice line → **the 3-choice boon card**. Reuse the *existing* `_on_ember_level_up` juice rather than adding a second celebration (see §7 collision).

**ON-DEMAND (character panel).** Bound to **KEY_C** — the `"character"` action is **already registered in `game_state.gd` and currently unhandled** (do *not* use Tab; Tab is the run-map). Opens an "Embergrowth" panel: current stage, active Mode, unlocked Kingdoms, and every derived stat (damage, crit%, max_hp, move, regen, lifesteal) with the **+delta broken out** (base + rescue buff + succession + boons). Directly answers "why am I stronger."

**META (village skin).** A **Soil/Humus meter** beside the Warmth meter and a Kingdom/Mode roster, so meta growth reads at home too. Rescuing a survivor plays a visible **school-unlock card** instead of the current silent invisible ember.

---

## 7. The science — every mechanic grounded, every liberty flagged

Each mechanic states the real ecology/biology/physics it rests on. **All errors the critiques found are corrected here.**

- **Heat delivery = the three transfer modes.** Conduction (contact), convection (moving fluid/air), radiation (EM across a gap, inverse-square falloff). Airtight; the spine of the whole element system.
- **Kindle = heat of combustion, not "10% trophic transfer."** *Fix:* the earlier Lindeman-10% framing was circular (an invented ×10 to make 10% fit) and mis-applied (a fire absorbing heat from dead matter is not a trophic transfer). We use **calorific value / heat of combustion** — the honest metric for energy released by burning fuel — varying by family (dry wood ≈ 18 MJ/kg; wet tissue far less; rock 0). More accurate *and* more fun.
- **Slag yields ~0 Kindle; you spend heat to crack it.** *Fix:* the 2nd law says the hot cat *loses* heat to cold rock, so harvesting warmth from non-combustible Slag was a perpetual-motion bug. Net-cost framing (Radiation/crit is the answer) resolves it.
- **Frost gate = sensible heat then latent heat.** *Fix:* latent heat of fusion is *constant* per mass; it can't scale with depth. Depth-cold scales the **sensible-heat** phase (warming ice toward 0 °C); the latent plateau is fixed. Teaches the freezing-point plateau correctly.
- **Beast moisture gate = latent heat of vaporisation.** *Fix:* wet fuel resists ignition chiefly because ~2260 kJ/kg must boil the water off first — not "high specific heat."
- **Succession = *secondary* succession.** *Fix:* a ruin retains soil/seed banks/organics, so it is secondary succession by definition. The meta Soil bar is real **humus accumulation** enabling faster establishment. *(Deliberate liberty: compressing five stages into one descent is a stated scale metaphor.)* Where we want a bare-substrate biome, we lean on **deglaciation exposing fresh substrate → primary succession** — which also makes "get hotter → advance succession" *causally real* (warming drives the stage sequence), not just a naming metaphor.
- **Flora "Photosynthesis" = LIGHT, not warmth.** *Fix:* photosynthesis is photon-driven, and the setting is a dark ruin, and a cat is a heterotroph. Regen only triggers **standing in the Ember's own light or a brazier** — scientifically valid (light-driven), on-theme (you carry the light that restarts the cycle), and a fun positioning mechanic. *(Lampshade: the Ember seeds photosynthetic lichen on the cat's coat — a real mutualism, cf. sloth-algae.)*
- **Fungi chain = parasitic/pathogenic fungi, not mycorrhizae.** *Fix:* mycorrhizae are *mutualist nutrient exchange with living plants* (wrong guild, and the "wood-wide-web" sharing narrative is contested in the 2023 literature). We use **Armillaria rhizomorphs** — real physical black bootlace networks that spread infection host-to-host through substrate (and Armillaria is literally Earth's largest organism) — for an honest, offensive, chaining network.
- **Fungi loot/soil = egestion, not "90% is all heat."** *Fix:* the consumption budget is C = Production + Respiration + Egestion. Only the *respiration* fraction is heat (→ GWI); a large share is **egesta/detritus** → routed to the **Fungi decomposer role and the Soil meta bar**. This is both accurate *and* wires the decomposer Kingdom into the core kill loop instead of leaving it a bolt-on.
- **Fauna Predatory Instinct = selective culling of weak prey.** Real. *Implementation fix:* a **flat bonus vs low-HP targets**, keeping the single per-swing crit roll intact (see §8) rather than moving the roll per-target and breaking the parry model.
- **Thermal vs Beast = heat *exhaustion*, not "enrage."** *Fix:* acute heat stress causes torpor/collapse, not a frenzy. It's a slow / damage-down debuff. *(If a cold-slow ever appears it is metabolic Arrhenius torpor — never "temperature is kinetic energy," which conflates microscopic random KE with bulk locomotion.)*
- **Thermal-shock spalling / fire-setting vs Slag.** Rapid uneven heating fractures brittle rock — real Paleolithic-to-Roman mining. *(Liberty footnoted: historical fire-setting is flame-contact + a water quench; assigning it purely to Radiation is a gameplay carve-up. The Thermal Shock duo restores the quench half.)*
- **Entangling Roots, not "allelopathy."** *Fix:* real allelopathy (juglone) chemically suppresses *plant* germination; it doesn't slow mobile animals. Root-slow is physical entanglement. *(If we want a true allelopathy boon, make it block husk regen / suppress reinforcements — exactly what juglone does.)*
- **Litho grounding (later).** Abiotic pioneer substrate + **chemolithotrophs** (iron/sulfur bacteria — among the few sun-independent ecosystems; the purest case is radiolysis-driven deep-rock microbes). Thermal mass = *stores/buffers heat via density & solidity*, not "high heat capacity" (water's specific heat far exceeds rock's).
- **"Canopy," not "Climax."** *Fix:* the Clementsian single-stable "climax community" is a superseded equilibrium concept; modern ecology treats mature communities as dynamic patch-mosaics. Renamed to avoid asserting dated theory.
- **Thermodynamic framing.** The frozen world is **low-free-energy / gradient-starved** (not "high-entropy"); the Ember is a concentrated low-entropy energy source, and life/warmth is the free energy (exergy) it spends to hold back a slide toward cold equilibrium (Schrödinger/Prigogine dissipative structures). NPP rises with temperature **only where water and nutrients allow** (co-limitation caveat).

**Flagged deliberate liberties:** (1) absorbing a husk's heat into *permanent* stat gains is a gamey metaphor — the Ember narrates it as such; (2) five succession stages in one descent is a scale metaphor; (3) assigning biological families to magical fire-husks is a stated conceit — the matrix still reasons from each family's real material properties.

---

## 8. Godot data model & implementation plan

Mapped to the real files. **Conventions honoured:** code-first nodes, `class_name` static namespaces (like `Vfx`/`Iso`), duck-typed cross-actor calls via groups + `has_method`, the persistent `Player.new()` owned by Main and reparented across layer swaps.

### 8.0 ⚠️ Reconcile the EXISTING progression system FIRST (the #1 trap)

All four feasibility reviews independently found a **live, fully-wired persistent XP→level system** the source proposals were blind to:
- `dungeon.gd:327` `GameState.add_xp(3 + room_index*2)` on every kill; `:309` `+30` for the Warden.
- `game_state.gd` `add_xp/level_for_xp/ember_level` + signals `xp_changed(total,level,into,span)`, `ember_level_up`.
- `player.gd:685` `_on_ember_level_up` → bumps `damage_mult`/`max_hp` **and already pops "LEVEL UP!" + shake + zoom_punch**.
- `main.gd:319` `apply_ember_level(GameState.ember_level)` re-applies cumulatively at run start.

Running Kindle *alongside* this **double-scales stats and fires two "LEVEL UP" bursts per threshold.** **Decision — repurpose, don't duplicate:**
1. **Repoint** the per-kill energy: `dungeon.gd` calls `player.gain_kindle(kcal)` instead of `GameState.add_xp(...)`.
2. **Retire** the persistent in-run scaling: remove `apply_ember_level` (main.gd:319) and the stat bump in `_on_ember_level_up` (player.gd), so `max_hp`/`damage_mult` are mutated in exactly **one** place (`_bloom()`).
3. **Reuse** the existing `_on_ember_level_up` juice (ring/embers/shake/zoom_punch/"LEVEL UP!") for the Bloom moment — rename the banner, keep the polish.
4. **Persistent leveling now flows from Soil** (GWI + rescues), never from a second per-kill counter.

### 8.1 New static class — `scripts/elements.gd`

```gdscript
class_name Elements extends RefCounted   # static namespace, like Vfx/Iso — NOT an autoload
```
- `MODES := ["conduction","radiation","convection"]`
- `MATRIX` : nested Dictionary `mode → family → {mult, burn, spread, pull, cracks}`
- `THRESHOLDS := [0, 8, 20, 40, 70]`, stage names, per-family calorific values, mode/kingdom colours (reuse `Palette`)
- static `resolve(mode, family, crit) -> Dictionary`
- **No `[autoload]` edit and no `--import` rescan needed** — `class_name` on a `RefCounted` resolves like `Vfx` does. *(The proposals' "new autoload + rescan" step is wrong for this pattern.)*

### 8.2 `player.gd` (Player) — run-scoped fields + hooks

- **Add:** `kindle: float`, `kindle_stage: int`, `mode: String`, `kingdoms: Array[String]`, `boons: Dictionary` (id→tier); make `CRIT_CHANCE` a **var** (base_damage/base_max_hp/max_hp are *already* vars).
- **Signals:** `kindle_changed(kindle, stage)`, `bloomed(stage)`, `boon_offer(cards)` (Main catches → HUD).
- **Methods:** `gain_kindle(kcal)` (accumulate; route respiration→GWI accumulator, egestion→Soil accumulator; `_check_bloom()`); `_bloom()` (stage++, flat stat step, run juice, emit `boon_offer`); `apply_boon(id)`; `set_mode(m)`.
- **`_do_attack_hit(k)`:** after the existing `en.take_damage(dmg, from_dir, crit)`, add one line — `en.apply_heat(mode, dmg, crit)` (consults `Elements`, applies burn/thermal-shock/spread, fires the RESONANCE/resist float). Fauna Predatory = **flat bonus** when `en.hp_frac` low (keep the single per-swing crit roll at line ~347 untouched — parry-forced-crit stays intact). Lifesteal via a **quiet** heal path (no ember/float spam per tick).
- **Finisher branch (`k==2`):** already loops radially — Convection flips `en.shove` to an inward pull + spreads burn; Conduction ignites all.
- **`_perfect_parry()`:** the empowered riposte also applies the active mode at ×2 ("the Ember flares").
- **`begin_run()`:** reset run-scoped fields; seed `kindle`/`kindle_stage` from `GameState.soil_value()`; set default mode from last-rescued. Keep `apply_buff()` as the shim for legacy rescue stat buffs.

### 8.3 `enemy.gd` (Enemy)

- **Add:** `family: String`, `frozen_temp: float`, `frozen_hp: float`, `moisture: float`, `_statuses: Dictionary` (burn/decay timers).
- **`configure(hp, speed, tex_key, family := "", frozen := 0)`** — default args so the two call sites (dungeon.gd:295, :306) don't break.
- **`apply_heat(mode, dmg, crit)`** — resolve gates (sensible→latent frost; moisture boil-off), then route to a **quiet internal damage path** (`_take_dot(n)`: subtract hp + `_flash` only — **no knockback, no per-tick float number**; ordinary hits keep the full `take_damage` juice).
- **Status tick** in `_physics_process` beside `_stun_t` (burn DoT, decay heal-block+chain, chill speed-mult). Reuse `stun`/`shove` primitives.
- **Status visuals:** a **dedicated overlay child Sprite2D** (additive) or the family **glyph billboard** — **do not** stack tints on `_sprite.modulate`, which `_flash`/`stun`/`_die` already fight over (cyan stun tint would collide with any chill tint).
- **Death payload:** bind the enemy into the death connection — `e.died.connect(_on_enemy_died.bind(e))` — so the Dungeon can read `e.family` (→ calorific value) and rot-boosted `loot_mult`. *(The Warden bounty lambda at dungeon.gd:309 is the precedent.)*

### 8.4 `dungeon.gd`

- `_spawn_enemies` / `_spawn_brute`: assign `family` (depth-weighted mix; deeper → more Slag/frost) and `frozen` by `room_index`.
- `_on_enemy_died(pos, e)`: `player.gain_kindle(Elements.kcal(e.family))`; roll drops with `e.loot_mult`. Fetch the player via `get_tree().get_first_node_in_group("player")` + `has_method` guard.

### 8.5 `main.gd`

- Replace the `for pillar in GameState.rescued: apply_buff` block (~299–302) with: legacy `apply_buff` (kept) **+** `player.kingdoms`/`modes` from `GameState`, **+** `player` seed from `GameState.soil_value()`. Remove `apply_ember_level` (line 319) per §8.0.
- Catch `player.boon_offer` → `get_tree().paused = true` → `hud.open_boon_cards(cards)` → un-pause on pick. On return home, bank the respiration/egestion accumulators → `GameState.add_gwi(...)` + Soil.

### 8.6 `hud.gd`

- **Warmth bar + 5 notches** in the combat skin (reuse `_trough_style()` draw; register inside `set_combat(on)`); combat-only `_process` **self-polls** `hero.get("kindle")` (same idiom as the dash pip — poll *vars*, not signals).
- **`open_boon_cards(cards)`** overlay: **must** be `MOUSE_FILTER_STOP` (copy the map-dim at hud.gd:962–976) so a card click doesn't fall through to a sword swing (attack = LMB); set the overlay + HUD `process_mode = PROCESS_MODE_WHEN_PAUSED`; **no cancel path**. *(This is genuinely new — the village build-menu is not reusable as-is: it's village-only, Esc-cancellable, and doesn't pause.)*
- **Mode-coloured `Vfx.float_text`**, family glyph billboards, RESONANCE/resist floats.
- **KEY_C character panel** — fill the already-registered-but-unhandled `"character"` action in `_input`.
- Village skin: Soil meter + Kingdom/Mode roster.

### 8.7 `game_state.gd`

- **Add:** `soil: float` (derived), `kingdoms_unlocked: Array`, `modes_unlocked: Array`; helper `soil_value() -> float`; signals `soil_changed`. Reframe `add_rescued` to also append the pillar's Kingdom + Mode (keep its dedup). **Save/load stub deferred to Phase 4.**

### 8.8 `survivor.gd`

- Keep `_buff_for_pillar` (legacy stat). Add `_unlocks_for_pillar` → `GameState.unlock_kingdom(k)` + `unlock_mode(m)`. Play a visible unlock card instead of the silent ember.

**GDScript 4.7 care (per DESIGN §6):** annotate Variant loop vars over untyped `get_nodes_in_group`/dict iterations; guard tweens with `is_instance_valid`.

---

## 9. Phased roadmap

Each phase is independently shippable and testable via `./play.sh` + the autoplay bot.

**Phase 0 — MVP: visible power that scales with depth (≈1–2 days). Fixes "weaker deep" + bug 1 alone.**
- Reconcile the existing XP system (§8.0): repoint `add_xp`→`gain_kindle`, retire duplicate scaling.
- `kindle`/`kindle_stage` on Player; Kindle on kill (flat per-kill for now, family calorific values deferred); 5 succession stages with flat stat steps.
- Warmth bar + notches in the combat HUD (self-poll); Bloom moment reusing existing `_on_ember_level_up` juice; **scarf glow + `set_grade` warm-up** per stage.
- GWI/Soil start-bonus in `begin_run`. Boon pick offers **flat stat sparks** only (+HP/+DMG/+crit) — no modes/kingdoms yet.
- *Ship gate: run now visibly scales with depth and shows it. This alone answers the felt bug.*

**Phase 1 — one Mode end-to-end (≈1 day).**
- `Elements` data class; `Enemy.family` + the **quiet burn ticker** + `apply_heat`; **Conduction/Blaze** row live; mode-coloured damage numbers; the real **boon-card overlay** (paused, MOUSE_FILTER_STOP); Conduction unlocked by rescuing the Smith. *Proves the whole pipeline.*

**Phase 2 — full matrix (≈2 days).**
- Radiation + Convection (aura, thermal-shock crit, updraft-pull finisher, dash draft trail); the **frost (sensible+latent) and moisture gates**; family-per-family Kindle calorific values; mode swap input; family glyph billboards + RESONANCE/resist floats.

**Phase 3 — Kingdoms + panel (≈2 days).**
- Tag survivors → unlock the three Kingdoms; Flora regen (in-light), Fauna predatory/lifesteal, Fungi rhizomorph chain + loot/soil; **KEY_C character panel**; Duo boons (Thermal Shock / Firestorm / Nutrient Bloom); rarity tiers + duplicate→upgrade.

**Phase 4 — meta & persistence (≈2–3 days).**
- `GameState.save()/load()` (ConfigFile → `user://`); Soil meta bar in the village; survivor-staffed workshops that spend Soil; GWI run-start scaling; the Litho fourth Kingdom as a Soil-threshold unlock; cold-room Kindle drain (behind the flag from §4.1).

**Phase 5 — capstone & balance (stretch).**
- Endosymbiosis weapon tree (husk cores permanently "engulfed" into the claws to level Modes — grounded in real endosymbiotic theory / kleptoplasty); Warden elemental interactions; a full balance pass verifying succession bonuses out-pace husk depth-scaling across a 6+ room run via the autoplay bot; per-family husk sprites (pure art debt — code falls back to `enemy_husk`, so sprites never gate systems).
