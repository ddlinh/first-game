<!--
  Story-driven development roadmap for REKINDLED.
  Derived from STORY_DESIGN.md (the narrative/play bible) and its Appendix B
  (Shipped -> Vision phase plan), reconciled with the live build, VILLAGE_DESIGN.md,
  PROGRESSION_DESIGN.md, CRITIQUE.md and QA_REPORT.md.
  This is the PATH; STORY_DESIGN is the destination. Each milestone is a shippable
  vertical slice, not a checklist of loose tasks.
-->

# REKINDLED — Development Roadmap (Story-Driven Milestones)

*How to build the game **STORY_DESIGN.md** describes, in shippable vertical slices.
Where STORY_DESIGN is the **destination** and its Appendix B is the phase switch-on,
this doc is the **ordered build plan**: what to make next, why, what story content it
authors, and what it honestly costs.*

*Last updated: 2026-08-14.*

---

## How to read this roadmap

Three sequencing principles decide the order — they come straight from the genre and
from the standing review of the build:

1. **Loop-first.** REKINDLED is a **roguelite**: procedural node-map descents, per-run
   Bloom/boon reset, persistent meta (village, GWI, Codex, Soil). Fun comes from a loop
   worth repeating + meta progression — **never** from hand-authored linear levels or a
   fixed cutscene plot. So we deepen the *loop*, not build *levels*.
2. **Story is emergent, delivered through the loop.** The "continuous story" is the
   thesis + the Ember's per-beat voice + the impact-ranked Codex + the worldline seal —
   authored as **fragments wired to mechanics** (each rescue, each Bloom, each GWI
   milestone), so the arc assembles itself the way a player plays. We still *write* that
   content; we just never gate it behind a linear script.
3. **Deepen before breadth.** STORY_DESIGN itself prices each new worldline at ≈ **×4**
   base content. One frontier + one Warden made *excellent* beats five shallow ones.

**Markers** (same convention as STORY_DESIGN): **SHIPPED** = in the build today ·
**⟢ VISION** = designed, not built · **⚑** = a flagged science/history liberty.

Each milestone below is one **vertical slice** — it ends in something a player can
actually play and feel, and something we can test.

---

## Baseline — what is already SHIPPED (Milestones 1–6 + EMBERGROWTH Phase 0)

The loop and its polish are done; the **vision systems layer is not**. Shipped today:

- **The core loop:** DESCEND at the Supply Gate → branching node map of locked arenas →
  Kindled Claws combat (6-HP cat, 3-hit combo, dash i-frames, guard/perfect-parry, ~2
  committed attackers) → **Kindle → Bloom** up 5 seral stages (flat step + pick-1-of-3
  boon, reset each descent) → **rescue one survivor** (banks instantly, +1 attunement) →
  **DEEPER / HOME** gates → bank-or-forfeit.
- **The village:** clearing + hearth, **building lifecycle** (Dormant → Blueprint →
  Operational → Upgraded), the **Farmer → Farm** earned chain, upgrade tiers + farm
  irrigation, **Carpenter's Workshop**, Manage menu (upgrade / relocate / demolish, 50%
  salvage), distance-based warmth, **GWI-as-weather**.
- **Meta & framing:** **Soil** seeds the starting stage, one generic **Warden**, the
  **Codex (K)** impact-ranked, **win state**, save/load, title + pause, procedural audio,
  the accessibility valve (assist difficulty, telegraph widening, UI scaling), **EN/VI
  localization**, and the readability/life pass (danger zones, enemy variety + bomber,
  wind/water shaders, chimney smoke).

**Not shipped (the whole ⟢ VISION layer this roadmap builds toward):** Heat Modes,
Kingdoms, Husk Families + the Mode×Family matrix, the four extra frontiers + their
craft-Wardens + the First Hearth, the World Map & expansion spectrum, the base-defense
pivot (Incursions / Long Night), the five-ending payoff, and co-op.

---

## The milestone line (M7 → M15), in order

> Each milestone: **Goal** (what the player newly feels) · **Scope** (systems) ·
> **Story authored** (the narrative half) · **Maps to** (source sections) ·
> **Done when** (acceptance) · **Cost / risk** (honest).

### M7 — "The Story in the Loop" *(author the narrative the shipped loop already earns — no new systems)*
- **Goal:** the current loop finally *speaks* — rescues, Blooms and the Warden land
  emotionally, not just mechanically. This is the cheapest, highest-payoff milestone and
  the one the standing review flags as most overdue.
