# REKINDLED — Architecture & Build Contract

A post-apocalyptic roguelite (concept: `rekindled_master_concept.html`). The vertical
slice proves the **full core loop**: descend into a subterranean ruin → fight husks →
rescue a survivor → carry materials home → build on the 8×8 village grid → plant and
harvest a crop → the village warms (GWI) → run again.

Engine: **Godot 4.7.1**. GDScript. **Art ships as PNG files in `godot/art/`** and
the game renders them directly (see `art/README.md`); the code-drawn generators in
`scripts/art_*.gd` are now only a default-generator/fallback that repopulates a
missing file. Repaint a PNG, no code changes.

## Look and feel
Two references, deliberately combined:

- **Cult of the Lamb** for the *cast and register*: bold flat fills, thick dark
  sticker outlines, soft rounded shapes, a cute animal cast led by a ginger cat with
  an ember scarf.
- **Hades** for the *presentation*: a floor tilted away from the camera with upright
  characters standing on it, rooms as lit islands in absolute darkness, depth by
  overlap, contact shadows under everything, dramatic point lighting, and an ornate
  gilded interface.

Civilisation lives in **people and knowledge**, not loot — rescuing a survivor is the
emotional beat. **GWI** (Global Warmth Index, 0→1) is the progress bar: as you build,
the ambient light, the colour grade and the village bonfire all visibly warm up.

---

## 1. The 2.5D projection — `scripts/iso.gd`

The game simulates on a flat plane but presents it from a low angle:

    screen.x = ground.x
    screen.y = ground.y * Palette.SQUASH        (0.625)

Crucially this is **not** done by scaling a parent node — non-uniform scale on a
physics ancestor deforms collision shapes. Instead each layer *authors its geometry
already squashed* (a grid cell is `CELL x CELL_Y` = 48×30, not 48×48) and actors
compress the Y of their velocity with `Iso.vel()`. Collision stays uniform; circles
stay circles.

Four rules bind every module:

1. **A Node2D's `position` is its feet**, not its visual centre. Anchor body sprites
   with `Iso.anchor_feet(sprite, sink)`; the upright cast (hero, survivors, husks)
   go through `Iso.mount_body(sprite)`, which feet-anchors AND knocks the sprite
   down by `Palette.ACTOR_SCALE` so bodies read at a Hades remove from the world.
   `Iso.walk_anim()` then drives the flip-based turnaround plus a step-bob/squash.
2. **Distances are ground distances** — `Iso.gdist()`, never `distance_to()`, or every
   range becomes an egg. Aim with `Iso.gdir()`; convert back with `Iso.offset()`.
3. **Depth is Y order.** Layer roots set `y_sort_enabled`; anything standing on the
   floor keeps `z_index == 0` so it sorts by its feet.
4. **Everything standing casts a contact shadow** (`Iso.shadow`). Without it a
   billboard is a sticker floating in space.

`Iso` also owns the lighting helpers: `ambient()` (the `CanvasModulate` wash that
makes lights visible at all), `light()` (a ground-flattened `PointLight2D`),
`flicker()`, and `prop()` for a feet-anchored, shadowed scenery sprite.

### z_index convention (within a y-sorted layer)
| z | what |
|---|---|
| -10 | ground tiles |
| -9 | floor decals — rubble, bones, the build-grid guide |
| -8 | platform edges / cliff faces |
| 0 | **everything standing on the floor** — actors, buildings, props, wall blocks |
| 30 | build-placement ghost |
| 40 / 50 / 100 | slashes / particles / floating text |

---

## 2. The art pipeline

| file | role |
|---|---|
| `scripts/art.gd` (`Art`) | the shared vector engine — signed-distance primitives, anti-aliased fills, rim light, ground occlusion, gradients, falloff discs, seamless wrap-scatter |
| `scripts/art_env.gd` (`ArtEnv`) | ground tiles, wall blocks, platform edges, buildings, crops |
| `scripts/art_props.gd` (`ArtProps`) | portal, gate, cage, brazier, bonfire, scenery, pickups |
| `scripts/art_cast.gd` (`ArtCast`) | the cat hero, the survivors, the husks |
| `scripts/art_fx.gd` (`ArtFx`) | contact shadow, light falloff, particles, slashes, UI icons |
| `scripts/assets.gd` (autoload `Assets`) | the catalogue: runs the modules, owns the cache, serves `Assets.tex(key)` |

Textures bake at **2× on-screen size** (`Palette.PX = 0.5`) with a linear filter, so
the art stays smooth as the camera zooms. `Art.paint()` scans only each shape's
bounding box, so a sprite is built from many small calls rather than one big union —
that is what gives each form its own light falloff instead of one flat gradient.

