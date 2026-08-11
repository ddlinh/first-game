# REKINDLED — QA & Design Review Report #1

*Role: Game Critic & QA Specialist · Date: 2026-08-11 · Build: `main` @ 3c028d8 + uncommitted rewrite*
*Scope: full source review (all `godot/scripts/*.gd`, shaders, project config, design docs) + headless import check.*

**How to use this file:** each finding has a stable ID. Update the `Status`
column as work lands (`Open` → `In progress` → `Fixed @ <commit>` / `Won't fix (reason)`).
Severity: **S1** breaks the game's core promise · **S2** major flaw, iterate soon ·
**S3** quality/polish · **S4** nit/hygiene.

---

## 0. Verdict in three sentences

The vertical slice is technically solid — it imports clean, the 2.5D
presentation kit, camera rig, and HUD are genuinely well-engineered, and the
full loop (village → run → rescue → build → warmth) does run end-to-end. But
the *roguelite promise is currently fake*: loot and rescues bank instantly and
death costs nothing, so the advertised "push deeper or bank" tension does not
exist, and there is no fail state, no win state, and no cross-run difficulty —
the game trends to trivial by descent three. The next iteration should spend
almost entirely on **stakes, scaling, and combat readability** (F-01…F-05)
before any new content is added.

---

## 0b. Milestone 1 — DELIVERED (2026-08-11, "Real Stakes + Visible Village")

Implemented, compiled clean (`godot --headless --import`), and verified on screen
via the capture harness. **16 findings** addressed (10 fully, 6 partially).

**Stakes (the fake-loop, F-01/F-02/F-06):** a run **satchel** holds unbanked loot
(shown in the combat HUD); it banks only on a live HOME exit and **forfeits 75% on
death**. A proper **death state** freezes + collapses the hero (was controllable for
1.6 s). A **run-summary card** ("RUN BANKED" / "YOU FELL IN THE DARK") gives each
run an arc.

**Visible world (F-18/F-20/F-21/F-22/F-23/F-26):** the second full-screen grade
overlay is gone — warmth now drives the one grade live *and* physical objects: dead
trees leaf out, the bonfire grows, buildings glow. A **placement grid + cell box**
shows where builds land; every structure is feet-anchored + shadowed; empty crop
plots show tilled soil; an **objective chain** guides the build phase.

**Balance & HUD (F-09/F-16/F-17/F-25/F-28/F-29):** duplicate-rescue exploit closed;
gate previews show the true captive; builder count fixed; HUD banner-stacking + heart
overflow + stale-chrome bleed fixed; attunements rebalanced; XP curve slowed ~2.7×
and the mid-fight full-heal removed.

**Verification via adversarial review.** A 4-dimension multi-agent review
(correctness / GDScript-4.7 / render / lifecycle) over the diff found **10 confirmed
defects the screenshot pass missed** — all fixed and re-verified:
- **BLOCKER:** `enter_village()` never cleared `_dead`, so the hero returned home a
  frozen corpse → **softlock after the first death.** (Runtime-confirmed fixed:
  `AFTER_DEATH _dead=false`.)
- **MAJOR:** the thaw grabbed the tree's *shadow* sprite, not its body, so trees
  never actually greened over.
- **MINOR ×8:** empty rooms skipped the cleared-tally/beacon; objective stale after
  plant/harvest; bonfire light fought its flicker tween; deeper-room advance leaked
  velocity/i-frames; foe-tally fade bled across rooms; run-map overlay could stick
  over the village.

**Deferred to later milestones (per §5):** combat depth (F-04/F-05), cross-run
scaling (F-03), in-run build variance / EMBERGROWTH (D-01), audio (F-15), iso-distance
debt (F-10/F-11/F-12), save/load (F-07), the knowledge layer (D-06/F-08), dungeon
art pass (F-24), win-state (F-02 remainder).

---

## 0c. QA Validation Pass #2 (2026-08-11, post-Milestone 1) — VERDICT

Independent re-verification of every "Fixed (M1)" claim: code re-read of the
actual wiring (not the changelog), fresh capture run (`_shot_01…_shot_14`,
regenerated post-fix), and a repaired test for the one path that had silently
lost coverage.

**Confirmed fixed on evidence: 10 / 16 fully, 5 partially — no M1 claim was
found to be false.** Highlights of the evidence chain: zero `add_resource`
calls remain in dungeon.gd (all loot → satchel); `AFTER_DEATH _dead=false`
runtime probe + collapse/revive frames; cold-vs-warm frames now unmistakable;
placement grid on screen; post-level-up HP `10/11` proves the full-heal removal;
the character sheet's ×1.24 damage independently confirms the rebalance math.

**Validation itself caught 3 issues** (this is why QA re-checks):
1. **Stale test masking a coverage gap** — the harness's 13-XP award no longer
   crossed the new 32-XP threshold, so the coalesced level-up banner had *never
   been exercised*. Fixed the harness (35 XP → single banner; 245 XP → crosses
   two levels); both paths now verified on screen, including the coalesced
   **"EMBER LEVEL 2 → 3"** card (`_shot_08`).
2. **Tip bleed across layer swaps** — a village tip ("Empty soil…") faded out
   over the dungeon, overlapping the intro dialogue. The swap-cleanup cleared
   toasts + banners but not tips. Fixed in `set_combat` and re-verified.
3. **Doc drift** — GAME.md still describes the pre-M1 rules (F-31).

New findings filed: **F-30…F-34** (all S4 polish — dead shader file, doc drift,
banner slot spacing, salvage rounding, empty-room fanfare). Nothing regressed;
the milestone stands. Recommended next: commit M1 (F-19), then GAME.md sync
(F-31) alongside whichever next phase the producer picks from §5.

---

## 0d. Milestone 2 — DELIVERED (2026-08-11, "A Loop Worth Repeating")

The QA report's stated **#1 existential risk** — *no per-run variance* (**D-01**,
"the biggest design risk", "fatal if unfixed") — addressed by shipping
**EMBERGROWTH Phase 0** from `PROGRESSION_DESIGN.md` §4.1/§8.0/§9. Compiled clean
(`godot --headless --import`, exit 0), verified on screen via the capture harness,
and driven end-to-end by the autoplay bot (drafts boons across a full loop, no
deadlock).

