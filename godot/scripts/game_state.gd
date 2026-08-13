extends Node
## Persistent meta-progression that survives across dungeon runs and village
## visits. This is the single source of truth for resources, the rescued roster,
## the village grid layout, and the Global Warmth Index (GWI).

signal resources_changed
signal roster_changed
signal gwi_changed(value: float)
# The unbanked run satchel changed (loot picked up / banked / forfeited).
signal satchel_changed
# Meta-progression: total Ember XP and the derived Ember Level.
# xp_changed(total, level, xp_into_level, xp_span_of_level); ember_level_up(new_level).
signal xp_changed(total: int, level: int, into: int, span: int)
signal ember_level_up(new_level: int)
# The knowledge Codex gained an entry (QA D-06): a rescue or a first-built invention.
signal codex_changed
# The world has fully rekindled (GWI hit 1.0) — the win state (CRITIQUE B4/A1).
signal game_won
# The UI language changed ("en" | "vi") — the HUD relocalises visible text.
signal lang_changed(lang: String)

# Starter stock: just enough to hand-build the first Cabin (the onboarding
# "lay the first stones yourself" moment). Everything after needs dungeon loot.
var resources := {"wood": 6, "stone": 3, "iron": 0, "food": 0, "seeds": 3}

# Loot gathered on the CURRENT descent but not yet banked. It only merges into
# `resources` on a live return home; a death forfeits most of it. This is what
# turns a run into a gamble instead of a shopping trip (QA F-01).
var satchel: Dictionary = {"wood": 0, "stone": 0, "iron": 0}
# Running tally of the current descent, read by the return/death summary (QA F-02):
# {"rooms", "husks", "rescues": Array[String], "xp_start", "kindle", "blooms"}.
# `kindle`/`blooms` track the run's EMBERGROWTH growth for the summary card (D-01).
var run_stats: Dictionary = {}

# Pillar ids of survivors brought home: "farmer", "smith", "builder", ...
var rescued: Array[String] = []

# Rescue buffs reframed as natural "attunements" — a single source of truth shared
# by the Survivor, Main (re-apply on descent), and the HUD panel. Each maps a rescued
# pillar to the stat buff kind, a display name, a one-line effect, and its element
# (the seam the item-3 elemental progression will grow from).
# Rebalanced toward parity (QA F-28): +50% damage strictly dominated the other two,
# making rescue order a solved problem. All three are now comparable picks.
const ATTUNEMENTS := {
	"farmer":  {"buff": "armor",  "name": "Bramble Ward", "desc": "+2 Max HP",   "element": "Flora"},
	"smith":   {"buff": "damage", "name": "Ember Fang",   "desc": "+25% Damage", "element": "Thermal"},
	"builder": {"buff": "speed",  "name": "Gale Step",     "desc": "+25% Speed",  "element": "Wind"},
}

# Survivors are people, not role-nouns (CRITIQUE A2): a given name each, shared by the
# rescue moment and the villager they become. Proper nouns, so they stay untranslated.
const SURVIVOR_NAMES := {"farmer": "Rowan", "smith": "Bex", "builder": "Malin"}

func survivor_name(p: String) -> String:
	return String(SURVIVOR_NAMES.get(p, p.capitalize()))

# --- Meta-progression: Ember XP → Ember Level (persists across runs) ---
var xp: int = 0
var ember_level: int = 0

# Village grid: Vector2i(cell) -> {"type": String, "built": bool}
var grid: Dictionary = {}

var gwi: float = 0.0   # 0.0 (cold ash) .. 1.0 (full ember radiance)
var won: bool = false  # has the world fully rekindled? (win fires once, CRITIQUE B4)
var run_count: int = 0
var village_seeded: bool = false  # has the opening village layout been placed?
# Half-extent (in cells, Chebyshev) of the tended CLEARING you may build on. The
# world field is large; you spend resources to expand this outward over a run.
var village_radius: int = 2
var tutorial_seen: bool = false   # has the first-visit village onboarding run?
var combat_tutorial_seen: bool = false  # has the first-descent combat intro run?

