class_name Enemy
extends CharacterBody2D
## A husk that hunts the player through a ruin chamber. Builds its own Sprite2D
## and CollisionShape2D in _ready(), chases the nearest node in group "player",
## and attacks with a TELEGRAPHED wind-up so every blow is readable and parryable
## (QA F-04) — passive body contact no longer damages. Four behaviours (QA F-05),
## chosen by `kind`: husk (lunge), charger (long telegraphed rush that self-stuns on
## a wall), lobber (keeps distance, arcs a blast), warden (heavy lunge + shockwave).
## References only autoloads (Palette / Assets / GameState), Vfx, Iso, and group "player".

# Fired once, on death, with the world position where the husk fell. The Dungeon
# listens to this to (maybe) drop a material Pickup.
signal died(pos: Vector2)

# --- Identity ---
var kind: String = "husk"       # "husk" | "charger" | "lobber" | "warden"

# --- Tunable stats. configure() overwrites these; read in _ready() so it is safe
# to set them before OR after the node is added. ---
var max_hp: int = 4
var speed: float = 100.0
var touch_damage: int = 1
var tex_key: String = "enemy_husk"

# --- Runtime state ---
var hp: int = 0                 # current health; initialised from max_hp in _ready()
var _dead: bool = false         # guards against a double death emit / free
var _sprite: Sprite2D = null    # body sprite, kept so configure() can re-skin it
var _flash_tw: Tween = null     # active hurt-flash tween, so hits don't stack
var _base_scale: Vector2 = Vector2.ONE  # body scale the walk cycle squashes around
var _base_tint: Color = Color(1, 1, 1, 1)  # per-kind body colour (hurt-flash returns here)
var _anim_t: float = 0.0        # walk/idle cycle phase
var _face_left: bool = false    # turnaround: which way the husk reads
var _stun_t: float = 0.0        # frozen (can't chase or attack) while > 0
var _warn: Sprite2D = null      # telegraph glow shown during a wind-up
var _danger: Node2D = null      # red ground zone marking WHERE a blow will land (QA feel)
var _zone_shown: bool = false   # whether the danger zone was drawn last frame

# --- Attack state machine ---
const A_CHASE := 0
const A_WINDUP := 1             # rooted, telegraphing — the parry/dodge window
const A_STRIKE := 2             # the committed blow (lunge / rush / lob)
const A_RECOVER := 3            # vulnerable endlag
var _phase: int = A_CHASE
var _phase_t: float = 0.0
var _atk_cd: float = 0.0
var _atk_dir: Vector2 = Vector2.RIGHT
var _aim_target: Vector2 = Vector2.ZERO  # lobber's marked landing spot
var _did_hit: bool = false

# --- Per-kind behaviour params, derived from `kind` in _apply_kind() ---
var _chase_speed: float = 100.0
var _strike_range: float = 46.0   # ground px at which a melee kind commits
var _hit_range: float = 30.0      # ground px a lunge connects within
var _windup: float = 0.42
var _strike_time: float = 0.18
var _recover: float = 0.35
var _cd: float = 0.7
var _lunge_speed: float = 340.0
var _ranged: bool = false
var _prefer_dist: float = 190.0
var _shockwave: bool = false
var _warn_col: Color = Palette.EMBER

# Attack-commitment token (QA F-04 readability): only a few husks may telegraph +
# strike at once, so a crowded room stays a *readable* fight (two tells to react to)
# instead of five simultaneous lunges — the "slot machine" F-04 warns about, at
# crowd scale. Melee husks that can't get a slot hold at range and menace; the
# Warden ignores the gate (a boss never waits its turn).
const MAX_COMMITTED := 2

