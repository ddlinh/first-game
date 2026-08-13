# REKINDLED — Critic's Review (open findings)

*A game critic's pass over the build, focused on **story** and **in-game UX**. This document has been **pruned to what is still open** — the many findings the team has since shipped and I re-verified in code are removed (summarised below), so what follows is only the outstanding work.*

**Build:** `main` (working tree, 2026-08-13) · Godot 4.7.1 · code-first, EN/VI localization · builds clean (`godot --headless --check-only`, exit 0).

### ✅ Resolved & removed from this doc
The following are done and verified in code, so their findings have been deleted: **an ending + win state** (Ember epilogue), **save/load** + autosave, **procedural audio** (SFX + ambient bed), the **meta-shell** (title / pause / settings / quit), **named, speaking survivors**, **environmental storytelling** in the ruins (examinable relics), **reactive Ember milestone lines**, a **Codex read-reward + "new" surfacing**, **colorblind + high-contrast** telegraph toggles, **keyboard boon draft** and **keyboard menu navigation**, **dismiss-to-continue** run-summary, **confirm dialogs** for destructive actions (New Game / mid-run quit), the **construction overhaul** (Manage → Upgrade/Relocate/Demolish, hearth-warmth placement), the **Living Settlement** population loop, and removal of the **dead Ember-XP plumbing**. `hud.gd` was also decomposed (`UiKit` / `HudMenus` / `HudPanels`, −31%).

### Scorecard (current)
| Dimension | Grade | One-line verdict |
|---|:---:|---|
| Combat feel | **A−** | Telegraphed, committal, juicy — and now audible. The best thing here. |
| Camera / juice | **A−** | Trauma shake, dead-zone follow, shaders, visible thaw. Above prototype grade. |
| UX shell | **A−** | Title, pause, settings, save, confirms, keyboard-navigable. Solved. |
| Onboarding | **B+** | Strong interactive intro; no longer replays every boot. |
| Audio | **B** | Coherent procedural layer + ambient bed, from zero assets. |
| Accessibility | **B−** | Colorblind + contrast that truly alter telegraphs; still no UI scaling / difficulty / rebinding. |
| Story / narrative | **B−** | Ending, named survivors, reactive lines, ruin fragments. Held back by the unbuilt vision layer + no antagonist. |
| Progression legibility | **B** | Bloom loop reads well; building levels + population deepen the meta. |
| Content depth | **B−** | Construction, farm chain, workshop, population all added — but the run map and Codex are still short. |

### Severity legend
🔴 Critical · 🟠 Major · 🟡 Minor

---

# PART A — STORY & NARRATIVE (open)

*The premise, voice, ending, named survivors, ruin fragments, and reactive lines are all in now. What's left is the **advertised depth** and an **antagonist**.*

### A4 / C2 🟠 The signature "vision" layer is documented, not built
This is now the single largest gap between the pitch and the play. `VISION.md` sells an educational roguelite "woven with profound knowledge of human civilizational advancement," and `PROGRESSION_DESIGN.md` elaborates a whole thermodynamic-and-ecology cosmology — **EMBERGROWTH Modes** (heat transfer), ecological **Kingdoms**, the Mode×Family interaction matrix, and an **inventions-of-civilization ladder**. On screen, the distinctive layer is still absent: the shipped attunements are flat stat buffs, and no invention beyond the Codex pilot is named as a *mechanic*. The QA doc's own line still stings: *"the design doc is currently a better game than the build."* This is the vision's differentiator and it isn't yet playable.

### A-antag 🟠 There is no antagonist and no cause
Survivors are people now, but the *opposition* still isn't. The husks get one line of lore ("Hollow things I left behind when the world went cold") and the Warden gets none — "a brute guards the deep" is its whole characterization. Nothing explains *what* caused the cataclysm beyond "the world went cold." A rescue-and-rebuild fantasy needs something to fear and a reason the dark fell; give the Warden a face and the cold a cause, even a thin one.

### A7 🟡 The progression/village metaphors are still narratively mute
EMBERGROWTH's succession stages (Ash → Pioneer → Herb → Thicket → Canopy) still carry **no per-stage flavor text**, and the village's warmth is framed as the world thawing but delivered only through banner toasts. The reactive Ember lines added general milestone commentary, but the "succession" and "rekindling" metaphors themselves never get a line of prose to land them.

---

# PART B — USER EXPERIENCE (open)

*The session shell, audio, confirms, and keyboard paths are all solved. What remains is the **endgame**, **save legibility**, a couple of **input edge cases**, and **spatial awareness**.*

### N4 🟠 Winning empties the game — the post-victory state is an inert, maxed-out sandbox
`won` latches true and warmth clamps at 1.0 forever (`game_state.gd set_gwi()`). The victory button ("Keep tending your village") returns you to a settlement whose warmth, thaw grade, and every village→run boon are permanently maxed, whose quests are all spent, and whose Codex is complete — with **no New Game+, no post-win objective, and no way to view the ending again.** The ending beat itself is good; what follows it is a void. A finisher needs somewhere to go — an endless "how deep can you push the ruins?" mode, and/or a rekindled-world seal on the title + a way to re-read the epilogue.

### N5 🟡 The save model is opaque — the player can't tell when it's safe to stop
Autosave happens only on returning to the village (`main.gd return_to_village()`) and on manual pause-save; there is **no "Saving…" indicator**, and run-scoped state is deliberately not captured. **Continue shows no context** either — no run count, survivor tally, or timestamp — so a returning player can't tell what they're loading into. The persistence works but communicates nothing, which is how players lose progress and blame the game.

