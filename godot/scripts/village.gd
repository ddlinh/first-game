class_name Village
extends Node2D
## The persistent settlement layer. The world is a large, lit, walkable FIELD
## centred on the hearth; only the tended CLEARING within `GameState.village_radius`
## cells of centre is buildable, and you spend resources to expand it outward — the
## map is not a fixed little grid. Applies the GWI grade, rebuilds recorded
## structures, grows crops, and hosts the Supply Gate. Main injects `hud`, reads
## `spawn_point()`, listens for `expedition_requested`.

# Fired when the player uses the Supply Gate — Main frees this and loads the Dungeon.
signal expedition_requested

# Cells are centred on multiples of CELL, with (0,0) at the hearth. FIELD is the
# spacious walkable world (half-extent in cells); the buildable clearing grows from
# START_RADIUS up to FIELD-1 as the player expands it.
const FIELD := 9
const CENTER := Vector2i.ZERO
const START_RADIUS := 2

# The module owns the buildable catalogue: cost, finished texture, the GWI warmth
# each completed building radiates, and a one-line effect blurb. The blurb + warmth
# are surfaced on the build-menu card (like a city-builder's building tooltip) so the
# player picks by what a structure DOES, not just what it costs (QA UX: build menu).
const BUILDINGS := {
	"cabin": {"label": "Cabin", "cost": {"wood": 5, "stone": 2}, "tex": "building_cabin", "gwi": 0.18,
		"desc": "Shelter for a survivor. Toughens you (+Max HP) on your next descent."},
	"forge": {"label": "Forge", "cost": {"stone": 4, "iron": 2}, "tex": "building_forge", "gwi": 0.15,
		"desc": "Work iron into blades. Sharpens your strikes (+Damage) below."},
	"crop_bed": {"label": "Crop Bed", "cost": {"wood": 3}, "tex": "building_crop_bed", "gwi": 0.05,
		"desc": "Tilled soil to grow food — seeds become Provisions that heal mid-run."},
	"workshop": {"label": "Workshop", "cost": {"wood": 6, "stone": 3}, "tex": "building_workshop", "gwi": 0.14,
		"desc": "The Carpenter's craft. Sharpens your eye (+Crit) below, and speeds every build."},
}

# The farm the Farmer establishes (VILLAGE_DESIGN P1). It is NOT a free build: rescuing
# the Farmer lays out this fallow cell from his knowledge, and the hero must supply the
# materials he lacks to break it into a working farm.
const FARM_CELL := Vector2i(2, 1)
const FARM_SETUP := {"wood": 6, "seeds": 4}       # break the fallow ground (fallow → active)
const FARM_IRRIGATE := {"stone": 8, "wood": 4}    # the Farmer's follow-up project (active → irrigated)

# Buildings can be upgraded Lv1→3 (VILLAGE_DESIGN P2/V6): each tier deepens the run-boon
# and warmth, and the structure visibly grows. Only the two combat buildings upgrade
# this way; the farm has its own Farmer-driven progression.
const MAX_BUILD_LEVEL := 3
const UPGRADABLE := {"cabin": true, "forge": true, "workshop": true}

# Warmth radiates from the hearth and dissipates with distance (real heat transfer): a
# structure raised close to the bonfire retains and returns more of its warmth than one
# out in the cold. This gives PLACEMENT a real, physical decision (CRITIQUE V2 /
# VILLAGE_DESIGN V10) — you cluster the settlement around its fire, the way cold-climate
# builders always have. Tied straight to the game's own metallurgy-is-thermodynamics line.
const WARMTH_NEAR := 1.0    # multiplier for a build on the hearth ring
const WARMTH_FAR := 0.45    # multiplier at the field's cold outer edge
# Demolition reclaims REUSABLE material, not the labour or the waste — real salvage rates
# run well under 100%. Half the invested materials (base cost + every upgrade tier) come
# back; the rest is lost to the teardown (CRITIQUE V1).
const SALVAGE_FRAC := 0.5

# --- Living settlement: population growth (VILLAGE_DESIGN P4/P5) ---
# While you tend the village, a fed AND housed settlement draws wanderers in. Growth is
# gated on HOUSING (Cabins) and FOOD (the farm), so the buildings interdepend and the town
# only grows if you keep both up. There is deliberately no starvation/death spiral — an
# unfed or unhoused town simply stops growing.
const GROW_INTERVAL := 12.0   # seconds of village time between settler-arrival checks
const GROW_FOOD_COST := 3     # food a newcomer consumes settling in

# Warm one-liners a settler offers when greeted — pure flavour, no mechanics.
const SETTLER_LINES := [
	"I followed the light through the frost. It's warm here… I'll stay.",
	"Give me a task and I'll earn my place by the fire.",
	"They said the ember-bearer walks again. I had to feel the warmth myself.",
	"A roof, a hearth, a full larder — I'd near forgotten what a home was.",
]

# One quest per rescued pillar. `res` is the resource threshold to reach; on turn-in
# the pillar rewards warmth (GWI) plus materials. Keeps the village loop purposeful.
const QUESTS := {
	"farmer": {"title": "Fill the larder", "res": "food", "need": 6,
		"reward": {"seeds": 2, "wood": 2}, "gwi": 0.10,
		"ask": "Grow us a store of food — bring the larder to 6.",
		"thanks": "The larder's full. We'll not go hungry now."},
	"smith": {"title": "Stoke the forge", "res": "iron", "need": 5,
		"reward": {"stone": 4}, "gwi": 0.10,
		"ask": "Haul me 5 iron from the ruins and I'll get the forge roaring.",
		"thanks": "Iron enough — the forge breathes fire again."},
	"builder": {"title": "Raise the roofs", "res": "_built", "need": 3,
		"reward": {"wood": 5}, "gwi": 0.15,
		"ask": "A village needs walls. Raise 3 buildings and I'll frame the rest.",
		"thanks": "Three roofs stand. This is a home again."},
}

# Once a survivor's one-off quest is done, they keep working: a REPEATABLE commission
# that trades a stack of materials for warmth + a little something back. This gives the
# village a standing purpose (and warmth a sink) instead of going inert after three
# quests — the ongoing-jobs loop farming/settlement builders lean on (fixes QA F-14).
const COMMISSIONS := {
	"farmer":  {"res": "food", "need": 4, "reward": {"seeds": 2}, "gwi": 0.04,
		"ask": "Keep the larder full — 4 food sees us through the cold."},
	"smith":   {"res": "iron", "need": 3, "reward": {"stone": 3}, "gwi": 0.04,
		"ask": "The forge is always hungry — 3 iron keeps it roaring."},
	"builder": {"res": "wood", "need": 4, "reward": {"stone": 2}, "gwi": 0.04,
		"ask": "There's always a roof to mend — 4 wood for the repairs."},
}

# Injected by Main before this node enters the tree (a Hud). Left untyped on
# purpose: the Hud class is not compiled into this module. Always null-guarded.
var hud

# The run-start gate, kept so the guidance beacon can point the player at it.
var _supply_gate: Node2D = null
# Holds the ground tiles so the clearing can be re-rendered when it expands.
var _ground: Node2D = null
# cell -> the building's visual root, so an upgrade can rescale it in place.
var _building_roots: Dictionary = {}
# Cells occupied by the stream — walkable but never buildable.
var _river_cells: Dictionary = {}

# --- Build placement state ---
var _placing: bool = false          # true while a ghost is following the cursor
var _place_id: String = ""          # which building the ghost represents
var _ghost: Sprite2D = null         # translucent preview sprite

# --- Warmth (GWI) visible-thaw handles, updated on gwi_changed (QA F-23) ---
var _bonfire_root: Node2D = null           # the hearth prop, so its flame can grow
var _bonfire_light: PointLight2D = null    # the hearth pool, brightening with warmth
var _bonfire_flicker: Tween = null         # the hearth's living flicker (rebuilt on warmth change)
# Dead things that green over as the world reignites: {"sprite", "threshold", "thawed"}.
var _thaw_markers: Array = []
# --- Build placement guide (grid + hovered-cell box, QA F-20) ---
var _place_guide: PlaceGuide = null

# --- Construction management: relocate / demolish (CRITIQUE V1/V4) ---
const NO_CELL := Vector2i(-999, -999)
# The cell the Build menu is currently MANAGING (upgrade / relocate / demolish).
var _manage_cell: Vector2i = NO_CELL
var _manage_active: bool = false
# While relocating, the cell we are moving a finished building FROM. It stays standing
# until the move is confirmed, so cancelling a relocate loses nothing. NO_CELL = not relocating.
var _relocate_from: Vector2i = NO_CELL
var _relocate_level: int = 1
# The cell the placement ghost targets. Driven by the mouse, but also nudgeable with the
# arrow keys so a build can be completed without a mouse (CRITIQUE V5).
var _place_cell: Vector2i = Vector2i.ZERO
var _place_mouse_px: Vector2 = Vector2.ZERO   # last seen mouse position, to detect movement
# Extra nodes a finished building owns (footprint collider, manage post), so demolish and
# relocate can tear the whole structure down cleanly. cell -> Array[Node].
var _building_extra: Dictionary = {}

# Settlement-growth timer; only advances while the village is on-screen (VILLAGE_DESIGN P4).
var _grow_t: float = 0.0

# Shared materials for the living-world effects: one wind sway (foliage) and one
# stream flow (water), so every plant ripples in sync and the river moves.
var _wind_mat: ShaderMaterial = null
var _water_mat: ShaderMaterial = null

func _wind_material() -> ShaderMaterial:
	if _wind_mat == null:
		_wind_mat = ShaderMaterial.new()
		_wind_mat.shader = load("res://shaders/wind.gdshader")
	return _wind_mat

func _water_material() -> ShaderMaterial:
	if _water_mat == null:
		_water_mat = ShaderMaterial.new()
		_water_mat.shader = load("res://shaders/water.gdshader")
	return _water_mat

# Make a standing prop (from Iso.prop) sway in the wind — its body sprite only, never
# the contact shadow (z −1), which must stay planted on the ground.
func _windify(root: Node2D) -> void:
	if root == null or not is_instance_valid(root):
		return
	for c in root.get_children():
		if c is Sprite2D and (c as Sprite2D).z_index != -1:
			(c as Sprite2D).material = _wind_material()

