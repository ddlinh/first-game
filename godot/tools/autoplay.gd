extends Node
## AUTOPLAY — a hands-off bot that plays a full loop so you can watch the game's
## progress: build a cabin → descend → fight husks → rescue → choose gates deeper
## → clear the boss → return home. Not shipped.
##
##   ./play.sh autoplay        (or:  godot --path . res://tools/autoplay.tscn)
##
## It drives the REAL game through simulated input, so what you see is genuine
## gameplay, not a scripted cutscene. Held inputs (move, attack) go through
## Input.action_press (the player polls those); one-shot UI actions (build menu,
## placement click, number keys) are dispatched as real events.

var main: Node
var _t: float = 0.0                 # seconds in the current build sub-step
var _clock: float = 0.0            # never-reset clock for absolute deadlines
var _vsub: int = 0                  # village build sub-step
var _rooms: int = 0                 # gates taken this run (0 = still in the entrance room)
var _run_started: bool = false      # have we descended yet?
# Village visit state (reset on entering the village).
var _was_in_village: bool = false
var _v_phase: String = "build"      # build → chores → expand → descend
var _first_village: bool = true
var _poked: Dictionary = {}         # interactables already visited this village trip
var _chore_deadline: float = 0.0
var _esub: int = 0                  # expand sub-step
var _mark: float = 0.0              # scratch timestamp
var _dash_cd: float = 0.0
var _atk_pulse: float = 0.0        # cadence timer for tapping attacks (combo chain)
var _layer_id: int = 0             # current world layer, to detect room changes
var _room_clock: float = 0.0       # when we entered the current room
var _attack_hold: bool = false
var _tap_rel: Dictionary = {}       # action -> seconds left before auto-release
var _last_pos: Vector2 = Vector2.ZERO
var _stuck_t: float = 0.0
var _avoid: Vector2 = Vector2.ZERO
var _avoid_t: float = 0.0

const MOVES := ["move_left", "move_right", "move_up", "move_down"]

# Fast-forward the whole demo. Everything (movement, combat, timers, camera) is
# delta-driven, so bumping the engine time scale just makes the bot play faster.
# Tweak this (≈2–5) to taste. Overridable at launch with `--fast=N`.
const SPEED := 3.0

func _ready() -> void:
	# Skip the blocking story intros so the bot flows freely; the non-blocking
	# contextual tips still pop, so you still see the teaching.
	GameState.tutorial_seen = true
	GameState.combat_tutorial_seen = true
	Engine.time_scale = _speed_from_args()
	# A Bloom's boon card (QA D-01) pauses the tree; keep the bot ticking through the
	# pause (ALWAYS) while the game world pauses normally (PAUSABLE), so the bot can
	# draft a boon instead of deadlocking on a paused, un-clickable card.
	process_mode = Node.PROCESS_MODE_ALWAYS
	main = Main.new()
	main.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(main)
	_announce("Autoplay started (%.1fx) — building, then descending" % Engine.time_scale)

# Read an optional `--fast=N` command-line override, else use SPEED.
func _speed_from_args() -> float:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fast="):
			return clampf(a.trim_prefix("--fast=").to_float(), 1.0, 8.0)
	return SPEED

# ---------------------------------------------------------------------------
# Frame loop
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	for a in _tap_rel.keys():
		_tap_rel[a] = float(_tap_rel[a]) - delta
		if float(_tap_rel[a]) <= 0.0:
			Input.action_release(a)
			_tap_rel.erase(a)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_clock += delta
	# A Bloom paused the world for a boon draft: take one (index 0) and resume. Must
	# run before anything else, since the rest of the world is frozen behind the card.
	var h0 := _hud()
	if h0 != null and h0.has_method("boon_open") and bool(h0.call("boon_open")):
		h0.call("pick_boon_index", 0)
		_announce("Drafting a Bloom boon")
		return
	var p := _player()
	if p == null:
		return
	_t += delta
	# Track room changes (village↔dungeon and gate advances) for the stuck-safeguard.
	var lyr := _layer()
	if lyr != null and lyr.get_instance_id() != _layer_id:
		_layer_id = lyr.get_instance_id()
		_room_clock = _clock
	var inv := _in_village()
	if inv != _was_in_village:
		_was_in_village = inv
		if inv:
			_on_enter_village()
	if inv:
		_tick_village(delta)
	else:
		_run_started = true
		_tick_dungeon(delta)

