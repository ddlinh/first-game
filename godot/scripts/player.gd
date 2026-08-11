class_name Player
extends CharacterBody2D
## The persistent hero: one instance owned by Main across every dungeon run and
## village visit. Handles WASD movement, a Space dash (with i-frames), a
## right-mouse guard that blocks contact damage, a left-mouse melee swing against
## the "enemy" group, damage/i-frames, per-run stat resets, and rescue buffs.

# Fired whenever hp or max_hp changes so the Hud can redraw the heart bar.
signal hp_changed(hp: int, max_hp: int)
# Fired exactly once when hp reaches 0; Main routes this to a return-home flow.
signal died
# EMBERGROWTH (QA D-01): a kill fed enough Kindle to cross a succession threshold,
# so the hero BLOOMS (stage-up). Carries the new stage for the HUD flourish.
signal bloomed(stage: int)
# A bloom offers three boons to draft; Main pauses and shows the card, then calls
# apply_boon(id). This is the run-scoped BUILD CHOICE the roguelite was missing.
signal boon_offer(cards: Array)

# --- Base stats (immutable baseline; multipliers/bonuses layer on top) ---
var base_speed: float = 220.0        # brisk — the old 150 felt sluggish
var base_max_hp: int = 6
var base_damage: int = 2

# --- Live stats ---
var max_hp: int = 6
var hp: int = 6
var speed_mult: float = 1.0
var damage_mult: float = 1.0
var crit_chance: float = 0.22        # was const CRIT_CHANCE; boons can raise it
var combat_enabled: bool = true
var facing: Vector2 = Vector2.RIGHT

# --- EMBERGROWTH: run-scoped Kindle → succession Blooms (QA D-01, PROGRESSION §4.1)
# Kill a husk → gain Kindle → cross a threshold → BLOOM (succession stage-up): a
# flat stat step AND a pick-1-of-3 boon (the run's build identity). All of this
# RESETS each descent; a warm village (Soil) seeds the starting stage, so power
# tracks the world you rebuilt — replacing the retired persistent Ember Level
# whose per-kill scaling double-stacked with husk depth-scaling (§8.0).
var kindle: float = 0.0
var kindle_stage: int = 0
var boons: Array[String] = []        # boon ids drafted this run (Phase 0: flat sparks)
var _ember_aura: Sprite2D = null     # a warm glow that swells each Bloom ("burn hotter")
# Provisions: the farm's yield carried underground (QA D-02 / Agriculture). Each is a
# heal charge the cat auto-eats the moment it's badly hurt — food finally feeds runs.
var provisions: int = 0

# --- Combo chain: 3 light steps (right crescent, left backhand, càn-quét spin) ---
# Per-step timings (windup / active / recovery seconds) and the p-fraction each
# single hit-scan fires at. Index 3 everywhere = the dash-pounce.
const CB_WIND := [0.05, 0.05, 0.09]
const CB_ACTIVE := [0.08, 0.08, 0.12]
const CB_REC := [0.13, 0.14, 0.20]
const STEP_ACTIVE := [0.35, 0.40, 0.45, 0.30]
const CB_RANGE := [48.0, 50.0, 70.0]     # ground-px reach (Iso.gdist)
const CB_CONE := [0.30, 0.25, -0.70]     # Iso.gdir dot cutoff (finisher ~ full sweep)
const CB_DMG := [1.0, 1.15, 1.7]         # damage multipliers
const CB_LUNGE := [13.0, 15.0, 8.0]      # body lunge px (finisher spins, so small)
const CB_COIL := [5.0, 6.0, 8.0]         # anticipation pull-back px
const CB_KNOCK := [6.0, 7.0, 14.0]       # knockback px
const CB_SHOVE := [90.0, 100.0, 0.0]     # px/s step-in impulse
const SHOVE_DECAY := 0.08
const STRETCH_X := [0.18, 0.22, 0.22]
const STRETCH_Y := 0.13
const STRIKE_SKEW := 0.18
const RESIDUAL_LEAN := 0.30
const COMBO_BUFFER := 0.16              # window to queue the next step
const COMBO_RESET := 0.35               # idle before the chain snaps back to step 1
const FINISHER_RECOVER := 0.16          # locked endlag after the sweep (dodge-cancelable)
const FINISHER_SHAKE := 0.12

const CRIT_MULT: int = 2

# --- EMBERGROWTH tuning (the ONE place run growth is defined, §8.0) ---
# Cumulative Kindle needed to REACH each succession stage, and the flat stat step
# every Bloom grants on top of a drafted boon. A ~5-husk room yields ~2 blooms
# early, so the hero visibly gets stronger as the run goes deeper (the felt "I get
# weaker the deeper I push" bug is gone).
const KINDLE_THRESHOLDS := [0, 8, 20, 40, 70]
const STAGE_NAMES := ["ASH", "PIONEER", "HERB", "THICKET", "CANOPY"]
const BLOOM_DMG := 0.12              # damage_mult added per Bloom
const BLOOM_SPD := 0.04              # speed_mult added per Bloom

# Draftable boons (Phase 0: flat "sparks" — the choice matters even before Modes /
# Kingdoms land). Three are rolled per Bloom; picking applies immediately.
const BOON_POOL := [
	{"id": "ember_fang",   "name": "Ember Fang",    "desc": "+20% damage"},
	{"id": "fleetfoot",    "name": "Fleetfoot",     "desc": "+12% move speed"},
	{"id": "bramble_heart","name": "Bramble Heart", "desc": "+2 Max HP, mend 2"},
	{"id": "keen_eye",     "name": "Keen Eye",      "desc": "+7% crit chance"},
	{"id": "second_wind",  "name": "Second Wind",   "desc": "Mend 3 HP now"},
	{"id": "hearths_gift", "name": "Hearth's Gift",  "desc": "+1 Max HP, +8% dmg"},
]

# --- Dash (dodge) + pounce ---
const DASH_SPEED: float = 440.0
const DASH_TIME: float = 0.16
const DASH_CD: float = 0.55
const DASH_IFRAMES: float = 0.26        # covers the burst + a hair of landing grace
const DASH_ATTACK_WINDOW: float = 0.18  # after a dash, a press triggers the pounce
const DASHATK_MULT: float = 1.5
const DASHATK_RANGE: float = 58.0
const DASHATK_CONE: float = 0.15        # tight forward stab
const DASHATK_LUNGE: float = 20.0
const DASHATK_KNOCK: float = 10.0

