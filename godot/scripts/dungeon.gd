class_name Dungeon
extends Node2D
## One subterranean ruin chamber, run as a Hades-style locked combat arena: the
## exits stay sealed until every husk is cleared, then a choice of gates opens
## with a reward preview — push DEEPER for richer, harder rooms, or take the HOME
## gate to bank your loot and rebuild. Main chains rooms within a run.
##
## Builds its own tiles, walls, survivor, husks and loot in _ready(). Main injects
## `hud`, reads `spawn_point()`, and listens for `exited` (home) and
## `advance_requested` (next room).

# Fired when the player takes the HOME gate — Main frees this and reloads the village.
signal exited
# Fired when the player takes a gate into a chosen map node — Main loads that room.
signal advance_requested(node_id: int)

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

# Which room this is within the current run (1 = first descent room). Set by Main
# before the node enters the tree; scales danger and loot.
var room_index: int = 1
# This room's node on the run map, and its type ("combat" | "treasure" | "rescue"
# | "rest" | "boss"). Set by Main; decides what the room spawns and which gates open.
var node_id: int = -1
var node_type: String = "combat"

# Arena state: husks left alive, and whether the exits have opened.
var _enemies_alive: int = 0
var _spawn_total: int = 0        # how many husks this room started with (for the tally)
var _cleared: bool = false
var _boss: Enemy = null          # the Warden, in boss rooms — polled for the boss bar

# Key cells decided up front so spawns and protection agree.
var _entrance: Vector2i = Vector2i.ZERO   # player start, bottom-centre
var _portal_cell: Vector2i = Vector2i.ZERO  # exit, top-centre
var _survivor_cell: Vector2i = Vector2i.ZERO  # captive, far corner

# A warm pool that rides with the hero so there is always light where you stand —
# the rest of the hall stays in near-dark until a brazier or the portal lifts it.
var _hero_light: PointLight2D = null

func _ready() -> void:
	# Feet-order depth so the hero sorts correctly against braziers, the portal and
	# husks instead of drawing through them.
	y_sort_enabled = true
	Sfx.ambient(false)   # leave the hearth's crackle behind — the ruins are cold and silent (B3)
	# Near-black ambient FIRST, so every light added after it carves a pool out of
	# the dark rather than washing over a fully-lit floor.
	Iso.ambient(self, Palette.AMBIENT_DUNGEON)
	_build_grid()
	_render_tiles()
	_collect_open_cells()
	_scatter_decals()
	_populate_by_type()
	_maybe_spawn_relic()
	_spawn_total = _enemies_alive       # remember the room's starting head-count
	_spawn_braziers()
	_setup_hero_light()

	# HUD heartbeat: the banner tracks the descent, the objective the room state.
	if hud and hud.has_method("set_depth"):
		hud.call("set_depth", GameState.run_count)
	# Combat readouts: raise the Warden bar in boss rooms, else the husk tally.
	if _boss != null and is_instance_valid(_boss) and hud and hud.has_method("show_boss"):
		hud.call("show_boss", "The Warden", _boss.max_hp)
	elif hud and hud.has_method("set_enemies"):
		hud.call("set_enemies", _enemies_alive, _spawn_total)
	if hud and hud.has_method("toast"):
		var head: String = (Loc.t("DESCENT  %d") % GameState.run_count) if room_index == 1 \
			else (Loc.t("CHAMBER  %d") % room_index)
		hud.call("toast", head, Palette.CYAN)

	# First time into the ruin: the Ember teaches combat with talking popups.
	if room_index == 1 and not GameState.combat_tutorial_seen:
		GameState.combat_tutorial_seen = true
		if hud and hud.has_method("start_dungeon_intro"):
			hud.call("start_dungeon_intro")

	# Sealed on entry: clear the room to open the exits. A room that spawns empty
	# (a treasure/rest node can roll 0 husks) still counts + opens its gates, but
	# QUIETLY — no "Chamber cleared!" fanfare for a room that was never sealed (F-34).
	if _enemies_alive <= 0:
		_on_room_cleared(true)
	elif hud and hud.has_method("set_objective"):
		hud.call("set_objective", "The exits are sealed — clear every husk")

# The hero's personal firelight, kept on their feet every frame.
func _setup_hero_light() -> void:
	_hero_light = Iso.light(self, Palette.TORCH.lerp(Palette.GOLD_L, 0.40), 300.0, 1.55)
	_hero_light.z_index = -5