func _ready() -> void:
	# Depth is feet-order: everything standing on the floor sorts by its Y so the
	# hero passes correctly in front of / behind buildings instead of clipping.
	y_sort_enabled = true
	if GameState.village_radius < START_RADIUS:
		GameState.village_radius = START_RADIUS

	_render_ground()
	_add_boundary()
	_dress_nature()
	_spawn_bonfire()
	_seed_and_rebuild()
	_spawn_supply_gate()
	_spawn_rescued_villagers()
	_spawn_settlers()
	_setup_farm()
	# Warmth now drives the one shared grade (Main) plus visible world objects —
	# the second full-screen overlay is gone (QA F-18/F-23).
	_apply_warmth(GameState.gwi)
	# The living settlement grows ONLY while you're here tending it — never off-screen and
	# never while the game is closed. Just keep the readout current on arrival.
	_refresh_residents()
	Sfx.ambient(true)   # the hearth's looping crackle — the sanctuary sounds alive (B3)

	# Build-menu wiring (null-guarded: Main may not have supplied a Hud).
	if hud:
		hud.build_selected.connect(_on_build_selected)
		hud.build_cancelled.connect(_on_build_cancelled)
		# Onboarding: a standing objective chain, plus a one-time controls card and
		# a line of premise on the very first visit.
		_update_objective()
		if not GameState.tutorial_seen:
			GameState.tutorial_seen = true
			# A passive controls card for reference, plus the guided talking intro.
			if hud.has_method("show_controls"):
				hud.call("show_controls")
			if hud.has_method("start_village_intro"):
				hud.call("start_village_intro")
	GameState.gwi_changed.connect(_on_gwi_changed)
	# Housing/population changes repaint the residents readout.
	GameState.population_changed.connect(_refresh_residents)

# Where Main drops the player: the hearth at the centre of the clearing.
func spawn_point() -> Vector2:
	return global_position

# ---------------------------------------------------------------------------
# Cell <-> world helpers  (cells centre on multiples of CELL; (0,0) = hearth)
# ---------------------------------------------------------------------------
func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * float(Palette.CELL)

func world_to_cell(point: Vector2) -> Vector2i:
	var c := float(Palette.CELL)
	return Vector2i(int(round(point.x / c)), int(round(point.y / c)))

# Buildable only inside the tended clearing, off the stream, and where nothing stands.
func _cell_free(cell: Vector2i) -> bool:
	if _river_cells.has(cell):
		return false
	if maxi(absi(cell.x - CENTER.x), absi(cell.y - CENTER.y)) > GameState.village_radius:
		return false
	return not GameState.grid.has(cell)

# ---------------------------------------------------------------------------
# World construction
# ---------------------------------------------------------------------------

# Lay the whole spacious field: bright tended grass inside the clearing, wilder
# worn grass beyond it. Rebuilt whenever the clearing expands.
func _render_ground() -> void:
	if _ground != null and is_instance_valid(_ground):
		_ground.queue_free()
	_ground = Node2D.new()
	add_child(_ground)
	var r: int = GameState.village_radius
	for gy in range(-FIELD, FIELD + 1):
		for gx in range(-FIELD, FIELD + 1):
			var cleared: bool = maxi(absi(gx - CENTER.x), absi(gy - CENTER.y)) <= r
			var s := Sprite2D.new()
			s.texture = Assets.tex("tile_grass" if cleared else "tile_grass_worn")
			# Squashed-aspect tile stretched back to a full square cell so rows meet.
			s.scale = Vector2(Palette.TILE_SX, Palette.TILE_SY)
			s.position = cell_to_world(Vector2i(gx, gy))
			s.z_index = -10  # beneath every structure and entity
			_ground.add_child(s)

# The whole walkable field (the boundary sits just outside this).
func _floor_rect() -> Rect2:
	var c := float(Palette.CELL)
	var half: float = (float(FIELD) + 0.5) * c
	return Rect2(Vector2(CENTER) * c - Vector2(half, half), Vector2(half, half) * 2.0)

# The hearth at the heart of the clearing — a warm focal point so the base is never
# a dark patch. Its baked glow reads warm on its own; a soft light adds a pool.
func _spawn_bonfire() -> void:
	var b: Node2D = Iso.prop(self, "bonfire", Vector2(0.0, -float(Palette.CELL) * 1.2), 60.0, 4.0)
	var l: PointLight2D = Iso.light(b, Palette.TORCH.lerp(Palette.GOLD_L, 0.3), 240.0, 0.6)
	l.position = Vector2(0.0, -40.0)
	_bonfire_root = b
	_bonfire_light = l
	_bonfire_flicker = Iso.flicker(l, 0.6, 0.16, 0.12)

# The open-air, natural dressing: a stream crossing the field with a plank bridge on
# the path and reeds on its banks, plus trees, bushes, flowers and rocks scattered
# through the wilder grass beyond the clearing.
func _dress_nature() -> void:
	var water := Node2D.new()
	add_child(water)
	for ry in [3, 4]:
		for gx in range(-FIELD, FIELD + 1):
			var cell := Vector2i(gx, ry)
			_river_cells[cell] = true
			var s := Sprite2D.new()
			s.texture = Assets.tex("tile_water")
			s.scale = Vector2(Palette.TILE_SX, Palette.TILE_SY)
			s.position = cell_to_world(cell)
			s.z_index = -9   # over the grass, under props and actors
			# A flowing-stream shader; repeat lets its scrolled UV wrap seamlessly.
			s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			s.material = _water_material()
			water.add_child(s)
	# A footbridge on the central path down to the gate.
	Iso.prop(self, "bridge", cell_to_world(Vector2i(0, 3)) + Vector2(0.0, float(Palette.CELL) * 0.5), 0.0, 0.0)
	# Reeds fringing both banks — they bend in the wind.
	for gx in [-7, -4, -1, 4, 6, 8]:
		_windify(Iso.prop(self, "reeds", cell_to_world(Vector2i(gx, 2)) + Vector2(0.0, 12.0), 22.0, 2.0))
		_windify(Iso.prop(self, "reeds", cell_to_world(Vector2i(gx + 1, 5)) - Vector2(0.0, 8.0), 22.0, 2.0))
	# Greenery in the outer wild grass (deterministic so the field looks composed).
	# Everything that grows sways in the wind; rocks stay put.
	_scatter_prop("tree", 9, 30, 4, 48.0, true)
	_scatter_prop("bush", 12, 41, 3, 30.0, true)
	_scatter_prop("flowers", 16, 55, 3, 0.0, true)
	_scatter_prop("rock_s", 6, 70, 4, 24.0, false)
	# Dead trees near the clearing that visibly green over as warmth rises — the
	# thaw the player is working toward, made physical (QA F-23).
	_add_thaw_marker(Vector2i(-3, -4), 0.12)
	_add_thaw_marker(Vector2i(3, -4), 0.24)
	_add_thaw_marker(Vector2i(-5, -1), 0.40)
	_add_thaw_marker(Vector2i(5, -2), 0.58)

# One dead tree that becomes a living tree once GWI crosses `threshold`.
func _add_thaw_marker(cell: Vector2i, threshold: float) -> void:
	var root: Node2D = Iso.prop(self, "dead_tree", cell_to_world(cell), 40.0, 2.0)
	_windify(root)   # even a bare tree creaks in the wind
	var spr: Sprite2D = null
	# Iso.prop adds the contact shadow (z_index -1) BEFORE the body sprite, so skip
	# the shadow — otherwise the thaw would repaint the shadow, not the tree.
	for c in root.get_children():
		if c is Sprite2D and (c as Sprite2D).z_index != -1:
			spr = c as Sprite2D
			break
	if spr != null:
		_thaw_markers.append({"sprite": spr, "threshold": threshold, "thawed": false})

# Drive every warmth-reactive object from the current GWI: the shared grade, the
# hearth's size/light, and the dead-tree thaw. The single place warmth becomes
# visible (QA F-18/F-23).
func _apply_warmth(gwi: float) -> void:
	Main.set_grade(0.4 + gwi * 0.6, 0.7, 0.7)
	if _bonfire_light != null and is_instance_valid(_bonfire_light):
		_bonfire_light.texture_scale = lerpf(240.0, 340.0, gwi) / 128.0
		# Rebuild the flicker around a warmth-driven base energy, else the looping
		# tween would immediately overwrite any energy we set here.
		if _bonfire_flicker != null and is_instance_valid(_bonfire_flicker):
			_bonfire_flicker.kill()
		_bonfire_flicker = Iso.flicker(_bonfire_light, lerpf(0.45, 1.15, gwi), 0.16, 0.12)
	if _bonfire_root != null and is_instance_valid(_bonfire_root):
		var s: float = lerpf(1.0, 1.22, gwi)
		_bonfire_root.scale = Vector2(s, s)
	for m in _thaw_markers:
		var md: Dictionary = m
		if bool(md["thawed"]):
			continue
		if gwi + 0.0001 >= float(md["threshold"]):
			md["thawed"] = true
			var spr: Sprite2D = md["sprite"]
			if spr != null and is_instance_valid(spr):
				spr.texture = Assets.tex("tree")
				Iso.anchor_feet(spr, 2.0)
				Vfx.embers(self, spr.global_position + Vector2(0.0, -30.0), 14, Palette.MOSS_L)

# Deterministically drop `count` copies of `key` in the wild grass, keeping clear of
# the clearing centre, the stream, the bridge path and the gate.
func _scatter_prop(key: String, count: int, salt: int, min_dist: int, shadow: float,
		sway: bool = false) -> void:
	var placed := 0
	var i := 0
	while placed < count and i < count * 8:
		var hx: float = Art.hash01(salt * 131 + i * 7)
		var hy: float = Art.hash01(salt * 131 + i * 7 + 3)
		var cx: int = int(round((hx * 2.0 - 1.0) * float(FIELD)))
		var cy: int = int(round((hy * 2.0 - 1.0) * float(FIELD)))
		i += 1
		var cell := Vector2i(cx, cy)
		if maxi(absi(cx), absi(cy)) < min_dist:
			continue                                  # keep the near clearing open
		if _river_cells.has(cell) or (absi(cx) <= 1 and cy >= 2 and cy <= 4):
			continue                                  # not in the water / bridge path
		if absi(cx) <= 1 and absi(cy - 6) <= 1:
			continue                                  # not on top of the gate
		var root: Node2D = Iso.prop(self, key, cell_to_world(cell), shadow, 2.0)
		if sway:
			_windify(root)
		placed += 1

# A solid wall frame just outside the floor so the hero can't wander off the island.
func _add_boundary() -> void:
	var r := _floor_rect()
	var t := 48.0
	var body := StaticBody2D.new()
	add_child(body)
	var segs := [
		[Vector2(r.get_center().x, r.position.y - t * 0.5), Vector2(r.size.x + t * 2.0, t)],  # top
		[Vector2(r.get_center().x, r.end.y + t * 0.5), Vector2(r.size.x + t * 2.0, t)],        # bottom
		[Vector2(r.position.x - t * 0.5, r.get_center().y), Vector2(t, r.size.y + t * 2.0)],   # left
		[Vector2(r.end.x + t * 0.5, r.get_center().y), Vector2(t, r.size.y + t * 2.0)],        # right
	]
	for s: Array in segs:
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = s[1]
		cs.shape = rect
		cs.position = s[0]
		body.add_child(cs)