# --- Guard / parry ---
const GUARD_SPEED_MULT: float = 0.42
# Guard costs stamina so holding block forever is no longer free (QA F-04): it
# drains while raised and per blocked hit; empty → a GUARD BREAK that locks guard
# out briefly. A perfect parry refunds stamina, rewarding timing over turtling.
const GUARD_MAX: float = 1.0
const GUARD_DRAIN: float = 0.42        # stamina/sec while holding guard
const GUARD_REGEN: float = 0.5         # stamina/sec while not guarding
const GUARD_BLOCK_COST: float = 0.28   # stamina per blocked blow
const GUARD_BREAK_LOCK: float = 1.1    # seconds guard is unavailable after a break
const PARRY_REFUND: float = 0.35       # stamina returned by a perfect parry
const PARRY_WINDOW: float = 0.18        # raise-to-hit window for a PERFECT parry
const PARRY_IFRAMES: float = 0.30
const BLOCK_IFRAMES: float = 0.22
const PARRY_HITSTOP: float = 0.08       # the hardest freeze in the game
const PARRY_SHAKE: float = 0.10
const RIPOSTE_RANGE: float = 70.0       # radial counter reach
const PARRY_STAGGER: float = 0.7        # enemy stun on a parry
const PARRY_KNOCK: float = 14.0
const COUNTER_WINDOW: float = 0.6       # empowered-riposte window after a parry
const COUNTER_MULT: float = 2.0

# --- Locomotion feel ---
const MOVE_ACCEL: float = 2600.0        # px/s^2 ramp-up (anticipation in the step itself)
const MOVE_FRICTION: float = 3200.0     # px/s^2 coast-to-stop (follow-through + dash glide)

# Combat states.
const S_LOCO := 0
const S_ATTACK := 1
const S_DASHATK := 2

# Collision layers. The environment (walls, buildings, survivor) stays on the
# default layer 1; husks get their own layer so a dash can drop THEM from the
# player's mask — phasing through enemies while walls still stop you cold.
const LAYER_ENV: int = 1
const LAYER_ENEMY: int = 4           # bit for physics layer 3
const MASK_NORMAL: int = LAYER_ENV | LAYER_ENEMY   # collide with everything
const MASK_DASH: int = LAYER_ENV                   # collide with structures only

# --- Internal state ---
var _invuln: float = 0.0             # i-frame time remaining
var _dead: bool = false              # latch so `died` fires only once
var _sprite: Sprite2D = null
var _base_scale: Vector2 = Vector2.ONE  # body scale the walk cycle squashes around
var _anim_t: float = 0.0             # walk/idle cycle phase
var _face_left: bool = false         # turnaround: which way the hero reads
var _look_dir: Vector2 = Vector2.DOWN  # direction the sprite should present
var _tex_front: Texture2D = null
var _tex_back: Texture2D = null
var _move_dir: Vector2 = Vector2.RIGHT  # last non-zero move dir (dash while idle)

# Work swing — a visible hammer/labour motion played when the hero works a build
# frame (see play_work), so building reads as an action, not a stand-still.
const WORK_TIME := 0.34
var _work_t: float = 0.0
var _work_dir: Vector2 = Vector2.RIGHT

# Dash / dodge
var _dash_t: float = 0.0            # remaining dash burst
var _dash_cd: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _dash_atk_t: float = 0.0       # pounce window after a dash

# Guard / parry
var _guarding: bool = false
var _guard_was: bool = false       # guard held last frame (for the rising edge)
var _guard_hold: float = 0.0       # seconds guard has been held since raised
var guard_stamina: float = 1.0     # 0..1; drains while guarding, regens when not
var _guard_broken_t: float = 0.0   # guard locked out while > 0 (after a break)
var _guard_fx: Sprite2D = null
var _counter_t: float = 0.0        # empowered-riposte window after a parry

# Attack state machine
var _state: int = S_LOCO
var _atk_kind: int = 0             # 0/1/2 combo step, 3 = pounce
var _atk_t: float = 0.0            # remaining time of the current step
var _atk_dir: Vector2 = Vector2.RIGHT
var _did_hit: bool = false         # this step's single scan already fired
var _did_end: bool = false         # this step's recovery-start decision made
var _combo_next: int = 0           # step the next press plays (0..2)
var _buffer_t: float = 0.0         # buffered attack press
var _reset_t: float = 0.0          # idle since the last step
var _recover_t: float = 0.0        # finisher endlag lock
var _skew_start: float = 0.0       # skew carried into a step's windup (flow)
var _shove_v: Vector2 = Vector2.ZERO  # decaying step-in / pounce impulse
var _shove_t: float = 0.0
var _shove_dur: float = 0.08

func _ready() -> void:
	add_to_group("player")
	# Contact shadow first, so the body sits down into it (an unflipped clean
	# ellipse under the feet — the baked-in smear alone reads as a floating sticker).
	Iso.shadow(self, 46.0 * Palette.ACTOR_SCALE, 0.42)
	# Body sprite: feet anchored to the node origin and knocked down to Hades scale.
	_sprite = Sprite2D.new()
	_tex_front = Assets.tex("player")
	_tex_back = Assets.tex("player_back") if Assets.has("player_back") else _tex_front
	_sprite.texture = _tex_front
	add_child(_sprite)
	_base_scale = Iso.mount_body(_sprite, 5.0)
	# Physics body: a small circle at the feet so movement collides with walls/enemies.
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	col.shape = shape
	add_child(col)
	# Solid to structures and husks by default; a dash swaps to MASK_DASH.
	collision_layer = LAYER_ENV
	collision_mask = MASK_NORMAL
	# Guard bubble: a warm ring around the torso, hidden until the guard is raised.
	_guard_fx = Sprite2D.new()
	_guard_fx.texture = Assets.tex("glow_ring")
	var gm := CanvasItemMaterial.new()
	gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_guard_fx.material = gm
	_guard_fx.modulate = Palette.GOLD_L
	_guard_fx.position = Vector2(0.0, -32.0)
	_guard_fx.scale = Vector2(0.52, 0.46)
	_guard_fx.z_index = 5
	_guard_fx.visible = false
	add_child(_guard_fx)
	# Succession aura: a warm additive glow behind the body that swells one notch on
	# every Bloom, so "you burn hotter as you climb the run" reads on the hero itself
	# (PROGRESSION §6). Hidden until the first Bloom or a soil head-start.
	_ember_aura = Sprite2D.new()
	_ember_aura.texture = Assets.tex("glow_ring")
	var am := CanvasItemMaterial.new()
	am.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_ember_aura.material = am
	_ember_aura.modulate = Color(Palette.EMBER.r, Palette.EMBER.g, Palette.EMBER.b, 0.0)
	_ember_aura.position = Vector2(0.0, -26.0)
	_ember_aura.scale = Vector2(0.5, 0.5 * Palette.SQUASH)
	_ember_aura.z_index = -2
	_ember_aura.visible = false
	add_child(_ember_aura)
	# Sync live stats to baseline on spawn.
	max_hp = base_max_hp
	hp = max_hp
	hp_changed.emit(hp, max_hp)

