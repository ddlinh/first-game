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
var speed: float = 235.0               # follow speed — must beat the hero's so they keep up

# Internal freed flag (see header note re: the signal name clash).
var _freed: bool = false

# --- Tunables ---
const INTERACT_RADIUS: float = 34.0    # how close the player must be to press E
const FOLLOW_DISTANCE: float = 40.0    # stop closing in once within this range
const BODY_RADIUS: float = 9.0         # collision circle radius (world px)

# --- Child nodes (built in _ready) ---
var _body: Sprite2D = null             # the survivor sprite
var _cage: Sprite2D = null             # steel-bar overlay, removed on free
var _base_scale: Vector2 = Vector2.ONE  # body scale the walk cycle squashes around
var _anim_t: float = 0.0               # walk/idle cycle phase
var _face_left: bool = false           # turnaround: which way the survivor reads

func _ready() -> void:
	add_to_group("interactable")
	_build_children()

# Build sprite + cage overlay + collision from code.
func _build_children() -> void:
	# Contact shadow under the whole thing (cage included).
	Iso.shadow(self, 46.0 * Palette.ACTOR_SCALE, 0.42)

	# Body sprite, with a farmer fallback if the pillar key is unknown.
	_body = Sprite2D.new()
	var key: String = "survivor_" + pillar
	if not Assets.has(key):
		key = "survivor_farmer"
	_body.texture = Assets.tex(key)
	add_child(_body)
	_base_scale = Iso.mount_body(_body, 5.0)

	# Cage overlay drawn on top; freed later removes it. Anchored the same way so
	# the bars land around the captive rather than floating off-scale.
	_cage = Sprite2D.new()
	_cage.texture = Assets.tex("cage")
	_cage.z_index = 1
	add_child(_cage)
	Iso.mount_body(_cage, 5.0)

	# Physics body. While caged it is INERT — no layer, no mask — so the hero passes
	# through it freely; colliding a moving body against a caged one made the tight
	# camera jitter. Freeing it (free_it) turns collision back on for wall-following.
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = BODY_RADIUS
	col.shape = shape
	add_child(col)
	collision_layer = 0
	collision_mask = 0

# ---------------------------------------------------------------------------
# Interaction protocol (see DESIGN.md "Interaction protocol")
# ---------------------------------------------------------------------------
func interact_radius() -> float:
	return INTERACT_RADIUS

func can_interact(by: Node) -> bool:
	# Only a still-caged survivor can be freed.
	return not _freed

func interact_prompt() -> String:
	return Loc.t("Free %s  [E]") % Loc.t(pillar)

func do_interact(by: Node) -> void:
	free_it(by)

# ---------------------------------------------------------------------------
# Freeing
# ---------------------------------------------------------------------------
func free_it(by: Node) -> void:
	if _freed:
		return
	_freed = true

	# Remove the cage.
	if is_instance_valid(_cage):
		_cage.queue_free()
	_cage = null

	# Now that it moves, collide with walls only (layer 2 / mask 1) — never with the
	# hero (who is layer 1, mask 5), so following never shoves or jitters the player.
	collision_layer = 2
	collision_mask = 1

	# Trail the rescuer from now on — and join "companion" so Main carries this node
	# across room transitions (it trails through the rest of the run, then settles at
	# home) rather than being freed with the old dungeon layer.
	follow_target = by as Node2D
	add_to_group("companion")

	# No longer offer a prompt.
	remove_from_group("interactable")

	# First rescue of this pillar grants the permanent attunement; a duplicate (all
	# pillars already home) hands over supplies instead of re-stacking a buff — the
	# old exploit that let +damage stack every rescue room (QA F-09).
	var already: bool = GameState.has_rescued(pillar)
	GameState.add_rescued(pillar)   # dedups the roster itself
	if not already:
		var buff: String = _buff_for_pillar(pillar)
		if buff != "" and by.has_method("apply_buff"):
			by.call("apply_buff", buff, true)   # true → raise the "attunement gained" banner
			Main.banner(Loc.t("Attunement: %s") % Loc.t(_attune_name(pillar)), Loc.t(_attune_desc(pillar)), Palette.MOSS_L)
		if GameState.run_stats.has("rescues"):
			(GameState.run_stats["rescues"] as Array).append(pillar)
	else:
		GameState.satchel_add("iron", 2)
		GameState.satchel_add("stone", 2)
		Main.banner("Supplies recovered", "+2 iron  ·  +2 stone", Palette.GOLD_L)

	# Signature ember burst + announce the rescue.
	Vfx.embers(get_parent(), global_position, 24, Palette.EMBER)
	freed.emit(pillar)

# Map a pillar role to the buff kind / display copy, via the shared attunement table.
func _buff_for_pillar(p: String) -> String:
	var a: Dictionary = GameState.ATTUNEMENTS.get(p, {})
	return String(a.get("buff", ""))

func _attune_name(p: String) -> String:
	return String(GameState.ATTUNEMENTS.get(p, {}).get("name", p))

func _attune_desc(p: String) -> String:
	return String(GameState.ATTUNEMENTS.get(p, {}).get("desc", ""))

# ---------------------------------------------------------------------------
# Following
# ---------------------------------------------------------------------------
func _physics_process(_delta: float) -> void:
	# Caged survivors don't move.
	if not _freed:
		return

	# If the target vanished, stand still.
	if not is_instance_valid(follow_target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Close the gap to the rescuer in GROUND space (never egg-shaped, QA F-10), and
	# keep pace with a buffed hero — follow speed tracks the hero's live speed so a
	# Gale Step cat can't outrun the escort (QA F-12).
	var gd: float = Iso.gdist(global_position, follow_target.global_position)
	var follow_speed: float = speed
	var hb: Variant = follow_target.get("base_speed")
	var hm: Variant = follow_target.get("speed_mult")
	if hb != null and hm != null:
		follow_speed = maxf(speed, float(hb) * float(hm) * 1.15)
	# Hopelessly far (a long dash, a wall detour, off-screen) → snap in behind the hero.
	if gd > 340.0:
		global_position = follow_target.global_position + Iso.offset(Vector2.DOWN, FOLLOW_DISTANCE)
		velocity = Vector2.ZERO
	elif gd > FOLLOW_DISTANCE:
		velocity = Iso.step(global_position, follow_target.global_position, follow_speed)
		var dx: float = follow_target.global_position.x - global_position.x
		if absf(dx) > 2.0:
			_face_left = dx < 0.0
	else:
		velocity = Vector2.ZERO
	move_and_slide()

# Turnaround + walk cycle, only once freed — a caged captive stays still under the
# bars so the overlay never drifts off the body.
func _process(delta: float) -> void:
	if not _freed:
		# Teach the rescue the first time the hero gets near a caged captive.
		var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and Iso.gdist(global_position, pl.global_position) < 80.0:
			Main.tip("rescue", "A captive! Stand close and press E to free them — they'll follow you home to join the village.")
		return
	var moving: bool = velocity.length() > 6.0
	_anim_t += delta * (1.0 if moving else 0.6)
	Iso.walk_anim(_body, _base_scale, _anim_t, moving, _face_left)