func _process(_delta: float) -> void:
	if _hero_light != null and is_instance_valid(_hero_light):
		var p: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if p != null and is_instance_valid(p):
			_hero_light.global_position = p.global_position - Vector2(0.0, 18.0)
	# Feed the Warden bar the boss's live health.
	if node_type == "boss" and is_instance_valid(_boss) and hud and hud.has_method("set_boss_hp"):
		hud.call("set_boss_hp", _boss.hp)

# Where Main drops the player: on the entrance floor near the bottom.
func spawn_point() -> Vector2:
	return _cell_center(_entrance)

# What the guidance beacon points at: once cleared, the nearest exit gate; before
# that, a caged survivor to rescue (if any) — husks themselves need no beacon.
func guidance_target() -> Node2D:
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if _cleared:
		var best: Node2D = null
		var bd: float = INF
		for n in get_tree().get_nodes_in_group("interactable"):
			var nd := n as Node2D
			if nd == null or nd.get("kind") == null:
				continue   # only ExitGates carry `kind`
			var d: float = 0.0 if pl == null else nd.global_position.distance_to(pl.global_position)
			if d < bd:
				bd = d
				best = nd
		return best
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.has_method("free_it"):
			return n as Node2D   # a caged survivor
	return null

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

# Render every cell: a varied floor everywhere; the outer shell as flat dark wall;
# interior cover as a STANDING wall_block with a real face (QA F-24). One shared
# StaticBody carries all the wall colliders.
func _render_tiles() -> void:
	var body := StaticBody2D.new()  # one body, many rectangle shapes
	add_child(body)
	for y in range(H):
		for x in range(W):
			var cell := Vector2i(x, y)
			var walk: bool = _walkable[cell]
			var border: bool = x == 0 or y == 0 or x == W - 1 or y == H - 1
			if walk:
				_floor_tile(cell)
			elif border:
				var s := Sprite2D.new()
				s.texture = Assets.tex("tile_wall")
				s.scale = Vector2(Palette.TILE_SX, Palette.TILE_SY)
				s.position = _cell_center(cell)
				s.z_index = -10
				add_child(s)
				_wall_collider(body, cell)
			else:
				# Floor under the block (no hole), then a feet-anchored standing block.
				_floor_tile(cell)
				Iso.prop(self, "wall_block", _cell_center(cell), 0.0, 0.0)
				_wall_collider(body, cell)

# One floor cell, its texture varied deterministically so the hall isn't one tile
# repeated: mostly plain, some alt, a few cracked.
func _floor_tile(cell: Vector2i) -> void:
	var r: float = Art.hash01(cell.x * 73 + cell.y * 131 + 7)
	var key: String = "tile_floor"
	if r > 0.90:
		key = "tile_floor_crack"
	elif r > 0.68:
		key = "tile_floor2"
	var s := Sprite2D.new()
	s.texture = Assets.tex(key)
	s.scale = Vector2(Palette.TILE_SX, Palette.TILE_SY)
	s.position = _cell_center(cell)
	s.z_index = -10
	add_child(s)

func _wall_collider(body: StaticBody2D, cell: Vector2i) -> void:
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(float(Palette.CELL), float(Palette.CELL))
	cs.shape = rect
	cs.position = _cell_center(cell)
	body.add_child(cs)

# Floor litter — rubble and bones — so the ruin reads as ruined (QA F-24).
func _scatter_decals() -> void:
	var spots := _pick_spawn_cells(randi_range(6, 10), 3)
	for cell: Vector2i in spots:
		var s := Sprite2D.new()
		s.texture = Assets.tex("rubble" if randf() < 0.6 else "bones")
		s.scale = Vector2(Palette.PX, Palette.PX)
		s.position = _cell_center(cell)
		s.z_index = -9   # floor decal: above tiles, below everything standing
		add_child(s)

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

