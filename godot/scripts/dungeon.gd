class_name Dungeon
extends Node2D
## One procedurally-decorated subterranean ruin chamber (v1 = single hall, not
## multi-room). Builds its own tiles, walls, portal, survivor, husks and loot in
## _ready(). Main injects `hud`, reads `spawn_point()`, and listens for `exited`.

# Fired when the player uses the return Portal — Main frees this and reloads the
# village.
signal exited

# Chamber size in tiles (× Palette.CELL for world px). A wide rectangular hall.
const W := 26
const H := 16

# Injected by Main before this node enters the tree (a Hud). Left untyped on
# purpose: the Hud class is not compiled in this module. The Dungeon does not
# call it, but Main sets it uniformly across layers.
var hud

# Vector2i(cell) -> bool (true = walkable floor, false = solid wall).
var _walkable: Dictionary = {}
# Flat list of walkable interior cells, used for random spawning.
var _open_cells: Array[Vector2i] = []

# Key cells decided up front so spawns and protection agree.
var _entrance: Vector2i = Vector2i.ZERO   # player start, bottom-centre
var _portal_cell: Vector2i = Vector2i.ZERO  # exit, top-centre
var _survivor_cell: Vector2i = Vector2i.ZERO  # captive, far corner

func _ready() -> void:
	_build_grid()
	_render_tiles()
	_collect_open_cells()
	_setup_atmosphere()
	_spawn_portal()
	_spawn_survivor()
	_spawn_enemies()
	_scatter_pickups()

# ---------------------------------------------------------------------------
# Atmosphere
# ---------------------------------------------------------------------------

## Drop the chamber into near-darkness and then carve it back out with fire.
## This is what makes the ruin feel underground: the player's lantern and a
## handful of braziers are the only reasons anything is visible, so the room
## reveals itself as you walk it instead of being flatly presented.
func _setup_atmosphere() -> void:
	Iso.ambient(self, Palette.AMBIENT_DUNGEON)

	# Braziers on open floor, spread out and kept clear of the entrance so the
	# player walks from dark into light rather than starting in a pool of it.
	var spots := _pick_spawn_cells(9, 3)
	var placed: Array[Vector2i] = []
	for cell: Vector2i in spots:
		var too_close := false
		for p: Vector2i in placed:
			if absi(p.x - cell.x) + absi(p.y - cell.y) < 5:
				too_close = true
				break
		if too_close:
			continue
		placed.append(cell)
		var at: Vector2 = _cell_center(cell)
		var root := Iso.prop(self, "brazier", at, 34.0, 2.0)
		var l := Iso.light(root, Palette.TORCH, 140.0, 1.15)
		l.position = Vector2(0.0, -42.0)
		Iso.flicker(l, 1.15, 0.16, 0.12)
		# Embers drifting off the bowl, so the light has a visible source.
		var p := CPUParticles2D.new()
		p.texture = Assets.tex("ember")
		p.position = Vector2(0.0, -48.0)
		p.amount = 10
		p.lifetime = 1.6
		p.direction = Vector2(0, -1)
		p.spread = 22.0
		p.gravity = Vector2(0, -34)
		p.initial_velocity_min = 12.0
		p.initial_velocity_max = 34.0
		p.scale_amount_min = Palette.PX * 0.35
		p.scale_amount_max = Palette.PX * 0.8
		p.color = Palette.TORCH
		p.z_index = 30
		root.add_child(p)
		p.emitting = true

	# Collapsed masonry along the walls, purely to break up long empty runs.
	for cell: Vector2i in _pick_spawn_cells(7, 3):
		if not _touches_wall(cell):
			continue
		var at2: Vector2 = _cell_center(cell) + Vector2(randf_range(-8, 8), randf_range(-4, 4))
		var r := Iso.prop(self, "rubble", at2, 30.0, 0.0)
		r.z_index = -1

# True when a walkable cell has at least one solid neighbour.
func _touches_wall(cell: Vector2i) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = cell + d
		if _walkable.has(n):
			var w: bool = _walkable[n]
			if not w:
				return true
	return false

# Where Main drops the player: on the entrance floor near the bottom.
func spawn_point() -> Vector2:
	return _cell_center(_entrance)

# The chamber's full tile extent, so the camera never shows the void outside it.
func camera_bounds() -> Rect2:
	var c := float(Palette.CELL)
	return Rect2(global_position, Vector2(float(W) * c, float(H) * c))

# ---------------------------------------------------------------------------
# Layout
# ---------------------------------------------------------------------------

# Centre of a grid cell in world px (Sprite2D is centre-anchored).
func _cell_center(cell: Vector2i) -> Vector2:
	var c := float(Palette.CELL)
	return Vector2(cell.x, cell.y) * c + Vector2(c * 0.5, c * 0.5)