func _physics_process(delta: float) -> void:
	# Dead: the corpse stays put (the camera still follows global_position) — no
	# steering, no dash, no residual velocity (QA F-06).
	if _dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# A dash overrides steering: fly straight along the locked-in direction, shedding
	# a trail. On the last frame we DON'T zero velocity — friction below glides the
	# hero out of the roll — and we open the pounce window.
	if _dash_t > 0.0:
		_dash_t -= delta
		if _dash_t <= 0.0:
			collision_mask = MASK_NORMAL
			_dash_atk_t = DASH_ATTACK_WINDOW
		# Ground-uniform dash so the roll covers the same distance in every direction.
		velocity = Iso.vel(_dash_dir, DASH_SPEED)
		move_and_slide()
		_spawn_afterimage()
		return
	# Target velocity from input, unless an attack/recovery roots us in place.
	var rooted: bool = _state == S_ATTACK or _state == S_DASHATK or _recover_t > 0.0
	var target: Vector2 = Vector2.ZERO
	if not rooted:
		var dir: Vector2 = _input_dir()
		if dir.length() > 0.01:
			_move_dir = dir.normalized()
			facing = _move_dir
		var spd: float = base_speed * speed_mult
		if _guarding:
			spd *= GUARD_SPEED_MULT
		# Ground-uniform velocity (Iso.vel squashes the Y leg) so N/S covers the same
		# GROUND distance as E/W instead of 1.6x more — the 2.5D contract (QA F-11).
		target = Iso.vel(dir, spd)
	# Ramp toward the target (accel in, friction out) — starts anticipate, stops coast,
	# and a dash bleeds smoothly into the input. Then add any decaying step-in impulse.
	var a: float = (MOVE_ACCEL if target.length() > 1.0 else MOVE_FRICTION) * delta
	velocity = velocity.move_toward(target, a)
	if _shove_t > 0.0:
		_shove_t -= delta
		velocity += _shove_v * clampf(_shove_t / _shove_dur, 0.0, 1.0)
	move_and_slide()

# Raw movement vector from the four move actions. Diagonals keep full speed (the
# vector is only clamped, so pressing two keys never exceeds unit length).
func _input_dir() -> Vector2:
	var d := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up"))
	return d.limit_length(1.0)

func _process(delta: float) -> void:
	# Dead: freeze input and pose; the collapse tween in _die() plays it out.
	if _dead:
		return
	_tick_timers(delta)
	if combat_enabled:
		_combat_input(delta)
	elif Input.is_action_just_pressed("dash") and _dash_cd <= 0.0 and _dash_t <= 0.0:
		_start_dash()   # village: dodge doubles as traversal
	_present(delta)

func _tick_timers(delta: float) -> void:
	if _invuln > 0.0: _invuln -= delta
	if _dash_cd > 0.0: _dash_cd -= delta
	if _dash_atk_t > 0.0: _dash_atk_t -= delta
	if _buffer_t > 0.0: _buffer_t -= delta
	if _counter_t > 0.0: _counter_t -= delta
	if _recover_t > 0.0: _recover_t -= delta
	if _work_t > 0.0: _work_t -= delta
	if _guard_broken_t > 0.0: _guard_broken_t -= delta
	if _reset_t > 0.0:
		_reset_t -= delta
		if _reset_t <= 0.0:
			_combo_next = 0

# Input priority: dash (escape) > pounce > advance current attack > recovery lock >
# guard (modifier) > start an attack.
func _combat_input(delta: float) -> void:
	if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0 and _dash_t <= 0.0:
		_start_dash()
		return
	if _dash_t > 0.0:
		if Input.is_action_just_pressed("attack"):
			_start_attack(3)   # pounce out of the dodge
		return
	if _dash_atk_t > 0.0 and Input.is_action_just_pressed("attack"):
		_start_attack(3)
		return
	if _state == S_ATTACK or _state == S_DASHATK:
		if Input.is_action_just_pressed("attack"):
			_buffer_t = COMBO_BUFFER
		_advance_attack(delta)
		return
	if _recover_t > 0.0:
		_guarding = false
		_guard_was = false
		return
	# Guard is a modifier on locomotion; track the rising edge for the parry window.
	# It can only be raised when not broken and there's stamina left (QA F-04).
	var wants_guard: bool = Input.is_action_pressed("defend")
	var guard_now: bool = wants_guard and _guard_broken_t <= 0.0 and guard_stamina > 0.02
	if guard_now and not _guard_was:
		_guard_hold = 0.0
	elif guard_now:
		_guard_hold += delta
	_guarding = guard_now
	_guard_was = guard_now
	# Drain while up, regen while down (never mid-break).
	if _guarding:
		guard_stamina = maxf(0.0, guard_stamina - GUARD_DRAIN * delta)
		if guard_stamina <= 0.0:
			_break_guard()
	elif _guard_broken_t <= 0.0:
		guard_stamina = minf(GUARD_MAX, guard_stamina + GUARD_REGEN * delta)
	# Start a chain on a FRESH press or a buffered tap — never on a mere hold, so a
	# held button can't perpetually re-loop the finisher (its recovery ends, and it
	# would restart step 0 every cycle). Intra-combo hold-chaining lives in
	# _advance_attack; the buffer here catches a tap made during a step's recovery.
	if not _guarding and (Input.is_action_just_pressed("attack") or _buffer_t > 0.0):
		_buffer_t = 0.0
		_start_attack(_combo_next)

