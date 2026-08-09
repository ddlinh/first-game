class_name Survivor
extends CharacterBody2D
## A captured survivor found in the dungeon. Starts caged and interactable; once
## the player frees it, it grants a run buff, is logged in the roster, and trails
## the player home. Self-builds its children in _ready() (code-first convention).
##
## NOTE: DESIGN.md lists BOTH a var `freed` and a `signal freed(pillar)`. GDScript
## forbids a var and a signal sharing a name, so the public signal keeps the exact
## contract name `freed` and the internal boolean state is `_freed`. See concerns.

# Fired once when the player frees this survivor. `pillar` is the survivor's role.
signal freed(pillar: String)

# --- Public state (pillar is set by the spawner BEFORE adding to the tree) ---
var pillar: String = "farmer"          # "farmer" | "smith" | "builder"
var follow_target: Node2D = null       # who this survivor trails once freed
var speed: float = 165.0               # follow move speed (world px/s)

# Internal freed flag (see header note re: the signal name clash).
var _freed: bool = false

# --- Tunables ---
const INTERACT_RADIUS: float = 34.0    # how close the player must be to press E
const FOLLOW_DISTANCE: float = 40.0    # stop closing in once within this range
const BODY_RADIUS: float = 9.0         # collision circle radius (world px)

# --- Child nodes (built in _ready) ---
var _body: Sprite2D = null             # the survivor sprite
var _cage: Sprite2D = null             # steel-bar overlay, removed on free
var _shadow: Sprite2D = null           # contact shadow
var _anim: ActorAnim = null            # procedural idle/walk motion

func _ready() -> void:
	add_to_group("interactable")
	_build_children()

# Build sprite + cage overlay + collision from code.
func _build_children() -> void:
	_shadow = Iso.shadow(self, 33.0, 0.40)

	# Body sprite, with a farmer fallback if the pillar key is unknown.
	_body = Sprite2D.new()
	var key: String = "survivor_" + pillar
	if not Assets.has(key):
		key = "survivor_farmer"
	_body.texture = Assets.tex(key)
	_body.scale = Vector2(Palette.ACTOR_PX, Palette.ACTOR_PX)
	add_child(_body)
	Iso.anchor_feet(_body, 4.0)

	# Cage overlay drawn on top; freed later removes it.
	_cage = Sprite2D.new()
	_cage.texture = Assets.tex("cage")
	_cage.scale = Vector2(Palette.ACTOR_PX, Palette.ACTOR_PX)
	_cage.z_index = 1
	add_child(_cage)
	Iso.anchor_feet(_cage, 4.0)

	# A caged survivor still breathes — the idle bob is what stops them reading
	# as scenery, and it is the first hint that there is somebody in there.
	_anim = ActorAnim.new(_body, _shadow)
	_anim.bob = 2.4

	# Physics body collision (default layers/masks per the contract).
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = BODY_RADIUS
	col.shape = shape
	add_child(col)

# ---------------------------------------------------------------------------
# Interaction protocol (see DESIGN.md "Interaction protocol")
# ---------------------------------------------------------------------------
func interact_radius() -> float:
	return INTERACT_RADIUS

func can_interact(by: Node) -> bool:
	# Only a still-caged survivor can be freed.
	return not _freed

func interact_prompt() -> String:
	return "Free %s  [E]" % pillar

func do_interact(by: Node) -> void:
	free_it(by)

# ---------------------------------------------------------------------------
# Freeing
# ---------------------------------------------------------------------------
func free_it(by: Node) -> void:
	if _freed:
		return
	_freed = true

	# The cage breaks apart rather than disappearing: it flies up, spins off and
	# fades, and throws stone chips as it goes.
	if is_instance_valid(_cage):
		var cage := _cage
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(cage, "position:y", cage.position.y - 34.0, 0.34) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(cage, "rotation", randf_range(-0.6, 0.6), 0.34)
		tw.tween_property(cage, "scale", cage.scale * 1.2, 0.34)
		tw.tween_property(cage, "modulate:a", 0.0, 0.34)
		tw.chain().tween_callback(cage.queue_free)
	_cage = null
	Vfx.debris(get_parent(), global_position + Vector2(0.0, -26.0), "chip_stone", 10)

	# Trail the rescuer from now on.
	follow_target = by as Node2D

	# No longer offer a prompt.
	remove_from_group("interactable")

	# Persist the rescue and grant the matching run buff to the rescuer.
	GameState.add_rescued(pillar)
	var buff: String = _buff_for_pillar(pillar)
	if buff != "" and by.has_method("apply_buff"):
		by.call("apply_buff", buff)

	# The emotional beat of the whole loop, so it gets the biggest effect in the
	# game: a wave of embers, a light that fills the chamber, and a screen flash.
	var at: Vector2 = global_position + Vector2(0.0, -26.0)
	Vfx.embers(get_parent(), at, 34, Palette.EMBER)
	Vfx.shockwave(get_parent(), global_position, 130.0, Palette.GOLD_L, 0.55)
	Vfx.light_pop(get_parent(), global_position, Palette.TORCH, 320.0, 1.0)
	Vfx.glint(get_parent(), at, Palette.GOLD_L)
	Vfx.float_text(get_parent(), at + Vector2(0.0, -20.0), pillar.to_upper() + " FREED",
			Palette.GOLD)
	Juice.shake(6.0, 0.40)
	Juice.flash(Palette.TORCH, 0.30, 0.55)
	if _anim != null:
		_anim.punch(0.34)
	freed.emit(pillar)

# Map a pillar role to the buff kind the rescuer receives.
func _buff_for_pillar(p: String) -> String:
	match p:
		"farmer":
			return "armor"
		"smith":
			return "damage"
		"builder":
			return "speed"
	return ""

# ---------------------------------------------------------------------------
# Following
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if _anim != null:
		_anim.tick(delta, velocity)

func _physics_process(_delta: float) -> void:
	# Caged survivors don't move.
	if not _freed:
		velocity = Vector2.ZERO
		return

	# If the target vanished, stand still.
	if not is_instance_valid(follow_target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Close the gap to the rescuer, but idle once near enough.
	var to_target: Vector2 = follow_target.global_position - global_position
	if to_target.length() > FOLLOW_DISTANCE:
		velocity = to_target.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
