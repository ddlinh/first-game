class_name Main
extends Node
## Scene manager, cinematic camera rig, and owner of the one full-screen grade.
##
## Responsibilities:
##  * holds the single persistent Player and the Hud across layer swaps;
##  * swaps Village <-> Dungeon, reparenting the player so it survives;
##  * runs the central interaction scan (ground distances, see Iso);
##  * drives a Hades-style camera: dead zone, cursor look-ahead, critically
##    damped follow, trauma shake, zoom punch, and clamping to the layer bounds;
##  * owns res://shaders/post.gdshader on a persistent CanvasLayer(1).
##
## LAYER CONTRACT (what Main asks of Village / Dungeon)
##   required  spawn_point() -> Vector2
##             `hud` property, assigned before the layer enters the tree
##   optional  camera_bounds() -> Rect2
##       The world-space rectangle the camera is allowed to SHOW — normally the
##       floor's full extent plus however much platform edge and void you want
##       in frame. Main clamps the camera centre to that rect inset by half the
##       on-screen view, and centres on an axis the rect is too small to fill,
##       so the void never creeps in behind the camera. The call is
##       has_method-guarded: omit it and the camera simply runs unbounded.
##
## GLOBAL HOOKS (static, so any module can reach the rig without a reference)
##   Main.shake(amount)                  0..1 of trauma; shake is trauma squared
##   Main.zoom_punch(amount)             brief push-in, decays on its own
##   Main.set_grade(warm, vignette, bloom)   drive the post-process

# --- Camera tuning (all distances are world px unless noted) ---
# The whole rig runs in _physics_process, locked to the same 60 Hz step the player
# moves on — decoupling them (camera on render, body on physics) is what made the
# hero swim against the world. The look-ahead is deliberately gentle so the frame
# doesn't chase every mouse twitch, which also reads as instability.
const CAM_SMOOTH := 0.09        # tight critically-damped follow — settles fast so the frame halts with the hero
const CAM_DEAD_ZONE := 6.0      # small: the frame tracks closely, no floaty slop
const LOOK_VELOCITY := 0.0      # NO lead — a lead has to unwind on stop and reads as lag
const LOOK_MAX := 52.0          # ground px cap on the total look-ahead
const LOOK_SMOOTH := 0.50       # look-ahead has its own, lazier spring
const ZOOM_MIN := 1.4
const ZOOM_MAX := 3.2
const TRAUMA_DECAY := 2.8       # trauma units per second (snappier settle = less lingering jitter)
const SHAKE_OFFSET := 12.0      # world px at full trauma — a nudge, not a quake
const SHAKE_ROT := 0.0          # NO camera roll: rotating the frame is what reads as stutter
const SHAKE_FREQ := 22.0        # noise samples per second
const PUNCH_PER_TRAUMA := 0.04  # zoom-in fraction added per unit of trauma
const PUNCH_MAX := 0.08
const PUNCH_RELAX := 8.0        # how fast the punch unwinds
const TRAUMA_FRAME_CAP := 0.35  # max trauma any single frame may add — stops an AoE
                                # kill (finisher + N husk deaths at once) from lurching

# --- Grade defaults, applied on a layer swap before the layer's own _ready() ---
const GRADE_GRAIN := 0.42

# Set in _ready so the static hooks below can find the live rig from anywhere.
static var _inst: Main = null
# The capture / autoplay harnesses set this before instancing Main so they boot straight
# into the village instead of stopping at the title menu (CRITIQUE B1).
static var skip_title: bool = false

var _layer: Node2D = null
var _player: Player = null
var _hud: Hud = null
var _camera: Camera2D = null
var _returning: bool = false
var _game_started: bool = false   # false at the title backdrop; true once New/Continue runs

# --- Camera state ---
var _body := Damper.new()        # smoothed camera position
var _look := Damper.new()        # smoothed look-ahead offset
var _anchor: Vector2 = Vector2.ZERO   # dead-zone centre the frame chases
var _trauma: float = 0.0
var _trauma_frame_id: int = -1   # process-frame the cap is tracking
var _trauma_frame: float = 0.0   # trauma requested so far this frame
var _punch: float = 0.0
var _shake_t: float = 0.0
var _base_zoom: float = 2.05
var _noise := FastNoiseLite.new()