# The branching map of the CURRENT run (a RunMap; untyped so this autoload never
# depends on the class resolving first). Main generates it on descent.
var run_map = null

# One-time contextual tutorial tips already shown (key -> true), so each activity
# is taught exactly once, the moment the player first meets it.
var tips_seen: Dictionary = {}

# Quest state per rescued pillar: "new" (not yet offered) → "active" → "done".
var quests: Dictionary = {}

# The farm is gated on the FARMER (VISION: knowledge is carried by people). Rescuing
# the Farmer lays out fallow ground from his knowledge; the hero then supplies the
# materials he lacks to break it. "none" (no Farmer yet) → "fallow" (laid out, awaiting
# 6 wood + 4 seeds) → "active" (worked, producing food + Provisions).
var farm_state: String = "none"

# Recovered-knowledge Codex (QA D-06): ids from Lore.ENTRIES the player has unlocked.
# The framing entry is known from the start; inventions unlock as they're recovered.
var codex: Array[String] = ["ember"]

# UI language: "en" (English) or "vi" (Tiếng Việt). Read by Loc.t everywhere text is
# shown; toggled with L. Persisted to a tiny standalone settings file (independent of
# the not-yet-built game save, F-07), so the choice survives a relaunch.
var lang: String = "en"

# --- Accessibility + audio settings (CRITIQUE B6), persisted with the language ---
var volume: float = 0.85          # master audio level 0..1
var muted: bool = false
var high_contrast: bool = false   # bolder, outlined attack telegraphs (low-vision aid)
var colorblind: bool = false      # swap red danger zones for a high-luminance orange
const SETTINGS_PATH := "user://settings.cfg"

func _ready() -> void:
	_setup_input()
	_load_settings()

# Register input actions in code so the project does not depend on the fragile
# project.godot [input] serialisation format.
func _setup_input() -> void:
	_key_action("move_up", [KEY_W, KEY_UP])
	_key_action("move_down", [KEY_S, KEY_DOWN])
	_key_action("move_left", [KEY_A, KEY_LEFT])
	_key_action("move_right", [KEY_D, KEY_RIGHT])
	_key_action("interact", [KEY_E])
	_key_action("build_menu", [KEY_B])
	_key_action("cancel", [KEY_ESCAPE])
	_key_action("dash", [KEY_SPACE])
	_key_action("map", [KEY_TAB])
	_key_action("character", [KEY_C])   # toggle the character / progression panel
	_key_action("codex", [KEY_K])       # toggle the knowledge Codex ("the Ember's memories")
	_key_action("lang", [KEY_L])        # cycle the UI language (English / Tiếng Việt)
	# Combat is on the mouse: left swings, right guards.
	_mouse_action("attack", MOUSE_BUTTON_LEFT)
	_mouse_action("defend", MOUSE_BUTTON_RIGHT)

func _key_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _mouse_action(action: String, button: int) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var mb := InputEventMouseButton.new()
	mb.button_index = button
	InputMap.action_add_event(action, mb)

# --- Resources ---
func add_resource(kind: String, amount: int) -> void:
	resources[kind] = int(resources.get(kind, 0)) + amount
	resources_changed.emit()

func amount(kind: String) -> int:
	return int(resources.get(kind, 0))

func can_afford(costs: Dictionary) -> bool:
	for k in costs:
		if int(resources.get(k, 0)) < int(costs[k]):
			return false
	return true

func spend(costs: Dictionary) -> bool:
	if not can_afford(costs):
		return false
	for k in costs:
		resources[k] = int(resources.get(k, 0)) - int(costs[k])
	resources_changed.emit()
	return true