# The camera may only show the island (plus its own margin) — never scroll off into
# the endless void. `Main` clamps to this and centres on any axis too small to fill.
func camera_bounds() -> Rect2:
	return _floor_rect()

# Warmth changed: repaint the whole world's warmth cues at once. The old
# second full-screen shader overlay is retired — post.gdshader is the one grade,
# driven here through Main (QA F-18); the visible thaw lives in _apply_warmth.
func _on_gwi_changed(value: float) -> void:
	_apply_warmth(value)
	_ember_warmth_lines(value)

# The Ember reacts as the world thaws (CRITIQUE A5): a one-time line each time warmth first
# crosses a milestone, so the mentor keeps speaking instead of going silent after the intro.
# Main.tip is one-shot per key and persisted, so each fires exactly once across the game.
func _ember_warmth_lines(v: float) -> void:
	if v >= 0.25:
		Main.tip("ember_warm_25", "The frost draws back a step. You feel it too — the world exhaling.")
	if v >= 0.5:
		Main.tip("ember_warm_50", "Halfway to the old warmth. The world is remembering how to be alive.")
	if v >= 0.75:
		Main.tip("ember_warm_75", "So close now. My light strains upward, toward the surface and the sun.")

# Reconstruct every structure the grid records. Farming is no longer a turn-one
# freebie — it comes from rescuing the Farmer (see _setup_farm), so the rescue finally
# matters and the "knowledge is carried by people" VISION lands (VILLAGE_DESIGN P1).
func _seed_and_rebuild() -> void:
	GameState.village_seeded = true
	for key in GameState.grid.keys():
		var cell: Vector2i = key
		var data: Dictionary = GameState.grid[cell]
		var btype: String = String(data.get("type", ""))
		var built: bool = bool(data.get("built", false))
		if built:
			_add_building_sprite(cell, btype)
			if btype == "crop_bed":
				_spawn_crop_plot(cell)
		else:
			_spawn_scaffold(cell, btype)

# The rescue payoff: every survivor brought home lives in the village — wandering,
# working, and offering a quest. Reads GameState.rescued (populated in the dungeon).
func _spawn_rescued_villagers() -> void:
	for i in range(GameState.rescued.size()):
		var pillar: String = GameState.rescued[i]
		var v := Villager.new()
		v.setup(pillar, self, Vector2(-96.0 + float(i) * 72.0, -24.0))
		add_child(v)

# --- Living settlement: population (VILLAGE_DESIGN P4/P5) --------------------
# Re-spawn the generic settlers the town has already drawn (the persisted count), so a
# reloaded village looks as populous as it is.
func _spawn_settlers() -> void:
	for i in range(GameState.settlers):
		_add_settler_node(i)

# One strolling settler: a quest-less Villager with a varied look, placed on the sunnier
# (south) side so the newcomers read as filling in around the founding survivors.
func _add_settler_node(index: int) -> void:
	var skins := ["survivor_farmer", "survivor_smith", "survivor_builder"]
	var v := Villager.new()
	v.skin = skins[maxi(0, index) % skins.size()]
	v.settler = true
	var col: int = index % 4
	var row: int = int(index / 4)
	v.setup("settler", self, Vector2(64.0 + float(col) * 48.0, 44.0 + float(row) * 42.0))
	add_child(v)

# Ticks while the village is on-screen: a fed, housed town draws a wanderer every so often.
func _settlement_tick(delta: float) -> void:
	if GameState.residents() >= GameState.housing_cap():
		return                                   # no room — nowhere for a newcomer to live
	_grow_t += delta
	if _grow_t < GROW_INTERVAL:
		return
	_grow_t = 0.0
	if GameState.amount("food") < GROW_FOOD_COST:
		return                                   # a hungry town attracts no one
	GameState.spend({"food": GROW_FOOD_COST})
	if not GameState.add_settler():
		return
	_add_settler_node(GameState.settlers - 1)
	GameState.add_gwi(0.02)                       # a fuller village is a warmer one
	Sfx.play("bloom", -6.0)
	Vfx.embers(self, Vector2(0.0, -20.0), 16, Palette.GOLD)
	if hud and hud.has_method("toast"):
		hud.toast(Loc.t("A wanderer, drawn by the warmth, settles in.  (%d residents)")
			% GameState.residents(), Palette.MOSS_L)

func _refresh_residents() -> void:
	if hud and hud.has_method("set_residents"):
		hud.call("set_residents", GameState.residents(), GameState.housing_cap())

# --- The Farmer → Farm chain (VILLAGE_DESIGN P1) ----------------------------
# Rescuing the Farmer carries the KNOWLEDGE of agriculture home; from it he lays out
# fallow ground, but lacks materials to work it — so the hero gets a supply quest.
# Idempotent, so it rebuilds the correct farm object on every village visit.
func _setup_farm() -> void:
	if not GameState.has_rescued("farmer"):
		return   # no Farmer yet → no farm; the rescue is what unlocks farming
	# First time the Farmer is home: he tills a plot from memory (fallow, inert).
	if GameState.farm_state == "none":
		GameState.farm_state = "fallow"
		Main.tip("farm_fallow", "The Farmer remembers this craft — he's tilled a plot from memory, but lacks the materials to work it. Bring him what he needs.")
	if GameState.farm_state == "fallow":
		_spawn_fallow_plot(FARM_CELL)
	elif GameState.farm_state == "active" or GameState.farm_state == "irrigated":
		# _seed_and_rebuild raises the plot from the grid; only self-heal if it's missing.
		if not GameState.grid.has(FARM_CELL):
			GameState.grid[FARM_CELL] = {"type": "crop_bed", "built": true, "seeded": true, "level": 1}
			_add_building_sprite(FARM_CELL, "crop_bed")
			_spawn_crop_plot(FARM_CELL)
		if GameState.farm_state == "active":
			_spawn_farm_project(FARM_CELL)     # the Farmer offers the irrigation project
		else:
			_add_irrigation_visuals(FARM_CELL) # channels that mark the worked, watered farm
	_update_objective()

func _spawn_fallow_plot(cell: Vector2i) -> void:
	var fp := FallowPlot.new()
	fp.village = self
	fp.cell = cell
	fp.position = cell_to_world(cell)
	add_child(fp)

# The hero delivered what the Farmer lacked: break the fallow ground into a working
# farm — record it, raise the plot, warm the village, and confirm the knowledge.
func _activate_farm(cell: Vector2i) -> void:
	GameState.farm_state = "active"
	GameState.grid[cell] = {"type": "crop_bed", "built": true, "seeded": true}
	_add_building_sprite(cell, "crop_bed")
	_spawn_crop_plot(cell)
	GameState.add_gwi(0.08)
	Vfx.embers(self, cell_to_world(cell), 26, Palette.MOSS_L)
	Sfx.play("bloom", -3.0)
	if hud:
		hud.toast(Loc.t("The Farmer breaks the fallow ground — the farm lives!"), Palette.GOLD)
	var line: String = String(Lore.EMBER_LINE.get("agriculture", ""))
	if line != "":
		Main.tip("codex_agriculture", line)
	_update_objective()

# The Farmer's standing offer once the farm works: a "project stake" a cell beside the
# plot (kept apart from the plant/harvest spot so the two prompts never collide).
func _spawn_farm_project(cell: Vector2i) -> void:
	var fp := FarmProject.new()
	fp.village = self
	fp.cell = cell
	fp.position = cell_to_world(cell) + Vector2(float(Palette.CELL), 0.0)
	add_child(fp)

# The Farmer's follow-up (VILLAGE_DESIGN §4.1 tier 5): dig irrigation. Crops ripen
# faster and yield more, the descent carries more Provisions (the farm counts as two
# crop-bed levels), and the world warms — the flagship chain keeps evolving.
func _irrigate_farm(cell: Vector2i) -> void:
	GameState.farm_state = "irrigated"
	var d: Dictionary = GameState.grid.get(cell, {})
	d["level"] = 2
	GameState.grid[cell] = d
	_add_irrigation_visuals(cell)
	GameState.add_gwi(0.08)
	Vfx.embers(self, cell_to_world(cell), 24, Palette.CYAN)
	Sfx.play("bloom", -3.0)
	if hud:
		hud.toast(Loc.t("Irrigation dug — the farm thrives, and feeds your descents."), Palette.GOLD)
	Main.tip("farm_irrigated", "Water reaches every row now — crops ripen faster, the harvest runs deeper, and you descend with more Provisions.")
	_update_objective()

# A little ring of flowing-water channels around the farm (shared stream shader), so an
# irrigated plot reads at a glance. Named + guarded so it's raised exactly once.
func _add_irrigation_visuals(cell: Vector2i) -> void:
	var nm := "Irrigation_%d_%d" % [cell.x, cell.y]
	if has_node(NodePath(nm)):
		return
	var root := Node2D.new()
	root.name = nm
	root.z_index = -8   # over the grass, under the crop plot
	add_child(root)
	var c := float(Palette.CELL)
	for off in [Vector2(-0.7, 0.0), Vector2(0.7, 0.0), Vector2(0.0, 0.72)]:
		var s := Sprite2D.new()
		s.texture = Assets.tex("tile_water")
		s.scale = Vector2(Palette.TILE_SX * 0.6, Palette.TILE_SY * 0.6)
		s.position = cell_to_world(cell) + off * c
		s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		s.material = _water_material()
		root.add_child(s)

# How many buildings the player has actually raised (for the builder's quest).
func built_count() -> int:
	var n := 0
	for key in GameState.grid.keys():
		var d: Dictionary = GameState.grid[key]
		if bool(d.get("built", false)) and not bool(d.get("seeded", false)):
			n += 1
	return n

# Advance the standing objective through concrete village goals so the build phase
# has beats instead of one static line (QA F-22).
func _update_objective() -> void:
	# Keep the residents readout current — housing changes whenever a Cabin is built/upgraded/removed.
	_refresh_residents()
	if hud == null or not hud.has_method("set_objective"):
		return
	# The Farmer's supply quest takes priority once he's laid the fallow ground.
	if GameState.farm_state == "fallow":
		hud.call("set_objective", "Bring the Farmer %d wood & %d seeds — break the fallow ground (press E on it)"
			% [int(FARM_SETUP["wood"]), int(FARM_SETUP["seeds"])])
	elif built_count() < 1:
		hud.call("set_objective", "Raise a building — press B, place a Cabin, then hammer it up (E)")
	elif GameState.farm_state == "active" and not _any_crop_growing() and GameState.amount("seeds") > 0:
		hud.call("set_objective", "Plant a seed on the farm — stand on it and press E")
	else:
		hud.call("set_objective", "Warm the village, then Descend at the Supply Gate")

func _any_crop_growing() -> bool:
	for c in get_children():
		if c is CropPlot and (c as CropPlot).stage >= 0:
			return true
	return false