# Begin one attack step (0..2 combo, 3 = pounce): lock aim, timings, momentum.
func _start_attack(kind: int) -> void:
	_atk_kind = kind
	_state = S_DASHATK if kind == 3 else S_ATTACK
	_atk_t = _step_total(kind)
	_did_hit = false
	_did_end = false
	_buffer_t = 0.0
	_recover_t = 0.0
	_dash_atk_t = 0.0
	_skew_start = _sprite.skew
	if kind == 3:
		_atk_dir = _dash_dir
		_dash_t = 0.0
		collision_mask = MASK_NORMAL
		_shove_v = _atk_dir * 130.0
		_shove_dur = 0.10
	else:
		var m: Vector2 = get_global_mouse_position() - global_position
		_atk_dir = m.normalized() if m.length() > 2.0 else facing
		_shove_v = _atk_dir * float(CB_SHOVE[kind])
		_shove_dur = SHOVE_DECAY
	_shove_t = _shove_dur
	facing = _atk_dir
	if absf(_atk_dir.x) > 0.05:
		_face_left = _atk_dir.x < 0.0

# Tick the active step: fire its single hit-scan, decide chaining at recovery-start,
# and finish out.
func _advance_attack(delta: float) -> void:
	_atk_t -= delta
	var k: int = _atk_kind
	var total: float = _step_total(k)
	var p: float = clampf(1.0 - _atk_t / total, 0.0, 1.0)
	if not _did_hit and p >= float(STEP_ACTIVE[k]):
		_did_hit = true
		_do_attack_hit(k)
	var aw: float = _step_wind(k) / total
	var as_: float = _step_active(k) / total
	if not _did_end and p >= aw + as_:
		_did_end = true
		var chain: bool = _buffer_t > 0.0 or Input.is_action_pressed("attack")
		if chain and k < 2:
			_start_attack(k + 1)          # cancel recovery, flow straight into next
			return
		if chain and k == 3:
			_start_attack(1)              # pounce → backhand
			return
		_combo_next = 0 if k == 2 else (1 if k == 3 else k + 1)
	if _atk_t <= 0.0:
		_end_attack(k)

func _end_attack(k: int) -> void:
	_state = S_LOCO
	if k == 2:
		_recover_t = FINISHER_RECOVER     # locked endlag (a dodge can cancel it)
		_combo_next = 0
	_reset_t = COMBO_RESET

# Resolve one step's hit: aim cone (ground-space), damage, knockback, VFX, and the
# reserved camera punch for crits / the finisher / the pounce.
func _do_attack_hit(k: int) -> void:
	var dir: Vector2 = _atk_dir
	var counter: bool = _counter_t > 0.0        # empowered riposte after a parry
	var crit: bool = counter or (randf() < crit_chance)
	if counter:
		_counter_t = 0.0
	var mult: float = DASHATK_MULT if k == 3 else float(CB_DMG[k])
	var dmg: int = int(round(base_damage * damage_mult * mult))
	if crit:
		dmg *= CRIT_MULT
	var big: bool = counter or k == 3
	match k:
		0: Vfx.slash_dir(get_parent(), global_position + dir * 26.0, dir, big, false)
		1: Vfx.slash_dir(get_parent(), global_position + dir * 27.0, dir, big, true)
		2: Vfx.spin_slash(get_parent(), global_position, true)
		3: Vfx.slash(get_parent(), global_position + dir * 30.0, dir, true)
	if counter and k != 2:
		Vfx.ring(get_parent(), global_position, 60.0, Palette.CYAN, 0.3)
	# Scan in GROUND space (Iso.gdist/gdir) so north/south reach isn't egg-shaped.
	var aim_g: Vector2 = Iso.gdir(global_position, global_position + dir)
	var rng: float = DASHATK_RANGE if k == 3 else float(CB_RANGE[k])
	var cone: float = DASHATK_CONE if k == 3 else float(CB_CONE[k])
	var knock: float = DASHATK_KNOCK if k == 3 else float(CB_KNOCK[k])
	var hits: int = 0
	var hit_pos: Vector2 = global_position
	for e in get_tree().get_nodes_in_group("enemy"):
		var en := e as Node2D
		if en == null:
			continue
		if Iso.gdist(global_position, en.global_position) > rng:
			continue
		var to_g: Vector2 = Iso.gdir(global_position, en.global_position)
		if to_g.dot(aim_g) <= cone:
			continue
		var from_dir: Vector2 = to_g if k == 2 else dir   # finisher knocks radially
		if en.has_method("take_damage"):
			en.call("take_damage", dmg, from_dir, crit)
		if k == 2 and en.has_method("shove"):
			en.call("shove", from_dir, knock)
		hits += 1
		hit_pos = en.global_position
	if hits <= 0:
		return
	var up: Vector2 = Vector2(0.0, -34.0 * Palette.ACTOR_SCALE)
	if k == 2:
		Vfx.ring(get_parent(), global_position, 92.0, Palette.GOLD_L, 0.40)
		Vfx.crunch(get_parent(), hit_pos + up, dir)
		Vfx.embers(get_parent(), global_position, 10, Palette.EMBER)
		Vfx.float_text(get_parent(), global_position + up, "CÀN QUÉT!", Palette.GOLD_L)
		Vfx.hitstop(self, 0.05)
		Main.shake(FINISHER_SHAKE)
		Main.zoom_punch(0.03)
	elif crit:
		Vfx.ring(get_parent(), hit_pos, 78.0, Palette.CYAN if counter else Palette.GOLD_L, 0.34)
		Vfx.crunch(get_parent(), hit_pos + up, dir)
		Vfx.float_text(get_parent(), hit_pos + up, "RIPOSTE!" if counter else "CRIT!", Palette.GOLD_L)
		Vfx.hitstop(self, 0.045 if k == 3 else 0.05)
		Main.shake(0.10 if k == 3 else 0.14)
		Main.zoom_punch(0.03)

# --- Per-step timing helpers ---
func _step_wind(k: int) -> float:
	return float(CB_WIND[k]) if k < 3 else 0.04