# --- Post-process state ---
var _post_rect: ColorRect = null
var _post_mat: ShaderMaterial = null

# Last known hp, so a drop can be turned into shake without touching Player.
var _last_hp: int = 0

# --- Guidance: a world beacon over the current objective + an off-screen arrow ---
var _beacon: Node2D = null
var _beacon_t: float = 0.0

func _ready() -> void:
	randomize()
	_inst = self
	# Run the camera rig LAST in the physics step, so it follows the player's
	# already-updated position this frame instead of lagging one behind.
	process_physics_priority = 100

	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.9

	_hud = Hud.new()
	add_child(_hud)

	_player = Player.new()
	add_child(_player)
	# No z_index override: depth is y-sort now, and anything standing on the
	# floor must stay at z_index 0 so it sorts by its feet (see Iso).
	_player.hp_changed.connect(_on_player_hp)
	_player.died.connect(_on_player_died)
	# A Bloom offers three boons to draft: pause the world and raise the card (QA D-01).
	_player.boon_offer.connect(_on_boon_offer)
	_last_hp = _player.hp

	_camera = Camera2D.new()
	add_child(_camera)
	_camera.zoom = Vector2(_base_zoom, _base_zoom)
	_camera.ignore_rotation = false   # allow roll if ever re-enabled (SHAKE_ROT is 0: roll is off by default — offset-only shake)
	_camera.make_current()

	_setup_post()
	_setup_beacon()
	# The win state (CRITIQUE B4/A1): full warmth raises the Ember's epilogue.
	GameState.game_won.connect(_on_game_won)
	# Boot to the title screen (CRITIQUE B1). New Game / Continue start the world;
	# without a title (older HUD) fall back to dropping straight into the village.
	if _hud.has_method("show_title") and not skip_title:
		_hud.show_title()
	else:
		_game_started = true
		return_to_village()

# The world fully rekindled. Raise the Ember's epilogue over a paused world — the
# rekindling payoff the VISION is built around.
func _on_game_won() -> void:
	Sfx.play("win", 0.0)
	if _hud != null and _hud.has_method("show_victory"):
		var built := 0
		for key in GameState.grid.keys():
			if bool((GameState.grid[key] as Dictionary).get("built", false)):
				built += 1
		_hud.show_victory({
			"runs": GameState.run_count,
			"rescued": GameState.rescued.size(),
			"buildings": built,
		})

# A gold chevron that hovers over whatever the current layer says the objective is.
func _setup_beacon() -> void:
	_beacon = Node2D.new()
	_beacon.z_index = 200
	_beacon.visible = false
	add_child(_beacon)
	var glow := Sprite2D.new()
	glow.texture = Assets.tex("glow_ring")
	var gm := CanvasItemMaterial.new()
	gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = gm
	glow.modulate = Color(Palette.GOLD_L.r, Palette.GOLD_L.g, Palette.GOLD_L.b, 0.5)
	var k: float = 48.0 / 128.0
	glow.scale = Vector2(k, k)
	_beacon.add_child(glow)
	var back := Polygon2D.new()
	back.polygon = PackedVector2Array([Vector2(-12, -16), Vector2(12, -16), Vector2(0, 3)])
	back.color = Palette.BLACK
	_beacon.add_child(back)
	var tri := Polygon2D.new()
	tri.polygon = PackedVector2Array([Vector2(-9, -14), Vector2(9, -14), Vector2(0, 0)])
	tri.color = Palette.GOLD_L
	_beacon.add_child(tri)

func _exit_tree() -> void:
	if _inst == self:
		_inst = null

# ---------------------------------------------------------------------------
# Static hooks — usable as Main.shake(...) from any module, no reference needed
# ---------------------------------------------------------------------------

## Add screen-shake trauma (0..1). Shake scales with trauma *squared*, so small
## taps stay subtle while a real hit slams the frame. Also nudges the zoom punch.
static func shake(amount: float) -> void:
	if _inst != null and is_instance_valid(_inst):
		_inst._add_trauma(amount)