# Fill the room according to its map-node type. The entrance (room 1) always cages
# the tutorial farmer; the other types trade husks for loot, captives or a hearth.
func _populate_by_type() -> void:
	match node_type:
		"treasure":
			_spawn_enemies(randi_range(0, 2))
			_scatter_pickups(9)
		"rescue":
			_spawn_survivor(_rescue_pillar_for_node())
			_spawn_enemies(randi_range(3, 5))
			_scatter_pickups(4)
		"rest":
			_spawn_enemies(randi_range(0, 1))
			_scatter_pickups(3)
			_heal_hearth()
		"boss":
			_spawn_brute()
			_spawn_enemies(randi_range(2, 3))
			_scatter_pickups(5)
		_:  # "combat" (and the layer-0 start room)
			if room_index == 1:
				_spawn_survivor("farmer")
			_spawn_enemies(randi_range(4, 6) + (room_index - 1))
			_scatter_pickups(4)

func _spawn_survivor(pillar: String) -> void:
	# Survivor lives in a sibling file; --check-only may not resolve the type.
	var surv := Survivor.new()
	surv.pillar = pillar             # set before adding: it self-cages in _ready
	surv.position = _cell_center(_survivor_cell)
	add_child(surv)

# The survivor this rescue node committed to at map-generation time, so the room
# matches the gate/map preview (QA F-16). Falls back to a fresh roll if unset.
func _rescue_pillar_for_node() -> String:
	var rm = GameState.run_map
	if rm != null and node_id >= 0:
		var p: String = rm.pillar_of(node_id)
		if p != "":
			return p
	var all: Array[String] = ["farmer", "smith", "builder"]
	var fresh: Array[String] = []
	for q: String in all:
		if not GameState.has_rescued(q):
			fresh.append(q)
	var pool: Array[String] = fresh if not fresh.is_empty() else all
	return pool[randi_range(0, pool.size() - 1)]

func _spawn_enemies(count: int) -> void:
	# Difficulty tracks BOTH how deep this room is AND how many runs deep the meta is,
	# so a fresh descent isn't identical every time (QA F-03).
	var depth: int = room_index + GameState.run_count
	var spots := _pick_spawn_cells(count, 5)
	for i in range(spots.size()):
		var cell: Vector2i = spots[i]
		# Enemy lives in a sibling file; --check-only may not resolve the type.
		var e := Enemy.new()
		e.position = _cell_center(cell)
		var hp: int = 4 + (depth - 1)
		# Cap base husk speed below the hero's 220 so kiting stays a valid counterplay
		# deep in the meta (QA review 5); the charger's ×1.15 rush can still catch you.
		var spd: float = minf(100.0 + float(depth - 1) * 8.0, 200.0)
		var k: String = _roll_husk_kind(depth)
		match k:
			"charger":
				e.configure(hp + 2, spd, "enemy_husk", "charger")
			"lobber":
				e.configure(maxi(3, hp - 1), spd, "enemy_husk", "lobber")
			"bomber":
				# Fragile (pop it early) but its blast bites (touch_damage 2).
				e.configure(maxi(2, hp - 2), spd, "enemy_husk", "bomber")
				e.touch_damage = 2
			_:
				e.configure(hp, spd, "enemy_husk", "husk")
		e.died.connect(_on_enemy_died)  # drop loot where it falls + track the count
		add_child(e)
		_enemies_alive += 1

# Weight the husk roster by depth: chargers & bombers appear from depth 2, lobbers
# from 3, so early runs teach the basic lunge before the room gets busy (QA F-05).
func _roll_husk_kind(depth: int) -> String:
	if depth >= 3 and randf() < 0.22:
		return "lobber"
	if depth >= 2 and randf() < 0.18:
		return "bomber"
	if depth >= 2 and randf() < 0.28:
		return "charger"
	return "husk"

# The boss room's Warden: a slow, heavy brute that must fall to open the exits.
func _spawn_brute() -> void:
	var spots := _pick_spawn_cells(1, 6)
	var cell: Vector2i = spots[0] if not spots.is_empty() else _portal_cell
	var e := Enemy.new()
	e.position = _cell_center(cell)
	e.configure(14 + (room_index + GameState.run_count) * 2, 85.0, "enemy_brute", "warden")
	e.touch_damage = 2
	e.died.connect(_on_enemy_died)
	e.died.connect(func(_p: Vector2) -> void: _award_kindle(12 + room_index))  # Warden Kindle bounty
	add_child(e)
	_enemies_alive += 1
	_boss = e                            # tracked so _process can drive the boss bar

