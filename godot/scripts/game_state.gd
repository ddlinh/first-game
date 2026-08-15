extends Node
## Persistent meta-progression that survives across dungeon runs and village
## visits. This is the single source of truth for resources, the rescued roster,
## the village grid layout, and the Global Warmth Index (GWI).

signal resources_changed
signal roster_changed
signal gwi_changed(value: float)
# The unbanked run satchel changed (loot picked up / banked / forfeited).
signal satchel_changed
# The knowledge Codex gained an entry (QA D-06): a rescue or a first-built invention.
signal codex_changed
# The world has fully rekindled (GWI hit 1.0) — the win state (CRITIQUE B4/A1).
signal game_won
# The settlement's population changed (a wanderer settled in) — the HUD updates its readout.
signal population_changed
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

# Generic townsfolk drawn to the warmth, beyond the named survivors you rescue (VILLAGE_
# DESIGN P4/P5). A fed, housed village attracts them over time; a larger population warms
# the world and gives later descents a head-start (see soil_value).
var settlers: int = 0

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

# One line of WHO each survivor is — the person behind the craft (people are the reward,
# VISION / CRITIQUE A2). The rescue moment gives their reactive line (Survivor.LINES); this
# is the quieter characterisation, read at leisure beside their attunement on the character
# sheet. Kept in the Ember's register so the roster reads as lives carried home, not stats.
const SURVIVOR_LORE := {
	"farmer": "Rowan kept the seed-vault through the long winters. He planted the last handful rather than eat it — that is the whole of him.",
	"smith": "Bex learned the forge from her mother, who learned it from hers. She reads a fire's colour the way you read a face.",
	"builder": "Malin raised half this village the first time. She still walks the old foundations at night, naming rooms that aren't there yet.",
}

func survivor_name(p: String) -> String:
	return String(SURVIVOR_NAMES.get(p, p.capitalize()))

func survivor_lore(p: String) -> String:
	return String(SURVIVOR_LORE.get(p, ""))

# Village grid: Vector2i(cell) -> {"type": String, "built": bool, "level": int, "orient": int}
# `orient` (M8) is the building's facing: +1 default, -1 mirrored (flip_h). Old saves and
# freshly-placed entries without the key read as +1.
var grid: Dictionary = {}

# Player-expression cosmetic layer (M8 / VILLAGE_DESIGN §6): a GWI-NEUTRAL sibling of `grid`.
# `paths` is the set of cells with a laid path tile; `props` is the placed craft-gated
# decorations. NOTHING here grants warmth, boons, or caps — it only dresses the town, so
# the skyline stays an honest résumé. Serialised with the save (Vector2i round-trips).
#   paths: Array[Vector2i]
#   props: Array[{ "id": String, "cell": Vector2i, "orient": int }]
var decor: Dictionary = {"paths": [], "props": []}

var gwi: float = 0.0   # 0.0 (cold ash) .. 1.0 (full ember radiance)
var won: bool = false  # has the world fully rekindled? (win fires once, CRITIQUE B4)
var run_count: int = 0
# The deepest single descent reached, in chambers (CRITIQUE N4). Post-win this is the
# record the endless "deep ruins" chase is built around: once won, each descent runs one
# layer deeper than this best, so victory has somewhere to go instead of a maxed sandbox.
var deepest_run: int = 0
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
# materials he lacks to break it, and later funds irrigation. "none" (no Farmer yet) →
# "fallow" (awaiting 6 wood + 4 seeds) → "active" (worked) → "irrigated" (his follow-up
# project: faster/richer crops + more Provisions on descent).
var farm_state: String = "none"

# Recovered-knowledge Codex (QA D-06): ids from Lore.ENTRIES the player has unlocked.
# The framing entry is known from the start; inventions unlock as they're recovered.
var codex: Array[String] = ["ember"]
# Entries the player has actually READ (opened the Codex on), separate from merely unlocked.
# Reading a new memory grants a little warmth — knowledge = warmth, the game's thesis (A6).
var codex_read: Array[String] = []

# Ruins story fragments already discovered (indices into Lore.RUINS_FRAGMENTS), so each
# "you find…" beat is shown once ever and the descent keeps revealing new ones (A3).
var ruins_found: Array[int] = []

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
	_key_action("rotate", [KEY_R])      # flip a building/decoration's facing while placing it (M8)
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
# Storage economy (VILLAGE_DESIGN P5): raw stockpiles are capped, so a surplus is a real
# decision — raise Granaries to store more, or watch banked loot spill and be lost. Seeds
# are a farm currency and stay uncapped.
const RESOURCE_CAP_BASE := 50
const STORAGE_PER_GRANARY := 30
const CAPPED := {"wood": true, "stone": true, "iron": true, "food": true}

func storage_cap() -> int:
	return RESOURCE_CAP_BASE + STORAGE_PER_GRANARY * building_count("granary")

