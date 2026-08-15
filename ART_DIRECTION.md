<!--
  Art-direction bible for REKINDLED, Village/town first.
  Grounded against the live rendering stack (iso.gd, art.gd, assets.gd, art_env.gd,
  art_props.gd, palette.gd) and reconciled with the game's visual thesis (GWI = colour
  temperature) from STORY_DESIGN.md. Companion to VILLAGE_DESIGN.md §6 (personalization)
  and DEV_ROADMAP.md (M8, M15).
-->

# REKINDLED — Art Direction (Village / Town first)

*The look the settlement is built toward, and the rules that keep it on-thesis. Village
is specced in full here; frontiers (STORY_DESIGN §5) extend the same principles later.*

*Reference the user set as the north star: **The Settlers Online** — a lush, dense,
isometric medieval town (canals, paved plazas, decorative gardens, tiered buildings,
many small worker props).*

*Last updated: 2026-08-14.* · Markers: **SHIPPED** = true of the build today · **→**
proposed direction · **⚑** a flagged fiction liberty.

---

## 0. The north star, in one sentence

> **A Settlers-style lush, dense, decorated isometric town — but rendered as the WARM
> POLE of a temperature gradient, not an always-summer world.**

The reference image is, in REKINDLED's own terms, a **GWI ≈ 1.0** settlement: fully
thawed, green, populous. Our job is to make a town that reads that way when warm **and**
reads blue, rimed and half-dead when cold — because the whole game is the journey between
those two states (STORY_DESIGN: *"the world's temperature is its colour"*).

---

## 1. What ships today (the stack we build on)

Grounded in code — the good news is the camera and pipeline already support this direction
**without an engine rewrite**:

- **Camera — already isometric.** `iso.gd` is a pseudo-3D "2.5D" kit (a Hades-style low-angle
  camera over a flat ground plane): Y-sort depth, feet-anchored sprites, contact shadows,
  circular collision. **This is exactly the Settlers viewpoint.** SHIPPED.
- **Look — "storybook / Cult of the Lamb."** `art.gd` bakes every texture from vector /
  signed-distance primitives: **bold flat fills, thick dark outlines**, analytic AA, at 2×
  size drawn down at `PX = 0.5`. Highly stylized, high-contrast. SHIPPED.
- **Pipeline — PNG override.** `assets.gd`: every texture is a PNG in `res://art/<key>.png`
  (listed in `_manifest.txt`); the game loads those files. **Repaint a PNG (same key) and
  the game shows it** — so the look can change with **zero engine work**. SHIPPED.
- **Current catalogue (small):** `art_env.gd` = 8 ground tiles, dungeon wall, platform
  edges, **4 buildings**, 4 crop stages; `art_props.gd` = bonfire, brazier, cage, gate,
  portal, dead trees, stumps, rocks, fences, barrels, banners, decals, pickups.
- **Grade — already warmth-driven.** GWI reads as weather: ambient light warms blue→gold,
  the bonfire grows, dead trees leaf out (`village.gd` warmth cues). SHIPPED.

**Takeaway:** the viewpoint and the delivery pipeline are ready. What the Settlers look
asks for is a **style shift + a much bigger, denser, tier-detailed art catalogue** — a
content investment, not an engineering one.

---

## 2. The style decision — pick a family (recommend HYBRID)

The reference and the current art are the **same viewpoint, different style families.**
Choose deliberately:

| Option | What it is | Fit with thesis / cost | Verdict |
|---|---|---|---|
| **Keep** current | Cult-of-the-Lamb storybook, sparse | Cheapest; not the ask | Reject |
| **HYBRID** (recommend) | Keep readable storybook **silhouettes + outlines**; borrow Settlers **density, canals, plazas, gardens, per-tier detail** | Best balance of "looks like the ref" and Pillar 1 "readable skyline"; **M** cost | **Adopt** |
| **Full realism** | Settlers-grade semi-realistic textured iso | Highest fidelity; **studio-scale art cost**; dense detail fights glance-legibility and the cold↔warm grade | Reject (for now) |

**The hybrid rule of thumb:** *silhouette and outline stay storybook (so the town stays
legible and cheap-ish to draw); density, layout and dressing go Settlers.*

---

## 3. Non-negotiables (these override aesthetics)

Any art choice must satisfy all four, or it's wrong regardless of how good it looks:

1. **Cold↔warm grade is mandatory, per asset.** The north-star image is the **GWI 1.0**
   state only. Every building, tile and prop must also read at low GWI: **blue-grey,
   desaturated, rimed with frost, snow-capped, dead/leafless.** No asset may be authored
   "summer-only." The thaw is the game's central spectacle — protect it. (Grade spec: §6.)
2. **The skyline stays a readable résumé (Pillar 1).** A forge-town and a farm-town must be
   told apart in **one glance from the hearth.** Settlers density is welcome *only* if
   distinct building silhouettes and the diversity signal survive it. Density must never
   smear legibility.