## Brief push-in on the camera, unwinding by itself. `amount` is a zoom fraction.
static func zoom_punch(amount: float) -> void:
	if _inst != null and is_instance_valid(_inst):
		_inst._punch = clampf(_inst._punch + amount, 0.0, PUNCH_MAX)

## Drive the full-screen grade. `warm` 0 = cold ash, 1 = ember radiance.
static func set_grade(warm: float, vignette: float = 1.0, bloom: float = 0.7) -> void:
	if _inst != null and is_instance_valid(_inst):
		_inst._apply_grade(warm, vignette, bloom)

# --- Title / save flow (CRITIQUE B1/B2), driven by the HUD's title & pause menus ---
static func start_new_game() -> void:
	if _inst == null: return
	GameState.reset_all()
	GameState.clear_save()
	_inst._game_started = true
	_inst.return_to_village()

static func continue_game() -> void:
	if _inst == null: return
	GameState.load_game()
	_inst._game_started = true
	_inst.return_to_village()

static func quit_to_title() -> void:
	if _inst == null: return
	GameState.save_game()
	_inst._game_started = false
	if _inst._hud != null and _inst._hud.has_method("show_title"):
		_inst._hud.show_title()

static func save_now() -> void:
	if _inst != null:
		GameState.save_game()

## Fire a one-time contextual tutorial line, from anywhere (survivor, crop, gate…).
static func tip(key: String, text: String) -> void:
	if _inst != null and is_instance_valid(_inst) and _inst._hud != null \
			and _inst._hud.has_method("tip"):
		_inst._hud.tip(key, text)

## Raise a big centred banner (level-ups, attunements) from anywhere.
static func banner(title: String, sub: String = "", color: Color = Palette.GOLD_L) -> void:
	if _inst != null and is_instance_valid(_inst) and _inst._hud != null \
			and _inst._hud.has_method("big_banner"):
		_inst._hud.big_banner(title, sub, color)

func _add_trauma(amount: float) -> void:
	# Cap cumulative trauma per process-frame so many sources firing at once (a
	# finisher landing on a cluster + each husk's death) can't sum into one slam.
	var fr := Engine.get_process_frames()
	if fr != _trauma_frame_id:
		_trauma_frame_id = fr
		_trauma_frame = 0.0
	var add := clampf(amount, 0.0, maxf(0.0, TRAUMA_FRAME_CAP - _trauma_frame))
	_trauma_frame += amount
	_trauma = clampf(_trauma + add, 0.0, 1.0)
	_punch = clampf(_punch + add * PUNCH_PER_TRAUMA, 0.0, PUNCH_MAX)

func _apply_grade(warm: float, vignette: float, bloom: float) -> void:
	if _post_mat == null:
		return
	_post_mat.set_shader_parameter("warm", clampf(warm, 0.0, 1.0))
	_post_mat.set_shader_parameter("vignette", maxf(vignette, 0.0))
	_post_mat.set_shader_parameter("bloom", maxf(bloom, 0.0))

# ---------------------------------------------------------------------------
# Post-process overlay (persists across layer swaps)
# ---------------------------------------------------------------------------

func _setup_post() -> void:
	# Layer 1: above the world (layer 0), below the Hud (layer 10), and outside
	# any layer's CanvasModulate so the grade is never double-darkened.
	var cl := CanvasLayer.new()
	cl.layer = 1
	add_child(cl)

	_post_mat = ShaderMaterial.new()
	_post_mat.shader = load("res://shaders/post.gdshader")
	_post_mat.set_shader_parameter("grain", GRADE_GRAIN)

	_post_rect = ColorRect.new()
	_post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # never eat clicks
	_post_rect.material = _post_mat
	cl.add_child(_post_rect)

	_fit_post()
	get_viewport().size_changed.connect(_fit_post)

func _fit_post() -> void:
	if _post_rect == null:
		return
	var vp := get_viewport()
	if vp == null:
		return
	_post_rect.position = Vector2.ZERO
	_post_rect.size = vp.get_visible_rect().size

