class_name Player
extends CharacterBody2D
## The persistent hero: one instance owned by Main across every dungeon run and
## village visit. WASD movement, a mouse-aimed three-hit melee combo, an
## i-framed dash, damage handling, per-run stat resets and rescue buffs.
##
## FEEL, IN ONE PLACE
## Three things do most of the work and they all live here:
##  - The COMBO alternates shoulders (A-B-heavy) and each step is a different
##    arc, cooldown and damage, so mashing produces rhythm instead of a strobe.
##  - Every connecting hit calls Juice.hitstop(). The freeze is what converts a
##    particle near an enemy into the feeling of contact.
##  - The DASH is i-framed and leaves afterimages. Invulnerability makes it a
##    real defensive option; the afterimages are what stop it reading as a
##    teleport.

# Fired whenever hp or max_hp changes so the Hud can redraw the heart bar.
signal hp_changed(hp: int, max_hp: int)
# Fired exactly once when hp reaches 0; Main routes this to a return-home flow.
signal died

# --- Base stats (immutable baseline; multipliers/bonuses layer on top) ---
var base_speed: float = 150.0
var base_max_hp: int = 6
var base_damage: int = 2

# --- Live stats ---
var max_hp: int = 6
var hp: int = 6
var speed_mult: float = 1.0
var damage_mult: float = 1.0
var combat_enabled: bool = true
var attack_cd: float = 0.34          # kept for compatibility; per-step values below
var facing: Vector2 = Vector2.RIGHT

# --- Combo tuning -----------------------------------------------------------
# Per step: recovery before the next swing, damage scale, knockback, arc kind.
const COMBO := [
	{"cd": 0.26, "dmg": 1.0, "kb": 7.0, "kind": "light", "flip": false, "lunge": 90.0},
	{"cd": 0.24, "dmg": 1.0, "kb": 7.0, "kind": "light", "flip": true, "lunge": 90.0},
	{"cd": 0.46, "dmg": 1.9, "kb": 20.0, "kind": "heavy", "flip": false, "lunge": 170.0},
]
const COMBO_WINDOW := 0.62     # seconds after a swing that the chain stays open
const REACH := 46.0            # melee reach, px
const ARC_DOT := 0.20          # how wide the swing hemisphere is

# --- Dash tuning ------------------------------------------------------------
const DASH_SPEED := 560.0
const DASH_TIME := 0.15
const DASH_CD := 0.55
const DASH_GHOST_EVERY := 0.028

# --- Internal state ---
var _cd: float = 0.0                 # attack recovery remaining
var _invuln: float = 0.0             # i-frame time remaining
var _dead: bool = false              # latch so `died` fires only once
var _sprite: Sprite2D = null
var _shadow: Sprite2D = null
var _anim: ActorAnim = null
var _light: PointLight2D = null

var _combo: int = 0                  # 0 = chain idle, else 1..3
var _combo_left: float = 0.0         # time left to continue the chain
var _lunge: Vector2 = Vector2.ZERO   # decaying impulse from the last swing

var _dash_left: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _ghost_t: float = 0.0

func _ready() -> void:
	add_to_group("player")

	# Contact shadow first, so it draws under the body.
	_shadow = Iso.shadow(self, 34.0, 0.42)

	# Body sprite, anchored so the node position is where the feet touch the
	# floor. That is what makes the shadow, the hop and the y-sorting agree.
	_sprite = Sprite2D.new()
	_sprite.texture = Assets.tex("player")
	_sprite.scale = Vector2(Palette.ACTOR_PX, Palette.ACTOR_PX)
	add_child(_sprite)
	Iso.anchor_feet(_sprite, 4.0)

	# The hero carries the last ember, so the hero carries a light.
	_light = Iso.light(self, Palette.TORCH, 108.0, 1.15)
	_light.position = Vector2(-12.0, -34.0)      # at the lantern, not the navel
	Iso.flicker(_light, 1.15, 0.10, 0.14)

	_anim = ActorAnim.new(_sprite, _shadow)

	# Physics body: a small circle so movement collides with walls/enemies.
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	col.shape = shape
	add_child(col)

	max_hp = base_max_hp
	hp = max_hp
	hp_changed.emit(hp, max_hp)

# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if _dash_left > 0.0:
		# A dash owns the velocity outright — no steering mid-dash, which is what
		# makes it a commitment rather than a speed boost.
		velocity = _dash_dir * DASH_SPEED
		move_and_slide()
		_dash_trail(delta)
		return

	var dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * base_speed * speed_mult + _lunge
	move_and_slide()
	# Bleed the swing lunge away quickly so it adds punch, not drift.
	_lunge = _lunge.move_toward(Vector2.ZERO, 900.0 * delta)
	if dir.length() > 0.01:
		facing = dir.normalized()

func _process(delta: float) -> void:
	if _cd > 0.0:
		_cd -= delta
	if _invuln > 0.0:
		_invuln -= delta
	if _dash_cd > 0.0:
		_dash_cd -= delta
	if _combo_left > 0.0:
		_combo_left -= delta
		if _combo_left <= 0.0:
			_combo = 0

	if _dash_left > 0.0:
		_dash_left -= delta
		if _dash_left <= 0.0:
			_end_dash()

	# Aim the body at the cursor while fighting, so the hero always faces the
	# thing being hit even when standing still.
	if _anim != null:
		if combat_enabled:
			_anim.face((get_global_mouse_position() - global_position).x)
		var footfall: bool = _anim.tick(delta, velocity)
		if footfall and _dash_left <= 0.0:
			Vfx.dust(get_parent(), global_position, 2)

	if Input.is_action_just_pressed("dash"):
		_try_dash()
	if combat_enabled and _cd <= 0.0 and Input.is_action_pressed("attack"):
		_swing()

# ---------------------------------------------------------------------------
# Dash
# ---------------------------------------------------------------------------
func _try_dash() -> void:
	if _dash_cd > 0.0 or _dash_left > 0.0:
		return
	var dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_dash_dir = dir.normalized() if dir.length() > 0.01 else facing
	facing = _dash_dir
	_dash_left = DASH_TIME
	_dash_cd = DASH_CD
	# I-frames cover the dash plus a few forgiving ms on the far side.
	_invuln = maxf(_invuln, DASH_TIME + 0.10)
	_ghost_t = 0.0

	Vfx.streak(get_parent(), global_position - _dash_dir * 10.0, _dash_dir, 1.15)
	Vfx.dust(get_parent(), global_position, 9, -_dash_dir)
	Vfx.shockwave(get_parent(), global_position, 44.0, Palette.AMBER, 0.26, "ring_soft")
	Juice.shake(3.0, 0.14)
	if _anim != null:
		_anim.punch(0.20)

# Leave a trail of fading ghosts along the dash path.
func _dash_trail(delta: float) -> void:
	_ghost_t -= delta
	if _ghost_t > 0.0:
		return
	_ghost_t = DASH_GHOST_EVERY
	if _sprite == null:
		return
	# The ghost is a plain centred sprite, so it has to be placed at the body's
	# VISUAL centre — the feet anchor offset, scaled — not at the node origin.
	Vfx.afterimage(get_parent(), _sprite.texture,
			_sprite.global_position + _sprite.offset * _sprite.scale,
			_sprite.scale, Color(1.0, 0.72, 0.40, 0.42), 0.24)

func _end_dash() -> void:
	_dash_left = 0.0
	velocity = Vector2.ZERO
	Vfx.dust(get_parent(), global_position, 4)
	if _anim != null:
		_anim.punch(0.14)

## True while the dash is active — Main/HUD can use this for a cooldown pip.
func is_dashing() -> bool:
	return _dash_left > 0.0

## 0..1 readiness of the dash, for a HUD indicator.
func dash_ready() -> float:
	return 1.0 - clampf(_dash_cd / DASH_CD, 0.0, 1.0)