func _step_active(k: int) -> float:
	return float(CB_ACTIVE[k]) if k < 3 else 0.06
func _step_rec(k: int) -> float:
	return float(CB_REC[k]) if k < 3 else 0.10
func _step_total(k: int) -> float:
	return _step_wind(k) + _step_active(k) + _step_rec(k)

# ---------------------------------------------------------------------------
# Visual presentation — one place, mutually exclusive pose paths.
# ---------------------------------------------------------------------------
func _present(delta: float) -> void:
	_update_guard_fx(delta)   # fades the shield bubble in/out from _guarding, any state
	var moving: bool = velocity.length() > 6.0
	if _dash_t > 0.0:
		_look_dir = _dash_dir
	elif _state == S_ATTACK or _state == S_DASHATK:
		_look_dir = _atk_dir
	elif moving:
		_look_dir = velocity.normalized()
	var want_back: bool = _look_dir.y < -0.42
	var tex: Texture2D = _tex_back if want_back else _tex_front
	if _sprite.texture != tex:
		_sprite.texture = tex
	if _state == S_LOCO and _dash_t <= 0.0 and absf(_look_dir.x) > 0.08:
		_face_left = _look_dir.x < 0.0

	if _state == S_ATTACK or _state == S_DASHATK:
		_attack_pose()
	elif _dash_t > 0.0:
		_dash_pose()
	elif _recover_t > 0.0:
		# Ease the strike pose back to neutral through the endlag.
		_sprite.position = _sprite.position.lerp(Vector2.ZERO, 0.35)
		_sprite.skew = lerpf(_sprite.skew, 0.0, 0.35)
		_sprite.scale = _sprite.scale.lerp(_base_scale, 0.35)
	elif _work_t > 0.0 and not moving:
		_work_pose()
	else:
		_anim_t += delta * (1.0 if moving else 0.7)
		Iso.walk_anim(_sprite, _base_scale, _anim_t, moving, _face_left)

# Analytic three-phase strike pose (anticipation → strike → recovery), computed off
# the step countdown so it survives hitstop and fast-forward exactly.
func _attack_pose() -> void:
	var k: int = _atk_kind
	if k == 2:
		_finisher_pose()
		return
	var total: float = _step_total(k)
	var p: float = clampf(1.0 - _atk_t / total, 0.0, 1.0)
	var aw: float = _step_wind(k) / total
	var as_: float = _step_active(k) / total
	var lunge: float = DASHATK_LUNGE if k == 3 else float(CB_LUNGE[k])
	var coil: float = 6.0 if k == 3 else float(CB_COIL[k])
	var stretch_x: float = 0.24 if k == 3 else float(STRETCH_X[k])
	var stretch_y: float = 0.14 if k == 3 else STRETCH_Y
	var skew_sign: float = signf(_atk_dir.x)
	if k == 1:
		skew_sign = -skew_sign                # the backhand whips the other way
	var amt: float = 0.0
	var sx: float = 1.0
	var sy: float = 1.0
	var skew: float = 0.0
	if p < aw:                                # anticipation: coil back + gather
		var w: float = _e_out(p / maxf(aw, 0.001))
		amt = -coil * w
		sx = 1.0 - 0.06 * w
		sy = 1.0 + 0.08 * w
		skew = -STRIKE_SKEW * skew_sign * w + _skew_start * RESIDUAL_LEAN * (1.0 - w)
	elif p < aw + as_:                        # strike: lunge + stretch + whip
		var sf: float = (p - aw) / maxf(as_, 0.001)
		amt = lerpf(-coil, lunge, _back_out(sf))
		var r: float = sin(sf * PI)
		sx = 1.0 + stretch_x * r
		sy = 1.0 - stretch_y * r
		skew = STRIKE_SKEW * skew_sign * _e_out(sf)
	else:                                     # recovery: settle back with a small dip
		var pr: float = (p - aw - as_) / maxf(1.0 - aw - as_, 0.001)
		amt = lunge * (1.0 - _e_io(pr))
		var dip: float = sin(pr * PI)
		sx = 1.0 - 0.03 * dip
		sy = 1.0 + 0.02 * dip
		skew = STRIKE_SKEW * skew_sign * (1.0 - _e_io(pr))
	_sprite.position = Iso.offset(_atk_dir, amt)
	_sprite.scale = Vector2(_base_scale.x * sx, _base_scale.y * sy)
	_sprite.skew = skew
	_sprite.flip_h = _face_left

# The càn-quét whirl: a hop, a pinch-and-pop, a deep skew loading the spin, and a
# double flip so it reads as one clean rotation.
func _finisher_pose() -> void:
	var total: float = _step_total(2)
	var p: float = clampf(1.0 - _atk_t / total, 0.0, 1.0)
	var pinch: float = sin(p * PI)
	_sprite.position = Iso.offset(_atk_dir, 8.0 * pinch) + Vector2(0.0, -6.0 * pinch)
	_sprite.scale = Vector2(_base_scale.x * (1.0 + 0.22 * pinch), _base_scale.y * (1.0 - 0.10 * pinch))
	_sprite.skew = 0.24 * sin(p * TAU)
	_sprite.flip_h = cos(p * TAU) < 0.0

# Trigger a single hammer/labour swing toward `toward` (a ground direction). Called
# by build frames (and any future "work" interactable) when the hero works them, so
# the action is legible — the hero visibly winds up and chops, not stands frozen.
func play_work(toward: Vector2) -> void:
	_work_t = WORK_TIME
	if toward.length() > 0.01:
		_work_dir = toward.normalized()
		if absf(toward.x) > 2.0:
			_face_left = toward.x < 0.0

# The swing itself: rise + lean back on the wind-up, then chop down-and-forward
# toward the frame — a clear overhead hammer beat.
func _work_pose() -> void:
	var p: float = clampf(1.0 - _work_t / WORK_TIME, 0.0, 1.0)
	var reach: float
	var lift: float
	var sx: float = 1.0
	var sy: float = 1.0
	if p < 0.34:                              # wind up: lift the hammer, lean back
		var w: float = _e_out(p / 0.34)
		reach = -4.0 * w
		lift = -7.0 * w
		sy = 1.0 + 0.07 * w
	else:                                     # chop: swing forward and drive down
		var s: float = (p - 0.34) / 0.66
		var r: float = sin(s * PI)
		reach = lerpf(-4.0, 8.0, _back_out(s))
		lift = -7.0 + 9.0 * _e_out(s)
		sx = 1.0 + 0.10 * r
		sy = 1.0 - 0.09 * r
	_sprite.position = Iso.offset(_work_dir, reach) + Vector2(0.0, lift)
	_sprite.scale = Vector2(_base_scale.x * sx, _base_scale.y * sy)
	_sprite.skew = 0.0
	if absf(_work_dir.x) > 0.05:
		_sprite.flip_h = _work_dir.x < 0.0
	else:
		_sprite.flip_h = _face_left

