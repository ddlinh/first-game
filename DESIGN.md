# REKINDLED — Vertical Slice: Architecture & Build Contract

A post-apocalyptic roguelite (concept: `rekindled_master_concept.html`). This slice
proves the **full core loop**: enter a subterranean ruin → fight husks → rescue a
survivor → carry materials home → build on the 8×8 village grid (hammer by hand) →
plant & harvest a crop → the village warms (GWI) → run again.

Engine: **Godot 4.7.1**. GDScript. Art: procedurally-baked pixel sprites.

## Design philosophy (from the concept doc)
- Civilization lives in **people & knowledge**, not loot. Rescuing a survivor is the
  emotional beat — it fires embers and grants a support buff.
- **Dual-layer loop**: Expedition (roguelite, run-scoped buffs) ↔ Settlement (persistent).
- **GWI** (Global Warmth Index 0→1): the world visibly reignites as you build.
- Onboarding: hand-hammer your first building; rescuing a Builder later automates it.

---

## Architecture: code-first
Entities are plain scripts with `class_name` that **build their own children in
`_ready()`** (Sprite2D, CollisionShape2D, …). Almost no `.tscn` files — only
`Main.tscn`. This keeps modules self-contained and independently authorable.

### File map
| File | Class | Owner | Status |
|------|-------|-------|--------|
| `scripts/palette.gd` | (autoload `Palette`) | lead | DONE |
| `scripts/assets.gd` | (autoload `Assets`) | lead | DONE |
| `scripts/game_state.gd` | (autoload `GameState`) | lead | DONE |
| `scripts/vfx.gd` | `Vfx` | lead | DONE |
| `shaders/gwi.gdshader` | — | lead | DONE |
| `scripts/player.gd` | `Player` | module | TODO |
| `scripts/enemy.gd` | `Enemy` | module | TODO |
| `scripts/survivor.gd` | `Survivor` | module | TODO |
| `scripts/dungeon.gd` | `Dungeon` | module | TODO |
| `scripts/village.gd` | `Village` | module | TODO |
| `scripts/hud.gd` | `Hud` | lead | TODO |
| `scripts/main.gd` + `Main.tscn` | `Main` | lead | TODO |

---

## Autoload APIs (already built — DO NOT modify these files)

### `Palette` — constants
- `PX := 3`, `TILE := 16`, `CELL := 48` (one grid cell in on-screen px).
- Colors: `EMBER, EMBER_D, AMBER, GOLD, TEAL, SPROUT, SOIL, SOIL_D, GRASS, GRASS_D,
  WOOD, WOOD_D, ROOF, STONE, STONE_D, IRON, SKIN, HAIR, WHITE, BLACK, BLOOD,
  COLD_FLOOR, COLD_FLOOR2, COLD_WALL, STEEL, INDIGO, HUSK, HUSK_D, HUSK_SKIN,
  GWI_COLD, GWI_WARM`.

### `Assets`
- `Assets.tex(key: String) -> Texture2D`  ·  `Assets.has(key) -> bool`
- Keys: `player`, `survivor_farmer|smith|builder`, `enemy_husk`, `enemy_brute`,
  `building_cabin|forge|crop_bed|scaffold`, `crop_0..3`,
  `tile_floor|wall|grass|dirt`, `portal`, `cage`, `supply_gate`,
  `material_wood|stone|iron|food`, `ember`, `slash`.

### `GameState`
- Vars: `resources: Dictionary` (keys `wood,stone,iron,food,seeds`), `rescued: Array[String]`,
  `grid: Dictionary` (Vector2i→{"type","built"}), `gwi: float`, `run_count: int`,
  `village_seeded: bool`.
- `add_resource(kind, amount)` · `amount(kind)->int` · `can_afford(costs:Dictionary)->bool`
  · `spend(costs)->bool` · `add_rescued(pillar)` · `has_rescued(pillar)->bool`
  · `add_gwi(delta)` · `set_gwi(v)`.
- Signals: `resources_changed`, `roster_changed`, `gwi_changed(value: float)`.
- Input actions already registered: `move_up/down/left/right`, `interact` (E),
  `attack` (LMB), `build_menu` (B), `cancel` (Esc).