# Progress toward a quest's goal (resource count, or buildings raised).
func quest_progress(pillar: String) -> int:
	var q: Dictionary = QUESTS.get(pillar, {})
	if q.is_empty():
		return 0
	if String(q["res"]) == "_built":
		return built_count()
	return GameState.amount(String(q["res"]))

# The Supply Gate sits out in the field south of the clearing — the way down.
func _spawn_supply_gate() -> void:
	var g := SupplyGate.new()
	g.village = self
	g.position = Vector2(0.0, float(Palette.CELL) * 6.0)
	add_child(g)
	_supply_gate = g

# What the guidance beacon points at: fallow ground waiting on the Farmer's supplies,
# then a frame to hammer, then a ripe crop to harvest, otherwise the Supply Gate.
func guidance_target() -> Node2D:
	var fallow: Node2D = null
	var scaffold: Node2D = null
	var ripe: Node2D = null
	for c in get_children():
		if c is FallowPlot:
			fallow = c
		elif c is Scaffold:
			scaffold = c
		elif c is CropPlot and (c as CropPlot).stage == 3:
			ripe = c
	if fallow != null and GameState.can_afford(FARM_SETUP):
		return fallow
	if scaffold != null:
		return scaffold
	if ripe != null:
		return ripe
	if fallow != null:
		return fallow
	return _supply_gate

# Drop a finished building's sprite onto a cell (no side effects — used by both
# rebuild and finish_building).
func _add_building_sprite(cell: Vector2i, build_id: String) -> void:
	var info: Dictionary = BUILDINGS.get(build_id, {})
	var tex_key: String = String(info.get("tex", "building_cabin"))
	# Feet-anchored + contact-shadowed like every other prop, so structures sit ON
	# the ground and y-sort by their base instead of floating as stickers (QA F-21).
	var root: Node2D = Iso.prop(self, tex_key, cell_to_world(cell), 42.0, 2.0)
	# Finished buildings visibly work: a warm hearth-light so the village reads as
	# lived-in rather than a field of inert props (QA F-22).
	if build_id == "forge":
		var lf: PointLight2D = Iso.light(root, Palette.TORCH, 96.0, 0.85)
		lf.position = Vector2(0.0, -22.0)
		Iso.flicker(lf, 0.85, 0.28, 0.13)
		_bldg_puff(root, Vector2(2.0, -30.0), Palette.EMBER, 0.4, 1.0)          # forge sparks
	elif build_id == "cabin":
		var lc: PointLight2D = Iso.light(root, Palette.GOLD_L, 74.0, 0.5)
		lc.position = Vector2(0.0, -20.0)
		_bldg_puff(root, Vector2(9.0, -44.0), Palette.SHADOW.lightened(0.4), 1.3, 2.6)  # chimney smoke
	elif build_id == "workshop":
		var lw: PointLight2D = Iso.light(root, Palette.GOLD_L, 70.0, 0.45)
		lw.position = Vector2(0.0, -14.0)
		_bldg_puff(root, Vector2(-14.0, -6.0), Palette.WOOD.lightened(0.2), 1.6, 3.4)   # drifting sawdust
	# Track every node this building owns so demolish / relocate can remove it cleanly.
	var extra: Array = []
	# Solid buildings get a footprint collider so the hero can't walk through them.
	# Crop beds stay flat ground you can stand on to plant/harvest.
	if build_id == "cabin" or build_id == "forge" or build_id == "workshop":
		var body := StaticBody2D.new()
		body.position = cell_to_world(cell) + Vector2(0.0, 8.0)
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(42.0, 26.0)
		cs.shape = rect
		body.add_child(cs)
		add_child(body)
		extra.append(body)
	# Upgrade support (VILLAGE_DESIGN P2): remember the visual root so an upgrade can
	# grow it, scale it now to its recorded tier, and — for the upgradable buildings —
	# drop an interactable manage post beside it (upgrade / relocate / demolish).
	var level: int = maxi(1, int(GameState.grid.get(cell, {}).get("level", 1)))
	_building_roots[cell] = root
	root.scale = Vector2.ONE * _level_scale(level)
	if UPGRADABLE.has(build_id):
		var mgr := BuildingManager.new()
		mgr.village = self
		mgr.cell = cell
		mgr.build_id = build_id
		mgr.position = cell_to_world(cell)
		add_child(mgr)
		extra.append(mgr)
	_building_extra[cell] = extra

# Visual size per tier: a Lv3 building stands notably taller than a fresh Lv1 (P2).
func _level_scale(level: int) -> float:
	return 1.0 + float(clampi(level, 1, MAX_BUILD_LEVEL) - 1) * 0.14

# The escalating upgrade cost: the base build cost times the current level, so each tier
# asks more than the last.
func _upgrade_cost(build_id: String, from_level: int) -> Dictionary:
	var base: Dictionary = BUILDINGS.get(build_id, {}).get("cost", {})
	var out: Dictionary = {}
	for k in base:
		out[k] = int(base[k]) * from_level
	return out