func is_capped_resource(kind: String) -> bool:
	return CAPPED.has(kind)

func add_resource(kind: String, amount: int) -> void:
	var existing: int = int(resources.get(kind, 0))
	var total: int = existing + amount
	# Positive gains for a capped resource may only fill UP TO the ceiling; the overflow is
	# lost (P5's "build storage or waste surplus" pressure). The ceiling is max(cap, existing)
	# so a gain never REDUCES a stockpile that was already over cap (e.g. a migrated save) —
	# a gain must never shrink your stores. Teach the fix once, and only when a Granary is
	# actually buildable (the Builder is home), so the advice is never a dead end.
	if amount > 0 and CAPPED.has(kind):
		var ceiling: int = maxi(storage_cap(), existing)
		if total > ceiling:
			total = ceiling
			if has_rescued("builder"):
				Main.tip("storage_full", "Your stores are brimming — surplus is being lost. Raise a Granary to stockpile more.")
	resources[kind] = total
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

# --- Village stakes: cold snaps (VILLAGE_DESIGN P6) ---
# Returning from a run, the cold can strike the settlement — the one pressure that pushes
# warmth DOWN, so defensive building finally has a purpose (V9: warmth used to only ever
# rise). Watchtowers ward it; about three hold it off entirely. Never before the village is
# established (gwi ≥ 0.25), never once the world is rekindled. Reported on the run-summary card.
const COLD_SNAP_CHANCE := 0.30
const COLD_SNAP_DROP := 0.08
const COLD_SNAP_FLOOR := 0.15
var last_cold_snap: Dictionary = {}   # run-scoped; the summary card reads + reports it

func maybe_cold_snap() -> Dictionary:
	if won or gwi < 0.25:
		return {"hit": false}
	if randf() > COLD_SNAP_CHANCE:
		return {"hit": false}
	var towers: int = building_count("watchtower")
	var mitigation: float = clampf(float(towers) / 3.0, 0.0, 1.0)
	var drop: float = COLD_SNAP_DROP * (1.0 - mitigation)
	var before: float = gwi
	if drop > 0.001:
		set_gwi(maxf(COLD_SNAP_FLOOR, gwi - drop))
	return {"hit": true, "drop": before - gwi, "towers": towers, "warded": mitigation >= 0.999}

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

# How many unlocked entries the player hasn't opened yet (drives the "new memory" cue, A6).
func codex_unread() -> int:
	var n: int = 0
	for id in codex:
		if not (id in codex_read):
			n += 1
	return n

# Mark every unlocked-but-unread entry as read; returns how many were newly read, so the
# caller can grant the one-time warmth reward for actually reading them.
func mark_codex_read() -> int:
	var newly: int = 0
	for id in codex:
		if not (id in codex_read):
			codex_read.append(id)
			newly += 1
	return newly

# --- Ruins story fragments (CRITIQUE A3) ---
# A random still-undiscovered fragment index, or -1 when the player has found them all.
func next_ruins_fragment() -> int:
	var pool: Array[int] = []
	for i in range(Lore.RUINS_FRAGMENTS.size()):
		if not (i in ruins_found):
			pool.append(i)
	if pool.is_empty():
		return -1
	return pool[randi() % pool.size()]

func mark_ruins_found(idx: int) -> void:
	if idx >= 0 and not (idx in ruins_found):
		ruins_found.append(idx)

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

# --- Living settlement: population & housing (VILLAGE_DESIGN P4/P5) ---
# Everyone who lives here: the named survivors you rescued plus the settlers they drew in.
func residents() -> int:
	return rescued.size() + settlers

# Housing capacity: the hearth shelters the founding survivors (base 3, one per pillar);
# each Cabin LEVEL houses two more (a Lv3 cabin is a longhouse for six). Population can
# never exceed this — so attracting settlers needs Cabins, tying housing to growth.
func housing_cap() -> int:
	return 3 + building_level_sum("cabin") * 2

# A wanderer settles in, if there is room. Returns true only if the town actually grew.
func add_settler() -> bool:
	if residents() >= housing_cap():
		return false
	settlers += 1
	population_changed.emit()
	return true

# --- Run satchel (unbanked loot) + run summary ------------------------------