### N6 🟡 Esc can't pause during the moments a player most wants to bail
`toggle_pause()` bails out if a dialogue line is waiting or a build placement is active, so during a scripted intro line or the dungeon-intro freeze, **Esc does nothing** — no pause, no menu, no skip. A first-time player reaching for Escape mid-cutscene has no route until the dialogue clears.

### B8 🟡 No minimap or next-room hint
The only map is the full-screen **Tab** overlay. Mid-run the player has no ambient sense of where they are in the run's 5 layers or what's next — a small persistent minimap or "next: rescue / boss" hint would give the descent spatial legibility without opening the full graph.

### B6-rem 🟡 Remaining accessibility gaps
Colorblind and high-contrast telegraphs are solved, but there is still **no UI / font scaling, no difficulty toggle, and no key rebinding** (input actions are registered in code, so the editor Input Map is empty — a rebinding UI would be built from scratch). Lower priority than the above, but the standard accessibility checklist isn't complete.

### B9 🟡 Content ceiling is raised but still finite
The village loop is materially deeper now (upgrade tiers, the farm chain, the workshop, the population loop). What still caps a session is the **content around it**: three one-off survivor quests, a 5-layer run map, and a small Codex. This is expected for a slice — it's the ceiling the next content push has to raise, not a defect.

---

# PART C — SYSTEMS / TECH (open)

- **C3 🟡 `hud.gd` decomposition is under way, not finished.** The god-object is down from ~2,600 to ~1,800 lines with the toolkit, menu shell, and overlay panels extracted (`UiKit` / `HudMenus` / `HudPanels`). What remains inside is the **boon draft**, the **dialogue/intro** system, and the **live gauges** (`_build_ui` + refreshers). The gauges are legitimately the HUD's own job; the boon draft and dialogue are the last clean split candidates.
- **C4 🟡 Doc-vs-code drift.** The `QA_REPORT.md` status table lags the shipped code in several places. It's the team's source of truth, so it's worth a reconciliation pass — several F-/D- items it lists as open are now done.
- **C5 🟡 Title collision.** "Rekindled" overlaps with existing games (e.g. *Rekindled Trails*); worth resolving before any public-facing build.
- **V1-rem 🟡 Crop Beds can't be demolished or relocated.** The Manage menu (Upgrade / Relocate / Demolish) covers Cabin / Forge / Workshop; Crop Beds still have no removal path, so a misplaced bed is permanent. Minor, since beds are cheap and tied to the farm chain — but it's the one building type the construction overhaul didn't reach.

---

# PART D — Village depth (from `VILLAGE_DESIGN.md`, open)

The construction *act* and a population loop are shipped; the deeper economy/stakes systems remain:

- **P5 — Storage caps + a Granary.** Resources are still one flat unbounded pool. Storage infrastructure (a Granary that raises caps, preserves food) would give the economy a reason to exist and a real "build storage or waste surplus" decision.
- **P6 — Village stakes / defence.** Nothing threatens the settlement, so defensive buildings (palisade, watchtower) have no purpose and warmth only ever rises. An occasional threat the walls defend against would give building a *protective* reason.

*(Both assume new systems — P5 is medium, P6 is large. They're the frontier of the village layer, not debt.)*

---

# Strengths worth protecting

- **Combat is the star.** Fully-telegraphed contact damage, wind-up rings, and a two-attacker commitment token keep crowds readable — a real, well-considered guarantee.
- **The camera/juice rig** — trauma² shake with a per-frame cap, dead-zone spring follow, zoom-punch on crits — is above prototype grade.
- **The visible thaw** (dead trees leaf out, the bonfire grows and brightens with warmth) is exactly the legible, satisfying feedback the game should keep leaning into.
- **The Codex's honesty** — real history, real mechanisms, liberties flagged — is the distinctive, defensible heart of the vision. Grow it.
- **Full, high-quality VI localization** through a single `Loc.t()` chokepoint. Translation is not the weak point.

---

# Prioritized recommendations (open only)

| # | Recommendation | Addresses | Effort |
|---|---|---|:---:|
| 1 | **Give the post-win state a destination** — an endless "deep ruins" mode and/or a rekindled-world title seal + a way to re-read the ending. | N4 | M |
| 2 | **Build one slice of the vision layer** — even a single EMBERGROWTH Mode or a named invention that changes how a run plays — so the differentiator becomes playable. | A4 / C2 | L |
| 3 | **Give the cold a cause and the Warden a face** — a thin antagonist thread across the intro / ruins / boss. | A-antag | S–M |
| 4 | **Save legibility** — a "Saving…" flash + run/survivor context on the Continue button. | N5 | S |
| 5 | **A small persistent minimap / next-room hint.** | B8 | S–M |
| 6 | **Per-stage succession flavor + a village threat + storage economy** as the village layer's next depth pass. | A7, P5, P6 | M–L |
| 7 | **Finish the `hud.gd` split** (boon draft + dialogue) and reconcile `QA_REPORT.md`. | C3, C4 | S–M |
| 8 | **Round out accessibility** — UI scaling, a difficulty toggle, key rebinding. | B6-rem | M |

---

*End of pruned review. The frame around the session is built, the world has a voice and a sound, and the construction loop is real. The work now is upward: make the **advertised vision** playable, give the ending **somewhere to go**, and give the cold a **cause** worth fearing.*