# A stretched roll pose during the dodge.
func _dash_pose() -> void:
	_sprite.position = Vector2.ZERO
	_sprite.skew = 0.12 * signf(_dash_dir.x)
	_sprite.scale = Vector2(_base_scale.x * 1.18, _base_scale.y * 0.88)
	if absf(_dash_dir.x) > 0.05:
		_sprite.flip_h = _dash_dir.x < 0.0

# --- Ease helpers ---
func _e_out(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)
func _e_io(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)
func _back_out(x: float) -> float:
	var e: float = x - 1.0
	return 1.0 + 2.7 * e * e * e + 1.7 * e * e

# Take a hit. A raised guard blocks; a guard raised JUST as the blow lands is a
# perfect parry — deflect, stagger the attacker(s), and empower the next strike.
func take_damage(n: int) -> void:
	if _invuln > 0.0:
		return
	if _guarding:
		if _guard_hold <= PARRY_WINDOW:
			_perfect_parry()
		else:
			_block()
		return
	_invuln = 0.6
	hp -= n
	_flash(Palette.BLOOD)
	hp_changed.emit(hp, max_hp)
	Vfx.float_text(get_parent(), global_position + Vector2(0.0, -42.0 * Palette.ACTOR_SCALE),
		"-%d" % n, Palette.BLOOD)
	# An unblocked hit breaks the combo.
	_combo_next = 0
	_reset_t = 0.0
	# Agriculture (QA D-02): badly hurt but alive → the cat eats a Provision. A
	# cushion against attrition, not a death-save (it never fires on a killing blow).
	if hp > 0 and hp <= 2 and provisions > 0:
		provisions -= 1
		Vfx.float_text(get_parent(), global_position + Vector2(0.0, -52.0 * Palette.ACTOR_SCALE),
			"provision", Palette.MOSS_L)
		heal(3)
	if hp <= 0 and not _dead:
		_die()

# Death: stop fighting, become untargetable, collapse in place, and tell Main
# (which runs the return-home flow + the run summary). One-shot via `_dead`.
func _die() -> void:
	_dead = true
	combat_enabled = false
	_invuln = 1.0e9                # no further hits register on the corpse
	velocity = Vector2.ZERO
	_reset_combat_state()
	if _sprite != null:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate", Palette.SHADOW_D.darkened(0.1), 0.30)
		tw.parallel().tween_property(_sprite, "scale",
			Vector2(_base_scale.x * 1.2, _base_scale.y * 0.42), 0.42) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(_sprite, "skew", 0.5, 0.42)
	Vfx.embers(get_parent(), global_position, 16, Palette.SHADOW.lightened(0.12))
	died.emit()

# Normal block: eat the blow, brief i-frame, modest spark — no hitstop. Costs
# stamina; draining it on this blow triggers a guard break (QA F-04).
func _block() -> void:
	_invuln = BLOCK_IFRAMES
	guard_stamina = maxf(0.0, guard_stamina - GUARD_BLOCK_COST)
	Vfx.hit_spark(get_parent(), global_position + Vector2(0.0, -32.0))
	Vfx.ring(get_parent(), global_position, 44.0, Palette.GOLD_L, 0.3)
	Vfx.float_text(get_parent(), global_position + Vector2(0.0, -42.0 * Palette.ACTOR_SCALE),
		"chặn", Palette.GOLD_L)
	Main.shake(0.06)
	if guard_stamina <= 0.0:
		_break_guard()

# Guard shattered: drop the guard, lock it out briefly, and punish with a stagger cue.
func _break_guard() -> void:
	_guarding = false
	_guard_was = false
	guard_stamina = 0.0
	_guard_broken_t = GUARD_BREAK_LOCK
	if _guard_fx != null:
		_guard_fx.modulate.a = 0.0
		_guard_fx.visible = false
	Vfx.hit_spark(get_parent(), global_position + Vector2(0.0, -30.0))
	Vfx.float_text(get_parent(), global_position + Vector2(0.0, -46.0 * Palette.ACTOR_SCALE),
		"GUARD BREAK", Palette.BLOOD)
	Main.shake(0.09)

# Perfect parry: the hardest freeze in the game, a radial stagger of nearby husks
# (no attacker reference exists — take_damage takes one int — so the counter is a
# group scan), and an armed empowered riposte on the next attack.
func _perfect_parry() -> void:
	_invuln = PARRY_IFRAMES
	var up: Vector2 = Vector2(0.0, -32.0)
	Vfx.parry_flash(get_parent(), global_position + up)
	Vfx.ring(get_parent(), global_position, 60.0, Palette.CYAN, 0.30)
	Vfx.float_text(get_parent(), global_position + Vector2(0.0, -42.0 * Palette.ACTOR_SCALE),
		"PARRY!", Palette.GOLD_L)
	Vfx.hitstop(self, PARRY_HITSTOP)
	Main.shake(PARRY_SHAKE)
	Main.zoom_punch(0.03)
	# Timing beats turtling: a perfect parry refunds guard stamina.
	guard_stamina = minf(GUARD_MAX, guard_stamina + PARRY_REFUND)
	for e in get_tree().get_nodes_in_group("enemy"):
		var en := e as Node2D
		if en == null:
			continue
		if Iso.gdist(global_position, en.global_position) > RIPOSTE_RANGE:
			continue
		var from_dir: Vector2 = Iso.gdir(global_position, en.global_position)
		if en.has_method("stun"):
			en.call("stun", PARRY_STAGGER)
		elif en.has_method("take_damage"):
			en.call("take_damage", 0, from_dir, false)
		if en.has_method("shove"):
			en.call("shove", from_dir, PARRY_KNOCK)
	_counter_t = COUNTER_WINDOW