# Start-of-descent reset: empty the satchel and open a fresh tally.
func reset_run() -> void:
	satchel = {"wood": 0, "stone": 0, "iron": 0}
	run_stats = {"rooms": 0, "husks": 0, "rescues": [] as Array,
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

# A live return home: merge the satchel into the real stockpile THROUGH the storage cap
# (VILLAGE_DESIGN P5) — banked loot is the main channel, so it must spill at the ceiling like
# every other gain. Returns what actually landed (cap-limited), so the summary reads true.
func bank_satchel() -> Dictionary:
	var banked: Dictionary = {}
	for k in satchel:
		var before: int = int(resources.get(k, 0))
		add_resource(k, int(satchel[k]))
		banked[k] = int(resources.get(k, 0)) - before
	satchel = {"wood": 0, "stone": 0, "iron": 0}
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
		# Salvage banks through the cap too; anything over the ceiling counts as lost.
		var before: int = int(resources.get(k, 0))
		add_resource(k, save)
		kept[k] = int(resources.get(k, 0)) - before
		lost[k] = have - kept[k]
	satchel = {"wood": 0, "stone": 0, "iron": 0}
	satchel_changed.emit()
	return {"kept": kept, "lost": lost}

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
	return clampf(gwi * 0.6 + float(rescued.size()) * 0.05 + float(settlers) * 0.02, 0.0, 1.0)

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

# Peek the save for the title's Continue affordance (CRITIQUE N5) — run count, roster
# size, warmth, and when it was written — without loading it over live state. Empty if
# there is no readable save.
func save_summary() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var data: Variant = str_to_var(txt)
	if not (data is Dictionary):
		return {}
	var d: Dictionary = data
	return {
		"run_count": int(d.get("run_count", 0)),
		"rescued": _as_str_array(d.get("rescued", [])).size(),
		"settlers": int(d.get("settlers", 0)),
		"gwi": float(d.get("gwi", 0.0)),
		"saved_at": int(d.get("saved_at", 0)),
		"won": bool(d.get("won", false)),
		"deepest_run": int(d.get("deepest_run", 0)),
	}

func save_game() -> void:
	var data := {
		"resources": resources, "rescued": rescued, "settlers": settlers, "grid": grid,
		"gwi": gwi, "won": won, "run_count": run_count, "deepest_run": deepest_run,
		"village_seeded": village_seeded, "village_radius": village_radius,
		"tutorial_seen": tutorial_seen, "combat_tutorial_seen": combat_tutorial_seen,
		"quests": quests, "codex": codex, "codex_read": codex_read, "farm_state": farm_state,
		"tips_seen": tips_seen, "ruins_found": ruins_found, "decor": decor,
		# When this snapshot was written, so the title's Continue can say how long ago (N5).
		"saved_at": int(Time.get_unix_time_from_system()),
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
	settlers = int(d.get("settlers", 0))
	grid = d.get("grid", {})
	gwi = float(d.get("gwi", 0.0))
	won = bool(d.get("won", false))
	run_count = int(d.get("run_count", 0))
	deepest_run = int(d.get("deepest_run", 0))
	village_seeded = bool(d.get("village_seeded", false))
	village_radius = maxi(2, int(d.get("village_radius", 2)))
	tutorial_seen = bool(d.get("tutorial_seen", false))
	combat_tutorial_seen = bool(d.get("combat_tutorial_seen", false))
	quests = d.get("quests", {})
	codex = _as_str_array(d.get("codex", ["ember"]))
	codex_read = _as_str_array(d.get("codex_read", []))
	ruins_found = _as_int_array(d.get("ruins_found", []))
	farm_state = String(d.get("farm_state", "none"))
	tips_seen = d.get("tips_seen", {})
	decor = _coerce_decor(d.get("decor", {}))
	# Re-announce loaded state so the HUD repaints (safe if listeners aren't wired yet).
	resources_changed.emit()
	roster_changed.emit()
	population_changed.emit()
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

# Same, for the Array[int] fields (ruins_found).
func _as_int_array(a: Variant) -> Array[int]:
	var out: Array[int] = []
	if a is Array:
		for x in a:
			out.append(int(x))
	return out

# Coerce a loaded decor blob into the {paths:[], props:[]} shape — old saves lack the key,
# so a missing/garbled value degrades to an empty, valid cosmetic layer (M8).
func _coerce_decor(v: Variant) -> Dictionary:
	var out: Dictionary = {"paths": [], "props": []}
	if v is Dictionary:
		if (v as Dictionary).get("paths") is Array:
			out["paths"] = ((v as Dictionary)["paths"] as Array).duplicate()
		if (v as Dictionary).get("props") is Array:
			out["props"] = ((v as Dictionary)["props"] as Array).duplicate()
	return out

# Wipe all meta-progression back to a fresh start (New Game).
func reset_all() -> void:
	resources = {"wood": 6, "stone": 3, "iron": 0, "food": 0, "seeds": 3}
	satchel = {"wood": 0, "stone": 0, "iron": 0}
	run_stats = {}
	rescued = [] as Array[String]
	settlers = 0
	grid = {}
	decor = {"paths": [], "props": []}
	gwi = 0.0
	won = false
	run_count = 0
	deepest_run = 0
	village_seeded = false
	village_radius = 2
	tutorial_seen = false
	combat_tutorial_seen = false
	quests = {}
	codex = ["ember"] as Array[String]
	codex_read = [] as Array[String]
	ruins_found = [] as Array[int]
	farm_state = "none"
	tips_seen = {}
	run_map = null
	resources_changed.emit()
	roster_changed.emit()
	gwi_changed.emit(gwi)