### `Vfx` (static)
- `Vfx.embers(parent, gpos, amount:=16, color:=Color("ff6b35"))`
- `Vfx.slash(parent, gpos, dir: Vector2)`
- `Vfx.hit_spark(parent, gpos)`
- `Vfx.float_text(parent, gpos, text, color:=Color(1,1,1,1))`

---

## Shared conventions

**Sprite construction** (use everywhere):
```gdscript
var s := Sprite2D.new()
s.texture = Assets.tex("player")
s.scale = Vector2(Palette.PX, Palette.PX)   # 16px art → 48px on screen, centered
add_child(s)
```

**World scale**: 1 grid cell = `Palette.CELL` (48 px). Character body radius ≈ 9 px.

**Groups**: player node → `add_to_group("player")`; enemies → `add_to_group("enemy")`.
Find the player: `get_tree().get_first_node_in_group("player")`.

**Interaction protocol** — anything the player can press **E** on joins group
`"interactable"` and implements exactly:
```gdscript
func interact_radius() -> float          # world px, e.g. 34.0
func can_interact(by: Node) -> bool
func interact_prompt() -> String         # e.g. "Free survivor  [E]"
func do_interact(by: Node) -> void
```
`Main` scans every frame: takes the player, picks the nearest interactable within its
`interact_radius()` whose `can_interact(player)` is true, shows its prompt, and on the
`interact` action calls `do_interact(player)`. Only the single nearest one is active.

**HUD access**: `Main` sets `layer.hud` (a `Hud`) before adding the layer to the tree,
so it is available in the layer's `_ready()`. Always null-guard: `if hud: hud.toast(...)`.
Hud API the layers may use:
- `hud.toast(text: String, color := Color("f7c59f"))`
- `hud.open_build_menu(entries: Array)` where each entry is
  `{"id": String, "label": String, "cost": Dictionary, "affordable": bool}`
- `hud.close_build_menu()`
- signals: `hud.build_selected(id: String)`, `hud.build_cancelled` (connect with null-guard).

**GDScript 4.7 pitfalls (MANDATORY)**:
- NEVER `:=` infer from a Variant. Loop vars over untyped arrays, `dict[...]`,
  `.get(...)`, `node.get(...)`, `has_method` results are Variant → use explicit types:
  `var nx: int = x + d.x`.
- `move_and_slide()` takes no args; set the `velocity` property first.
- Signals: declare `signal foo(x)`; emit `foo.emit(x)`; connect `o.foo.connect(cb)`.
- Timers: `get_tree().create_timer(sec).timeout.connect(cb)`.
- Tweens: `var tw := create_tween()` on a Node.
- RNG: `randi_range(a,b)`, `randf_range(a,b)`, `randf()`. (`Main` calls `randomize()`.)
- Physics: `CharacterBody2D` + child `CollisionShape2D` holding a `CircleShape2D`
  (`var c := CircleShape2D.new(); c.radius = 9`). Keep default collision layers/masks.
- Area2D pickups: `area.body_entered.connect(cb)`; player is a body in group `"player"`.
- Helper classes used by only one module → define as **inner classes** in that file.

---

## Module specs

### `Player` (`scripts/player.gd`, `class_name Player extends CharacterBody2D`)
Children in `_ready()`: Sprite2D `tex("player")`; CollisionShape2D circle r≈9; join
group `"player"`. Set `z_index` by y is handled by Main (skip).

State: `base_speed := 150.0`, `base_max_hp := 6`, `base_damage := 2`,
`max_hp`, `hp`, `speed_mult := 1.0`, `damage_mult := 1.0`, `combat_enabled := true`,
`attack_cd := 0.34` (timer), `facing := Vector2.RIGHT`.

Signals: `hp_changed(hp: int, max_hp: int)`, `died`.

Movement (`_physics_process`): read `move_*` actions → normalized dir →
`velocity = dir * base_speed * speed_mult` → `move_and_slide()`. Track `facing` from
dir (or from mouse). 

