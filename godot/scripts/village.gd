class_name Village
extends Node2D
## The persistent settlement layer. Renders the 8x8 grass build grid, applies the
## Global Warmth Index (GWI) full-screen grade, rebuilds every structure recorded
## in GameState (finished buildings + in-progress scaffolds), grows crops, and
## hosts the Supply Gate that starts an expedition. Main injects `hud`, reads
## `spawn_point()`, and listens for `expedition_requested`.

# Fired when the player uses the Supply Gate — Main frees this and loads the Dungeon.
signal expedition_requested

# Village build grid is 8x8 cells, centred around this node's origin.
const GRID := 8

# Extra rings of ground rendered outside the build grid so the settlement sits in
# a landscape rather than on a floating slab.
const GROUND_MARGIN := 7

# The module owns the buildable catalogue: cost, finished texture, and the GWI
# warmth each completed building radiates.
const BUILDINGS := {
	"cabin": {"label": "Cabin", "cost": {"wood": 5, "stone": 2}, "tex": "building_cabin", "gwi": 0.18},
	"forge": {"label": "Forge", "cost": {"stone": 4, "iron": 2}, "tex": "building_forge", "gwi": 0.15},
	"crop_bed": {"label": "Crop Bed", "cost": {"wood": 3}, "tex": "building_crop_bed", "gwi": 0.05},
}

# Injected by Main before this node enters the tree (a Hud). Left untyped on
# purpose: the Hud class is not compiled into this module. Always null-guarded.
var hud

# Top-left world offset so the GRIDxGRID grid is centred on this node's origin.
var origin: Vector2 = Vector2.ZERO

# --- Build placement state ---
var _placing: bool = false          # true while a ghost is following the cursor
var _place_id: String = ""          # which building the ghost represents
var _ghost: Sprite2D = null         # translucent preview sprite

# --- GWI overlay handles (updated on gwi_changed) ---
var _gwi_mat: ShaderMaterial = null
var _gwi_rect: ColorRect = null

# --- Atmosphere handles (also driven by gwi_changed) ---
var _ambient: CanvasModulate = null
var _fire_light: PointLight2D = null

func _ready() -> void:
	# Centre the grid around origin: subtract half the grid extent.
	var half: float = float(GRID * Palette.CELL) * 0.5
	origin = Vector2(-half, -half)

	_render_ground()
	_setup_gwi_overlay()
	_setup_atmosphere()
	_seed_and_rebuild()
	_spawn_supply_gate()

	# Build-menu wiring (null-guarded: Main may not have supplied a Hud).
	if hud:
		hud.build_selected.connect(_on_build_selected)
		hud.build_cancelled.connect(_on_build_cancelled)
	GameState.gwi_changed.connect(_on_gwi_changed)

# Where Main drops the player: the grid centre (this node's origin), on grass.
func spawn_point() -> Vector2:
	return global_position

# The rectangle the camera is allowed to show — the full rendered meadow, so the
# view never slides off the ground into the void.
func camera_bounds() -> Rect2:
	var half: float = float((GRID + GROUND_MARGIN * 2) * Palette.CELL) * 0.5
	return Rect2(global_position - Vector2(half, half), Vector2(half, half) * 2.0)

# ---------------------------------------------------------------------------
# Grid <-> world helpers
# ---------------------------------------------------------------------------

# Centre of a grid cell in this layer's local space (Sprite2D is centre-anchored).
func cell_to_world(cell: Vector2i) -> Vector2:
	var c := float(Palette.CELL)
	return origin + Vector2(cell) * c + Vector2(c * 0.5, c * 0.5)

# Which cell a local-space point falls in (may be out of bounds).
func world_to_cell(point: Vector2) -> Vector2i:
	var c := float(Palette.CELL)
	var local: Vector2 = point - origin
	return Vector2i(int(floor(local.x / c)), int(floor(local.y / c)))

