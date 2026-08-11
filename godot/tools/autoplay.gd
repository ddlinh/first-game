extends Node
## AUTOPLAY — a hands-off bot that plays a bounded scenario (not an endless loop) so
## you can watch the game's arc start to finish: build a cabin → descend → fight husks
## → rescue → choose gates deeper → bank the run home → one last round of village life
## → the game ends. Completes MAX_RUNS full runs, then quits. Not shipped.
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
var _v_phase: String = "build"      # build → chores → expand → descend (→ ending)
var _first_village: bool = true
var _runs_done: int = 0             # completed dungeon runs (village entries after a run)
var _finishing: bool = false        # last village visit — wrap up instead of descending
var _end_t: float = 0.0             # seconds spent on the closing beat before we quit
var _place_tries: int = 0           # cabin-placement attempts this visit (retry guard)
var _poked: Dictionary = {}         # interactables already visited this village trip
var _chore_deadline: float = 0.0
var _esub: int = 0                  # expand sub-step
var _mark: float = 0.0              # scratch timestamp
var _dash_cd: float = 0.0
var _atk_pulse: float = 0.0        # cadence timer for tapping attacks (combo chain)
var _int_pulse: float = 0.0        # cadence timer for tapping interact (hammering a frame)
var _layer_id: int = 0             # current world layer, to detect room changes
var _room_clock: float = 0.0       # when we entered the current room
var _attack_hold: bool = false
var _tap_rel: Dictionary = {}       # action -> seconds left before auto-release
var _last_pos: Vector2 = Vector2.ZERO
var _stuck_t: float = 0.0
var _avoid: Vector2 = Vector2.ZERO
var _avoid_t: float = 0.0

const MOVES := ["move_left", "move_right", "move_up", "move_down"]

# The demo is a bounded scenario, not an endless montage: build the village, then
# complete this many full dungeon runs (descend → fight → rescue → bank home). After
# the last run the bot returns home, does one closing round of village life, and the
# game ends. Bump this for a longer showcase.
const MAX_RUNS := 1

# Playback speed for the whole demo. Everything (movement, combat, timers, camera) is
# delta-driven, so bumping the engine time scale just makes the bot play faster.
# Default 1× = real time (readable); speed it up at launch with `--fast=N` (up to 8).
const SPEED := 1.0

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
	_end_t = 0.0
	_place_tries = 0
	_chore_deadline = _clock + 16.0
	# Each time we come home from a completed run, that's one run banked. Once we hit
	# the target, this becomes the final visit: one last round of chores, then the end.
	if _run_started:
		_runs_done += 1
	_finishing = _runs_done >= MAX_RUNS
	if _finishing:
		_v_phase = "chores"
		_announce("Home for good — %d run(s) banked, tending the village one last time" % _runs_done)
	else:
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
		"ending":
			_phase_ending(delta)
		_:
			_phase_descend(delta)

# Cabin cell — inside the tended clearing (Chebyshev ≤ START_RADIUS) and off-centre
# so it never lands on the hearth.
const BUILD_CELL := Vector2i(2, -1)

func _phase_build(delta: float) -> void:
	match _vsub:
		0:                                          # open the build menu (press B)
			if GameState.can_afford({"wood": 5, "stone": 2}):
				_action_event("build_menu")
				_vsub = 1
				_t = 0.0
				_announce("Village: opening the build menu")
			else:
				_first_village = false
				_v_phase = "chores"
		1:                                          # menu up → choose the Cabin (entry 1)
			var h := _hud()
			if h != null and bool(h.get("_menu_open")):
				_key(KEY_1)
				_vsub = 2
				_t = 0.0
			elif _t > 2.0:
				_finish_build()                     # menu never opened — give up gracefully
		2:                                          # hover the target cell and let the OS
			var lyr := _layer()                     # cursor SETTLE before we click, so
			if bool(lyr.get("_placing")):           # _try_place() reads the right cell
				_aim(lyr.call("cell_to_world", BUILD_CELL))
				if _t > 0.25:
					_vsub = 3
					_t = 0.0
			elif _t > 2.0:
				_finish_build()
		3:                                          # click to drop the frame (mouse settled)
			var lyr2 := _layer()
			if lyr2 == null or not bool(lyr2.get("_placing")):
				# Placement already ended (e.g. a prior click landed) — verify below.
				_vsub = 4
				_t = 0.0
			else:
				_aim(lyr2.call("cell_to_world", BUILD_CELL))
				_action_event("attack")
				_announce("Village: placing a cabin")
				_vsub = 4
				_t = 0.0
		4:                                          # did a frame actually appear? retry if not
			if _find_frame() != null:
				_vsub = 5
				_t = 0.0
				_int_pulse = 0.0
			elif _t > 0.5:
				_place_tries += 1
				if _place_tries < 4:
					_vsub = 2                       # re-hover and click again
					_t = 0.0
				else:
					_finish_build()                 # placement won't take — don't hang the demo
		5:                                          # hammer the frame all the way up (E)
			var sc := _find_frame()
			if sc != null and _t < 20.0:
				if _go_to(sc.global_position, 18.0, delta):
					# Tap on a slow cadence: interact is edge-triggered, so a held button
					# only lands ONE hammer. Releasing between taps lets each swing play
					# out fully and read as a distinct strike (not a blur).
					_int_pulse -= delta
					if _int_pulse <= 0.0:
						_tap("interact")
						_int_pulse = 0.55
			elif sc == null and _place_tries < 4:
				_announce("Village: cabin raised — doing the rounds")
				_vsub = 6                           # linger a beat on the finished cabin
				_t = 0.0
			else:
				if _place_tries >= 4:
					_announce("Village: (couldn't seat the cabin frame) — doing the rounds")
				else:
					_announce("Village: (cabin frame left half-built) — doing the rounds")
				_finish_build()
		6:                                          # admire the raised cabin, then move on
			_stop_move()
			if _t > 1.4:
				_finish_build()