# Kick off a dash in the current movement direction (or facing if standing still):
# lock the direction, grant i-frames, and throw a puff + a small push-in.
func _start_dash() -> void:
	var d: Vector2 = Vector2.ZERO
	var mv: Vector2 = _input_dir()
	if mv.length() > 0.01:
		d = mv.normalized()
	else:
		d = _move_dir
	if d.length() < 0.01:
		d = Vector2.RIGHT
	_dash_dir = d
	_move_dir = d
	facing = d
	_dash_t = DASH_TIME
	_dash_cd = DASH_CD
	_invuln = maxf(_invuln, DASH_IFRAMES)
	collision_mask = MASK_DASH          # phase through husks, not through walls
	# The dodge is the universal escape: it cancels any attack, recovery or guard.
	_state = S_LOCO
	_recover_t = 0.0
	_atk_t = 0.0
	_buffer_t = 0.0
	_guarding = false
	_guard_was = false
	Vfx.dust(get_parent(), global_position, 9)

# A fading ghost of the body, dropped each dash frame to draw the streak.
func _spawn_afterimage() -> void:
	if _sprite == null or _sprite.texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = _sprite.texture
	ghost.scale = _sprite.scale
	ghost.offset = _sprite.offset
	ghost.flip_h = _sprite.flip_h
	ghost.global_position = _sprite.global_position
	ghost.modulate = Color(Palette.GOLD_L.r, Palette.GOLD_L.g, Palette.GOLD_L.b, 0.45)
	ghost.z_index = -1
	get_parent().add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tw.tween_callback(ghost.queue_free)

# Fade the shield bubble in/out with the guard and give it a slow living shimmer.
func _update_guard_fx(delta: float) -> void:
	if _guard_fx == null:
		return
	_guard_fx.visible = _guarding or _guard_fx.modulate.a > 0.02
	var target: float = 0.7 if _guarding else 0.0
	_guard_fx.modulate.a = move_toward(_guard_fx.modulate.a, target, delta * 6.0)
	if _guarding:
		_guard_fx.rotation += delta * 1.4

# Brief red flash on the body sprite, tweening back to normal.
func _flash(c: Color) -> void:
	if _sprite == null:
		return
	_sprite.modulate = c
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate", Color.WHITE, 0.3)

# Restore hp (hearth rooms, future potions), capped at max. A warm ember lift.
func heal(n: int) -> void:
	if n <= 0:
		return
	hp = mini(max_hp, hp + n)
	hp_changed.emit(hp, max_hp)
	Vfx.embers(get_parent(), global_position, 10, Palette.GOLD)
	Vfx.float_text(get_parent(), global_position + Vector2(0.0, -42.0 * Palette.ACTOR_SCALE),
		"+%d" % n, Palette.MOSS_L)

# Permanent rescue buff applied when a survivor is freed and follows home.
# `announce` triggers the on-screen "Attunement gained" banner (skipped on the
# silent per-run re-application, which only rebuilds stats).
func apply_buff(kind: String, announce: bool = false) -> void:
	match kind:
		"armor":
			max_hp += 2
			hp += 2
		"damage":
			damage_mult += 0.25
		"speed":
			speed_mult += 0.25
	hp_changed.emit(hp, max_hp)
	Vfx.embers(get_parent(), global_position, 10, Palette.GOLD)
	if announce:
		var up: Vector2 = Vector2(0.0, -46.0 * Palette.ACTOR_SCALE)
		Vfx.ring(get_parent(), global_position, 70.0, Palette.MOSS_L, 0.4)
		Vfx.float_text(get_parent(), global_position + up, "ATTUNED", Palette.GOLD_L)

# The village you rebuilt strengthens the descent (QA D-02): the Forge sharpens the
# claws (Metallurgy), Cabins harden the body (Shelter), the Crop Beds send you down
# with Provisions (Agriculture). Applied once per fresh run by Main, on top of the
# reset baseline + rescue attunements. Each is capped, so a *diverse* village beats
# spamming one building — which also dissolves the cabin-spam dominant strategy (F-13).
func apply_village(forges: int, cabins: int, crop_beds: int) -> void:
	var f: int = mini(forges, 3)
	var c: int = mini(cabins, 3)
	damage_mult += 0.08 * float(f)
	max_hp += c
	hp = max_hp
	provisions = mini(crop_beds, 3)
	hp_changed.emit(hp, max_hp)

# ---------------------------------------------------------------------------
# EMBERGROWTH — Kindle → succession Blooms → drafted Boons (QA D-01)
# The single per-run growth path. Dungeon calls gain_kindle() on every husk kill;
# stat mutations happen in exactly one place (_bloom / apply_boon), so nothing
# double-scales (§8.0). All of it is reset by begin_run().
# ---------------------------------------------------------------------------

# Release a husk's stored fuel as Kindle. Only counts in combat (village kills
# don't exist, but this guards a stray call). Crossing a threshold blooms.
func gain_kindle(amount: float) -> void:
	if amount <= 0.0 or not combat_enabled or _dead:
		return
	kindle += amount
	GameState.run_stats["kindle"] = int(GameState.run_stats.get("kindle", 0)) + int(round(amount))
	_check_bloom()

# Advance one succession stage per threshold crossed; each stage-up is one Bloom.
func _check_bloom() -> void:
	while kindle_stage < KINDLE_THRESHOLDS.size() - 1 \
			and kindle >= float(KINDLE_THRESHOLDS[kindle_stage + 1]):
		kindle_stage += 1
		_bloom(kindle_stage)

# A Bloom: the flat succession stat step, the "burn hotter" flourish (reusing the
# retired level-up juice), and the pick-1-of-3 boon offer that carries the run's
# build identity.
func _bloom(stage: int) -> void:
	damage_mult += BLOOM_DMG
	speed_mult += BLOOM_SPD
	if stage == 2 or stage == 4:      # a Max HP step at two of the five stages
		max_hp += 1
		hp = mini(max_hp, hp + 1)
	hp_changed.emit(hp, max_hp)
	GameState.run_stats["blooms"] = int(GameState.run_stats.get("blooms", 0)) + 1
	_flare_aura(stage)
	var up: Vector2 = Vector2(0.0, -46.0 * Palette.ACTOR_SCALE)
	Vfx.ring(get_parent(), global_position, 96.0, Palette.GOLD_L, 0.5)
	Vfx.embers(get_parent(), global_position, 18, Palette.EMBER)
	Vfx.float_text(get_parent(), global_position + up,
		"%s BLOOM" % STAGE_NAMES[clampi(stage, 0, STAGE_NAMES.size() - 1)], Palette.GOLD_L)
	Vfx.hitstop(self, 0.05)
	Main.shake(0.14)
	Main.zoom_punch(0.035)
	bloomed.emit(stage)
	boon_offer.emit(_roll_boons())

