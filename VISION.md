# REKINDLED — Core Vision & Design Principles

*Reminder document. Read before proposing or accepting any feature.
Last updated: 2026-08-11.*

---

## The vision (one paragraph)

A **visually captivating** game — dynamic effects, warmth you can *see* — woven
with **profound knowledge of human civilizational advancement**. Strict
chronology takes a back seat to **essential, world-changing inventions**: the
things that actually bent the curve of history (fire, agriculture, metallurgy,
the wheel, writing, printing, sanitation, electricity…). The player doesn't
memorize dates; they *re-enact why each invention mattered*.

REKINDLED is the vehicle: a post-apocalyptic roguelite where a ginger cat
carrying the last Ember descends into cold ruins, rescues survivors, and
rebuilds a village. **Civilisation lives in people and knowledge, not loot** —
every system should reinforce that sentence.

## The three pillars

1. **Spectacle with substance.** Every mechanic earns a visible, juicy effect
   (hit-stop, warm grades, ember bursts) — but the effect must *communicate*
   the system underneath, never decorate a hollow one. If a feature can't be
   read on screen without a tooltip, it isn't finished.
2. **Real knowledge, honestly used.** Science and history ground the mechanics
   (see `PROGRESSION_DESIGN.md` §7 for the method: every mechanic states its
   real basis; every liberty is flagged as a deliberate metaphor). This is the
   established "science-first" rule — extend it to *history of invention*:
   a building, tech, or upgrade should map to a real world-changing advance
   and teach *why* it changed the world (impact over chronology).
3. **Progress = rekindling.** The single progress fantasy is warmth returning
   to a dead world. Player power, village growth, visual grade, and the
   invention ladder are the *same* bar (GWI / Ember). No parallel currencies
   that don't feed it.

## Design principles (test every proposal against these)

- **Impact over chronology.** Order inventions by *how much they changed the
  world*, not by date. It's fine for agriculture and pottery to be siblings;
  it's not fine to invent a fake technology or a wrong causal story.
- **The loop must have real stakes.** Roguelite structure only means something
  if pushing deeper risks something and banking gives something up. Any reward
  that is "banked instantly and kept on death" is a bug against this principle.
- **People are the reward.** Rescues, villagers, and their knowledge are the
  emotional and mechanical payoff. Loot exists to serve them.
- **One celebration per beat.** A threshold (level, bloom, invention) fires
  exactly one polished moment — never two overlapping systems both scaling
  stats or both raising banners (see PROGRESSION_DESIGN §8.0).
- **Readable before tunable.** New combat mechanics need a telegraph the
  player can see and react to *before* we balance numbers around them.
- **Code-first, file-based art, 2.5D contract.** Respect `DESIGN.md`'s iso
  rules (feet anchors, ground distances, y-sort, contact shadows) in every new
  actor and effect.

## What "done" looks like for the current phase

The vertical slice proves the loop shape. The next milestone is making the
loop *matter*: real risk/reward on descent, difficulty that keeps pace with
meta-growth, a win/lose state, and the first visible slice of the
invention-knowledge layer (buildings/quests that teach why an advance
mattered). Tracked issue-by-issue in `QA_REPORT.md`.