# ---------------------------------------------------------------------------
# Layer transitions
# ---------------------------------------------------------------------------
# How deep into the current run we are (1 = first arena). Rooms chain until the
# hero takes a HOME gate or falls.
var _room_in_run: int = 0

func start_dungeon() -> void:
	_room_in_run = 1
	# Fresh satchel + run tally for this descent (QA F-01/F-02).
	GameState.reset_run()
	# Roll a fresh branching map for this run; the entrance is its layer-0 node.
	var rm := RunMap.new()
	rm.generate(5)
	GameState.run_map = rm
	var d := Dungeon.new()
	d.room_index = 1
	d.node_id = rm.current
	d.node_type = rm.type_of(rm.current)
	_install_layer(d, true, true)   # fresh run: reset stats, re-apply buffs
	d.exited.connect(_on_dungeon_exited)
	d.advance_requested.connect(_advance_room)

# Take a gate into a chosen map node: build that room but KEEP the hero's hp and
# loot — the tension of pushing on instead of banking at the home gate.
func _advance_room(node_id: int) -> void:
	if _returning:
		return
	var rm = GameState.run_map
	if rm != null:
		rm.choose(node_id)
	_room_in_run += 1
	var d := Dungeon.new()
	d.room_index = _room_in_run
	d.node_id = node_id
	d.node_type = rm.type_of(node_id) if rm != null else "combat"
	_install_layer(d, true, false)  # same run: carry hp/loot forward
	d.exited.connect(_on_dungeon_exited)
	d.advance_requested.connect(_advance_room)

func return_to_village() -> void:
	_returning = false
	GameState.run_map = null   # the run's map dies with the run
	var v := Village.new()
	_install_layer(v, false)
	v.expedition_requested.connect(start_dungeon)
	# Autosave on settling back in the village (CRITIQUE B2), once a game is actually
	# under way — never from the title backdrop.
	if _game_started:
		GameState.save_game()

func _install_layer(layer: Node2D, is_dungeon: bool, fresh_run: bool = true) -> void:
	# Detach the persistent actors — the hero AND any freed survivors trailing him —
	# from the old layer so freeing it doesn't take them down with it.
	var companions: Array[Node2D] = []
	for c in get_tree().get_nodes_in_group("companion"):
		var cn := c as Node2D
		if cn != null and is_instance_valid(cn):
			companions.append(cn)
	if is_instance_valid(_player) and _player.get_parent() != null:
		_player.get_parent().remove_child(_player)
	for cn in companions:
		if cn.get_parent() != null:
			cn.get_parent().remove_child(cn)
	if is_instance_valid(_layer):
		_layer.queue_free()
	_layer = layer
	layer.hud = _hud
	# A sane grade for the destination, set BEFORE the layer builds itself so a
	# layer that grades in its own _ready() wins.
	if is_dungeon:
		_apply_grade(0.10, 0.88, 0.85)   # softer vignette so the room edges stay readable
		# Count a fresh descent BEFORE the layer builds, so the Dungeon and the HUD
		# depth banner agree. Advancing to a deeper room is the SAME descent.
		if fresh_run:
			GameState.run_count += 1
	else:
		# The sanctuary reads as open-air daylight even when cold (warm floor 0.4),
		# brightening toward golden as the settlement warms. A light vignette only.
		_apply_grade(0.4 + GameState.gwi * 0.6, 0.7, 0.7)
	# Swap the HUD skin BEFORE the layer builds, so the dungeon populates an already
	# combat-mode HUD (foe tally / Warden bar) — village = full economy chrome.
	if _hud.has_method("set_combat"):
		_hud.set_combat(is_dungeon)
	add_child(layer)                    # runs layer._ready(): builds the world
	layer.add_child(_player)            # reparent the persistent player into it
	_player.global_position = layer.spawn_point()
	if is_dungeon:
		if fresh_run:
			_player.begin_run()   # resets run growth + seeds the Soil head-start
			# Rescue buffs are permanent: re-apply one per rescued survivor on top
			# of the fresh baseline so descents keep past bonuses. (Persistent power
			# now flows from Soil in begin_run, not a per-kill Ember Level — §8.0.)
			for pillar in GameState.rescued:
				var b := _buff_for_pillar(pillar)
				if b != "":
					_player.apply_buff(b)
			# The village you rebuilt strengthens the descent (QA D-02).
			_apply_village_boons()
		else:
			# A deeper room carries hp + loot + succession forward, but scrubs
			# transient motion/combat state so it can't leak into the next arena.
			_player.enter_next_room()
		# Warmth reflects the run's succession stage, so a Bloom's "the world warms"
		# cue survives room-to-room advances instead of snapping back to cold.
		_apply_dungeon_grade()
	else:
		_player.enter_village()
	# Carry trailing survivors forward: into a deeper ruin they keep following the
	# hero; back at the village they've made it home, so they settle (the village
	# re-spawns them as working villagers from the roster) and the escort is freed.
	_settle_companions(companions, layer, is_dungeon)
	_last_hp = _player.hp
	_hud.set_hp(_player.hp, _player.max_hp)
	_hud.set_depth(GameState.run_count if is_dungeon else 0)
	_hud.hide_prompt()
	_reset_camera()