**Bake cache.** Drawing the full catalogue costs ~9 s, a visible freeze on launch, so
`Assets` fingerprints the art sources (MD5 over `art*.gd`, `palette.gd`, `assets.gd`)
and parks the baked PNGs in `user://artcache/<project>/<fingerprint>/`. Warm start is
~10 ms. Editing any art file changes the fingerprint, so the cache cannot go stale —
but the first run after an art edit pays the full bake. That is expected.

---

## 3. Autoloads and shared services

**`Palette`** — display constants (`PX`, `TILE`, `CELL`, `SQUASH`, `CELL_Y`, `TILE_W`,
`TILE_H`, `WALL_H`, `WALL_H_TEX`) and the colour system: the original storybook
palette, the 2.5D presentation palette (`VOID INK PLUM PLUM_L WINE TORCH TORCH_L
GOLD_L CYAN MOSS_L EARTH …`), per-layer ambient (`AMBIENT_VILLAGE`,
`AMBIENT_DUNGEON`), the `RIM` light tint, and the `UI_*` chrome colours.

**`Assets`** — `tex(key)`, `has(key)`, `put(key, image)`. An unknown key logs a
warning and returns the player texture, so a missing asset is loud but not fatal.

**`GameState`** — `resources`, `rescued`, `grid` (Vector2i → {"type","built"}), `gwi`,
`run_count`, `village_seeded`; `add_resource` / `amount` / `can_afford` / `spend` /
`add_rescued` / `has_rescued` / `add_gwi` / `set_gwi`; signals `resources_changed`,
`roster_changed`, `gwi_changed(value)`. Owns the input actions: `move_*`, `interact`
(E), `attack` (LMB), `build_menu` (B), `cancel` (Esc).

**`Vfx`** (static) — `embers`, `dust`, `slash`, `hit_spark`, `impact`, `hitstop`,
`float_text`. All 2.5D-aware: effects that *spread* are squashed into the floor plane,
effects that *rise* travel in un-squashed screen Y.

---

## 4. `Main` — scene manager, camera rig, and the grade

`Main` holds the one persistent `Player` and `Hud` across layer swaps, runs the
central interaction scan (in ground distances), and drives a Hades-style camera:
dead zone, cursor look-ahead, critically damped follow, trauma shake, zoom punch, and
clamping to the layer's bounds. It owns the single full-screen post-process on
`CanvasLayer(1)`.

**Layer contract** — what `Main` asks of `Village` / `Dungeon`:

| | |
|---|---|
| required | `spawn_point() -> Vector2`, and a `hud` property assigned before the layer enters the tree |
| optional | `camera_bounds() -> Rect2` — the world rect the camera may show; `has_method`-guarded |

**Global hooks** (static, so any module can reach the rig):
`Main.shake(amount)` · `Main.zoom_punch(amount)` · `Main.set_grade(warm, vignette, bloom)`

**`shaders/post.gdshader`** — uniforms `warm` (cold ash → ember radiance), `vignette`,
`bloom` (threshold + `textureLod` on the screen texture), `grain`.

**Interaction protocol** — anything the player can press **E** on joins group
`"interactable"` and implements exactly:

```gdscript
func interact_radius() -> float          # ground px
func can_interact(by: Node) -> bool
func interact_prompt() -> String         # e.g. "Free survivor  [E]"
func do_interact(by: Node) -> void
```

`Main` picks the single nearest valid one each frame and shows its prompt.

**`Hud` API** used by the layers: `toast(text, color)`, `open_build_menu(entries)`
(entries are `{"id","label","cost","affordable"}`), `close_build_menu()`,
`set_hp(hp, max_hp)`, `set_gwi(v)`, `show_prompt(text)`, `hide_prompt()`; signals
`build_selected(id)` and `build_cancelled`. Layers always null-guard `hud`.

**Context-aware combat HUD.** One HUD, two skins, flipped by a single `_combat`
bool. `Main._install_layer` calls `set_combat(is_dungeon)` *before* the layer builds,
so the world populates an already-correct HUD: village = full economy chrome
(resources, warmth, roster); ruins = a lean frame (economy folds away, corners dim,
hearts relocate bottom-left with **dash / riposte ability pips** beneath). The pips
are self-polled — the HUD's own `_process` (enabled only in combat) reads the hero's
`_dash_cd` / `_counter_t` by group, so the player pushes nothing per-frame. The
Dungeon drives `set_enemies(remaining, total)` (top-left husk tally, cached
`_spawn_total`) from `_on_enemy_died`, and `show_boss(name, max_hp)` /
`set_boss_hp(hp)` / `hide_boss()` for the centred Warden bar (which suppresses the
depth caption while up). All calls are `has_method`-guarded. Note: HUD icon
`TextureRect`s set `expand_mode = EXPAND_IGNORE_SIZE` so `custom_minimum_size` — not
the large source PNG — decides their layout footprint.