Attack (`_process` or input): when `combat_enabled` and `attack` action pressed and
cooldown ready → swing toward the mouse (`(get_global_mouse_position()-global_position)`):
- `Vfx.slash(get_parent(), global_position + dir*22, dir)`
- overlap-scan enemies: for each node in group `"enemy"` within ~40 px and roughly in
  the `dir` hemisphere (`dir.dot((e.global_position-global_position).normalized()) > 0.25`),
  call `e.take_damage(int(round(base_damage * damage_mult)), dir)`.
- start cooldown.

`func take_damage(n: int) -> void`: if invulnerable (brief i-frames ~0.6s) return;
`hp -= n`; flash sprite red (modulate tween); `hp_changed.emit(hp,max_hp)`;
`Vfx.float_text(...)` optional; if `hp <= 0` → `died.emit()` (once).

`func apply_buff(kind: String) -> void`: `"armor"`→ `max_hp+=2; hp+=2`;
`"damage"`→ `damage_mult+=0.5`; `"speed"`→ `speed_mult+=0.2`. Then `hp_changed.emit`.
`Vfx.embers(get_parent(), global_position, 10, Palette.GOLD)`.

`func begin_run() -> void`: reset `max_hp=base_max_hp; hp=max_hp; speed_mult=1;
damage_mult=1; combat_enabled=true`; `hp_changed.emit`. (Run buffs are per-run.)
`func enter_village() -> void`: `combat_enabled=false; hp=max_hp; hp_changed.emit`.

### `Enemy` (`scripts/enemy.gd`, `class_name Enemy extends CharacterBody2D`)
Children: Sprite2D (default `tex("enemy_husk")`); CollisionShape2D circle r≈9; group
`"enemy"`. `func configure(hp:int, speed:float, tex_key:String) -> void` to vary it
(call before/after adding; store then apply in `_ready` if not yet built — simplest:
expose vars `max_hp`, `speed`, `touch_damage`, `tex_key` with defaults and read them in
`_ready`). Defaults: `max_hp=4, speed=72, touch_damage=1, tex_key="enemy_husk"`.

Signals: `died(pos: Vector2)`.

`_physics_process`: find player via group; if present move toward it
(`velocity = toward*speed`, `move_and_slide()`); on contact (dist < ~22) call
`player.take_damage(touch_damage)` on a ~0.8s internal cooldown.

`func take_damage(n: int, from_dir := Vector2.ZERO) -> void`: `hp-=n`; flash;
knockback (`global_position += from_dir*6`); `Vfx.hit_spark(get_parent(), global_position)`;
if `hp<=0`: `died.emit(global_position)`; `Vfx.embers(get_parent(), global_position, 8, Palette.STEEL)`;
`queue_free()`.

### `Survivor` (`scripts/survivor.gd`, `class_name Survivor extends CharacterBody2D`)
Vars: `pillar := "farmer"` (set before adding to tree), `freed := false`,
`follow_target: Node2D = null`, `speed := 165.0`. In group `"interactable"`.
Children: body Sprite2D `tex("survivor_"+pillar)` (fallback farmer); a cage overlay
Sprite2D `tex("cage")` shown while caged (removed on free); CollisionShape2D circle.

Interaction protocol: `interact_radius()->34.0`; `can_interact(by)-> not freed`;
`interact_prompt()-> "Free %s  [E]" % pillar`; `do_interact(by)-> free_it(by)`.

`func free_it(by: Node) -> void`: guard `freed`; `freed=true`; remove cage sprite;
`follow_target = by`; leave group `"interactable"`; `GameState.add_rescued(pillar)`;
map buff (`farmer→"armor", smith→"damage", builder→"speed"`) and if
`by.has_method("apply_buff")` call it; `Vfx.embers(get_parent(), global_position, 24, Palette.EMBER)`;
`emit` a `freed(pillar: String)` signal.

`_physics_process`: if `freed` and `follow_target` valid, if dist to target > ~40 move
toward it (`velocity = toward*speed`, `move_and_slide()`), else idle.

### `Dungeon` (`scripts/dungeon.gd`, `class_name Dungeon extends Node2D`)
Public: `var hud` (set by Main); `signal exited`; `func spawn_point() -> Vector2`
(where Main places the player — near the entrance at the bottom).