# Fresh village trip: pick the opening phase and reset per-visit bookkeeping.
func _on_enter_village() -> void:
	_release_all()
	_poked.clear()
	_esub = 0
	_vsub = 0
	_t = 0.0
	_chore_deadline = _clock + 16.0
	_v_phase = "build" if _first_village else "chores"
	_announce("Home — tending the village")

# ---------------------------------------------------------------------------
# Village loop: (first visit) raise a cabin, then every visit do the chores —
# talk to villagers (accept/turn in quests), plant/harvest, hammer frames — then
# expand the clearing if affordable, and descend for another run.
# ---------------------------------------------------------------------------
func _tick_village(delta: float) -> void:
	match _v_phase:
		"build":
			_phase_build(delta)
		"chores":
			_phase_chores(delta)
		"expand":
			_phase_expand(delta)
		_:
			_phase_descend(delta)

func _phase_build(delta: float) -> void:
	match _vsub:
		0:
			if GameState.can_afford({"wood": 5, "stone": 2}):
				_action_event("build_menu")
				_vsub = 1
				_t = 0.0
				_announce("Village: opening the build menu")
			else:
				_first_village = false
				_v_phase = "chores"
		1:
			var h := _hud()
			if h != null and bool(h.get("_menu_open")):
				_key(KEY_1)                        # pick entry 1 (Cabin)
				_vsub = 2
				_t = 0.0
			elif _t > 2.0:
				_vsub = 3
		2:
			var lyr := _layer()
			if bool(lyr.get("_placing")):
				var cell: Vector2 = lyr.call("cell_to_world", Vector2i(2, -1))
				_aim(cell)
				_action_event("attack")            # left-click places the frame
				_vsub = 3
				_t = 0.0
				_announce("Village: placing a cabin")
			elif _t > 2.0:
				_vsub = 3
		_:
			var sc := _find_prompt("Hammer")
			if sc != null and _t < 16.0:
				if _go_to(sc.global_position, 18.0, delta):
					_tap("interact")
			else:
				_announce("Village: cabin raised — doing the rounds")
				_first_village = false
				_v_phase = "chores"
				_chore_deadline = _clock + 16.0

# Visit villagers (accept/turn in quests), crop plots (plant/harvest) and any
# frames (hammer) — one E-tap each, nearest first, until none left or time's up.
func _phase_chores(delta: float) -> void:
	if _clock > _chore_deadline:
		_v_phase = "expand"
		return
	var target := _next_chore()
	if target == null:
		_v_phase = "expand"
		return
	if _go_to(target.global_position, 18.0, delta):
		_tap("interact")
		_poked[target.get_instance_id()] = true
		_announce("Village: %s" % String(target.call("interact_prompt")))

func _next_chore() -> Node2D:
	var p := _player()
	var best: Node2D = null
	var bd: float = INF
	for n in get_tree().get_nodes_in_group("interactable"):
		if not n.has_method("interact_prompt"):
			continue
		if _poked.has(n.get_instance_id()):
			continue
		var s := String(n.call("interact_prompt"))
		if "Descend" in s:                         # the gate is the descend phase
			continue
		if n.has_method("can_interact") and not bool(n.call("can_interact", p)):
			continue
		var d: float = p.global_position.distance_to((n as Node2D).global_position)
		if d < bd:
			bd = d
			best = n
	return best

