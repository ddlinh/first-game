extends Node
## Persistent meta-progression that survives across dungeon runs and village
## visits. This is the single source of truth for resources, the rescued roster,
## the village grid layout, and the Global Warmth Index (GWI).

signal resources_changed
signal roster_changed
signal gwi_changed(value: float)

# Starter stock: just enough to hand-build the first Cabin (the onboarding
# "lay the first stones yourself" moment). Everything after needs dungeon loot.
var resources := {"wood": 6, "stone": 3, "iron": 0, "food": 0, "seeds": 3}

# Pillar ids of survivors brought home: "farmer", "smith", "builder", ...
var rescued: Array[String] = []

# Village grid: Vector2i(cell) -> {"type": String, "built": bool}
var grid: Dictionary = {}

var gwi: float = 0.0   # 0.0 (cold ash) .. 1.0 (full ember radiance)
var run_count: int = 0
var village_seeded: bool = false  # has the opening village layout been placed?

func _ready() -> void:
	_setup_input()

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
	# Dash: Shift for the left hand on WASD, Space as the familiar alternative.
	_key_action("dash", [KEY_SHIFT, KEY_SPACE])
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", mb)

func _key_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

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

func has_rescued(pillar: String) -> bool:
	return pillar in rescued

# --- Global Warmth Index ---
func add_gwi(delta: float) -> void:
	set_gwi(gwi + delta)

func set_gwi(v: float) -> void:
	gwi = clampf(v, 0.0, 1.0)
	gwi_changed.emit(gwi)