# Re-parent trailing survivors into the freshly-built layer, or release them once
# they've reached the village. In a ruin they line up just behind the hero's spawn
# and keep trailing; at home they've delivered themselves — the village already
# re-spawns them as villagers from the roster — so we free the escort node.
func _settle_companions(companions: Array[Node2D], layer: Node2D, is_dungeon: bool) -> void:
	if companions.is_empty():
		return
	if not is_dungeon:
		# Home at last: a small arrival flourish, then hand off to the village roster.
		for cn in companions:
			if is_instance_valid(cn):
				Vfx.embers(layer, cn.global_position if cn.get_parent() != null else _player.global_position, 14, Palette.MOSS_L)
				cn.remove_from_group("companion")
				cn.queue_free()
		return
	var base: Vector2 = layer.spawn_point()
	var i: int = 0
	for cn in companions:
		if not is_instance_valid(cn):
			continue
		layer.add_child(cn)
		# Fan out a step behind the entrance so they don't stack on the hero.
		cn.global_position = base + Iso.offset(Vector2.DOWN, 34.0 + 18.0 * i) \
			+ Iso.offset(Vector2.RIGHT, (12.0 if i % 2 == 0 else -12.0))
		if "follow_target" in cn:
			cn.set("follow_target", _player)   # keep trailing the persistent hero
		i += 1

# Same pillar→buff mapping the Survivor uses, so re-applied bonuses match rescues.
func _buff_for_pillar(pillar: String) -> String:
	return String(GameState.ATTUNEMENTS.get(pillar, {}).get("buff", ""))

# Turn the rebuilt village into descent power (QA D-02): forges → Metallurgy (+dmg),
# cabins → Shelter (+HP), crop beds → Agriculture (Provisions). Announced so the
# player feels the village pay off underground — the run-side of "rebuild → warmth".
func _apply_village_boons() -> void:
	if not is_instance_valid(_player) or not _player.has_method("apply_village"):
		return
	# Count LEVELS, not buildings (VILLAGE_DESIGN P2/V6): an upgraded Forge/Cabin deepens
	# the boon, so construction keeps paying off past the old 3-building ceiling.
	var forges: int = GameState.building_level_sum("forge")
	var cabins: int = GameState.building_level_sum("cabin")
	var crops: int = GameState.building_level_sum("crop_bed")
	var shops: int = GameState.building_level_sum("workshop")
	_player.apply_village(forges, cabins, crops, shops)
	if forges + cabins + crops + shops <= 0 or _hud == null:
		return
	var parts: Array[String] = []
	if forges > 0:
		parts.append(Loc.t("Metallurgy +%d%% dmg") % int(round(0.08 * float(mini(forges, 6)) * 100.0)))
	if cabins > 0:
		parts.append(Loc.t("Shelter +%d HP") % mini(cabins, 6))
	if crops > 0:
		parts.append(Loc.t("%d Provisions") % mini(crops, 3))
	if shops > 0:
		parts.append(Loc.t("Carpentry +%d%% crit") % int(round(0.03 * float(mini(shops, 6)) * 100.0)))
	if _hud.has_method("toast"):
		_hud.toast(Loc.t("The village provides:  ") + "   ·   ".join(parts), Palette.MOSS_L)