# Hearth rooms mend the hero — deferred, because the player is reparented into the
# room only AFTER this _ready() populate runs.
func _heal_hearth() -> void:
	get_tree().create_timer(0.2).timeout.connect(func() -> void:
		var p: Node = get_tree().get_first_node_in_group("player")
		if p != null and p.has_method("heal"):
			p.call("heal", 3)
		if hud and hud.has_method("toast"):
			hud.call("toast", "The hearth warms you  (+3)", Palette.GOLD))

# Husk death: feed the hero Kindle (deeper husks burn richer → faster Blooms), drop
# loot, then check for room clear. Kindle is run-scoped power (QA D-01) — it drives
# the succession Blooms and their drafted boons, replacing the retired Ember XP.
func _on_enemy_died(pos: Vector2) -> void:
	_award_kindle(3 + room_index)
	GameState.run_stats["husks"] = int(GameState.run_stats.get("husks", 0)) + 1
	var drop_chance: float = 0.45 + float(room_index - 1) * 0.06
	if randf() < drop_chance:
		var kind: String = _random_material()
		_spawn_pickup(kind, pos)
	_enemies_alive = maxi(0, _enemies_alive - 1)
	if hud and hud.has_method("set_enemies"):
		hud.call("set_enemies", _enemies_alive, _spawn_total)
	if _enemies_alive == 0 and not _cleared:
		_on_room_cleared()

# Route a Kindle award to the persistent hero (found by group, so this never holds
# a stale reference across a reparent). Guarded so a stray call is harmless.
func _award_kindle(amount: int) -> void:
	var p: Node = get_tree().get_first_node_in_group("player")
	if p != null and is_instance_valid(p) and p.has_method("gain_kindle"):
		p.call("gain_kindle", float(amount))

func _scatter_pickups(count: int) -> void:
	var spots := _pick_spawn_cells(count, 2)
	for cell: Vector2i in spots:
		var kind: String = _random_material()
		_spawn_pickup(kind, _cell_center(cell))

func _spawn_pickup(kind: String, pos: Vector2) -> void:
	var pk := Pickup.new(kind)
	pk.position = pos
	add_child(pk)

# Seed the chamber with an environmental story fragment (CRITIQUE A3): a frozen remnant to
# examine. Skipped in boss rooms and the very first descent (kept clean for the boss beat
# and onboarding), a coin-flip otherwise, and only while undiscovered fragments remain.
func _maybe_spawn_relic() -> void:
	if node_type == "boss" or room_index <= 1:
		return
	if randf() > 0.55:
		return
	var idx: int = GameState.next_ruins_fragment()
	if idx < 0:
		return
	var cells: Array = _pick_spawn_cells(1, 3)
	if cells.is_empty():
		return
	var r := Relic.new()
	r.frag_idx = idx
	r.fragment = String(Lore.RUINS_FRAGMENTS[idx])
	r.dungeon = self
	r.position = _cell_center(cells[0])
	add_child(r)

# ---------------------------------------------------------------------------
# Arena clear → open the choice of exits
# ---------------------------------------------------------------------------

# The last husk fell: fanfare, reframe the objective, and raise the gates. `silent`
# skips the fanfare for a room that spawned empty and was never sealed (QA F-34).
func _on_room_cleared(silent: bool = false) -> void:
	if _cleared:
		return
	_cleared = true
	GameState.run_stats["rooms"] = int(GameState.run_stats.get("rooms", 0)) + 1
	# The Ember speaks the first time the Warden falls (CRITIQUE A5) — one-time, persisted.
	if node_type == "boss":
		Main.tip("ember_first_boss", "The brute falls. It was only ever the cold, wearing a shape to frighten you.")
	if hud and hud.has_method("hide_boss"):
		hud.call("hide_boss")
	if hud and hud.has_method("set_enemies"):
		hud.call("set_enemies", 0, _spawn_total)   # "CLEARED" flash on the tally
	if not silent:
		if hud and hud.has_method("toast"):
			hud.call("toast", "Chamber cleared!", Palette.GOLD_L)
		var c: Vector2 = _cell_center(_portal_cell)
		Vfx.ring(self, c + Vector2(0.0, -30.0), 150.0, Palette.GOLD_L, 0.7)
		Vfx.embers(self, c + Vector2(0.0, -20.0), 16, Palette.GOLD)
		Main.zoom_punch(0.03)
		Main.tip("map", "The gates are open. Press Tab to see the ruin map, then walk into a glowing gate to choose your path.")
	_open_exits()