func _cost_str(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for k in cost:
		parts.append("%d %s" % [int(cost[k]), Loc.t(String(k))])
	return ", ".join(parts)

# How fast scaffolds rise — the Workshop speeds every build (VILLAGE_DESIGN P3): each
# workshop level adds 12% construction speed (to both hand-hammering and the Builder's
# auto-raise), capped so a fully-kitted village isn't instant.
func build_speed() -> float:
	return 1.0 + 0.12 * float(mini(GameState.building_level_sum("workshop"), 5))

# Warmth-retention multiplier for a cell: WARMTH_NEAR at the hearth, easing to WARMTH_FAR
# at the cold edge of the field. Smooth, so the "warm ring" reads as a gradient, not a step.
func _hearth_warmth_factor(cell: Vector2i) -> float:
	var d: float = Vector2(cell - CENTER).length()
	var t: float = clampf(d / float(FIELD), 0.0, 1.0)
	return lerpf(WARMTH_NEAR, WARMTH_FAR, smoothstep(0.0, 1.0, t))

# Warmth a fresh build of `build_id` would add if raised on `cell` right now: base warmth,
# divided by how many of that type will then stand (diminishing duplicates, F-13), times
# the cell's hearth-warmth factor. The honest number the placement readout shows (V2/V3).
func _predicted_warmth(build_id: String, cell: Vector2i) -> float:
	var base: float = float(BUILDINGS.get(build_id, {}).get("gwi", 0.0))
	var n: int = maxi(1, GameState.building_count(build_id) + 1)
	return base / float(n) * _hearth_warmth_factor(cell)

# Spend the escalating cost to raise a building a tier: deepen its boon (via the stored
# level), grow the sprite, warm the world a notch, and celebrate (VILLAGE_DESIGN P2/V6).
func _upgrade_building(cell: Vector2i, build_id: String) -> void:
	var d: Dictionary = GameState.grid.get(cell, {})
	var lv: int = maxi(1, int(d.get("level", 1)))
	if lv >= MAX_BUILD_LEVEL:
		return
	var cost: Dictionary = _upgrade_cost(build_id, lv)
	if not GameState.can_afford(cost):
		if hud:
			hud.toast(Loc.t("Not enough materials"), Palette.BLOOD)
		return
	GameState.spend(cost)
	d["level"] = lv + 1
	GameState.grid[cell] = d
	if _building_roots.has(cell) and is_instance_valid(_building_roots[cell]):
		var root: Node2D = _building_roots[cell]
		var tw := root.create_tween()
		tw.tween_property(root, "scale", Vector2.ONE * _level_scale(lv + 1), 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var info: Dictionary = BUILDINGS.get(build_id, {})
	GameState.add_gwi(float(info.get("gwi", 0.0)) * 0.5 / float(lv + 1))   # a smaller warmth step per tier
	Vfx.embers(self, cell_to_world(cell), 20, Palette.GOLD)
	Sfx.play("warm", -4.0)
	if hud:
		hud.toast(Loc.t("%s upgraded to Lv %d!") % [Loc.t(String(info.get("label", build_id))), lv + 1], Palette.GOLD)

# ---------------------------------------------------------------------------
# Manage an existing building: upgrade / relocate / demolish (CRITIQUE V1/V4)
# ---------------------------------------------------------------------------
# Opens the Build menu in MANAGE mode for the structure on `cell`. Reuses the build-card
# UI (number-key + click selectable) with special "mng_" ids routed in _on_build_selected,
# so a misplaced or outgrown building is no longer permanent — the way every city-builder
# lets you bulldoze or move a structure.
func open_manage_menu(cell: Vector2i, build_id: String) -> void:
	if _placing or hud == null:
		return
	_manage_cell = cell
	_manage_active = true
	var info: Dictionary = BUILDINGS.get(build_id, {})
	var tex: String = String(info.get("tex", ""))
	var label: String = String(info.get("label", build_id))
	var lv: int = maxi(1, int(GameState.grid.get(cell, {}).get("level", 1)))
	var entries: Array = []
	if UPGRADABLE.has(build_id) and lv < MAX_BUILD_LEVEL:
		var ucost: Dictionary = _upgrade_cost(build_id, lv)
		entries.append({
			"id": "mng_upgrade", "label": "%s → Lv %d" % [Loc.t(label), lv + 1],
			"cost": ucost, "affordable": GameState.can_afford(ucost), "tex": tex,
			"desc": Loc.t("Deepen its boon and warmth; the structure grows taller."), "warm": 0.0,
		})
	entries.append({
		"id": "mng_relocate", "label": "%s: %s" % [Loc.t("Relocate"), Loc.t(label)],
		"cost": {}, "affordable": true, "tex": tex,
		"desc": Loc.t("Pick it up and set it on a new tile — no materials lost."), "warm": 0.0,
	})
	var salvage: String = _cost_str(_salvage_for(cell, build_id))
	entries.append({
		"id": "mng_demolish", "label": "%s: %s" % [Loc.t("Demolish"), Loc.t(label)],
		"cost": {}, "affordable": true, "tex": tex,
		"desc": Loc.t("Salvage %s — half the materials; the rest is lost to the teardown.") \
			% (salvage if salvage != "" else Loc.t("nothing")), "warm": 0.0,
	})
	hud.open_build_menu(entries, "MANAGE")

# Total materials sunk into a building: base cost + every upgrade tier paid (base*L for
# each L→L+1). Demolition salvages a fraction of this.
func _invested(build_id: String, level: int) -> Dictionary:
	var out: Dictionary = {}
	var base: Dictionary = BUILDINGS.get(build_id, {}).get("cost", {})
	for k in base:
		out[k] = int(base[k])
	for from_lv in range(1, level):
		for k in base:
			out[k] = int(out.get(k, 0)) + int(base[k]) * from_lv
	return out

# What a demolish refunds: SALVAGE_FRAC of everything invested, dropping amounts that
# floor to zero.
func _salvage_for(cell: Vector2i, build_id: String) -> Dictionary:
	var lv: int = maxi(1, int(GameState.grid.get(cell, {}).get("level", 1)))
	var inv: Dictionary = _invested(build_id, lv)
	var out: Dictionary = {}
	for k in inv:
		var amt: int = int(floor(float(inv[k]) * SALVAGE_FRAC))
		if amt > 0:
			out[k] = amt
	return out

# Free every node a finished building owns (sprite root, collider, manage post) and clear
# the grid cell. Shared by demolish and relocate. Warmth already banked is intentionally
# left in place — the knowledge took root; you are reclaiming materials, not un-warming
# the world (which would risk un-winning and confuse the meter).
func _tear_down(cell: Vector2i) -> void:
	if _building_roots.has(cell) and is_instance_valid(_building_roots[cell]):
		_building_roots[cell].queue_free()
	_building_roots.erase(cell)
	if _building_extra.has(cell):
		for nd in _building_extra[cell]:
			if is_instance_valid(nd):
				nd.queue_free()
	_building_extra.erase(cell)
	GameState.grid.erase(cell)

func _demolish_building(cell: Vector2i, build_id: String) -> void:
	var refund: Dictionary = _salvage_for(cell, build_id)
	_tear_down(cell)
	for k in refund:
		GameState.add_resource(String(k), int(refund[k]))
	Vfx.dust(self, cell_to_world(cell), 12)
	Sfx.play("build", -4.0, 0.7)
	if hud:
		var got: String = _cost_str(refund)
		hud.toast(Loc.t("%s demolished — salvaged %s") \
			% [Loc.t(String(BUILDINGS.get(build_id, {}).get("label", build_id))),
			   got if got != "" else Loc.t("nothing")], Palette.AMBER)
	_update_objective()

# Begin relocating a finished building. The original stays standing until the move is
# confirmed (so cancelling loses nothing); on confirm we tear the old one down and raise
# the same building — at its current tier, for free — on the new cell (see _try_place).
func _start_relocate(cell: Vector2i, build_id: String) -> void:
	_relocate_from = cell
	_relocate_level = maxi(1, int(GameState.grid.get(cell, {}).get("level", 1)))
	_enter_placement(build_id)

# A repeating puff of smoke/sparks from a finished building, re-arming itself so the
# chimney keeps breathing (cabin) and the forge keeps sparking — the little signs of
# life that make a structure read as inhabited rather than a placed sticker.
func _bldg_puff(root: Node2D, at: Vector2, col: Color, lo: float, hi: float) -> void:
	if not is_instance_valid(root) or not root.is_inside_tree():
		return
	Vfx.embers(root, at, 3, col)
	get_tree().create_timer(randf_range(lo, hi)).timeout.connect(
		_bldg_puff.bind(root, at, col, lo, hi))

func _spawn_scaffold(cell: Vector2i, build_id: String) -> void:
	var sc := Scaffold.new()
	sc.setup(cell, build_id, self)
	sc.position = cell_to_world(cell)
	add_child(sc)

func _spawn_crop_plot(cell: Vector2i) -> void:
	var cp := CropPlot.new()
	cp.village = self               # so plant/harvest can refresh the objective chain
	cp.position = cell_to_world(cell)
	cp.z_index = 1  # crops sit on top of the crop-bed sprite
	add_child(cp)

# Called by a Scaffold when hammering completes: promote the record, raise the
# finished sprite, warm the world, and (for crop beds) open a plantable plot.
func finish_building(cell: Vector2i, build_id: String) -> void:
	if GameState.grid.has(cell):
		var d: Dictionary = GameState.grid[cell]
		d["built"] = true
		GameState.grid[cell] = d

	_add_building_sprite(cell, build_id)

	var info: Dictionary = BUILDINGS.get(build_id, {})
	# Diminishing warmth per duplicate: the Nth building of a type gives base/N, so a
	# DIVERSE village warms faster than spamming one kind (QA F-13 — retires the
	# cabin-spam dominant strategy). building_count now includes this one, so it is N.
	var n: int = maxi(1, GameState.building_count(build_id))
	# Diminishing per duplicate (a diverse village warms faster, F-13) AND scaled by how
	# close to the hearth it stands (heat retention, CRITIQUE V2). Grant — and SHOW — the
	# actual warmth, not the base; the card's flat headline was misleading before (V3).
	var gained: float = float(info.get("gwi", 0.0)) / float(n) * _hearth_warmth_factor(cell)
	GameState.add_gwi(gained)
	Vfx.embers(self, cell_to_world(cell), 22, Palette.GOLD)
	if gained > 0.0:
		Vfx.float_text(self, cell_to_world(cell) + Vector2(0.0, -32.0),
			"+%d%% warmth" % int(round(gained * 100.0)), Palette.AMBER)
	Sfx.play("warm", -5.0)
	if hud:
		hud.toast(Loc.t("%s raised!") % Loc.t(String(info.get("label", build_id))), Palette.GOLD)

	# First time this craft is raised, recover its invention's knowledge (QA F-08 /
	# D-06): the Ember says why it changed the world, and it enters the Codex.
	var entry: String = String(Lore.BUILDING_ENTRY.get(build_id, ""))
	if entry != "" and GameState.unlock_codex(entry):
		var e: Dictionary = Lore.entry(entry)
		if hud:
			hud.toast(Loc.t("Recovered: %s  —  press K for the Codex") % Loc.t(String(e.get("title", ""))), Palette.GOLD_L)
		var line: String = String(Lore.EMBER_LINE.get(entry, ""))
		if line != "":
			Main.tip("codex_" + entry, line)
	else:
		Main.tip("warmth", "Warmth rises with every building — watch the gauge, top-right. A warm village is the whole goal.")

	if build_id == "crop_bed":
		_spawn_crop_plot(cell)
	# The Ember marks the first roof raised since the cold (CRITIQUE A5) — one-time.
	if built_count() == 1:
		Main.tip("ember_first_build", "One roof raised against the dark. The cold has somewhere to lose to now.")
	_update_objective()

# ---------------------------------------------------------------------------
# Build menu + placement
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_menu"):
		_open_build_menu()
		return
	if event.is_action_pressed("cancel"):
		# (When the Hud menu is open the Hud consumes cancel itself.)
		if _placing:
			_exit_placement()
		return
	if event.is_action_pressed("attack"):
		if _placing:
			_try_place()
			get_viewport().set_input_as_handled()
		return
	# Keyboard placement (CRITIQUE V5): while a ghost is up, the arrow keys nudge it and
	# Enter confirms, so a build can be completed with no mouse. The mouse still works.
	if _placing and event is InputEventKey and event.pressed and not event.echo:
		var nudged := true
		match event.physical_keycode:
			KEY_LEFT:  _place_cell += Vector2i(-1, 0)
			KEY_RIGHT: _place_cell += Vector2i(1, 0)
			KEY_UP:    _place_cell += Vector2i(0, -1)
			KEY_DOWN:  _place_cell += Vector2i(0, 1)
			KEY_ENTER, KEY_KP_ENTER:
				_try_place()
				nudged = false
			_:
				nudged = false
		if nudged:
			var r: int = GameState.village_radius
			_place_cell.x = clampi(_place_cell.x, CENTER.x - r, CENTER.x + r)
			_place_cell.y = clampi(_place_cell.y, CENTER.y - r, CENTER.y + r)
			_place_mouse_px = get_global_mouse_position()   # don't let the mouse stomp the nudge
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	# The settlement grows over time while you tend it (VILLAGE_DESIGN P4).
	_settlement_tick(delta)
	# Ghost preview tracks the cursor (or the arrow-key cursor), snapped to a grid cell.
	if not (_placing and _ghost):
		return
	# Only take the mouse when it has actually moved, so a keyboard nudge isn't stomped.
	var mpx: Vector2 = get_global_mouse_position()
	if mpx.distance_to(_place_mouse_px) > 1.0:
		_place_mouse_px = mpx
		_place_cell = world_to_cell(to_local(mpx))
	var cell: Vector2i = _place_cell
	_ghost.position = cell_to_world(cell)
	var ok: bool = _cell_free(cell)
	_ghost.modulate = Color(1.0, 1.0, 1.0, 0.55) if ok else Color(1.0, 0.35, 0.3, 0.55)
	# The build grid + hovered-cell box so placement has a visible target (QA F-20).
	if _place_guide != null and is_instance_valid(_place_guide):
		_place_guide.hover = cell
		_place_guide.valid = ok
		_place_guide.queue_redraw()
	# Live, honest warmth readout for THIS tile (CRITIQUE V2/V3): a build warms the world
	# more the closer it stands to the hearth.
	if hud and hud.has_method("place_hint"):
		if _relocate_from != NO_CELL:
			hud.call("place_hint", Loc.t("Relocating — pick a tended tile   ·   Esc to cancel"))
		elif ok:
			var w: float = _predicted_warmth(_place_id, cell)
			hud.call("place_hint", Loc.t("Warmth here: +%d%%   ·   closer to the hearth is warmer   ·   Esc to cancel") % int(round(w * 100.0)))
		else:
			hud.call("place_hint", Loc.t("Blocked tile — pick a bright, empty one   ·   Esc to cancel"))

func _open_build_menu() -> void:
	if _placing or hud == null:
		return
	_manage_active = false   # a fresh Build menu is never a manage menu
	Main.tip("build", "Pick a building, then place it on a tended (bright) tile. The closer to the hearth, the more warmth it gives. 'Expand Clearing' tends more land.")
	var entries: Array = []
	for key in BUILDINGS.keys():
		var id: String = key
		# Crop Beds require the Farmer's knowledge — you can only expand the farm once
		# he's established it (VILLAGE_DESIGN P1). Before that, farming isn't buildable.
		if id == "crop_bed" and not (GameState.farm_state == "active" or GameState.farm_state == "irrigated"):
			continue
		# The Workshop needs the Carpenter (VILLAGE_DESIGN P3): rescue the Builder first —
		# knowledge carried by people, the same gate the farm uses.
		if id == "workshop" and not GameState.has_rescued("builder"):
			continue
		var info: Dictionary = BUILDINGS[id]
		var cost: Dictionary = info["cost"]
		entries.append({
			"id": id,
			"label": String(info["label"]),
			"cost": cost,
			"affordable": GameState.can_afford(cost),
			"tex": String(info.get("tex", "")),
			"desc": String(info.get("desc", "")),
			"warm": float(info.get("gwi", 0.0)),
		})
	# The expansion option: no placement, it just tends more of the field.
	if GameState.village_radius < FIELD - 1:
		var ecost: Dictionary = _expand_cost()
		entries.append({
			"id": "expand",
			"label": "Expand Clearing",
			"cost": ecost,
			"affordable": GameState.can_afford(ecost),
			"tex": "tile_grass",
			"desc": "Tend one more ring of wild land so you can build farther out.",
			"warm": 0.0,
		})
	hud.open_build_menu(entries)

# Expansion cost climbs with how much land you've already tended.
func _expand_cost() -> Dictionary:
	var r: int = GameState.village_radius
	return {"wood": 4 + r * 3, "stone": 2 + r * 2}

func _on_build_selected(id: String) -> void:
	# MANAGE-mode actions (upgrade / relocate / demolish) route to the managed cell.
	if _manage_active:
		var cell: Vector2i = _manage_cell
		var bid: String = String(GameState.grid.get(cell, {}).get("type", ""))
		_manage_active = false
		if bid == "":
			return
		match id:
			"mng_upgrade":  _upgrade_building(cell, bid)
			"mng_relocate": _start_relocate(cell, bid)
			"mng_demolish": _demolish_building(cell, bid)
		return
	if id == "expand":
		_expand()
	else:
		_enter_placement(id)

# Spend to tend one more ring of the field, then re-lay the ground.
func _expand() -> void:
	if hud:
		hud.close_build_menu()
	if GameState.village_radius >= FIELD - 1:
		if hud:
			hud.toast("The clearing is already vast", Palette.UI_DIM)
		return
	var cost: Dictionary = _expand_cost()
	if not GameState.can_afford(cost):
		if hud:
			hud.toast("Not enough materials to expand", Palette.BLOOD)
		return
	GameState.spend(cost)
	GameState.village_radius += 1
	_render_ground()
	Vfx.embers(self, Vector2.ZERO, 26, Palette.GOLD)
	if hud:
		hud.toast("Clearing expanded — more land to build on!", Palette.GOLD)
	Main.tip("expand", "The clearing grew. Keep expanding to reclaim the wild and raise a real settlement.")

func _on_build_cancelled() -> void:
	# Menu closed without a pick: leave manage mode and ensure any ghost is gone.
	_manage_active = false
	_exit_placement()

func _enter_placement(id: String) -> void:
	if not BUILDINGS.has(id):
		return
	_placing = true
	_place_id = id
	if hud:
		hud.close_build_menu()
	var info: Dictionary = BUILDINGS[id]
	if _ghost == null:
		_ghost = Sprite2D.new()
		_ghost.z_index = 30
		add_child(_ghost)
	_ghost.texture = Assets.tex(String(info["tex"]))
	_ghost.scale = Vector2(Palette.PX, Palette.PX)
	_ghost.modulate = Color(1.0, 1.0, 1.0, 0.55)
	_ghost.visible = true
	# Start the ghost where the mouse is (or fall back to the player's cell), and re-arm
	# mouse tracking so the first mouse move takes over from any prior keyboard cursor.
	_place_mouse_px = get_global_mouse_position()
	_place_cell = world_to_cell(to_local(_place_mouse_px))
	# A persistent placement banner (like a city-builder's "placing X" prompt) so the
	# player always knows what they're dropping and how to confirm/cancel.
	if hud and hud.has_method("show_place_banner"):
		var mode: String = "relocate" if _relocate_from != NO_CELL else "build"
		hud.call("show_place_banner", String(info["label"]), info["cost"], mode)
	# Raise the buildable-cell grid guide for the duration of placement.
	if _place_guide == null or not is_instance_valid(_place_guide):
		_place_guide = PlaceGuide.new()
		_place_guide.village = self
		add_child(_place_guide)
	_place_guide.visible = true
	_place_guide.queue_redraw()

func _exit_placement() -> void:
	_placing = false
	_place_id = ""
	_relocate_from = NO_CELL
	_relocate_level = 1
	if _ghost:
		_ghost.visible = false
	if hud and hud.has_method("hide_place_banner"):
		hud.call("hide_place_banner")
	if _place_guide != null and is_instance_valid(_place_guide):
		_place_guide.queue_free()
		_place_guide = null

# Commit a placement on left-click / Enter, if the cell is free (and, for a new build,
# affordable). A relocate carries a finished building over for free instead.
func _try_place() -> void:
	if not _placing:
		return
	var cell: Vector2i = _place_cell
	if not _cell_free(cell):
		return  # only land on empty in-bounds cells; keep placing otherwise
	# Relocating a finished building: no cost, carry its tier, tear down the original now
	# that a valid destination is confirmed (cancelling earlier would have kept it).
	if _relocate_from != NO_CELL:
		var bid: String = _place_id
		var lvl: int = _relocate_level
		var from: Vector2i = _relocate_from
		_exit_placement()
		_tear_down(from)
		GameState.grid[cell] = {"type": bid, "built": true, "level": lvl}
		_add_building_sprite(cell, bid)
		Vfx.embers(self, cell_to_world(cell), 14, Palette.GOLD)
		Sfx.play("build", -5.0)
		if hud:
			hud.toast(Loc.t("%s relocated") % Loc.t(String(BUILDINGS.get(bid, {}).get("label", bid))), Palette.MOSS_L)
		_update_objective()
		return
	var info: Dictionary = BUILDINGS[_place_id]
	var cost: Dictionary = info["cost"]
	if not GameState.can_afford(cost):
		if hud:
			hud.toast("Not enough materials", Palette.BLOOD)
		return
	GameState.spend(cost)
	GameState.grid[cell] = {"type": _place_id, "built": false, "level": 1}
	_spawn_scaffold(cell, _place_id)
	_exit_placement()
	Main.tip("hammer", "That's a frame. Stand beside it and tap E a few times to hammer it up.")

# ===========================================================================
# Inner classes (used only by the Village)
# ===========================================================================

# A floor overlay drawn during build placement: every buildable cell is FILLED with a
# gold wash whose strength tracks that tile's hearth-warmth (a city-builder desirability
# overlay, CRITIQUE V2 — bright ring near the fire, faint at the cold edge), plus a bold
# box on the hovered cell (gold = valid, red = blocked) so the player sees exactly where
# a building lands and how far the clearing reaches (F-20).
class PlaceGuide extends Node2D:
	var village: Village = null
	var hover: Vector2i = Vector2i.ZERO
	var valid: bool = false

	func _ready() -> void:
		z_index = 25   # above the floor + props, below the placement ghost (z 30)

	func _draw() -> void:
		if village == null or not is_instance_valid(village):
			return
		var C := float(Palette.CELL)
		var half := Vector2(C, C) * 0.5
		var r: int = GameState.village_radius
		var gold := Palette.GOLD_L
		var span: float = maxf(0.0001, Village.WARMTH_NEAR - Village.WARMTH_FAR)
		for gy in range(-r, r + 1):
			for gx in range(-r, r + 1):
				var cell := Vector2i(gx, gy)
				if not village._cell_free(cell):
					continue
				var c: Vector2 = village.cell_to_world(cell)
				# Warmer tiles glow more: normalise the factor to 0..1 for the fill alpha.
				var f: float = village._hearth_warmth_factor(cell)
				var warm01: float = clampf((f - Village.WARMTH_FAR) / span, 0.0, 1.0)
				draw_rect(Rect2(c - half, Vector2(C, C)),
					Color(gold.r, gold.g, gold.b, 0.05 + 0.20 * warm01), true)
				draw_rect(Rect2(c - half, Vector2(C, C)),
					Color(gold.r, gold.g, gold.b, 0.16), false, 1.0)
		# The hovered cell: filled tint + bold outline, coloured by validity.
		var hc: Vector2 = village.cell_to_world(hover)
		var col: Color = Palette.GOLD_L if valid else Palette.BLOOD
		var hr := Rect2(hc - half, Vector2(C, C))
		draw_rect(hr, Color(col.r, col.g, col.b, 0.14), true)
		draw_rect(hr, col, false, 2.5)

# A small bobbing amber "!" bubble raised over a ripe crop plot — the farming-sim
# harvest cue, so the player spots ready plots across the field without walking to each.
class RipeCue extends Node2D:
	var _t: float = 0.0

	func _ready() -> void:
		z_index = 40   # floats above the crop sprite and soil
		position = Vector2(0.0, -30.0)

	func _process(delta: float) -> void:
		_t += delta
		position.y = -30.0 - absf(sin(_t * 3.0)) * 4.0   # gentle up-and-down bob
		queue_redraw()

	func _draw() -> void:
		var pulse: float = 0.5 + 0.5 * sin(_t * 3.0)
		# soft halo + solid pip so it reads on bright grass and dim soil alike
		draw_circle(Vector2.ZERO, 9.0,
			Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.28 + 0.24 * pulse))
		draw_circle(Vector2.ZERO, 6.5, Palette.GOLD_L)
		# an exclamation mark inside, in dark soil so it stays legible
		draw_rect(Rect2(Vector2(-1.2, -4.2), Vector2(2.4, 5.2)), Palette.SOIL_D)
		draw_circle(Vector2(0.0, 3.4), 1.4, Palette.SOIL_D)

# A blueprint frame the player hammers up (or a rescued Builder auto-raises).
class Scaffold extends Node2D:
	var cell: Vector2i = Vector2i.ZERO
	var build_id: String = ""
	var village: Village = null
	var progress: float = 0.0
	var _done: bool = false
	var _sprite: Sprite2D = null

	# Set identity before adding to the tree so _ready has everything.
	func setup(c: Vector2i, id: String, v: Village) -> void:
		cell = c
		build_id = id
		village = v

	func _ready() -> void:
		# Feet-anchored + shadowed so the frame stands on the ground (QA F-21).
		Iso.shadow(self, 40.0, 0.36)
		_sprite = Sprite2D.new()
		_sprite.texture = Assets.tex("building_scaffold")
		_sprite.scale = Vector2(Palette.PX, Palette.PX)
		add_child(_sprite)
		Iso.anchor_feet(_sprite, 2.0)
		add_to_group("interactable")

	# --- Interaction protocol (see DESIGN.md) ---
	func interact_radius() -> float:
		return 34.0

	func can_interact(_by: Node) -> bool:
		return not _done

	func interact_prompt() -> String:
		return Loc.t("Hammer  [E]  (%d%%)") % int(progress * 100.0)

	func do_interact(_by: Node) -> void:
		if _done:
			return
		progress += 0.34 * (village.build_speed() if village != null else 1.0)   # Workshop speeds it (P3)
		# Make the hero visibly swing the hammer toward the frame.
		if _by is Node2D and _by.has_method("play_work"):
			_by.call("play_work", global_position - (_by as Node2D).global_position)
		# Chunky per-strike feedback so the labour reads at a glance: wood chips fly,
		# a dust puff kicks up, the frame thunks, and the rising % floats off it.
		Vfx.embers(get_parent(), global_position + Vector2(0.0, -14.0), 8, Palette.WOOD)
		Vfx.dust(get_parent(), global_position, 6)
		Vfx.float_text(get_parent(), global_position + Vector2(0.0, -26.0),
			"%d%%" % int(progress * 100.0), Palette.GOLD_L)
		Sfx.play("build", -5.0)
		_thunk()
		if progress >= 1.0:
			_complete()

	# Rescuing a Builder automates construction over time.
	func _process(delta: float) -> void:
		if _done:
			return
		if GameState.has_rescued("builder"):
			progress += delta * 0.5 * (village.build_speed() if village != null else 1.0)
			if progress >= 1.0:
				_complete()

	# A punchier hammer-shake + squash so each strike lands with weight.
	func _thunk() -> void:
		if _sprite == null:
			return
		var tw := _sprite.create_tween()
		tw.tween_property(_sprite, "position", Vector2(0, -6), 0.05)
		tw.parallel().tween_property(_sprite, "scale",
			Vector2(Palette.PX * 1.06, Palette.PX * 0.92), 0.05)
		tw.tween_property(_sprite, "position", Vector2.ZERO, 0.12)
		tw.parallel().tween_property(_sprite, "scale",
			Vector2(Palette.PX, Palette.PX), 0.12)

	func _complete() -> void:
		if _done:
			return
		_done = true
		if village:
			village.finish_building(cell, build_id)
		queue_free()

# Fallow ground the Farmer laid out from memory but cannot yet work (VILLAGE_DESIGN P1,
# stage "fallow"). Interact to break it into a real farm once you carry the materials
# he lacks. It is the physical form of the Farmer's supply quest.
class FallowPlot extends Node2D:
	var village: Village = null
	var cell: Vector2i = Vector2i.ZERO

	func _ready() -> void:
		z_index = 1
		add_to_group("interactable")

	# Tilled-but-untended soil with faint furrow marks — "prepared, but nothing sown."
	func _draw() -> void:
		var rx: float = float(Palette.CELL) * 0.42
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, Palette.SQUASH))
		draw_circle(Vector2.ZERO, rx, Palette.SOIL_D)
		draw_circle(Vector2(0.0, -1.5), rx * 0.85, Palette.SOIL)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i in range(-1, 2):
			draw_line(Vector2(float(i) * 10.0, -8.0), Vector2(float(i) * 10.0, 8.0),
				Palette.SOIL_D, 1.0)

	func _process(_delta: float) -> void:
		var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and global_position.distance_to(pl.global_position) < 84.0:
			Main.tip("farm_break", "Fallow ground the Farmer tilled. Gather %d wood and %d seeds from the ruins, then press E here to break it into a farm."
				% [int(Village.FARM_SETUP["wood"]), int(Village.FARM_SETUP["seeds"])])

	func interact_radius() -> float:
		return 40.0

	func can_interact(_by: Node) -> bool:
		return true

	func interact_prompt() -> String:
		var nw: int = int(Village.FARM_SETUP["wood"])
		var ns: int = int(Village.FARM_SETUP["seeds"])
		if GameState.can_afford(Village.FARM_SETUP):
			return Loc.t("Break the fallow ground  (%d wood, %d seeds)  [E]") % [nw, ns]
		return Loc.t("Fallow ground — needs %d wood, %d seeds  (you have %d, %d)") \
			% [nw, ns, GameState.amount("wood"), GameState.amount("seeds")]

	func do_interact(_by: Node) -> void:
		if not GameState.can_afford(Village.FARM_SETUP):
			if village != null and village.hud != null and village.hud.has_method("toast"):
				village.hud.call("toast", Loc.t("The Farmer needs %d wood and %d seeds first.")
					% [int(Village.FARM_SETUP["wood"]), int(Village.FARM_SETUP["seeds"])], Palette.BLOOD)
			return
		GameState.spend(Village.FARM_SETUP)
		var v: Village = village
		var c: Vector2i = cell
		queue_free()
		if v != null and is_instance_valid(v):
			v._activate_farm(c)