# Once per trip, if we can afford it, tend one more ring of the clearing.
func _phase_expand(delta: float) -> void:
	match _esub:
		0:
			if GameState.can_afford({"wood": 10, "stone": 6}):
				_action_event("build_menu")
				_mark = _clock
				_esub = 1
				_announce("Village: expanding the clearing")
			else:
				_v_phase = "descend"
		1:
			var h := _hud()
			if h != null and bool(h.get("_menu_open")):
				_key(KEY_4)                        # entry 4 = Expand Clearing
				_esub = 2
			elif _clock - _mark > 2.0:
				_v_phase = "descend"
		_:
			_v_phase = "descend"

func _phase_descend(delta: float) -> void:
	var gate := _find_prompt("Descend")
	if gate == null:
		_drive_toward(_player().global_position + Vector2(0.0, 140.0), delta)
	elif _go_to(gate.global_position, 18.0, delta):
		_rooms = 0                                 # a fresh run starts here
		_tap("interact")
		_announce("Descending into the ruins")

# ---------------------------------------------------------------------------
# Dungeon: fight until clear, rescue if safe, then take a gate (deeper, then home).
# ---------------------------------------------------------------------------
func _tick_dungeon(delta: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0:
		# Safeguard: this bot has no pathfinding, so if a husk is stuck behind cover
		# and the room won't clear, force it after a while so the demo never hangs.
		if _clock - _room_clock > 45.0:
			for e in enemies:
				if e.has_method("take_damage"):
					e.call("take_damage", 999, Vector2.RIGHT, false)
			_announce("(nudging a stuck room clear)")
			return
		_fight(enemies, delta)
		return
	_hold_attack(false)
	# Room cleared: free any caged survivor before leaving, so they come home and
	# the village-life / quest loop actually has someone to show.
	var surv := _find_prompt("Free")
	if surv != null:
		if _go_to(surv.global_position, 18.0, delta):
			_tap("interact")
			_announce("Freeing a survivor")
		return
	_choose_gate(delta)

func _fight(enemies: Array, delta: float) -> void:
	var p := _player()
	var nearest := _nearest(enemies, p.global_position)
	if nearest == null:
		return
	var edist: float = p.global_position.distance_to(nearest.global_position)
	# Rescue a caged survivor when no husk is breathing down our neck.
	var surv := _find_prompt("Free")
	if surv != null and edist > 95.0:
		_hold_attack(false)
		if _go_to(surv.global_position, 18.0, delta):
			_tap("interact")
			_announce("Freeing a survivor")
		return
	_aim(nearest.global_position)
	if edist > 38.0:
		_hold_attack(false)
		_drive_toward(nearest.global_position, delta)
		# Dash to close a big gap (also dodges).
		if _dash_cd <= 0.0 and edist > 150.0:
			_tap("dash")
			_dash_cd = 1.4
	else:
		_stop_move()
		# Tap on a cadence (not a hold): each fresh press starts/advances a combo
		# step, so the bot rolls through the 3-hit chain into the càn-quét finisher
		# instead of stalling after one combo (a held button no longer auto-loops).
		_hold_attack(false)
		_atk_pulse -= delta
		if _atk_pulse <= 0.0:
			_tap("attack")
			_atk_pulse = 0.28

func _choose_gate(delta: float) -> void:
	var gate := _pick_gate()
	if gate == null:
		_stop_move()
		return
	if _go_to(gate.global_position, 18.0, delta):
		var kind := String(gate.get("kind"))
		_rooms += 1
		_tap("interact")
		if kind == "home":
			_announce("Taking the HOME gate — banking the run")
		else:
			_announce("Taking a gate deeper  (room %d)" % (_rooms + 1))
		_t = 0.0

# Prefer descending deeper; bank home once the run is long or only home remains.
func _pick_gate() -> Node2D:
	var home: Node2D = null
	var node: Node2D = null
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.get("kind") == null:
			continue
		if String(n.get("kind")) == "home":
			home = n as Node2D
		else:
			node = n as Node2D
	# Push a couple rooms deep, then bank home so the demo returns to village life.
	if _rooms >= 2:
		return home if home != null else node
	return node if node != null else home

# ---------------------------------------------------------------------------
# Movement / input helpers
# ---------------------------------------------------------------------------
func _drive_toward(w: Vector2, delta: float) -> void:
	var p := _player()
	if p == null:
		return
	var d: Vector2 = (w - p.global_position)
	if _avoid_t > 0.0:
		d = _avoid
	for a in MOVES:
		Input.action_release(a)
	if d.x > 8.0:
		Input.action_press("move_right")
	elif d.x < -8.0:
		Input.action_press("move_left")
	if d.y > 8.0:
		Input.action_press("move_down")
	elif d.y < -8.0:
		Input.action_press("move_up")
	_update_stuck(delta)

func _go_to(w: Vector2, dist: float, delta: float) -> bool:
	var p := _player()
	if p == null:
		return false
	if p.global_position.distance_to(w) <= dist:
		_stop_move()
		return true
	_drive_toward(w, delta)
	return false

# If we stop making progress toward a target, jink in a random direction briefly
# to slide off whatever wall we're pinned on.
func _update_stuck(delta: float) -> void:
	var p := _player()
	if p == null:
		return
	if _avoid_t > 0.0:
		_avoid_t -= delta
		return
	if p.global_position.distance_to(_last_pos) < 1.5:
		_stuck_t += delta
		if _stuck_t > 0.5:
			_avoid = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * 90.0
			_avoid_t = 0.45
			_stuck_t = 0.0
	else:
		_stuck_t = 0.0
	_last_pos = p.global_position

func _stop_move() -> void:
	for a in MOVES:
		Input.action_release(a)

func _release_all() -> void:
	_stop_move()
	_hold_attack(false)

func _hold_attack(on: bool) -> void:
	if on and not _attack_hold:
		Input.action_press("attack")
		_attack_hold = true
	elif not on and _attack_hold:
		Input.action_release("attack")
		_attack_hold = false

func _tap(action: String) -> void:
	Input.action_press(action)
	_tap_rel[action] = 0.10

# Dispatch a real action event (for UI handled in _unhandled_input: build menu,
# placement click).
func _action_event(name: String) -> void:
	var down := InputEventAction.new()
	down.action = name
	down.pressed = true
	down.strength = 1.0
	Input.parse_input_event(down)
	var up := InputEventAction.new()
	up.action = name
	up.pressed = false
	Input.parse_input_event(up)

# Dispatch a raw key (the build menu reads number keys in _input).
func _key(code: int) -> void:
	var down := InputEventKey.new()
	down.physical_keycode = code
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventKey.new()
	up.physical_keycode = code
	up.pressed = false
	Input.parse_input_event(up)

func _aim(w: Vector2) -> void:
	var vp := get_viewport()
	if vp != null:
		Input.warp_mouse(vp.get_canvas_transform() * w)

# ---------------------------------------------------------------------------
# Scene queries
# ---------------------------------------------------------------------------
func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _layer() -> Node:
	for c in main.get_children():
		if c is Node2D and c.has_method("spawn_point"):
			return c
	return null

func _hud() -> Node:
	for c in main.get_children():
		if c is CanvasLayer and c.has_method("toast"):
			return c
	return null

func _in_village() -> bool:
	var l := _layer()
	return l != null and l.has_method("finish_building")

func _nearest(list: Array, from: Vector2) -> Node2D:
	var best: Node2D = null
	var bd: float = INF
	for n in list:
		var nd := n as Node2D
		if nd == null or not is_instance_valid(nd):
			continue
		var d: float = from.distance_to(nd.global_position)
		if d < bd:
			bd = d
			best = nd
	return best

# Nearest interactable whose prompt contains `sub` and is currently actionable.
func _find_prompt(sub: String) -> Node2D:
	var p := _player()
	for n in get_tree().get_nodes_in_group("interactable"):
		if not n.has_method("interact_prompt"):
			continue
		if n.has_method("can_interact") and not bool(n.call("can_interact", p)):
			continue
		if sub in String(n.call("interact_prompt")):
			return n as Node2D
	return null

func _announce(s: String) -> void:
	print("[AUTOPLAY] ", s)
	var h := _hud()
	if h != null and h.has_method("toast"):
		h.call("toast", s, Palette.CYAN)
