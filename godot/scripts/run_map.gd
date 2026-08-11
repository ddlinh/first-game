class_name RunMap
extends RefCounted
## The branching map of a single dungeon run — a Cult-of-the-Lamb node graph.
##
## Nodes are laid out in LAYERS (depth 1..N). Layer 0 is the entrance room, the
## last layer is a single boss. Each node has a TYPE that decides what the room
## spawns. `forward[id]` lists the nodes reachable from `id` — the branches. The
## player sits on `current`; clearing that room lets them pick one of `reachable()`.
##
## Pure data + generation; the Dungeon reads a node's type to build the room, the
## exit gates offer the reachable nodes, and the HUD draws the whole graph on Tab.

# id -> { "layer": int, "type": String }
var nodes: Dictionary = {}
# id -> Array[int] of forward (next-layer) node ids
var forward: Dictionary = {}
# Array[Array[int]] — node ids grouped by layer, for layout and linking
var by_layer: Array = []
# The room the player is currently in (-1 before a run starts).
var current: int = -1
# Nodes already visited this run (for dimming on the map).
var visited: Dictionary = {}
var layers: int = 5

# Room types and how often the middle layers roll them.
const WEIGHTED := ["combat", "combat", "combat", "treasure", "rest"]

func generate(layer_count: int = 5) -> void:
	layers = maxi(3, layer_count)
	nodes.clear()
	forward.clear()
	by_layer.clear()
	visited.clear()
	var next_id: int = 0

	# Layer 0: the single entrance room (combat + the run's caged survivor).
	nodes[next_id] = {"layer": 0, "type": "combat"}
	forward[next_id] = [] as Array
	by_layer.append([next_id] as Array)
	next_id += 1

	for L in range(1, layers):
		var row: Array = []
		var count: int = 1 if L == layers - 1 else randi_range(2, 3)
		for i in range(count):
			var t: String = "boss" if L == layers - 1 else WEIGHTED[randi_range(0, WEIGHTED.size() - 1)]
			nodes[next_id] = {"layer": L, "type": t}
			forward[next_id] = [] as Array
			row.append(next_id)
			next_id += 1
		by_layer.append(row)

	# Guarantee one rescue somewhere in the middle so a run can always add a pillar.
	_ensure_type("rescue")
	# Assign each rescue node a concrete survivor up front, so the gate preview,
	# the run map and the room all show the SAME captive (QA F-16).
	for id: int in nodes:
		if String(nodes[id]["type"]) == "rescue":
			nodes[id]["pillar"] = _fresh_pillar()
	# Wire every layer to the next: proximity links, with full coverage + branching.
	for L in range(layers - 1):
		_link(by_layer[L], by_layer[L + 1])

	current = by_layer[0][0]
	visited[current] = true

# Force at least one node of `t` into a middle layer if none rolled.
func _ensure_type(t: String) -> void:
	for id: int in nodes:
		if String(nodes[id]["type"]) == t:
			return
	var L: int = randi_range(1, maxi(1, layers - 2))
	var row: Array = by_layer[L]
	var pick: int = row[randi_range(0, row.size() - 1)]
	nodes[pick]["type"] = t

# Connect nodes in layer `a` to layer `b`: each a-node reaches the nearest 1-2
# b-nodes, and every b-node is guaranteed at least one incoming edge.
func _link(a: Array, b: Array) -> void:
	var covered: Dictionary = {}
	for i in range(a.size()):
		var na: int = a[i]
		var ratio: float = float(i) / maxf(1.0, float(a.size() - 1))
		var j: int = int(round(ratio * float(b.size() - 1)))
		var targets: Array = [b[j]]
		if b.size() > 1 and randf() < 0.5:
			var j2: int = clampi(j + (1 if randf() < 0.5 else -1), 0, b.size() - 1)
			if j2 != j:
				targets.append(b[j2])
		for tgt: int in targets:
			if not forward[na].has(tgt):
				forward[na].append(tgt)
			covered[tgt] = true
	for bid: int in b:
		if not covered.has(bid):
			var na2: int = a[randi_range(0, a.size() - 1)]
			if not forward[na2].has(bid):
				forward[na2].append(bid)

# The nodes the player may descend into next (empty after the boss).
func reachable() -> Array:
	if current < 0:
		return [] as Array
	return forward.get(current, [] as Array)

# Commit to a reachable node.
func choose(id: int) -> void:
	if id in reachable():
		current = id
		visited[id] = true

# A survivor pillar not yet brought home, so a rescue always offers someone new.
func _fresh_pillar() -> String:
	var all: Array[String] = ["farmer", "smith", "builder"]
	var fresh: Array[String] = []
	for p: String in all:
		if not GameState.has_rescued(p):
			fresh.append(p)
	var pool: Array[String] = fresh if not fresh.is_empty() else all
	return pool[randi_range(0, pool.size() - 1)]

func type_of(id: int) -> String:
	return String(nodes.get(id, {}).get("type", "combat"))

# The survivor caged at a rescue node (empty for non-rescue nodes).
func pillar_of(id: int) -> String:
	return String(nodes.get(id, {}).get("pillar", ""))

func layer_of(id: int) -> int:
	return int(nodes.get(id, {}).get("layer", 0))

func at_boss() -> bool:
	return current >= 0 and layer_of(current) == layers - 1

func node_count() -> int:
	return nodes.size()