3. **One camera. Every asset obeys `iso`.** Feet-anchored, Y-sorted, contact-shadowed, drawn
   for the fixed low-angle projection (`art_env.gd`'s "ONE CAMERA" rule). No asset painted
   for a different perspective.
4. **Science-first fiction (project iron rule).** A **recovering post-freeze settlement** —
   rustic timber/stone/thatch, things these survivors would actually build. No anachronism,
   no fantasy ornament, nothing that contradicts a world clawing warmth back from cold.
   ⚑ Only liberty: a settlement dresses itself faster than history would (pace, not kind).

---

## 4. What we borrow from the Settlers look (the concrete list)

Density and dressing are the point — and they line up exactly with the **personalization
layer** (VILLAGE_DESIGN §6 / P7, DEV_ROADMAP M8):

- **Dense, terraced layout** — buildings packed on stepped ground, not scattered on a flat
  lawn; the clearing rings read as deliberate terraces.
- **Water features — canals / ponds / channels.** The **water shader already exists** (M6
  life pass), so canals are cheap spectacle and a natural warm-town flex.
- **Paved plazas & courts** — stone-laid ground tiles around the hearth and between
  districts (doubles as the **paths/roads** planning tool, §6.2).
- **Decorative gardens & crops** — flower beds, kitchen gardens, orchard rows (the
  craft-gated Farmer decorations, §6.3).
- **Per-tier building detail** — a building visibly gains mass/detail Dormant → Blueprint →
  Operational → **Upgraded** (banners, scaffolding gone, chimney smoke, add-ons).
- **Many small worker/life props** — villagers at work, washing lines, benches, carts,
  drying racks — the *lived-in* density that sells "a town, not a camp."

All of the above stay **GWI-neutral** as decoration (no warmth/boons) per §6.3 — they make
the town *yours*, not stronger.

---

## 5. The build path (incremental, via PNG override — no rewrite)

Do it in layers; each ships something visible. Every asset is authored **with a cold and a
warm read** (or a shader-driven grade) from day one.

1. **Style pilot** — repaint **1–2 buildings** (Cabin, Forge) + their tiers in the
   hybrid look; validate cold↔warm grade and glance-legibility before committing the set.
2. **Modular tile + prop kit** — paved/plaza tiles, canal/water tiles, terraced ground,
   fences/hedges; the reusable vocabulary a dense town needs.
3. **Per-tier building art** — unique art for each lifecycle tier of every building.
4. **Decoration catalogue** — the craft-gated cosmetic props (§6.3), GWI-neutral.
5. **Life props** — worker animations, carts, washing lines, benches ringing the bonfire.

**Cost, honestly:** Steps 1–2 are **S–M**; steps 3–5 are **M–L** and grow with the building
count. Matching Settlers *fidelity* is studio-scale — the hybrid keeps it tractable by
reusing storybook silhouettes and the modular kit. Stage it; don't attempt the full town in
one pass.

---

## 6. Palette & the cold↔warm grade

The single most important spec — it's what makes the north-star image honest.

- **Cold pole (GWI → 0):** desaturated **blue-grey**, low contrast, **rime/frost overlay**,
  snow caps, leafless/dead foliage, weak hearth glow, long cold shadows.
- **Warm pole (GWI → 1):** saturated **golden-hour** ambient, warm ambers and living greens,
  frost gone, foliage leafed and flowering, big bonfire, soft warm shadows — the reference
  image.
- **Driver:** GWI applies a **global grade** (ambient light + palette shift) **plus** a
  **per-asset state** (snow/rime → clear, dead → leafed). Extend the existing warmth-cue
  system in `village.gd`; anchor palette in `palette.gd`.
- **Outer-ring exception:** a Cold-Snap-dormant ring (DEV_ROADMAP M13) sits at the **cold
  pole locally** even in a warm town — rimed and blue-grey — so neglect reads on sight.

---

## 7. Keeping density legible (Pillar 1 under Settlers density)

Density is the risk; these rules defend the résumé:

- **Silhouette-first.** Each building's outline stays distinct and recognisable at a glance,
  even shrunk — no two building types share a silhouette.
- **Outline retained.** Keep the thick storybook outline; it's what holds shapes apart in a
  dense scene (this is *why* we don't go full-realism).
- **Craft colour-coding.** Roof/accent hues cue craft family (forge = iron/dark, farm =
  green/gold, hall = timber/warm) so a district reads by colour.
- **The hearth is the focal anchor.** Brightest, tallest, centre — the eye starts there and
  reads outward by ring.
- **Rings as legible structure.** Terraces/plazas separate districts so density groups
  instead of smears.

---

## 8. Explicit anti-goals

- **Not** photoreal / full-texture realism (cost + legibility + grade all fight it).
- **Not** always-summer — every asset must survive the cold pole.
- **Not** density for its own sake — if a prop doesn't sell "lived-in" or breaks the glance
  read, cut it.
- **Not** anachronistic or fantasy ornament — fiction-fit only.
- **Not** an engine change — this is a content/style investment on the shipped iso + PNG
  pipeline.

---

## 9. Code map (where the art lives)

| Concern | File(s) |
|---|---|
| Isometric camera / projection / shadows / Y-sort | `godot/scripts/iso.gd` |
| Shared vector/SDF drawing engine (the storybook baker) | `godot/scripts/art.gd` |
| Texture catalogue + **PNG override pipeline** (`res://art/<key>.png`) | `godot/scripts/assets.gd` |
| Built world: ground tiles, buildings, crop stages | `godot/scripts/art_env.gd` |
| Freestanding props / scenery / pickups | `godot/scripts/art_props.gd` |
| Global palette + display scaling (`PX`) | `godot/scripts/palette.gd` |
| Village warmth cues / GWI-as-weather grade | `godot/scripts/village.gd` |
| FX (wind/water shaders, smoke) | `godot/scripts/vfx.gd`, `godot/scripts/art_fx.gd` |

**Cross-refs:** the *what to place* (planning + decoration) lives in **VILLAGE_DESIGN.md §6**;
the *when to build it* lives in **DEV_ROADMAP.md** (M8 personalization, M15 frontiers); the
*why colour = warmth* lives in **STORY_DESIGN.md** (thesis, §1 legibility channels, §5
frontiers).

*Bottom line: keep the isometric camera and the readable storybook silhouette; borrow the
Settlers density, canals, plazas and dressing; and author every asset to grade from a cold,
rimed, half-dead read to the lush golden-hour town in the reference — because that thaw is
the game.*
