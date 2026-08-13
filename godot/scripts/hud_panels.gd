class_name HudPanels
extends RefCounted
## Informational overlay panels, split out of the Hud god-object (CRITIQUE C3): the
## character / progression sheet (C), the knowledge Codex (K), and the full run map (Tab).
## All are NON-modal toggled overlays built under the Hud's `_root`. Owned by the Hud, which
## delegates toggle_*() and calls refresh_character() / close_overlays() / relocalize() at
## the right moments. Behaviour is identical to the old in-Hud code; only the state and
## builders moved. `_hud` is untyped to stay off a circular class_name dependency.

var _hud = null
var _char_panel: PanelContainer = null     # toggled character / progression sheet
var _codex_panel: Control = null
var _map_root: Control = null              # full-screen dim + graph, toggled by Tab
var _map_canvas: Control = null            # the Control whose _draw renders the graph

func _init(hud) -> void:
	_hud = hud

# --- Integration points the Hud calls -----------------------------------------
# Keep an open character sheet live as Kindle streams in and the hero blooms.
func refresh_character() -> void:
	if _char_panel != null and is_instance_valid(_char_panel):
		_populate_character()

# On a layer swap (set_combat): a run-map / Codex left open must not hang across it (F-25).
func close_overlays() -> void:
	if _map_root != null:
		_map_root.visible = false
	if _codex_panel != null and is_instance_valid(_codex_panel):
		_codex_panel.queue_free()
		_codex_panel = null

# Language changed: rebuild the open character sheet and Codex in the new language.
func relocalize() -> void:
	if _char_panel != null and is_instance_valid(_char_panel):
		_populate_character()
	if _codex_panel != null and is_instance_valid(_codex_panel):
		toggle_codex()   # close…
		toggle_codex()   # …and rebuild in the new language

# --- Character / progression sheet (C) ----------------------------------------
func toggle_character() -> void:
	if _char_panel != null and is_instance_valid(_char_panel):
		_char_panel.queue_free()
		_char_panel = null
		return
	_char_panel = UiKit.panel()
	_char_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	_char_panel.position = Vector2(20, 0)
	UiKit.ignore(_char_panel)
	_hud._root.add_child(_char_panel)
	_populate_character()

func _populate_character() -> void:
	if _char_panel == null or not is_instance_valid(_char_panel):
		return
	for c in _char_panel.get_children():
		c.queue_free()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	vb.custom_minimum_size = Vector2(210, 0)
	UiKit.ignore(vb)
	_char_panel.add_child(vb)
	vb.add_child(UiKit.label("THE KINDLED", 16, Palette.EMBER))
	# Succession (run-scoped) + Soil (the meta head-start the next descent begins at).
	var hero: Node = _hud.get_tree().get_first_node_in_group("player")
	var stage: int = int(hero.get("kindle_stage")) if hero != null and is_instance_valid(hero) else 0
	vb.add_child(UiKit.label(Loc.t("Succession   %s  (stage %d)")
		% [Loc.t(_hud.STAGE_LABELS[clampi(stage, 0, _hud.STAGE_LABELS.size() - 1)]), stage], 14, Palette.GOLD_L))
	vb.add_child(UiKit.label(Loc.t("Soil head-start   stage %d") % GameState.soil_start_stage(), 13, Palette.MOSS_L))
	# Live combat stats, read straight off the persistent hero.
	if hero != null and is_instance_valid(hero):
		var mhp: int = int(hero.get("max_hp"))
		var bdmg: int = int(hero.get("base_damage"))
		var dmul: float = float(hero.get("damage_mult"))
		var smul: float = float(hero.get("speed_mult"))
		var critv: Variant = hero.get("crit_chance")
		var critc: float = float(critv) if critv != null else 0.22
		var dmg: int = int(round(float(bdmg) * dmul))
		for line in [
			Loc.t("Max HP        %d") % mhp,
			Loc.t("Damage        %d  (x%.2f)") % [dmg, dmul],
			Loc.t("Move Speed    %d%%") % int(round(smul * 100.0)),
			Loc.t("Crit Chance   %d%%") % int(round(critc * 100.0)),
		]:
			vb.add_child(UiKit.label(line, 14, Palette.UI_TEXT))
		# Boons drafted this run (the build identity — empty in the village).
		var blist: Variant = hero.get("boons")
		if blist is Array and not (blist as Array).is_empty():
			vb.add_child(UiKit.label("Boons", 14, Palette.EMBER))
			var counts: Dictionary = {}
			for bid in (blist as Array):
				counts[bid] = int(counts.get(bid, 0)) + 1
			for bid in counts:
				var nm: String = Loc.t(_hud._boon_name(String(bid)))
				var c: int = int(counts[bid])
				vb.add_child(UiKit.label("• %s%s" % [nm, ("  x%d" % c) if c > 1 else ""], 13, Palette.UI_TEXT))
		# Provisions carried this run (the farm's yield — Agriculture, QA D-02).
		var pv: Variant = hero.get("provisions")
		if pv != null and int(pv) > 0:
			vb.add_child(UiKit.label(Loc.t("Provisions   x%d  (auto-heal when hurt)") % int(pv), 13, Palette.MOSS_L))
	# Attunements earned (rescued survivors), by element.
	vb.add_child(UiKit.label("Attunements", 14, Palette.EMBER))
	if GameState.rescued.is_empty():
		vb.add_child(UiKit.label("—  none yet", 13, Palette.UI_DIM))
	else:
		for pillar in GameState.rescued:
			var a: Dictionary = GameState.ATTUNEMENTS.get(pillar, {})
			var nm: String = Loc.t(String(a.get("name", pillar)))
			var ds: String = Loc.t(String(a.get("desc", "")))
			var el: String = Loc.t(String(a.get("element", "")))
			vb.add_child(UiKit.label("• %s  (%s) — %s" % [nm, el, ds], 13, Palette.UI_TEXT))
	vb.add_child(UiKit.label("[C] close    ·    [K] Codex", 12, Palette.UI_DIM))