# Cells that must never be turned into cover walls (would trap key spawns).
func _is_protected(cell: Vector2i) -> bool:
	# Entrance column, kept open up from the bottom so the player is not boxed.
	if cell.x == _entrance.x and cell.y >= H - 4:
		return true
	# An open pocket around the exit portal.
	if absi(cell.x - _portal_cell.x) <= 2 and absi(cell.y - _portal_cell.y) <= 2:
		return true
	# The survivor's corner.
	if absi(cell.x - _survivor_cell.x) <= 1 and absi(cell.y - _survivor_cell.y) <= 1:
		return true
	return false

# Fill _walkable: border ring of wall, interior floor, plus scattered cover.
func _build_grid() -> void:
	_entrance = Vector2i(W / 2, H - 2)
	_portal_cell = Vector2i(W / 2, 1)
	_survivor_cell = Vector2i(2, 2)

	for y in range(H):
		for x in range(W):
			var cell := Vector2i(x, y)
			var border: bool = x == 0 or y == 0 or x == W - 1 or y == H - 1
			_walkable[cell] = not border

	# Scatter 6-10 random 1-2 tile wall blocks as cover.
	var blocks := randi_range(6, 10)
	for i in range(blocks):
		var bx := randi_range(2, W - 3)
		var by := randi_range(2, H - 3)
		var bw := randi_range(1, 2)
		var bh := randi_range(1, 2)
		for oy in range(bh):
			for ox in range(bw):
				var cell := Vector2i(bx + ox, by + oy)
				if not _walkable.has(cell):
					continue
				if _is_protected(cell):
					continue
				_walkable[cell] = false

	# Guarantee the survivor's tile is standable.
	_walkable[_survivor_cell] = true

# Render every cell as a tile sprite; give walls a shared StaticBody collider.
func _render_tiles() -> void:
	var body := StaticBody2D.new()  # one body, many rectangle shapes
	add_child(body)
	for y in range(H):
		for x in range(W):
			var cell := Vector2i(x, y)
			var walk: bool = _walkable[cell]
			var s := Sprite2D.new()
			s.texture = Assets.tex("tile_floor") if walk else Assets.tex("tile_wall")
			s.scale = Vector2(Palette.PX, Palette.PX)
			s.position = _cell_center(cell)
			s.z_index = -10  # keep tiles beneath every entity
			# Mirror floor slabs per cell so the flagstone joints stop lining up
			# into an obvious grid. Walls are left alone: their lit top lip has to
			# stay at the top of every block.
			if walk:
				s.flip_h = Art.hash01(x * 73856093 + y * 19349663) > 0.5
				s.flip_v = Art.hash01(x * 83492791 + y * 2971215073) > 0.5
			add_child(s)
			if not walk:
				var cs := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(float(Palette.CELL), float(Palette.CELL))
				cs.shape = rect
				cs.position = _cell_center(cell)
				body.add_child(cs)

# Cache every walkable interior cell for random spawn selection.
func _collect_open_cells() -> void:
	_open_cells.clear()
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			var cell := Vector2i(x, y)
			var walk: bool = _walkable[cell]
			if walk:
				_open_cells.append(cell)

# Pick up to `count` distinct open cells at least `min_dist` (manhattan) from
# the entrance, excluding the survivor's tile.
func _pick_spawn_cells(count: int, min_dist: int) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for cell: Vector2i in _open_cells:
		var d: int = absi(cell.x - _entrance.x) + absi(cell.y - _entrance.y)
		if d >= min_dist and cell != _survivor_cell:
			candidates.append(cell)
	candidates.shuffle()
	var picked: Array[Vector2i] = []
	for i in range(mini(count, candidates.size())):
		var c: Vector2i = candidates[i]
		picked.append(c)
	return picked

func _random_material() -> String:
	var mats: Array[String] = ["wood", "stone", "iron"]
	return mats[randi_range(0, mats.size() - 1)]

# ---------------------------------------------------------------------------
# Spawns
# ---------------------------------------------------------------------------

func _spawn_portal() -> void:
	var portal := Portal.new()
	portal.dungeon = self
	portal.position = _cell_center(_portal_cell)
	add_child(portal)

func _spawn_survivor() -> void:
	# Survivor lives in a sibling file; --check-only may not resolve the type.
	var surv := Survivor.new()
	surv.pillar = "farmer"           # set before adding: it self-cages in _ready
	surv.position = _cell_center(_survivor_cell)
	add_child(surv)

func _spawn_enemies() -> void:
	var count := randi_range(4, 6)
	var spots := _pick_spawn_cells(count, 5)
	for cell: Vector2i in spots:
		# Enemy lives in a sibling file; --check-only may not resolve the type.
		var e := Enemy.new()
		e.position = _cell_center(cell)
		e.died.connect(_on_enemy_died)  # drop loot where it falls
		add_child(e)

