class_name Enemy
extends CharacterBody2D
## A husk that hunts the player through a ruin chamber. Builds its own sprite,
## shadow and collision in _ready(), chases the nearest node in group "player",
## and deals contact damage on a short cooldown. Varied via configure().
##
## REACTION IS THE POINT
## A husk that only loses a number when hit reads as a health bar with legs.
## Every hit here produces: a white blow-out frame, a squash, real knockback that
## decays (not a teleport), and an ash puff. Death releases the ember trapped in
## its chest — the one warm thing about it — which is the game's whole premise
## played out in two seconds.

# Fired once, on death, with the world position where the husk fell.
signal died(pos: Vector2)

# --- Tunable stats. configure() overwrites these; they are read in _ready() so
# it is safe to set them before OR after the node is added. ---
var max_hp: int = 4
var speed: float = 72.0
var touch_damage: int = 1
var tex_key: String = "enemy_husk"

# --- Runtime state ---
var hp: int = 0
var _touch_cd: float = 0.0
var _dead: bool = false
var _sprite: Sprite2D = null
var _shadow: Sprite2D = null
var _anim: ActorAnim = null
var _flash_tw: Tween = null
var _knock: Vector2 = Vector2.ZERO    # decaying knockback impulse
var _stagger: float = 0.0             # seconds of lost control after a hit

const KNOCK_DECAY := 340.0            # px/s^2 the shove bleeds off at
const STAGGER_TIME := 0.16

func _ready() -> void:
	_shadow = Iso.shadow(self, 32.0, 0.40)

	_sprite = Sprite2D.new()
	_sprite.texture = Assets.tex(tex_key)
	_sprite.scale = Vector2(Palette.ACTOR_PX, Palette.ACTOR_PX)
	add_child(_sprite)
	Iso.anchor_feet(_sprite, 4.0)

	_anim = ActorAnim.new(_sprite, _shadow)
	_anim.bob = 2.6           # husks shamble; they don't bounce like the hero
	_anim.lean_max = 0.10

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	add_child(shape)

	hp = max_hp
	add_to_group("enemy")

# Vary this husk. Safe before the node is built (values are stored and applied in
# _ready) or after (sprite + hp are refreshed immediately).
func configure(hp: int, speed: float, tex_key: String) -> void:
	max_hp = hp
	self.speed = speed
	self.tex_key = tex_key
	self.hp = max_hp
	if _sprite != null:
		_sprite.texture = Assets.tex(tex_key)
		Iso.anchor_feet(_sprite, 4.0)

func _process(delta: float) -> void:
	if _anim != null:
		_anim.tick(delta, velocity)

func _physics_process(delta: float) -> void:
	if _touch_cd > 0.0:
		_touch_cd -= delta
	if _stagger > 0.0:
		_stagger -= delta

	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		velocity = _knock
		move_and_slide()
		_knock = _knock.move_toward(Vector2.ZERO, KNOCK_DECAY * delta)
		return

	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()
	# Staggered husks are shoved, not steering — that is what sells the hit.
	if _stagger > 0.0:
		velocity = _knock
	elif dist > 0.001:
		velocity = to_player.normalized() * speed + _knock
	else:
		velocity = _knock
	move_and_slide()
	_knock = _knock.move_toward(Vector2.ZERO, KNOCK_DECAY * delta)

	if dist < 22.0 and _touch_cd <= 0.0 and not _dead:
		if player.has_method("take_damage"):
			player.call("take_damage", touch_damage)
			_touch_cd = 0.8
			# The husk lunges as it connects, so contact damage has an author.
			if _anim != null:
				_anim.punch(0.24)
			Vfx.dust(get_parent(), global_position, 3)

## Take a melee hit. `impulse` is an already-scaled knockback vector (the
## attacker's direction times its knockback strength).
func take_damage(n: int, impulse: Vector2 = Vector2.ZERO) -> void:
	if _dead:
		return
	hp -= n
	_hurt_flash()
	_knock += impulse * 26.0
	_stagger = STAGGER_TIME
	if _anim != null:
		_anim.punch(0.30)

	Vfx.float_text(get_parent(), global_position + Vector2(0.0, -42.0), str(n), Palette.AMBER)
	Vfx.ash_burst(get_parent(), global_position + Vector2(0.0, -20.0), 5)

	if hp <= 0:
		_die(impulse)

func _die(impulse: Vector2) -> void:
	_dead = true
	remove_from_group("enemy")
	died.emit(global_position)

	var at: Vector2 = global_position + Vector2(0.0, -22.0)
	# The body goes to ash...
	Vfx.ash_burst(get_parent(), at, 20)
	Vfx.dust(get_parent(), global_position, 7)
	Vfx.shockwave(get_parent(), global_position, 62.0, Palette.HUSK, 0.34, "ring_soft")
	# ...and the ember it was carrying gets out. This is the game's premise in
	# two seconds, so it is deliberately the warmest thing in the frame.
	Vfx.embers(get_parent(), at, 14, Palette.EMBER)
	Vfx.light_pop(get_parent(), global_position, Palette.TORCH, 150.0, 0.55)
	Juice.hitstop(0.055)
	Juice.shake(6.0, 0.24)

	# Collapse rather than vanish: a short blow-out-and-shrink, then free.
	if _sprite != null and is_instance_valid(_sprite):
		if _flash_tw != null and _flash_tw.is_valid():
			_flash_tw.kill()
		_sprite.modulate = Color(2.4, 2.0, 1.8, 1.0)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_sprite, "scale",
				Vector2(_sprite.scale.x * 1.25, _sprite.scale.y * 0.30), 0.16) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(_sprite, "modulate:a", 0.0, 0.16)
		if _shadow != null and is_instance_valid(_shadow):
			tw.tween_property(_shadow, "modulate:a", 0.0, 0.16)
		tw.chain().tween_callback(queue_free)
	else:
		queue_free()

	# Stop steering and animating while the corpse plays out.
	set_physics_process(false)
	set_process(false)

# A one-frame white blow-out reading as the flash of contact, easing back
# through the hurt red. Kills any in-flight flash so rapid hits keep popping.
func _hurt_flash() -> void:
	if _sprite == null:
		return
	if _flash_tw != null and _flash_tw.is_valid():
		_flash_tw.kill()
	_sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	_flash_tw = create_tween()
	_flash_tw.tween_property(_sprite, "modulate", Palette.BLOOD, 0.06)
	_flash_tw.tween_property(_sprite, "modulate", Color(1, 1, 1, 1), 0.20)