# The Farmer's follow-up offer once the farm is active (VILLAGE_DESIGN §4.1 tier 5): a
# little project stake beside the plot — press E to fund irrigation. Removes itself once
# the farm is irrigated.
class FarmProject extends Node2D:
	var village: Village = null
	var cell: Vector2i = Vector2i.ZERO

	func _ready() -> void:
		z_index = 2
		add_to_group("interactable")

	# A small stake + signboard so it reads as "work to be done here".
	func _draw() -> void:
		draw_line(Vector2(0, 2), Vector2(0, -24), Palette.WOOD_D, 3.0)
		var sign := Rect2(Vector2(-11, -34), Vector2(22, 13))
		draw_rect(sign, Palette.WOOD, true)
		draw_rect(sign, Palette.WOOD_D, false, 1.5)

	func _process(_delta: float) -> void:
		var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and global_position.distance_to(pl.global_position) < 84.0:
			Main.tip("farm_irrigate_hint", "The Farmer wants to dig irrigation — %d stone and %d wood, and the farm will thrive."
				% [int(Village.FARM_IRRIGATE["stone"]), int(Village.FARM_IRRIGATE["wood"])])

	func interact_radius() -> float:
		return 42.0

	func can_interact(_by: Node) -> bool:
		return GameState.farm_state == "active"

	func interact_prompt() -> String:
		var ns: int = int(Village.FARM_IRRIGATE["stone"])
		var nw: int = int(Village.FARM_IRRIGATE["wood"])
		if GameState.can_afford(Village.FARM_IRRIGATE):
			return Loc.t("Dig irrigation  (%d stone, %d wood)  [E]") % [ns, nw]
		return Loc.t("Irrigation — needs %d stone, %d wood  (you have %d, %d)") \
			% [ns, nw, GameState.amount("stone"), GameState.amount("wood")]

	func do_interact(_by: Node) -> void:
		if not GameState.can_afford(Village.FARM_IRRIGATE):
			if village != null and village.hud != null and village.hud.has_method("toast"):
				village.hud.call("toast", Loc.t("The Farmer needs %d stone and %d wood.")
					% [int(Village.FARM_IRRIGATE["stone"]), int(Village.FARM_IRRIGATE["wood"])], Palette.BLOOD)
			return
		GameState.spend(Village.FARM_IRRIGATE)
		var v: Village = village
		var c: Vector2i = cell
		queue_free()
		if v != null and is_instance_valid(v):
			v._irrigate_farm(c)