func _ready() -> void:
	# Contact shadow, then a feet-anchored Hades-scaled billboard.
	Iso.shadow(self, 42.0 * Palette.ACTOR_SCALE, 0.4)
	_sprite = Sprite2D.new()
	_sprite.texture = Assets.tex(tex_key)
	add_child(_sprite)
	_base_scale = Iso.mount_body(_sprite, 3.0)
	# Telegraph glow: an additive ring that swells during a wind-up so the player
	# reads the incoming blow. Kept OFF the body modulate (which _flash/stun/_die
	# already contend over — see DESIGN §6).
	_warn = Sprite2D.new()
	_warn.texture = Assets.tex("glow_ring")
	var wm := CanvasItemMaterial.new()
	wm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_warn.material = wm
	_warn.z_index = 2
	_warn.position = Vector2(0.0, -18.0)
	_warn.visible = false
	add_child(_warn)
	# Red danger zone painted on the FLOOR during a wind-up: it shows exactly where the
	# blow will land (a lunge lane, a slam ring, a bomb blast) and fills in as the strike
	# nears, so every attack is dodge-able on sight. Drawn under the actors (z −3).
	_danger = Node2D.new()
	_danger.z_index = -3
	_danger.z_as_relative = false
	add_child(_danger)
	_danger.draw.connect(_draw_danger)
	# Physics body: a small circle at the feet so husks bump walls and each other.
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	add_child(shape)
	# Husks live on their own physics layer (3 = bit 4) so a dashing hero can drop
	# them from its mask and phase through; they still collide with walls, the hero
	# (layer 1) and each other.
	collision_layer = 4
	collision_mask = 1 | 4
	_apply_kind()
	# Fresh full health, and register so the player's melee scan can find us.
	hp = max_hp
	add_to_group("enemy")

# Vary this husk. Safe before the node is built (values stored, applied in _ready)
# or after (sprite + hp + behaviour refreshed immediately). `kind` selects the AI.
func configure(hp: int, speed: float, tex_key: String, kind: String = "husk") -> void:
	max_hp = hp
	self.speed = speed
	self.tex_key = tex_key
	self.kind = kind
	self.hp = max_hp
	if _sprite != null:
		_sprite.texture = Assets.tex(tex_key)
		_apply_kind()

# Translate `kind` into behaviour numbers, scaled off the injected base `speed`. Each
# kind also gets a distinct SIZE and body TINT so a busy room reads as a varied threat
# roster at a glance, not one sprite repeated.
func _apply_kind() -> void:
	_chase_speed = speed
	_ranged = false
	_shockwave = false
	var kf: float = 1.0                       # per-kind size multiplier
	match kind:
		"charger":
			_strike_range = 210.0; _hit_range = 34.0
			_windup = 0.6; _strike_time = 0.5; _recover = 0.55; _cd = 1.25
			_lunge_speed = 470.0; _chase_speed = speed * 1.15
			_warn_col = Palette.WINE.lerp(Palette.EMBER, 0.5)
			_base_tint = Color(1.0, 0.70, 0.60); kf = 1.20   # a big, angry red husk
		"lobber":
			_ranged = true; _cd = 2.2; _prefer_dist = 190.0
			_windup = 0.5; _strike_time = 0.12; _recover = 0.5
			_chase_speed = speed * 0.8
			_warn_col = Palette.CYAN
			_base_tint = Color(0.70, 0.86, 1.0); kf = 0.86   # a small, cold caster
		"warden":
			_strike_range = 66.0; _hit_range = 42.0
			_windup = 0.55; _strike_time = 0.24; _recover = 0.7; _cd = 1.1
			_lunge_speed = 320.0; _shockwave = true
			_warn_col = Palette.WINE.lerp(Palette.EMBER, 0.4)
			_base_tint = Palette.WHITE; kf = 1.0             # the brute sprite is already big
		"bomber":
			# A kamikaze: closes in, swells a red blast ring, then self-destructs. Kill it
			# first, or leave its circle before it blows.
			_strike_range = 78.0; _hit_range = _bomb_radius()
			_windup = 0.7; _strike_time = 0.08; _recover = 0.3; _cd = 0.9
			_lunge_speed = 0.0; _chase_speed = speed * 0.95
			_warn_col = Color(1.0, 0.25, 0.15)
			_base_tint = Color(1.0, 0.60, 0.42); kf = 0.84   # small, glowing hot
		_:  # husk
			_strike_range = 46.0; _hit_range = 30.0
			_windup = 0.42; _strike_time = 0.18; _recover = 0.35; _cd = 0.7
			_lunge_speed = 340.0
			_warn_col = Palette.EMBER
			_base_tint = Palette.WHITE; kf = 1.0
	if _warn != null:
		_warn.modulate = Color(_warn_col.r, _warn_col.g, _warn_col.b, 0.0)
	# Fresh (never compounding) kind-scaled base, so configure() can re-skin safely.
	_base_scale = Iso.actor_scale() * kf
	if _sprite != null:
		_sprite.scale = _base_scale
		_sprite.modulate = _base_tint