# True when a cell is inside the grid and not already occupied.
func _cell_free(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID or cell.y >= GRID:
		return false
	return not GameState.grid.has(cell)

# ---------------------------------------------------------------------------
# World construction
# ---------------------------------------------------------------------------

# Lay the ground down. The meadow runs well past the 8x8 build grid: with the
# camera pulled back to Hades framing, a bed that stopped at the buildable cells
# left the settlement floating in a black void.
func _render_ground() -> void:
	for gy in range(-GROUND_MARGIN, GRID + GROUND_MARGIN):
		for gx in range(-GROUND_MARGIN, GRID + GROUND_MARGIN):
			var cell := Vector2i(gx, gy)
			var s := Sprite2D.new()
			# A trodden dirt path rings the plot, which frames the buildable area
			# without needing a UI overlay to explain where it is.
			var ring: bool = (gx == -1 or gx == GRID or gy == -1 or gy == GRID) \
					and gx >= -1 and gx <= GRID and gy >= -1 and gy <= GRID
			# Pick one of the four grass variants, then mirror it, on a hash of the
			# cell coordinates. Sixteen combinations from four textures, all
			# wrap-scattered so every pairing still meets seamlessly — which is
			# what stops a meadow of one tile reading as a lattice.
			var h: float = Art.hash01(gx * 73856093 + gy * 19349663)
			var v: int = int(Art.hash01(gx * 6151 + gy * 31337) * 4.0) % 4
			var grass: String = "tile_grass" if v == 0 else "tile_grass_%d" % v
			s.texture = Assets.tex("tile_path" if ring else grass)
			s.scale = Vector2(Palette.PX, Palette.PX)
			s.position = cell_to_world(cell)
			s.z_index = -10  # keep tiles beneath every structure and entity
			s.flip_h = h > 0.5
			s.flip_v = Art.hash01(gx * 83492791 + gy * 2971215073) > 0.5
			add_child(s)
	_scatter_ground_detail()

# Loose scenery outside the build grid: it breaks the tile lattice with something
# that is obviously hand-placed rather than tiled, and gives the eye somewhere to
# rest at the edge of the settlement.
func _scatter_ground_detail() -> void:
	var span: float = float((GRID + GROUND_MARGIN * 2) * Palette.CELL) * 0.5
	for i in range(26):
		var k := i * 5711 + 13
		var x: float = lerpf(-span, span, Art.hash01(k))
		var y: float = lerpf(-span, span, Art.hash01(k + 1))
		# Keep the buildable plot itself clear.
		var pad: float = float(GRID * Palette.CELL) * 0.5 + float(Palette.CELL)
		if absf(x) < pad and absf(y) < pad:
			continue
		var r := Iso.prop(self, "rubble", Vector2(x, y), 26.0, 0.0)
		r.scale = Vector2(0.7, 0.7)
		r.z_index = -2

# Full-screen GWI colour grade on its own CanvasLayer (below the HUD at layer 10).
func _setup_gwi_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)

	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # never eat clicks
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/gwi.gdshader")
	mat.set_shader_parameter("gwi", GameState.gwi)
	rect.material = mat
	layer.add_child(rect)

	_gwi_rect = rect
	_gwi_mat = mat
	_update_overlay_size()
	# Keep the grade covering the whole viewport as the window resizes.
	get_viewport().size_changed.connect(_update_overlay_size)

func _update_overlay_size() -> void:
	if _gwi_rect == null:
		return
	var vp := get_viewport()
	if vp == null:
		return
	_gwi_rect.position = Vector2.ZERO
	_gwi_rect.size = vp.get_visible_rect().size

func _on_gwi_changed(value: float) -> void:
	if _gwi_mat:
		_gwi_mat.set_shader_parameter("gwi", value)
	_apply_ambient(value)

# ---------------------------------------------------------------------------
# Atmosphere
# ---------------------------------------------------------------------------

## The settlement's own light, separate from the GWI screen grade. A cold
## dusk-lit village at gwi 0 lifts toward full daylight as it is rebuilt, so the
## warmth the player earns is something the eye can see on the grass, not just a
## post-process filter over the top of it.
func _setup_atmosphere() -> void:
	_ambient = Iso.ambient(self, Palette.AMBIENT_VILLAGE)
	_apply_ambient(GameState.gwi)

	# The bonfire is the heart of the settlement. Placed just off the north edge
	# of the build grid, opposite the Supply Gate, so it never blocks a cell or
	# the player's spawn.
	var at := Vector2(0.0, origin.y - float(Palette.CELL) * 0.55)
	var root := Iso.prop(self, "bonfire", at, 66.0, 4.0)
	_fire_light = Iso.light(root, Palette.TORCH, 190.0, 1.3)
	_fire_light.position = Vector2(0.0, -34.0)
	Iso.flicker(_fire_light, 1.3, 0.14, 0.13)

	var p := CPUParticles2D.new()
	p.texture = Assets.tex("ember")
	p.position = Vector2(0.0, -46.0)
	p.amount = 18
	p.lifetime = 2.1
	p.direction = Vector2(0, -1)
	p.spread = 26.0
	p.gravity = Vector2(0, -40)
	p.initial_velocity_min = 16.0
	p.initial_velocity_max = 46.0
	p.scale_amount_min = Palette.PX * 0.4
	p.scale_amount_max = Palette.PX * 0.95
	p.color = Palette.TORCH
	p.z_index = 30
	root.add_child(p)
	p.emitting = true