func _on_dungeon_exited() -> void:
	if _returning:
		return
	# A live return: the satchel banks into the real stockpile, then a summary card.
	var banked: Dictionary = GameState.bank_satchel()
	var data: Dictionary = _run_summary(true, banked, {})
	return_to_village()
	if _hud != null and _hud.has_method("show_run_summary"):
		_hud.show_run_summary(data)

# Package the current run's tally for the summary card (QA F-02). Reports the run's
# EMBERGROWTH growth (Kindle gathered + Blooms reached) in place of the retired XP.
func _run_summary(alive: bool, kept: Dictionary, lost: Dictionary) -> Dictionary:
	var rs: Dictionary = GameState.run_stats
	return {
		"alive": alive,
		"rooms": int(rs.get("rooms", 0)),
		"husks": int(rs.get("husks", 0)),
		"rescues": (rs.get("rescues", [] as Array) as Array).duplicate(),
		"kept": kept,
		"lost": lost,
		"kindle": int(rs.get("kindle", 0)),
		"blooms": int(rs.get("blooms", 0)),
	}

# The dungeon's base warmth grade, lifted a notch per succession stage so a Bloom's
# "the sanctuary warms" cue persists as the hero pushes deeper (QA D-01 / §6).
func _apply_dungeon_grade() -> void:
	var stage: int = 0
	if is_instance_valid(_player):
		var sv: Variant = _player.get("kindle_stage")
		stage = int(sv) if sv != null else 0
	_apply_grade(0.10 + clampf(float(stage) * 0.05, 0.0, 0.30), 0.88, 0.85)

# ---------------------------------------------------------------------------
# Boon draft (QA D-01): a Bloom pauses the world and offers three boons. Offers
# queue so a multi-stage kill (a big Kindle bounty) resolves one card at a time.
# ---------------------------------------------------------------------------
var _boon_queue: Array = []
var _boon_active: bool = false

func _on_boon_offer(cards: Array) -> void:
	_boon_queue.append(cards)
	if not _boon_active:
		_show_next_boon()

func _show_next_boon() -> void:
	if _boon_queue.is_empty():
		_boon_active = false
		get_tree().paused = false
		return
	_boon_active = true
	get_tree().paused = true
	var cards: Array = _boon_queue.pop_front()
	if _hud != null and _hud.has_method("open_boon_cards"):
		_hud.open_boon_cards(cards, _on_boon_picked)
	else:
		# No HUD path — auto-pick so a paused tree can never soft-lock.
		_on_boon_picked(String(cards[0]["id"]) if not cards.is_empty() else "")

func _on_boon_picked(id: String) -> void:
	if is_instance_valid(_player) and _player.has_method("apply_boon"):
		_player.apply_boon(id)
	_show_next_boon()

# Player hp is the one gameplay event the camera reacts to; routing it here keeps
# the juice out of Player, which does not know a camera exists.
func _on_player_hp(hp: int, max_hp: int) -> void:
	if hp < _last_hp:
		_add_trauma(0.30)
		Vfx.hitstop(self, 0.05)
	_last_hp = hp
	if _hud:
		_hud.set_hp(hp, max_hp)

func _on_player_died() -> void:
	if _returning:
		return
	_returning = true
	_add_trauma(0.95)
	Sfx.play("death", -2.0)
	# Death forfeits most of the satchel (25% salvaged) — the stakes that make a run
	# a gamble (QA F-01). Capture the summary before the village reloads.
	var res: Dictionary = GameState.forfeit_satchel(0.25)
	var data: Dictionary = _run_summary(false, res.get("kept", {}), res.get("lost", {}))
	if _hud:
		_hud.toast("You fell in the dark...", Palette.BLOOD)
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		return_to_village()
		if _hud != null and _hud.has_method("show_run_summary"):
			_hud.show_run_summary(data))

# ---------------------------------------------------------------------------
# The camera rig runs in _physics_process, in lockstep with the player's own
# movement (also physics) — this is the fix for the frame-to-frame stutter. The
# interaction scan is cosmetic and stays on the render frame.
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_update_camera(delta)
	_update_guidance()

