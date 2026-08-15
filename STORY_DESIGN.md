<!--
  Story / scenario / play-design bible for REKINDLED.
  Produced by a multi-lens design workflow (foundation designers -> early/mid/end
  scenario writers -> a science-first + design-coherence audit -> synthesis),
  grounded against the live build and reconciled with every audit finding.
  See VISION.md (pitch & pillars), GAME.md (shipped content), DESIGN.md
  (architecture), PROGRESSION_DESIGN.md (EMBERGROWTH), VILLAGE_DESIGN.md, CRITIQUE.md.
-->

# REKINDLED — Story, Scenarios & Branching History
### A narrative & play-design bible — early / mid / end game, play-styles, the histories players write, and co-op

*Written **before** implementation, to steer it. Where `VISION.md` sells the pitch, `GAME.md`
catalogues what ships, and `PROGRESSION_DESIGN.md` specs the systems, **this document describes
what a playthrough feels like** — the shapes a session takes, the choices that make one player's
world diverge from another's, and how solo and co-op each read across the whole arc.*

*Last updated: 2026-08-14.*

---

## How to read this document

REKINDLED already runs end-to-end; much of what it *promises* is documented but not yet built.
This bible describes the **destination** — so it is scrupulous about which parts you can play
today and which are the vision layer. Three markers carry that honesty on every page:

- **SHIPPED** — playable in the current build (EMBERGROWTH Phase 0, the village lifecycle, one
  Warden, rescue-attunements, bank-or-forfeit).