- **Scope:** no new systems; content + one VFX pass. Wire the Ember's **per-beat voice**
  (first rescue of a craft, first Bloom into a new seral stage, GWI thresholds), the
  **per-succession-stage** flavour lines (Ash→Canopy, drafted in STORY_DESIGN §3), and
  the **Warden gutter** VFX + coda line.
- **Story authored:** full text for the **6 shipped Codex entries** (impact-ranked, each
  liberty flagged per Appendix A); **3–5 named survivors** with one lore line + a reactive
  rescue line each; the single **Warden's encounter coda**.
- **Maps to:** STORY_DESIGN §3 (Ember voice, the Warden), §7 (early-game beats),
  Appendix A (Codex honesty). Uses `lore.gd`, `survivor.gd`, `game_state.gd`.
- **Done when:** a first-hour playthrough hits ≥1 authored Ember line per beat, all 6
  Codex entries read as honest paragraphs, and the Warden **visibly guts out** (does not
  "die") on defeat.
- **Cost / risk:** **S.** The one real risk is the **gutter VFX** — it must sell
  *extinguish, not wound*, or the "bar = how much cold holds the shape" fiction reads as a
  plain health bar. Prototype the VFX here before it recurs on every craft-Warden.

### M8 — "A Town That's Yours" *(the player-expression / personalization layer)*
- **Goal:** ownership — the settlement reads as legibly **yours**, planned and dressed to
  taste, without breaking "the skyline is a readable résumé."
- **Scope:** **P7-MVP first** — building **rotation** + paintable **paths/roads**; then a
  small **GWI-neutral, craft-gated decoration** catalogue (Farmer → gardens/drying racks,
  Builder → carved posts/paved courts, Smith → lantern-stands; population → banners,
  benches). New free-placement prop system + `GameState.decor` save field.