# Point the player at what to do next: hover the beacon over the layer's declared
# objective target, or (when it's off-screen) show a HUD arrow toward it.
func _update_guidance() -> void:
	var target: Node2D = null
	if _layer != null and is_instance_valid(_layer) and _layer.has_method("guidance_target"):
		target = _layer.guidance_target()
	if target == null or not is_instance_valid(target):
		if _beacon != null:
			_beacon.visible = false
		if _hud != null and _hud.has_method("set_guide_arrow"):
			_hud.set_guide_arrow(false)
		return
	_beacon_t += 0.06
	var wp: Vector2 = target.global_position + Vector2(0.0, -80.0 + sin(_beacon_t * 4.0) * 4.0)
	_beacon.global_position = wp
	var vp := get_viewport()
	if vp == null:
		return
	var sp: Vector2 = vp.get_canvas_transform() * wp
	var size: Vector2 = vp.get_visible_rect().size
	var m := 64.0
	var on_screen: bool = sp.x > m and sp.x < size.x - m and sp.y > m and sp.y < size.y - m
	_beacon.visible = on_screen
	if _hud == null or not _hud.has_method("set_guide_arrow"):
		return
	if on_screen:
		_hud.set_guide_arrow(false)
	else:
		var center: Vector2 = size * 0.5
		var dir: Vector2 = sp - center
		dir = dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT
		var edge: Vector2 = center + dir * size.length()
		edge.x = clampf(edge.x, m, size.x - m)
		edge.y = clampf(edge.y, m, size.y - m)
		_hud.set_guide_arrow(true, edge, dir.angle())

func _process(_delta: float) -> void:
	_scan_interaction()

# Drop the rig on top of the player with no easing — used on every layer swap so
# the new world does not slide in from the old one's coordinates.
func _reset_camera() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_camera):
		return
	_anchor = _player.global_position
	_look.snap(Vector2.ZERO)
	_body.snap(_clamp_to_bounds(_anchor))
	_trauma = 0.0
	_punch = 0.0
	_camera.global_position = _body.value
	_camera.rotation = 0.0
	_camera.zoom = Vector2(_base_zoom, _base_zoom)

func _update_camera(delta: float) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_camera):
		return

	# 1. Dead zone. The anchor only moves once the hero leaves a small circle
	#    measured on the FLOOR, so idle wobble never sloshes the frame and the
	#    zone stays round instead of egg-shaped under the squash.
	var pos: Vector2 = _player.global_position
	var away: Vector2 = Iso.to_ground(pos - _anchor)
	var dist: float = away.length()
	if dist > CAM_DEAD_ZONE:
		_anchor += Iso.to_screen(away * ((dist - CAM_DEAD_ZONE) / dist))

	# 2. Look-ahead: lead ONLY in the direction the hero is actually running (WASD).
	#    The mouse never moves the frame — the camera is bound to the character, not
	#    the cursor. A stationary hero means a stationary frame.
	var lead: Vector2 = Iso.to_ground(_player.velocity) * LOOK_VELOCITY
	if lead.length() > LOOK_MAX:
		lead = lead.normalized() * LOOK_MAX
	var look: Vector2 = _look.update(Iso.to_screen(lead), LOOK_SMOOTH, delta)

	# 3. Critically damped follow, clamped to the layer both before and after the
	#    spring so smoothing can never overshoot into the void. On an axis the
	#    clamp actually bit, the spring's velocity is dumped — otherwise it winds
	#    up against the wall and flings the frame the moment the wall goes away.
	var target: Vector2 = _clamp_to_bounds(_anchor + look)
	var loose: Vector2 = _body.update(target, CAM_SMOOTH, delta)
	var settled: Vector2 = _clamp_to_bounds(loose)
	if not is_equal_approx(settled.x, loose.x):
		_body.vel.x = 0.0
	if not is_equal_approx(settled.y, loose.y):
		_body.vel.y = 0.0
	_body.value = settled

	# 4. Trauma shake. Offset is noise (not white noise) so it rolls instead of
	#    buzzing, and its Y is squashed like everything else on the ground plane.
	_trauma = maxf(0.0, _trauma - TRAUMA_DECAY * delta)
	var shake_amount: float = _trauma * _trauma
	var offset := Vector2.ZERO
	var roll: float = 0.0
	if shake_amount > 0.0001:
		_shake_t += delta * SHAKE_FREQ
		offset = Vector2(
			_noise.get_noise_2d(_shake_t, 0.0),
			_noise.get_noise_2d(0.0, _shake_t + 137.0) * Palette.SQUASH
		) * SHAKE_OFFSET * shake_amount
		roll = _noise.get_noise_2d(_shake_t + 311.0, 91.0) * SHAKE_ROT * shake_amount

	# 5. Zoom punch unwinds toward the player's chosen zoom.
	_punch = lerpf(_punch, 0.0, clampf(delta * PUNCH_RELAX, 0.0, 1.0))

	_camera.global_position = settled + offset
	_camera.rotation = roll
	var z: float = _base_zoom * (1.0 + _punch)
	_camera.zoom = Vector2(z, z)