- **⟢ VISION** — documented in the design docs but **not yet built**. Described here as the goal,
  never as if it were live. [Appendix B](#appendix-b--shipped--vision-roadmap) is the path from one
  to the other.
- **⚑** — a deliberate scientific or historical **liberty**, flagged in the open per Pillar 2. The
  game teaches real history and real physics honestly, or it says nothing.

Beyond the early/mid/end arc, this edition also charts three world-scale layers: **Worldlines**
(§4 — how a single first invention cascades into a whole world), the **Run Environments / biomes**
you actually descend into (§5), and the **World Map & Expansion** layer that stitches them together (§6).

Every proposal here was passed through a **science-first accuracy audit** (the project's iron rule)
and a **design-coherence / buildability audit**; their corrections are baked in, not appended.

## The thesis this whole document serves

> **Civilisation lives in people and knowledge, not loot.**

One progress bar — **GWI**, the Global Warmth Index — carries player power, village growth, the
visual thaw, and the invention ladder at once (Pillar 3: *progress = rekindling*). Every scenario,
play-style, ending, and co-op rule below bends back toward that sentence, and toward its two
companions: **spectacle *with* substance** — a mechanic that needs a tooltip to read on screen isn't
finished (Pillar 1) — and **real knowledge, honestly used** (Pillar 2). Plus the three that keep the
loop alive: the loop must have **real stakes** (push-deeper risk vs bank-now), **people are the
reward**, and **one celebration per beat**.

## Contents

1. [The Branching Philosophy — How Choices Become History](#1-the-branching-philosophy--how-choices-become-history)
2. [Play-Style Archetypes](#2-play-style-archetypes)
3. [The Long Dark — Antagonist, World & Stakes](#3-the-long-dark--antagonist-world--stakes)
4. [Worldlines — How the First Choice Cascades](#4-worldlines--how-the-first-choice-cascades)
5. [Run Environments — The Cold Took Every Direction](#5-run-environments--the-cold-took-every-direction)
6. [The World Map & Expansion — Reclaim, Federate, or Annex](#6-the-world-map--expansion--reclaim-federate-or-annex)
7. [Early Game — The First Warm Night](#7-early-game--the-first-warm-night)
8. [Mid Game — The Loop Matures](#8-mid-game--the-loop-matures)
9. [End Game — Mastery & the Deepest Hearth](#9-end-game--mastery--the-deepest-hearth)
10. [The Endings & the Rekindled World](#10-the-endings--the-rekindled-world)
11. [Co-op — Two Embers, One Hearth](#11-co-op--two-embers-one-hearth)
- [Appendix A — Science-First Ledger](#appendix-a--science-first-ledger)
- [Appendix B — Shipped → Vision Roadmap](#appendix-b--shipped--vision-roadmap)
- [Appendix C — Spectacle & Readability Spec](#appendix-c--spectacle--readability-spec)
- [Appendix D — Accessibility, Open Tuning Knobs & Code Map](#appendix-d--accessibility-open-tuning-knobs--code-map)

---


## 1. The Branching Philosophy — How Choices Become History

Two players start the same cat, the same Ember, the same cold clearing — and ten hours later stand in front of two settlements that could not be mistaken for each other. That divergence is not scripted. It falls out of five recurring choices, each of which leaves a **visible mark** on the world: a different skyline, a different Codex state, a different difficulty seed, a different Ember voice. Nothing here is abstract book-keeping — the branch a player carves is meant to read off the screen without a tooltip, faithful to the thesis that **civilisation lives in people and knowledge, not loot.**

### The five choice axes

| Axis | The choice | How the world visibly diverges |
|---|---|---|
| **First survivor** | Which craft you free first: Smith → **Forge / Metallurgy**; Farmer → **Crop Bed / Agriculture**; Builder → **Cabin / Construction** (and Carpenter's / Builder) | The first building silhouette to rise, the first attunement re-applied each descent, and the Ember's first "recovered" monologue. *(The rescue's ⟢ Heat-Mode + Kingdom bias is the vision layer — see §2.)* |
| **Invention order** | Agriculture-first vs Metallurgy-first vs Construction-first | The **shape** of the settlement — fields, forges, or halls first — and which Codex entries flip from locked to unlocked, each stamped with the run that recovered it |
| **Aggression vs sustainability** | Push the **DEEPER** gate and hoard the satchel vs bank early and often | How much loot you actually keep vs **forfeit** in the dark, and therefore how fast your invention ladder advances — greed banks big or banks nothing |
| **Village shape** | Monoculture spam vs a diverse skyline; warmth-rush vs production chains | The skyline literally: a bristling one-note camp vs a varied town. Warmth climbs *faster on diversity*, because run-effects **cap at 3** and duplicate buildings give diminishing warmth |
| **Mercy vs plunder** | Rescue-completionist vs loot-speed clears | On-screen **population** (villagers wandering and working) and how far up the successional sequence your descents begin |

**The first invention seeds more than a skyline now — it seeds a whole *worldline*,** a cascade of biome, frontier, Warden and ending-gravity that §4 traces end to end. This section owns the *choice*; §4 owns the *cascade*.

### The Soil model — where your history lets you begin

Soil is the persistent meta value that seeds *which successional stage a descent starts on* — Ash → Pioneer → Herb → Thicket → Canopy. Because the long freeze scoured the surface down to bare mineral substrate, this is **primary succession**: "Ash" names the cold-scoured mineral surface itself (lichen-grade pioneers, not leftover organics). ⚑ Real primary succession runs over centuries; compressing it into a single descent is a deliberate liberty.

**Shipped today:** `soil = clamp(gwi*0.6 + rescued*0.05, 0, 1)`. The problem is honest and worth flagging: GWI and Soil become nearly the **same term**, so Soil can barely separate mercy from plunder, and it can never produce the interesting case — a world whose choices should read differently from its warmth.

**Proposed (a flagged change from shipped):** re-weight Soil so it is dominated by **rescued-count and village diversity**, with GWI only a minor term. Exact weights are TBD. The point is that the two things the thesis cares about — people and knowledge — drive where you begin, so:

- A **merciful, diverse** world genuinely starts *later along the successional sequence* (a higher seral stage), its history literally easier to re-enter.
- A **cold, plundered** world genuinely starts **raw** at Ash/Pioneer — and its skyline is genuinely cold, too. There is no "warm skyline but raw Soil" state: hoarding loot does not thaw the world, so a greedy world is low-warmth by construction, not a bookkeeping accident.

Seeding a run to stage N is never a punishment for skipping the climb: you receive the **flat stat steps of stages 1..N and a start-of-run boon draft** for the Blooms you leapt over — a warm start is a head start, never a boon deficit.

### The legibility channels — showing the player the history they're writing

Per Pillar 1 (spectacle *with* substance), every branch is surfaced on always-on channels that each read on screen:

- **The warmth grade (GWI, the master bar).** The loudest signal. As it rises, ambient light warms toward golden hour, the bonfire grows, dead trees leaf out. You *see* your aggregate history in the sky before reading a number — and monoculture spam visibly stalls it (cap-of-3, diminishing warmth), so the skyline itself teaches "diverse beats spam."
- **The village silhouette.** The building lifecycle (Dormant → Blueprint → Operational → Upgraded) plus the expandable clearing make the settlement a **readable résumé** — forges vs fields vs halls, dense vs sparse population, one ring vs three. The Forge-Lit Warren and the Green Terrace are told apart in a single glance from the hearth. ⟢ **VISION — the personalization layer.** A planned-and-decorated *player-expression* layer (town-planning: rotation, paths, soft adjacency; plus a **GWI-neutral, craft-gated decoration** catalogue) is designed to sit *on top of* this silhouette without distorting it: the functional résumé still reads at a glance, the player just makes the town legibly **theirs**, and because decorations are earned from recovered crafts, even the dressing stays an honest record. Full spec: `VILLAGE_DESIGN.md` §6.
- **The Codex (press K, "the Ember's memories").** The Codex is **displayed impact-ranked** — the same fixed, honest ordering for every player, most world-changing invention first, each liberty flagged. Recovery history is a **separate channel**: an entry's locked/unlocked state plus a "recovered on run N" stamp. What diverges between worlds is therefore *which entries are lit and when they were earned* — never the position in the list. Codex completeness is the knowledge-history the loot count never captures.
- **The Ember's milestone voice.** One reactive line per beat — first rescue of a craft, first Bloom into a new seral stage, crossing a warmth threshold — celebrating exactly **one thing per beat** and always honouring "carried, not looted." The branch is spoken, not just tallied.

*(Proposed additions to the same spirit: a one-line Ember stage-title on descent — e.g. "You wake already in the thicket; your village bought you this ground" — so the Soil seed reads as earned history rather than a silent buff; and an auto-generated world-epithet stamped on the title/pause screen, a single legible name for the history the player wrote.)*

### The three exemplar worlds, at a glance

Ten hours in, the choice axes above resolve into recognisable worlds. Each is dramatized in full — skyline, Codex state, difficulty seed, Ember voice — as a vignette in **§8 (Mid Game)**, their single narrative home; here they are only a legend for reading a hearth-view at a glance:

| World | Archetype / gravity | One-glance skyline tell |
|---|---|---|
| **The Forge-Lit Warren** | Bright Predator / plunder | Forges and smoke crowding a clearing — but the sky stays **cold**, Soil stays raw, descents keep starting at Ash/Pioneer |
| **The Green Terrace** | Slow Bloom / mercy | Crop terraces, a granary, leafed-out trees and a dozen working villagers — bright, mid-thaw, pastoral |
| **The Hearth-Keep** | Hearthkeeper / guardian | Tall arched cabins ringing an oversized bonfire, the clearing expanded outward two rings — high and *stable* warmth |

Same game, three skylines, three Codex states, three difficulty seeds, three Ember voices — each an honest record of what its player chose to remember. See §8 for the full dramatization and §4 for how each first invention cascades into its worldline.

## 2. Play-Style Archetypes

Six fantasies that **emerge from the systems**, not from flavour. Each is a real centre of gravity along the same tensions the branching axes describe: greedy↔sustainable, combat↔builder, loner↔guardian, monoculture↔generalist, mercy↔plunder.

> **⟢ VISION marker.** Heat **Modes** (Blaze / Sear / Draft), **Kingdoms** (Flora / Fauna / Fungi), **Husk Families** (Bramble / Beast / Slag + the Frost-Encased depth status), and the **Mode × Family** matrix are the *documented vision layer* — designed, not yet built. What is **shipped today** is the Kindled Claws combat kit, the Bloom/boon succession draft, the three rescue **attunements** (Bramble Ward +2 HP / Flora; Ember Fang +25% dmg / Thermal; Gale Step +25% spd / Wind), the village buildings, Soil, GWI, and the Codex. Each archetype below is split accordingly.

**Three rules govern every archetype below. They live here as their canonical home; the archetypes only point back to them.**

- **The decouple rule.** Heat **Modes swap mid-run and at Rest-Hearths**, while a **Kingdom is a boon-pool identity fixed for the run**, merely *biased* toward the survivor you rescued. After their respective rescues, Mode and Kingdom **decouple**, so cross-pairs like **Sear+Fauna** or **Draft+Flora** are entirely legal, deliberate builds — not accidents.
- **The attunement no-stack rule.** Attunements do **not** stack unbounded — one meaningful attunement per element with hard diminishing returns (or a small cap), mirroring the buildings' cap-of-3 discipline. Durability therefore comes from **Cabin → Construction +MaxHP tiers**, *not* from spamming +2 HP Bramble Wards. This preserves the **6-HP glass-cat** stakes: Construction raises the pool in a few deliberate tiers; there is never a 20-HP cat.
- **The cap-of-3 / diversity rule.** Run-effects **cap at 3** and duplicate buildings give diminishing warmth, so a diverse skyline genuinely beats monoculture spam. Every archetype's village math obeys this.

| Archetype | One-line fantasy | ⟢ Heat Mode | ⟢ Kingdom | Village spine (shipped) | Tension |
|---|---|---|---|---|---|
| **The Bright Predator** | Burn hottest, bank last | Sear | Fauna | Forge (Metallurgy) | Greedy / deep |
| **The Slow Bloom** | Never quite die | Draft | Flora | Crop Bed (Agriculture) | Sustainable |
| **The Hearthkeeper** | Bring everyone home | Sear | Flora | Cabin (Construction) | Cautious / mercy |
| **The Kindler** | Right fire, right foe | *swaps all* | *biased, swaps* | Carpenter's (Builder) | Adaptive |
| **The Rot-Reaper** | Feed the soil, feed the run | Draft | Fungi | mixed, Soil-fed | Speed / plunder |
| **The Archivist** | Warm the world by knowing it | *any* | Flora | widest, diverse | Bank-early |

### The Bright Predator — *the greedy glass cannon*

**Shipped today:** the aggressive read of the Kindled Claws kit — the 3-hit combo into the "Can Quet" 360 finisher, ~22% crits, dash i-frame rolls through husks, pounce. Lean on **one** Ember Fang (+25% dmg / Thermal) attunement and a Forge-heavy village for flat **+damage**, push Blooms for stat steps and offensive boons, always take the **DEEPER** gate, hoard the satchel, bank at the last possible hearth. This is **combat-greed**: you *duel the crowd* for the biggest banked satchel — where the Rot-Reaper plunders an economy and never fights a duel, the Predator's whole score is the fight itself. The crowd melts *if* you keep swinging, and one bad **red-danger-zone** read on 6 HP means you fall in the dark and **forfeit** the satchel.

**⟢ Vision:** Sear's crit-and-radiant-aura stacks with Fauna's bonus-damage-vs-low-HP, lifesteal, and pack-momentum speed-on-kill — Sear (a Radiation Mode) over Fauna (the Smith's Kingdom) is a **cross-pair**, legal once Mode and Kingdom decouple after the rescue (the decouple rule, §2 above). ⚑ "pack-momentum" is a behavioural gloss on predator ecology.

**On Wardens:** the Predator does **not** farm Wardens for GWI — a Warden gutters and goes out, it is never renewable loot or XP (the rule lives in §3). The Predator's warmth comes from **banked returns** on fast, deep runs; the fantasy is banking the biggest satchel of the deepest run, against the constant threat of forfeiting all of it.

### The Slow Bloom — *the attrition survivalist*

**Shipped today:** the never-quite-dies playstyle — the **Crop Bed → Agriculture** line lets you carry a **Provision heal-charge** into the run; you bank early and often, chip with the combo, and take defensive Bloom boons. **One** Bramble Ward (+2 HP / Flora) attunement rides along each descent — capped, not spammed (the no-stack rule, §2). Low burst ceiling, near-zero deaths.

**⟢ Vision:** Flora's regen-in-the-Ember's-light plus entangling roots and thorns, married to Draft's updraft finisher that pulls light husks in for safe AoE — Draft over Flora (the Builder's Kingdom) is a **cross-pair**, legal via the decouple. The real power is systemic: a merciful, diverse history feeds Soil, so every descent **begins further along the successional sequence** already — the Slow Bloom's strength is *starting warm*, not any single heroic run.

### The Hearthkeeper — *the guardian / rescue-completionist*

**Shipped today:** the **survival identity** — parry-forward defence on a **Cabin → Construction (+Max HP tier)** frame, so a measured, tier-earned HP pool and a healthy guard meter let you **stand on the front line and body-block** for a trailing survivor. The perfect-parry stagger and guaranteed-crit riposte exist to *hold ground*, not to duel for loot. Prioritise **Rescue** rooms; every freed survivor banks the instant you free them and grants **one** permanent attunement. You clear at the survivor's pace, not yours — here **mercy is protection**, a shield thrown over the people you carry. Its durability is the **Construction +MaxHP tiers** of §2's no-stack rule, never stacked wards: a measured pool, still a glass cat at base.

**⟢ Vision:** Sear+Flora — the Builder's *native* Radiation+Flora pairing (no decouple needed), with thorns punishing anything that reaches the person behind you. The Mode still swaps at Rest-Hearths if a room demands it.

### The Kindler — *the adaptive synergist*

**Shipped today:** the reader — dash i-frames, perfect parry, pounce, and a boon draft re-planned each Bloom to suit the room in front of you. A **Carpenter's → Builder** village speeds the building unlocks the full kit depends on. Even without the Mode layer, the Kindler is the player who treats *every* telegraph as a puzzle.

**⟢ Vision:** the only archetype that lives in the **Mode × Family matrix**, swapping Heat Modes mid-run and at Rest-Hearths to counter what a husk is *made of* (family) independently of how it *attacks* (behaviour — these compose):

- **Blaze** to ignite a **Bramble** husk's dry fuel — a Bramble Charger telegraphs its rush and catches fire on contact.
- **Draft** to boil off a **Beast** husk's moisture past its damp gate, then **Firestorm** (Draft feeds the oxygen) to self-spread.
- **Slag** husks are near-inert rock (~0 kindle): you *spend* heat to crack them — a Slag Bomber must be **cracked before it can be popped**.
- **Sear** to **accelerate** a **Frost-Encased** husk's sensible-heat warm-up (grounded: ice and water absorb infrared strongly) — a Frost-Encased Lobber must be thawed before its arc lands. Sear does **not** skip the fixed latent-heat melt plateau; against Slag and armour its edge is *delivering heat without surviving melee contact* (⚑ a metaphor, not "penetrating armour").

Because Sear only accelerates and never bypasses the melt plateau, the Kindler keeps a genuine Frost-Encased edge through **multi-mode Thermal-Shock chains**. Thermal Shock here is a **fire-only rapid-heating fracture**: a steep thermal gradient driven into a cold, brittle solid → differential expansion → crack. ⚑ This is real, but classic thermal shock usually needs a rapid **cool/quench** the fire-only kit lacks; the honest historical anchor is **fire-setting** — heat the rock, then quench it with water to split it (Paleolithic to Roman mining). Never "heat then cool" for the fire kit. ⚑ The three heat-transfer modes are real physics; treating them as swappable *loadouts* is the game liberty.

### The Rot-Reaper — *the plunder economist*

**Shipped today:** the fast **economy** — clear rooms quickly (leaning on **one** Gale Step +25% spd / Wind attunement, capped per §2), turn kills into materials, ship materials home, watch Soil climb, start the next descent higher. You are farming an economy, **not fighting duels** — where the Bright Predator's score is the fight, the Rot-Reaper's score is throughput: fast clears, kills → materials/Soil, next run higher.

**⟢ Vision:** a Fungi monoculture — afflicted husks **drop more materials and feed Soil**, and the Armillaria **rhizomorph** chain spreads decay husk-to-husk. Draft+Fungi is the Farmer's **native** Convection+Fungi pairing, so no decouple is needed, though the Mode still swaps for a stubborn family. ⚑ Decomposers returning nutrients to soil is real ecology; compressing it into a currency is the liberty. The thesis is the built-in counter-pressure: under the proposed Soil model, warmth rewards **rescued people and village diversity**, not raw loot, so a pure plunderer's world stays **cold and its Soil plateaus** until they also free survivors — the loop refuses to let plunder alone win.

### The Archivist — *the civilisation architect*

**Shipped today:** the **completion identity** — the village *is* the build. You **bank early** to keep the invention ladder advancing, build **wide** (cap-of-3 discipline, §2), recover inventions deliberately, and read **GWI** — the ambient thaw, the growing bonfire, trees leafing out — as the score. **Combat is maintenance**, a chore between rooms rather than the point; here **mercy is the Codex** — every survivor is another entry lit, and you track your own progress through the Codex's **recovered-on-run stamps** while the list stays impact-ranked for everyone. The Archivist **ends nearest GWI 1.0** of any style.

**⟢ Vision:** **any Heat Mode as a safe default** — the Archivist has no signature element and no need for one; whatever the room needs, since the fight is maintenance, not identity. Ends closest to **GWI 1.0 and the epilogue**, with the fullest Codex and the most legible, storybook village of any style — the clearest proof that warmth is a record of what you chose to remember, not what you carried out.


---

## 3. The Long Dark — Antagonist, World & Stakes

*The enemy is entropy — the slow, lawful loss of every gradient the living once maintained — and forgetting is entropy's form in a mind. Nothing here gives the cold a plan. It gives the cold a face only where the fiction already earns one: at the hearths people let go out.*

### The Antagonist Arc — Entropy That Learns a Shape

The Long Dark cannot escalate the way a villain does, because it wants nothing. What escalates instead is **your ability to read it** — the game teaches you to see the same indifferent process at three depths of legibility.

**Early — the cold is ambient and mute.** On the first descents there is no antagonist on screen at all, and that is the point. Husks lunge without malice; they are hollow, not hostile — the fire's leftovers, running down the way anything unheated runs down. The threat is *conditions*: the light is blue, the floors are rimed, the Ember gutters if the cat stands too long in the dark. The only "voice" the cold has is absence — rooms that were homes, now silent. *Reads on screen:* no health bar, no telegraph — just a falling light meter and breath fogging in still air. This is entropy as most people meet it: not an attack, just a temperature.

**Mid — the ruins begin to remember who they were, and so does the cold.** As the run branches deeper, environmental fragments stop being scenery and start being *testimony* — the tally-marks stopping at forty-one, the loom with the shuttle still in it, the ledger that goes grain → firewood → only names. The husks here wear the *shape of their trade*: a courier-husk still walks its route, a weaver-husk still works an empty loom until you disturb it. The cold did not author this. It has merely preserved a groove worn by repetition — a pattern that outlived its meaning. **This is the honest core of "the cold learned a shape":** a Warden is not a mind the dark grew. It is a **metastable, self-perpetuating decayed state — a configuration kept from re-ordering by the absence of free-energy throughput** — a loop of behaviour so deeply grooved that it kept turning after the person inside it went out. ⚑ *Real entropy has no memory; we borrow the true idea that some decayed states are self-perpetuating and hard to reverse for lack of energy flow, and dramatize it as "the cold learned to hold this posture" (full physics → App A).*

**End — the first hearth ever let die.** The deepest ruin is the *oldest* one: the place where, before there was a village to forget, the first tended fire went cold one untended night. Everything above is an echo of that first lapse. Reaching it is the game admitting what the antagonist always was — not a boss at the bottom of a dungeon, but **the origin of neglect**, the first hand that failed to pass the flame.

### The Wardens — a Face That Gutters, Never Bleeds

A Warden is the cold given the *silhouette of a lost profession*. It is emphatically not a beast: **strike it and it does not bleed — it gutters, dims, and goes out like a flame starved of air.** Its bar is not blood; it is *how much cold is holding the shape together*. You do not kill it; you **relight what it was guarding**, and the shape has no more reason to stand. *Reads on screen:* every hit dims it a shade rather than reddening it; at zero it collapses into a warm, settling glow, not a corpse.

**Behaviour × family compose here too (⟢ VISION).** A Warden is a *behaviour* (the boss posture in the roster: Husk / Charger / Lobber / Bomber / Warden) and — in the VISION material layer — also made of *something* (Bramble / Beast / Slag, with Frost-Encased as a depth status). The axes are orthogonal and stack: a **Bramble Charger** *ignites* on a Blaze/Conduction contact; a **Slag Bomber** must be **cracked** with heat before its kamikaze ring can be popped; a **Frost-Encased Lobber** must be **thawed** before its arced blast lands. A craft-Warden inherits the same grammar — a Slag-bodied smith-Warden must be heat-cracked before its shape yields — so boss fights read as the enemy grammar taken to scale, never a new ruleset.

> **What ships vs. what is VISION.** The SHIPPED game has **one generic Warden** — a Warden-room in the **Buried Warren** (the Construction descent, §5) that recurs as ordinary roguelite structure; its VISION identity is **The Unfinished Arch**. The **four craft-Wardens** and **the First Warden** below, along with Husk Families and deep biomes, are the documented ⟢ **VISION** layer, not in the build.

**One-time craft-Wardens (⟢ VISION).** The vision layer places one Warden per frontier, each the guardian of a specific forgotten craft — a face for the antagonist without a personality, and the invention-ladder made legible *as combat*. The roster grows to four craft-Wardens plus the deepest terminus:

| Warden (⟢ VISION) | Frontier / biome (§5) | Craft it guards (Codex) | The honest fragment at its feet |
|---|---|---|---|
| **The Unfinished Arch** | the **Buried Warren** — DOWN *(the shipped descent)* | Construction | A cradle rocked to a stop under a sagging keystone |
| **The Cold-Struck Smith** | the **Glaciated Spire** — UP, the summit forge | Metallurgy | A workshop of half-made tools |
| **The Keeper of the Empty Rows** | the **Frostmarch Tundra** — OUT, the buried fields | Agriculture | Seed jars scraped empty; a granary of frost |
| **The Last Wright** | the **Ashen Wald** — ACROSS | Woodcraft *(folded into the Carpenter's/Builder craft — not a standalone invention line)* | A frame-house half-raised, its joints never pegged |
| **The First Warden** | the **First Hearth** — the deepest terminus every worldline converges on | *the keeping of fire itself* | A hearth laid with kindling, waiting for a spark that never came |

The **Drowned Coast** (the frozen sea) hosts **no** craft-Warden — it is the shared expansion highway (§6); an optional Salt-Keeper→Preservation there is ⟢ VISION.

These craft-Wardens are **one-time relights**, not renewable prey. **You never farm a Warden for loot or XP** — when it falls it goes out for good, and there is no second one behind it. The First Warden is not guarding someone else's craft; it guards *the act of remembering itself*, fights faintly like all the others at once, and when it falls it does not die — it **finally warms** and stops needing to stand watch. **GWI rises from banked returns — rescues, recovered crafts, warmed rings — never from bleeding a boss.**

This keeps every Warden science-first: each is a self-perpetuating decayed state, and the counter to each is **energy plus information restored** — heat plus the recovered craft, the real-world answer to local entropy. No villain. No plan.

### World-Stakes — Staged, Honestly

Warmth today only ever rises, so home is never at stake. The fix must stay on-thesis: the cold cannot *plot a raid*, but entropy absolutely reclaims any gradient you stop maintaining. So stakes come in **two clearly separated builds**, and the gap between them is stated, not hidden.

**v1 — the Cold Snap (a purely ECONOMIC threat, buildable now).** An expanded clearing is warmth held against a gradient; hold it carelessly and the gradient wins back a ring. If GWI in an outer ring falls below its threshold — from over-expanding, letting a hearth go unfed, or spending too many days in the deep without tending home — the outermost ring **frosts over and goes dormant**: its buildings idle, its crops still, its attunements greyed until you re-warm it. **No husks enter the village; there is no in-village combat.** Nothing is destroyed — it is *forgotten*, and can be remembered again. This runs entirely on the existing warmth thresholds and the distance-based warmth from the construction overhaul, which makes **kept hearths / braziers** genuine load-bearing infrastructure. *Reads on screen:* the outer ring visibly rimes over, colour drains to blue-grey, and its building icons dim to dormant. ⚑ *The reclamation compresses slow thermodynamic and social decay into a between-runs event; the direction (untended order decays) is honest, the speed is theatrical.* (Exact Cold-Snap thresholds are **TBD**.)

**Later phase — Incursions + the Long Night (a base-defense PIVOT; flag the build cost).** Husk Incursions, watchtower/villager combat, and the Long Night are a **substantial later phase**, not a tuning knob on v1. They introduce **in-village combat** — a genre the current builder/farm screen has *none* of: enemy pathing into the clearing, palisade funnelling, watchtower early-warning, villager combatants and their AI, a defend-loop UI. **That is a real build cost and it is called out here, not buried.** When it exists:

- **Husk Incursions.** Accumulated "unclosed depth" occasionally lets a small band of husks surface into the cold outer rings between runs. Palisade (slows/funnels) and watchtower (early warning + a villager who fends them off *if you built a village diverse enough to spare one*) earn their keep. Incursions threaten **dormancy, not death** — an unchecked incursion frosts a ring, it does not raze it. **People are the reward, never the ante:** losing survivors is never on this table.
- **The Long Night.** A rare, telegraphed, opt-into-able tent-pole: the world tilts furthest from its warmth and for one long night *everything* costs more heat to keep lit — the game's periodic exam in diversity. Survive it and the world rebounds warmer; fail and you lose ground you can re-warm. *Reads on screen:* the sky deepens past normal night, every lit ring's glow shrinks, and the heat-drain clock ticks visibly faster. **Mechanism (grounded):** a seasonal, axial-tilt deepening of the cold gradient — the literal longest night. ⚑ *The astronomical cycle is compressed to a game-legible cadence; the physics (tilt → a longest night → a deeper cold gradient) is real.* (Incursion cadence and Long Night cadence are **TBD**.)

All of it is entropy honestly staged: neglect, over-reach, and the periodic deepening of the gradient — none of which requires the cold to *want* anything.

### Other Hearths — Carried Hand to Hand

The thesis is *warmth is carried hand to hand, or it is lost.* A world with only one hearth quietly contradicts that. So the other-hearths layer should exist — as **faint signals and guttering fires, not rival factions.** This beat is the seed the whole expansion layer grows from (§6).

**Where they appear (and the build cost).** Two surfaces, both **new spawn work to flag**: (1) a dedicated **"guttering hearth" run-map node type** — a new node the branching descent map can roll, sitting alongside Combat/Treasure/Rescue/Rest-Hearth/Boss, with its own room content and outcome hooks; and (2) faint **between-run signals** in the village sky — a distant ember-glow on the horizon that hints a hearth is failing out there, seeding the *feeling* that you are not the only spark without breaking the lone-Ember fiction. Both are new content pipelines (node type + its authored rooms; the between-run signal system and its art), not free reskins. *Reads on screen:* a special node icon that flickers weakly on the map, and, in the village, a low pulse of orange far off in the dark.

**Relight vs cannibalise — the ruling.** Reaching a guttering hearth is a clean mercy-vs-pragmatism axis with no correct answer:

- **Relight it** — spend your own heat and materials to rekindle a stranger's fire. Little loot; you gain a *survivor or two who remember a craft you did not*, and total warmth (GWI) rises faster because two hands now pass the flame instead of one. This is real fire-spread — honest, on-thesis, no apology owed.
- **Cannibalise it** — take its banked materials for a large, immediate windfall and let the fire go out. This **forfeits those survivors' rescue**: they are **never killed on-screen — people are not the ante** — but their people and knowledge are **permanently removed from the world**, and GWI takes a lasting dent. The Ember notes, quietly, that this is exactly how the Long Dark spreads: one hearth's warmth taken to feed another's, until nothing is tended everywhere at once. The weight of the choice is **what you chose not to carry.**

Keep it lone-hearth in *feeling* — you are still the last living Ember — but let the map prove the last Ember's whole job is to make itself **no longer the last.** (This choice feeds the mercy axis of the endings — see §10.)

### The Ember's Voice — From Coaxing a Cat to a World Remembered

The Ember is the only continuous character, and its tone is a **slow thaw of its own.**

- **Early (Ash / first descents):** *coaxing a frightened animal* — short, warm, protective, a little anxious, over-explaining because it is teaching. *"Easy. Stay near me. The dark is only cold — and cold, we can answer."*
- **Mid:** *fond and wry*, a teacher watching the student outpace the lesson, beginning to ask *you* to remember. *"You know this one now. Show me."*
- **End:** it speaks *as a memory the world is keeping* rather than a voice keeping the world — calm, plural, almost gone in the best way, because it no longer carries the flame alone. *"I am nearly out. That is not sad. It means the fire is somewhere else now — in them, in you. Where it was always meant to be."*

**Per-succession-stage flavour lines.** The long freeze scoured the surface down to **bare mineral substrate**, so this is **primary succession** — "Ash" names the cold-scoured mineral rock itself, not leftover organics, which is why lichen pioneers come *first*. One line as each Bloom crosses into a later seral stage — the Ember narrating the world reading itself back to life, and reading *your* growth in the same breath:

- **Ash** — *"Bare mineral rock, scoured to nothing. Nothing has grown here — not yet, not ever. But nothing grows anywhere until something dares to be first."*
- **Pioneer** — *"There — lichen on the stone, the boldest life there is. It asks for almost nothing, and it begins everything."*
- **Herb** — *"Green, and soft enough to bruise. Fragile things are how a world tells you it has stopped dying."*
- **Thicket** — *"It tangles now, reaches, competes. Crowding is a kind of confidence. Let it fight for the light."*
- **Canopy** — *"Look up. It closes over us like a held breath let go. This is what patience becomes: shade for something that comes after."*

⚑ *Primary succession over bare rock — cold-scoured mineral surface → pioneer lichens → herbs → shrub thicket → closed canopy — is real ecology compressed to a single run's arc as a deliberate metaphor for how fast warmth returns once someone tends it (full ecology → App A).*


---

## 4. Worldlines — How the First Choice Cascades

> ⟢ **VISION.** Everything here is the destination layer, not shipped. What ships today is one frontier — the **Buried Warren** descent and its single Warden (the Unfinished Arch) — plus the invention-identity *reskin* the doc has flagged as too cosmetic. This section is the fix: it promotes the **first invention** from a cosmetic axis into a **worldline seed** — a single early choice that biases the *frontier you play in*, the *tech you reach earliest*, the *politics of how warmth spreads*, and the *objective you fall toward*. The ending grid (§10) still selects the ending *family*; the worldline colours the *world, the road, and the cheapest objective* underneath the epithet, so two "Rekindled Commons" saves are materially different games, not one cutscene with two stamps. ⚑ Compressing a civilisation's tech and settlement history into a ~10-hour run is a deliberate liberty; ⚑ the fiction that recovering *one* craft "opens" a frontier is game-logic, not technological determinism.

### The Worldline Seed — one choice, four cascades

The first craft you recover is not a head start on a shared tree — it is a **fork in which tree grows.** Each seed leans, at once: **which frontier is cheapest to open** (the biome roster is owned by §5; the worldline chooses the *nearest door*), **which tech spine grows earliest**, **which expansion style is cheapest** (the reclaim→federate→annex→cannibalise spectrum is owned by §6; the worldline picks which end your tools *natively favour*), and **which ending family you drift toward** if you never fight your gravity. All of it is a *leaning* — never a lock. (Soil model, "warm start = head start, not a boon deficit," and the input choice-axes → §1.)

| First invention (seed) | Frontier it opens first ⟢ | Tech spine it grows earliest | Expansion it favours | Ending family it drifts toward | Archetype |
|---|---|---|---|---|---|
| **Agriculture** (Farmer → Crop Bed) | **OUT — the Frostmarch Tundra**: frostbound fields & the buried rows | seed-vault → granary → irrigation → surplus | **Federate** — feed a guttering hearth, it allies as an equal | **The Slow Dawn** (III) · Diverse × Mercy × Starved | Slow Bloom |
| **Metallurgy** (Smith → Forge) | **UP — the Glaciated Spire**: summit forge / the forge-deep | ore → steel → hull-plate → deep-breaching tools | **Bank-fast & hold narrow** — a warm, monoculture empire | **The Long Watch** (II) · Monoculture × Plunder × Confronted | Bright Predator |
| **Construction** (Builder → Cabin) — **SHIPPED baseline** | **DOWN — the Buried Warren**: collapsed vaults *(shipped)* | shoring → load-bearing arch → palisade / watchtower | **Reclaim & hold** — a defensible chain of relit rings | **Rekindled Commons — Hearth-Keep** (I) · Diverse × Mercy × Confronted | Hearthkeeper |
| **Builder / Carpenter** (Carpenter's) | **ACROSS — home = the Ashen Wald**; tours the rest cheapest | woodcraft → fast cross-spine unlocks | **Flexible** — any skin, cheapest tour | **The Kept Flame** (V) · Codex 100% | Kindler |

The cascade is *organic*, not arbitrary: agriculture reads the soil, so its cheapest door is **out** to the Frostmarch Tundra where fields and seed-vaults lie; metallurgy forges hull-plate and cutting tools, so it **climbs up** the Glaciated Spire to the summit forge-deep; construction raises shoring and arches, so it **descends** the Buried Warren (the shipped road); woodcraft frames and joins, so its home is the **Ashen Wald**, from which it tours every other frontier for the least cost. The **Drowned Coast** — the frozen sea — belongs to no seed; it is the shared expansion highway everyone crosses (§6). And which craft-Warden you relight **first** falls out of your seed: the **Keeper of the Empty Rows** (agriculture), the **Cold-Struck Smith** (metallurgy), the **Unfinished Arch** (construction, *shipped*), the **Last Wright** (Ashen Wald / Woodcraft) — the rest toured in the order the branching map allows. Every worldline eventually converges on the same deepest terminus, **the First Hearth / the First Warden** (⟢ VISION capstone).

### Build cost, honestly

Each new seed is not one asset — it is a **content multiplier.** A single worldline authored to full depth is roughly *frontier art + tech-spine + late-capability set + ending coda* ≈ **base authored content ×4.** ⚑ That is the real reason this is VISION, not a weekend reskin. The one place where the multiplier is already partly paid is the Construction spine: its **palisade / watchtower** rung *is* the flagged base-defense pivot (see §3 stakes, §5 frontier, App B roadmap) — it inherits that pivot's full cost and is **not a cheap unlock.** Staging of the remaining three seeds is deferred to the PROGRESSION phases in App B, one frontier at a time behind the shipped Warren.

### Why they play like different games by mid-run

By hour four the worldlines do not share a screen. An **agriculture** save is running a *surface* loop — tundra whiteouts and frostbound rows, feeding guttering farm-communities, watching population climb — on a granary economy the smith never sees. A **metallurgy** save is *climbing the Spire*, banking depth behind tools it forges to breach higher into the summit forge. A **construction** save is *descending the Buried Warren*, raising a shored ring-chain and holding it against the cold. Different biome, enemy mix, traversal, economy — and different *cheapest* capabilities: construction-first **natively** raises the palisade/watchtower infrastructure the late base-defense phase wants; metallurgy-first forges deep-breaching tools **earliest**; agriculture-first hits population surplus **cheapest**, the only build that can out-warm the deep without ever fighting it. But the seed biases which late game is *cheapest* — **every capability and every ending stays reachable by paying a fork's cost.** Leanings, not rails.

### The three mid-game forks

A seed is **gravity, not rails.** Three forks let you fulfil your worldline's default — or pay to bend it — and each is a real *content* fork, not a slider:

- **Fork A — Confront vs Starve the Deep.** *Confront:* you drive to the terminus and relight the Wardens as boss encounters — the deep-biome arenas *are* your late content. *Starve:* you never descend to fight; you pour runs into surface federation and surplus until the deepest ruin is **found already warm and empty** (the starve-the-deep road, its full ruling → §9). Different content sets — boss arenas vs a diplomacy-and-surplus loop — not two difficulties of one fight. Agriculture starves natively; metallurgy can barely afford to; construction usually confronts to relight-and-hold.
- **Fork B — Federate vs Annex vs Cannibalise** (the political fork; §6 owns the spectrum's mechanics). *Federate:* relit hearths stay **independent equals** — a spreading web of many warm points (the **federate skin of Commons**). *Annex:* you draw them into one central blaze, **The One Great Hearth** — hub-and-spoke, one dense GWI pool, **still merciful and populous** (the **centralised skin of Commons**, never conquest, never plunder). *Cannibalise:* you **strip** a guttering hearth for a windfall and let it go out — never PvP, **people are never the ante and are never killed on screen**, but their knowledge leaves the world and GWI dents; this is the mercy-axis dark turn toward The Hollow Warmth (IV). The fork decides the **political geometry of the final map** — the substance the old "reskin" endings lacked.
- **Fork C — Specialise vs Diversify.** *Specialise:* single-craft mastery reaches the deepest gate fastest, but a monoculture skyline Cold-Snaps first. *Diversify:* a broad village climbs slower to any one depth but hits a higher warmth ceiling and survives the world-stakes exam. (This is §2's cap-of-3 / diversity discipline, surfaced as an ending axis.)

### The Branch Table — first invention × key fork → a distinct destination

Each row is a different world, a different *final objective* (all cashing the **one** master GWI bar — never a parallel currency), and a different worldline coda. Ending & Ember beats live at their home in **§10**; below, only the genuinely-new worldline coda.

| Worldline + fork | Late-game world (reads on screen) | **Final objective** (how you win) | Ending → §10 · worldline coda |
|---|---|---|---|
| **Agriculture** · Federate · **Starve** | a spreading federation of green hearths across the Frostmarch Tundra; the buried rows warm and unguarded | **Race breadth to 1.0** — federate and feed until surplus out-warms the deep; the terminus **gutters unmet, offscreen** | **The Slow Dawn (III)** · *coda:* the fields warmed before the fight ever came. |
| **Metallurgy** · Monoculture · Bank-fast · **Confront** | one warm, narrow forge-empire climbing the Glaciated Spire; the Pack pacing its walls | **Reach & force** — forge deep-breaching tools, climb, relight the First Warden **by arms** | **The Long Watch (II)** · *coda:* a fire of one log — mind the second night. |
| **Construction** · Reclaim/Federate · **Confront** | a fortified ring-chain descending the Buried Warren, watchtowers lit, held through a Long Night | **Hold & relight** — raise the network, survive the world-stakes, relight the First Hearth face to face | **Rekindled Commons — Hearth-Keep (I)** · *coda:* the stone remembers the shape of shelter. |
| **Any** · **Cannibalise** · Starve | a single blazing point in a cold-edged waste; outer rings frosted from untended Cold-Snaps; a Codex of gaps | **Scrape 1.0 hollow** — cannibalise guttering hearths for windfall, tend nothing | **The Hollow Warmth (IV)** · *coda:* the dark only moved somewhere you cannot see it. |
| **Builder/Carpenter** · Diversify · tour-all | every frontier visited from the Ashen Wald outward, every craft-Warden's knowledge relit; the storybook diverse town | **Complete the record** — recover **every** craft across every frontier (Codex 100%) | **The Kept Flame (V)** · *coda:* the list of what a mind learned to do, and troubled to teach. |

**The metallurgy gravity — a road, not a punishment.** The Predator's default *deliberately* bends cautionary: monoculture + bank-fast + confront is the cheap grain of a metallurgy seed, and it pours into **The Long Watch (II)** — a warm, narrow, victorious empire whose Ember names its **known second-night cost** aloud (→ §10), never scolds. The Long Watch is reached by that monoculture-plunder-confront road, **not by annex** — annex stays a merciful, centralised skin of Commons. The *worked subversion* is the escape: a metallurgy save that **diversifies + shows mercy + federates** pays out of its gravity into Commons.

**Leanings, not rails (a worked subversion).** An **agriculture** seed that instead **specialises grain + banks fast + confronts** becomes a *farmer-empire* — granaries feeding a town that marches deep to fight — and lands in **The Long Watch** by a road no smith walked, seeded by grain not iron. The seed sets the cheap path; the forks let you pay to defy it. The first choice makes a *default* game; mastery is bending it.

### How it stays legible — and honest to the thesis

Every worldline **reads on screen** without a tooltip (Pillar 1): the **frontier art** (white tundra vs glaciated spire vs the Warren's vaults vs the Ashen Wald) names the seed; the **skyline** names the tech spine (granaries vs forge-stacks vs shored arches); a between-runs **warmth-map** shows your politics as *shape* — a web of equal lights (federate), one bright hub (annex / The One Great Hearth), or a single point in a cold field (cannibalise). One early **Ember line** names the seed aloud, and the §10 world-seal folds it into the epithet. The invention **Codex stays fixed, impact-ranked, and honest** (App A/D) — expansion never adds deletable entries or invented dialects; federate/annex/cannibalise differences live only in the map's geometry, population, and which real entries a world relit.

This model leans on the Soil re-weighting (→ §1) and the Mode/Kingdom decouple (→ §2), and its starve-the-deep win rests on §9. And it stays on-thesis: entropy is the **only** antagonist — every worldline fights only cold and husks, never people; **annex is not conquest** (a community joins yours, its craft banks); the on-thesis dark shape is **cannibalise**, warmth taken from one hearth to feed another *exactly as the Long Dark spreads* — and even there people are never killed, only *un-remembered*. The Warden gutters, never bleeds. Whichever worldline you seed, the last screen pays off one sentence in a different world: **civilisation lives in people and knowledge, not loot — and warmth is carried, hand to hand, or it is lost.**


---

## 5. Run Environments — The Cold Took Every Direction

> **SHIPPED vs ⟢ VISION — read once.** Everything you can play today runs in **one** environment: the **Buried Warren**, a descent through a sunken ruin at the Supply Gate (branching node-map, locked arenas, rimed blue stone). That single direction — *always down* — is the monotony this section fixes. The **Warren is the SHIPPED baseline**; the four frontiers after it, the material **Families** (Bramble/Beast/Slag) that colour their enemy mixes, and the **Frost-Encased** *depth status* layered over them, are **⟢ VISION** — designed here, not built. Nothing below is live yet.

The frozen world is not one shaft straight down. Entropy took no single road; it took **every gradient at once** — the city sank, the sea froze mid-swell, the mountain vanished under advancing ice, the forest died standing, the plain locked to permafrost. So a run should be able to go **down, out, or up**, and each destination should *play* differently, not merely reskin. The unifying rule keeps it honest: **the cold is the ambient condition and heat is the player's scarce gift.** That is why a "lava level" or fire-realm is rejected outright ⚑ — ambient heat as a hazard inverts the whole spine; a **frozen sea, a glaciated peak, a permafrost steppe, an ash-killed forest** are all *states a cold, forgetting world actually produces*, so they are fair game and their liberties are only ever about **compressed timescale**, never about a warm world pretending to be cold.

### The frontier roster at a glance

| Frontier | Direction | Reads on screen | Signature mechanic(s) | Dominant family + depth status | Craft-Warden → Codex | Worldline (opens first) | Status |
|---|---|---|---|---|---|---|---|
| **The Buried Warren** | **down** — sunken city | cracked rimed stone, tight ember-lit dark | cave-ins reshape danger zones; the Ember *is* your vision radius | **Slag** (masonry, rubble) + **Frost-Encased** deep — ⟢ *family typing is VISION; shipped foes are behaviour-only* | **The Unfinished Arch** → Construction | **Construction-first** | **SHIPPED** |
| **The Frostmarch Tundra** | **out** — buried fields | flat white steppe, horizontal snow, a lost beacon | **whiteout squalls** cut sight & shorten telegraphs; **permafrost dig** to reach caches | **Beast** (frozen megafauna) + **Bramble** (sedge) | **The Keeper of the Empty Rows** → Agriculture | **Agriculture-first** | ⟢ VISION |
| **The Glaciated Spire** | **up** — smothered peak | blue serac walls, thin pale sky, vertical arenas | **altitude cold-drain** (climb warm-point to warm-point — relight old braziers / set your own — or gutter); **icefall** as moving hazard | **Slag** (ore/rock) + **Frost-Encased** status (glacier) | **The Cold-Struck Smith** → Metallurgy | **Metallurgy-first** | ⟢ VISION |
| **The Ashen Wald** | **across** — dead forest | skeletal black trees, drifting ash, unlit coal beds | **fire-spread terrain** — burns propagate across the whole biome (a double edge) | **Bramble** (standing dead wood) | **The Last Wright** → Woodcraft (Carpenter's/Builder) | shared (leans Builder) | ⟢ VISION |
| **The Drowned Coast** | **out** — frozen sea | a fracturing ice-sheet, frozen swells, far hearth-glimmers | **thin ice — keep moving**; **tidal cracks / opening leads** flex the floes, opening/closing routes | **Beast** (marine) + **Frost-Encased** status (sea-ice) | *(no craft-Warden — the expansion corridor)* | shared (expansion highway) | ⟢ VISION |

### 1. The Buried Warren — down into the sunken city *(SHIPPED baseline)*

**Fiction.** The city did not fall to a foe; it **sank under its own cold-shattered weight** — beams gave, vaults filled with ash and rime, and a warren of half-collapsed streets pressed down into the dark, one untended winter at a time. **Direction:** down. **Look:** the shipped palette — cracked stone tilted toward camera, everything rimed blue, one warm point in the frame.

**Mechanics.** *Structural collapse:* the ceilings are unstable, so **Bomber** husks and stress-cracks drop rubble that **paints new danger zones mid-fight** — the arena rewrites itself, and you route around debris rather than through it. *Lightless dark:* the Ember is your **vision radius**; stray too far from it and the read shrinks, and standing idle in the black lets cold seep faster. **Enemy mix (behaviour × family):** **Slag** dominates — masonry, permafrost-rock, near-inert (~0 Kindle) — so a **Slag Bomber must be cracked before its kamikaze ring pops** and a **Slag Charger** self-stuns on a wall. The deepest streets add the **Frost-Encased** depth status. *(The **family** layer here — the Slag/Frost-Encased typing — is ⟢ VISION; the **shipped** Warren foes are **behaviour-only**, their family arriving with the Mode×Family matrix.)* **Rescue → Codex:** the **Builder/mason**, guarded by **The Unfinished Arch** (a cradle rocked to a stop under a sagging keystone) — teaches **Construction** (the load-bearing arch, stored labour). **Worldline & expansion:** **Construction-first** opens the Warren deepest and earliest; its scattered survivors are **vault-dwellers** huddled in the last sound rooms — the natural *reclaim → federate* population for a Hearth-Keep worldline. ⚑ *A city compressing centuries of subsidence into a walkable ruin is theatrical; the direction (untended structure decays) is honest.*

### 2. The Frostmarch Tundra — out across the buried fields *(⟢ VISION)*

**Fiction.** The croplands the cold took: topsoil frozen to iron, seed-jars scraped empty, a granary of frost. **Direction:** out, across open steppe. **Look:** a flat white horizon, **horizontal snow**, the guidance-beacon reduced to a thin thread you *must* follow because the land gives no other landmark.

**Mechanics.** *Whiteout squalls:* blizzards roll through on a loop and **collapse visibility**, so danger-zone telegraphs read late and the beacon becomes survival gear — the Ember's light is a lantern in a wall of white. *Permafrost dig:* caches, seed-vaults, and some survivors are **locked under rime you clear**, a short exposed race against the cold while you're stationary. **Enemy mix:** **Beast** — the tundra *preserves* damp carcasses (mammoth-husks are honest: megafauna genuinely surface from permafrost), so a **Beast Charger** is **moisture-gated**, you **boil off its water before it will ignite** (Draft, or two heat sources). Frozen **sedge-mats** seed light **Bramble Lobbers**. **Rescue → Codex:** the **Farmer**, guarded by **The Keeper of the Empty Rows** at a frost-granary — teaches **Agriculture** (surplus, the seed-vault). ⚑ *A permafrost seed-vault is real (Svalbard); reanimating frozen fauna as husks is the fiction; blizzard cadence is compressed.* ⚑ *Tundra **surface** megafauna read as **damp-not-deep-frozen** — thawed at the surface and waterlogged, so they resolve as plain **moisture-gated Beast** (boil off the water). A truly permafrost-locked carcass would be **Frost-Encased first**, passing a sensible-plus-latent melt before the Beast moisture gate ever applies (calorimetry, App A).* **Worldline & expansion:** **Agriculture-first** opens the Frostmarch first; its people are **herder-nomads** whose bands you can **federate** into a Green-Terrace commons — mobile communities, honest to a plain.

### 3. The Glaciated Spire — up into the smothered peak *(⟢ VISION)*

**Fiction.** A mountain mining town **smothered by an advancing glacier** — ore still in the veins, the high smelter choked with ice. (This realises the doc's "choked forge-deep" as a **frozen summit forge**, so the metallurgy road climbs instead of only descending.) **Direction:** up. **Look:** blue serac walls, falling ice, a thin pale sky — the only frontier where you can look *down* on the cloud and *up* at nothing warm.

**Mechanics.** *Altitude cold-drain:* the higher you ascend, the **faster the Ember cools** (⚑ honest: colder and thinner air aloft, less oxygen to feed a flame), so you **climb warm-point to warm-point — old braziers you relight and fires the Ember sets itself, every warm point on the face heat you supplied** — dawdling between them guts the run, giving the Spire a relentless upward tempo no other frontier has. *Icefall traversal:* vertical arenas with **falling seracs as moving danger zones**. **Enemy mix:** **Slag** (ore, rock — spend heat to crack it) plus **Frost-Encased** glacier husks; a **Slag Lobber** rains rock from above, a **Frost-Encased Charger** must be **thawed before its rush lands**. **Rescue → Codex:** the **Smith**, guarded by **The Cold-Struck Smith** — a **Slag-bodied Warden you heat-crack** — teaches **Metallurgy**. The Spire is the home of the **fire-setting** anchor (heat rock at the face to shatter it — Paleolithic-to-Roman mining), so **Thermal-Shock chains** read most naturally here. **Worldline & expansion:** **Metallurgy-first** opens the Spire; its survivors are **fastness holdouts** in watchtowers — a population that biases the harder, colder *annex*-leaning worldline (a Forge-Lit reach).

### 4. The Ashen Wald — across the dead forest *(⟢ VISION)*

**Fiction.** A forest that **died standing** — killed by the long cold and buried in old ash, now a field of dry black skeletons that never rotted because nothing warm was left to rot them. **Direction:** out/across. **Look:** skeletal black trunks, **drifting ash**, **dark coal beds / unlit seams underfoot** — inert exposed fuel, nothing burning until you burn it.

**Mechanics.** *Fire-spread terrain:* the entire biome is **Bramble fuel**, so your **Blaze burns propagate husk-to-husk *and across the scenery*** — the showcase where **Firestorm** truly sings, and every flame here is unambiguously **your own**, lit by Blaze, never an ambient seam-fire. It is a **double edge**: fire clears a pack, then keeps running toward your own route or a **trailing survivor**, forcing you to fight *and manage the burn* (never as damage to the survivor — **people are never the ante** — but as a lane you must keep open for them). *Ash-drift low-vision* adds a softer whiteout. **Enemy mix:** near-pure **Bramble** — a **Bramble Charger** ignites on contact and carries fire into whatever it charged past; a **Bramble Bomber** goes fuel-air. **Rescue → Codex:** the **woodwright/charcoal-burner**, guarded by **The Last Wright** — teaches **Woodcraft** (timber frames, charcoal), feeding the **Carpenter's/Builder** line (honest impact link: charcoal is the fuel a forge needs). ⚑ *Dry standing dead wood and exposed coal are genuinely flammable; the ash and the seams are old, pre-freeze, and inert — nothing burns until the Ember lights it, because an actively burning forest would contradict a cold world.* **Worldline & expansion:** a **shared** frontier leaning Builder; its people are **charcoal-camps** — small, portable, easily **federated or cannibalised** (the Wald is where the cannibalise temptation bites, since its fuel is *right there*).

### 5. The Drowned Coast — out onto the frozen sea *(⟢ VISION)*

**Fiction.** The sea froze mid-swell over a drowned shore; **other hearths glimmer across the ice**, which is why this is the game's **expansion highway** rather than a craft-vault. **Direction:** out. **Look:** a **fracturing ice-sheet under your paws**, a horizon of frozen waves, a far orange pulse or two in the dark — proof you are not the last spark.

**Mechanics.** *Thin ice — keep moving:* stand still and the floe **cracks**; a Charger's rush or a Bomber **shatters the sheet and drops you into freezing water** (heavy cold-damage and satchel-forfeit risk — ⚑ real cold-water immersion is far deadlier than we let it be; softened for play). *Tidal flex — cracks and leads:* the tide still heaves under the sheet on a timer, so the floes **flex, crack open into leads, and grind shut again**, **opening and closing routes** rather than flooding them, so you read the ice as carefully as the enemy (⚑ sea ice genuinely opens **leads** under tidal stress — no surface flood needed; only the timer is compressed). **Enemy mix:** **Beast** (waterlogged marine husks, moisture-gated) and **Frost-Encased** sea-ice husks; a **Beast Lobber** throws from open water. **Rescue → Codex:** the coast has **no craft-Warden** — its beat is the **guttering-hearth community node** across the ice (relight → federate → annex → cannibalise), the single richest **expansion** surface in the game. (A **Salt-Keeper** survivor may teach **Preservation** here — ⟢ VISION, flagged — since preserved provisions are what make crossing the sea to other communities possible.) **Worldline & expansion:** **shared**, and the spine of the political axis — a **Rekindled Commons** federates the coastal hearths, a **Hollow Warmth** cannibalises them.

### The First Hearth — where every road ends

All frontiers eventually point to the **oldest ruin, the deepest hearth** — the first tended fire ever let go cold. It is not a sixth biome so much as the **terminus every worldline converges on** (the doc's **First Warden**, guardian of *remembering itself*). ⟢ VISION, capstone-tier; owned jointly with the end-game and worldline sections. Its only environmental note here: it is **direction-agnostic** — the last stairs down are *reached from whichever frontier your worldline climbed*, so the road there is legible as your history.

### Why these, and not others

Each frontier is a **thermodynamic state a cold world genuinely reaches** — subsidence, sea-ice, glaciation, standing die-off, permafrost — so the fiction stays science-first with liberties only on *timescale*. The explicit rejections keep the spine intact: **no volcanic/lava biome** (ambient heat inverts the thesis ⚑), **no "corrupted"/magical realm** (the antagonist is entropy, not a dark power), and **no biome whose "boss" is a rival army** — every enemy is the cold wearing a husk's shape, and **people are never the ante**. Variety comes from *how the cold took the place* and *what that costs a fire*, never from importing a warmer world.

### Buildable staging order

1. **Now (SHIPPED):** the Buried Warren descent — the baseline, untouched.
2. **Stage 1 — biome parameter + Frostmarch Tundra.** Teach the node-map a `biome` field; ship the cheapest new mechanic first — **whiteout** (a visibility shader + wind vector reusing existing rooms). Lowest engineering cost, biggest "it's not just down" payoff.
3. **Stage 2 — Glaciated Spire.** **Altitude cold-drain** reuses the Ember-cool meter concept; adds vertical arena layout.
4. **Stage 3 — Ashen Wald.** **Fire-spread terrain** depends on **Heat Modes/Blaze** (PROGRESSION Phase 1–2), so gate it there; it is the reward that makes Blaze feel essential.
5. **Stage 4 — Drowned Coast.** Most systems-heavy (dynamic floor states, tide timer) and the **expansion** corridor, so land it alongside the expansion axis (Phase 4).
6. **Terminus — the First Hearth** with the Phase 5 capstone.

Each stage is additive, each frontier reads its cold on screen in one glance, and — the point — **no two runs have to walk the same direction into the dark again.**


---

## 6. The World Map & Expansion — Reclaim, Federate, or Annex

*Design owner: expansion/conquest. This answers the client's second ask — is there conquering, and what does it cost — and reconciles it with the thesis before designing anything. Everything here is **⟢ VISION**: it grows the §3 "Other Hearths" seed (the guttering-hearth node + the between-run sky-signal) into a whole map layer, and none of it ships today. It adds **no** new ending: §10 owns the five rekindlings, and expansion only skins one of them.*

### The honest answer first — literal conquest would betray the spine

Let me be a critic before a designer. REKINDLED's antagonist is **entropy**; its creed is **people and knowledge, not loot**; its bosses **gutter, they do not bleed**; and its iron rule is **people are never the ante.** Bolt classic 4X military conquest onto that — march on a rival survivor-town, kill its defenders, seize its stores and territory — and every one of those load-bearing commitments snaps at once. You would have smuggled in a *second* antagonist (rival humans) that the fiction spent chapters insisting does not exist; you would have made people lootable; and you would have pointed the player's whole arsenal at the very thing the game says is the point. **So no: there is no PvP military conquest of other survivors in REKINDLED, and there should not be.** Anyone who wants that game wants a different game, and grafting it on would gut this one.

But "no armies" is not "no expansion." A world with exactly one hearth quietly contradicts *warmth is carried hand to hand.* The real question is not *whether* you take other lands but *how warmth spreads across them* — and hiding in that question is a spiky, consequential axis where the aggressive, centralising, empire-building fantasy is fully expressible, and its enemy is still only ever the cold.

### The World Map — warmth as a stain spreading across the white (⟢ VISION)

Above the village clearing sits a second, zoomed-out board: **the World Map**, the frozen continent the cold took in every direction. Your hearth is a single golden bloom in a field of white. Scattered across the frontier roster of §5 — the Buried Warren, the Drowned Coast, the Glaciated Spire, the Ashen Wald, the Frostmarch Tundra — are **other hearths**, each rendered by its warmth-state and readable at a glance:

- a **dark** ruin — a community already gone out (a pure relight/rescue target);
- a **guttering** ember — a community failing *now* (the §3 mercy-vs-pragmatism beat);
- a **steady** independent fire — a community still alive and warm on its own (something you cannot simply "rescue").

Reaching any of them is a **run into that frontier** (mechanics owned by §5). The World Map is the *between-run strategic layer* where you choose which frontier to press, then watch warmth answer: as you succeed, GWI spreads outward from your hearth as a literal **thawing stain** eating the white — snow greying to wet earth, a corridor of thaw linking your fire to the next. *(Reads on screen: the map is mostly white; every warmth you hold is colour, and the shape of your civilisation is the shape of the stain.)* Which frontier opens *first* is biased by your first recovered invention — the worldline cascade of §4 — so your expansion story begins where your knowledge story began.

### The Expansion Spectrum — one axis, four honest verbs (⟢ VISION)

When you reach a community, you choose how its warmth joins the world. One choice axis, no correct answer, running from most generous to darkest:

| Verb | What it is | You gain | It costs | Reads on screen | Pushes the ending toward |
|---|---|---|---|---|---|
| **RECLAIM** / relight | Rekindle a **dead or guttering** hearth; rescue its people | Survivors who know a craft you may not; GWI rises faster (two hands pass the flame) | Your own heat + materials to relight; little loot | A dark ruin flares to gold; new named villagers walk in | Mercy → **The Rekindled Commons** (§10) |
| **FEDERATE** / ally | Ally with a **living, independent** hearth; they stay their own | Knowledge trade; real Codex entries relit in *both* places; their **frontier opens** to your runs; one more living voice on the map | You don't absorb their people or population; slower to centralise | Two fires linked by a warm corridor, both still lit | Plural → the **FEDERATE skin** of Commons I (§10) |
| **ANNEX** / absorb | Out-warm them until folding in is their people's own rational choice; take people **and** territory under one great hearth | Efficient, centralised warmth; their population + territory count as *yours*; a bigger single bar | Fewer living communities on the map — one hub where there were many; nothing murdered | Their fire is subsumed into your growing central blaze; one hearth where there were two | Centralised → the **ANNEX skin** of Commons I (§10) |
| **CANNIBALISE** | Strip their warmth + materials; let the fire go out | A large immediate windfall | **Forfeits their rescue**; fewer relit entries; a lasting GWI dent; spreads the Long Dark | The distant ember you drained darkens and goes out; the stain *recedes* there | Mercy axis → **The Hollow Warmth** (IV) (§10) |

Two of these already live in the doc's DNA (RECLAIM = §3 "relight"; CANNIBALISE = §3 "cannibalise"). The two new middle verbs are where the political game lives — and the sharpest of them is **ANNEX**, because it is the one that finally lets the client have their "conquering," honestly.

**FEDERATE vs ANNEX is a choice about the plurality of living communities, not a body count and never a knowledge tax.** A federated ally keeps their own hearth, their own people, their own steady light on the map — one more voice tending the flame beside you. Annexation folds them into your one great hearth: you gain their population and territory as raw, efficient warmth, but the map now holds a single hub where it held a web of independent fires. Crucially, **knowledge itself is never at stake either way.** The invention Codex is fixed, impact-ranked, and honest (App A/D); no community owns a private "dialect" of it and none can delete an entry from it. What the choice moves is *how many living communities carry the flame* and *how the recovery channel reads*: a web of allied fires relights real entries in many places at once; one great hearth relights loudly from a single point. If you want per-community texture, it lives on a clearly-**separate, flagged community-lore surface** — never the invention ledger. A map of many allied fires lives in many voices; one great Hearth lives loudly in one. Both are warm. They are not the same civilisation, and the last screen will say so.

### A conquest playstyle, with no one murdered (⟢ VISION)

The aggressive-expansion fantasy, made expressible without a single killed survivor:

- **You fight the cold to *reach* them.** The campaign against a proud, still-warm community is the brutal run across its hostile frontier to arrive at its gates at all — you are always fighting husks and the gradient, never its people.
- **You pressure them politically and economically, not militarily.** Your leverage is your **warmth-grid**: your surplus, your Codex completeness, the reach of your thaw. A guttering community federates readily. A proud, self-sufficient one resists — and **annexing it requires out-warming it** so thoroughly that folding into your hearth becomes its people's own rational choice to survive. You win the "war" by making your fire the obvious one to gather around, not by breaking theirs.
- **Annexation is a political/economic verb — centralised, never plunder.** You extend your warmth-network until their independent hearth is redundant, then absorb it. **People are never the ante** — even CANNIBALISE never shows a survivor killed on screen; it shows a *fire* going out and a rescue *not taken.* The weight of the dark choices is always **what you chose not to carry**, never a corpse.

So the empire-builder gets a real power fantasy — a centralising, efficient Hearth-empire spreading its single great blaze across the map — and pays for it in the plurality of living communities, one hub instead of a web, not in blood and not in lost knowledge. The antagonist stays entropy the whole way down.

### How expansion skins the ending — a political shape, not a new world (⟢ VISION)

Expansion adds **no sixth ending and no sixth axis.** It re-skins the ending §10 already owns: **The Rekindled Commons (I)** — warm, merciful, populous — has always been the destination of the mercy road, and the Spectrum simply gives that one world its **political shape**, surfaced on the world-seal:

- **Federate-dominant + mercy → the FEDERATE skin of Commons I.** Ending I read as its most plural self: a **ring of independent allied hearths** on the horizon, a web of many lights, plural precisely because its members were never absorbed. The seal names the alliance; the epilogue names the entries a web of hands relit.
- **Annex-dominant + mercy → the ANNEX skin of Commons I: "The One Great Hearth."** The same Commons, **centralised** — one enormous merciful blaze where a federation shows many, still warm and still populous, just gathered to a single point. The Ember's read is ambivalent, not damning: *"You gathered every fire into one. It is warm. It is also the only way left to be warm here."* This is a centralised tilt of Commons I, **never** "Plunder"; the militant monoculture ending, **The Long Watch (II)**, is a different road entirely (monoculture × bank-fast × confront — §10), not reachable by annexing anyone.
- **Cannibalise-dominant → the mercy axis bends toward The Hollow Warmth (IV)** (§10), sharpened. The stain is thin and receding at the edges; the hearths you drained are dark holes in the map — the cautionary win with a map to prove it: *you moved the dark somewhere you cannot see it.*

Like every §10 axis, this **spotlights** one political shape of a world reachable from any save; it never gates which endings exist. It just means two players who both hit GWI 1.0 with full towns can stand before a **plural federation** and a **single great hearth** and read the difference without a tooltip.

### Ties — worldline, frontiers, co-op (⟢ VISION)

- **Worldline (§4).** Your first invention biases which frontier opens first, so your **first community encounter — and the first Spectrum choice you make on it** — sets your expansion tone early and seeds the political skin of your ending, exactly as the §4 cascade seeds the rest.
- **Frontiers (§5).** Communities sit roughly one-per-frontier across the §5 roster; **FEDERATE is literally how a locked frontier opens** to your runs — expansion is wired into which content you can even reach.
- **Co-op (§11).** Spectrum choices are **shared moral beats**, resolved by §11's existing consensus rules: RECLAIM banks party-wide the instant the hearth relights; **FEDERATE / ANNEX / CANNIBALISE need consensus** (like the DEEPER gate and the guttering-hearth vote), so two players argue the political shape of the world they share. The world stays host-owned, the political seal is shared, and **both names go on the legacy seal** under whichever shape they built together.

### Build cost, honestly

This is a **substantial ⟢ VISION layer, not a tuning knob** — and larger than the §3 seed it grows from. It needs: a **World-Map screen** (new zoomed-out board + its state) layered over the village; a **community entity** with warmth-states and per-frontier authored content; the **four Spectrum outcomes** wired to GWI, population, and the **lit-state / recovery channel** (which real Codex entries got relit, and in how many places) — plus the map's political geometry, a web of many lights versus one hub; and a **political-seal** read on the ending screen that skins Commons I. It touches the invention Codex **only** to relight fixed entries — never to add, narrow, or delete them; any per-community flavour lives on a separate flagged lore surface. Cannibalise and reclaim reuse §3's outcome hooks; **federate and annex are new systems.** ⚑ *Liberty: warmth "spreading as a stain" and communities "folding in" compress slow social and thermodynamic diffusion into a legible map cadence — the direction (tended warmth spreads, untended warmth recedes) is honest; the speed is theatrical.* None of it ships today; it is the destination the lone-Ember world is written toward — the last Ember's whole job being to make itself **no longer the last.**


---

## 7. Early Game — The First Warm Night

> **⟢ SHIPPED vs VISION — read this once, it holds for the whole section.** Everything the first warm night is *built on* ships today: **Kindle → Bloom** (five seral stages, flat stat step + **pick-1-of-3 boon** each) → boons/Blooms reset every descent; **Soil**, **GWI-as-weather**; the 3-hit combo + dash i-frames + guard/perfect-parry; **red danger-zone** telegraphs; **one rescue-attunement** banked on contact; the **Warden** boss room; and **bank-or-forfeit** at the gates. Two things this chapter only *foreshadows* are **⟢ VISION** — documented, not in the build, never shown as live: the first **HEAT MODE** a craft-rescue would someday hand you, and the material **HUSK FAMILIES** (Bramble/Beast/Slag + Frost-Encased) that would layer over the behaviour roster. Wherever they surface below they carry the ⟢ marker; nothing under it is playable yet.

The first one-to-two hours. From a single guttering ember in a cold ruin to a hearth that is visibly bigger than it was that morning, with one more face beside it.

### The First Hour, As It Ships

**Cold open.** Black, then a sound before an image: a dry *tick tick tick*, a flame trying to catch and failing. A low light resolves — the colour of a coal on its last minute — and the VOICE speaks close and a little frightened, the way you steady something small:

> *"…there. You held. Good. I thought — no. Never mind what I thought. You're awake, and I'm still lit, and that's two things the dark didn't get tonight."*

The frame widens: a ginger CAT on cracked stone, breath smoking, everything rimed blue — the light, the floor, the leafless dead trees at the ruin's edge. This is the master signal you spend the whole game learning to read: **the world's temperature is its colour**, and right now it is nearly out. One far-off point glows dull orange at the top of frame — the **BONFIRE HEARTH** of your ruined settlement — and the Ember, warm against your chest, tugs you toward it. That short walk *is* the tutorial's first sentence: cold everywhere, one warm point, go to it.

**The Supply Gate.** The Ember teaches by wanting something. *"I can feel them down there. People the fire left behind, and things we could carry home. I can't fetch them. You can."* A guidance beacon — a thin thread of warm light, the only warm thing on screen — draws down toward the **Supply Gate**. You DESCEND.

**First blood, made readable.** The first room is a small sealed arena, floor tilted toward the camera. A single HUSK unfolds from a heap of dead matter — hollow, not hostile. *"It isn't angry. It's just cold, running down. Answer it."* It winds up a lunge and the floor along its path blooms a **RED DANGER ZONE** — the game's core promise made visible: *every blow is painted before it lands.* You DASH (the roll phases clean through the husk, an i-frame heartbeat) and come out into the 3-hit combo — right crescent, left backhand, the 360° **CAN QUET** finisher that flings the husk off its feet. First **KINDLE** motes drift up and settle into the Ember, which brightens by a hair. Six HP, one committed threat at a time: it is *readable*, and being readable is the whole feeling — the dark is answerable.

**First Bloom.** A few kills in, a threshold trips and the cat **BLOOMS** — a pulse and a shift in the ember-aura around the paws — stepping one stage up the seral ladder (**Ash → Pioneer → Herb → Thicket → Canopy**; primary-succession framing in §3, physics in App A). Each Bloom is a flat stat step **plus a pick-1-of-3 BOON draft** that all **resets on the next descent** (Soil/Bloom model → §1).

**First rescue — the beat the game is built around.** Two rooms on, a survivor curled dim in a frost-bubble. You break it; they stand, blink, and **fall in behind you, trailing room to room.** The Ember's voice softens: *"There. That's the reward. Not the metal — them."* The instant you free them it **BANKS**: a permanent **ATTUNEMENT** locks in — say **Bramble Ward (+2 HP, Flora)**, re-applied at the start of every future descent — and it cannot be lost in the dark. Attunements no-stack and the cat stays a **6-HP glass predator** — the ruling, and where real bulk actually comes from, lives in §2. People are safe the moment they're carried; loot is not.

**The first Warden.** An early descent's capstone is the **Warden** room — the cold "learned a shape." Strike it and it does not bleed; it **gutters and goes out**, like a flame starved of air — a one-time relight, never a farm (§3).

**The first bank.** A cleared room opens two GATES — **DEEPER** (richer, harder) or **HOME** (bank) — and the Ember lays the stakes bare, no menu required: *"Full satchel, and the light behind us is thin. Push, and we might carry twice as much — or fall in the dark and carry nothing. Home's warm. Your call."* You take HOME and surface with the satchel intact.

**The first thaw you can SEE.** At the hearth you spend what you carried. A DORMANT building — the Cabin — has a survivor who *knows* it, so it becomes a **BLUEPRINT**; deliver its resource quest and it goes **OPERATIONAL**. The world answers *on screen*: the bonfire swells a notch, the ambient light rolls a few degrees off blue toward gold, and — the payoff you feel in your chest — **one dead tree at the clearing's edge puts out a single leaf.** That is GWI ticking up, rendered as weather, not a number. The first warm night is exactly this: a fire visibly bigger than this morning's, one more face beside it, light no longer quite so blue.

### ⟢ What the Night Foreshadows (Vision Layer)

Two doors the early game *points at* but does not open — flagged so no one mistakes them for live:

**⟢ Your first HEAT MODE.** The survivor you freed *knows a craft*, and the fiction primes you to expect that knowledge to one day teach the fire a new way to move: rescue the **Smith → CONDUCTION / "Blaze"** (contact burn DoT trailing off staggered husks); the **Builder → RADIATION / "Sear"** (radiant aura + hotter crits); the **Farmer → CONVECTION / "Draft"** (an updraft finisher that pulls light husks inward). Modes would swap mid-run and at Rest-Hearths, and after their rescues **Mode and Kingdom decouple** so cross-pairs are legal (→§2). **None of this is in the build** — today the fire is one verb; this is the layer the early game is *written toward*, not shipped inside.

**⟢ Husk FAMILIES over the behaviour roster.** Everything you fight in hour one is pure **behaviour** — Husk / Charger / Lobber / Bomber / Warden (how it attacks). The vision layer adds an orthogonal **material family** — Bramble (dry, ignites) / Beast (damp, moisture-gated) / Slag (inorganic, ~0 kindle) plus **Frost-Encased** as a depth status (what it's *made of*) — and the two **compose**: a **Bramble Charger** telegraphs its rush and, under ⟢ Blaze, ignites mid-charge; a **Slag Bomber** must be *cracked* before its kamikaze ring can be popped; a **Frost-Encased Lobber** has to be *thawed* before its arc will land. Behaviour = how it comes at you; family = what it costs to put out. Shipped today: behaviour only.

### The Play-Style Divergence Starts Here (No Warm-but-Raw Paths)

Nothing in the first hour is neutral. Your first survivor, first invention, first build, and first HOME-vs-DEEPER call are already carving a history — three concrete early branches:

| | **Smith-first aggressor** | **Farmer-first homesteader** | **Greedy deep-diver** |
|---|---|---|---|
| First rescue | Smith *(→ ⟢ Blaze later)* | Farmer *(→ ⟢ Draft later)* | whoever's deepest |
| Archetype seed | **The Bright Predator** | **The Slow Bloom** | greed-tilted Bright Predator |
| First build | **Forge** (Metallurgy, +dmg) | **Crop Bed** (Agriculture, carry a Provision) | banks little, builds late |
| Risk appetite | push, but bank the kill | bank early, bank often | always take DEEPER |
| Ember's early read | *"You out-heat everything you touch."* | *"You never stand at the cliff."* | *"You keep the satchel too long."* |

Three paths are only the branches the first hour makes *visible*; the full six-pole compass (**Bright Predator / Slow Bloom / Hearthkeeper / Archivist**, plus **Kindler / Rot-Reaper** once ⟢ VISION lands) lives in §2, and here identities are *expressed*, not found (→§9). The first invention you light seeds a **worldline** (→§4), and later runs can strike out toward different **frontiers** (→§5).

### Learning the Loop (No Wall of Text)

The loop — **descend → fight → rescue → bank → build → warm** — is taught by three quiet channels, never a manual:

- **The Ember's reactive voice** — one idea per beat, narrating what's in front of you the instant it matters.
- **Just-in-time control tips at first contact** — attack, dash, and guard/perfect-parry each taught on their first relevant telegraph, then never nagged again.
- **The guidance beacon** — the single warm thread always pointing at the next meaningful thing; where *warm = important*, following the light *is* the correct instinct.

### Solo and Co-op in the First Hour

**Solo** is the arc above — one cat, one anxious voice, 6 HP, no default revive; the accessibility valve (assist/story difficulty, telegraph-widening, UI scaling, an *optional* solo revive token) is a chosen setting, not the baseline (knobs → App D). **Co-op** reframes the same beats as spark-lending, and two are new to the first hour: the **first spark-relay** — one player breaks the frost-bubble and takes point while the freed survivor tucks behind the *other*, and the rescue **banks party-wide** the instant it's freed, though loot never pools (each bearer keeps a **PRIVATE satchel**); and the **first gutter** — a Sparkbearer at 0 HP doesn't die, it **gutters**, and a partner holds **Rekindle** to revive at low HP. *You can lose a bearer and never lose the fire.* Full spark fiction, revive economy, party scaling, and gate-voting → §11.

### First Stakes — and the First Loss

The first real gamble arrives around run two or three: satchel fat, beacon home gone thin. DEEPER for maybe double, or HOME to keep what's yours. This is the game's heart in miniature — **the only currency that can be lost is loot; people and attunements banked instantly.**

The **first loss** is a teacher, and almost every player gets it here. You push DEEPER on 6 HP, misread one red zone in a busier room, and fall in the dark. The screen goes cold, the satchel spills, you surface with **most of your loot forfeit.** Two load-bearing softeners keep it a lesson, not a gut-punch:

- **What you kept.** The survivor you freed on the way down is *still home*; their attunement is *still on*. The Ember says it out loud: *"We lost the metal. We didn't lose them. That's the trade we can always live with."* The forfeit prices greed while proving the thesis — *what survives is people and knowledge, not loot.*
- **What resets vs what persists.** Blooms and boons were always going to reset on the next descent, so losing the satchel costs *this* run's materials, not your progress: **Soil, GWI, rescues, and the Codex are untouched.** You go again a little warmer, and next time the satchel's fat and the light's thin, you take HOME — the central lesson landed without a line of tutorial text.

In co-op the first loss is stranger — a **full-party gutter** ends the run and forfeits every unbanked private satchel, while a *single* gutter usually gets Rekindled; the full revive economy lives in §11.

### Early-Game Exit Condition

Early game ends at roughly the first genuinely **warm night**, two-ish hours in: the core loop is internalised (combo, dash, at least one deliberate parry), **one rescue-attunement** is banked with the glass-cat stakes intact, a first OPERATIONAL building feeds the next run, **Soil** is beginning to seed a higher starting seral stage, and GWI is visibly off the floor — warmer sky, bigger bonfire, first leaves out. What pulls them into mid-game (§8): a Gate finally offering to go *below* the shallow ash into a distinct deep biome (→§5), the **⟢ VISION** promises coming due (the first **HEAT MODE**, the first **KINGDOM**, husk **FAMILIES** as a second axis), a Codex with obvious gaps daring them to recover more inventions, and — the quiet hook under all of it — the knowledge that a warmer, more populous, more *diverse* village makes the *next* descent begin further along the succession sequence. The player leaves early game holding one thing the opening didn't have: **a fire that is now theirs to keep, and every reason to carry it deeper.**


---

## 8. Mid Game — The Loop Matures

*The tutorial fire is behind you. Enough people are home that the Ember no longer has to explain itself. Now the whole machine turns over at once — the descent stops being "swing the three-hit combo at whatever lunges" and starts asking who you are inside the loop. This is where REKINDLED stops teaching you the loop and starts reading your choices back to you as a skyline.*

> **What is real here, and what is the promise.** The mid-game you can play **today** is built from **SHIPPED** parts: kill→**Kindle**, thresholds→**Bloom** up the five seral stages, each Bloom a flat stat step plus a **pick-1-of-3 boon** (Blooms/boons reset each descent); **Soil** seeding your starting stage; **Attunements** from rescues; the **Cabin/Forge/Crop Bed/Carpenter's** invention ladder with its Dormant→Blueprint→Operational→Upgraded lifecycle; the 6-HP glass-cat's bank-or-forfeit stakes; and a **v1 economic Cold Snap**.
> Everything that gives the mid-game its *texture below* — **Heat Modes, Kingdoms, Husk Families, the Mode × Family matrix, deep biomes, craft-Wardens, Husk Incursions and the Long Night** — is the **⟢ VISION** layer: designed and documented, **not yet built**. Wherever this section leans on it, it is tagged ⟢ VISION and must never be read as shipped.

---

### What It Looks and Feels Like

**Shipped, today.** Two or three survivors home means your descents open **further along the successional sequence** — Soil seeds you past **Ash** (the cold-scoured mineral surface) into **Pioneer/Herb** with the flat stat steps of every skipped stage *and* a start-of-run boon draft to stand in for the Blooms you leapt over, so a warm start is never a boon deficit. Your **Attunements** re-apply on entry (Bramble Ward, Ember Fang, Gale Step), the granary hands you a **Provision**, and the satchel is now worth a whole building tier — which is exactly what makes the walk back to the Supply Gate a real gamble. ⚑ The long freeze scoured the surface to bare mineral substrate, so this is **primary** succession (lichen pioneers kept, "Ash" = mineral surface, not leftover organics); ⚑ we compress the whole Ash→Pioneer→Herb→Thicket→Canopy sequence into a single descent.

**Mid-game runs now vary by frontier** — which frontier a Gate opens onto (the shipped Buried Warren down; ⟢ VISION the Glaciated Spire, Frostmarch Tundra and Ashen Wald) re-textures the whole descent; the frontier/biome roster is homed in **§5**.

**⟢ VISION — the texture the mid-game is built toward.** Once Modes and Kingdoms land, the combo re-skins under your hands. You carry **one Heat Mode** into the ruins and **swap it mid-run at any Rest-Hearth**; your **Kingdom** is a boon-pool identity **fixed for the run**, biased toward whichever survivor you rescued. Crucially, after their respective rescues **Mode and Kingdom decouple** — cross-pairs are legal (→ **§2**).

| Mode (all fire) | On-screen tell | The verb |
|---|---|---|
| **Conduction / Blaze** | husks smoke with a contact-burn DoT | fire that carries husk-to-husk |
| **Radiation / Sear** | a passive radiant aura, crit rate up | heat delivered *at range*, without melee contact |
| **Convection / Draft** | the CAN QUET finisher becomes an updraft; a hot trail streams off the dash | pull light husks inward, feed oxygen to a burn |

The reason you *swap* is that the ruins ⟢ VISION fight back with **material, not just aggression** — and behaviour and material are **orthogonal axes that compose.** The **behaviour roster** (Husk / Charger / Lobber / Bomber / Warden) says *how a thing attacks*; the **family** (Bramble / Beast / Slag, plus **Frost-Encased** as a depth *status*) says *what it's made of*. They multiply:

- a **Bramble Charger** telegraphs its rush with a red danger zone and *ignites* the moment Blaze touches it, then carries fire into whatever it charged past;
- a **Slag Bomber** must be **cracked** before its kamikaze ring can pop — heat the rock first or it detonates intact;
- a **Frost-Encased Lobber** must be **thawed** before its arc ever lands, so you race its telegraph against its own melt.

| Family | What it is | The gate | The honest answer |
|---|---|---|---|
| **Bramble** | dry dead vegetation, high fuel | none — it *wants* to burn | Blaze; ignites and spreads |
| **Beast** | damp organic mass | **moisture** — boil off water first | Draft accelerates evaporation (or two heat sources at once) |
| **Slag** | inorganic rock/permafrost, ~0 Kindle | **armour** — you *spend* heat to crack it | any Mode chips it; pays almost no Kindle |
| **Frost-Encased** *(depth status)* | any husk, deep-cold | **two-phase**: a depth-scaled sensible-heat warm-up, then a **fixed latent-heat melt plateau** | Sear *accelerates the warm-up* (never skips the plateau); brute heat and wait it out |

**Sear does not "ignore" gates.** It delivers heat without surviving melee contact, but Slag still costs you heat and pays little Kindle, and against Frost-Encased it only *accelerates* the warm-up — never skipping the melt plateau — so the generalist keeps a genuine Frost-Encased edge through **multi-mode Thermal-Shock chains** (physics + fire-setting anchor: App A).

**Home has become a settlement, not a camp** (shipped). Buildings have climbed their lifecycle and the invention ladder is visibly higher — the Forge's **Metallurgy** pushing toward **steel**, the Cabin's **Construction** recovering the **load-bearing arch**, the Crop Bed's **Agriculture** grown into **irrigation and a granary**. Villagers wander and *work*. Because run-effects **cap at 3** and duplicate buildings give **diminishing warmth**, a maturing village is one that has begun to **diversify on purpose** — spam loses.

---

### Play-Styles at Full Power — Two Worlds That No Longer Look Alike

Mid-game is where branching stops being potential and becomes **skyline you can read from the hearth.** The mode/kingdom/family colour below is **⟢ VISION**; the substrate every vignette rests on — Kindle→Bloom→boon, Soil, Attunements, banking, buildings — is shipped.

> **Soil re-weighting** — the canonical model, the proposed weights, and the *warm start = head start, not a boon deficit* rule live in **§1**; the consequence the vignettes below enforce: **a greedy world is a genuinely cold, low-warmth world — never warm-but-raw.**

#### Vignette — The Bright Predator, "The Forge-Cold Warren" (World A)

Rin rescued the **Smith** first and never looked back: metallurgy-first, steel nearly recovered — but she **plunders**, banks late, and freed almost no one. So her skyline is **genuinely cold**: a handful of forges bristling black against a frozen, under-warmed horizon, GWI low because she never banked the returns that raise it. And because rescued-count and diversity are what feed the re-weighted Soil, her descents also start **raw, near Ash** — recovering *steel* did not buy her a later seral stage; **greed keeps both the skyline and the Soil cold at once.** ⟢ VISION She runs **Sear + Fauna** and lives on the **DEEPER** gate: dashes *through* a Charger (i-frames; it self-stuns on the wall), Sear-crits the low-HP Brambles so Fauna's execute refunds HP and **pack-momentum speed** — faster at the end of the fight than the start. Then a **Slag** hulk anchors the next room: Sear delivers heat safely but the kill pays almost no Kindle, her Bloom stalls, and one missed **red danger zone** ends the run in the dark with the whole satchel forfeit. She banks at the last hearth, heart in throat. The Ember is admiring but wary: *"You out-heat the rock beautifully. But rock was never the cold's true face."*

#### Vignette — The Slow Bloom, "The Green Terrace" (World B)

Sol rescued the **Farmer** first: agriculture-first, the full farm chain recovered, crop terraces stepping down toward a bonfire grown huge. He **banks early and frees everyone**, so under the re-weighted Soil his **many rescues and broad, diverse village** — not a warmth coincidence — start his descents at **Thicket, a later seral stage**, with the stacked stat steps of stages 1..N and a **boon draft for the skipped Blooms** waiting on entry. His warmth is high and rising on **diversity**, not loot spikes. ⟢ VISION He runs **Convection + Flora**: a Beast room that would wall a Blaze build, his **Draft** boils dry in seconds, the updraft knots the husks, Flora roots hold them, and he sips a carried **Provision** while thorns do the work — near-zero burst, near-zero deaths. The Ember sounds at home: *"A surplus. The first freedom — hands spared from the soil to do everything else."*

#### Vignette — The Kindler, the specialist in not specialising

Mara reads the **family first, the telegraph second**. ⟢ VISION On a **Frost-Encased** lane she **Sear-soaks** to accelerate the sensible-heat warm-up, then drives a **Blaze** burst to land **Thermal Shock** — the brittle cold husk crazes white and shatters on screen. Next room is Bramble; she swaps to **Draft** and lets **Firestorm** eat the pack. Her village is **Carpenter's / Builder**-heavy, because only fast unlocks keep all three Modes in her pocket. She out-scales specialists on exactly the deep husks that punish a fixed build — and, importantly, she does it **solo**, sequencing Modes across Rest-Hearths.

> **Thermal Shock, honestly.** The fire-only kit cracks a cold, brittle husk by rapid-heating gradient alone — it **never** "heats then cools" (physics + fire-setting anchor: App A).

**The other archetypes at mid-game — none vanish.** **The Hearthkeeper** is the defensive HP identity — HP from stacked **Cabin/Construction +MaxHP tiers**, not from stacking attunements, so the cat stays a **6-HP glass predator**, never a 20-HP tank (attunement no-stack + HP source: → **§2**). **The Rot-Reaper** runs **Fungi**: afflicted husks drop more Materials and Soil and an Armillaria-style rhizomorph **chains** the affliction across a pack — warmth from *decomposition*, not kills. **The Archivist** chases a **complete Codex**, freeing every survivor for the knowledge itself; the Codex is **displayed impact-ranked (canon)**, while a separate "recovered on run N" stamp is the *only* record of the Archivist's history — order never encodes it.

**Same game, ten hours in:** a forge-cold warren vs a green terrace, a raw-Soil plunderer vs a Thicket-start grower, spiky loot-warmth vs broad diverse-warmth. Nobody touched a difficulty slider. They chose *what to remember first*, and the world became the record of it.

---

### The Antagonist Gains a Face — ⟢ VISION

Early, the cold was mute — conditions, not an enemy. Past the shallow ash you drop into **distinct deep biomes** where fragments become **testimony**: the tally-marks stopping at forty-one, the loom with the shuttle still in it, the ledger that runs *grain → firewood → only names*. Husks wear the **shape of their trade**. The cold didn't author this; it preserved a groove worn so deep it kept turning after the person went out.

At the bottom of each deep biome stands a **craft-Warden** — the cold given the silhouette of a lost profession. Strike it and **it does not bleed; it gutters and dims like a flame starved of air** — its bar is *how much cold still holds the shape together*, not blood.

| Warden | Biome | Craft it guards |
|---|---|---|
| **The Keeper of the Empty Rows** | the buried fields | Agriculture |
| **The Cold-Struck Smith** | the choked forge-deep | Metallurgy |
| **The Unfinished Arch** | the collapsed vaults | Construction |

You don't slay them so much as **relight what they guarded** (heat + the recovered craft), folding the invention into the **Codex** — antagonist and invention-ladder become the same bar, read as combat. These craft-Wardens are **one-time relights**, met in any order the branching map allows; the **generic Warden-room** recurs as ordinary roguelite structure. **You never farm a Warden for renewable loot or XP** — GWI comes from **banked returns**, never from bleeding a boss.

#### The first World-Stakes event — home stops being safe scenery

**Shipped, v1 = a purely economic Cold Snap.** Over-expand the clearing, or spend too many days in the deep untending, and GWI in your **outer ring drops below threshold**. The ring **frosts over and goes dormant** (its buildings idle, crops still, attunements greyed) — the on-screen tell is a visible rime creeping the skyline. **Nothing is destroyed; it is *forgotten*,** and re-warms when you feed the hearths again. **No husks enter the village; there is no in-village combat.** Suddenly your braziers and distance-based warmth are **infrastructure**, and the monoculture player learns viscerally that a one-note camp can't keep every ring lit. (Cold-Snap thresholds are **TBD**; canonical world-stakes/antagonist framing lives in **§3**.)

> **⟢ VISION / substantial later phase — flagged build cost.** **Husk Incursions**, **watchtower/villager combat**, and the **Long Night** are *not* in v1. They introduce **in-village combat — a base-defense pivot the current builder/farm screen has no systems for** (enemy pathing into the village, defendable structures, villager combat AI). That is a large, separate build, not a mid-game polish pass, and is called out as such. ⚑ The Long Night is a seasonal/axial-tilt deepening of the cold gradient (the longest night), compressed for play. Incursion cadence and Long Night cadence are **TBD**.

---

### New Decisions and Tensions

- **Deep-vs-bank, at real stakes.** The satchel is worth a building tier; the dark still forfeits everything unbanked; **rescues and attunements bank the instant you free them.** On 4 HP with steel one room away — *is the arch worth the fall?*
- **Specialise vs generalise (⟢ VISION).** A fixed Sear+Fauna diver shreds shallow rooms but stalls on a Slag vault; the Kindler answers every family but masters none. **Rescue order** quietly locks this in — each survivor is a Mode and a Kingdom you can or can't reach.
- **Monoculture vs diversity, now that duplicates hurt.** Cap-of-3 and diminishing warmth make a fourth forge nearly dead warmth; the Cold Snap makes undiverse rings the *first* to go dormant. Diversity stops being advice and becomes survival.
- **Mercy vs plunder — guttering hearths.** Out in the cold your Ember catches a **faint signal**, another fire nearly out. **Relight it** (spend heat/materials; gain survivors who know a craft you don't, and faster GWI) or **cannibalise it.** Cannibalising **forfeits those survivors' rescue** — they are **not killed on-screen; people are never the ante** — but their people and knowledge are **permanently removed from the world and it dents GWI.** The weight is *what you chose not to carry*. The Ember notes quietly that taking one hearth's warmth to feed another's *is exactly how the Long Dark spreads.* This axis is silently choosing your ending.
- **First expansion choices, on other hearths.** Mid-game is where you first reach *beyond* your own clearing to neighbouring hearths and make the opening **federate / annex / cannibalise** calls — the first strokes of your world's political shape. The full expansion spectrum and its map geometry are homed in **§6**.

**Accessibility valve.** Because the forfeit is real, the 6-HP cat ships with assist options — **assist/story difficulty, an optional solo revive token, telegraph-timing widening, UI scaling** — so the stakes have a valve, and co-op never becomes the *only* safer way to play.

---

### Solo and Co-op at Full Power

**Solo** stays a puzzle-duel — carry one Mode, swap it at Rest-Hearths, read the family as carefully as the telegraph, and *sequence* your way to **Firestorm** and **Thermal Shock** on your own. Firestorm/Thermal-Shock are **solo-achievable** and **no depth is gated behind co-op** (revive, private satchels, N-scaling, roles, and the full ruling: → **§11**).

**The mid-game phase-delta is overlap.** ⟢ VISION Because Modes and Kingdoms are per-player and **decouple** after rescues, two fixed builds run legal cross-pairs *simultaneously* — and simultaneity unlocks the one thing a soloist can only approximate across hearths: the genuinely **simultaneous two-source combo** (the **Boil-Off Brigade**, two heat sources at once clearing a Beast's moisture in half the time). Co-op's upside is **revive + team combos + shared people, not lowered pressure** — full rules in **§11**.

---

### Mid-Game Exit Condition

You know the mid-game is closing when three things converge. **The invention ladder tops out** — steel forged, the arch raised, irrigation and granary running — and the Codex has only its deepest, oldest gaps left. **The craft-Wardens fall** (⟢ VISION), one per deep biome, each relit shape leaving the map quieter and the ruins colder-still-deeper than anything you've walked. And **your world has committed to its shape** — a Forge-Cold Warren, a Green Terrace, a Hearth-Keep — legible in the skyline, the Codex's impact order, the Soil-driven starting stage, and the Ember's changed voice.

At that point the map points *down and in.* The boot-prints in the fragments all run toward the deep, and the Ember begins to speak of **the oldest ruin, the first hearth ever let die,** where **the First Warden** stands — not a craft's guardian but the guardian of *remembering itself.* You can keep out-warming the dark until its shapes gutter unmet, or go down and **light the spark that was never struck.** Either way, the next chapter stops being about growing the fire. It becomes about what your fire was *for.*


---

## 9. End Game — Mastery & the Deepest Hearth

> **SHIPPED vs ⟢ VISION.** The mastery *loop* is **shipped (EMBERGROWTH Phase 0)**: kill → Kindle, thresholds → Bloom up the successional sequence (Ash → Pioneer → Herb → Thicket → Canopy), each Bloom a flat stat step plus a pick-1-of-3 boon, Attunements re-applied each descent, Soil seeding your starting seral stage, and banked returns raising GWI. The **⟢ VISION layer is documented, not built**: Heat Modes, Kingdoms, Husk Families and the Mode×Family matrix, deep biomes, the craft-Wardens and the First Warden, and the world-events (Cold Snaps, the Long Night). Every build identity and deep-descent beat below that leans on the vision layer is tagged **⟢ VISION** and must never read as already playable.

### A World Nearly Warm

By the time a player enters the end-game, the loop has done its quiet work, and the proof is on the surface before you ever descend again. **The bonfire hearth is a bonfire now in the old sense — a fire of bones and beams, throwing gold across a clearing expanded outward three rings.** GWI hangs somewhere past 0.85; the ambient light no longer reads as "day," it reads as *held golden hour*, the one the whole game has been walking toward. Dead trees carry leaves. Frost survives only in the outermost ring, and only if you neglected it (the economic Cold Snap — no husks in the village yet).

The **skyline is a résumé you can read at a glance.** A mastery save is *diverse* by necessity — run-effects cap at 3 and duplicate buildings give diminishing warmth, so the finisher's village is Cabin, Forge, Crop Bed and Carpenter's all Operational or Upgraded, each with its lifecycle badge (Dormant → Blueprint → Operational → **Upgraded**) sitting at the top tier. Villagers of every craft wander and work: the Farmer running irrigation, the Smith at the anvil, the Builder walking a fresh foundation, a dozen named survivors you carried home by name. This is the *working-town* state — not a maxed sandbox. Which *shape* that working town wears — which invention topped out, which frontier the run descends toward, which Warden waits below — is set by its **worldline** (→ §4).

The **Codex (press K)** is nearly whole. *ember, the_long_dark, agriculture, metallurgy, construction, the_warden* are all recovered — each an honest, **impact-ranked** paragraph with its liberties flagged — and the only gaps left are the deep-craft entries the deepest Wardens still guard. (The Codex is *displayed* impact-ranked; your recovery order lives in a separate channel — locked/unlocked state plus a "recovered on run N" stamp — never conveyed by list position.)

And the build is at **full mastery.** The player no longer *finds* an identity per run — they *express* one. Kindle flows fast and Blooms climb to the top of the successional sequence (Thicket, Canopy) inside a single descent because fat **Soil** already seeds a later seral stage — a warm start is never a boon deficit (full Soil model → §1). Attunements re-apply each descent but stay capped, and the cat is still the **6-HP glass cat**, never a 20-HP tank (→ §2).

> **⚑ Soil re-weighting.** The proposed reweighting — dominated by rescued-count and village diversity with GWI a minor term, so a cold, plundered world genuinely starts **RAW** under any sky — is stated in full in **§1**.

#### Signature runs at mastery ⟢ VISION

At full mastery the six archetypes (→ §2) stop being stat sheets and become whole grammars a finisher *expresses* rather than *finds*. Their registry — names, Modes, Kingdoms, and one-move fantasies — is §2's to hold; §9 only insists that by the end the identity is *worn*, not discovered, and reads on sight without a tooltip.

After their respective rescues, **Mode and Kingdom decouple**, so cross-pairs are legal — a **Sear + Fauna** predator or a **Draft + Fungi** rotter are both valid expressions, not off-canon. On screen you *read* the archetype without a tooltip: the Predator trails radiant heat-shimmer and red crit-pops; the Slow Bloom leaves a green thorn-lattice; the Rot-Reaper's kills bloom pale mycelium between corpses; the Hearthkeeper simply *does not die* when it should.

**Heat against the cold, at mastery ⟢ VISION.** Against **Frost-Encased** husks — the depth *status*, not a family — **Sear/Radiation accelerates the sensible-heat warm-up** (grounded: ice and water drink infrared strongly) but **never skips the fixed latent-heat melt plateau**; the plateau is a hard gate you wait out, not a wall you punch through. So the Kindler's real Frost edge is the **Thermal-Shock chain**: a fire-only *rapid-heating* fracture — drive a steep thermal gradient into a cold, brittle shell so it cracks by differential expansion. ⚑ *Classic thermal shock usually needs a rapid **cool**/quench the fire-only kit lacks; the honest anchor is **fire-setting** — heat rock, then quench it to crack, Paleolithic-to-Roman mining. Never "heat then cool" for the fire kit.* Against **Slag** (inorganic, ~near-zero kindle) Sear's edge is **delivering heat without surviving melee contact** (⚑ metaphor, not "penetrating armour"). The marquee combos — **Firestorm** (Draft feeds a Blaze until it self-spreads across dry Bramble) and **Thermal Shock** — are **solo-doable** by swapping Modes mid-run and at Rest-Hearths; no depth record is ever gated behind a second player.

**The families become a vocabulary ⟢ VISION.** Behaviour (Husk / Charger / Lobber / Bomber / Warden) and material family (Bramble / Beast / Slag, with Frost-Encased as a depth status) are **orthogonal and compose**: a **Bramble Charger** telegraphs its rush and ignites on Blaze; a **Slag Bomber** must be *cracked* before its kamikaze ring can be popped; a **Frost-Encased Lobber** must be *thawed* before its arc ever lands. At mastery you stop fearing the Slag and start **spending heat on it on purpose.**

### The Confrontation — What "Defeating" Entropy Honestly Means ⟢ VISION

The deepest descent is not a difficulty spike; it is a **legibility spike.** The oldest ruin is also the *first* ruin — the place where, before any village existed to forget, the first tended fire went cold one untended night. Reaching it, the game finally says out loud what the antagonist always was: **the origin of neglect, not a boss at the bottom of a dungeon.**

On the way down you relight the named **craft-Wardens** — each a **one-time relight**, not a farm, that hands back its craft and never respawns as loot or XP; GWI comes from banked returns, never from bleeding a boss (→ §3).

**The honest core: you do not kill the First Warden. It does not bleed.** Its bar is not blood — it is *how much cold is holding the shape together.* You strike it and it **gutters, dims, and goes out like a flame starved of air.** Beating it is not a slaying; the Ember reaches past the composite silhouette — every posture the cold ever held, faintly at once — to the unlit kindling behind it, and **lights the spark that was never struck.** The Warden does not fall. It *finally warms*, and stops needing to stand watch. **⚑** *This dramatizes attractor-dynamics: a self-perpetuating decayed state undone by energy + information restored — heat plus the recovered craft. No villain, no plan.*

> **Vignette — the deepest arena.**
> The floor is rimed stone laid in a ring around a cold grate. The Ember's voice drops to almost nothing: *"This is the first one. Before the village. Before me. Someone laid this fire and never struck it."* The arena seals — Hades-style, no exit until it's decided. The First Warden rises: not a beast, a *silhouette of every lost trade at once*, smith-stoop and courier-lean and the sag of an unfinished arch. It telegraphs a heavy lunge; the red danger zone paints wide and slow. You dash — i-frames, *phase through* — pounce on the turn. Its bar drops, and where you struck it the shape goes *translucent*, cold leaking out as pale vapour. It is not wounded. It is being *forgotten by the thing that was holding it.*

**Different play-styles reach this room by different roads — and one valid road never enters it at all.** Whether a run *races* the deep on plunder (early, under-warmed, on a knife-edge), *saves everyone* and arrives late but armoured, or *starves* the deep and never fights at all is exactly the **Starved↔Confronted** and **Mercy↔Plunder** read that §10's ending axes formalise.

That third road is the boldest canon move in the game: **you can win without ever fighting.** Raise enough diverse, tended fires and the Wardens gutter on their own; the deepest ruin is *already warm and empty* when you finally descend. The game honours it as a real victory, not a skipped one.

### The Ending You Earn — see §10

Reaching GWI 1.0 *always* rekindles the world; **which rekindling you get is the shape of what you carried**, read off three axes — **Diverse↔Monoculture, Mercy↔Plunder, Starved↔Confronted** — with your **dominant invention** (first craft / invention-ladder identity) and **dominant Mode/Kingdom** folded into the world-seal epithet and at least one epilogue line, so the 10 hours of build expression are legible on the last screen. The ending's *political shape* — a federated ring of independent hearths versus a single central blaze — is a **skin the expansion layer supplies (→ §6)**, not a separate rekindling. The full roster of rekindlings, the world-seal, the re-readable epilogue, and every post-win destination (**Endless Deep**, the single **Legacy / NG+** that carries Codex + Soil forward, the Codex museum) live in **§10**. All of them are reachable from **any** completed save; the ending you reached only *spotlights* one — it never gates which exist. The living warm town also stays *tended*, not inert: Cold Snaps to answer, other guttering hearths still calling to be relit, and the later-phase **Long Night** as the finisher's recurring exam (⚑ a seasonal/axial-tilt deepening of the cold gradient, compressed) — proof the world can still be lost, and re-won.

### Solo vs Co-op End Game

**Solo** end-game is the confrontation above — one 6-HP cat, one Ember, one build expressed to mastery, one epilogue keyed to your axes.

**Co-op** earns one end-game beat the solo game structurally cannot — the **finish at the cold grate**: when the Warden's shape goes translucent the game asks for **both** cats at the grate at once, and Player 1's true Ember and Player 2's lent spark light the first fire together, one hearth relit by two hands. Every other co-op rule — the spark fiction, the gutter/**Rekindle** revive, private satchels, the 2P→4 / 3P→6 scaling that pins per-player pressure to the solo baseline, simultaneous-only combos, and *no depth gated behind a second player* — lives in **§11**.

### Reflection — The Last Screen Is the Thesis

Pillar 3 says there is only ever **one progress bar**: warmth returning to a dead world, with player power, village growth, visual grade, and the invention ladder all the *same* bar — the GWI, the Ember. The end-game is where that promise is finally cashed. You do not "beat" REKINDLED by out-damaging a health pool — the deepest enemy **does not bleed; it gutters and goes out**, undone by the one thing it cannot answer: someone who kept remembering, and taught the fire to be kept. The epilogue does not reward you with loot. It shows you the golden-hour world, the named survivors, the near-full Codex — **the people and the knowledge you carried, and nothing else** — and tells you, in the Ember's last near-silent voice, that the fire is somewhere else now: *in them, in you.* The last screen isn't a victory tally. It's the thesis, paid off in gold: **civilisation lives in people and knowledge, not loot — and warmth is carried, hand to hand, or it is lost.**


---

## 10. The Endings & the Rekindled World

Reaching GWI 1.0 *always* rekindles the world. **Which** rekindling you get is never decided by whether you won — it is decided by the shape of what you carried down and back up again: how broad a civilisation you grew, how many people you saved, whether you relit the first hearth face to face or simply out-warmed the dark until it had nothing left to hold, how deep you dared, and which invention your town was built around. The last screen is not a victory tally. It is the thesis paid off in gold — *civilisation lives in people and knowledge, not loot* — and the golden-hour world it shows you is a résumé of your choices you can read without a tooltip. (The full seed→cascade that carries a run's shape into its seal is homed in **§4**; this chapter is the home of the ending *axes* and the five rekindlings themselves.)

> ⟢ **VISION.** The shipped kernel is small and honest: GWI 1.0 → a **re-readable Ember epilogue**, with the **Codex (K)** and the **invention/building identity** already on disk. The elaborated five-world system below — and every place it folds a **Heat Mode** or a **Kingdom** into a seal — is the documented **vision layer**, not a shipped feature. The invention-identity axis rests on shipped buildings; the Mode/Kingdom folding does not yet exist.

### The Axes That Choose Your Rekindling

Five axes read your run and select the epilogue. The first four decide *which world*; the fifth decides *what that world is called and looks like*.

| Axis | Poles | Decided by | Reads on screen as |
|---|---|---|---|
| **Diversity** | Diverse ↔ Monoculture | distinct crafts Operational/Upgraded (run-effects cap at 3; duplicate buildings give diminishing warmth) | the variety of the skyline |
| **Mercy** | Mercy ↔ Plunder | survivors carried, Codex completeness, other hearths **relit vs cannibalised** (cannibalise pushes toward Plunder) | how many named villagers walk the clearing |
| **Confrontation** | Confronted ↔ Starved | did you **relight the First Hearth face to face**, or out-warm it until the Warden guttered unmet, offscreen | a silhouette at the deepest grate — or a sunrise with none in it |
| **How-Deep** | Homestead ↔ Delver | deepest ruin reached / banked **depth-record** | the depth stamp on your world-seal |
| **Invention-Identity** ⟢ | Construction / Metallurgy / Agriculture / Builder lead **+ dominant Mode/Kingdom** | your first craft and invention-ladder lead, plus the run's Mode/Kingdom | the reskin of your seal and town silhouette |

**Mode and Kingdom decouple after their rescues,** so an epithet may pair *any* Mode with *any* Kingdom — a **Sear-Fauna** "Searing Pack" seal or a **Draft-Fungi** "Gale-Rot" seal are both legal reads, not errors. ⟢ VISION.

**The expansion's Political Shape (federate ↔ annex) is *not* a sixth axis.** It is a **skin of the Rekindled Commons (I)** only — it reskins that one merciful, populous world's *geometry*, never selects a different world. See ending I below.

### The Five Rekindlings

Each seal-**epithet** folds the dominant **invention** (a shipped identity) together with the dominant **Mode/Kingdom** (⟢ vision), and at least one epilogue line carries the same fold, so ten hours of build expression are legible on the final screen.

> **I — The Rekindled Commons** *(Diverse × Mercy × Confronted — the "true" ending).*
> **Looks like:** the fullest thaw — held golden hour, a bonfire of bone and beam thrown gold across three rings, dead trees in closed **Canopy**, and *named survivors of every craft working side by side.*
> **Political Shape (a SKIN of Commons — not a sixth axis or a new world):** the same merciful, populous ending wears one of two geometries. **Federate** — a full ring of independent lit hearths on the horizon, warmth held as a web of equals. **Annex — "The One Great Hearth":** a single central blaze all the rings gather around, centralised but *still merciful and populous.* Annex is a **centralised tilt, never "Plunder"** — it is one look of this one merciful world, and the Long Watch's plunder road (II) is a different world entirely.
> **World-seal (template):** *"The [Craft]-Commons of the [Mode/Kingdom]."* Worked reads: a Construction-led, Draft/Flora Hearthkeeper win seals as **"The Hearth-Keep Commons, Green Under the Gale"**; a Metallurgy-led, Sear/Fauna Kindler win seals as **"The Forge-Lit Commons of the Searing Pack."** The **invention-identity axis reskins the same ending** — *Hearth-Keep* (Construction) / *Forge-Lit* (Metallurgy) / *Terrace* (Agriculture) / *Wright's* (Builder) Commons.
> **Ember:** *"You did not keep the fire. You taught it to be kept without you. That is the only way it was ever kept."* — and, folding the build: *"They will strike iron by your light for a hundred winters, and never know the Pack that kept the wolves from the door."*

> **II — The Long Watch** *(Monoculture × Plunder × Confronted — warm, but thin).*
> **Looks like:** warm but *flat* — one kind of building to every horizon, one great hearth blazing alone, the Pack still pacing walls that guard a narrow town. The light is warm and monotone.
> **Reached the metallurgy way:** monoculture, bank-fast, and **confront** the First Warden by force — its default gravity — *never by annex.* You out-heated it; the relight is one-time and never farmed (see §3).
> **World-seal:** **"The Forge-Lit Warren of the Searing Pack — One Log, Blazing."** (Metallurgy + Sear/Radiation + Fauna.)
> **Ember:** *"You out-fought the dark. But a fire of one log burns fast. Mind the second night."*

> **III — The Slow Dawn** *(Diverse × Mercy × Starved — you never fought the Warden at all).*
> **Looks like:** a **sunrise with no silhouette in it.** Green terraces holding against the gale; when you finally walk down to the oldest ruin, the grate is warm and the arena empty — the First Warden long since **gone soft and gone**, guttered unmet because the world out-remembered it (Warden ruling: §3).
> **World-seal:** **"The Terrace That Out-Warmed the Dark, Green Under the Gale."** (Agriculture + Draft/Convection + Flora.)
> **Ember:** *"You never had to strike it. You only had to remember faster than it could forget. That, too, is a victory — the kindest kind."*
> This "starve the deep" win is **fully valid and honoured** — not a skipped ending, a *different* one: raise enough diverse, tended fires and the cold's grooved shapes have no gradient left to hold. (Attractor-dynamics dramatized — App A.)

> **IV — The Hollow Warmth** *(Monoculture × Plunder × Starved — the cautionary win).*
> **Cannibalise feeds here:** hearths *taken* for warmth instead of relit push the **Mercy** axis toward Plunder, and this is a road into this world.
> **Looks like:** a warm sky over a *mostly empty field* — and, honestly, a **cold skyline at the margins**: half the outer rings still frosted and dormant from Cold Snaps you never tended, few villagers, a Codex full of gaps. The warmth is nominal and brittle; a greedy world barely scrapes 1.0 and the dark claws rings back the moment you look away. (A plundered world reads genuinely *cold at its edges* — never "warm but hollow-hearted and secretly fine.")
> **World-seal:** **"The Warm and Empty Field — the Mycelium Fed, the Hearths Few."** (Fungi tempo + plunder emptiness.)
> **Ember, at its coldest:** *"Warm is not the same as remembered. You have a fire. You have almost no one to keep it. Be careful you have not simply moved the dark somewhere you cannot see it."*

> **V — The Kept Flame** *(any axes × **Codex 100%** override — the knowledge ending).*
> **Looks like:** the world thaws while the **inventions scroll in gold** — agriculture, metallurgy, construction, the keeping of fire — every liberty read, every craft-Warden's knowledge relit. The last beat belongs to the list itself.
> **World-seal:** **"The Kept Flame — Every Craft Remembered."**
> **Ember:** *"Civilisation was never the loot, or even the warmth. It was this — the list of what a mind learned to do, and troubled to teach. Carry that, and you carry everything."*

### Which Ending Each Path Leans Toward

Every archetype gets a home, and every leaning is a **tendency, not a rail** — any archetype can carry any world, because the axes read your *choices,* not your class. The full seed→cascade (which archetype's default worldline drifts toward which seal, and why) is homed in **§4**; it is not re-derived here.

### After the Last Ember — Post-Win Destinations

**Every destination below is reachable from *any* completed save.** The ending you reached only **spotlights** one — it never gates which of them exist. Finish once, and all of this is open.

| Destination | What it is | Notes |
|---|---|---|
| **Endless Deep** | past the First Warden's now-warm grate the ruin keeps descending; **generic** Warden-rooms recur as ordinary roguelite structure; Frost-Encased gates deepen (physics: App A) | the **How-Deep** axis's home — a banked **depth-record**, never a warmth or loot tap (GWI is already 1.0). You never re-kill the First Warden — a one-time relight (§3) |
| **Legacy / New Game+** *(unified)* | **one** system: begin again with **Codex intact and Soil seeded**, an established world passing the craft down; per-ending **cosmetic** framing dresses your starting town in your ending's character | de-dups "Legacy" and "Soil-carry" into a single mode. Seeding to stage N grants stages 1..N's flat steps **and** a start-of-run boon draft for the skipped Blooms — a warm start is never a boon deficit (§1) |
| **The World-Seal + re-readable epilogue** | your auto-generated **epithet** and seal on the title/pause screen (folds dominant invention + Mode/Kingdom ⟢ + depth stamp, and — for a Commons win — its federate/annex skin), with the **epilogue one click away**, re-readable anytime | the ending you reached foregrounds one seal; you may re-view any you have earned |
| **The Codex Museum** | a permanent readable room — every invention and flagged liberty, **displayed impact-ranked**; your recovery history (locked/unlocked + a "recovered on run N" stamp) is a **separate channel**, never conveyed by list position | the Kept Flame's home, but open from *any* save, not gated to that ending. The Codex is fixed and honest — federate/annex worlds add no deletable entries (App A/D) |
| **The Living Village** | Cold Snaps, Husk Incursions, and the opt-in **Long Night** keep the warm town a *tended* thing; other **guttering hearths** still call to be relit for fresh survivors and Codex depth | home stays at stake — warmth kept is warmth carried. Incursions **frost a ring, never raze it**; people are never the ante. Long Night deepens the cold gradient (App A) |

The whole architecture cashes Pillar 3's single bar: you do not "beat" REKINDLED by out-damaging a health pool — the deepest enemy **does not bleed; it gutters and goes out**, undone by the one thing it cannot answer, someone who kept remembering. Whichever of the five worlds your seal names, the epilogue rewards you with no loot at all — only the golden-hour world, the named survivors, and the Codex: *the people and the knowledge you carried, and nothing else.*


---

## 11. Co-op — Two Embers, One Hearth

Co-op is greenfield. This layer is designed to reinforce the sacred thesis — *civilisation lives in people and knowledge, not loot* — rather than dilute it. The guiding move: co-op is not "more cats," it is the game's central metaphor made literal. Warmth is passed **hand to hand**, or it is lost.

> **Build reality (flag):** The engine has no netcode and only a ConfigFile save for village meta; RUN state is deliberately unsaved. Everything below is scoped **couch-first (shared-screen, two gamepads)**, with online as a later lift. Nothing here assumes a rewrite of the save model — the shared village stays one host-owned `hearth-save`, exactly as today.

> **⟢ VISION.** Heat Modes, Kingdoms, Husk Families and the Mode × Family matrix that this section composes on are the **planned vision layer**, not shipped. Co-op inherits them wholesale; nothing built into today's game gains a second player yet.

### Player count & the multi-Ember fiction

**Recommendation: 2 players is the tuned core; 3 is the canon-perfect ceiling; no 4.**

The reason is science-first, not arbitrary. A living system needs three roles: **Producers (Flora), Consumers (Fauna), Decomposers (Fungi)** — already the three Kingdoms, already mapped to the three rescuable crafts (Builder, Smith, Farmer). So a party of three isn't "one more body," it is a **complete successional trio**: two players pick two of the three and feel a deliberate gap; three players close the loop. A fourth breaks both the trophic metaphor *and* the readability budget (see scaling, below).

**LITHO stays out of the party for now.** The reserved 4th ecological role — the chemolithotroph tank — is a **solo late-meta unlock**, not a co-op slot; three rescues = the complete trio is the co-op **baseline**. Whether LITHO ever becomes a 4th co-op slot is **TBD (flagged)**.

#### The fiction — the Ember lends a spark

There was only ever **one** last Ember. Two points of warmth may cross the ruins, but the flame is never divided — that would cheapen the stakes and contradict the physics. Instead, the Ember **lends a spark**: the cat kindles a companion's *own fuel* from the one Ember, and that companion carries borrowed light as a **Sparkbearer** (a littermate, or a survivor the cat relit).

Lending a spark is **honest fire-spread** — combustion propagating to fresh fuel is exactly what fire does, and it is the whole game's metaphor made literal, so it needs no apology. The single dramatized cheat lives elsewhere: when a spark gutters and *flows back* to the Ember to be rekindled (flagged at the revive, below).

| Fiction option | Keeps "one last ember" sacred? | Serves "carried, hand to hand"? | Verdict |
|---|---|---|---|
| Split the Ember into equal portions in littermates | No — divisible fire = cheaper stakes | Weakly | Reject |
| Each player is an independent Ember-bearer | No — now there are many "last" embers | No | Reject |
| **The cat kindles a lent SPARK in a companion; the true Ember stays whole** | **Yes — the flame is never divided, only spread** | **Yes, literally** | **Recommend** |

Player 1 is the ginger cat carrying the one Ember; each partner is a **Sparkbearer** carrying kindled, borrowed light. You can lose a *bearer* and never lose the *fire*, because the fire was always the thing carried between people.

### Roles & team combos — composing a party

Heat Modes and Kingdoms are **per-player**, so a party *composes* into interactions no soloist can reach at once. Three clean identities fall straight out of the three rescue crafts; two players pick complementary halves, three fill the loop.

#### Who does what

| Party role (Kingdom / trophic) | Rescue source | Default (biased) Heat Mode | In-fight job |
|---|---|---|---|
| **The Slow Bloom** — Flora / Producer | Builder | Radiation ("Sear") | Holds ground; radiant aura + regen-in-light; roots and thorns peel husks off a diving ally |
| **The Bright Predator** — Fauna / Consumer | Smith | Conduction ("Blaze") | Glass cannon; burn-DoT + lifesteal + pack-momentum on kills; dives the low-HP husks the Bloom exposes |
| **The Rot-Reaper** — Fungi / Decomposer | Farmer | Convection ("Draft") | Updraft finisher + hot-draft trails; afflicted husks drop more Materials and feed Soil; oxygen for the Predator's fire |

**Mode and Kingdom decouple after their rescues.** A Kingdom is a boon-pool identity **fixed for the run** (biased by the rescue that unlocked it); a Heat Mode **swaps mid-run and at Rest-Hearths** — for co-op players exactly as for a soloist. So the "default" Mode above is a lean, not a lock: cross-pairs like **Sear + Fauna** or **Draft + Fungi** are perfectly legal once both rescues are in.

**A note on Sear and gates:** Sear **accelerates** a gate's warm-up but never **bypasses** it, so the Frost-Encased edge is kept by **multi-mode Thermal-Shock chains**, not a single hot beam (the physics — IR absorption, the fixed latent-heat plateau, reach-not-penetration, all ⚑-flagged — lives in App A).

**The other three archetypes still get expression** — they are Mode/meta/village overlays, decoupled from the Kingdom slot, so any party member can lean into one:

- **The Hearthkeeper** — the front-line anchor. Its HP identity comes from **Cabin / Construction +MaxHP tiers**, *not* from spamming +2HP attunements; the 6-HP glass-cat stakes are preserved (never a 20-HP cat).
- **The Kindler** — the Radiation/Sear specialist who cracks **Slag and Frost-Encased** depth gates via multi-mode Thermal-Shock chains.
- **The Archivist** — the knowledge-carrier who ports Codex paragraphs between worlds (portable progression, below).

Two-player default = **Slow Bloom + Bright Predator** (anvil + hammer). Add the Rot-Reaper and the party self-sustains: the Decomposer feeds Soil and drops, the Producer regens, the Consumer converts it to pressure.

#### Team combos — and where the co-op edge actually is

The physically-honest Mode × Family matrix becomes *team* play. But most of it is **already reachable solo** by swapping Modes sequentially mid-run or at a Rest-Hearth — co-op simply lets two *fixed* builds overlap in **real time**. The four heat combos sit in one roster below alongside the plays that are co-op-only *by nature* — the rescue relay, the spark-relay revive, and the village stand.

| Co-op play | Sources | Effect | Best against | Co-op-only? |
|---|---|---|---|---|
| **Firestorm** | Conduction burn + Convection draft | Draft feeds oxygen to the burn → fire intensifies and self-spreads room-wide | **Bramble** (dry, high fuel — carries fire) | **No** — soloable by sequential Mode swaps |
| **Thermal Shock** | Radiation sear + Conduction burst | Localized heating fractures a cold, brittle solid (App A) | **Slag / Frost-Encased** | **No** — soloable via multi-mode chains |
| **Nutrient Bloom** | Fungi kill + Flora field | Decomposer kill drops a heal/thorn bloom the Producer's light amplifies | **Beast** attrition, sustained fights | Overlap only — not a hard gate |
| **Boil-Off Brigade** | **Two heat sources on one target at once** | Parallel heat clears a Beast's moisture gate in half the time | **Beast** (damp — boil the water first) | **Yes** — genuinely simultaneous |
| **Rescue-carry chain** | Two players relay a trailing survivor | Hand a survivor player-to-player, one covering while the other carries — the thesis as a *play verb* | escort / ambush rooms | **Yes** |
| **Spark-relay revive** | A living cat cups a partner's guttering spark | Re-ignite a downed Sparkbearer (see *Downed / revive*, below) — the single most on-theme moment in the game | any downed ally | **Yes** — solo keeps no revive |
| **Defend the village together** | Both players, in the home you raised | Hold the shared warm village as a duo when the deep pushes back — the post-win endless mode's co-op hook | Husk Incursions / Long Night | **Yes** |

**The rule, stated plainly:** only genuinely **simultaneous two-source** combos (the *Boil-Off Brigade*) are a co-op-only edge. **Firestorm** and **Thermal Shock** are achievable **solo** through sequential mid-run / Rest-Hearth Mode swaps, and **no depth record is gated behind co-op-only combos** — a soloist can reach max depth. Co-op is *faster and showier* at these, not *required* for them.

**⚑ Thermal Shock:** a fire-only rapid-heating fracture (honest anchor: fire-setting; the full framing and its ⚑ liberty live in App A). The co-op version changes nothing physical — it simply delivers the heating step from two Modes at once.

Worked composition (behaviour × family compose orthogonally): a **Frost-Encased Lobber** must be thawed before its arc lands, and a **Slag Bomber** must be cracked before it can be popped — either is a clean "one player sets the gate, the other cashes it" beat.

### The descent in co-op

**Movement on the map:** the party is **one shared token** on the branching node graph (keeps everyone together and the map readable). Inside a locked arena they move and fight **independently**. Between rooms, back to one token.

**Satchel — private carry, shared bank.** Each player fills their **own** run satchel and bears their **own** forfeit risk: if *you* fall in the dark, *you* lose *your* loot — the glass-cat risk/reward stays personal and intact, mirroring the solo forfeit exactly. **Rescues and attunements**, by contrast, **bank instantly and party-wide** the moment a survivor is freed. Loot is private and riskable; *people and knowledge* are communal and safe — the thesis, enforced by the reward structure.

**Satchel edge-rulings:**

| Edge case | Ruling |
|---|---|
| A player times out (spark flows back), then the party reaches a **HOME** gate | Their **un-spilled** satchel **still banks** — a timeout is not an automatic full forfeit |
| Spilled embers left ungrabbed | **Forfeit at the next room transition** (recoverable only within the room) |
| **Full-party gutter** | **Every unbanked satchel is forfeit** (solo dark-fall parity); the Ember survives, you limp home on banked gains |
| Rescues / attunements | **Bank the instant a survivor is freed** — never at risk |

**Gate votes (DEEPER vs HOME).** Pushing deeper is the risky commitment, so it needs consensus: **DEEPER requires a majority** (in 2P, unanimous). **Any single player may call HOME** — banking is always a safe out, and no one is dragged into the dark against their nerve. On a 2P split the Ember offers a Rest-Hearth beat to reconsider, then defaults **HOME**. Push-vs-bank tension becomes a *social* layer without stalling the map.

**Expansion is a shared vote, too.** The World-Map Spectrum choices — reclaim, federate, annex, cannibalise — are shared consensus beats resolved exactly like the DEEPER-gate vote: a lasting commitment needs the party's agreement (detail in §6).

**Downed / revive — the spark-relay.** At 0 HP a Sparkbearer doesn't die — it **gutters**: incapacitated, its lent spark flickering on the ground. A partner can **Rekindle** it (stand adjacent, hold — "cup the spark") to revive at low HP. If no one reaches it in time, the spark **flows back to the Ember**: that player sits out until the next room / Rest-Hearth and **spills part of their satchel** as recoverable "spilled embers" a teammate can grab.

> **⚑ Liberty (flagged HERE, not on the lending):** a guttered spark *flowing back* to its source to be rekindled is the one physical cheat — combustion has no reverse-propagation to its source. The *lending* of a spark is honest fire-spread and needs no apology; only this *return* is dramatized.

**Reads on screen:** the downed cat collapses into a dim, guttering ember-mote on the floor; the reviver's paws cup around it and a visible thread of light bridges the two, the mote swelling back into a full flame on a rising warm chord — legible across a crowded arena with no tooltip. **Solo keeps no revive** (solo death consequences are unchanged), so co-op is *different*, not *free-easier*: the revive already costs dropped loot and tempo.

**Difficulty scaling — per-player pressure holds at the solo baseline.** Solo pressure is **~2 committed attackers for one player** (the readability pillar: only ~2 husks commit at once) = **2.0 per player**. Co-op does **not** lower this. Committed-attacker count **scales with party size to hold 2.0 each**: **2P → 4 committed, 3P → 6 committed.** Husk *population* also swells so rooms feel fuller, but each player still faces ~2 telegraphing danger zones, so crowds stay readable. The co-op **upside is revive + team combos + shared people — never lowered pressure**; solo is never a gimped co-op. The Warden gains HP and **one extra telegraph lane per extra player**, placed so danger zones never overlap into an unreadable smear.

**Guttering hearths — relight or cannibalise, together.** Deeper rooms hold *other* survivors' fading hearths. The party can **relight** one (a rescue — banks party-wide, instantly) or **cannibalise** it for its residual warmth and materials. Cannibalising **forfeits that rescue**: the survivor is **never shown dying** — *people are never the ante* — but their people and knowledge leave the world for good and **GWI dents**. In co-op this becomes a shared moral beat (consensus, like the gate vote); the weight both players carry out is *what you chose not to carry.*

| Descent question | Ruling |
|---|---|
| Map movement | **One shared token**; independent inside arenas |
| Gate choice | DEEPER = majority (2P unanimous); **HOME = any one player** |
| Downed model | **Gutter → Rekindle** revive; timeout = spark returns + spilled-ember drop |
| Committed pressure | **~2.0 per player** always (2P→4, 3P→6 committed attackers) |
| Blooms / boons | **Individual** — own Kindle, own Blooms, own pick-1-of-3 (assist credit on kills to stop leeching) |
| Friendly fire | **None on damage.** Ally burn/draft/fungi fields are beneficial/neutral; a Convection updraft may *reposition* (non-damaging) a teammate |

Individual Blooms are essential: they preserve each player's build identity (the soloist's fantasy) *and* they're what make the combos above possible.

### The village in co-op

**Whose village? One shared, persistent, host-owned settlement.** Guests inhabit the host's world; there is no "instanced" village to reconcile — this matches the existing single ConfigFile save with zero new persistence work.

Both players **build, farm, and quest simultaneously** from a **shared stockpile**, turning the prep phase into a co-op "kitchen" beat: one lays foundations and runs the Carpenter/Builder loop while the other tends the Farm chain and hauls. Placement is first-come with a soft "claim" highlight so two hammers don't collide.

**"Rescue the knowledge, supply the labour" with two labourers:** the *knowledge* half (rescuing the survivor who knows the craft) stays a single, party-wide event — no double-dipping. The *labour* half (the resource-delivery quest) **parallelizes**: two players clear a building's quest faster, or one delivers while the other preps the next foundation. Expanding the clearing is a shared sink, so **the warm village visibly grows faster in co-op** — the "build it together" fantasy, and a genuine reason to invite a friend. The **3-effect run cap and diminishing duplicate-warmth rules are untouched**, so co-op still rewards a *diverse* village, not spam.

### Drop-in / drop-out & portable progression

- **Village phase:** free drop-in/out. A joining guest's spark is kindled at the bonfire; on leaving, the spark returns to the Ember and the guest-cat curls by the hearth. No penalty.
- **Mid-run drop:** the departing spark returns to the Ember (a forced gutter-timeout), the unbanked satchel spills as recoverable embers for the host, and the run **re-tunes down to the remaining N at the next room boundary** (never mid-arena — that would be unfair).
- **Host drop = session ends.** Loot and warmth stay with the host's world, so a guest can't strip-mine a friend's GWI.

**Portable progression — the rule that keeps saves honest:**

- **Codex knowledge is portable.** Lore is low-power, so a guest carries recovered paragraphs home into their **own** Codex; *knowledge is the point*, and it is the one thing they rightly leave with.
- **Attunements are NOT freely portable.** An attunement is bound to a rescue performed in a player's **own** world. Rescues done inside the host's co-op world bank to the **host's** GWI, party-wide, but grant the guest **no permanent** solo-save buff (at most a **fractional/temporary carry — exact rule TBD**). Symmetrically, **joining a session never front-loads your solo save's permanent attunements** as full power — a co-op run cannot be a buff-import. This preserves the cap-of-3 attunement discipline (one meaningful attunement per element/Kingdom, hard diminishing returns) and stops co-op from strip-mining or trivializing either world.
- **Absence in the persistent village:** contributions simply persist. The village doesn't track who swung the hammer, so a returning partner just re-kindles at the hearth — no ghost bookkeeping.

### How co-op changes the game — at a glance

| Phase | Solo | With co-op |
|---|---|---|
| **Early** | Learn combos on Bramble; slow village chores | **Parallelized prep**; first rescue-carry relays; learning to Rekindle a guttering partner |
| **Mid** | Swap Modes to answer gates alone | **Persistent team comps** run Firestorm / Thermal Shock *simultaneously* (soloable sequentially, faster here); the *Boil-Off Brigade* is the true co-op-only edge on Beast gates; gate-votes become social |
| **End** | Solo push to GWI 1.0; endless-deep alone | **Co-op push to rekindling**; endless-deep as a duo; **both names on the one rekindled-world legacy seal**, with the epithet folding each player's dominant invention and Mode/Kingdom |

Every ruling above is chosen so that **solo loses nothing** (private satchel, own risk, own build, own reachable depth, no revive crutch) while **co-op means something new** (shared-token tension, trophic-trio composition, hand-to-hand revive, parallel village-raising) — and so the whole layer says, again, the one thing REKINDLED always says: *warmth is carried, hand to hand, or it is lost.*


---

## Appendix A — Science-First Ledger

Every mechanic in this bible is anchored to a real physical, ecological, or historical process, with each liberty marked ⚑ and stated plainly. This is Pillar 2 as an audit: a real advance, the *right* causal story, liberties flagged, impact over date. Rows tagged ⟢ VISION describe the destination layer and are not yet shipped.

| Mechanic | Real anchor (the honest causal story) | Liberty ⚑ | Status |
|---|---|---|---|
| **Heat Modes** | The three genuine modes of heat transfer. **Conduction/Blaze** = contact transfer through touch (the burn DoT lands where the claw lands). **Radiation/Sear** = infrared emission across a gap (the radiant aura needs no contact). **Convection/Draft** = heat carried by moving fluid/air (the updraft finisher rides a rising thermal column). | ⚑ A single Ember switching cleanly between all three "at will" is a gameplay abstraction; real sources bleed all three modes at once. | ⟢ VISION |
| **Kindle = heat of combustion** | Killing a husk releases its stored chemical energy as heat — a literal enthalpy of combustion. Yield varies by **family** because dry lignin-rich fuel (Bramble) releases more accessible heat than damp tissue (Beast) or near-inert mineral (Slag, ~0 kindle). | ⚑ Instant, quantised "kindle points" abstract a continuous exothermic reaction into a score. | SHIPPED (as kill→Kindle) |
| **Frost gate (sensible → fixed latent heat)** | Thawing a Frost-Encased solid follows real calorimetry: first **sensible heat** raises temperature toward the melt point (this part scales with how hard you heat), then a **fixed latent-heat plateau** where energy goes into the phase change at constant temperature. The plateau is a fixed cost — it cannot be rushed. | — (this is straight physics; no liberty needed) | ⟢ VISION (depth status) |
| **Beast moisture gate (latent heat of vaporisation)** | Damp Beast tissue must first boil off its water — the **latent heat of vaporisation** — before it can ignite. Water is a genuine ignition sink, which is why wet fuel resists fire. | — (real; wet fuel truly gates on this) | ⟢ VISION (family gate) |
| **Thermal Shock** | Fire-only **rapid-heating fracture**: driving a steep thermal gradient into a cold, brittle solid causes differential expansion between hot surface and cold interior, and the solid cracks. The honest historical anchor is **fire-setting** — Paleolithic-to-Roman miners heated rock at the face to shatter it. | ⚑ Classic textbook thermal shock usually needs a rapid **cool/quench** the fire-only kit lacks; fire-setting historically *quenched with water* to crack rock. The kit keeps the fracture but never writes "heat then cool." | ⟢ VISION |
| **Sear vs Frost (IR absorption by ice)** | Sear/Radiation **accelerates the sensible-heat warm-up** because ice and water absorb infrared strongly — a grounded, real property. It speeds the ramp; it does **not** skip the fixed latent-heat melt plateau. | — (IR absorption is real; the plateau is honestly preserved) | ⟢ VISION |
| **Sear vs Slag / armour** | Against near-inert Slag, Sear's real edge is **delivering heat without surviving melee contact** — radiant transfer across a gap keeps the glass-cat out of a hazardous exchange. | ⚑ "Cuts armour" is a *metaphor for reach*, not literal penetration; radiant heat does not bypass a solid. Because Sear only *accelerates* and never bypasses, **The Kindler** keeps a real Frost edge through multi-mode Thermal-Shock chains, not through a magic armour-skip. | ⟢ VISION |
| **Succession (the Bloom ladder)** | Blooming Ash → Pioneer → Herb → Thicket → Canopy is **primary succession** on **bare mineral substrate**: the long freeze scoured the surface, so "Ash" names the cold-scoured mineral surface, not leftover organics, and lichen/pioneer colonisers arrive first. This is a **successional sequence / later seral stage**, explicitly **not** "further up a food web." | ⚑ Real primary succession takes decades to centuries; compressing it into one descent is a deliberate one-descent compression. | SHIPPED (5 stages) |
| **Fungi kingdom** | Decomposers close the loop: fungi return locked nutrients to the substrate, and *Armillaria* grows **rhizomorphs** — real root-like cords that spread through soil and chain between hosts (the honest basis for the Armillaria rhizomorph chain and "afflicted husks drop more materials/Soil"). | ⚑ Weaponised chain-spread and drop-rate bonuses are game economy layered on real decomposer ecology. | ⟢ VISION |
| **Flora regen** | Flora's regen is **light-driven, not warmth-driven** — it models photosynthesis, which is powered by light energy, so the cat heals "in light," not "when warm." | ⚑ Instant combat-timescale regen abstracts a slow metabolic process. | ⟢ VISION |
| **The Long Dark (the cause)** | **Entropy / gradient-loss** made legible: "the world went cold the way any fire goes cold — one untended moment at a time." It is the sum of what the living stopped remembering, which is why remembering can undo it. There is **no villain-with-a-plan**. | ⚑ Not a scheming antagonist, and deliberately **not** framed as a "local minimum" to be optimised out — it is thermodynamic forgetting given a face only in the Warden. | SHIPPED (lore spine) |
| **Long Night (world-stakes)** | A **seasonal / axial-tilt deepening** of the cold gradient — the longest night, when the tilt swings the ring furthest from its warmth and the temperature gradient steepens. | ⚑ Compressed cadence and severity for play; real axial seasonality is gradual. | ⟢ VISION (later phase) |
| **The Warden (the face)** | "The cold learned a shape… strike it and it does not bleed; it gutters and goes out, like a flame starved of air." A localised deficit of heat/energy, defeated by **restoring** heat, not by wounding a body. | ⚑ A distributed thermodynamic state given a single fightable silhouette. | SHIPPED (one Warden) |
| **Attunements (rescue buffs)** | Each freed survivor teaches a durable adaptation (Bramble Ward, Ember Fang, Gale Step). Modelled as **one meaningful buff per element/Kingdom with hard diminishing returns** — mirroring the buildings' cap-of-3 discipline, so the 6-HP glass cat is never inflated toward a 20-HP tank. **The Hearthkeeper's** HP identity comes from Cabin/Construction +MaxHP tiers, not from stacking +2HP attunements. | ⚑ Permanent "remembered" buffs re-applied each descent abstract learned skill as a stat. | SHIPPED (one attunement) |
| **Altitude cold-drain** (Glaciated Spire, UP) | Climbing Metallurgy's summit forge, the air aloft is genuinely **colder, thinner, and lower in oxygen** — real lapse-rate and reduced partial pressure — so warmth bleeds faster the higher you push and a fire has to breathe harder to hold. | ⚑ Per-metre drain and the "fire needs air aloft" tax are tuned for a run's pace, not real hypsometry. | ⟢ VISION |
| **Cold-water immersion** (Drowned Coast) | Falling through the frozen sea, sudden immersion in near-freezing water strips core heat **orders of magnitude faster than cold air** — real cold-shock and rapid core cooling. | ⚑ Softened for play — a true plunge incapacitates in minutes; the run grants a survivable warmth-drain timer instead. | ⟢ VISION |
| **Permafrost megafauna (frost-then-moisture two-gate)** | A deep-frozen carcass locked in permafrost is a **two-gate thaw**: it must first **melt** (sensible heat + latent heat of fusion) and only *then* can its freed moisture **boil off** (latent heat of vaporisation) before the tissue takes fire — the Frost gate and the Beast moisture gate stacked in one body, in series. | — (straight calorimetry: two real plateaus back to back) | ⟢ VISION |
| **Sea-ice tidal cracks / opening leads** (Drowned Coast) | The frozen sea **flexes with the tide** and fractures into **opening leads** — the real flexing and cracking of sea ice — so the shared highway shifts and gaps underfoot. | ⚑ Crack cadence and lead-width are set by a play-tuned tide timer, not real tidal periods. | ⟢ VISION |
| **Warmth-as-a-stain diffusion** (World Map) | Tended warmth **spreads outward and untended warmth recedes** across the map like a stain — the honest direction of a real heat gradient / diffusion (warmth flows down the gradient, and a source that stops being fed cools back toward the cold). | ⚑ Direction is honest; the *speed* of the stain eating white (or receding) is theatrical, compressed for a readable map. | ⟢ VISION |
| **Ashen-Wald fire-spread** (Woodcraft, ACROSS) | Fire propagates across **dry standing dead wood** — real surface/crown fire-spread through cured fuel, the Wald a forest killed and dried by the freeze. | ⚑ The ash is **old, pre-freeze**, and burns are **player-caused only** (no ambient wildfire); spread rate is tuned for arena play. | ⟢ VISION |
| **Woodcraft / charcoal** (the Last Wright) | Charring wood in low oxygen drives off volatiles to leave **charcoal — the hotter, cleaner fuel a forge actually needs** to reach smelting heat: the honest causal link from Woodcraft ACROSS to Metallurgy's forge-deep. | ⚑ An instant "make charcoal" step abstracts a slow pyrolysis burn. | ⟢ VISION |
| **The invention Codex (fixed, impact-ranked)** | Knowledge is **never deletable**. The Codex is a **fixed, impact-ranked, honest** ledger of real advances (App D), ordered by consequence — not chronology, not playthrough. The **expansion layer does NOT make Codex entries deletable or add per-community "dialects"**: federate / annex / cannibalise change the **map's political geometry, the population, and which real entries a given world relit**, never the fixed ledger itself. | — (the honesty *is* the design; any per-community flavour lives on a clearly-separate community-lore surface, off the invention ledger) | SHIPPED (impact-ranking) + ⟢ VISION (expansion channel) |

## Appendix B — Shipped → Vision Roadmap

The chapters of this bible describe the **destination**. This appendix is the **path**. Everything tagged ⟢ VISION above turns on in stages; nothing here is presented as already running.

### What a session looks like TODAY (shipped)

A run is one heat identity, not a matrix. You **DESCEND** at the Supply Gate into a branching node map of locked arenas. You fight with Kindled Claws (6-HP cat, 3-hit combo, dash i-frames, guard/perfect parry) against a readable roster where only ~2 husks commit at once. Kills **Kindle**; thresholds **Bloom** you up the five succession stages, each Bloom a flat stat step plus a **pick-1-of-3 boon** — and Blooms/boons **reset every descent**. You may **rescue one survivor** who then trails you; freeing them **banks instantly** and grants a **single permanent attunement** re-applied each descent. Cleared rooms open **DEEPER or HOME** gates. Return in the light to **bank**; fall in the dark and **forfeit** most of the satchel. Back in the **VILLAGE**, you build/farm/expand the clearing, run the building lifecycle (Dormant → Blueprint → Operational → Upgraded via rescue + resource quests), and **GWI** ticks up as warmth banks. One Warden stands as the boss; **Soil** seeds your starting stage. That is the whole shipped loop, and it is complete on its own terms.

### The staged switch-on (maps to PROGRESSION_DESIGN Phases 1–5)

| Phase | Vision layer that turns on | What the player newly feels |
|---|---|---|
| **Phase 1 — One Mode** | The first **Heat Mode** goes live as a real, swappable tool (start with Conduction/Blaze). Mode-coloured numbers appear. | "My fire has a *character* I can carry and swap at Rest-Hearths." |
| **Phase 2 — Full Matrix** | All three Modes + the material **Families** (Bramble/Beast/Slag) and the **Frost-Encased** depth status, composed orthogonally with the behaviour roster into the full **Mode × Family** matrix. | "*How* it attacks and *what it's made of* are different questions — a Bramble Charger ignites on Blaze; a Slag Bomber must be cracked before it pops; a Frost-Encased Lobber must be thawed before its arc lands." |
| **Phase 3 — Kingdoms + panel** | **Kingdoms** (Flora/Fauna/Fungi) as boon-pool identities, biased by the matching rescue, with the identity panel UI. After the respective rescues, **Mode and Kingdom decouple** — cross-pairs like **Sear + Fauna** or **Draft + Fungi** become legal. | "I pick a run *identity*, not just a stat line, and I can mix a Mode with an off-element Kingdom." |
| **Phase 4 — Meta / persistence + World-Stakes v1** | Deeper persistence and the **re-weighted Soil** proposal (dominated by rescued-count + village diversity, GWI a minor term), plus **World-Stakes v1 = a purely economic Cold Snap** (a neglected outer ring goes dormant / loses warmth; **no husks enter the village, no in-village combat**). | "A merciful, diverse world starts *further along the successional sequence*; a plundered world starts genuinely **raw and cold-skyline**." |
| **Phase 5 — Capstone** | The **win** (GWI 1.0 → re-readable epilogue) and post-win destinations, endings that pay off the build, and the reserved 4th **LITHO** solo late-meta role. | "The 10 hours of build expression are legible on the last screen." |

### The frontier & world-map switch-on (extends the phase table)

The worldlines (§4), the run environments (§5), and the World Map & expansion (§6) turn on over the same phases, layered on top of the rows above. Only the Buried Warren descent + its single Warden ship today; every other frontier and craft-Warden is ⟢ VISION.

| Phase | Frontier / world layer that turns on | What the player newly feels |
|---|---|---|
| **Phase 2** | A **biome parameter** on the run map, and the first alternate frontier — the **Frostmarch Tundra** (Agriculture's buried fields, OUT) — standing beside the Buried Warren baseline. The **Glaciated Spire** (Metallurgy's summit forge, UP) begins its climb here. | "The descent isn't the only door — the same run can march *out* into frozen fields or start *up* the Spire." |
| **Phase 2–3** | The **Glaciated Spire** completes (altitude cold-drain, the forge-deep summit and its Cold-Struck Smith), and the **Ashen Wald** (Woodcraft, ACROSS — the Last Wright) switches on, **gated on Blaze / Heat Modes** existing since it lives on player-caused fire-spread. | "Each invention has a *place* now — I climb to the forge, march the fields, or burn a path across the dead Wald." |
| **Phase 4** | The **World Map**, the **expansion spectrum** (federate ↔ annex ↔ cannibalise), and the **Drowned Coast** shared highway (frozen sea, tidal leads, no craft-Warden) turn on above World-Stakes and the re-weighted Soil. | "My village is a *point on a map* that can reach out and relight neighbours — as a web of hearths, one central hub, or by feeding on them." |
| **Phase 5** | **Worldline-gated endings** (each frontier's road tilts which of the five rekindlings you reach) and the **First Hearth / First Warden** capstone every worldline converges on. | "Where I went shaped how the world came back — and the deepest terminus was the same First Hearth all along." |

**Flagged build costs that are NOT hidden:** the **Husk Incursion / watchtower / Long Night** base-defense pivot is a *substantial later phase* beyond World-Stakes v1 — it introduces in-village combat the current builder/farm screen has none of, so it is a real engineering cost, not a threshold flip. Co-op is **greenfield** (none exists yet). And the co-op fiction's ⚑ liberty lives specifically on the **revive** (a guttered spark "flowing back" to be rekindled — combustion has no reverse-propagation), not on lending sparks, which is honest fire-spread.

**Two more flagged costs the frontier layer adds:** the worldlines are a **content multiplier**, not a threshold flip — every added frontier is a full biome of art, roster, and its own craft-Warden, so branching *multiplies* build cost rather than reusing the Warren. And the **World-Map / expansion layer inherits the base-defense pivot** flagged above: reaching out to hold, annex, or defend a relit neighbour is built on that same substantial in-village-combat engineering, never free on top of it.

## Appendix C — Spectacle & Readability Spec

Pillar 1: a system that needs a tooltip isn't finished. Each new system commits to a **visible/audible tell** that reads on screen without explanation.

| New system | How it READS ON SCREEN (the tell) |
|---|---|
| **Cold-Snap dormancy** (World-Stakes v1) | The neglected outer ring **visibly desaturates and frosts over** — colour drains toward grey-blue, hearth-glow shrinks, the warmth clock on that district dims — so "this ring went dormant" is a look, not a number. |
| **Spark-relay revive** (co-op ⟢ VISION) | A guttered companion darkens to an ember-husk; a **visible arc of spark** relays from a living cat and the companion **re-ignites with a flare** — the reverse-flow reads as a bright, deliberate, one-beat event. |
| **Firestorm** (co-op simultaneous combo) | Two heat sources overlap and the arena **blooms into a shared roaring sheet of flame** with a low bass swell — clearly a *two-source* spectacle, distinct from any solo attack. |
| **Thermal Shock** (solo-achievable via sequential Mode swaps) | The struck Frost/Slag solid **spiderwebs with glowing crack-lines** and shatters on a sharp *crack* — the fracture, not a health bar, tells you it worked. |
| **Nutrient-Bloom** (Fungi ⟢ VISION) | An afflicted husk's death sends a **spreading green-gold rhizomorph flush** across the ground that visibly seeds extra materials/Soil — decomposition you can watch return. |
| **The Warden gutter** | The Warden does not bleed — struck, it **guts and dims like a flame starved of air**, silhouette flickering down to embers and out. Extinguishing, never a corpse. |
| **Mode-coloured numbers + family glyphs** | Damage numbers are **tinted by active Mode** (Blaze/ Sear/ Draft each own a hue) and each enemy carries a small **family glyph** (Bramble/Beast/Slag) plus a frost-rime overlay when Frost-Encased — so the Mode × Family read is instant. |
| **Ending-axis reveal** | The final world-seal **stamps an epithet built from your dominant invention and Mode/Kingdom**, reskinning the "Rekindled Commons" into a **Forge-town / Terrace / Hearth-Keep** look with at least one epilogue line naming your build — the last screen shows *which* fire you rebuilt. |
| **Warmth-stain world map** (expansion ⟢ VISION) | Warmth reads as **colour eating white** — a tended world spreads a living stain across the frost — and the *political shape* is legible at a glance: a **web of many small lights** (federate skin), **one bright hub** feeding spokes (annex skin), or a **single lit point** with the rest still white (cannibalise). |
| **Hearth relit / annexed / cannibalised** (world map ⟢ VISION) | On the map a neighbour hearth **flares back to full colour** when relit, **binds to your hub with a warm spoke** when annexed, or **darkens and feeds its glow into yours** when cannibalised — the political choice is a one-beat animation, not a menu line. |
| **Frontier reads: whiteout / altitude-drain / thin-ice** (biomes ⟢ VISION) | Each frontier tells its hazard on sight — the Frostmarch Tundra's **whiteout** swallows the screen edges, the Glaciated Spire's **altitude-drain** bleeds the warmth meter faster the higher you climb, and the Drowned Coast's **thin ice** webs with stress-cracks and opening leads underfoot. |
| **Craft-Warden gutter** (per-frontier ⟢ VISION) | Each frontier's craft-Warden dies the Warden's way — **guttering to embers, never a corpse** — but wears its craft as it goes out: the Cold-Struck Smith dims like a **cooling forge**, the Keeper of the Empty Rows like **rows going white**, the Last Wright like a **fire burning down to ash**, the Unfinished Arch like a **hearth snuffed mid-build** — so "this frontier's Warden went out" is a look, not a kill-count. |

## Appendix D — Accessibility, Open Tuning Knobs & Code Map

### Assist options for the 6-HP glass cat

The real-stakes forfeit needs an accessibility valve — this also offsets any "co-op is safer" perception, since solo players get the same relief.

- **Assist / Story difficulty** — softer incoming damage and forgiveness on the bank-or-forfeit spill, without removing the loop's shape.
- **Optional solo revive token** — a single self-rescue per run so a fall in the dark isn't always a full forfeit (mirrors the co-op revive's mercy for solo players).
- **Telegraph-timing widening** — lengthen the red-danger-zone windup so the tell is readable at slower reaction speeds; parry/dodge windows scale with it.
- **UI scaling** — resize HUD, numbers, and family glyphs for legibility.
- The 6-HP glass-cat stakes remain the **default**; assists are opt-in and never the balance baseline.

### Open tuning knobs (explicitly TBD — not solved)

- **Cold-Snap thresholds** — warmth level at which an outer ring tips dormant.
- **Incursion cadence** — frequency/severity of Husk Incursions (later phase).
- **Spilled-ember recovery window** — how long a co-op spilled satchel is grabbable before room transition.
- **Long Night cadence** — how often / how deep the axial-tilt deepening swings.
- **Exact Soil weights** — the re-weighted formula's rescued-count / diversity / minor-GWI coefficients (the shipped `soil = gwi*0.6 + rescued*0.05` is flagged for replacement).
- **Attunement diminishing-returns curve / cap** — the exact per-element falloff that holds the glass-cat identity.
- **Co-op committed-attacker scaling** — confirming 2P→4, 3P→6 holds ~2.0 pressure per player.
- **Expansion consensus cadence** — how often the world-map consensus/vote to reach out, federate, or annex a neighbour resolves.
- **Community warmth-state thresholds** — the warmth levels at which a neighbouring community reads as lit / guttering / dark (and so becomes relight- or annex-eligible).
- **Biome parameters** — per-frontier tuning: the Frostmarch whiteout drain, the Glaciated Spire altitude cold-drain curve, and the Ashen Wald fire-spread rate.
- **Worldline content-multiplier** — how many frontiers ship per phase, since each is a full biome + craft-Warden (the branching-cost lever).
- **Drowned-Coast tide timer** — the tidal-crack / opening-lead cadence on the frozen-sea highway.

### Code & doc map (orientation, canonical filenames)

| Doc system | Primary file(s) |
|---|---|
| Cat combat: HP, combo, dash i-frames, pounce, guard/perfect parry | `godot/scripts/player.gd` |
| Enemy behaviour roster (Husk/Charger/Lobber/Bomber/Warden), telegraphs, ~2-committed crowd rule | `godot/scripts/enemy.gd` |
| Run structure: node map, room types, gates, satchel, bank-or-forfeit | `godot/scripts/dungeon.gd`, `godot/scripts/run_map.gd` |
| Frontier **biome field** on the run map (selects Warren / Spire / Tundra / Wald and its parameters) | `godot/scripts/run_map.gd`, `godot/scripts/dungeon.gd` |
| Village: clearing, hearth, building lifecycle, farm, quests, warmth | `godot/scripts/village.gd` |
| World map: districts, warmth-stain diffusion, expansion spectrum (federate/annex/cannibalise) | `godot/scripts/world_map.gd`, `godot/scripts/expansion.gd` |
| Neighbouring **community** as an entity (warmth-state lit/guttering/dark, relight / annex / cannibalise) | `godot/scripts/community.gd` |
| Meta state: GWI, Kindle/Bloom, boons, attunements, Soil, save/load | `godot/scripts/game_state.gd` |
| Rescued survivor that trails the player | `godot/scripts/survivor.gd` |
| Codex text, impact-ranking, lore (Long Dark / Warden) | `godot/scripts/lore.gd` |
| HUD, menus, panels, shared UI, localisation, audio | `godot/scripts/hud.gd`, `hud_menus.gd`, `hud_panels.gd`, `ui_kit.gd`, `loc.gd`, `sfx.gd` |
| Vision layer (Heat Modes, Kingdoms, Families, matrix, deep biomes) | `VISION.md` |
| Current-build design of record | `GAME.md`, `DESIGN.md` |
| Phase 1–5 switch-on plan | `PROGRESSION_DESIGN.md` |
| Village lifecycle / building design | `VILLAGE_DESIGN.md` |
| Standing critique + QA findings driving the roadmap | `CRITIQUE.md`, `QA_REPORT.md` |

Note: the Codex is **displayed impact-ranked** (canon) in `lore.gd`; the player's **recovery history** — locked/unlocked state plus a "recovered on run N" stamp — is a **separate channel** carried in `game_state.gd`, never conveyed by list position. The expansion layer's federate / annex / cannibalise differences ride this same recovery/lit-state channel and the world-map's political geometry (`world_map.gd`, `expansion.gd`), plus population — **never** by adding deletable entries or per-community dialects to the fixed, impact-ranked invention ledger.