**The missing organ — drafting (D-01/D-04).** Every husk kill now feeds run-scoped
**Kindle** instead of persistent XP; crossing a threshold `[0,8,20,40,70]` triggers
a **Bloom** — a succession stage-up (Ash→Pioneer→Herb→Thicket→Canopy) that grants a
flat stat step **and a paused pick-1-of-3 boon card** (the run's build identity).
Blooms/boons **reset each descent**, so runs finally diverge. The boon overlay is
`PROCESS_MODE_ALWAYS` + `MOUSE_FILTER_STOP` with no cancel (a click can't fall
through to a sword swing; the run can't stall un-paused); multi-Bloom kills queue
cards and resolve them one at a time.

**The double-scaling trap, closed (F-03 / §8.0).** The persistent Ember-Level
stat growth (`apply_ember_level` + the per-level bump in `_on_ember_level_up`) is
**retired** — with F-03's `run_count` husk-scaling now live, keeping it would have
double-scaled the hero. Stats mutate in exactly **one place per source** now
(`_bloom` / `apply_boon` / `apply_buff` / `_seed_from_soil`). `CRIT_CHANCE` became a
var so crit boons work.

**Meta that isn't a parallel currency (§3 pillar 3).** Persistent power flows from
**Soil** = `clamp(gwi*0.6 + rescued*0.05, 0, 1)`, which seeds each run's starting
succession stage — a warm, populous village literally begins further up the food
web. No new currency; GWI + rescues *are* the meta.

**On screen (§6 feedback).** Combat HUD: a **Kindle bar with 5 succession notches**
+ a stage label, self-polled (same idiom as the dash pip). The hero wears a
**succession aura** that swells per Bloom ("burn hotter"); the dungeon **grade warms
a notch per stage** and survives room-to-room advances. Character sheet (**C**) now
reads succession stage / Soil head-start / drafted boons / true crit%. Run-summary
card reports **Kindle gathered + Blooms** in place of the retired XP.

*Screenshots regenerated (`_shot_07_bloom_boon`, `_shot_08_character_sheet`,
`_shot_11_run_summary`): the "CHOOSE A BLOOM" draft, the char sheet showing
`Succession PIONEER (stage 1)` + `Keen Eye` boon + `Crit 29%`, and `Kindle gathered
+46 / Blooms 3`.*

**Findings moved:** **D-01** Fixed (M2) · **D-04** Fixed (M2, drafting adds the
verb the old +number growth lacked) · **F-03** the §8.0 half resolved (cross-run
husk scaling by `run_count` was already live; the double-scaling reconciliation is
now done) · **F-31** doc drift closed (GAME.md progression section rewritten to the
Kindle/Bloom/Soil rules). **Deferred (later EMBERGROWTH phases):** Modes/Kingdoms/
family matrix (Phase 1–3), cold-drain (§4.1 flag), save/load (F-07, Phase 4).

---

## 0e. Milestone 3 — DELIVERED (2026-08-11, "Knowledge Changes How You Play")

The **Purpose** phase (§5 step 6): make the loop *about* the vision — *rescue people
→ recover knowledge → knowledge changes how you play → the world warms*. Compiled
clean, verified on screen (`_shot_08`, `_shot_15_codex`), and driven end-to-end by the
autoplay bot (build → descend with village boons → fight → Bloom → draft) with zero
runtime errors.

**Village → run coupling, at last (D-02).** The three buildings stopped being inert
warmth-tickers and became **recovered inventions that change the descent**: the
**Forge → Metallurgy** (+8% damage each), the **Cabin → Construction/Shelter** (+1 Max
HP each), the **Crop Bed → Agriculture** (a **Provision** each — a heal charge the cat
auto-eats when badly hurt, so the farm's yield literally keeps you alive underground).
Applied once per fresh descent atop the reset baseline + attunements; announced by a
"The village provides:" toast and read in the char sheet (`_shot_08`: Damage ×1.20 =
forge +0.08 & Pioneer bloom +0.12; Max HP 9 = base 6 + cabin +1 + Bramble Ward +2;
Provisions x1 with a bottom-left pip). One-way coupling → two-way.

**Cabin-spam dissolved (F-13).** Each run effect is capped (3) **and** duplicate
buildings now give **diminishing warmth** (`base_gwi / N`), so a *diverse* village
warms faster and fights better than spamming cabins — building choice is a real
decision. Food gains a run-side purpose (Provisions) on top of the farmer quest.

**Knowledge, finally played (F-08 / D-06 K-0+K-1).** Raising a craft — or rescuing its
survivor — **recovers its invention**: the Ember speaks one honest line on *why it
changed the world*, and it enters the **Codex** (new key **K**, `Lore.gd`). The Codex
(`_shot_15_codex`: "THE EMBER'S MEMORIES · 3/4") holds real, science-vetted paragraphs
written to the PROGRESSION_DESIGN §7 standard — the Neolithic surplus, metallurgy as
applied thermodynamics (the same heat the Ember carries), the load-bearing arch — each
with its liberties flagged; undiscovered entries read as `? ? ?`. The knowledge layer,
graded **"D on screen / A− on paper"** in this report, is now *on screen*.

**Findings moved:** **D-02** Fixed (M3) · **F-13** Fixed (M3, diminishing GWI + food
sink + distinct building effects) · **F-08** Fixed (M3, the K-0 pilot) · **D-06** Fixed
(M3, K-0+K-1 shipped; K-2 invention-tree / K-3 EMBERGROWTH-boons-as-discoveries still
to come) · **D-03** further reduced (a real village build-decision now exists).
**Not yet verified by an independent adversarial pass** (the M2/M3 review agents were
stopped); self-verified via import + capture + autoplay.

---

## 0f. Milestone 4 — DELIVERED (2026-08-11, "A Loop Worth Mastering")

The **Challenge** phase (§5 step 3) — *close it out*. The combat-depth code
(telegraphs, four husk behaviours, guard-stamina/parry, ground-distance steering)
had been written in the working tree but was never verified or closed. This
milestone hardened it, verified it, ran it past an adversarial review, and closes
**F-04 / F-05 / F-10 / F-11**.

**New — attack-commitment (hardening F-04).** A room of five husks used to be able to
telegraph and lunge **all at once** — the exact "unreadable slot machine" F-04 exists
to prevent, re-created at crowd scale. Added a commitment token: at most **2**
non-warden husks may be mid-attack at a time; the rest hold at range and menace; the
Warden is exempt. Crowded rooms are now *readable* (verified on screen, `_shot_16`:
two husks with glowing wind-up rings flanking the hero, the others waiting).

**Adversarial review found & fixed 6 bugs in the existing combat code** (this is why
the code hadn't been safe to close):
1. **Charger self-stunned on ANY collision** (`get_slide_collision_count() > 0`) — so
   it aborted its rush on an ally husk or the hero, not just a wall. Now wall-only
   (`_hit_a_wall`: collider is not a `CharacterBody2D`), and uses `stun()` so the
   punish window shows the readable cyan "stun" cue (fixes review 1 **and** 6).
2. **Lobbers bypassed the commit gate but still consumed its slots** → froze melee
   husks unpredictably. The budget now counts melee-only.
3. **The Warden counted against the husk budget** (spec: exempt) → boss rooms were
   quieter than intended. Now excluded from the count.
4. **The Warden shockwave hit through walls** and lacked a dead-player guard. Now a
   line-of-sight raycast (env layer, excluding self + hero) blocks it through cover,
   plus a `_dead` guard. (Probe-verified: adjacent → damage, far/blocked → none, no
   physics error.)
5. **Enemy speed scaled uncapped** — base husks passed the hero's 220 at deep meta,
   killing the kite counterplay. Capped base at 200 (the charger's ×1.15 rush can
   still catch you).

**Explicitly probed clean by the review:** the commitment token cannot deadlock a
room (kills, not attacks, clear it; a parried/killed attacker never leaks a slot);
guard/parry has no free-unbreakable-guard exploit and correctly interrupts a
wind-up; provisions auto-eat never fires on a killing blow; and combat steering is
fully ground-distance (F-10/F-11) — the only screen-space `distance_to` left is the
non-combat guidance-beacon pick.

**Findings moved:** **F-04** Fixed (M4 — telegraphs + guard cost + commitment
readability) · **F-05** Fixed (M4 — four verified behaviours, charger/warden bugs
corrected) · **F-10** Fixed (M4 — enemy steering on `Iso`) · **F-11** Fixed (M4).
Combat now has *depth worth mastering*: bait the commit, punish the recovery, parry
the tell. **Deferred:** the win-state beat (F-02 remainder), audio (F-15), save/load
(F-07).

---

## 0g. Milestone 5 — DELIVERED (2026-08-11, "Readability & Fairness Debt")

The **Readability & fairness** phase (§5 step 5) — closed out. Most of it was
already coded (F-10/F-11 verified in M4, F-17 in M1); this pass verified the rest,
fixed the one genuinely-open behavior bug, and swept the fixed-in-code polish so the
status column stops lying.

**F-12 (companions keep up) — verified & closed.** The follower already scales its
speed off the hero's *live* speed (`max(235, base_speed × speed_mult × 1.15)`) with a
catch-up snap at `gd > 340 px` (`survivor.gd:160-171`) — and, importantly, this holds
up against the M2/M3 speed inflation (Fleetfoot boons + builder attunement + Bloom
speed steps can push the hero well past a fixed 235; the ×1.15-of-live-speed margin
tracks it). Ground-distance throughout (F-10).

**F-25 remainder (intro ran mid-fight) — FIXED.** The first-descent intro dialogue
played while the room's husks were already attacking, and a click that advanced a
line also swung the sword. Now the intro **freezes the fight**: husks stop their AI in
place, the hero is untouchable and can't attack, all symmetrically undone when the
dialogue ends. Probe-verified: *during* → `frozen_husks=5/5, combat_enabled=false,
invuln big`; *after advancing* → `frozen 0/5, combat_enabled=true, invuln≈0`.

**Fixed-in-code polish, verified & closed:** **F-30** — `shaders/gwi.gdshader` is gone
(only `post.gdshader` remains). **F-32** — banner slot pitch is 78px (clears a
two-line card). **F-33** — death salvage rounds on the satchel *total*, not per
material.

**Findings moved:** **F-12** Fixed (M5, verified) · **F-25** Fixed (M5, the last
sub-item — intro no longer overlaps combat) · **F-30 / F-32 / F-33** Fixed (M5,
verified). With F-10/F-11/F-17 already done, **§5 step 5 is complete**. The capture
harness now skips the (freezing) tutorial intro so it shoots real post-tutorial
combat.

---

## 1. Summary table

| ID | Severity | Area | Title | Status |
|---|---|---|---|---|
| F-01 | **S1** | Core loop | Risk/reward loop is fake: loot & rescues bank instantly, death penalty is zero | **VERIFIED (QA#2)** — zero `add_resource` left in dungeon.gd; satchel lifecycle confirmed in code + on-screen chip |
| F-02 | **S1** | Core loop | No fail state and no win state | **Partly fixed, VERIFIED (QA#2)** — both summary cards confirmed on screen (`_shot_11`, `_shot_13`); win-state still open |
| F-03 | **S1** | Balance | Difficulty never scales across runs while Ember Level grows unbounded | **Fixed (M2)** — husks scale with `room+run_count`; the unbounded Ember Level is *retired* for run-scoped Kindle/Soil (§8.0 double-scaling closed) |
| F-04 | **S2** | Combat | Parry/guard system unreadable: no telegraphs, costless guard | **Fixed (M4)** — telegraphed wind-ups, guard-stamina + guard-break, and an attack-commitment token so crowds stay readable (`_shot_16`); 6 review bugs fixed |
| F-05 | **S2** | Combat | Enemy roster is one behavior (chase + touch) with stat variants | **Fixed (M4)** — four verified behaviours (husk / charger / lobber / warden), incl. wall-only charger self-stun and a no-through-wall Warden shockwave |
| F-06 | **S2** | Bug | Player stays controllable/attackable for 1.6 s after death; no death state | **VERIFIED (QA#2)** — collapse on screen (`_shot_13`); runtime probe `AFTER_DEATH _dead=false`; upright + clean tint after revive (`_shot_14`) |
| F-07 | **S2** | Meta | No save/load — all progress lost on quit (known, deferred) | Open |
| F-08 | **S2** | Vision | Civilizational-invention layer absent from playable content | **Fixed (M3)** — buildings/rescues are now named inventions (Agriculture/Metallurgy/Construction) with an Ember "why it mattered" line + a Codex entry; each changes a run verb |
| F-09 | **S3** | Bug | Duplicate-rescue exploit: re-freeing a rescued pillar stacks its buff again | **VERIFIED (QA#2)** — `already` guard confirmed before `add_rescued`; dup path routes to satchel |
| F-10 | **S3** | Bug | Ground-distance rule broken in Enemy & Survivor (screen-space `distance_to`) | **Fixed (M4, VERIFIED)** — Enemy steering/ranges on `Iso.gdist/step/gdir`; review confirmed the only `distance_to` left is the non-combat beacon pick |
| F-11 | **S3** | Bug | `Iso.vel()` never used — N/S movement covers 1.6× more ground than E/W | **Fixed (M4)** — Player/Enemy velocity go through `Iso.vel()`; N/S and E/W cover equal ground |
| F-12 | **S3** | Bug | Followers can't keep up with Gale Step hero (235 < 264 px/s), no catch-up | **Fixed (M5, VERIFIED)** — follow speed = `max(235, base×mult×1.15)` tracks the hero's live (M2/M3-inflated) speed; catch-up snap at gd>340px; ground-distance |
| F-13 | **S3** | Economy | Food is a dead-end resource; cabin-spam is the dominant GWI strategy | **Fixed (M3)** — duplicate buildings give diminishing GWI, each type now has a distinct run effect, and food converts to Provisions (a real sink) |
| F-14 | **S3** | Content | Village goes inert after 3 one-off quests | Open |
| F-15 | **S3** | Audio | Zero audio in the entire project | Open |
| F-16 | **S4** | UX | Rescue gate preview always shows the farmer icon | **VERIFIED (QA#2)** — pillar assigned at map-gen (after `_ensure_type`), read by gate/room |
| F-17 | **S4** | Quest | Builder quest counts the pre-seeded crop bed (3 needed = 2 real) | **VERIFIED (QA#2)** — `seeded` flag excluded in `built_count` |
| F-18 | **S4** | Visual | Village GWI wash & Main post-process both on CanvasLayer 1; bloom never sees the warmth tint | **VERIFIED (QA#2)** — zero `gwi.gdshader` references remain in scripts (dead file → F-30) |
| F-19 | **S4** | Hygiene | Orphan `tools/smoke.gd.uid`; large uncommitted deletion set; `seed` param shadows built-in; camera comment contradicts `SHAKE_ROT=0` | **Partly fixed (M1)** — orphan removed, `seed`→`salt`; commit + camera comment still open |
| F-20 | **S2** | Build UX | No placement box/grid: build ghost has no cell outline, footprint box, or grid overlay | **VERIFIED (QA#2)** — grid + hovered-cell box on screen (`_shot_12`) |
| F-21 | **S2** | Visual | Buildings/crops/gates are centre-anchored, shadowless sprites — they float, overlap the stream, y-sort wrong; empty farm plots are invisible | **VERIFIED (QA#2)** — structures grounded + shadowed on screen; tilled-soil draw confirmed in code |
| F-22 | **S2** | Village UX | Village-building scenario unclear: no goal chain, buildings show no function, objective line static | **Partly fixed, VERIFIED (QA#2)** — objective chain live on screen (`_shot_01`), forge/cabin glow; villager-to-building AI still open |
| F-23 | **S2** | Theme | Cold and warm village are visually indistinguishable — the "world visibly thaws" fantasy isn't landing on screen | **VERIFIED (QA#2)** — cold vs warm frames now unmistakable (`_shot_01` vs `_shot_02`): trees leaf out with fruit, bonfire grows, grade warms |
| F-24 | **S3** | Visual | Dungeon reads flat: walls are lighter floor tiles with no vertical face; floor-variation & decal art (crack tiles, rubble, bones, wall_block, edges) exists but is unused | Open |
| F-25 | **S3** | UI | HUD collisions & spam: permanent controls card overlaps hearts; heart row overflows/clips at high max HP; level-up banners stack 5-deep; stale toasts persist across layer swaps; intro dialogue runs during combat | **Fixed (M5)** — hearts numeric, coalesced banners, no stale chrome, tip-bleed fixed; the last sub-item (intro-during-combat) is closed: the first-descent intro now **freezes the fight** (husks hold, hero untouchable + can't swing) until dismissed |
| F-26 | **S4** | UI | Warmth-meter flame reads as a water droplet at low GWI; Supply Gate art reads as a crate, not a descent | **Partly fixed, VERIFIED (QA#2)** — flame reads as fire at GWI 0 (`_shot_01`); gate sprite art still a plank |
| F-27 | **S4** | Branding | Title "REKINDLED" sits in a crowded Steam name-cluster; *Rekindled Trails* (2025) overlaps thematically (fire companion + rebuilding ruined towns) | Open |
| F-28 | **S3** | Balance | Attunements are wildly unbalanced: Ember Fang (+50% dmg) strictly dominates Gale Step (+20% speed) and Bramble Ward (+2 HP) — rescue priority is a solved problem | **VERIFIED (QA#2)** — values consistent in both `ATTUNEMENTS` and `apply_buff`; sheet shows ×1.24 stacking correctly |
| F-29 | **S3** | Balance | Ember XP pacing inflates (LV 5 by chamber 3 in a bot run) and each level grants a full heal — a Warden kill's +30 XP chains multiple free full heals mid-fight, deleting attrition | **VERIFIED (QA#2)** — behaviorally proven: post-level-up HP reads `10/11`, not full (`_shot_08`); LV 3 at 245 XP on the slowed curve |
| F-30 | **S4** | Hygiene | `shaders/gwi.gdshader` (+ `.uid`) is now a dead file — zero references after the F-18 fix | **Fixed (M5)** — file removed; only `post.gdshader` remains in `shaders/` |
| F-31 | **S4** | Docs | GAME.md drift: still documents +50% dmg / +20% speed attunements, "full heal" on level-up, and instant loot banking — the satchel/death-forfeit rule (now the game's central mechanic) is undocumented | **Fixed (M2)** — GAME.md progression section rewritten to the Kindle/Bloom/Soil rules; attunement values already synced in code |
| F-32 | **S4** | UI | Banner stack slots (62 px) are tighter than a banner with a subtitle — simultaneous banners slightly overlap (`_shot_07`: level card clips the attunement card's subtitle) | **Fixed (M5)** — slot pitch raised to 78px, clears a title+subtitle card |
| F-33 | **S4** | Balance | Death salvage `floor(n × 0.25)` per material rounds 1–3 of a kind to zero — early-game deaths salvage "nothing" despite the advertised 25%; consider rounding on the satchel total | **Fixed (M5)** — salvage rounds on the satchel TOTAL then distributes; ≥1 kept whenever anything was carried |
| F-34 | **S4** | UX | Empty rooms (treasure/rest with 0 husks) now fire the full "Chamber cleared!" fanfare + toast on *entry* — side effect of the empty-room tally fix; consider a quieter path for never-sealed rooms | Open (QA#2) |

Verified clean: headless import (no script errors), interaction protocol
consistency, HUD null-guarding, bake-cache design, tween/timer validity guards,
combo state machine reset paths, camera-bounds clamping.

---

## 2. Findings in detail

### F-01 · S1 · The risk/reward loop is fake
**Where:** [dungeon.gd:477](godot/scripts/dungeon.gd:477) (`Pickup._on_body_entered` → `GameState.add_resource` immediately), [survivor.gd:115](godot/scripts/survivor.gd:115) (`GameState.add_rescued` at the moment of freeing), [main.gd:380](godot/scripts/main.gd:380) (`_on_player_died` → plain `return_to_village`, everything kept, then full heal in `enter_village`).
**What the docs promise:** GAME.md §2/§5 — "take the HOME gate to *bank* the run", "deeper for richer, harder rooms".
**What the code does:** every pickup is banked into persistent state the frame you touch it; rescues are banked on free; dying returns you home with all of it plus a free full heal. Taking the HOME gate and dying are mechanically identical outcomes.
**Impact:** the central roguelite decision — the reason the branching map, HOME gate, and "carry hp forward" exist — has no teeth. Players will (correctly) learn that dying is a fast-travel button.
**Recommendation:** introduce a *run satchel*: pickups go to a run-scoped inventory shown in the ruins HUD; the HOME gate banks it; death forfeits most of it (keep a pity fraction, e.g. 25–50%, this is a cozy-leaning game). Keep rescues banked on exit-alive-only *or* keep them safe but make the survivor visibly "carried" — pick one and make the rule loud. This one change retroactively justifies half the systems already built.

### F-02 · S1 · No fail state, no win state
**Where:** death handling ([main.gd:380](godot/scripts/main.gd:380)); GWI cap ([game_state.gd:163](godot/scripts/game_state.gd:163) clamps to 1.0 with no listener for reaching it).
**What happens:** hitting GWI 1.0 changes a shader uniform and nothing else. Dying costs 1.6 seconds. There is no run summary, no ending beat, no game over.
**Impact:** sessions have no arc; motivation collapses once the novelty of the loop wears off (~15–25 minutes).
**Recommendation (cheap first pass):** (a) a *run summary card* on every return (rooms cleared, loot banked/lost, rescues, XP) — one HUD panel, huge perceived-value; (b) a scripted "the world thaws" celebration + credits-tease at GWI 1.0; (c) death shows the summary with what was forfeited (pairs with F-01).

### F-03 · S1 · Cross-run difficulty is flat while the player grows without bound
**Where:** enemy scaling uses only `room_index` ([dungeon.gd:293-294](godot/scripts/dungeon.gd:293), hp `4 + (room-1)`, speed `100 + 10·(room-1)`); `GameState.run_count` is never consulted for difficulty; Ember Level adds +1 HP/+8% damage per level forever ([player.gd:57-58](godot/scripts/player.gd:57), reapplied at [main.gd:319](godot/scripts/main.gd:319)).
**Impact:** every new descent starts at the same difficulty while the hero snowballs (plus up to +2 HP/+50% dmg/+20% speed attunements). By run 3 the finisher one-shots rooms. The game's own progression doc calls this out (PROGRESSION_DESIGN §8.0) and prescribes the fix — reconcile before adding EMBERGROWTH, or the two systems will double-scale.
**Recommendation:** short-term, scale husk hp/count/speed with `run_count` (and consider a soft cap or diminishing Ember curve). Long-term, follow PROGRESSION_DESIGN Phase 0 exactly: repoint per-kill XP into run-scoped Kindle and let *Soil/GWI* carry the meta, so per-run challenge is designed, not accidental.

### F-04 · S2 · Parry and guard don't work as designed systems
**Where:** contact damage fires with zero telegraph on a 0.8 s internal cooldown ([enemy.gd:92-95](godot/scripts/enemy.gd:92)); perfect parry = guard raised within 0.18 s *before* an untelegraphed tick ([player.gd:523-531](godot/scripts/player.gd:523)); guard has no cost, no break, no facing arc.
**Impact:** the "hardest freeze in the game" moment is effectively a slot machine — there is nothing on screen to react *to*. Meanwhile hold-RMB blocks all contact damage from any direction at only a speed penalty, so cautious play is degenerate.
**Recommendation:** give husks a real attack: a 0.3–0.4 s windup pose (lean-back + flash — the analytic pose system already supports this) followed by a lunge, and make *that* the parryable hit; keep plain contact as chip damage that guard merely reduces. Add a guard cost (stamina, or guard-break stun on N absorbed hits). This is the single highest-leverage combat-feel fix.

### F-05 · S2 · One enemy behavior carries the whole game
**Where:** [enemy.gd](godot/scripts/enemy.gd) — Husk and Warden share the identical chase-and-touch brain; only stats and sprite differ ([dungeon.gd:301-313](godot/scripts/dungeon.gd:301)).
**Impact:** every room, every depth, every "type" plays the same; the branching map's room variety is cosmetic. Boss fight = bigger hp bar.
**Recommendation:** two new behaviors buy the most variety per line of code: a *lobber* (stationary, arcing projectile — forces movement) and a *charger* (telegraphed straight rush — feeds the parry from F-04). Give the Warden one pattern (e.g. charge + shockwave ring on wall hit). The family/mode matrix in PROGRESSION_DESIGN will need these hooks anyway.

### F-06 · S2 · No death state — the corpse keeps fighting
**Where:** [player.gd:541-543](godot/scripts/player.gd:541) latches `_dead` but disables nothing; [main.gd:380-387](godot/scripts/main.gd:380) waits 1.6 s on a timer.
**Repro:** die adjacent to husks → you can still move, dash, attack, pick up loot, and take further hits (hp goes negative, each hit re-triggers hurt juice) until the timer fires.
**Recommendation:** on `died`: set `combat_enabled = false`, zero input, play a collapse pose (reuse the enemy dissolve idiom), make the hero non-targetable (leave "player" group or add an `_invuln = INF`). Pairs with the F-02 death summary.

### F-07 · S2 · No persistence (known, deferred — keep it visible)
**Where:** [game_state.gd](godot/scripts/game_state.gd) — everything in-memory; PROGRESSION_DESIGN §4.3 already flags it ("session-only until save/load is added", scoped Phase 4).
**Impact:** for a meta-progression game, quitting = wiping the save. Fine for a dev slice; fatal for any external playtest.
**Recommendation:** don't wait for Phase 4's full design — a 30-line `ConfigFile` dump of `resources/rescued/grid/gwi/xp/run_count/village_radius/quests/tips_seen` on quit + load on boot unblocks playtesting now.

### F-08 · S2 · The stated core vision isn't in the game yet
**Where:** content-wide. The vision (see [VISION.md](VISION.md)) centers on *essential, world-changing inventions*; the playable slice's knowledge layer is three generic buildings (cabin/forge/crop bed) and three fetch quests.
**Impact:** nothing currently teaches or even names an invention; the "civilisation lives in knowledge" premise is told (Ember dialogue) but never played.
**Recommendation:** pilot the invention layer through what exists: rename/reframe buildings and quests as *recovered knowledge* — e.g. the Farmer's quest arc = **Agriculture** (crop rotation unlocks a 2nd harvest), the Smith's = **Metallurgy** (iron tools upgrade your claws visibly), the Builder's = **Load-bearing construction** (expansion gets cheaper). Each unlock gets one Ember line on *why it changed the world*. This is re-skinning + copy, not new systems — a cheap first proof of the vision. Grow it later into the EMBERGROWTH boon pool (boons as inventions/discoveries fits Hades' boon fantasy perfectly).

### F-09 · S3 · Duplicate-rescue buff stacking
**Where:** [dungeon.gd:276-284](godot/scripts/dungeon.gd:276) (`_pick_rescue_pillar` falls back to an already-rescued pillar once all three are home) + [survivor.gd:114-119](godot/scripts/survivor.gd:114) (`apply_buff` is called unconditionally; only `add_rescued` dedups).
**Repro:** rescue all 3 pillars → enter any rescue room → free the duplicate → gain another +50% damage (or +2 HP / +20% speed) for this run, and another every rescue room after.
**Impact:** inconsistent with the once-per-pillar rule Main re-applies at run start; snowballs F-03.
**Recommendation:** either skip the buff when `GameState.has_rescued(pillar)` and grant materials instead ("they bring supplies"), or make duplicate rescue rooms roll treasure. Decide, then also fix the gate preview (F-16) to match.

### F-10 · S3 · Screen-space distances in Enemy and Survivor break the 2.5D contract
**Where:** [enemy.gd:80-95](godot/scripts/enemy.gd:80) (`to_player.length()`, `dist < 22.0`, straight `normalized()` steering); [survivor.gd:151-153](godot/scripts/survivor.gd:151); [survivor.gd:166](godot/scripts/survivor.gd:166) (tip range).
**Impact:** DESIGN.md rule 2 ("distances are ground distances… or every range becomes an egg") is violated by the two most common actors: husk touch range is ~22 ground px horizontally but ~35 vertically — husks "reach" you visibly early when approaching from above/below.
**Recommendation:** use `Iso.gdist` for the range check and `Iso.step(global_position, player.global_position, speed)` for steering, mirroring what `player._do_attack_hit` and `Main._scan_interaction` already do correctly.

### F-11 · S3 · `Iso.vel()` is documented but never called
**Where:** [iso.gd:46-49](godot/scripts/iso.gd:46) exists; Player ([player.gd:207](godot/scripts/player.gd:207)), Enemy, Survivor all set isotropic screen-space velocity. DESIGN.md §1 claims "actors compress the Y of their velocity with `Iso.vel()`".
**Impact:** vertical movement covers 1.6× the *ground* distance of horizontal movement per second. It's symmetric across actors so it's not unfair, but it warps the game: kiting north/south outranges everything, dash distance is direction-dependent, and the tuned dead-zone/aim feel differs by axis.
**Recommendation:** decide once: (a) adopt `Iso.vel()` everywhere and retune speeds (+the dash), or (b) declare screen-space movement canon and fix DESIGN.md/iso.gd docs. Don't leave code and contract disagreeing — the next actor written will pick a side at random.

### F-12 · S3 · Companions fall behind a buffed hero
**Where:** [survivor.gd:17](godot/scripts/survivor.gd:17) `speed := 235` ("must beat the hero's") vs hero 220 × 1.2 (Gale Step) = 264, ignoring dash (440) entirely.
**Impact:** with the builder rescued, freed survivors trail out of frame for whole rooms; the emotional payoff of the escort reads as abandonment. (They do survive room transitions via the companion group, so it's cosmetic-but-loud.)
**Recommendation:** scale follow speed off the hero's live speed (`player.base_speed * player.speed_mult * 1.15`) and add a cheap catch-up teleport when `gdist > ~340 px` or off-screen for >2 s (standard escort idiom).

### F-13 · S3 · Economy dead ends
**Where:** food's only sink is the farmer quest ([village.gd:31-34](godot/scripts/village.gd:31)); GWI sources are unbounded identical buildings ([village.gd:22-26](godot/scripts/village.gd:22)).
**Impact:** after the farmer quest, farming is pointless (GAME.md's "food/seeds sustain the loop" isn't implemented — nothing eats). Cabin-spam (5 wood → +0.18 GWI) dominates every other warmth source; building choice is fake.
**Recommendation:** give food a drain (villagers consume 1 food per run-day; fed villagers work faster / grant a run blessing — ties into F-08's knowledge framing), and add diminishing GWI per duplicate building type (or per-type caps: warmth wants a *diverse* village).

### F-14 · S3 · The village goes inert after ~3 turn-ins
**Where:** [village.gd:767-790](godot/scripts/village.gd:767) — quest chain is `new → active → done`, then villagers only emit a thanks toast forever.
**Impact:** the "villagers send you back down with purpose" loop (GAME.md §7) lasts three quests, then the sanctuary is scenery.
**Recommendation:** a tiny repeatable request generator per pillar (rotating "bring N of X" with material rewards + small GWI) keeps the loop alive for the slice; the invention arcs (F-08) are the real successor.

### F-15 · S3 · Zero audio
**Where:** no `AudioStreamPlayer`/`AudioServer` reference in the entire project.
**Impact:** for a game whose thesis is *sensory warmth*, silence is the single biggest gap between "impressive slice" and "captivating" — hit feedback, crackling hearth, the level-up moment are all half-mute.
**Recommendation:** a first pass needs ~10 assets: swing ×3, hit/crit, parry, dash, pickup, hammer, level-up, ambient fire loop. Even placeholder synthesized SFX (the code-first ethos extends here — a tiny `Sfx` static class à la `Vfx`) transforms feel.

### F-16 · S4 · Rescue gate preview lies about who's caged
**Where:** [dungeon.gd:503](godot/scripts/dungeon.gd:503) — preview icon hardcodes `survivor_farmer`; the actual pillar is rolled later by `_pick_rescue_pillar`.
**Recommendation:** roll the pillar when the map node is generated (store on the RunMap node) so gate, map, and room agree.

### F-17 · S4 · Builder quest is off by one
**Where:** [village.gd:266-269](godot/scripts/village.gd:266) seeds a built crop bed; [village.gd:294-299](godot/scripts/village.gd:294) `built_count` counts it → "Raise 3 buildings" needs only 2 player builds.
**Recommendation:** exclude the seeded cell (flag it `"seeded": true`) or bump the need to 4 — either, but make the number honest.

### F-18 · S4 · Two full-screen grades share CanvasLayer 1
**Where:** [main.gd:200-205](godot/scripts/main.gd:200) (post-process) and [village.gd:232-243](godot/scripts/village.gd:232) (GWI wash) both use `layer = 1`; draw order is tree-order-dependent and the wash currently applies *after* grading, so bloom/vignette never see the warmth tint.
**Recommendation:** fold the GWI wash into `post.gdshader` (a `warm`-driven tint already exists — the village layer can drive `Main.set_grade` alone) and delete the second overlay.

### F-19 · S4 · Hygiene sweep
- Orphan [godot/tools/smoke.gd.uid](godot/tools/smoke.gd.uid) — its script was deleted; remove the `.uid`.
- Git working tree carries the whole proto2→REKINDLED rewrite uncommitted (30+ deletions, all new code untracked). Commit the pivot — right now a stray `git checkout .` loses the game.
- [village.gd:187](godot/scripts/village.gd:187) parameter `seed` shadows the global `seed()` function.
- [main.gd:110](godot/scripts/main.gd:110) `ignore_rotation = false` "shake needs the camera to actually roll" vs [main.gd:43](godot/scripts/main.gd:43) `SHAKE_ROT := 0.0` — comment and config disagree.

### F-20 · S2 · No placement box or grid when building
**Where:** [village.gd:474-514](godot/scripts/village.gd:474) — placement shows only a translucent building sprite (`_ghost`) tinted red when blocked. There is no cell outline under it, no footprint box, and no grid overlay showing which tiles are buildable. DESIGN.md's own z-index table even specifies a "build-grid guide" floor decal at z −9 — documented, never implemented.
**Impact:** the player can't tell *where* a building will land, what a "cell" even is, or where the buildable clearing ends (its edge is only a subtle grass-brightness change). Red-tint-on-blocked is the only feedback, and it doesn't explain *why* (outside clearing? on stream? occupied?).
**Recommendation:** while placing: (a) draw the clearing's buildable cells as a faint grid decal (the documented z −9 guide); (b) put a hard cell-outline box under the ghost — gold when valid, red when blocked; (c) one-word reason on blocked ("wild land", "water", "occupied"). Verified against screenshot `_shot_03_build_menu.png`.

### F-21 · S2 · Buildings, crops, and gates break the game's own 2.5D contract — this is why the farm "doesn't feel real"
**Where:** [village.gd:336-354](godot/scripts/village.gd:336) (`_add_building_sprite` — no `Iso.anchor_feet`, no `Iso.shadow`, position = cell centre), same for Scaffold ([village.gd:535-540](godot/scripts/village.gd:535)), CropPlot ([village.gd:593-598](godot/scripts/village.gd:593)), SupplyGate ([village.gd:661-666](godot/scripts/village.gd:661)). Iso rule 1 ("position is the feet; anchor with `Iso.anchor_feet`; everything standing casts a contact shadow") is applied to every *actor and prop* but skipped for every *player-built structure*.
**Observed on screen** (`_shot_03`): the cabin's lower half hangs into the stream row; buildings sort against actors by their centre rather than their base; no contact shadows, so structures read as stickers laid on the grass — exactly the "not real" feeling reported. Compounding it: an empty CropPlot hides its sprite entirely ([village.gd:648-655](godot/scripts/village.gd:648)), so a "farm" is an invisible interaction point on a bare bed — there's no soil, no mound, no dry/planted/watered state to look at, and seeds are a pure number in the HUD.
**Recommendation:** route every placed structure through the same mounting as props (`Iso.anchor_feet` + `Iso.shadow`, feet at the cell's south edge); give CropPlot an always-visible soil sprite (empty tilled soil → seeded mound → sprout → leafy → ripe), and make harvest drop a visible food item that arcs to the HUD counter. Small work, disproportionate realness gain.

### F-22 · S2 · The village-building scenario is unclear — nothing tells you what to build, why, or what changed
**Where:** the only guidance is one static objective line ("Build up the village, then Descend…", [village.gd:88](godot/scripts/village.gd:88)) and a beacon that points at scaffolds/ripe crops/the gate. Buildings have no visible function after completion (a cabin and a forge *do nothing observable* — F-13/D-02), quests hide until you happen to talk to a villager, and the warmth reward is an abstract meter tick.
**Impact:** the player's village "story" has no beats: build → number goes up → nothing changes. Combined with F-20/F-21 the whole sanctuary half feels like a menu with grass.
**Recommendation (cheap, sequenced):** (a) a *settlement objective chain* — the objective line advances through concrete goals ("Raise a Cabin → the Farmer needs a home", "Plant your first crop", "Raise a Forge → sharpen your claws"), each naming the *reason*; (b) buildings visibly work when built (smoke from the cabin chimney, forge glow + clink, villager walks to *their* building and works there — the Villager wander AI already exists, give it destinations); (c) tie each build to its beneficiary (rescued farmer stands by the crop bed, smith by the forge) so cause→effect is watchable. This is the UX face of D-02 and the natural home of the F-08 invention framing.

### F-23 · S2 · The core fantasy isn't visible: cold village and warm village look the same
**Where:** compare `_shot_01_village_cold.png` (GWI 0) with `_shot_02_village_warm.png` (GWI ≈ 0.38) — the frames are effectively identical. The GWI wash ([shaders/gwi.gdshader](godot/shaders/gwi.gdshader)) and the `set_grade` warm ramp ([main.gd:301](godot/scripts/main.gd:301)) are tuned so subtly they don't survive perception, and F-18 (the wash drawing after the post-process) further mutes it.
**Impact:** "as it climbs, the whole sanctuary warms from cool daylight toward golden hour" (GAME.md §8) is the game's central promise and its progress feedback — currently a player cannot see their progress at all between 0.0 and ~0.4.
**Recommendation:** make warmth *staged and material*, not just a grade: define 4–5 GWI tiers that each swap something physical — ground tint zones around the hearth, dead→budding→blooming trees (art exists: `dead_tree` vs `tree`), bonfire size/light radius growth, ambient colour steps, particle density (falling ash → drifting pollen/fireflies). Grade curves alone will never carry it; the world's *objects* must thaw. This is also the cheapest place to prove the "dynamic effects" half of the vision.

### F-24 · S3 · The dungeon reads as a flat purple grid, not "lit islands in the black"
**Where/observed** (`_shot_05`, `_shot_06`, `_shot_10`): walls render as slightly-lighter floor tiles with no vertical face ([dungeon.gd:188-208](godot/scripts/dungeon.gd:188) uses only `tile_floor`/`tile_wall`), so cover blocks read as pale floor patches; the floor is one tile repeated with zero variation; ambient `AMBIENT_DUNGEON` (#585274) is a fairly light lavender so the promised near-dark never happens and brazier pools barely register.
**The kicker:** the art to fix this already exists and is baked — `wall_block` (with a proper front face), `tile_floor2`, `tile_floor_crack`, `rubble`, `bones`, `edge_*` platform edges — all unused by dungeon.gd.
**Recommendation:** use `wall_block` for interior cover (feet-anchored, y-sorted, +WALL_H collider per DESIGN); mix `tile_floor`/`tile_floor2`/`tile_floor_crack` ~70/20/10; scatter `rubble`/`bones` decals at z −9; darken the ambient toward the documented near-black and raise brazier energy/radius to compensate. Mostly wiring, no new art.

### F-25 · S3 · HUD collisions, overflow, and spam
**Observed:** (a) the CONTROLS card is permanent and overlaps the heart row in combat (`_shot_06`); (b) at Ember LV 5 + Bramble Ward the heart row (13 hearts) overflows its panel and clips under the card (`_shot_10`); (c) killing the Warden crosses several XP thresholds at once → five "EMBER LEVEL N" banners stacked half-overlapping mid-screen during the boss (`_shot_10`; [game_state.gd:147-157](godot/scripts/game_state.gd:147) fires per level, [hud.gd:794-802](godot/scripts/hud.gd:794) slots overlap); (d) village toasts/banners persist into the dungeon across the layer swap (`_shot_05` "Cabin raised!" ghost); (e) the dungeon intro dialogue neither pauses combat nor blocks attack input (HUD consumes the click but Player polls `Input` directly), so scripted lines run mid-fight (`_shot_10`).
**Recommendation:** auto-fade the controls card after ~60 s (re-show on a help key); switch hearts to two rows or `♥ × N` numeric past 8; queue banners sequentially (one at a time, 0.9 s each) and collapse multi-level gains into one "EMBER LEVEL 3 → 5" card; clear transient toasts/banners in `set_combat`; gate the first-descent intro to before enemies activate (or pause during `say`).

### F-26 · S4 · Small readability misses
- The warmth meter's flame icon is tinted `GWI_COLD` (blue-grey) at low GWI ([hud.gd:764-765](godot/scripts/hud.gd:764)) — it reads as a **water droplet** (`_shot_01`), i.e. the opposite of its meaning. Keep the flame warm-but-dim (ember under ash), let the *fill* carry the cold→warm ramp.
- The Supply Gate sprite reads as a crate/log pile, not a way down (`_shot_01`) — it's the single most important interactable in the village. It deserves a hole/stair/hatch silhouette, its own light, and idle particles.

### F-27 · S4 · Title collision check (branding, not code)
**Confirmed 2026-08-11 via Steam search:** the exact standalone title
"Rekindled" appears unclaimed, but the cluster is crowded — *Rekindle* (×2,
one a 2026 parry-action game), *Rekindling*, *The Last Sunshine: Rekindled*,
*LOST EMBER: Rekindled Edition*, *Rekindled: Cozy Tavern Life* (Q4 2026, cozy
genre adjacency), and most notably **Rekindled Trails** (2025, Very Positive)
— which *also* features a fire companion helping rebuild ruined towns.
**Impact:** discoverability/SEO risk and a real "is this that other game?"
confusion risk with Rekindled Trails; zero urgency at prototype stage.
**Recommendation:** keep REKINDLED as the working title; before any public
page, differentiate — either a distinctive subtitle ("REKINDLED: <x>") or a
coined name (the project already owns a great one: *Embergrowth*). Re-run the
search before committing store branding.

### F-28 · S3 · Attunement balance is solved-on-sight
**Where:** [game_state.gd:25-29](godot/scripts/game_state.gd:25) / [player.gd:657-672](godot/scripts/player.gd:657) — the three rescue buffs are +2 Max HP (farmer), **+50% damage** (smith), +20% speed (builder).
**Impact:** +50% damage is worth several levels of any other stat in this game's math (base damage 2, finisher ×1.7, crit ×2 — the smith buff is the difference between 3-shotting and 2-shotting everything). Players who notice will always chase the smith first; the other two rescues feel like consolation prizes, which undercuts the "every rescue is precious" fantasy.
**Recommendation:** near-term, rebalance toward parity (e.g. +25% dmg / +25% speed / +2 HP with a heal-on-rescue); long-term this dissolves into PROGRESSION_DESIGN's plan where each rescue unlocks a *Mode + Kingdom* (a new way to play, not a bigger number) — which is the real fix.

### F-29 · S3 · XP pacing and the level-up full heal break attrition
**Where:** XP curve `6·l·(l+1)` ([game_state.gd:130-131](godot/scripts/game_state.gd:130)) vs per-kill awards `3 + 2·room` ([dungeon.gd:327](godot/scripts/dungeon.gd:327)) and the Warden's +30 bounty; each level fully heals ([player.gd:685-689](godot/scripts/player.gd:685)).
**Observed:** the autoplay run hit LV 5 by chamber 3 (`_shot_10` — five stacked banners); early thresholds (12/24 XP) fall every ~3–4 kills, so "LEVEL UP!" fires constantly and stops meaning anything. Worse, the full heal per level means a big kill (Warden) chains multiple full heals *mid-boss-fight* — combined with the village free heal and hearth rooms, HP attrition (the roguelite's core pressure) barely exists.
**Recommendation:** slow the curve ~2.5–3× (or scale XP-to-level with `run_count`); replace full heal with +2 HP on level; collapse multi-level gains into one banner (also F-25c). Note this whole system is slated for repurposing into run-scoped Kindle (PROGRESSION_DESIGN §8.0) — tune it only as a stopgap.

---

## 3. Overall design assessment (one level above the findings)

*Added 2026-08-11 after the finding-level pass. These are design-shape issues,
tracked like findings (`D-xx`) — they resolve through the roadmap in §5, not
through single patches.*

### Scorecard

| Dimension | Grade | One-line verdict |
|---|---|---|
| Core fantasy & theme | **A** | "Warmth = progress" is coherent, distinct, and visible on screen |
| Loop architecture | **B+** | The two-space rhythm (sanctuary ↔ ruins) is the right skeleton |
| Combat verbs | **B** | Rich moveset, superb feel — but nothing to use it against |
| Per-run variance | **D** | Every run plays identically; the biggest design risk |
| Village ↔ run coupling | **C–** | Quests point down; nothing you build points down |
| Progression design | **C** | All numbers, no new capabilities |
| Economy & decisions | **C–** | Few real choices; dominant strategies everywhere |
| Vision fit | **C** | The invention layer exists only in docs and dialogue |

### What the design gets right (protect these)

- **The core fantasy is the project's best asset.** GWI driving the actual
  light of the world — win condition as *visible warmth* — is a rare unity of
  theme, mechanics, and rendering. The rescue-as-emotional-beat ("civilisation
  lives in people, not loot") gives the game a heart Hades clones lack.
- **The loop skeleton is proven and correctly assembled**: cozy base ↔
  dangerous run, with a closed circuit (rescue → settle → quest → descend →
  warmth). The pieces are in the right order; they just need teeth (§2 F-01).

### Structural gaps

| ID | Severity | Gap | Status |
|---|---|---|---|
| D-01 | **S1** | **No per-run variance.** The game borrows Hades' presentation without Hades' reason to replay: no in-run build variation (Ember Level and attunements are flat, permanent stat growth), so run five plays exactly like run one, only easier. A roguelite without variance is a grind corridor with a map screen. `PROGRESSION_DESIGN.md` Phase 0–1 (Kindle → Blooms → pick-1-of-3 boons) is precisely the missing organ — the design doc is currently a better game than the build. | **Fixed (M2)** — EMBERGROWTH Phase 0 shipped: run-scoped Kindle → Blooms → **pick-1-of-3 boon draft** (resets each descent); Soil seeds the start stage. Verified on screen + by the autoplay bot. Modes/Kingdoms (Phase 1–3) still to come. |
| D-02 | **S2** | **Village → run coupling is one-way.** Runs feed the village richly; the village feeds runs nothing (no building changes what happens underground). Fix is cheap and thematic: Forge upgrades the claws, Crop Bed lets you carry food down as run healing, Cabins grant per-villager run blessings. Buildings differentiating also dissolves the cabin-spam dominance (F-13) at the design level. | **Fixed (M3)** — exactly this: Forge → Metallurgy (+dmg), Cabin → Shelter (+HP), Crop Bed → Agriculture (Provisions carried down as healing). Capped + diminishing so diversity wins. |
| D-03 | **S2** | **Decision density is too low.** Real decisions per minute: combat ≈ 0 (one enemy behavior → optimal play never changes), village ≈ 0 (dominant strategy, cosmetic placement), run = 1 per room (which gate) — and F-01 removes even that one's stakes. The whole roadmap (§5) is really one campaign: raising interesting-decisions-per-minute. | **Much reduced** — run now has the Bloom boon draft (M2) + gate choice with real stakes (M1); village has a genuine build-mix decision (M3, diminishing + distinct effects). Combat depth (F-04/F-05 code) still to be verified/closed. |
| D-04 | **S3** | **Progression grants numbers, not verbs.** +1 HP/+8% damage never changes how you play; an unlocked heat mode, dodge property, or crop type does. Players remember new abilities, never multiplier ticks. Resolved by the EMBERGROWTH modes/kingdoms when they land. | **Partly fixed (M2)** — the *drafting choice* (pick-1-of-3 each Bloom) is now the memorable beat; Phase 0 boons are still flat sparks, so true new *verbs* wait on Modes/Kingdoms (Phase 1–3). |
| D-05 | **S3** | **The theme deserves one systemic mechanic.** Warmth is only a progress bar; the cold-drain mechanic already specced (flagged off) in `PROGRESSION_DESIGN.md` §4.1 would make warmth something managed moment-to-moment — fiction and mechanics becoming the same system, as the game's best ideas already do. | Open |

### UI, color & theme assessment

*Added 2026-08-11 from a screenshot review (`tools/capture` frames `_shot_01`…`_shot_10`).*

| Layer | Grade | Verdict |
|---|---|---|
| Palette design (in code) | **A–** | `palette.gd` is a real color script: warm/cold families, a Hades contrast ladder, UI chrome tokens — professional structure |
| HUD chrome & layout | **B–** | Gilded-panel language is consistent and the two-skin (village/ruins) concept works; but collisions, overflow, and banner spam undermine it (F-25) |
| Character/effect art | **B+** | The cat is genuinely charming; sticker outlines land the Cult-of-the-Lamb register; combat VFX language (rings, embers, floats) is coherent |
| Environment delivery | **C–** | Village: muddy, hard-edged clearing rectangle, flat teal stream, repetitive grass. Dungeon: flat purple grid, walls don't stand (F-24). Much of the fixing art already exists unused |
| Theme on screen | **D+** | The one thing the game is *about* — visible warmth — doesn't read: cold and warm village frames are indistinguishable (F-23) |

**The pattern:** the *systems* for beauty are built (palette, baker, lighting
kit, grade pipeline) but the *delivery* is under-tuned — anchoring skipped on
structures (F-21), variation assets unused (F-24), grade ramps too subtle to
perceive (F-23). This is tuning-and-wiring debt, not missing technology; a
focused "art delivery pass" (F-20…F-26 as one package) would move the game from
"programmer-complete" to "captivating" faster than any new feature.

### The knowledge layer (yếu tố tri thức) — maturity audit

*Added 2026-08-11. The vision's defining ingredient — "profound knowledge of
civilizational advancement" — audited across everything that ships or is specced.*

| Tier | Where knowledge lives today | State |
|---|---|---|
| **Told** | One premise line ("civilisation lives in people and knowledge") + ~8 Ember tutorial lines | Shipped, but contains zero actual knowledge — the Ember only teaches controls |
| **Implied** | Survivors are professions (farmer/smith/builder) — conceptually knowledge carriers | Shipped, but mechanically they are stat buffs + fetch quests; their craft is never expressed |
| **Designed** | EMBERGROWTH (`PROGRESSION_DESIGN.md`): heat transfer, ecology, succession — science-vetted to an unusually high standard (§7's error-correction method) | **Not shipped.** The best knowledge asset the project owns is a document |
| **Absent** | The inventions-of-civilization layer (fire → agriculture → metallurgy → …): the vision's core | Not designed beyond VISION.md; no invention is named anywhere in game |

**Grade: D on screen / A− on paper.** The project's knowledge *method* is
excellent — PROGRESSION_DESIGN §7 (state the real science, correct every error,
flag every liberty) is exactly how an educational layer earns trust. But none
of it reaches the player yet.

**Design principle for shipping it — teach through mechanics, not popups.**
The player should *experience why the invention mattered*, with the Ember
delivering one honest line at the moment of use. A ladder of increasing effort:

- **K-0 · Reframe (days):** rename buildings/quests as *recovered knowledge* —
  the quest chain of each survivor = one advance (Agriculture / Metallurgy /
  Construction), one Ember line each on why it changed the world. (= F-08 pilot.)
- **K-1 · Codex ("the Ember's memories"):** every rescue/advance adds an entry
  to a collection panel (extend the existing C-sheet) — a one-paragraph real
  fact, written to the §7 standard. Collection = visible knowledge progress.
- **K-2 · Invention tree:** advances gated by *survivor + materials + prior
  advance*, ordered by impact not chronology; **every invention changes a verb**,
  not a number — crop rotation = second harvest cycle; bellows = forge upgrade
  (and it literally *is* convection, bridging to EMBERGROWTH's modes); writing =
  quests/recipes persist as a board instead of vanishing dialogue.
- **K-3 · EMBERGROWTH boons as discoveries:** the designed run-layer ships with
  its real science names (conduction/radiation/convection, succession stages) —
  natural science in the ruins, applied invention in the village, one spine:
  *rescue people → recover knowledge → knowledge changes how you play → the
  world warms.*

Tracked as **D-06** below; F-08 is its first executable slice (K-0).

| ID | Severity | Gap | Status |
|---|---|---|---|
| D-06 | **S1 (vision)** | Knowledge is told, never played: the layer that defines the game exists only in docs. Ship the K-ladder (K-0 now, K-1/K-2 with the village purpose phase, K-3 = EMBERGROWTH). Guard-rail: every entry passes the PROGRESSION_DESIGN §7 vetting method — real mechanism, corrected errors, flagged liberties; never invent fake history. | **K-0+K-1 Fixed (M3)** — inventions recovered on build/rescue with an Ember "why it mattered" line; a **Codex** (key K, `Lore.gd`) of §7-vetted real facts, on screen (`_shot_15`). K-2 invention-tree / K-3 EMBERGROWTH-boons-as-discoveries remain. |

### Character progression review (thiết kế nâng cấp nhân vật)

*Added 2026-08-11 on request: is the upgrade design reasonable, is it derivative, what's new, is it attractive?*

**How the character is upgraded today — three layers, all passive:**

| Layer | Source | Effect | Player choice? |
|---|---|---|---|
| Ember Level | XP per kill (persistent) | +1 Max HP, +8% dmg per level, full heal, unbounded | **None** |
| Attunements | One per rescued survivor (max 3, permanent) | +2 HP / +50% dmg / +20% speed | **None** (only rescue order) |
| In-run growth | — | *does not exist* | — |

**Is it reasonable? Structurally, no — four compounding problems:**
1. **Zero drafting.** Every upgrade happens *to* the player; nothing is ever chosen. Build choice is the beating heart of the modern roguelite (Hades boons, Dead Cells scrolls, Slay the Spire/Balatro card picks) and it is entirely absent.
2. **All numbers, no verbs** (D-04) — nothing you gain changes *how* you play.
3. **Monotonic growth vs flat difficulty** (F-03) — the curve only ever gets easier.
4. **Local math is off** even within its own frame: attunements are solved-on-sight (F-28), XP pacing inflates and the per-level full heal deletes attrition (F-29).

**Is it derivative?** The *shipped* layer is generic rather than copied: persistent
kill-XP levels are the Rogue Legacy / Vampire Survivors meta-pattern *minus the
choice those games offer* (both let you pick what to buy); rescue-granted
permanent buffs echo Hades' keepsakes and Children of Morta's family bonds, but
as flat stats. Verdict: nothing plagiarized — but nothing distinctive either.
This is the placeholder tier every roguelite prototype passes through; the risk
is only if it ships as final.

**What's new, and is it attractive?** The genuine novelty is the *designed*
layer, EMBERGROWTH (`PROGRESSION_DESIGN.md`): elements as the **three real
modes of heat transfer** (conduction/radiation/convection) instead of a fantasy
element wheel; an in-run level track that is **ecological succession** (Ash →
Canopy); boon pools built from **real trophic roles** (producers / consumers /
decomposers); a science-vetted interaction matrix; and meta-progression as
**Soil** fed by warmth and rescues. No shipped roguelite on the market builds
its progression from honest thermodynamics and ecology — combined with the
knowledge layer (D-06) it is the project's clearest unique selling point.
**Attractiveness is conditional on readability**: the science must be taught by
feel (mode-coloured numbers, "IGNITE!/resist" floats, the §6 feedback plan),
never by spreadsheet. If EMBERGROWTH Phase 0–1 ships with that discipline, the
progression goes from the game's weakest system to its signature. Rating:
shipped layer **D+**, designed layer **A– potential**.

### Competitive positioning — where REKINDLED loses to the market, and how to fix it

*Benchmark set (2025–26 landscape): Hades II, Dead Cells / Windblown, Cult of
the Lamb, Balatro/Slay the Spire (build-crafting expectations), Vampire
Survivors / Brotato (feel-per-minute expectations), Children of Morta.*

| # | Gap vs market | Benchmark that sets the bar | Severity | Fix (tracked) |
|---|---|---|---|---|
| 1 | **Build variety / run variance** — zero in-run choices vs hundreds of viable builds | Hades II, Dead Cells, Balatro | Fatal if unfixed | D-01 → EMBERGROWTH Phase 0–1 |
| 2 | **Enemy & combat depth** — 1 behavior + 1 stat-brute vs dozens of telegraphed enemy types | Hades II, Windblown | Severe | F-04, F-05 |
| 3 | **Death means something** — market leader made death = story progress; here death is a free teleport | Hades (I & II) | Severe | F-01/F-02 + cheap reactive Ember/villager lines per run outcome |
| 4 | **Sensory baseline** — zero audio; juice is visual-only | every benchmark | Severe for perception | F-15 |
| 5 | **Persistence & QoL** — no save/load, no pause/settings | table stakes everywhere | Blocks playtesting | F-07 |
| 6 | **Content volume** — 1 biome, 1 weapon, 2 enemies vs years of content | Hades II, Dead Cells | Real but **do not chase** | see strategy below |

**Strategy — compete on identity, not volume.** A first game cannot out-content
Supergiant or Motion Twin, and shouldn't try. REKINDLED's defensible niche is
the **hybrid**: cozy-rebuild × action-roguelite × real knowledge. Cult of the
Lamb proved the hybrid formula sells (base-building audience × run audience);
*Rekindled Trails*' success (F-27) proves appetite for exactly this
rebuild-with-fire cozy fantasy; nobody occupies the "roguelite that honestly
teaches thermodynamics, ecology, and the inventions of civilization" square —
plus a marketable cat. The plan is therefore not "add more of everything" but:
fix gaps 1–5 (all already tracked), keep content volume modest but *dense with
identity* (every enemy a real material family, every building a real invention),
and let the warmth/knowledge fantasy be the storefront differentiator.

### Bottom line

Nothing needs *redesigning* — skeleton and soul are both right, and the
systems that fix the gaps are already specified in the project's own docs. The
one existential risk is **sameness** (no stakes, no variance, no
cross-feeding ⇒ a beautiful ritual that stops mattering after three runs).
The work is sequencing, and §5's order is built to attack exactly that.

---

## 4. What's genuinely good (keep doing this)

- **The 2.5D kit** (`iso.gd`) and its written contract are excellent — the four
  rules + z-conventions read like a real studio's tech bible. (Now enforce
  them: F-10/F-11.)
- **Combat *feel* engineering**: analytic three-phase poses that survive
  hit-stop, buffered combo chaining, dash-cancel rules, the per-frame trauma
  cap on the camera — this is far above prototype grade.
- **Docs-as-truth culture**: GAME.md/DESIGN.md/PROGRESSION_DESIGN.md are
  current and honest (the progression doc even audits its own codebase traps).
  The gaps this report found are mostly places where code drifted from doc —
  the docs themselves are the project's best asset.
- **The science-vetting discipline** in PROGRESSION_DESIGN §7 is exactly the
  right method to extend to the invention/history layer (VISION.md).

## 5. Suggested iteration order (phase 1 of the step-by-step plan)

1. **Stakes** — F-01, F-06, F-02(a run-summary card): makes the existing loop real. Smallest set of changes with the largest meaning gain.
2. **Art delivery & village UX pass** — F-20, F-21, F-22, F-23, F-25, F-26 (+ F-24 if time): placement grid, anchored/shadowed structures, visible farm states, staged warmth tiers, HUD cleanup. Makes the *existing* content look and read like the vision; mostly wiring, no new systems.
3. **Challenge** — F-03 (+ F-09 to stop snowballing), F-04: makes the loop worth mastering.
4. **Variance** — D-01 via PROGRESSION_DESIGN Phase 0–1 (Kindle/Blooms/boons): makes the loop worth *repeating*. (Also retires D-04.)
5. **Readability & fairness debt** — F-10, F-11, F-12, F-17.
6. **Purpose** — F-08 pilot + D-02 (buildings that matter) + F-13/F-14: makes the loop *about* the vision.
7. **Senses** — F-15, F-18, F-05's telegraphs double as spectacle; D-05 when pacing allows.

Subsequent review passes will re-test each `Fixed` finding and append report #2.