# --- Roster ---
func add_rescued(pillar: String) -> void:
	if pillar in rescued:
		return
	rescued.append(pillar)
	roster_changed.emit()
	# A rescued survivor carries their craft home — recover its knowledge (D-06/F-08).
	unlock_codex(String(Lore.PILLAR_ENTRY.get(pillar, "")))

func has_rescued(pillar: String) -> bool:
	return pillar in rescued

# --- Knowledge Codex (QA D-06) ---
# Unlock a Codex entry; returns true only if it was newly recovered (so callers can
# fire the one-time Ember line + fanfare). Empty/duplicate ids are no-ops.
func unlock_codex(id: String) -> bool:
	if id == "" or id in codex:
		return false
	codex.append(id)
	codex_changed.emit()
	return true

func has_codex(id: String) -> bool:
	return id in codex

# How many BUILT buildings of a type stand in the village (drives the village→run
# boons, QA D-02). Counts the seeded starter bed too — a crop bed is a crop bed.
func building_count(build_type: String) -> int:
	var n: int = 0
	for key in grid.keys():
		var d: Dictionary = grid[key]
		if bool(d.get("built", false)) and String(d.get("type", "")) == build_type:
			n += 1
	return n

# Total LEVELS of a built building type (VILLAGE_DESIGN P2/V6): a Lv3 forge counts as
# three, so UPGRADING a building deepens its run-boon — construction keeps mattering
# past the old 3-building ceiling. A building with no recorded level counts as 1.
func building_level_sum(build_type: String) -> int:
	var n: int = 0
	for key in grid.keys():
		var d: Dictionary = grid[key]
		if bool(d.get("built", false)) and String(d.get("type", "")) == build_type:
			n += maxi(1, int(d.get("level", 1)))
	return n

# --- Run satchel (unbanked loot) + run summary ------------------------------

# Start-of-descent reset: empty the satchel and open a fresh tally.
func reset_run() -> void:
	satchel = {"wood": 0, "stone": 0, "iron": 0}
	run_stats = {"rooms": 0, "husks": 0, "rescues": [] as Array, "xp_start": xp,
		"kindle": 0, "blooms": 0}
	satchel_changed.emit()

func satchel_add(kind: String, n: int) -> void:
	satchel[kind] = int(satchel.get(kind, 0)) + n
	satchel_changed.emit()

func satchel_total() -> int:
	var t: int = 0
	for k in satchel:
		t += int(satchel[k])
	return t

# A live return home: merge the satchel into the real stockpile. Returns what banked.
func bank_satchel() -> Dictionary:
	var banked: Dictionary = satchel.duplicate()
	for k in satchel:
		resources[k] = int(resources.get(k, 0)) + int(satchel[k])
	satchel = {"wood": 0, "stone": 0, "iron": 0}
	resources_changed.emit()
	satchel_changed.emit()
	return banked

# Death: salvage a fraction of the satchel, lose the rest. Returns {"kept","lost"}.
# Rounds on the satchel TOTAL, not per-material, then distributes the salvage — so a
# small early-game satchel still yields *something* instead of flooring each kind to
# zero (QA F-33). At least 1 is kept whenever anything was carried.
func forfeit_satchel(keep_frac: float = 0.25) -> Dictionary:
	var total: int = satchel_total()
	var keep_total: int = int(round(float(total) * keep_frac))
	if total > 0:
		keep_total = maxi(1, keep_total)
	var kept: Dictionary = {"wood": 0, "stone": 0, "iron": 0}
	var lost: Dictionary = {"wood": 0, "stone": 0, "iron": 0}
	var remaining: int = keep_total
	for k in ["wood", "stone", "iron"]:
		var have: int = int(satchel.get(k, 0))
		var save: int = mini(have, remaining)
		remaining -= save
		kept[k] = save
		lost[k] = have - save
		resources[k] = int(resources.get(k, 0)) + save
	satchel = {"wood": 0, "stone": 0, "iron": 0}
	resources_changed.emit()
	satchel_changed.emit()
	return {"kept": kept, "lost": lost}