func _physics_process(delta: float) -> void:
	if _atk_cd > 0.0:
		_atk_cd -= delta
	# Stunned (parried): frozen, and any wind-up/strike is cancelled — a parry buys
	# a real interrupt, not just a pause.
	if _stun_t > 0.0:
		_stun_t -= delta
		_cancel_attack()
		velocity = Vector2.ZERO
		move_and_slide()
		if _stun_t <= 0.0 and _sprite != null:
			_sprite.modulate = _base_tint
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# A dead hero (corpse) is not a valid target — stop pressing the attack.
	var pdead: Variant = player.get("_dead")
	if pdead != null and bool(pdead):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var gd: float = Iso.gdist(global_position, player.global_position)
	# Always lean toward the prey (except mid-lunge, which locks its facing).
	if _phase != A_STRIKE and absf(player.global_position.x - global_position.x) > 2.0:
		_face_left = player.global_position.x < global_position.x
	match _phase:
		A_CHASE: _tick_chase(player, gd)
		A_WINDUP: _tick_windup(delta)
		A_STRIKE: _tick_strike(player, gd, delta)
		A_RECOVER: _tick_recover(delta)
	# Flash the red danger zone on only LATE in the wind-up (and through the strike),
	# then clear it one frame after — a brief, fair warning right before the blow
	# rather than a marker that lingers the whole telegraph.
	var want_zone: bool = _zone_live()
	if _danger != null and (want_zone or _zone_shown):
		_zone_shown = want_zone
		_danger.queue_redraw()

# --- CHASE: close in (ground-uniform, QA F-10/F-11); commit when in range. ---
func _tick_chase(player: Node2D, gd: float) -> void:
	if _ranged:
		# Hold a firing range: back off if crowded, close if too far, else settle.
		if gd < _prefer_dist * 0.7:
			velocity = -Iso.step(global_position, player.global_position, _chase_speed)
		elif gd > _prefer_dist * 1.35:
			velocity = Iso.step(global_position, player.global_position, _chase_speed)
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		if _atk_cd <= 0.0 and gd <= _prefer_dist * 1.5:
			_begin_windup(player)
		return
	if gd <= _strike_range and _atk_cd <= 0.0:
		if _may_commit():
			_begin_windup(player)
			return
		# In range but the attack slot is full: hold and menace, don't pile on. This
		# is what keeps a five-husk room readable (QA F-04).
		velocity = Vector2.ZERO
		move_and_slide()
		return
	velocity = Iso.step(global_position, player.global_position, _chase_speed)
	move_and_slide()

# May this husk begin an attack now? Gated so at most MAX_COMMITTED melee husks
# telegraph/strike at once (QA F-04). The Warden is exempt — it always presses.
func _may_commit() -> bool:
	if kind == "warden":
		return true
	return _committed_others() < MAX_COMMITTED

# How many OTHER husks are currently mid-attack (winding up or striking). A small
# group scan — the roster is tiny — recomputed each check so a husk dying or being
# parried mid-swing can never leak a phantom "committed" slot.
func _committed_others() -> int:
	var n: int = 0
	for e in get_tree().get_nodes_in_group("enemy"):
		var en := e as Enemy
		if en == null or en == self or not is_instance_valid(en):
			continue
		# The budget is a MELEE pile-on limit: lobbers (ranged positional threats) and
		# the Warden (exempt boss) neither consume nor are gated by it (QA review 2/3).
		if en._ranged or en.kind == "warden":
			continue
		if en._phase == A_WINDUP or en._phase == A_STRIKE:
			n += 1
	return n