`_ready()` builds ONE procedurally-decorated ruin chamber (v1 is a single chamber, not
multi-room — a wide rectangular hall with a solid wall border plus a handful of random
interior wall blocks as cover). Steps:
1. Pick chamber size in tiles, e.g. `W=26, H=16` (× CELL). Build a `walkable` grid.
   Border cells = wall; scatter ~6–10 random 1–2 tile wall blocks inside as cover
   (keep the entrance column and portal area clear).
2. Render tiles: for every cell add a Sprite2D (`tile_floor` for walkable, `tile_wall`
   for walls) at `cell*CELL + CELL/2`, scale PX. Give wall cells a `StaticBody2D` with a
   rectangle `CollisionShape2D` (CELL×CELL) so the player/enemies can't pass. (A single
   StaticBody2D with many CollisionShape2D children is fine.)
3. Spawn a `Portal` (inner class, interactable) in the top area; `do_interact` →
   `exited.emit()`.
4. Spawn 1 `Survivor` (`pillar = "farmer"`) in a far corner (add to tree; it self-cages).
5. Spawn `randi_range(4,6)` `Enemy` on random walkable cells away from the entrance;
   connect each `died(pos)` → drop: 45% chance spawn a `Pickup` (inner class) of a random
   material at pos.
6. Scatter ~4 `Pickup`s (wood/stone/iron) on walkable cells.
Camera bounds not required. Use `randomize`-seeded RNG (Main randomizes).

`Pickup` (inner `Area2D`): Sprite2D `tex("material_"+kind)` scale PX; on
`body_entered(body)` if body in group `"player"`: `GameState.add_resource(kind,1)`;
`Vfx.float_text(get_parent(), global_position, "+1 "+kind, Palette.AMBER)`; `queue_free()`.

`Portal` (inner, interactable Node2D): Sprite2D `tex("portal")`; radius 40;
`can_interact` always true; prompt `"Return home  [E]"`; `do_interact` → `exited.emit()`
(reference the Dungeon via a stored ref or `get_parent()`... store `var dungeon` set on spawn).

### `Village` (`scripts/village.gd`, `class_name Village extends Node2D`)
Public: `var hud`; `signal expedition_requested`; `func spawn_point() -> Vector2`
(centre-ish, on grass).

Grid: 8×8, `GRID := 8`. Cell (gx,gy)∈[0,8) maps to world
`Vector2(gx,gy)*Palette.CELL + Vector2(CELL/2,CELL/2)` offset so the grid is centred
around origin (subtract `GRID*CELL/2`). Store an `origin` and helper
`cell_to_world(Vector2i)` / `world_to_cell(Vector2)`.

`_ready()`:
1. Render 8×8 grass tiles (Sprite2D `tile_grass`), plus a subtle 1px grid line overlay
   (a `_draw`/Line2D or dim ColorRects — optional).
2. Add the **GWI overlay**: a `CanvasLayer` (layer = 1) containing a full-rect
   `ColorRect` sized to the viewport with `ShaderMaterial(load("res://shaders/gwi.gdshader"))`;
   set `gwi` uniform from `GameState.gwi`; update on `gwi_changed`. Set the ColorRect
   `mouse_filter = IGNORE` and anchor full-rect; make it follow the viewport size.
   (If the shader misbehaves, fall back to a `CanvasModulate` lerping `Palette.GWI_COLD`
   →`GWI_WARM` by gwi — but try the shader first.)
3. First-time seeding: if not `GameState.village_seeded`: place one pre-built Crop Bed at
   a fixed cell (so farming is reachable turn 1), set `village_seeded=true`. Then always
   rebuild every entry in `GameState.grid`: built ones → finished building sprite (+ crop
   plots if crop_bed); unbuilt ones → a `Scaffold`.
4. Place a `SupplyGate` (inner, interactable) at a grid edge → `do_interact` →
   `expedition_requested.emit()`. Prompt `"Descend into the ruins  [E]"`.
5. Connect `hud.build_selected`/`build_cancelled` (null-guarded) and
   `GameState.gwi_changed`.

Building table (module owns this):
```
BUILDINGS = {
  "cabin":    {"label":"Cabin",    "cost":{"wood":5,"stone":2}, "tex":"building_cabin", "gwi":0.18},
  "forge":    {"label":"Forge",    "cost":{"stone":4,"iron":2}, "tex":"building_forge", "gwi":0.15},
  "crop_bed": {"label":"Crop Bed", "cost":{"wood":3},           "tex":"building_crop_bed","gwi":0.05},
}
```