# --- Ember XP / levels -------------------------------------------------------
# Cumulative XP required to REACH a given level. Slowed ~2.7x from the first pass
# (QA F-29: levels were falling every ~3 kills, so "LEVEL UP!" stopped meaning
# anything and the per-level heal deleted attrition). Increments 32, 64, 96, …
func _cum(level: int) -> int:
	return 16 * level * (level + 1)

func level_for_xp(total: int) -> int:
	var l: int = 0
	while _cum(l + 1) <= total:
		l += 1
	return l

func xp_floor(level: int) -> int:   # total XP at which `level` began
	return _cum(level)

func xp_ceil(level: int) -> int:    # total XP needed for the next level
	return _cum(level + 1)

# Award Ember XP (husk kills). Rolls up any levels crossed, firing ember_level_up
# once per level so every threshold gets its own celebration, then reports progress.
func add_xp(n: int) -> void:
	if n <= 0:
		return
	xp += n
	var target: int = level_for_xp(xp)
	while ember_level < target:
		ember_level += 1
		ember_level_up.emit(ember_level)
	var into: int = xp - xp_floor(ember_level)
	var span: int = xp_ceil(ember_level) - xp_floor(ember_level)
	xp_changed.emit(xp, ember_level, into, span)

# --- Global Warmth Index ---
func add_gwi(delta: float) -> void:
	set_gwi(gwi + delta)

func set_gwi(v: float) -> void:
	gwi = clampf(v, 0.0, 1.0)
	gwi_changed.emit(gwi)
	# The VISION's payoff (CRITIQUE B4/A1): full warmth means the world has rekindled.
	# Fire the win exactly once — reaching 1.0 used to change a shader uniform and
	# nothing else; now it ends the arc with the Ember's epilogue.
	if gwi >= 1.0 and not won:
		won = true
		game_won.emit()

# --- Soil (meta head-start for the run's succession, PROGRESSION §4.3 / D-01) ---
# Accumulated "humus": a warm, populous village lets each descent begin further up
# the ecological succession instead of from a persistent Ember Level (retired per
# §8.0). Derived — session-only — from the two things that already persist across
# runs: banked warmth (GWI) and settled survivors. Read by Player.begin_run to seed
# the starting Bloom stage, so per-run power scales with the world you've rebuilt.
func soil_value() -> float:
	return clampf(gwi * 0.6 + float(rescued.size()) * 0.05, 0.0, 1.0)

# The succession stage a descent starts at, given current Soil (0..2). A cold, empty
# world starts at Ash (0); a warm, populated one begins as high as Herb (2).
func soil_start_stage() -> int:
	return mini(2, int(floor(soil_value() * 2.0)))

# --- Language / settings (standalone persistence, independent of F-07) ---

# Set the UI language ("en"|"vi"), announce it, and persist the choice. No-op if
# unchanged. `toggle_lang` flips between the two for the L key.
func set_lang(new_lang: String) -> void:
	var l: String = "vi" if new_lang == "vi" else "en"
	if l == lang:
		return
	lang = l
	_save_settings()
	lang_changed.emit(lang)

func toggle_lang() -> void:
	set_lang("en" if lang == "vi" else "vi")

# Load persisted settings on boot. First run has no file: default the language to
# Vietnamese when the OS locale is Vietnamese, else English.
func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		lang = "vi" if String(cfg.get_value("ui", "lang", "en")) == "vi" else "en"
		volume = clampf(float(cfg.get_value("ui", "volume", 0.85)), 0.0, 1.0)
		muted = bool(cfg.get_value("ui", "muted", false))
		high_contrast = bool(cfg.get_value("ui", "high_contrast", false))
		colorblind = bool(cfg.get_value("ui", "colorblind", false))
	else:
		lang = "vi" if OS.get_locale().begins_with("vi") else "en"
	apply_audio_settings()

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)   # keep any other keys already stored
	cfg.set_value("ui", "lang", lang)
	cfg.set_value("ui", "volume", volume)
	cfg.set_value("ui", "muted", muted)
	cfg.set_value("ui", "high_contrast", high_contrast)
	cfg.set_value("ui", "colorblind", colorblind)
	cfg.save(SETTINGS_PATH)