# Raise one gate per reachable map node (each previewing its room type), plus a
# HOME gate to bank and leave. Laid in a row across the open pocket at the top.
func _open_exits() -> void:
	var rm = GameState.run_map
	var reach: Array = rm.reachable() if rm != null else []
	var gates: Array = []
	for nid: int in reach:
		gates.append({"kind": "node", "node": nid, "type": rm.type_of(nid)})
	gates.append({"kind": "home"})

	var n: int = gates.size()
	for i in range(n):
		var off: float = (float(i) - float(n - 1) * 0.5) * 1.35 * float(Palette.CELL)
		var g := ExitGate.new()
		var info: Dictionary = gates[i]
		if String(info["kind"]) == "home":
			g.setup_home(self)
		else:
			var nid2: int = int(info["node"])
			var pil: String = rm.pillar_of(nid2) if rm != null else ""
			g.setup_node(self, nid2, String(info["type"]), pil)
		g.position = _cell_center(_portal_cell) + Vector2(off, float(Palette.CELL))
		add_child(g)

	if hud and hud.has_method("set_objective"):
		if reach.is_empty():
			hud.call("set_objective", "The ruin is conquered — take the gate home")
		else:
			hud.call("set_objective", "Choose a path — Tab shows the map")
	if reach.is_empty() and hud and hud.has_method("toast"):
		hud.call("toast", "The ruin is conquered!", Palette.GOLD_L)

# Scatter a few braziers so the hall reads as lit islands in the dark: each is a
# feet-anchored prop with a flickering warm pool and a slow drip of embers.
func _spawn_braziers() -> void:
	var spots := _pick_spawn_cells(5, 4)
	for cell: Vector2i in spots:
		var pos: Vector2 = _cell_center(cell)
		var root: Node2D = Iso.prop(self, "brazier", pos, 34.0, 2.0)
		# Flame sits high on the prop; put the light and the embers up there.
		var flame: Vector2 = Vector2(0.0, -46.0)
		var l: PointLight2D = Iso.light(root, Palette.TORCH, 225.0, 1.5)
		l.position = flame
		l.z_index = -5
		Iso.flicker(l, 1.45, 0.22, 0.10)
		# A repeating ember drip, driven by a looping timer parked on the brazier.
		var t := get_tree().create_timer(randf_range(0.3, 0.9))
		t.timeout.connect(_brazier_puff.bind(root, flame))

# One ember puff from a brazier, re-arming itself so the flame keeps breathing for
# as long as the brazier is alive.
func _brazier_puff(root: Node2D, flame: Vector2) -> void:
	if not is_instance_valid(root) or not root.is_inside_tree():
		return
	Vfx.embers(root, flame, 4, Palette.TORCH)
	var t := get_tree().create_timer(randf_range(0.7, 1.3))
	t.timeout.connect(_brazier_puff.bind(root, flame))

# ---------------------------------------------------------------------------
# Inner classes (used only by the Dungeon)
# ---------------------------------------------------------------------------

# Floor loot: walk over it to bank one unit of a material.
class Pickup extends Area2D:
	var kind: String = "wood"

	var _sprite: Sprite2D = null
	var _glow: Sprite2D = null
	var _t: float = 0.0

	func _init(k: String) -> void:
		kind = k

	func _ready() -> void:
		# A soft warm halo under the loot so it reads as a beacon in the dark.
		_glow = Sprite2D.new()
		_glow.texture = Assets.tex("glow_ring")
		var gm := CanvasItemMaterial.new()
		gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_glow.material = gm
		_glow.modulate = Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.5)
		var gk: float = 60.0 / 128.0
		_glow.scale = Vector2(gk, gk * Palette.SQUASH)
		_glow.z_index = -1
		add_child(_glow)

		_sprite = Sprite2D.new()
		_sprite.texture = Assets.tex("material_" + kind)
		_sprite.scale = Vector2(Palette.PX, Palette.PX)
		add_child(_sprite)

		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 12.0
		cs.shape = c
		add_child(cs)
		body_entered.connect(_on_body_entered)

	# Bob the loot and pulse its halo so it catches the eye across a dark hall.
	func _process(delta: float) -> void:
		_t += delta
		if _sprite != null:
			_sprite.position.y = sin(_t * 3.0) * 3.0 - 6.0
		if _glow != null:
			_glow.modulate.a = 0.4 + 0.18 * (0.5 + 0.5 * sin(_t * 3.0))

	func _on_body_entered(body: Node) -> void:
		if body.is_in_group("player"):
			# Into the run satchel, not the bank — you only keep this if you make it
			# home alive (QA F-01).
			GameState.satchel_add(kind, 1)
			Sfx.play("pickup", -6.0)
			Main.tip("loot", "Loot goes in your satchel (bottom-left). Bank it at a HOME gate — die in the dark and you lose most of it.")
			Vfx.ring(get_parent(), global_position, 40.0, Palette.GOLD, 0.4)
			Vfx.embers(get_parent(), global_position, 8, Palette.GOLD)
			Vfx.float_text(get_parent(), global_position, "+1 " + kind, Palette.AMBER)
			queue_free()