func _apply_ambient(gwi: float) -> void:
	if _ambient == null:
		return
	var k: float = clampf(gwi, 0.0, 1.0)
	_ambient.color = Palette.AMBIENT_VILLAGE.lerp(Color(1, 1, 1, 1), k)
	if _fire_light != null and is_instance_valid(_fire_light):
		# The bonfire grows with the settlement it warms.
		_fire_light.texture_scale = lerpf(190.0, 300.0, k) / 128.0

# First visit seeds one pre-built Crop Bed so farming is reachable turn one;
# then (every visit) reconstruct every structure the grid records.
func _seed_and_rebuild() -> void:
	if not GameState.village_seeded:
		var seed_cell := Vector2i(2, 5)
		GameState.grid[seed_cell] = {"type": "crop_bed", "built": true}
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

# Place the Supply Gate just below the grid's bottom edge (off the build cells).
func _spawn_supply_gate() -> void:
	var g := SupplyGate.new()
	g.village = self
	g.position = Vector2(0.0, origin.y + float(GRID * Palette.CELL) + float(Palette.CELL) * 0.5)
	add_child(g)

# Drop a finished building's sprite onto a cell (no side effects — used by both
# rebuild and finish_building).
func _add_building_sprite(cell: Vector2i, build_id: String) -> Sprite2D:
	var info: Dictionary = BUILDINGS.get(build_id, {})
	var tex_key: String = String(info.get("tex", "building_cabin"))
	var at: Vector2 = cell_to_world(cell)

	# Contact shadow under the eaves, so the building sits on the grass instead
	# of floating above it.
	var sh := Sprite2D.new()
	sh.texture = Assets.tex("shadow")
	sh.position = at + Vector2(0.0, 26.0)
	sh.scale = Vector2(0.46, 0.46)
	sh.modulate = Color(0, 0, 0, 0.34)
	sh.z_index = -5
	add_child(sh)

	var s := Sprite2D.new()
	s.texture = Assets.tex(tex_key)
	s.scale = Vector2(Palette.PX, Palette.PX)
	s.position = at
	add_child(s)
	return s

func _spawn_scaffold(cell: Vector2i, build_id: String) -> void:
	var sc := Scaffold.new()
	sc.setup(cell, build_id, self)
	sc.position = cell_to_world(cell)
	add_child(sc)

func _spawn_crop_plot(cell: Vector2i) -> void:
	var cp := CropPlot.new()
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

	var s: Sprite2D = _add_building_sprite(cell, build_id)
	var at: Vector2 = cell_to_world(cell)

	# The building punches up out of the ground rather than blinking on: a
	# squashed start overshooting to full size is the whole "raised!" beat.
	if s != null:
		s.scale = Vector2(Palette.PX * 1.25, Palette.PX * 0.15)
		var tw := s.create_tween()
		tw.tween_property(s, "scale", Vector2(Palette.PX, Palette.PX), 0.42) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var info: Dictionary = BUILDINGS.get(build_id, {})
	GameState.add_gwi(float(info.get("gwi", 0.0)))

	# Completion is the loudest positive moment in the village, so it gets the
	# full stack: ground ring, dust at the footings, a fountain of embers, and a
	# light that briefly warms the whole plot.
	Vfx.shockwave(self, at + Vector2(0.0, 24.0), 96.0, Palette.GOLD_L, 0.46)
	Vfx.dust(self, at + Vector2(0.0, 24.0), 14)
	Vfx.debris(self, at + Vector2(0.0, 10.0), "chip_wood", 10)
	Vfx.embers(self, at, 30, Palette.GOLD)
	Vfx.light_pop(self, at, Palette.TORCH, 260.0, 0.8)
	Vfx.glint(self, at + Vector2(0.0, -34.0), Palette.GOLD_L)
	Juice.shake(7.0, 0.34)
	Juice.flash(Palette.GOLD_L, 0.20, 0.35)
	if hud:
		hud.toast("%s raised!" % String(info.get("label", build_id)), Palette.GOLD)

	if build_id == "crop_bed":
		_spawn_crop_plot(cell)

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