# --- WIND-UP: rooted, glowing — the telegraph the player reacts to. ---
func _begin_windup(player: Node2D) -> void:
	_phase = A_WINDUP
	_phase_t = _windup
	_did_hit = false
	_atk_dir = Iso.gdir(global_position, player.global_position)
	_aim_target = player.global_position
	velocity = Vector2.ZERO
	move_and_slide()
	if _warn != null:
		_warn.visible = true
	# A pip of warning motes so the tell reads even off the body.
	Vfx.embers(get_parent(), global_position + Vector2(0.0, -22.0), 4, _warn_col)

func _tick_windup(delta: float) -> void:
	_phase_t -= delta
	velocity = Vector2.ZERO
	move_and_slide()
	if _warn != null:
		# Swell + brighten toward the strike so the timing is legible.
		var k: float = 1.0 - clampf(_phase_t / maxf(_windup, 0.001), 0.0, 1.0)
		_warn.modulate.a = 0.25 + 0.55 * k
		var s: float = (0.5 + 0.5 * k) * (46.0 / 128.0)
		_warn.scale = Vector2(s, s * Palette.SQUASH)
	if _phase_t <= 0.0:
		_begin_strike()

# --- STRIKE: the committed blow. ---
func _begin_strike() -> void:
	_phase = A_STRIKE
	_phase_t = _strike_time
	_did_hit = false
	if _warn != null:
		_warn.visible = false
	if kind == "bomber":
		_explode()
		return
	if _ranged:
		_spawn_lob(_aim_target)
		velocity = Vector2.ZERO
	else:
		Vfx.dust(get_parent(), global_position, 6)

# The bomber's blast: everything inside the red circle takes the hit, then the bomber
# consumes itself. (Kill it during the wind-up and it dies without ever blowing.)
func _explode() -> void:
	var r: float = _bomb_radius()
	Vfx.ring(get_parent(), global_position, r * 1.5, Color(0.98, 0.30, 0.16), 0.5)
	Vfx.crunch(get_parent(), global_position + Vector2(0.0, -20.0), Vector2.UP)
	Vfx.embers(get_parent(), global_position, 20, Palette.EMBER)
	Main.shake(0.17)
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player):
		var pdead: Variant = player.get("_dead")
		var alive: bool = pdead == null or not bool(pdead)
		if alive and Iso.gdist(global_position, player.global_position) <= r and player.has_method("take_damage"):
			player.call("take_damage", _dmg())
	_die(Vector2.UP)

func _tick_strike(player: Node2D, gd: float, delta: float) -> void:
	_phase_t -= delta
	if _ranged:
		velocity = Vector2.ZERO
		move_and_slide()
	else:
		velocity = Iso.vel(_atk_dir, _lunge_speed)
		move_and_slide()
		# Charger bonks a WALL → drop early into a long self-stun (the punish window).
		# Only a wall counts (QA review 1): colliding with an ally husk or the hero must
		# not abort the rush. stun() gives the readable cyan "stun" punish cue (review 6).
		if kind == "charger" and not _did_hit and _hit_a_wall():
			Vfx.impact(get_parent(), global_position, _atk_dir)
			stun(0.9)
			return
		if not _did_hit and gd <= _hit_range:
			_did_hit = true
			_hit_player(player)
	if _phase_t <= 0.0:
		_begin_recover()

func _hit_player(player: Node2D) -> void:
	if player.has_method("take_damage"):
		player.call("take_damage", _dmg())

# Did this frame's move_and_slide hit a solid WALL (not an ally husk or the hero)?
# Walls/cover are StaticBody2D; every actor is a CharacterBody2D — so a charge only
# self-stuns on real cover, never on a body it merely bumped (QA review 1).
func _hit_a_wall() -> bool:
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var other: Object = col.get_collider()
		if other != null and not (other is CharacterBody2D):
			return true
	return false

# --- RECOVER: vulnerable endlag; the warden slams a shockwave as it lands. ---
func _begin_recover() -> void:
	_phase = A_RECOVER
	_phase_t = _recover
	velocity = Vector2.ZERO
	if _shockwave:
		_slam()

func _tick_recover(delta: float) -> void:
	_phase_t -= delta
	velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	if _phase_t <= 0.0:
		_phase = A_CHASE
		_atk_cd = _cd