# A frozen remnant of the people who lived here (CRITIQUE A3): examine it for a one-line
# story fragment, so a chamber reads as a place someone lost rather than a bare arena.
class Relic extends Node2D:
	var fragment: String = ""
	var frag_idx: int = -1
	var dungeon = null            # set at spawn; reaches the Hud to show the fragment
	var _t: float = 0.0
	var _used: bool = false

	func _ready() -> void:
		z_index = 1
		Iso.shadow(self, 30.0, 0.34)
		add_to_group("interactable")

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		# A dark, frost-rimed mound with a pale ice shard and a cold glimmer that pulses,
		# so the player reads it as something worth crossing the room to examine.
		var pulse: float = 0.5 + 0.5 * sin(_t * 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, Palette.SQUASH))
		draw_circle(Vector2.ZERO, 12.0, Palette.SHADOW)
		draw_circle(Vector2(0.0, -1.5), 9.0, Color(0.42, 0.46, 0.52))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if not _used:
			var shard := PackedVector2Array([Vector2(-4.0, -3.0), Vector2(0.0, -21.0), Vector2(4.0, -3.0)])
			draw_colored_polygon(shard, Color(0.62, 0.80, 1.0))
			draw_circle(Vector2(0.0, -18.0), 3.0 + pulse * 1.6,
				Color(Palette.CYAN.r, Palette.CYAN.g, Palette.CYAN.b, 0.35 + 0.3 * pulse))

	func interact_radius() -> float:
		return 34.0

	func can_interact(_by: Node) -> bool:
		return not _used

	func interact_prompt() -> String:
		return Loc.t("Examine  [E]")

	func do_interact(_by: Node) -> void:
		if _used:
			return
		_used = true
		remove_from_group("interactable")
		GameState.mark_ruins_found(frag_idx)
		Sfx.play("ui", -7.0)
		Vfx.embers(get_parent(), global_position + Vector2(0.0, -12.0), 10, Palette.CYAN)
		Vfx.ring(get_parent(), global_position, 34.0, Palette.CYAN, 0.5)
		if dungeon != null and is_instance_valid(dungeon) and dungeon.hud != null \
				and dungeon.hud.has_method("discovery"):
			dungeon.hud.call("discovery", fragment)
		queue_redraw()