# An interactable beside a finished building: press E to open the MANAGE menu — upgrade,
# relocate, or demolish (CRITIQUE V1/V4). It replaces the old single-purpose upgrade post,
# folding all three construction verbs onto the building itself so a misplaced or outgrown
# structure is never permanent. Present at every tier (you can still relocate/demolish a
# maxed building).
class BuildingManager extends Node2D:
	var village: Village = null
	var cell: Vector2i = Vector2i.ZERO
	var build_id: String = ""

	func _ready() -> void:
		add_to_group("interactable")

	func _level() -> int:
		return maxi(1, int(GameState.grid.get(cell, {}).get("level", 1)))

	func interact_radius() -> float:
		return 46.0

	# Suppressed while a ghost is up, so E doesn't open a manage menu mid-placement.
	func can_interact(_by: Node) -> bool:
		if village != null and is_instance_valid(village) and village._placing:
			return false
		return GameState.grid.has(cell)

	func interact_prompt() -> String:
		var label: String = Loc.t(String(Village.BUILDINGS.get(build_id, {}).get("label", build_id)))
		if Village.UPGRADABLE.has(build_id) and _level() < Village.MAX_BUILD_LEVEL:
			return Loc.t("Manage %s  (Lv %d)  [E]") % [label, _level()]
		return Loc.t("Manage %s  [E]") % label

	func do_interact(_by: Node) -> void:
		if village != null and is_instance_valid(village):
			village.open_manage_menu(cell, build_id)

# A soil plot atop a finished Crop Bed: plant a seed, wait through 4 stages, harvest.
class CropPlot extends Node2D:
	const STAGE_TIME := 4.0
	var stage: int = -1   # -1 = empty soil; 0..3 = growing; 3 = ripe
	var t: float = 0.0
	var village: Village = null   # to refresh the objective chain on plant/harvest
	var _sprite: Sprite2D = null
	var _cue: RipeCue = null       # bobbing "ready to harvest" marker (Stardew-style)
	var _auto_t: float = 0.0       # cadence for the Farmer working the plot on his own

	func _ready() -> void:
		# The growth sprite rides on top of always-visible tilled soil (see _draw),
		# so an empty plot still reads as a plantable farm rather than bare bed (F-21).
		_sprite = Sprite2D.new()
		_sprite.scale = Vector2(Palette.PX, Palette.PX)
		add_child(_sprite)
		Iso.anchor_feet(_sprite, 0.0)
		add_to_group("interactable")
		_refresh_sprite()

	# Tilled-soil furrows drawn under the crop, so the plot always looks worked.
	func _draw() -> void:
		var rx: float = float(Palette.CELL) * 0.40
		var ry: float = rx * Palette.SQUASH
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, Palette.SQUASH))
		draw_circle(Vector2.ZERO, rx, Palette.SOIL_D)
		draw_circle(Vector2(0.0, -1.5), rx * 0.86, Palette.SOIL)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i in range(-1, 2):
			draw_line(Vector2(float(i) * 9.0, -ry * 0.5), Vector2(float(i) * 9.0, ry * 0.5),
				Palette.SOIL_D, 1.0)

	# --- Interaction protocol ---
	func interact_radius() -> float:
		return 34.0

	# Interactable only when there is a meaningful action: plant (with seeds) or harvest.
	func can_interact(_by: Node) -> bool:
		if stage == -1:
			return GameState.amount("seeds") > 0
		return stage == 3

	func interact_prompt() -> String:
		if stage == -1:
			return Loc.t("Plant seed  [E]")
		if stage == 3:
			return Loc.t("Harvest  [E]")
		return Loc.t("Growing...")

	func do_interact(_by: Node) -> void:
		if stage == -1:
			if GameState.amount("seeds") > 0:
				GameState.spend({"seeds": 1})
				stage = 0
				t = 0.0
				_refresh_sprite()
		elif stage == 3:
			_harvest()
		if village != null and is_instance_valid(village):
			village._update_objective()

	# Irrigation (VILLAGE_DESIGN §4.1 tier 5) ripens crops faster and yields more food.
	func _stage_time() -> float:
		return STAGE_TIME * (0.7 if GameState.farm_state == "irrigated" else 1.0)

	func _yield_food() -> int:
		return 3 if GameState.farm_state == "irrigated" else 2

	# Reap a ripe plot: +food, +1 seed back (loop-sustaining), reset to empty soil.
	# Shared by the player's manual harvest and the Farmer's auto-tend.
	func _harvest() -> void:
		var food: int = _yield_food()
		GameState.add_resource("food", food)
		GameState.add_resource("seeds", 1)
		Sfx.play("harvest", -6.0)
		Vfx.embers(get_parent(), global_position, 12, Palette.GOLD)
		Vfx.float_text(get_parent(), global_position, "+%d food" % food, Palette.AMBER)
		stage = -1
		t = 0.0
		_refresh_sprite()

	func _process(delta: float) -> void:
		if stage >= 0 and stage < 3:
			t += delta
			if t >= _stage_time():
				t = 0.0
				stage = mini(stage + 1, 3)
				_refresh_sprite()
		# The Farmer works the farm on his own (VILLAGE_DESIGN P1 / V1): once he's home
		# and the farm is active, empty soil re-sows itself from the seed stock and ripe
		# crops are collected over time — so the farm produces food even while you're in
		# the ruins. Seed-gated, so it stalls if you run the seed stock dry.
		if GameState.has_rescued("farmer") and (GameState.farm_state == "active" or GameState.farm_state == "irrigated"):
			_auto_t += delta
			if stage == -1 and GameState.amount("seeds") > 0 and _auto_t >= 2.5:
				GameState.spend({"seeds": 1})
				stage = 0
				t = 0.0
				_auto_t = 0.0
				_refresh_sprite()
			elif stage == 3 and _auto_t >= 3.5:
				_auto_t = 0.0
				_harvest()
				if village != null and is_instance_valid(village):
					village._update_objective()
		# Teach planting/harvesting the first time the hero stands over a plot.
		var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and global_position.distance_to(pl.global_position) < 72.0:
			if stage == -1 and GameState.amount("seeds") > 0:
				Main.tip("plant", "Empty soil. Press E to plant a seed, or let the Farmer sow it — either way it grows.")
			elif stage == 3:
				Main.tip("harvest", "Ripe! Press E to harvest now, or the Farmer will collect it shortly.")

	func _refresh_sprite() -> void:
		if _sprite == null:
			return
		if stage < 0:
			_sprite.visible = false
		else:
			_sprite.visible = true
			_sprite.texture = Assets.tex("crop_%d" % stage)
		_refresh_cue()

	# Raise a bobbing amber marker over a RIPE plot so harvest-ready crops read across
	# the whole field at a glance (the farming-sim "come collect me" cue), and clear it
	# the instant the plot is harvested or replanted.
	func _refresh_cue() -> void:
		if stage == 3 and _cue == null:
			_cue = RipeCue.new()
			add_child(_cue)
		elif stage != 3 and _cue != null:
			_cue.queue_free()
			_cue = null