func _open_build_menu() -> void:
	if _placing or hud == null:
		return
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
	hud.open_build_menu(entries)

func _on_build_selected(id: String) -> void:
	_enter_placement(id)

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

func _exit_placement() -> void:
	_placing = false
	_place_id = ""
	if _ghost:
		_ghost.visible = false

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

# ===========================================================================
# Inner classes (used only by the Village)
# ===========================================================================

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
		var sh := Sprite2D.new()
		sh.texture = Assets.tex("shadow")
		sh.position = Vector2(0.0, 26.0)
		sh.scale = Vector2(0.42, 0.42)
		sh.modulate = Color(0, 0, 0, 0.30)
		sh.z_index = -5
		add_child(sh)

		_sprite = Sprite2D.new()
		_sprite.texture = Assets.tex("building_scaffold")
		_sprite.scale = Vector2(Palette.PX, Palette.PX)
		add_child(_sprite)
		add_to_group("interactable")
		_apply_progress()

	# The frame physically grows out of the ground as it is hammered, so progress
	# is legible from across the village without reading the prompt.
	func _apply_progress() -> void:
		if _sprite == null:
			return
		var k: float = lerpf(0.42, 1.0, clampf(progress, 0.0, 1.0))
		_sprite.scale = Vector2(Palette.PX, Palette.PX * k)
		# Anchor the growth to the base rather than the centre.
		_sprite.position.y = (1.0 - k) * float(_sprite.texture.get_height()) * Palette.PX * 0.5
		_sprite.modulate.a = lerpf(0.62, 1.0, clampf(progress, 0.0, 1.0))

	# --- Interaction protocol (see DESIGN.md) ---
	func interact_radius() -> float:
		return 34.0

	func can_interact(_by: Node) -> bool:
		return not _done

	func interact_prompt() -> String:
		return "Hammer  [E]  (%d%%)" % int(progress * 100.0)

	func do_interact(by: Node) -> void:
		if _done:
			return
		progress += 0.34
		_apply_progress()

		# A hammer blow: the strike lands at the top of the frame, throws chips
		# and sparks, kicks dust off the footings and shoves the camera. Same
		# grammar as a melee hit, because it is one — just against timber.
		var strike: Vector2 = global_position + Vector2(0.0, -18.0)
		var from: Vector2 = Vector2.LEFT
		if by is Node2D:
			var b := by as Node2D
			from = (strike - b.global_position).normalized()
		Vfx.impact(get_parent(), strike, from, 0.5)
		Vfx.debris(get_parent(), strike, "chip_wood", 7)
		Vfx.dust(get_parent(), global_position + Vector2(0.0, 20.0), 5)
		Vfx.embers(get_parent(), strike, 5, Palette.AMBER)
		Vfx.float_text(get_parent(), global_position + Vector2(0.0, -40.0),
				"%d%%" % int(clampf(progress, 0.0, 1.0) * 100.0), Palette.AMBER)
		Juice.hitstop(0.035)
		Juice.shake(5.0, 0.20)
		_thunk()

		if progress >= 1.0:
			_complete()

	# Rescuing a Builder automates construction over time.
	func _process(delta: float) -> void:
		if _done:
			return
		if GameState.has_rescued("builder"):
			progress += delta * 0.5
			_apply_progress()
			# The unseen Builder is still working: an occasional puff of dust so
			# an auto-raising plot doesn't look inert.
			if randf() < delta * 3.0:
				Vfx.dust(get_parent(), global_position + Vector2(randf_range(-16, 16), 18), 2)
			if progress >= 1.0:
				_complete()

	# Hammer recoil: the frame takes the blow and settles back.
	func _thunk() -> void:
		if _sprite == null:
			return
		var rest_y: float = _sprite.position.y
		var rest: Vector2 = _sprite.scale
		var tw := _sprite.create_tween()
		tw.tween_property(_sprite, "position:y", rest_y + 4.0, 0.05) \
			.set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(_sprite, "scale",
				Vector2(rest.x * 1.10, rest.y * 0.88), 0.05)
		tw.tween_property(_sprite, "position:y", rest_y, 0.14) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(_sprite, "scale", rest, 0.14) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
	var _sprite: Sprite2D = null
	var _sway: float = 0.0        # wind phase accumulator
	var _popping: bool = false    # a growth pop owns the transform while true

	func _ready() -> void:
		_sprite = Sprite2D.new()
		_sprite.scale = Vector2(Palette.PX, Palette.PX)
		add_child(_sprite)
		add_to_group("interactable")
		_refresh_sprite()

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
			return "Plant seed  [E]"
		if stage == 3:
			return "Harvest  [E]"
		return "Growing..."

	func do_interact(_by: Node) -> void:
		if stage == -1:
			if GameState.amount("seeds") > 0:
				GameState.spend({"seeds": 1})
				stage = 0
				t = 0.0
				_refresh_sprite()
				Vfx.dust(get_parent(), global_position + Vector2(0.0, 8.0), 5)
				Vfx.leaves(get_parent(), global_position, 4)
		elif stage == 3:
			GameState.add_resource("food", 2)
			GameState.add_resource("seeds", 1)  # one seed back to keep the loop going
			# Harvest: the crop bursts into leaf and grain rather than blinking out.
			Vfx.leaves(get_parent(), global_position + Vector2(0.0, -14.0), 16)
			Vfx.embers(get_parent(), global_position, 10, Palette.GOLD)
			Vfx.glint(get_parent(), global_position + Vector2(0.0, -20.0), Palette.GOLD_L)
			Vfx.shockwave(get_parent(), global_position + Vector2(0.0, 8.0), 46.0,
					Palette.LEAF, 0.30, "ring_soft")
			Vfx.float_text(get_parent(), global_position + Vector2(0.0, -26.0),
					"+2 food", Palette.AMBER)
			Juice.shake(2.5, 0.16)
			stage = -1
			t = 0.0
			_refresh_sprite()

	func _process(delta: float) -> void:
		_sway += delta
		if stage >= 0 and stage < 3:
			t += delta
			if t >= STAGE_TIME:
				t = 0.0
				stage = mini(stage + 1, 3)
				_refresh_sprite()
				# Each growth step pops, so the village is visibly working even
				# when the player is looking somewhere else.
				_pop()
				Vfx.leaves(get_parent(), global_position + Vector2(0.0, -10.0), 3)
		# A slow wind sway on everything planted. Phase is offset per plot by its
		# position so a field doesn't wave in unison.
		if _sprite != null and _sprite.visible and not _popping:
			var ph: float = _sway * 1.6 + global_position.x * 0.05
			_sprite.rotation = sin(ph) * 0.045
			_sprite.scale = Vector2(Palette.PX, Palette.PX * (1.0 + sin(ph * 1.3) * 0.018))
		# Ripe crops sparkle now and then to pull the eye across the village.
		if stage == 3 and randf() < delta * 0.55:
			Vfx.glint(get_parent(), global_position + Vector2(randf_range(-8, 8), -18.0),
					Palette.GOLD_L)

	func _refresh_sprite() -> void:
		if _sprite == null:
			return
		if stage < 0:
			_sprite.visible = false
		else:
			_sprite.visible = true
			_sprite.texture = Assets.tex("crop_%d" % stage)

	# Scale punch on a growth step. `_popping` parks the sway for its duration so
	# the two do not fight over the transform.
	func _pop() -> void:
		if _sprite == null:
			return
		_popping = true
		_sprite.rotation = 0.0
		_sprite.scale = Vector2(Palette.PX * 0.72, Palette.PX * 1.28)
		var tw := _sprite.create_tween()
		tw.tween_property(_sprite, "scale", Vector2(Palette.PX, Palette.PX), 0.34) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void: _popping = false)

# The run-start point: interact to descend into the ruins.
class SupplyGate extends Node2D:
	var village: Village = null  # set on spawn so do_interact can fire the signal

	func _ready() -> void:
		var s := Sprite2D.new()
		s.texture = Assets.tex("supply_gate")
		s.scale = Vector2(Palette.PX, Palette.PX)
		add_child(s)
		add_to_group("interactable")

	# --- Interaction protocol ---
	func interact_radius() -> float:
		return 40.0

	func can_interact(_by: Node) -> bool:
		return true

	func interact_prompt() -> String:
		return "Descend into the ruins  [E]"

	func do_interact(_by: Node) -> void:
		if village:
			village.expedition_requested.emit()