# A choice gate raised when the arena is cleared: one per reachable map node (its
# colour/icon previewing the room type) plus a HOME gate, each pulsing so the
# choice is legible from across the room. Walking through commits to that node.
class ExitGate extends Node2D:
	var dungeon: Dungeon = null
	var kind: String = "home"          # "home" ends the run, "node" advances into target_node
	var target_node: int = -1
	var _label: String = "Return home"
	var _hint: String = ""
	var _tint: Color = Palette.CYAN
	var _icon_key: String = "ui_ember_seal"
	var _sprite: Sprite2D = null

	# The colour / icon / words that preview a room type on its gate and the map.
	# `pillar` (rescue only) selects the correct captive icon (QA F-16).
	static func preview(t: String, pillar: String = "") -> Dictionary:
		match t:
			"treasure":
				return {"label": "Treasure", "hint": "a loot hoard", "tint": Palette.GOLD, "icon": "material_iron"}
			"rescue":
				var ic: String = "survivor_" + pillar
				if pillar == "" or not Assets.has(ic):
					ic = "survivor_farmer"
				var who: String = pillar.capitalize() if pillar != "" else "a captive"
				return {"label": "Rescue", "hint": Loc.t("%s waits") % Loc.t(who), "tint": Palette.MOSS_L, "icon": ic}
			"rest":
				return {"label": "Hearth", "hint": "rest & recover", "tint": Palette.AMBER, "icon": "ui_flame"}
			"boss":
				return {"label": "The Warden", "hint": "a brute guards the deep", "tint": Palette.WINE, "icon": "enemy_brute"}
			_:
				return {"label": "Combat", "hint": "husks & loot", "tint": Palette.EMBER, "icon": "enemy_husk"}

	func setup_home(d: Dungeon) -> void:
		dungeon = d
		kind = "home"
		_label = "Return home"
		_hint = "bank & rebuild"
		_tint = Palette.CYAN
		_icon_key = "ui_ember_seal"

	func setup_node(d: Dungeon, nid: int, t: String, pillar: String = "") -> void:
		dungeon = d
		kind = "node"
		target_node = nid
		var pv: Dictionary = preview(t, pillar)
		_label = String(pv["label"])
		_hint = String(pv["hint"])
		_tint = pv["tint"]
		_icon_key = String(pv["icon"])

	func _ready() -> void:
		Iso.shadow(self, 74.0, 0.4)
		_sprite = Sprite2D.new()
		_sprite.texture = Assets.tex("portal")
		_sprite.scale = Vector2(Palette.PX, Palette.PX)
		# Tint the arch toward this gate's colour so home/deeper read apart.
		_sprite.modulate = Palette.WHITE.lerp(_tint, 0.35)
		add_child(_sprite)
		Iso.anchor_feet(_sprite, 6.0)
		# Arcane light welling up out of the archway, in the gate's colour.
		var l: PointLight2D = Iso.light(self, _tint, 175.0, 1.0)
		l.position = Vector2(0.0, -58.0)
		l.z_index = -5
		Iso.flicker(l, 1.0, 0.16, 0.16)
		# The reward preview: an icon hovering over the arch, scaled to a legible ~46px
		# regardless of the source texture's native size.
		var icon := Sprite2D.new()
		icon.texture = Assets.tex(_icon_key)
		var ih: float = maxf(1.0, float(icon.texture.get_height()))
		var isc: float = 46.0 / ih
		icon.scale = Vector2(isc, isc)
		icon.position = Vector2(0.0, -104.0)
		icon.z_index = 6
		add_child(icon)
		var bob := icon.create_tween().set_loops()
		bob.tween_property(icon, "position:y", -110.0, 0.9).set_trans(Tween.TRANS_SINE)
		bob.tween_property(icon, "position:y", -100.0, 0.9).set_trans(Tween.TRANS_SINE)
		add_to_group("interactable")
		_breathe()
		_pulse()

	# A slow idle swell so the arch feels alive rather than painted on.
	func _breathe() -> void:
		if _sprite == null:
			return
		var tw := _sprite.create_tween().set_loops()
		var base: Vector2 = Vector2(Palette.PX, Palette.PX)
		tw.tween_property(_sprite, "scale", base * 1.04, 1.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_sprite, "scale", base, 1.2).set_trans(Tween.TRANS_SINE)

	# A coloured ripple and a lick of motes, re-arming on a timer.
	func _pulse() -> void:
		if not is_inside_tree():
			return
		Vfx.ring(self, Vector2(0.0, -34.0), 92.0, _tint, 0.9)
		Vfx.embers(self, Vector2(0.0, -30.0), 5, _tint)
		get_tree().create_timer(1.7).timeout.connect(_pulse)

	# --- Interaction protocol (see DESIGN.md) ---
	func interact_radius() -> float:
		return 40.0

	func can_interact(by: Node) -> bool:
		return true

	func interact_prompt() -> String:
		return "%s  [E]   ( %s )" % [Loc.t(_label), Loc.t(_hint)]

	func do_interact(by: Node) -> void:
		# A parting flare as the hero steps through.
		Vfx.ring(self, Vector2(0.0, -34.0), 130.0, _tint, 0.5)
		Vfx.embers(self, Vector2(0.0, -30.0), 18, _tint)
		Main.zoom_punch(0.05)
		if dungeon == null:
			return
		if kind == "node":
			dungeon.advance_requested.emit(target_node)
		else:
			dungeon.exited.emit()