- **Story authored:** short unlock lines ("the Builder shows the others how to raise a
  carved post") tying each cosmetic to the craft that remembered it.
- **Maps to:** **VILLAGE_DESIGN §6** (full spec) + **P7**, **ART_DIRECTION.md** (the
  Settlers-style visual target + cold↔warm grade), STORY_DESIGN §1 (village silhouette
  channel, the ⟢ VISION note). Uses `village.gd`, `game_state.gd`.
- **Done when:** the player can rotate buildings, lay a path, and place ≥5 craft-gated
  decorations that **add zero warmth/boons**; two saves with identical buildings look
  distinct; the functional silhouette still reads at a glance.
- **Cost / risk:** **S (MVP) → M (catalogue).** Keep every item GWI-neutral so it never
  touches balance. Optional stretch: soft **adjacency** bonuses (repairs V10 fully).

### M9 — "The Fire Gains a Character" *(Heat Mode #1: Blaze)*
- **Goal:** "my fire has a *character* I can carry and swap." The first real texture under
  the combo.
- **Scope:** one Heat Mode live — **Conduction / Blaze** (contact-burn DoT), swappable at
  Rest-Hearths; Mode-coloured damage numbers.
- **Story authored:** the Smith rescue now *teaches a way the fire moves*; one Ember line
  on first Mode acquisition.
- **Maps to:** STORY_DESIGN §7 (foreshadow), Appendix B **Phase 1**, PROGRESSION Phase 1.
- **Done when:** the player acquires Blaze from a rescue, swaps it at a Rest-Hearth, and
  sees Mode-tinted numbers; combat feel is re-textured with no regression to the 6-HP
  stakes.
- **Cost / risk:** **M.** First combat-system extension; get the swap UX clean — it recurs.

### M10 — "What It's Made Of" *(the full Mode × Family matrix)*
- **Goal:** "*how* it attacks and *what it's made of* are different questions." Combat gains
  a second, orthogonal axis.
- **Scope:** all **3 Heat Modes** (Blaze / Sear / Draft) + material **Families**
  (Bramble / Beast / Slag) + the **Frost-Encased** depth status, composed with the
  behaviour roster. The physically-honest gates: Bramble ignites, Beast is moisture-gated,
  Slag is heat-cracked, Frost-Encased thaws through a fixed latent-heat plateau.
- **Story authored:** family glyphs + one-line "read" hints surfaced diegetically; Codex
  notes on the physics (Appendix A rows go live as recovered entries).
- **Maps to:** STORY_DESIGN §2/§8 (matrix), **Appendix A** (the science), Appendix B
  **Phase 2**, PROGRESSION Phase 2.
- **Done when:** a Bramble Charger ignites on Blaze, a Slag Bomber must be cracked before
  it pops, a Frost-Encased Lobber must be thawed before its arc lands — each **reads on
  screen** (family glyph + rime overlay) without a tooltip (Pillar 1).
- **Cost / risk:** **L.** The biggest single combat build. Balance risk: Sear must
  *accelerate*, never *bypass*, the melt plateau, or the generalist edge collapses.

### M11 — "Choose an Identity" *(Kingdoms + decouple)*
- **Goal:** "I pick a run *identity*, not just a stat line — and I can mix a Mode with an
  off-element Kingdom."
- **Scope:** **Kingdoms** (Flora / Fauna / Fungi) as run-fixed boon-pool identities, biased
  by the matching rescue; **Mode and Kingdom decouple** after their rescues (cross-pairs
  like Sear+Fauna legal); the identity-panel UI.
- **Story authored:** each Kingdom's boon-draft flavour; the Ember naming your chosen
  identity.
- **Maps to:** STORY_DESIGN §2 (archetypes come alive), Appendix B **Phase 3**,
  PROGRESSION Phase 3.
- **Done when:** the six archetypes (§2) are *expressible* and read on sight; a soloist can
  reach Firestorm and Thermal Shock by sequencing Modes across Rest-Hearths.
- **Cost / risk:** **M.** Mostly data + UI on top of M10's matrix.

### M12 — "A Second Direction" *(biome parameter + first alternate frontier)*
- **Goal:** "the descent isn't the only door" — the same run can march **out** instead of
  only **down**.
- **Scope:** a `biome` field on the run map; the **Frostmarch Tundra** (Agriculture's
  buried fields, OUT) beside the Buried Warren — cheapest new mechanic first: **whiteout**
  (visibility shader + wind vector, reusing existing rooms). *(This is the first payment on
  the ×4 worldline multiplier — one frontier only.)*
- **Story authored:** the Tundra's testimony fragments; the **Keeper of the Empty Rows**
  craft-Warden coda (reusing M7's gutter VFX); the Agriculture worldline Ember line.
- **Maps to:** STORY_DESIGN **§5** (frontier roster) + **§4** (worldline seed), Appendix B
  frontier switch-on **Phase 2**. Uses `run_map.gd`, `dungeon.gd`.
- **Done when:** a run can choose the Tundra, whiteout reads on sight, and its craft-Warden
  relights Agriculture into the Codex.
- **Cost / risk:** **M–L.** New biome art + roster + one craft-Warden. Deliberately **one**
  frontier — resist shipping all five shallow.

### M13 — "Home Can Be Lost" *(World-Stakes v1 + Soil re-weight)*
- **Goal:** warmth stops being a one-way ratchet; neglect has a visible cost.
- **Scope:** **Cold Snap v1** — a neglected outer ring **frosts over and goes dormant**
  (no in-village combat, nothing destroyed, re-warmable); the **re-weighted Soil**
  (dominated by rescued-count + village diversity, GWI a minor term) so a merciful world
  starts later along the succession and a plundered world starts **raw and cold-skyline**.
- **Story authored:** the Ember's quiet line on a ring going dark; the Soil stage-title on
  descent ("you wake already in the thicket; your village bought you this ground").
- **Maps to:** STORY_DESIGN §3 (World-Stakes, staged), §1 (Soil model), Appendix B
  **Phase 4**, VILLAGE_DESIGN P6-adjacent, PROGRESSION Phase 4.
- **Done when:** over-expanding or neglecting a ring visibly rimes it dormant, and a cold
  plundered save demonstrably starts rawer than a warm diverse one.
- **Cost / risk:** **M.** **Design risk flagged:** a fully-reversible, no-loss dormancy may
  be *toothless*. Give the Cold Snap real teeth (re-warming costs materials, or the ring's
  quest progress stalls) so it creates genuine tension, not just an annoyance.

### M14 — "The Last Screen" *(the ending payoff — minimal first, then the five)*
- **Goal:** the 10 hours become legible on one final screen — the thesis paid off in gold.
- **Scope:** **ship the minimal ending first** — GWI 1.0 → a re-readable Ember epilogue
  keyed to the **already-shipped** axes (Diversity from buildings, Mercy from rescued +
  Codex, How-Deep from depth-record). **Then** layer the full **five rekindlings** + the
  world-seal epithet (folding dominant invention + Mode/Kingdom) as the vision systems land.
- **Story authored:** the five ending epilogues + world-seal epithet templates (drafted in
  STORY_DESIGN §10); the "starve the deep" win (§9) honoured as a real victory.
- **Maps to:** STORY_DESIGN **§9 / §10**, Appendix B **Phase 5**, PROGRESSION Phase 5.
- **Done when:** any GWI-1.0 save produces a re-readable epilogue that names its axes;
  later, the correct one of five seals is selected and reads without a tooltip.
- **Cost / risk:** **M (minimal) → L (five + seals).** The minimal ending de-risks the
  payoff so it isn't gated behind the most expensive content. **Balance risk:** verify
  "starve the deep" (win without fighting) isn't a degenerate dominant strategy.

### M15 — "Every Direction the Cold Took" *(remaining frontiers + the First Hearth)*
- **Goal:** the world becomes a place with directions — up the Spire, across the Wald,
  out onto the Coast — all converging on the First Hearth.
- **Scope:** the **Glaciated Spire** (altitude cold-drain, UP), the **Ashen Wald**
  (fire-spread, gated on Blaze), the **Drowned Coast** (thin ice / tidal leads), each with
  its craft-Warden; then the **First Hearth / First Warden** capstone every worldline
  converges on.
- **Story authored:** each frontier's testimony + craft-Warden coda; the First Warden's
  relight ("light the spark that was never struck"); worldline-gated ending tilts.
- **Maps to:** STORY_DESIGN §5 (roster) + §4 (worldlines) + §9 (confrontation), Appendix B
  frontier **Phases 2–5**.
- **Done when:** all four extra frontiers are playable and distinct on sight, and every
  worldline can reach the First Hearth by its own road.
- **Cost / risk:** **XL.** This is the ×4 multiplier paid in full — stage **one frontier
  per release**, never all at once.

---

## The three big pivots — separate tracks, flagged honestly

These are **not** milestones in the line above; each is a substantial, mostly-independent
system that can be scheduled when its value is worth its cost. STORY_DESIGN calls out all
three as large. Do **not** slip them in as "tuning knobs."

| Pivot | What it adds | Why it's a separate track | Home |
|---|---|---|---|
| **World Map & Expansion** | zoomed-out board; reclaim / federate / annex / cannibalise; warmth-stain map | new screen + community entity + expansion outcomes; **federate & annex are new systems** | STORY_DESIGN **§6** |
| **Base-defense pivot** | Husk Incursions, watchtower/villager combat, the **Long Night** | introduces **in-village combat** the builder screen has *no* systems for (enemy pathing, defend-loop UI, villager AI) | STORY_DESIGN §3 (stakes), Appendix B |
| **Co-op** | Sparkbearer fiction, gutter/Rekindle revive, private satchels, party scaling, shared village | **greenfield** — no netcode; couch-first first; inherits the whole vision layer | STORY_DESIGN **§11** |

**Recommended timing:** the base-defense pivot only *after* World-Stakes v1 (M13) proves
the economic threat; the World Map only *after* ≥2 frontiers exist to connect (post-M12);
co-op only *after* the solo vision layer (M9–M11) is stable, since co-op inherits it.

---

## Dependency order at a glance

```
  SHIPPED loop (M1–M6, Phase 0)
        │
        ├── M7  Story in the Loop ......... (content only; do first)
        ├── M8  A Town That's Yours ....... (village; parallel to M7/M9)
        │
        ▼
  M9  Blaze ──▶ M10 Mode×Family matrix ──▶ M11 Kingdoms      (combat spine, in order)
        │
        ▼
  M12 First alternate frontier (Tundra)
        │
        ▼
  M13 World-Stakes v1 + Soil re-weight
        │
        ▼
  M14 Endings (minimal ─▶ five)
        │
        ▼
  M15 Remaining frontiers + First Hearth
        │
        ▼
  Big pivots (World Map · Base-defense · Co-op) — scheduled by value, not sequence
```

**The single most important ordering rule:** M7 and M8 need **no** vision systems and pay
off immediately — start there. Then walk the combat spine (M9→M11) before spending on
breadth (M12, M15). Ship a **minimal ending (M14)** early enough that the emotional payoff
isn't hostage to the most expensive content.

---

## What this roadmap deliberately does NOT do

- **No hand-authored linear levels ("màn").** Runs stay procedural; content is room-types
  and frontier parameters, not fixed stages.
- **No fixed cutscene campaign.** The story is emergent — Ember voice, Codex, worldline
  seal — assembled by how the player plays.
- **No breadth before depth.** One excellent frontier and one honest Warden before five
  shallow ones; one minimal ending before five seals.

*Bottom line: build the **loop** deeper, wire the **story** into it as fragments, and ship
in **vertical slices** by phase. Follow the line M7 → M15, keep the three big pivots as
their own tracks, and every release is something a player can actually play and feel —
each one a step from the shipped loop toward the world STORY_DESIGN describes.*