# The warden's landing shockwave: a floor ring that hits the hero if close — but
# not through cover, and not onto a corpse (QA review 4).
func _slam() -> void:
	Vfx.ring(get_parent(), global_position, 120.0, _warn_col, 0.45)
	Main.shake(0.16)
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return
	var pdead: Variant = player.get("_dead")
	if pdead != null and bool(pdead):
		return
	if Iso.gdist(global_position, player.global_position) > 96.0:
		return
	# Line-of-sight: a wall between us eats the shockwave (no hits through cover). Ray
	# on the environment layer (bit 1 = walls/structures), excluding us and the hero.
	var space := get_world_2d().direct_space_state
	var excl: Array[RID] = [get_rid()]
	var pco := player as CollisionObject2D
	if pco != null:
		excl.append(pco.get_rid())
	var q := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1, excl)
	if not space.intersect_ray(q).is_empty():
		return
	if player.has_method("take_damage"):
		player.call("take_damage", _dmg())

# Active contact damage, from the injected touch_damage (kept as the per-kind dmg).
func _dmg() -> int:
	return touch_damage

# ---------------------------------------------------------------------------
# Red danger zone — the ground telegraph. Drawn in the enemy's local frame on the
# floor plane (squashed Y), filling in as the strike nears so the player can read
# and dodge every blow on sight.
# ---------------------------------------------------------------------------
func _draw_danger() -> void:
	if _dead or _danger == null or (_phase != A_WINDUP and _phase != A_STRIKE):
		return
	# 0 at the start of the wind-up, 1 at the moment of the blow (full during strike).
	var prog: float = 1.0
	if _phase == A_WINDUP:
		prog = 1.0 - clampf(_phase_t / maxf(_windup, 0.001), 0.0, 1.0)
	# Soft, low-opacity fill (no rim outline) so the zone reads as a subtle wash, not
	# a hard-edged marker. Still fills in toward the strike so the timing stays legible.
	var fill: float = 0.07 + 0.15 * prog
	var red := Color(0.95, 0.14, 0.12)
	if kind == "bomber":
		_zone_circle(_bomb_radius(), red, fill)
		return
	if _ranged:
		return   # a lobber's danger is its ground marker (drawn red on the Lob orb)
	# Directional lunge lane toward the locked-in strike direction.
	var sdir := Vector2(_atk_dir.x, _atk_dir.y * Palette.SQUASH)
	sdir = sdir.normalized() if sdir.length() > 0.001 else Vector2.RIGHT
	var perp := Vector2(-sdir.y, sdir.x)
	var reach: float = _lunge_reach()
	var w0: float = _hit_range * 0.55
	var w1: float = _hit_range * 1.0
	var quad := PackedVector2Array([
		perp * w0,
		sdir * reach + perp * w1,
		sdir * reach - perp * w1,
		-perp * w0,
	])
	_danger.draw_colored_polygon(quad, Color(red.r, red.g, red.b, fill))
	# The Warden also previews the shockwave ring it slams down on landing.
	if _shockwave:
		_zone_circle(96.0, red, fill * 0.45)

# A filled ground ellipse (a circle squashed onto the floor) — soft fill, no rim.
func _zone_circle(radius: float, col: Color, fill: float) -> void:
	var pts := PackedVector2Array()
	var n: int = 30
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		pts.append(Vector2(cos(a) * radius, sin(a) * radius * Palette.SQUASH))
	_danger.draw_colored_polygon(pts, Color(col.r, col.g, col.b, fill))

# The danger wash only appears for the final stretch of the wind-up (and the strike),
# so it flashes in just before the blow instead of lingering the whole telegraph. The
# bomber is exempt: its whole tell is a circle you must clear, so it shows throughout.
func _zone_live() -> bool:
	if _dead:
		return false
	if _phase == A_STRIKE:
		return true
	if _phase == A_WINDUP:
		if kind == "bomber":
			return true
		return _phase_t <= _windup * 0.45
	return false

# How far the lunge carries, in screen px, so the lane matches the actual reach.
func _lunge_reach() -> float:
	return _lunge_speed * _strike_time + _hit_range