# The run-start point: interact to descend into the ruins.
class SupplyGate extends Node2D:
	var village: Village = null  # set on spawn so do_interact can fire the signal

	func _ready() -> void:
		# The single most important interactable in the village: feet-anchored,
		# shadowed, lit with a cold rift glow and a lick of embers so it reads as a
		# way DOWN, not a crate (QA F-26).
		Iso.shadow(self, 62.0, 0.42)
		var s := Sprite2D.new()
		s.texture = Assets.tex("supply_gate")
		s.scale = Vector2(Palette.PX, Palette.PX)
		add_child(s)
		Iso.anchor_feet(s, 4.0)
		var l: PointLight2D = Iso.light(self, Palette.CYAN, 128.0, 0.9)
		l.position = Vector2(0.0, -30.0)
		l.z_index = -5
		Iso.flicker(l, 0.9, 0.18, 0.16)
		add_to_group("interactable")
		_puff()

	# A slow drift of cold motes rising from the mouth of the descent.
	func _puff() -> void:
		if not is_inside_tree():
			return
		Vfx.embers(self, Vector2(0.0, -22.0), 4, Palette.CYAN)
		get_tree().create_timer(1.4).timeout.connect(_puff)

	# --- Interaction protocol ---
	func interact_radius() -> float:
		return 40.0

	func can_interact(_by: Node) -> bool:
		return true

	func interact_prompt() -> String:
		return Loc.t("Descend into the ruins  [E]")

	func do_interact(_by: Node) -> void:
		if village:
			Sfx.play("descend", -3.0)
			village.expedition_requested.emit()

# A rescued survivor living in the village: strolls the clearing, stops to WORK
# (a labouring bob), and offers a one-off quest that rewards warmth + materials.
class Villager extends Node2D:
	var pillar: String = "farmer"
	var village: Village = null
	var skin: String = ""          # texture override (generic settlers vary their look)
	var settler: bool = false      # a drawn-in townsperson (no quest; a warm greeting only)
	var _home: Vector2 = Vector2.ZERO
	var _roam: float = 92.0
	var _sprite: Sprite2D = null
	var _base_scale: Vector2 = Vector2.ONE
	var _anim_t: float = 0.0
	var _face_left: bool = false
	var _target: Vector2 = Vector2.ZERO
	var _wait: float = 0.0
	var _working: bool = false

	func setup(p: String, v: Village, home: Vector2) -> void:
		pillar = p
		village = v
		_home = home

	func _ready() -> void:
		position = _home
		Iso.shadow(self, 46.0 * Palette.ACTOR_SCALE, 0.42)
		_sprite = Sprite2D.new()
		var key := skin if skin != "" else "survivor_" + pillar
		_sprite.texture = Assets.tex(key) if Assets.has(key) else Assets.tex("survivor_farmer")
		add_child(_sprite)
		_base_scale = Iso.mount_body(_sprite, 5.0)
		add_to_group("interactable")
		if not GameState.quests.has(pillar):
			GameState.quests[pillar] = "new"
		_pick_target()

	func _pick_target() -> void:
		_target = _home + Vector2(randf_range(-_roam, _roam), randf_range(-_roam, _roam))

	# Stroll to a spot, pause to work, repeat — so the village looks lived-in.
	func _process(delta: float) -> void:
		if _wait > 0.0:
			_wait -= delta
			_anim_t += delta * (7.0 if _working else 1.2)
			Iso.walk_anim(_sprite, _base_scale, _anim_t, false, _face_left)
			if _working:
				_sprite.position.y = -absf(sin(_anim_t * 3.0)) * 3.5   # heads-down labour
			if _wait <= 0.0:
				_pick_target()
			return
		var d: Vector2 = _target - global_position
		if d.length() < 5.0:
			_working = randf() < 0.6
			_wait = randf_range(1.6, 3.6)
			_anim_t = 0.0
			return
		if absf(d.x) > 2.0:
			_face_left = d.x < 0.0
		global_position += d.normalized() * 58.0 * delta
		_anim_t += delta
		Iso.walk_anim(_sprite, _base_scale, _anim_t, true, _face_left)

	# --- Quest interaction ---
	func interact_radius() -> float:
		return 42.0

	func can_interact(_by: Node) -> bool:
		return true

	func _state() -> String:
		return String(GameState.quests.get(pillar, "new"))

	func interact_prompt() -> String:
		var q: Dictionary = Village.QUESTS.get(pillar, {})
		if q.is_empty():
			return Loc.t("Greet the settler  [E]") if settler else Loc.t("Speak to the %s  [E]") % Loc.t(pillar)
		match _state():
			"active":
				var prog: int = village.quest_progress(pillar)
				var need: int = int(q["need"])
				if prog >= need:
					return Loc.t("Turn in “%s”  [E]") % Loc.t(String(q["title"]))
				return "%s   (%d/%d)  [E]" % [Loc.t(String(q["title"])), prog, need]
			"done":
				# Story quest finished → the villager keeps a standing commission open.
				var cm: Dictionary = Village.COMMISSIONS.get(pillar, {})
				if cm.is_empty():
					return Loc.t("Thank the %s  [E]") % Loc.t(pillar)
				var cres: String = String(cm["res"])
				var cneed: int = int(cm["need"])
				if GameState.amount(cres) >= cneed:
					return Loc.t("Commission: give %d %s  [E]") % [cneed, Loc.t(cres)]
				return "%s   (%d/%d %s)  [E]" % [Loc.t("Commission"), GameState.amount(cres), cneed, Loc.t(cres)]
			_:
				return Loc.t("Speak to the %s  [E]") % Loc.t(pillar)

	func do_interact(_by: Node) -> void:
		var q: Dictionary = Village.QUESTS.get(pillar, {})
		if q.is_empty():
			if settler:
				var lines: Array = Village.SETTLER_LINES
				if not lines.is_empty():
					_toast(Loc.t(String(lines[randi() % lines.size()])), Palette.CYAN)
			return
		var st := _state()
		if st == "new":
			GameState.quests[pillar] = "active"
			_toast(Loc.t("%s: “%s”") % [GameState.survivor_name(pillar), Loc.t(String(q["ask"]))], Palette.CYAN)
		elif st == "active":
			var need: int = int(q["need"])
			if village.quest_progress(pillar) >= need:
				GameState.quests[pillar] = "done"
				var reward: Dictionary = q["reward"]
				for k in reward:
					GameState.add_resource(String(k), int(reward[k]))
				GameState.add_gwi(float(q["gwi"]))
				Vfx.embers(get_parent(), global_position, 20, Palette.GOLD)
				Vfx.float_text(get_parent(), global_position + Vector2(0.0, -46.0), "Quest done!", Palette.GOLD_L)
				_toast(Loc.t("Quest complete: %s") % Loc.t(String(q["title"])), Palette.GOLD)
			else:
				var prog: int = village.quest_progress(pillar)
				_toast("%s  —  %d/%d" % [Loc.t(String(q["title"])), prog, need], Palette.AMBER)
		else:
			_fulfil_commission()

	# A repeatable errand once the story quest is done: trade a stack of materials for
	# warmth (+ a little back), so a settled villager keeps giving the player something
	# to do and warmth a steady sink (QA F-14 — no more inert village).
	func _fulfil_commission() -> void:
		var cm: Dictionary = Village.COMMISSIONS.get(pillar, {})
		if cm.is_empty():
			_toast(Loc.t(String(Village.QUESTS.get(pillar, {}).get("thanks", ""))), Palette.AMBER)
			return
		var res: String = String(cm["res"])
		var need: int = int(cm["need"])
		if GameState.amount(res) >= need:
			GameState.spend({res: need})
			var reward: Dictionary = cm["reward"]
			for k in reward:
				GameState.add_resource(String(k), int(reward[k]))
			GameState.add_gwi(float(cm["gwi"]))
			Vfx.embers(get_parent(), global_position, 16, Palette.GOLD)
			Vfx.float_text(get_parent(), global_position + Vector2(0.0, -46.0),
				Loc.t("Commission met!"), Palette.GOLD_L)
			_toast(Loc.t("Commission met — the village grows warmer."), Palette.GOLD)
		else:
			_toast("%s  (%d/%d %s)" % [Loc.t(String(cm["ask"])),
				GameState.amount(res), need, Loc.t(res)], Palette.AMBER)

	func _toast(text: String, col: Color) -> void:
		if village != null and village.hud != null and village.hud.has_method("toast"):
			village.hud.call("toast", text, col)