# Push the audio settings onto the Master bus (Sfx plays through it). Safe to call any
# time — the Master bus always exists.
func apply_audio_settings() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		bus = 0
	AudioServer.set_bus_mute(bus, muted or volume <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(volume, 0.0001, 1.0)))

# Setters used by the settings screen: mutate, persist, apply.
func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	apply_audio_settings()
	_save_settings()

func set_muted(m: bool) -> void:
	muted = m
	apply_audio_settings()
	_save_settings()

func set_high_contrast(on: bool) -> void:
	high_contrast = on
	_save_settings()

func set_colorblind(on: bool) -> void:
	colorblind = on
	_save_settings()

# --- Game save / load (CRITIQUE B2 / F-07) ----------------------------------
# All meta-progression that should survive a quit. Run-scoped state (satchel,
# run_stats, run_map) is deliberately excluded — those only live during a descent.
# We serialise with var_to_str, which round-trips Vector2i grid keys and nested
# dictionaries safely, so the whole snapshot is one human-readable file.
const SAVE_PATH := "user://save.dat"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"resources": resources, "rescued": rescued, "grid": grid,
		"gwi": gwi, "won": won, "run_count": run_count,
		"village_seeded": village_seeded, "village_radius": village_radius,
		"tutorial_seen": tutorial_seen, "combat_tutorial_seen": combat_tutorial_seen,
		"quests": quests, "codex": codex, "farm_state": farm_state,
		"tips_seen": tips_seen,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(var_to_str(data))
		f.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	f.close()
	var data: Variant = str_to_var(txt)
	if not (data is Dictionary):
		return false
	var d: Dictionary = data
	resources = d.get("resources", resources)
	rescued = _as_str_array(d.get("rescued", []))
	grid = d.get("grid", {})
	gwi = float(d.get("gwi", 0.0))
	won = bool(d.get("won", false))
	run_count = int(d.get("run_count", 0))
	village_seeded = bool(d.get("village_seeded", false))
	village_radius = maxi(2, int(d.get("village_radius", 2)))
	tutorial_seen = bool(d.get("tutorial_seen", false))
	combat_tutorial_seen = bool(d.get("combat_tutorial_seen", false))
	quests = d.get("quests", {})
	codex = _as_str_array(d.get("codex", ["ember"]))
	farm_state = String(d.get("farm_state", "none"))
	tips_seen = d.get("tips_seen", {})
	# Re-announce loaded state so the HUD repaints (safe if listeners aren't wired yet).
	resources_changed.emit()
	roster_changed.emit()
	gwi_changed.emit(gwi)
	return true

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

# Coerce a loaded untyped Array into the Array[String] fields expect.
func _as_str_array(a: Variant) -> Array[String]:
	var out: Array[String] = []
	if a is Array:
		for x in a:
			out.append(String(x))
	return out

# Wipe all meta-progression back to a fresh start (New Game).
func reset_all() -> void:
	resources = {"wood": 6, "stone": 3, "iron": 0, "food": 0, "seeds": 3}
	satchel = {"wood": 0, "stone": 0, "iron": 0}
	run_stats = {}
	rescued = [] as Array[String]
	grid = {}
	gwi = 0.0
	won = false
	run_count = 0
	village_seeded = false
	village_radius = 2
	tutorial_seen = false
	combat_tutorial_seen = false
	quests = {}
	codex = ["ember"] as Array[String]
	farm_state = "none"
	tips_seen = {}
	xp = 0
	ember_level = 0
	run_map = null
	resources_changed.emit()
	roster_changed.emit()
	gwi_changed.emit(gwi)
