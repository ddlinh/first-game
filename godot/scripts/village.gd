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

# The module owns the buildable catalogue: cost, finished texture, and the GWI
# warmth each completed building radiates.
const BUILDINGS := {
	"cabin": {"label": "Cabin", "cost": {"wood": 5, "stone": 2}, "tex": "building_cabin", "gwi": 0.18},
	"forge": {"label": "Forge", "cost": {"stone": 4, "iron": 2}, "tex": "building_forge", "gwi": 0.15},
	"crop_bed": {"label": "Crop Bed", "cost": {"wood": 3}, "tex": "building_crop_bed", "gwi": 0.05},
}

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

# Injected by Main before this node enters the tree (a Hud). Left untyped on
# purpose: the Hud class is not compiled into this module. Always null-guarded.
var hud

# The run-start gate, kept so the guidance beacon can point the player at it.
var _supply_gate: Node2D = null
# Holds the ground tiles so the clearing can be re-rendered when it expands.
var _ground: Node2D = null
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
	# Warmth now drives the one shared grade (Main) plus visible world objects —
	# the second full-screen overlay is gone (QA F-18/F-23).
	_apply_warmth(GameState.gwi)

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

# First visit seeds one pre-built Crop Bed so farming is reachable turn one;
# then (every visit) reconstruct every structure the grid records.
func _seed_and_rebuild() -> void:
	if not GameState.village_seeded:
		var seed_cell := Vector2i(2, 1)
		# Flag the freebie so the Builder's "raise 3 buildings" quest doesn't count
		# it — otherwise the goal is really only 2 player builds (QA F-17).
		GameState.grid[seed_cell] = {"type": "crop_bed", "built": true, "seeded": true}
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
	if hud == null or not hud.has_method("set_objective"):
		return
	if built_count() < 1:
		hud.call("set_objective", "Raise a building — press B, place a Cabin, then hammer it up (E)")
	elif not _any_crop_growing() and GameState.amount("seeds") > 0:
		hud.call("set_objective", "Plant a seed on the Crop Bed — stand on it and press E")
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

# What the guidance beacon points at: a frame waiting to be hammered, then a ripe
# crop to harvest, otherwise the Supply Gate (the way down).
func guidance_target() -> Node2D:
	var scaffold: Node2D = null
	var ripe: Node2D = null
	for c in get_children():
		if c is Scaffold:
			scaffold = c
		elif c is CropPlot and (c as CropPlot).stage == 3:
			ripe = c
	if scaffold != null:
		return scaffold
	if ripe != null:
		return ripe
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
	# Solid buildings get a footprint collider so the hero can't walk through them.
	# Crop beds stay flat ground you can stand on to plant/harvest.
	if build_id == "cabin" or build_id == "forge":
		var body := StaticBody2D.new()
		body.position = cell_to_world(cell) + Vector2(0.0, 8.0)
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(42.0, 26.0)
		cs.shape = rect
		body.add_child(cs)
		add_child(body)

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
	GameState.add_gwi(float(info.get("gwi", 0.0)) / float(n))
	Vfx.embers(self, cell_to_world(cell), 22, Palette.GOLD)
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
	_update_objective()

# ---------------------------------------------------------------------------
# Build menu + placement
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_menu"):
		_open_build_menu()
	elif event.is_action_pressed("cancel"):
		# (When the Hud menu is open the Hud consumes cancel itself.)
		if _placing:
			_exit_placement()
	elif event.is_action_pressed("attack"):
		if _placing:
			_try_place()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	# Ghost preview tracks the cursor, snapped to a grid cell; tinted red when blocked.
	if _placing and _ghost:
		var cell: Vector2i = world_to_cell(to_local(get_global_mouse_position()))
		_ghost.position = cell_to_world(cell)
		var ok: bool = _cell_free(cell)
		_ghost.modulate = Color(1.0, 1.0, 1.0, 0.55) if ok else Color(1.0, 0.35, 0.3, 0.55)
		# The build grid + hovered-cell box so placement has a visible target (QA F-20).
		if _place_guide != null and is_instance_valid(_place_guide):
			_place_guide.hover = cell
			_place_guide.valid = ok
			_place_guide.queue_redraw()

func _open_build_menu() -> void:
	if _placing or hud == null:
		return
	Main.tip("build", "Pick a building, then left-click a tended (bright) tile to drop its frame. 'Expand Clearing' tends more land to build on.")
	var entries: Array = []
	for key in BUILDINGS.keys():
		var id: String = key
		var info: Dictionary = BUILDINGS[id]
		var cost: Dictionary = info["cost"]
		entries.append({
			"id": id,
			"label": String(info["label"]),
			"cost": cost,
			"affordable": GameState.can_afford(cost),
		})
	# The expansion option: no placement, it just tends more of the field.
	if GameState.village_radius < FIELD - 1:
		var ecost: Dictionary = _expand_cost()
		entries.append({
			"id": "expand",
			"label": "Expand Clearing",
			"cost": ecost,
			"affordable": GameState.can_afford(ecost),
		})
	hud.open_build_menu(entries)

# Expansion cost climbs with how much land you've already tended.
func _expand_cost() -> Dictionary:
	var r: int = GameState.village_radius
	return {"wood": 4 + r * 3, "stone": 2 + r * 2}

func _on_build_selected(id: String) -> void:
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
	# Menu closed without a pick: nothing to place, ensure ghost is gone.
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
	if _ghost:
		_ghost.visible = false
	if _place_guide != null and is_instance_valid(_place_guide):
		_place_guide.queue_free()
		_place_guide = null