# The bomber's blast radius (screen px).
func _bomb_radius() -> float:
	return 74.0

# Abandon any wind-up/strike (parry interrupt, or a fresh stun).
func _cancel_attack() -> void:
	if _phase == A_CHASE:
		return
	_phase = A_CHASE
	_phase_t = 0.0
	_did_hit = false
	if _warn != null:
		_warn.visible = false
		_warn.modulate.a = 0.0
	if _danger != null:               # wipe the threat marker the instant it's cancelled
		_zone_shown = false
		_danger.queue_redraw()

# Spawn an arcing blast toward a marked ground spot (lobber).
func _spawn_lob(target: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var lob := Lob.new(global_position + Vector2(0.0, -20.0), target, _dmg(), _warn_col)
	parent.add_child(lob)

# Idle/chase/attack turnaround animation, driven off the phase + velocity.
func _process(delta: float) -> void:
	if _dead or _sprite == null:
		return
	match _phase:
		A_WINDUP:
			# Coil back: gather before the blow.
			var w: float = 1.0 - clampf(_phase_t / maxf(_windup, 0.001), 0.0, 1.0)
			_sprite.scale = Vector2(_base_scale.x * (1.0 - 0.08 * w), _base_scale.y * (1.0 + 0.12 * w))
			_sprite.skew = -0.14 * w * signf(_atk_dir.x if absf(_atk_dir.x) > 0.05 else 1.0)
			_sprite.flip_h = _face_left
		A_STRIKE:
			_sprite.scale = Vector2(_base_scale.x * 1.14, _base_scale.y * 0.9)
			_sprite.skew = 0.14 * signf(_atk_dir.x if absf(_atk_dir.x) > 0.05 else 1.0)
			_sprite.flip_h = _face_left
		_:
			var moving: bool = velocity.length() > 6.0
			_anim_t += delta * (1.0 if moving else 0.6)
			Iso.walk_anim(_sprite, _base_scale, _anim_t, moving, _face_left, 2.2)

# Take a melee hit. from_dir is the attacker's facing (knockback); crit hits pop a
# gold number and shove harder.
func take_damage(n: int, from_dir: Vector2 = Vector2.ZERO, crit: bool = false) -> void:
	if _dead:
		return
	hp -= n
	global_position += from_dir * (11.0 if crit else 6.0)
	Vfx.hit_spark(get_parent(), global_position)
	# Floating damage number so hits read as landing, gold on a crit.
	var up: Vector2 = Vector2(0.0, -30.0 * Palette.ACTOR_SCALE)
	Vfx.float_text(get_parent(), global_position + up, str(n),
		Palette.GOLD_L if crit else Palette.WHITE)
	if hp <= 0:
		_die(from_dir)
	else:
		_flash()

# Parried: freeze in place for `secs`, tinted cold, unable to chase or attack.
func stun(secs: float) -> void:
	if _dead:
		return
	_stun_t = maxf(_stun_t, secs)
	_cancel_attack()
	if _flash_tw != null and _flash_tw.is_valid():
		_flash_tw.kill()
	if _sprite != null:
		_sprite.modulate = Palette.CYAN
	Vfx.float_text(get_parent(), global_position + Vector2(0.0, -30.0 * Palette.ACTOR_SCALE),
		"stun", Palette.CYAN)

# Shoved outward (parry counter / finisher). Instant position push along the floor.
func shove(dir: Vector2, px: float) -> void:
	if _dead:
		return
	global_position += Iso.offset(dir, px)

# Death: unhook from combat, throw a crunch + husk-ash burst, and dissolve the
# body (a smear of shadow pulled sideways) before freeing.
func _die(from_dir: Vector2) -> void:
	_dead = true
	_stun_t = 0.0
	remove_from_group("enemy")
	set_physics_process(false)
	velocity = Vector2.ZERO
	if _warn != null:
		_warn.visible = false
	if _danger != null:
		_zone_shown = false
		_danger.queue_redraw()
	died.emit(global_position)
	Vfx.crunch(get_parent(), global_position + Vector2(0.0, -30.0 * Palette.ACTOR_SCALE), from_dir)
	Vfx.embers(get_parent(), global_position, 10, Palette.SHADOW.lightened(0.12))
	Vfx.hitstop(self, 0.045)
	Main.shake(0.10)
	if _sprite == null:
		queue_free()
		return
	if _flash_tw != null and _flash_tw.is_valid():
		_flash_tw.kill()
	_sprite.modulate = Palette.WHITE
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate", Palette.SHADOW_D.darkened(0.2), 0.10)
	tw.parallel().tween_property(_sprite, "scale",
		Vector2(_base_scale.x * 1.35, _base_scale.y * 0.5), 0.24) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.24).set_delay(0.06)
	tw.tween_callback(queue_free)