# --- The knowledge Codex (K) — "the Ember's memories" (QA D-06) ----------------
func toggle_codex() -> void:
	if _codex_panel != null and is_instance_valid(_codex_panel):
		_codex_panel.queue_free()
		_codex_panel = null
		return
	_codex_panel = Control.new()
	_codex_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_codex_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud._root.add_child(_codex_panel)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_codex_panel.add_child(cc)
	var card := UiKit.panel()
	cc.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 9)
	col.custom_minimum_size = Vector2(516, 0)
	UiKit.ignore(col)
	card.add_child(col)
	col.add_child(UiKit.label("THE EMBER'S MEMORIES", 21, Palette.EMBER))
	col.add_child(UiKit.label(Loc.t("Recovered knowledge   %d / %d") % [GameState.codex.size(), Lore.ENTRIES.size()],
		13, Palette.UI_DIM))
	# Which unlocked entries are new to the player THIS open (before we mark them read),
	# so the fresh memories carry a "new" tag (A6).
	var unread: Dictionary = {}
	for id0 in GameState.codex:
		if not GameState.codex_read.has(id0):
			unread[id0] = true
	for e: Dictionary in Lore.ENTRIES:
		var id: String = String(e.get("id", ""))
		var known: bool = GameState.has_codex(id)
		var head: String = ("%s      %s" % [Loc.t(String(e.get("title", ""))), Loc.t(String(e.get("era", "")))]) if known else "? ? ?"
		if known and unread.has(id):
			head += "     ✦ " + Loc.t("new")
		col.add_child(UiKit.label(head, 16, Palette.GOLD_L if known else Palette.UI_DIM))
		var body: Label = UiKit.label(
			String(e.get("fact", "")) if known else "Undiscovered — rescue this craft's survivor, or raise their building.",
			13, Palette.UI_TEXT if known else Palette.UI_DIM)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD
		body.custom_minimum_size = Vector2(500, 0)
		col.add_child(body)
	col.add_child(UiKit.label("[K] close", 12, Palette.UI_DIM))
	# Reading a new memory warms the world a touch — the small mechanical hook the Codex
	# was missing (A6). One-time per entry; knowledge = warmth, on-thesis.
	var newly: int = GameState.mark_codex_read()
	if newly > 0:
		var gain: float = 0.02 * float(newly)
		GameState.add_gwi(gain)
		_hud.toast(Loc.t("You dwell on the memory — the knowing warms the world.  +%d%%") % int(round(gain * 100.0)), Palette.GOLD_L)

# --- The full run map (Tab) ---------------------------------------------------
func toggle_map() -> void:
	var rm = GameState.run_map
	if rm == null:
		_hud.toast("No active run — descend first", Palette.UI_DIM)
		return
	if _map_root == null:
		_build_map_overlay()
	_map_root.visible = not _map_root.visible
	if _map_root.visible and _map_canvas != null:
		_map_canvas.queue_redraw()