# Commit a placement on left-click, if the cell is free and affordable.
func _try_place() -> void:
	if not _placing:
		return
	var cell: Vector2i = world_to_cell(to_local(get_global_mouse_position()))
	if not _cell_free(cell):
		return  # click empty in-bounds cells only; keep placing otherwise
	var info: Dictionary = BUILDINGS[_place_id]
	var cost: Dictionary = info["cost"]
	if not GameState.can_afford(cost):
		if hud:
			hud.toast("Not enough materials", Palette.BLOOD)
		return
	GameState.spend(cost)
	GameState.grid[cell] = {"type": _place_id, "built": false}
	_spawn_scaffold(cell, _place_id)
	_exit_placement()
	Main.tip("hammer", "That's a frame. Stand beside it and tap E a few times to hammer it up.")

# ===========================================================================
# Inner classes (used only by the Village)
# ===========================================================================

# A floor overlay drawn during build placement: faint outlines on every buildable
# cell + a bold box on the hovered cell (gold = valid, red = blocked) so the player
# can see exactly where a building will land and how far the clearing reaches (F-20).
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
		for gy in range(-r, r + 1):
			for gx in range(-r, r + 1):
				var cell := Vector2i(gx, gy)
				if not village._cell_free(cell):
					continue
				var c: Vector2 = village.cell_to_world(cell)
				draw_rect(Rect2(c - half, Vector2(C, C)),
					Color(gold.r, gold.g, gold.b, 0.16), false, 1.0)
		# The hovered cell: filled tint + bold outline, coloured by validity.
		var hc: Vector2 = village.cell_to_world(hover)
		var col: Color = Palette.GOLD_L if valid else Palette.BLOOD
		var hr := Rect2(hc - half, Vector2(C, C))
		draw_rect(hr, Color(col.r, col.g, col.b, 0.14), true)
		draw_rect(hr, col, false, 2.5)

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
		progress += 0.34
		Vfx.embers(get_parent(), global_position, 6, Palette.AMBER)
		_thunk()
		if progress >= 1.0:
			_complete()

	# Rescuing a Builder automates construction over time.
	func _process(delta: float) -> void:
		if _done:
			return
		if GameState.has_rescued("builder"):
			progress += delta * 0.5
			if progress >= 1.0:
				_complete()

	# Little hammer-shake for feedback.
	func _thunk() -> void:
		if _sprite == null:
			return
		var tw := _sprite.create_tween()
		tw.tween_property(_sprite, "position", Vector2(0, -3), 0.05)
		tw.tween_property(_sprite, "position", Vector2.ZERO, 0.08)

	func _complete() -> void:
		if _done:
			return
		_done = true
		if village:
			village.finish_building(cell, build_id)
		queue_free()

# A soil plot atop a finished Crop Bed: plant a seed, wait through 4 stages, harvest.
class CropPlot extends Node2D:
	const STAGE_TIME := 4.0
	var stage: int = -1   # -1 = empty soil; 0..3 = growing; 3 = ripe
	var t: float = 0.0
	var village: Village = null   # to refresh the objective chain on plant/harvest
	var _sprite: Sprite2D = null

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
			GameState.add_resource("food", 2)
			GameState.add_resource("seeds", 1)  # one seed back to keep the loop going
			Vfx.embers(get_parent(), global_position, 12, Palette.GOLD)
			Vfx.float_text(get_parent(), global_position, "+2 food", Palette.AMBER)
			stage = -1
			t = 0.0
			_refresh_sprite()
		if village != null and is_instance_valid(village):
			village._update_objective()

	func _process(delta: float) -> void:
		if stage >= 0 and stage < 3:
			t += delta
			if t >= STAGE_TIME:
				t = 0.0
				stage = mini(stage + 1, 3)
				_refresh_sprite()
		# Teach planting/harvesting the first time the hero stands over a plot.
		var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and global_position.distance_to(pl.global_position) < 72.0:
			if stage == -1 and GameState.amount("seeds") > 0:
				Main.tip("plant", "Empty soil. Press E to plant a seed, then come back when it's ripe.")
			elif stage == 3:
				Main.tip("harvest", "Ripe! Press E to harvest — food to live on, and a seed to replant.")

	func _refresh_sprite() -> void:
		if _sprite == null:
			return
		if stage < 0:
			_sprite.visible = false
		else:
			_sprite.visible = true
			_sprite.texture = Assets.tex("crop_%d" % stage)

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
			village.expedition_requested.emit()

# A rescued survivor living in the village: strolls the clearing, stops to WORK
# (a labouring bob), and offers a one-off quest that rewards warmth + materials.
class Villager extends Node2D:
	var pillar: String = "farmer"
	var village: Village = null
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
		var key := "survivor_" + pillar
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
			return Loc.t("Speak to the %s  [E]") % Loc.t(pillar)
		match _state():
			"active":
				var prog: int = village.quest_progress(pillar)
				var need: int = int(q["need"])
				if prog >= need:
					return Loc.t("Turn in “%s”  [E]") % Loc.t(String(q["title"]))
				return "%s   (%d/%d)  [E]" % [Loc.t(String(q["title"])), prog, need]
			"done":
				return Loc.t("Thank the %s  [E]") % Loc.t(pillar)
			_:
				return Loc.t("Speak to the %s  [E]") % Loc.t(pillar)

	func do_interact(_by: Node) -> void:
		var q: Dictionary = Village.QUESTS.get(pillar, {})
		if q.is_empty():
			return
		var st := _state()
		if st == "new":
			GameState.quests[pillar] = "active"
			_toast(Loc.t("%s: “%s”") % [Loc.t(pillar.capitalize()), Loc.t(String(q["ask"]))], Palette.CYAN)
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
			_toast(Loc.t(String(q["thanks"])), Palette.AMBER)

	func _toast(text: String, col: Color) -> void:
		if village != null and village.hud != null and village.hud.has_method("toast"):
			village.hud.call("toast", text, col)