# Husk death: 45% chance to drop one random material pickup at the corpse.
func _on_enemy_died(pos: Vector2) -> void:
	if randf() < 0.45:
		var kind: String = _random_material()
		_spawn_pickup(kind, pos)

func _scatter_pickups() -> void:
	var spots := _pick_spawn_cells(4, 2)
	for cell: Vector2i in spots:
		var kind: String = _random_material()
		_spawn_pickup(kind, _cell_center(cell))

func _spawn_pickup(kind: String, pos: Vector2) -> void:
	var pk := Pickup.new(kind)
	pk.position = pos
	add_child(pk)

# ---------------------------------------------------------------------------
# Inner classes (used only by the Dungeon)
# ---------------------------------------------------------------------------

# Floor loot: walk over it to bank one unit of a material.
class Pickup extends Area2D:
	var kind: String = "wood"
	var _sprite: Sprite2D = null
	var _t: float = 0.0

	func _init(k: String) -> void:
		kind = k

	func _ready() -> void:
		# Shadow first: without one, a hovering pickup reads as a UI icon that
		# has fallen into the world.
		var sh := Sprite2D.new()
		sh.texture = Assets.tex("shadow_small")
		sh.scale = Vector2(0.34, 0.34)
		sh.modulate = Color(0, 0, 0, 0.40)
		sh.z_index = -1
		add_child(sh)

		_sprite = Sprite2D.new()
		_sprite.texture = Assets.tex("material_" + kind)
		_sprite.scale = Vector2(Palette.PX, Palette.PX)
		add_child(_sprite)
		# Desync so a scattered field of loot doesn't pulse in unison.
		_t = randf() * TAU

		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 12.0
		cs.shape = c
		add_child(cs)
		body_entered.connect(_on_body_entered)

	# Loot hovers and turns. Motion is what makes it findable in a dark room.
	func _process(delta: float) -> void:
		_t += delta * 2.6
		if _sprite != null:
			_sprite.position.y = -8.0 + sin(_t) * 3.0
			_sprite.rotation = sin(_t * 0.6) * 0.10
		if randf() < delta * 0.5:
			Vfx.glint(get_parent(), global_position + Vector2(0.0, -10.0), Palette.GOLD_L)

	func _on_body_entered(body: Node) -> void:
		if body.is_in_group("player"):
			GameState.add_resource(kind, 1)
			var at: Vector2 = global_position + Vector2(0.0, -10.0)
			Vfx.float_text(get_parent(), at, "+1 " + kind, Palette.AMBER)
			Vfx.glint(get_parent(), at, Palette.GOLD_L)
			Vfx.embers(get_parent(), at, 6, Palette.GOLD)
			queue_free()

# Exit portal: the interactable that ends the run.
class Portal extends Node2D:
	var dungeon: Dungeon = null  # set on spawn so do_interact can fire `exited`
	var _rift: Sprite2D = null
	var _t: float = 0.0

	func _ready() -> void:
		var s := Sprite2D.new()
		s.texture = Assets.tex("portal")
		s.scale = Vector2(Palette.PX, Palette.PX)
		add_child(s)
		_rift = s
		add_to_group("interactable")

		# The one cold light in the ruin, so the way out is visible from a
		# distance and never competes with the warm braziers.
		var l := Iso.light(self, Palette.CYAN, 130.0, 1.0)
		l.position = Vector2(0.0, -6.0)
		Iso.flicker(l, 1.0, 0.12, 0.35)

		var p := CPUParticles2D.new()
		p.texture = Assets.tex("ember")
		p.amount = 12
		p.lifetime = 1.8
		p.direction = Vector2(0, -1)
		p.spread = 30.0
		p.gravity = Vector2(0, -26)
		p.initial_velocity_min = 10.0
		p.initial_velocity_max = 30.0
		p.scale_amount_min = Palette.PX * 0.3
		p.scale_amount_max = Palette.PX * 0.7
		p.color = Palette.CYAN
		p.z_index = 30
		add_child(p)
		p.emitting = true

	# A slow breathing pulse — the rift is open and working.
	func _process(delta: float) -> void:
		_t += delta * 1.7
		if _rift != null:
			var k: float = 1.0 + sin(_t) * 0.025
			_rift.scale = Vector2(Palette.PX * k, Palette.PX * (2.0 - k))

	# --- Interaction protocol (see DESIGN.md) ---
	func interact_radius() -> float:
		return 40.0

	func can_interact(by: Node) -> bool:
		return true

	func interact_prompt() -> String:
		return "Return home  [E]"

	func do_interact(by: Node) -> void:
		if dungeon:
			dungeon.exited.emit()