---

## 5. Layers

**`Village`** — the settlement: a large, lit, walkable **field** (FIELD cells each way)
centred on a **bonfire hearth**, so the base is never a dark patch. Only the tended
**clearing** within `GameState.village_radius` cells of centre is buildable (bright
grass); beyond it is wilder worn grass you reclaim by choosing **Expand Clearing**
in the build menu for a rising resource cost — the map grows with the run rather than
being a fixed grid. A boundary rings the whole field and `camera_bounds()` keeps the
frame on it. It reads as an **open-air, sunlit sanctuary**: a warm daylight grade
(bright even when cold), a stream with a plank **bridge** and reeds, and living
trees, bushes, wildflowers and rocks scattered through the wild grass (`tree`,
`bush`, `flowers`, `reeds`, `bridge`, `tile_water` — see `art_props`/`art_env`).
Every survivor brought home becomes a `Villager` who **wanders and works** the
clearing and offers a one-off **quest** (`Village.QUESTS`, state in
`GameState.quests`): talk to accept, meet a resource/build goal, turn in for warmth
(GWI) + materials. Buildings are placed from the build menu, hammered up from a
`Scaffold`, and warm the world (GWI); a `CropPlot` cycles seed → sprout → leafy →
ripe. The
`SupplyGate` starts an expedition.

**`Dungeon`** — one procedurally generated ruin chamber run as a **Hades-style
locked arena**: braziers carve pools of firelight out of a near-black ambient, a
warm light rides with the hero, and the exits stay **sealed until every husk is
cleared**. On clear, two `ExitGate`s rise with a floating reward preview — a cyan
**HOME** gate (bank loot, end the run → `exited`) and a warm **DEEPER** gate (next
arena → `advance_requested`). `Main` chains rooms within a run via `room_index`,
carrying the hero's hp and loot forward and scaling husk count/toughness and loot
with depth; a caged survivor waits in room 1.

**Run map** (`scripts/run_map.gd`, `RunMap`) — a run rolls a branching layered node
graph (combat / treasure / rescue / rest / boss at the end). The `Dungeon` reads
its node's type to populate the room; on clear, one `ExitGate` opens per reachable
node (each previewing that type) plus a HOME gate; walking through commits to that
node. **Tab** opens a Cult-of-the-Lamb-style overview drawn by the HUD — the whole
graph, your position, the reachable branches. `GameState.run_map` holds it for the
run and is cleared on return home.

---

## 6. GDScript 4.7 pitfalls (these have bitten this project)
- Never `:=` from a Variant. Loop vars over untyped arrays, `dict[...]`, `.get(...)`,
  `node.get(...)` and `has_method` results are Variant → annotate explicitly.
- `move_and_slide()` takes no args; set `velocity` first.
- A `var` and a `signal` may not share a name.
- Timers: `get_tree().create_timer(s).timeout.connect(cb)`. Guard tweens with
  `is_instance_valid` before touching a possibly-freed node.
- Never put non-uniform `scale` on a physics body or any of its ancestors.
- `PointLight2D` needs a `texture`, `blend_mode = Light2D.BLEND_MODE_ADD` and
  `texture_scale`; lights are only visible against a `CanvasModulate`.
  `CanvasModulate` affects its own canvas layer only — the HUD (layer 10) and the
  post-process (layer 1) are unaffected.
- Adding a file with a new `class_name` needs a project rescan before the identifier
  resolves: `godot --headless --path . --import`.

## 7. Tools (not shipped)
- `tools/autoplay.tscn` — a hands-off bot that plays a full loop (build → descend →
  fight → rescue → choose gates deeper → boss → home) through simulated input, so you
  can watch the game's progress. Launch with `./play.sh autoplay`.
- `tools/capture.tscn` — plays the real game and writes six frames to `res://_shot_*.png`:
  village cold, village warm, build menu, hero close-up, dungeon, dungeon combat.
- `tools/export_art.tscn` — freezes the code-drawn catalogue to `res://art/*.png` (+ the
  `_manifest.txt` and `_templates/`), the files the game then renders from.
- `tools/sheet.tscn` — lays the whole baked catalogue out on a board → `res://_shot_sheet.png`.
- `tools/bench.tscn` — times the baker's inner loops.