# Keep the whole view inside the layer's declared bounds; centre on any axis the
# layer is too small to fill. Uses the base zoom so a punch cannot un-clamp us.
func _clamp_to_bounds(pos: Vector2) -> Vector2:
	if _layer == null or not is_instance_valid(_layer):
		return pos
	if not _layer.has_method("camera_bounds"):
		return pos
	var vp := get_viewport()
	if vp == null:
		return pos
	var rect: Rect2 = _layer.camera_bounds()
	var half: Vector2 = vp.get_visible_rect().size * 0.5 / _base_zoom
	var out: Vector2 = pos
	if rect.size.x <= half.x * 2.0:
		out.x = rect.position.x + rect.size.x * 0.5
	else:
		out.x = clampf(pos.x, rect.position.x + half.x, rect.end.x - half.x)
	if rect.size.y <= half.y * 2.0:
		out.y = rect.position.y + rect.size.y * 0.5
	else:
		out.y = clampf(pos.y, rect.position.y + half.y, rect.end.y - half.y)
	return out

func _scan_interaction() -> void:
	if not is_instance_valid(_player) or _player.get_parent() == null:
		if _hud:
			_hud.hide_prompt()
		return
	var best = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		if not (n is Node2D):
			continue
		if not n.has_method("can_interact") or not n.can_interact(_player):
			continue
		var r: float = 34.0
		if n.has_method("interact_radius"):
			r = float(n.interact_radius())
		# Ground distance, not screen distance — otherwise every interaction
		# range would be an ellipse squashed against the tilted floor.
		var dist: float = Iso.gdist(n.global_position, _player.global_position)
		if dist <= r and dist < best_d:
			best_d = dist
			best = n
	if best != null:
		var prompt := "[E]"
		if best.has_method("interact_prompt"):
			prompt = str(best.interact_prompt())
		if _hud:
			_hud.show_prompt(prompt)
		if Input.is_action_just_pressed("interact") and best.has_method("do_interact"):
			best.do_interact(_player)
	elif _hud:
		_hud.hide_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(0.2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(-0.2)

func _zoom(step: float) -> void:
	_base_zoom = clampf(_base_zoom + step, ZOOM_MIN, ZOOM_MAX)

# ===========================================================================
# Inner class (used only by the camera rig)
# ===========================================================================

# Critically damped spring: reaches the target without ever overshooting, and
# behaves the same at any frame rate — the thing a raw position.lerp() is not.
class Damper:
	var value: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO

	func snap(v: Vector2) -> void:
		value = v
		vel = Vector2.ZERO

	func update(target: Vector2, smooth_time: float, delta: float) -> Vector2:
		var omega: float = 2.0 / maxf(smooth_time, 0.0001)
		var x: float = omega * delta
		# Rational stand-in for exp(-x): cheap, and stable for large delta.
		var decay: float = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
		var change: Vector2 = value - target
		var temp: Vector2 = (vel + change * omega) * delta
		vel = (vel - temp * omega) * decay
		value = target + (change + temp) * decay
		return value