# ---------------------------------------------------------------------------
# Melee
# ---------------------------------------------------------------------------
## Mouse-aimed swing. Advances the combo, throws the matching arc, lunges, and
## scans the swing hemisphere for enemies.
func _swing() -> void:
	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	var dir: Vector2 = to_mouse.normalized() if to_mouse.length() > 0.01 else facing
	facing = dir

	# Advance (or restart) the chain.
	_combo = (_combo % COMBO.size()) + 1 if _combo_left > 0.0 else 1
	_combo_left = COMBO_WINDOW
	var step: Dictionary = COMBO[_combo - 1]
	var kind: String = String(step["kind"])
	var heavy: bool = kind == "heavy"

	# The swing itself, pivoted on the hero so the blade sweeps around them.
	Vfx.swing(get_parent(), global_position + Vector2(0.0, -18.0), dir, kind, bool(step["flip"]))
	if _anim != null:
		_anim.face(dir.x)
		_anim.punch(0.26 if heavy else 0.16)
	# Step into the blow.
	_lunge = dir * float(step["lunge"])
	if heavy:
		Juice.shake(3.5, 0.16)

	var dmg: int = maxi(1, int(round(base_damage * damage_mult * float(step["dmg"]))))
	var hits: int = 0
	for e in get_tree().get_nodes_in_group("enemy"):
		var en := e as Node2D
		if en == null or not is_instance_valid(en):
			continue
		var offset: Vector2 = en.global_position - global_position
		if offset.length() > REACH or dir.dot(offset.normalized()) <= ARC_DOT:
			continue
		if not en.has_method("take_damage"):
			continue
		# Dynamic call: Player only knows enemies by group, not by class.
		en.call("take_damage", dmg, dir * float(step["kb"]))
		Vfx.impact(get_parent(), en.global_position + Vector2(0.0, -20.0), dir,
				0.85 if heavy else 0.45)
		hits += 1

	if hits > 0:
		# The freeze is the hit. Scaled by the blow, capped so a crowd can't
		# chain it into slow motion.
		Juice.hitstop(0.085 if heavy else 0.038)
		Juice.shake(9.0 if heavy else 4.0, 0.20)
		if heavy:
			Juice.flash(Palette.GOLD_L, 0.16, 0.18)
	_cd = float(step["cd"])

# ---------------------------------------------------------------------------
# Damage
# ---------------------------------------------------------------------------
func take_damage(n: int) -> void:
	if _invuln > 0.0 or _dead:
		return
	_invuln = 0.6
	hp -= n
	_flash(Palette.BLOOD)
	hp_changed.emit(hp, max_hp)

	# Getting hit has to feel worse than hitting: harder freeze, red wash, and a
	# shove that takes control away for a moment.
	Vfx.float_text(get_parent(), global_position + Vector2(0.0, -46.0), "-%d" % n, Palette.BLOOD)
	Vfx.impact(get_parent(), global_position + Vector2(0.0, -28.0), Vector2.UP, 0.5)
	Juice.hitstop(0.07)
	Juice.shake(8.0, 0.30)
	Juice.flash(Palette.BLOOD, 0.28, 0.30)
	if _anim != null:
		_anim.punch(0.30)

	if hp <= 0 and not _dead:
		_dead = true
		Vfx.embers(get_parent(), global_position + Vector2(0.0, -20.0), 26, Palette.EMBER)
		Vfx.light_pop(get_parent(), global_position, Palette.EMBER, 220.0, 0.7)
		Juice.flash(Palette.BLOOD, 0.45, 0.6)
		died.emit()

# Brief tint flash on the body sprite, easing back to normal.
func _flash(c: Color) -> void:
	if _sprite == null:
		return
	_sprite.modulate = c
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate", Color.WHITE, 0.3)

# ---------------------------------------------------------------------------
# Progression hooks
# ---------------------------------------------------------------------------
func apply_buff(kind: String) -> void:
	match kind:
		"armor":
			max_hp += 2
			hp += 2
		"damage":
			damage_mult += 0.5
		"speed":
			speed_mult += 0.2
	hp_changed.emit(hp, max_hp)
	Vfx.embers(get_parent(), global_position + Vector2(0.0, -20.0), 12, Palette.GOLD)
	Vfx.glint(get_parent(), global_position + Vector2(0.0, -50.0), Palette.GOLD_L)

func begin_run() -> void:
	max_hp = base_max_hp
	hp = max_hp
	speed_mult = 1.0
	damage_mult = 1.0
	combat_enabled = true
	_dead = false
	_invuln = 0.0
	_cd = 0.0
	_combo = 0
	_combo_left = 0.0
	_dash_left = 0.0
	_dash_cd = 0.0
	_lunge = Vector2.ZERO
	hp_changed.emit(hp, max_hp)

func enter_village() -> void:
	combat_enabled = false
	hp = max_hp
	_combo = 0
	_combo_left = 0.0
	hp_changed.emit(hp, max_hp)