# Three distinct boons to draft this Bloom.
func _roll_boons() -> Array:
	var pool: Array = BOON_POOL.duplicate()
	pool.shuffle()
	return pool.slice(0, mini(3, pool.size()))

# Apply a drafted boon immediately (called by Main after the card is picked).
func apply_boon(id: String) -> void:
	if id == "":
		return
	boons.append(id)
	match id:
		"ember_fang":   damage_mult += 0.20
		"fleetfoot":    speed_mult += 0.12
		"bramble_heart":
			max_hp += 2
			hp = mini(max_hp, hp + 2)
		"keen_eye":     crit_chance = minf(0.75, crit_chance + 0.07)
		"second_wind":  hp = mini(max_hp, hp + 3)
		"hearths_gift":
			max_hp += 1
			hp = mini(max_hp, hp + 1)
			damage_mult += 0.08
	hp_changed.emit(hp, max_hp)
	var up: Vector2 = Vector2(0.0, -42.0 * Palette.ACTOR_SCALE)
	Vfx.ring(get_parent(), global_position, 64.0, Palette.GOLD_L, 0.35)
	Vfx.embers(get_parent(), global_position, 12, Palette.GOLD)
	Vfx.float_text(get_parent(), global_position + up, "BOON", Palette.GOLD_L)

# Swell the succession aura to match the current stage (called on Bloom + soil seed).
func _flare_aura(stage: int) -> void:
	if _ember_aura == null:
		return
	_ember_aura.visible = true
	var a: float = 0.14 + 0.07 * float(stage)
	var s: float = 0.5 + 0.09 * float(stage)
	var tw := create_tween()
	tw.tween_property(_ember_aura, "modulate:a", a, 0.3).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_ember_aura, "scale",
		Vector2(s, s * Palette.SQUASH), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Start a dungeon run: reset run-scoped stats (permanent buffs from apply_buff
# are re-established by Main re-applying rescued roster, so here we clear to base).
func begin_run() -> void:
	max_hp = base_max_hp
	hp = max_hp
	speed_mult = 1.0
	damage_mult = 1.0
	crit_chance = 0.22
	combat_enabled = true
	_dead = false
	_invuln = 0.0
	guard_stamina = GUARD_MAX
	_guard_broken_t = 0.0
	collision_mask = MASK_NORMAL        # never enter a room mid-phase
	# Fresh run-scoped growth: Kindle, succession stage and drafted boons all reset
	# (they belong to a single descent), then the Soil head-start seeds the start.
	kindle = 0.0
	kindle_stage = 0
	boons.clear()
	provisions = 0                      # re-granted by the village boons (Main)
	_reset_combat_state()
	if _ember_aura != null:
		_ember_aura.visible = false
		_ember_aura.modulate.a = 0.0
		_ember_aura.scale = Vector2(0.5, 0.5 * Palette.SQUASH)
	if _guard_fx != null:
		_guard_fx.modulate.a = 0.0
		_guard_fx.visible = false
	_seed_from_soil()
	hp_changed.emit(hp, max_hp)

# Soil head-start: a warm, populous village begins the descent further up the
# succession (PROGRESSION §4.3). Seeds Kindle + stage and applies the seeded
# stages' flat stat steps — but offers NO boon cards (a head start, not free
# drafts). Rescue attunements (Main.apply_buff) still layer on top afterward.
func _seed_from_soil() -> void:
	var start_stage: int = GameState.soil_start_stage()
	if start_stage <= 0:
		return
	kindle_stage = start_stage
	kindle = float(KINDLE_THRESHOLDS[start_stage])
	for s in range(1, start_stage + 1):
		damage_mult += BLOOM_DMG
		speed_mult += BLOOM_SPD
		if s == 2 or s == 4:
			max_hp += 1
	hp = max_hp
	_flare_aura(start_stage)

# Return to the safe village: revive (clear the death latch — otherwise the hero
# comes home a frozen corpse and softlocks the loop), disable combat, heal to full.
func enter_village() -> void:
	_dead = false
	_invuln = 0.0
	combat_enabled = false
	collision_mask = MASK_NORMAL
	_reset_combat_state()
	# The succession aura belongs to a run; damp it at home so the village hero
	# isn't wearing last descent's Canopy glow.
	if _ember_aura != null:
		_ember_aura.visible = false
		_ember_aura.modulate.a = 0.0
	hp = max_hp
	hp_changed.emit(hp, max_hp)

# Advance to a DEEPER room in the same run: keep hp / loot / buffs, but scrub the
# transient motion + combat state so velocity, dash, i-frames and an armed riposte
# never leak into the next arena.
func enter_next_room() -> void:
	velocity = Vector2.ZERO
	_invuln = 0.0
	collision_mask = MASK_NORMAL
	_reset_combat_state()

# Clear every combat timer/latch so a mid-combo never leaks across a scene swap.
func _reset_combat_state() -> void:
	_state = S_LOCO
	_atk_kind = 0
	_atk_t = 0.0
	_did_hit = false
	_did_end = false
	_combo_next = 0
	_buffer_t = 0.0
	_reset_t = 0.0
	_recover_t = 0.0
	_counter_t = 0.0
	_dash_t = 0.0
	_dash_cd = 0.0
	_dash_atk_t = 0.0
	_guarding = false
	_guard_was = false
	_guard_hold = 0.0
	guard_stamina = GUARD_MAX
	_guard_broken_t = 0.0
	_shove_t = 0.0
	_shove_v = Vector2.ZERO
	if _sprite != null:
		_sprite.position = Vector2.ZERO
		_sprite.skew = 0.0
		_sprite.scale = _base_scale
		_sprite.modulate = Color(1, 1, 1, 1)   # clear any death/hurt tint on respawn