# Brief red hurt-flash that eases back to normal. Kills any in-flight flash first
# so rapid hits keep flashing instead of freezing mid-tween.
func _flash() -> void:
	if _sprite == null:
		return
	# While stunned, keep the cold cyan tint — the hurt-flash would wipe the "frozen"
	# read for the rest of the stun (it's only re-asserted when the stun ends).
	if _stun_t > 0.0:
		return
	if _flash_tw != null and _flash_tw.is_valid():
		_flash_tw.kill()
	_sprite.modulate = Palette.BLOOD
	_flash_tw = create_tween()
	_flash_tw.tween_property(_sprite, "modulate", _base_tint, 0.18)

# ---------------------------------------------------------------------------
# Lobber blast: a marked ground spot + an arcing orb that damages on landing.
# The marker gives the player time to leave the spot (QA F-05 ranged variety).
# ---------------------------------------------------------------------------
class Lob extends Node2D:
	var origin: Vector2
	var target: Vector2
	var dmg: int = 1
	var col: Color = Palette.CYAN
	const TRAVEL := 0.95
	const BLAST := 44.0
	var _t: float = 0.0
	var _orb: Sprite2D = null
	var _mark: Sprite2D = null

	func _init(o: Vector2, t: Vector2, d: int, c: Color) -> void:
		origin = o
		target = t
		dmg = d
		col = c

	func _ready() -> void:
		position = Vector2.ZERO
		# Ground-target warning marker at the landing spot.
		_mark = Sprite2D.new()
		_mark.texture = Assets.tex("glow_ring")
		var mm := CanvasItemMaterial.new()
		mm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_mark.material = mm
		_mark.global_position = target
		_mark.modulate = Color(0.98, 0.20, 0.15, 0.7)   # a red danger circle at the landing spot
		var mk: float = (BLAST * 2.0) / 128.0
		_mark.scale = Vector2(mk, mk * Palette.SQUASH)
		_mark.z_index = 1
		add_child(_mark)
		# The orb itself.
		_orb = Sprite2D.new()
		_orb.texture = Assets.tex("ember")
		_orb.global_position = origin
		_orb.modulate = Color(col.r * 1.4, col.g * 1.4, col.b * 1.4, 1.0)
		_orb.scale = Vector2(Palette.PX * 2.2, Palette.PX * 2.2)
		_orb.z_index = 60
		add_child(_orb)

	func _process(delta: float) -> void:
		_t += delta / TRAVEL
		if _t >= 1.0:
			_land()
			return
		var flat: Vector2 = origin.lerp(target, _t)
		var height: float = sin(_t * PI) * 74.0   # a real arc, up in screen Y
		if _orb != null:
			_orb.global_position = flat - Vector2(0.0, height)
		if _mark != null:
			_mark.modulate.a = 0.4 + 0.4 * _t   # brighten toward impact

	func _land() -> void:
		var parent := get_parent()
		if parent != null and is_instance_valid(parent):
			Vfx.impact(parent, target, Vector2.RIGHT)
			Vfx.ring(parent, target, BLAST * 1.6, col, 0.4)
			var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
			if player != null and is_instance_valid(player):
				var alive: Variant = player.get("_dead")
				var is_dead: bool = alive != null and bool(alive)
				if not is_dead and Iso.gdist(target, player.global_position) <= BLAST \
						and player.has_method("take_damage"):
					player.call("take_damage", dmg)
		queue_free()