Build flow:
- On `build_menu` action (and not already placing): build `entries` from BUILDINGS with
  `affordable = GameState.can_afford(cost)`; `hud.open_build_menu(entries)`.
- On `hud.build_selected(id)`: enter **placement mode** — a translucent ghost Sprite2D of
  the building follows the mouse, snapped to the nearest empty grid cell; `close_build_menu`.
- Left click (`attack` action or `_unhandled_input` mouse) on an empty in-bounds cell:
  if `GameState.can_afford(cost)` → `GameState.spend(cost)`, record
  `GameState.grid[cell] = {"type":id,"built":false}`, spawn a `Scaffold` at the cell,
  exit placement mode. Else `hud.toast("Not enough materials", Palette.BLOOD)`.
- `cancel` action exits placement/menu.

`Scaffold` (inner, interactable Node2D): stores `cell: Vector2i`, `build_id: String`,
`village` ref, `progress := 0.0`. Sprite2D `tex("building_scaffold")`.
- `interact_prompt()-> "Hammer  [E]  (%d%%)" % int(progress*100)`; `can_interact`→ not done.
- `do_interact(by)`: `progress += 0.34`; `Vfx.embers(get_parent(), global_position, 6, Palette.AMBER)`;
  hammer thunk sprite shake (optional); if `progress>=1.0` → `_complete()`.
- `_process(delta)`: if `GameState.has_rescued("builder")`: `progress += delta*0.5`
  (auto-build); if `progress>=1.0` → `_complete()`.
- `_complete()`: `village.finish_building(cell, build_id)` then `queue_free()`.

`Village.finish_building(cell, build_id)`: set `grid[cell].built=true`; add the finished
building Sprite2D at the cell; `GameState.add_gwi(BUILDINGS[build_id].gwi)`;
`Vfx.embers(...)` big; `hud.toast("%s raised!" % label, Palette.GOLD)`; if
`build_id=="crop_bed"` spawn a `CropPlot` at that cell.

`CropPlot` (inner, interactable Node2D): `stage := -1` (-1 = empty), `t := 0.0`,
`STAGE_TIME := 4.0`. Sprite2D updated to `crop_<stage>` when growing.
- empty: prompt `"Plant seed  [E]"`; `can_interact`→ `stage==-1 and GameState.amount("seeds")>0`;
  `do_interact`→ if seeds: `GameState.spend({"seeds":1})`; `stage=0`; update sprite.
- growing: `_process` advances `t`; every `STAGE_TIME` → `stage=min(stage+1,3)`; update sprite.
- ripe (`stage==3`): prompt `"Harvest  [E]"`; `do_interact`→ `GameState.add_resource("food",2)`;
  `GameState.add_resource("seeds",1)`; `Vfx.embers/float_text`; `stage=-1`; update sprite.

---

## Integration (lead builds `Main`/`Hud`)
- `Main` owns one persistent `Player` (created once), a `Camera2D` (follows player,
  mouse-wheel zoom clamped ~[1.4, 3.2]), and the `Hud`. It starts in the Village.
- `start_dungeon()`: free village; make `Dungeon`; `hud`-inject; add; reparent player to
  its `spawn_point()`; `player.begin_run()`; connect `dungeon.exited`.
- `return_to_village()`: free dungeon; make `Village`; inject; add; reparent player to
  `spawn_point()`; `player.enter_village()`; connect `village.expedition_requested`.
- Interaction scan + prompt (per the protocol). Connect `player.died` → toast + delayed
  `return_to_village()`.

## First-build scope (explicit, no hidden cuts)
- Dungeon procgen = ONE decorated chamber (not multi-room / multi-floor). One survivor
  (farmer). No run-buff shrines yet (rescue buff only). No co-op / AI companions.
- Village: 3 buildings (cabin, forge, crop bed) + 1 crop type. GWI via shader. No
  quest/tech-tree UI yet (quests are implied by building).
- Everything above is a deliberate slice of the full concept, to be expanded later.