# Leave the build phase for village chores (shared by every build exit path).
func _finish_build() -> void:
	_first_village = false
	_v_phase = "chores"
	_chore_deadline = _clock + 16.0

# Visit villagers (accept/turn in quests), crop plots (plant/harvest) and any
# frames (hammer) — one E-tap each, nearest first, until none left or time's up.
func _phase_chores(delta: float) -> void:
	if _clock > _chore_deadline:
		_after_chores()
		return
	var target := _next_chore()
	if target == null:
		_after_chores()
		return
	if _go_to(target.global_position, 18.0, delta):
		_tap("interact")
		_poked[target.get_instance_id()] = true
		_announce("Village: %s" % String(target.call("interact_prompt")))

# Chores done: on the final visit head to the ending; otherwise expand and descend again.
func _after_chores() -> void:
	_v_phase = "ending" if _finishing else "expand"

func _next_chore() -> Node2D:
	var p := _player()
	var best: Node2D = null
	var bd: float = INF
	var gate := _supply_gate()
	for n in get_tree().get_nodes_in_group("interactable"):
		if not n.has_method("interact_prompt"):
			continue
		if _poked.has(n.get_instance_id()):
			continue
		if n == gate:                              # the gate is the descend phase, not a chore
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
	var gate := _supply_gate()
	if gate == null:
		_drive_toward(_player().global_position + Vector2(0.0, 140.0), delta)
	elif _go_to(gate.global_position, 18.0, delta):
		_rooms = 0                                 # a fresh run starts here
		_tap("interact")
		_announce("Descending into the ruins")

# The closing beat: the hero is home, the run is banked. Drop back to real time for a
# calm final hold, announce the ending, then quit — the scenario is complete, no loop.
func _phase_ending(delta: float) -> void:
	_release_all()
	if _end_t == 0.0:
		Engine.time_scale = 1.0
		_announce("The ember is rekindled. The village endures. — demo complete")
	_end_t += delta
	if _end_t > 4.5:
		_announce("Autoplay finished.")
		get_tree().quit()

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
	var surv := _find_cage()
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
	var surv := _find_cage()
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

# Locale-independent interactable finders. The bot must NOT match on interact_prompt()
# text — that's translated (EN/VI), so an English substring like "Hammer" silently
# misses when the game runs in Vietnamese. These key off stable structure instead.

# An un-built build frame (village.Scaffold — the only interactable with a build_id).
func _find_frame() -> Node2D:
	var p := _player()
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.get("build_id") == null:
			continue
		if n.has_method("can_interact") and not bool(n.call("can_interact", p)):
			continue
		return n as Node2D
	return null

# A still-caged survivor (survivor.gd is the only interactable exposing free_it()).
func _find_cage() -> Node2D:
	var p := _player()
	for n in get_tree().get_nodes_in_group("interactable"):
		if not n.has_method("free_it"):
			continue
		if n.has_method("can_interact") and not bool(n.call("can_interact", p)):
			continue
		return n as Node2D
	return null

# The village's Supply Gate node (the way down), held directly by the Village layer.
func _supply_gate() -> Node2D:
	var l := _layer()
	if l == null:
		return null
	return l.get("_supply_gate") as Node2D

func _announce(s: String) -> void:
	print("[AUTOPLAY] ", s)
	var h := _hud()
	if h != null and h.has_method("toast"):
		h.call("toast", s, Palette.CYAN)