func _build_map_overlay() -> void:
	_map_root = Control.new()
	_map_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_root.visible = false
	_hud._root.add_child(_map_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP   # swallow clicks behind the map
	_map_root.add_child(dim)
	_map_canvas = Control.new()
	_map_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_root.add_child(_map_canvas)
	_map_canvas.draw.connect(_draw_map)

# Colour + preview icon per room type (mirrors the gate previews).
func _type_style(t: String) -> Dictionary:
	match t:
		"treasure":
			return {"c": Palette.GOLD, "icon": "material_iron"}
		"rescue":
			return {"c": Palette.MOSS_L, "icon": "survivor_farmer"}
		"rest":
			return {"c": Palette.AMBER, "icon": "ui_flame"}
		"boss":
			return {"c": Palette.WINE, "icon": "enemy_brute"}
		_:
			return {"c": Palette.EMBER, "icon": "enemy_husk"}

# Draw the whole run graph: layers left→right, branches as lines, each node a
# type-coloured disc with its preview icon. Current node gold, reachable cyan,
# unreached dim.
func _draw_map() -> void:
	var rm = GameState.run_map
	if rm == null or _map_canvas == null:
		return
	var canvas: Control = _map_canvas
	var vp: Vector2 = canvas.size
	# Shifted below the top-left HUD panel so the title and labels never clip it.
	var area := Rect2(Vector2(vp.x * 0.5 - 430.0, vp.y * 0.5 - 165.0), Vector2(860.0, 420.0))
	var layers: int = rm.by_layer.size()
	var pad := 80.0
	var positions: Dictionary = {}
	for L in range(layers):
		var row: Array = rm.by_layer[L]
		var x: float = area.position.x + pad + (area.size.x - 2.0 * pad) * (float(L) / maxf(1.0, float(layers - 1)))
		for i in range(row.size()):
			var y: float = area.get_center().y + (float(i) - float(row.size() - 1) * 0.5) * 96.0
			positions[row[i]] = Vector2(x, y)
	# Branches — brighter out of the room you're standing in.
	for id in rm.forward:
		var a: Vector2 = positions[id]
		var live: bool = (int(id) == int(rm.current))
		for tgt in rm.forward[id]:
			var b: Vector2 = positions[tgt]
			canvas.draw_line(a, b, Palette.UI_EDGE if live else Color(1, 1, 1, 0.14), 3.0 if live else 2.0, true)
	# Nodes.
	var reach: Array = rm.reachable()
	var font: Font = ThemeDB.fallback_font
	for id in rm.nodes:
		var pos: Vector2 = positions[id]
		var st: Dictionary = _type_style(rm.type_of(int(id)))
		var is_cur: bool = (int(id) == int(rm.current))
		var is_reach: bool = id in reach
		var active: bool = is_cur or is_reach or rm.visited.has(id)
		var r: float = 32.0 if is_cur else 27.0
		canvas.draw_circle(pos, r + 4.0, Color(0, 0, 0, 0.85))
		canvas.draw_circle(pos, r, Palette.UI_BG2 if active else Color(0.09, 0.08, 0.12, 0.9))
		var ring: Color = Palette.GOLD_L if is_cur else (Palette.CYAN if is_reach else st["c"])
		if not active:
			ring = Color(ring.r, ring.g, ring.b, 0.4)
		canvas.draw_arc(pos, r, 0.0, TAU, 40, ring, 3.5 if (is_cur or is_reach) else 2.5, true)
		var tex: Texture2D = Assets.tex(String(st["icon"]))
		var isz := 36.0
		var aspect: float = float(tex.get_width()) / maxf(1.0, float(tex.get_height()))
		var iw: float = clampf(isz * aspect, 18.0, isz * 1.3)
		canvas.draw_texture_rect(tex, Rect2(pos - Vector2(iw, isz) * 0.5, Vector2(iw, isz)),
			false, Color(1, 1, 1, 1.0 if active else 0.4))
		if is_cur:
			canvas.draw_string(font, pos + Vector2(-55.0, r + 21.0), "YOU ARE HERE",
				HORIZONTAL_ALIGNMENT_CENTER, 110, 13, Palette.GOLD_L)
	canvas.draw_string(font, area.position + Vector2(0.0, -18.0), Loc.t("RUIN  MAP"),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Palette.EMBER)
