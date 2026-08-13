class_name Hud
extends CanvasLayer
## Heads-up display: resource counts, HP pips, the GWI warmth meter, rescued
## roster, the interaction prompt, transient toasts, the build menu, and (on a
## run) the descent-depth banner. Driven by GameState signals; layers call
## toast()/open_build_menu(), Main calls set_hp()/set_depth().
##
## The chrome is the "ornate gilded interface" of the brief: the clusters sit in
## gilded dark panels, the roster rides in medallions, filigree brackets the four
## screen corners, and the baked ui_* iconography (flame, ember seal, medallion,
## corner) is finally wired in. Everything decorative is MOUSE_FILTER_IGNORE so a
## left-click still swings the sword through the HUD.

signal build_selected(id: String)
signal build_cancelled

const RES_ORDER := ["wood", "stone", "iron", "food", "seeds"]
const RES_ICON := {
	"wood": "material_wood", "stone": "material_stone", "iron": "material_iron",
	"food": "material_food", "seeds": "crop_3",
}
# GWI thresholds where the world visibly thaws (mirrors Village._dress_nature). The
# warmth gauge marks these so the player reads warmth as progress toward real, visible
# change — the way a survival/city-builder shows heat/hope milestones (Frostpunk).
const WARMTH_MARKS := [0.12, 0.24, 0.40, 0.58]

var _root: Control
var _res_labels: Dictionary = {}
var _res_chips: Dictionary = {}     # kind -> chip HBox, so a changed stock can pop
var _res_prev: Dictionary = {}      # kind -> last count, to detect gains/spends
var _hp_box: HBoxContainer
var _gwi_fill: ColorRect
var _warmth_pct: Label = null       # "42%" readout beside the WARMTH header
var _warmth_marks: Control = null   # thaw-threshold ticks over the warmth trough
var _gwi_val: float = 0.0           # last GWI, so the mark colours can be repainted
var _flame_icon: TextureRect
var _warmth_label: Label = null     # top-right "WARMTH" header, re-translated on L
var _roster_box: HBoxContainer
var _prompt: Label
var _toast_box: VBoxContainer
var _menu: PanelContainer
var _menu_open: bool = false
var _menu_ids: Array[String] = []
var _place_panel: PanelContainer = null   # "Placing X…" banner while a ghost is up
var _place_label: Label = null
var _depth_panel: PanelContainer
var _depth_label: Label
var _depth_val: int = 0             # last depth, so L can re-translate the banner live
var _objective: Label
var _objective_src: String = ""     # untranslated objective, re-applied on a lang swap
var _controls_card: PanelContainer
var _prev_hp: int = -1

# --- Dialogue / onboarding ("talking" popups) ---
signal dialogue_advanced
var _dlg_panel: PanelContainer
var _dlg_speaker: Label
var _dlg_text: Label
var _dlg_hint: Label
var _dlg_await: bool = false        # true while a line waits for the player
var _dlg_type_tw: Tween = null      # the typewriter reveal, so a click can finish it
# Bumped on every layer swap (set_combat). A scripted intro captures it and bails if
# it changes mid-flow, so a village line can't bleed into the ruin — or vice versa —
# when the player descends before the intro finishes (QA F-25).
var _dlg_gen: int = 0

# --- Run map overlay (Tab) ---
var _map_root: Control = null       # full-screen dim + graph, toggled by Tab
var _map_canvas: Control = null     # the Control whose _draw renders the graph

# --- Contextual tutorial tip (non-blocking Ember line) ---
var _tip_panel: PanelContainer = null
var _tip_label: Label = null
var _tip_tw: Tween = null

# --- Off-screen guidance arrow (points to the current objective) ---
var _guide_arrow: Node2D = null

# --- Context-aware combat HUD ---
const DASH_CD_REF := 0.55           # mirrors Player.DASH_CD (for the dash pip wedge)
const BOSS_FILL_W := 436.0          # inner width of the Warden bar fill
var _combat: bool = false
var _res_panel: PanelContainer = null      # top-left economy chrome (village only)
var _warmth_panel: PanelContainer = null   # top-right warmth + roster (village only)
var _corner_nodes: Array[TextureRect] = [] # the four filigree brackets
var _corner_bl: TextureRect = null         # bottom-left bracket (hidden in combat)
var _vitals_panel: PanelContainer = null   # bottom-left hearts + ability pips
var _foe_chip: PanelContainer = null       # top-left husks-remaining tally
var _foe_count: Label = null
var _foe_prev: int = 999
var _foe_tw: Tween = null                   # the CLEARED-fade, tracked so it can't bleed rooms
var _satchel_panel: PanelContainer = null  # top-left unbanked-loot readout (combat only)
var _satchel_label: Label = null
var _boss_root: Control = null             # top-centre Warden bar + name plate
var _boss_name: Label = null
var _boss_fill: ColorRect = null
var _boss_ghost: ColorRect = null          # lagging "chunk" chip behind the fill
var _boss_active: bool = false
var _boss_max: int = 1
var _boss_ratio: float = 1.0               # live hp fraction (target for the fill)
var _boss_ghost_ratio: float = 1.0         # lagging chip fraction (eases toward live)
var _pips_row: HBoxContainer = null        # dash + riposte pips (combat only)
var _dash_pip: Control = null              # dash-cooldown wedge
var _riposte_pip: Control = null           # perfect-parry riposte-armed cue
var _dash_ratio: float = 1.0               # 1 = dash ready
var _riposte_t: float = 0.0                # remaining riposte window (mirrors _counter_t)
var _pip_t: float = 0.0                    # clock for pip pulses
var _guard_bar: Panel = null               # guard-stamina trough (combat only)
var _guard_meter: ColorRect = null         # its fill (mirrors player.guard_stamina)
var _lowhp_tw: Tween = null                # looping low-health throb

# --- Progression readout: combat = Kindle/succession bar, village = Soil meter ---
const XP_W := 132.0                        # inner width of the progression bar fill
const KINDLE_MAX := 70.0                   # top of the succession track (mirrors Player)
const STAGE_LABELS := ["ASH", "PIONEER", "HERB", "THICKET", "CANOPY"]
var _level_label: Label = null
var _xp_fill: ColorRect = null
var _kindle_notches: Control = null        # stage-boundary ticks over the bar (combat)
var _char_panel: PanelContainer = null     # toggled character / progression sheet
# Level-up banner coalescing: many thresholds crossed on one big kill collapse
# into a single "EMBER LEVEL a → b" card instead of stacking (QA F-25/F-29).
var _lvl_from: int = 0
var _lvl_to: int = 0
var _lvl_armed: bool = false

# --- Title screen + pause menu (CRITIQUE B1) + settings (B6) ---
var _title_root: Control = null
var _pause_root: Control = null
var _settings_root: Control = null
var _place_active: bool = false   # true while a build ghost follows the cursor (Esc = cancel, not pause)
# --- Win screen (CRITIQUE B4/A1): the Ember's epilogue when the world rekindles ---
var _victory_root: Control = null
# --- Boon draft overlay (QA D-01): a paused pick-1-of-3 card raised on each Bloom.
var _boon_root: Control = null
var _boon_cb: Callable = Callable()        # Main's "picked" callback
var _boon_ids: Array[String] = []          # ids in the current offer (for bot picks)

# --- Provisions readout (QA D-02): the farm's heal charges carried into a run ---
var _prov_row: HBoxContainer = null
var _prov_label: Label = null
var _prov_prev: int = -1
# --- Knowledge Codex overlay (QA D-06): "the Ember's memories", toggled with K ---
var _codex_panel: Control = null

func _ready() -> void:
	layer = 10
	_build_ui()
	GameState.resources_changed.connect(_refresh_resources)
	GameState.roster_changed.connect(_refresh_roster)
	GameState.gwi_changed.connect(set_gwi)
	GameState.xp_changed.connect(set_ember)
	GameState.ember_level_up.connect(_on_level_up)
	GameState.satchel_changed.connect(_refresh_satchel)
	GameState.lang_changed.connect(_relocalize)
	_refresh_resources()
	_refresh_roster()
	set_gwi(GameState.gwi)
	# Seed the bottom-left progression bar (village = Soil head-start meter; combat =
	# the live Kindle/succession track, self-polled in _process). QA D-01.
	_refresh_progress_bar()

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_corners()

	# --- Top-left: resources (village economy; hidden in combat) ---
	_res_panel = _panel()
	_res_panel.position = Vector2(12, 10)
	_root.add_child(_res_panel)
	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 10)
	_ignore(res_row)
	_res_panel.add_child(res_row)
	for kind in RES_ORDER:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 3)
		_ignore(chip)
		var icon := TextureRect.new()
		icon.texture = Assets.tex(RES_ICON[kind])
		icon.custom_minimum_size = Vector2(22, 22)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_ignore(icon)
		chip.add_child(icon)
		var lab := _make_label("0", 18, Palette.WHITE)
		chip.add_child(lab)
		_res_labels[kind] = lab
		_res_chips[kind] = chip
		res_row.add_child(chip)

	# --- Top-right: WARMTH gauge + roster (village economy; hidden in combat) ---
	_warmth_panel = _panel()
	_warmth_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_warmth_panel.position = Vector2(-212, 10)
	_root.add_child(_warmth_panel)
	var tr := VBoxContainer.new()
	tr.add_theme_constant_override("separation", 6)
	_ignore(tr)
	_warmth_panel.add_child(tr)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	_ignore(head)
	tr.add_child(head)
	_flame_icon = TextureRect.new()
	_flame_icon.texture = Assets.tex("ui_flame")
	_flame_icon.custom_minimum_size = Vector2(20, 24)
	_flame_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ignore(_flame_icon)
	head.add_child(_flame_icon)
	_warmth_label = _make_label("WARMTH", 13, Palette.AMBER)
	head.add_child(_warmth_label)
	# A live percentage pushed to the right of the header, so warmth reads as a number
	# and not just a bar length.
	var wsp := Control.new()
	wsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ignore(wsp)
	head.add_child(wsp)
	_warmth_pct = _make_label("0%", 13, Palette.GOLD_L)
	head.add_child(_warmth_pct)

	# Framed warmth trough: a gilded panel with the fill inset inside it.
	var bar_frame := Panel.new()
	bar_frame.custom_minimum_size = Vector2(178, 16)
	bar_frame.add_theme_stylebox_override("panel", _trough_style())
	_ignore(bar_frame)
	tr.add_child(bar_frame)
	_gwi_fill = ColorRect.new()
	_gwi_fill.color = Palette.GWI_COLD
	_gwi_fill.position = Vector2(2, 2)
	_gwi_fill.size = Vector2(0, 12)
	_ignore(_gwi_fill)
	bar_frame.add_child(_gwi_fill)
	# Thaw-milestone ticks drawn over the fill: reached = gold, the next one to reach
	# is highlighted, later ones dim — so you can see the next visible thaw coming.
	_warmth_marks = Control.new()
	_warmth_marks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ignore(_warmth_marks)
	bar_frame.add_child(_warmth_marks)
	_warmth_marks.draw.connect(_draw_warmth_marks)

	_roster_box = HBoxContainer.new()
	_roster_box.add_theme_constant_override("separation", 3)
	_ignore(_roster_box)
	tr.add_child(_roster_box)

	# --- Depth banner: top centre, shown only on a run ---
	_depth_panel = _panel()
	_depth_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_depth_panel.position = Vector2(-90, 8)
	_depth_panel.visible = false
	_root.add_child(_depth_panel)
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 8)
	dh.alignment = BoxContainer.ALIGNMENT_CENTER
	_ignore(dh)
	_depth_panel.add_child(dh)
	var seal := TextureRect.new()
	seal.texture = Assets.tex("ui_ember_seal")
	seal.custom_minimum_size = Vector2(26, 26)
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ignore(seal)
	dh.add_child(seal)
	_depth_label = _make_label("RUIN  ·  DEPTH 1", 16, Palette.CYAN)
	dh.add_child(_depth_label)

	# --- Toasts: top-centre stack, below the depth banner ---
	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast_box.position = Vector2(-140, 112)
	_toast_box.custom_minimum_size = Vector2(280, 0)
	_toast_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_ignore(_toast_box)
	_root.add_child(_toast_box)

	# --- Objective line: bottom centre, above the interaction prompt ---
	_objective = _make_label("", 16, Palette.AMBER)
	_objective.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_objective.position = Vector2(-260, -108)
	_objective.custom_minimum_size = Vector2(520, 0)
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective.modulate = Color(1, 1, 1, 0.85)
	_objective.visible = false
	_root.add_child(_objective)

	# --- Interaction prompt: bottom centre ---
	_prompt = _make_label("", 20, Palette.GOLD)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-200, -70)
	_prompt.custom_minimum_size = Vector2(400, 0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	_root.add_child(_prompt)

	# --- Build menu: centre (hidden until opened) ---
	_menu = PanelContainer.new()
	_menu.add_theme_stylebox_override("panel", _menu_style())
	_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_menu.position = Vector2(-198, -300)
	_menu.custom_minimum_size = Vector2(396, 0)
	_menu.visible = false
	_root.add_child(_menu)

	# --- Placement banner: top centre, shown only while a build ghost follows the
	# cursor, so the player always knows what they're dropping and how to commit/cancel.
	_place_panel = _panel()
	_place_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_place_panel.position = Vector2(-200, 48)
	_place_panel.custom_minimum_size = Vector2(400, 0)
	_place_panel.visible = false
	_root.add_child(_place_panel)
	_place_label = _make_label("", 16, Palette.GOLD_L)
	_place_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place_label.custom_minimum_size = Vector2(376, 0)
	_place_panel.add_child(_place_label)

	_build_vitals()
	_build_foe_chip()
	_build_satchel()
	_build_boss_bar()
	_build_dialogue()
	_build_tip()

# Bottom-left VITALS: the hearts row (moved out of the economy panel) with the
# dash + riposte ability pips tucked under them — Hades' life-and-tools corner.
func _build_vitals() -> void:
	_vitals_panel = _panel()
	_vitals_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	# Tall enough for hearts + XP + pips + the guard meter without clipping the
	# bottom edge (QA F-04 meter added a row).
	_vitals_panel.position = Vector2(14, -134)
	_root.add_child(_vitals_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_ignore(v)
	_vitals_panel.add_child(v)
	_hp_box = HBoxContainer.new()
	_hp_box.add_theme_constant_override("separation", 6)
	_ignore(_hp_box)
	v.add_child(_hp_box)
	# Ember Level badge + XP bar (always visible — your growing strength at a glance).
	var xprow := HBoxContainer.new()
	xprow.add_theme_constant_override("separation", 7)
	xprow.alignment = BoxContainer.ALIGNMENT_CENTER
	_ignore(xprow)
	v.add_child(xprow)
	_level_label = _make_label("LV 0", 13, Palette.GOLD_L)
	xprow.add_child(_level_label)
	var trough := Panel.new()
	trough.custom_minimum_size = Vector2(XP_W + 4.0, 9)
	trough.add_theme_stylebox_override("panel", _trough_style())
	_ignore(trough)
	xprow.add_child(trough)
	_xp_fill = ColorRect.new()
	_xp_fill.color = Palette.EMBER
	_xp_fill.position = Vector2(2, 2)
	_xp_fill.size = Vector2(0, 5)
	_ignore(_xp_fill)
	trough.add_child(_xp_fill)
	# Succession stage-boundary ticks over the bar (combat only): the "5 notches" of
	# the Kindle track (QA D-01). Drawn above the fill so the stage you're in reads.
	_kindle_notches = Control.new()
	_kindle_notches.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kindle_notches.visible = false
	_ignore(_kindle_notches)
	trough.add_child(_kindle_notches)
	_kindle_notches.draw.connect(_draw_kindle_notches)
	# Ability pips (shown only in combat via set_combat).
	_pips_row = HBoxContainer.new()
	_pips_row.add_theme_constant_override("separation", 8)
	_pips_row.visible = false
	_ignore(_pips_row)
	v.add_child(_pips_row)
	_dash_pip = Control.new()
	_dash_pip.custom_minimum_size = Vector2(28, 28)
	_ignore(_dash_pip)
	_dash_pip.draw.connect(_draw_dash_pip)
	_pips_row.add_child(_dash_pip)
	_riposte_pip = Control.new()
	_riposte_pip.custom_minimum_size = Vector2(28, 28)
	_ignore(_riposte_pip)
	_riposte_pip.draw.connect(_draw_riposte_pip)
	_pips_row.add_child(_riposte_pip)
	# Guard-stamina meter under the pips (combat only): cyan → amber (low) → red
	# (broken), so the new guard cost is legible (QA F-04).
	_guard_bar = Panel.new()
	_guard_bar.custom_minimum_size = Vector2(64, 7)
	_guard_bar.add_theme_stylebox_override("panel", _trough_style())
	_guard_bar.visible = false
	_ignore(_guard_bar)
	v.add_child(_guard_bar)
	_guard_meter = ColorRect.new()
	_guard_meter.color = Palette.CYAN
	_guard_meter.position = Vector2(2, 2)
	_guard_meter.size = Vector2(60, 3)
	_ignore(_guard_meter)
	_guard_bar.add_child(_guard_meter)
	# Provisions (combat only): the farm's heal charges you carry down (QA D-02). A
	# food icon + count, self-polled; hidden when you carry none.
	_prov_row = HBoxContainer.new()
	_prov_row.add_theme_constant_override("separation", 4)
	_prov_row.visible = false
	_ignore(_prov_row)
	v.add_child(_prov_row)
	var prov_icon := TextureRect.new()
	prov_icon.texture = Assets.tex("material_food")
	prov_icon.custom_minimum_size = Vector2(18, 18)
	prov_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prov_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ignore(prov_icon)
	_prov_row.add_child(prov_icon)
	_prov_label = _make_label("x0", 14, Palette.MOSS_L)
	_prov_row.add_child(_prov_label)

# Top-left HUSK TALLY (combat only): the corner counter the economy chips vacate.
func _build_foe_chip() -> void:
	_foe_chip = _panel()
	_foe_chip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_foe_chip.position = Vector2(14, 12)
	_foe_chip.visible = false
	_root.add_child(_foe_chip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_ignore(row)
	_foe_chip.add_child(row)
	var icon := TextureRect.new()
	icon.texture = Assets.tex("enemy_husk")
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # let custom_minimum_size rule
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(1, 0.6, 0.6, 1)   # a menacing red-tint mini-husk
	_ignore(icon)
	row.add_child(icon)
	_foe_count = _make_label("0", 22, Palette.UI_TEXT)
	row.add_child(_foe_count)

# Top-left SATCHEL readout (combat only): the unbanked loot you stand to lose if
# you fall — sits just under the husk tally so run stakes read at a glance (F-01).
func _build_satchel() -> void:
	_satchel_panel = _panel()
	_satchel_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_satchel_panel.position = Vector2(14, 58)
	_satchel_panel.visible = false
	_root.add_child(_satchel_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_ignore(row)
	_satchel_panel.add_child(row)
	var icon := TextureRect.new()
	icon.texture = Assets.tex("ui_medallion")
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ignore(icon)
	row.add_child(icon)
	_satchel_label = _make_label("loot: empty", 15, Palette.AMBER)
	row.add_child(_satchel_label)

# Refresh the satchel readout from the run's unbanked loot.
func _refresh_satchel(_a := 0) -> void:
	if _satchel_label == null:
		return
	var parts: Array[String] = []
	for k in ["wood", "stone", "iron"]:
		var n: int = int(GameState.satchel.get(k, 0))
		if n > 0:
			parts.append("%d %s" % [n, Loc.t(k)])
	_satchel_label.text = Loc.t("loot: empty") if parts.is_empty() else (Loc.t("loot: %s") % ", ".join(parts))

# Top-centre WARDEN bar + name plate (boss rooms only) — a Hades-style event bar.
func _build_boss_bar() -> void:
	_boss_root = Control.new()
	_boss_root.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_root.visible = false
	_ignore(_boss_root)
	_root.add_child(_boss_root)
	# Name plate: an icon + title centred over the bar (a full-width row so the
	# HBox's own centre-alignment does the horizontal centring for us).
	var plate := HBoxContainer.new()
	plate.add_theme_constant_override("separation", 8)
	plate.alignment = BoxContainer.ALIGNMENT_CENTER
	plate.custom_minimum_size = Vector2(BOSS_FILL_W + 4.0, 26)
	plate.position = Vector2(-(BOSS_FILL_W + 4.0) * 0.5, 18)
	_ignore(plate)
	_boss_root.add_child(plate)
	var bi := TextureRect.new()
	bi.texture = Assets.tex("enemy_brute")
	bi.custom_minimum_size = Vector2(24, 24)
	bi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # let custom_minimum_size rule
	bi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bi.modulate = Color(1, 0.6, 0.6, 1)
	_ignore(bi)
	plate.add_child(bi)
	_boss_name = _make_label("THE WARDEN", 15, Palette.GOLD_L)
	plate.add_child(_boss_name)
	# The bar: a gilded trough with a lagging ghost chip behind the live fill.
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(BOSS_FILL_W + 4.0, 18)
	frame.position = Vector2(-(BOSS_FILL_W + 4.0) * 0.5, 48)
	frame.add_theme_stylebox_override("panel", _trough_style())
	_ignore(frame)
	_boss_root.add_child(frame)
	_boss_ghost = ColorRect.new()
	_boss_ghost.color = Palette.WINE.darkened(0.35)
	_boss_ghost.position = Vector2(2, 2)
	_boss_ghost.size = Vector2(BOSS_FILL_W, 14)
	_ignore(_boss_ghost)
	frame.add_child(_boss_ghost)
	_boss_fill = ColorRect.new()
	_boss_fill.color = Palette.BLOOD
	_boss_fill.position = Vector2(2, 2)
	_boss_fill.size = Vector2(BOSS_FILL_W, 14)
	_ignore(_boss_fill)
	frame.add_child(_boss_fill)

# A small non-blocking Ember tip, bottom-centre above the objective, that teaches
# one activity and fades on its own — safe to fire mid-combat.
func _build_tip() -> void:
	_tip_panel = _panel()
	_tip_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_tip_panel.position = Vector2(-320, -168)
	_tip_panel.custom_minimum_size = Vector2(640, 0)
	_tip_panel.modulate.a = 0.0
	_tip_panel.visible = false
	_root.add_child(_tip_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_ignore(row)
	_tip_panel.add_child(row)
	var seal := TextureRect.new()
	seal.texture = Assets.tex("ui_ember_seal")
	seal.custom_minimum_size = Vector2(30, 30)
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	seal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ignore(seal)
	row.add_child(seal)
	_tip_label = _make_label("", 16, Palette.UI_TEXT)
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.custom_minimum_size = Vector2(560, 0)
	_tip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_tip_label)

# A "talking" dialogue box: a portrait of the Ember, a speaker line, a typewriter
# body, and a continue hint. Sits low-centre; shown only during onboarding.
func _build_dialogue() -> void:
	_dlg_panel = PanelContainer.new()
	_dlg_panel.add_theme_stylebox_override("panel", _menu_style())
	_dlg_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_dlg_panel.position = Vector2(-330, -196)
	_dlg_panel.custom_minimum_size = Vector2(660, 0)
	_dlg_panel.visible = false
	_root.add_child(_dlg_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_ignore(row)
	_dlg_panel.add_child(row)

	var portrait := TextureRect.new()
	portrait.texture = Assets.tex("ui_ember_seal")
	portrait.custom_minimum_size = Vector2(64, 64)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ignore(portrait)
	row.add_child(portrait)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ignore(col)
	row.add_child(col)

	_dlg_speaker = _make_label("The Ember", 15, Palette.EMBER)
	col.add_child(_dlg_speaker)

	_dlg_text = _make_label("", 17, Palette.UI_TEXT)
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.custom_minimum_size = Vector2(540, 44)
	col.add_child(_dlg_text)

	_dlg_hint = _make_label("click  /  E   ▶", 13, Palette.UI_DIM)
	_dlg_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_dlg_hint)

# ---------------------------------------------------------------------------
# Chrome builders
# ---------------------------------------------------------------------------

# Filigree brackets in all four corners; the baked piece is drawn for the top-left
# and rotated a quarter-turn into each of the others.
func _build_corners() -> void:
	var data := [
		[Control.PRESET_TOP_LEFT, Vector2(6, 6), 0.0],
		[Control.PRESET_TOP_RIGHT, Vector2(-50, 6), PI * 0.5],
		[Control.PRESET_BOTTOM_RIGHT, Vector2(-50, -50), PI],
		[Control.PRESET_BOTTOM_LEFT, Vector2(6, -50), PI * 1.5],
	]
	for d in data:
		var tr := TextureRect.new()
		tr.texture = Assets.tex("ui_corner")
		tr.custom_minimum_size = Vector2(44, 44)
		tr.size = Vector2(44, 44)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.pivot_offset = Vector2(22, 22)
		tr.rotation = float(d[2])
		tr.modulate = Color(1, 1, 1, 0.5)
		_ignore(tr)
		_root.add_child(tr)
		tr.set_anchors_and_offsets_preset(int(d[0]))
		tr.position += Vector2(d[1])
		_corner_nodes.append(tr)
		if int(d[0]) == Control.PRESET_BOTTOM_LEFT:
			_corner_bl = tr   # the vitals panel occupies this corner in combat

# A gilded dark panel: the shared container for every HUD cluster.
func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel_style())
	_ignore(p)
	return p

func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Palette.UI_BG.r, Palette.UI_BG.g, Palette.UI_BG.b, 0.82)
	sb.set_border_width_all(2)
	sb.border_color = Palette.UI_EDGE
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 11
	sb.content_margin_right = 11
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 6
	return sb

func _menu_style() -> StyleBoxFlat:
	var sb := _panel_style()
	sb.bg_color = Color(Palette.UI_BG.r, Palette.UI_BG.g, Palette.UI_BG.b, 0.96)
	sb.set_border_width_all(3)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb

func _trough_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.55)
	sb.set_border_width_all(1)
	sb.border_color = Palette.UI_EDGE_D
	sb.set_corner_radius_all(4)
	return sb

func _make_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = Loc.t(text)   # localize every label at its single construction point
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Palette.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# Every decorative control must let the pointer through, or it eats the LMB swing.
func _ignore(c: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

# ---------------------------------------------------------------------------
func _refresh_resources(_a := 0) -> void:
	for kind in RES_ORDER:
		if not _res_labels.has(kind):
			continue
		var lab: Label = _res_labels[kind]
		var val: int = GameState.amount(kind)
		var prev: int = int(_res_prev.get(kind, val))
		lab.text = str(val)
		# Dim a depleted stock so "you're out of X" reads at a glance.
		lab.add_theme_color_override("font_color", Palette.UI_DIM if val == 0 else Palette.WHITE)
		# Pop the chip when the count moves — gold on a gain, ember on a spend — so the
		# economy feels responsive (the farming-sim resource-counter pop).
		if val != prev and _res_chips.has(kind):
			_pop_res_chip(_res_chips[kind], val > prev)
		_res_prev[kind] = val

func _pop_res_chip(chip: Control, gained: bool) -> void:
	if chip == null or not is_instance_valid(chip):
		return
	chip.pivot_offset = chip.size * 0.5
	chip.scale = Vector2(1.35, 1.35)
	var tw := chip.create_tween()
	tw.tween_property(chip, "scale", Vector2.ONE, 0.24) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	chip.modulate = Palette.GOLD_L if gained else Palette.EMBER
	var tw2 := chip.create_tween()
	tw2.tween_property(chip, "modulate", Color(1, 1, 1, 1), 0.4)

func set_hp(hp: int, max_hp: int) -> void:
	if _hp_box == null:
		return
	for c in _hp_box.get_children():
		c.queue_free()
	# Up to 8 hearts render as chunky pips; beyond that (Bramble Ward + levels) the
	# row would overflow the panel and clip under the controls card, so collapse to
	# one heart + a numeric count (QA F-25).
	if max_hp <= 8:
		for i in range(max_hp):
			var pip := Panel.new()
			pip.custom_minimum_size = Vector2(26, 26)   # chunky, cozy hearts
			pip.add_theme_stylebox_override("panel", _pip_style(i < hp))
			_ignore(pip)
			_hp_box.add_child(pip)
	else:
		var heart := Panel.new()
		heart.custom_minimum_size = Vector2(26, 26)
		heart.add_theme_stylebox_override("panel", _pip_style(hp > 0))
		_ignore(heart)
		_hp_box.add_child(heart)
		var lab := _make_label("%d / %d" % [maxi(hp, 0), max_hp], 18, Palette.UI_TEXT)
		_hp_box.add_child(lab)
	# Pop the row when a heart was just lost, so damage lands in the corner of the eye.
	if _prev_hp >= 0 and hp < _prev_hp:
		_hp_box.pivot_offset = _hp_box.size * 0.5
		var tw := _hp_box.create_tween()
		_hp_box.scale = Vector2(1.28, 1.28)
		tw.tween_property(_hp_box, "scale", Vector2.ONE, 0.22) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_prev_hp = hp
	_update_lowhp(hp)

# A slow ember throb on the vitals panel when life is critical (hp <= 2).
func _update_lowhp(hp: int) -> void:
	if _vitals_panel == null:
		return
	var low: bool = hp <= 2 and hp > 0
	if low and (_lowhp_tw == null or not _lowhp_tw.is_valid()):
		_lowhp_tw = _vitals_panel.create_tween().set_loops()
		_vitals_panel.modulate = Palette.WHITE.lerp(Palette.EMBER, 0.4)
		_lowhp_tw.tween_property(_vitals_panel, "modulate:a", 0.72, 0.55).set_trans(Tween.TRANS_SINE)
		_lowhp_tw.tween_property(_vitals_panel, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	elif not low and _lowhp_tw != null and _lowhp_tw.is_valid():
		_lowhp_tw.kill()
		_lowhp_tw = null
		_vitals_panel.modulate = Color(1, 1, 1, 1)

# ---------------------------------------------------------------------------
# Context switch — one HUD, two skins. Village = full economy chrome; ruins =
# a lean combat frame (hearts + pips, a husk tally, and a boss bar on demand).
func set_combat(on: bool) -> void:
	_combat = on
	# Invalidate + hide any scripted intro still in flight from the layer we're leaving
	# (QA F-25): the gen bump makes its coroutine bail at its next checkpoint, and
	# hiding the panel drops the line already on screen so it can't bleed across.
	_dlg_gen += 1
	dialogue_hide()
	if _res_panel != null:
		_res_panel.visible = not on
	if _warmth_panel != null:
		_warmth_panel.visible = not on
	if _corner_bl != null:
		_corner_bl.visible = not on
	for br in _corner_nodes:
		if is_instance_valid(br) and br != _corner_bl:
			br.modulate.a = 0.3 if on else 1.0
	if _objective != null:
		_objective.modulate.a = 0.5 if on else 1.0
	if _pips_row != null:
		_pips_row.visible = on
	if _guard_bar != null:
		_guard_bar.visible = on
	if _prov_row != null:
		_prov_row.visible = false        # re-shown by the combat _process poll if > 0
		_prov_prev = -1
	if _foe_chip != null:
		# Reset any leftover "CLEARED" fade/tick from the previous room — including
		# killing the pending fade tween so it can't fade the new room's tally away.
		if _foe_tw != null and _foe_tw.is_valid():
			_foe_tw.kill()
		_foe_tw = null
		_foe_chip.modulate = Color(1, 1, 1, 1)
		_foe_chip.scale = Vector2.ONE
		_foe_chip.visible = on and not _boss_active
	# A run-map overlay left open when leaving a dungeon would otherwise hang over
	# the village, blocking the mouse with no way to dismiss it (QA F-25).
	if _map_root != null:
		_map_root.visible = false
	# Reference panels shouldn't float across a layer swap either.
	if _codex_panel != null and is_instance_valid(_codex_panel):
		_codex_panel.queue_free()
		_codex_panel = null
	# Transient chrome must not bleed across a layer swap (QA F-25): drop stale
	# toasts + banners + tips, hide the village controls card in the ruins, show
	# the satchel. (A village tip fading out over a dungeon reads as a glitch.)
	if _toast_box != null:
		for c in _toast_box.get_children():
			c.queue_free()
	if _tip_panel != null:
		if _tip_tw != null and _tip_tw.is_valid():
			_tip_tw.kill()
		_tip_panel.visible = false
		_tip_panel.modulate.a = 0.0
	for b in get_tree().get_nodes_in_group("banner"):
		if is_instance_valid(b):
			b.queue_free()
	if _controls_card != null and is_instance_valid(_controls_card):
		_controls_card.visible = not on
	if _satchel_panel != null:
		_satchel_panel.visible = on
		_refresh_satchel()
	if not on:
		hide_boss()
		_foe_prev = 999
	# Retune the bottom-left progression bar for the skin: combat = live Kindle track
	# (+ succession notches), village = the Soil head-start meter (QA D-01).
	if _kindle_notches != null:
		_kindle_notches.visible = on
		_kindle_notches.queue_redraw()
	_refresh_progress_bar()
	set_process(on)
	if _dash_pip != null:
		_dash_pip.queue_redraw()
	if _riposte_pip != null:
		_riposte_pip.queue_redraw()

# The husks-remaining tally (top-left). A gentle tick on each kill; a gold
# "CLEARED" flash when the room empties.
func set_enemies(remaining: int, total: int) -> void:
	if _foe_count == null:
		return
	if _boss_active:
		return
	if remaining <= 0:
		_foe_count.text = Loc.t("CLEARED")
		_foe_count.add_theme_color_override("font_color", Palette.GOLD_L)
		if _foe_tw != null and _foe_tw.is_valid():
			_foe_tw.kill()
		_foe_tw = _foe_chip.create_tween()
		_foe_tw.tween_interval(1.1)
		_foe_tw.tween_property(_foe_chip, "modulate:a", 0.0, 0.6)
		_foe_prev = 0
		return
	_foe_chip.modulate.a = 1.0
	_foe_count.add_theme_color_override("font_color", Palette.UI_TEXT)
	_foe_count.text = "%d / %d" % [remaining, total]
	# A quick scale-tick when the count actually drops (a husk just fell).
	if remaining < _foe_prev and _foe_prev != 999:
		_foe_chip.pivot_offset = _foe_chip.size * 0.5
		var tk := _foe_chip.create_tween()
		_foe_chip.scale = Vector2(1.18, 1.18)
		tk.tween_property(_foe_chip, "scale", Vector2.ONE, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_foe_prev = remaining

# Raise the Warden bar. Suppresses the husk tally while it's up.
func show_boss(boss_name: String, max_hp: int) -> void:
	if _boss_root == null:
		return
	_boss_active = true
	_boss_max = maxi(1, max_hp)
	_boss_ratio = 1.0
	_boss_ghost_ratio = 1.0
	if _boss_name != null:
		_boss_name.text = boss_name.to_upper()
	if _boss_fill != null:
		_boss_fill.size = Vector2(BOSS_FILL_W, 14)
	if _boss_ghost != null:
		_boss_ghost.size = Vector2(BOSS_FILL_W, 14)
	_boss_root.visible = true
	_boss_root.modulate = Color(1, 1, 1, 1)
	if _foe_chip != null:
		_foe_chip.visible = false
	# The Warden bar owns the top-centre — fold the depth caption away while it's up.
	if _depth_panel != null:
		_depth_panel.visible = false
	# Sweep-in from the top.
	_boss_root.position.y = -30.0
	var tw := _boss_root.create_tween()
	tw.tween_property(_boss_root, "position:y", 0.0, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_boss_hp(hp: int) -> void:
	if not _boss_active or _boss_fill == null:
		return
	_boss_ratio = clampf(float(hp) / float(_boss_max), 0.0, 1.0)
	_boss_fill.size = Vector2(BOSS_FILL_W * _boss_ratio, 14)

func hide_boss() -> void:
	if _boss_root == null or not _boss_active:
		return
	_boss_active = false
	# Bring the depth caption back once the Warden is down (still in the ruin).
	if _combat and _depth_panel != null and _depth_label != null and _depth_label.text != "":
		_depth_panel.visible = true
	var tw := _boss_root.create_tween()
	tw.tween_property(_boss_root, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): _boss_root.visible = false)

# ---------------------------------------------------------------------------
# Per-frame combat polling: self-read the hero's dash cooldown + riposte window
# so the pips animate without the player having to push updates every frame. The
# ghost chip on the boss bar also eases here. Idle (village) turns _process off.
func _process(delta: float) -> void:
	if not _combat:
		return
	_pip_t += delta
	var hero: Node = get_tree().get_first_node_in_group("player")
	if hero != null and is_instance_valid(hero):
		var cdv: Variant = hero.get("_dash_cd")
		var cd: float = float(cdv) if cdv != null else 0.0
		var new_ratio: float = clampf(1.0 - cd / DASH_CD_REF, 0.0, 1.0)
		if not is_equal_approx(new_ratio, _dash_ratio):
			_dash_ratio = new_ratio
			if _dash_pip != null:
				_dash_pip.queue_redraw()
		var ctv: Variant = hero.get("_counter_t")
		var ct: float = float(ctv) if ctv != null else 0.0
		if (ct > 0.0) != (_riposte_t > 0.0):
			if _riposte_pip != null:
				_riposte_pip.queue_redraw()
		_riposte_t = ct
		# Guard stamina meter (self-polled, same idiom as the pips).
		if _guard_meter != null:
			var gsv: Variant = hero.get("guard_stamina")
			var gs: float = clampf(float(gsv), 0.0, 1.0) if gsv != null else 1.0
			var gbv: Variant = hero.get("_guard_broken_t")
			var broken: bool = gbv != null and float(gbv) > 0.0
			_guard_meter.size = Vector2(60.0 * gs, 3)
			if broken:
				_guard_meter.color = Palette.BLOOD
			elif gs < 0.34:
				_guard_meter.color = Palette.AMBER
			else:
				_guard_meter.color = Palette.CYAN
		# Kindle / succession bar (self-polled, same idiom as the pips).
		_sync_kindle_bar(hero)
		# Provisions readout (self-polled): show the count, hide it when empty.
		if _prov_row != null:
			var pv: Variant = hero.get("provisions")
			var prov: int = int(pv) if pv != null else 0
			_prov_row.visible = prov > 0
			if prov != _prov_prev:
				_prov_prev = prov
				if _prov_label != null:
					_prov_label.text = "x%d" % prov
		# Keep an open character sheet live as Kindle streams in and the hero blooms.
		if _char_panel != null and is_instance_valid(_char_panel):
			_populate_character()
	# Pulse the pips while they signal something live (ready dash / armed riposte).
	if _dash_pip != null and _dash_ratio >= 1.0:
		_dash_pip.queue_redraw()
	if _riposte_pip != null and _riposte_t > 0.0:
		_riposte_pip.queue_redraw()
	# Boss bar: the ghost chip trails the live fill, and a light shake while alive.
	if _boss_active:
		_boss_ghost_ratio = lerpf(_boss_ghost_ratio, _boss_ratio, clampf(delta * 4.0, 0.0, 1.0))
		if _boss_ghost != null:
			_boss_ghost.size = Vector2(BOSS_FILL_W * _boss_ghost_ratio, 14)
		if _boss_fill != null:
			# Fill colour bleeds from BLOOD (full) to WINE (near death).
			_boss_fill.color = Palette.WINE.lerp(Palette.BLOOD, _boss_ratio)

# The dash pip: a cooldown wedge that fills clockwise; a bright ring when ready.
func _draw_dash_pip() -> void:
	if _dash_pip == null:
		return
	var c: Vector2 = _dash_pip.size * 0.5
	var r: float = minf(c.x, c.y) - 3.0
	# Dark socket.
	_dash_pip.draw_circle(c, r, Color(0, 0, 0, 0.5))
	var ready: bool = _dash_ratio >= 1.0
	if ready:
		# A soft breathing glow + full bright ring.
		var pulse: float = 0.5 + 0.5 * sin(_pip_t * 5.0)
		_dash_pip.draw_circle(c, r, Color(Palette.CYAN.r, Palette.CYAN.g, Palette.CYAN.b, 0.35 + 0.25 * pulse))
		_dash_pip.draw_arc(c, r, 0.0, TAU, 40, Palette.WHITE, 2.0, true)
	else:
		# The cooldown sweep, filling clockwise from 12 o'clock.
		var a0: float = -PI / 2.0
		var a1: float = a0 + TAU * _dash_ratio
		_dash_pip.draw_arc(c, r, a0, a1, 32, Palette.CYAN, 3.0, true)
	# A tiny centred bolt glyph so the pip reads as "dash".
	_dash_pip.draw_line(c + Vector2(-3, -5), c + Vector2(1, -1), Palette.WHITE, 1.5)
	_dash_pip.draw_line(c + Vector2(1, -1), c + Vector2(-2, 1), Palette.WHITE, 1.5)
	_dash_pip.draw_line(c + Vector2(-2, 1), c + Vector2(3, 5), Palette.WHITE, 1.5)

# The riposte pip: dark when idle; a pulsing gold flare while a parry is armed.
func _draw_riposte_pip() -> void:
	if _riposte_pip == null:
		return
	var c: Vector2 = _riposte_pip.size * 0.5
	var r: float = minf(c.x, c.y) - 3.0
	var armed: bool = _riposte_t > 0.0
	if armed:
		var pulse: float = 0.5 + 0.5 * sin(_pip_t * 8.0)
		_riposte_pip.draw_circle(c, r + 1.5 * pulse, Color(Palette.GOLD_L.r, Palette.GOLD_L.g, Palette.GOLD_L.b, 0.3 + 0.3 * pulse))
		_riposte_pip.draw_circle(c, r, Palette.EMBER)
		_riposte_pip.draw_arc(c, r, 0.0, TAU, 40, Palette.GOLD_L, 2.0, true)
	else:
		_riposte_pip.draw_circle(c, r, Color(0, 0, 0, 0.5))
		_riposte_pip.draw_arc(c, r, 0.0, TAU, 40, Color(Palette.GOLD_L.r, Palette.GOLD_L.g, Palette.GOLD_L.b, 0.35), 1.5, true)
	# A small star/spark glyph at the centre.
	for i in range(4):
		var ang: float = i * PI / 2.0
		var v: Vector2 = Vector2(cos(ang), sin(ang)) * 4.0
		_riposte_pip.draw_line(c - v, c + v, Palette.WHITE if armed else Color(1, 1, 1, 0.5), 1.5)

# A rounded ember pip (filled) or a hollow dark socket (spent).
func _pip_style(filled: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(4)
	if filled:
		sb.bg_color = Palette.UI_HP
		sb.set_border_width_all(1)
		sb.border_color = Palette.GOLD_L
	else:
		sb.bg_color = Color(Palette.UI_HP_D.r, Palette.UI_HP_D.g, Palette.UI_HP_D.b, 0.7)
		sb.set_border_width_all(1)
		sb.border_color = Color(0, 0, 0, 0.6)
	return sb

func set_gwi(v: float) -> void:
	if _gwi_fill == null:
		return
	var w: float = clampf(v, 0.0, 1.0)
	_gwi_val = w
	_gwi_fill.size = Vector2(174.0 * w, 12)
	_gwi_fill.color = Palette.GWI_COLD.lerp(Palette.GWI_WARM, w)
	# The flame stays a flame — dim ember when cold, bright gold when warm — instead
	# of tinting cold blue-grey and reading as a water droplet (QA F-26).
	if _flame_icon != null:
		_flame_icon.modulate = Palette.EMBER.lerp(Palette.GOLD_L, w)
	if _warmth_pct != null:
		_warmth_pct.text = "%d%%" % int(round(w * 100.0))
	if _warmth_marks != null:
		_warmth_marks.queue_redraw()
	# Warmth feeds Soil, so the village head-start meter tracks it.
	_refresh_progress_bar()

# Thaw-milestone ticks over the warmth trough: reached thresholds glow gold, the next
# one to reach is highlighted (the goal to aim for), later ones stay dim.
func _draw_warmth_marks() -> void:
	if _warmth_marks == null:
		return
	var h: float = _warmth_marks.size.y
	var next_marked: bool = false
	for thr in WARMTH_MARKS:
		var x: float = 2.0 + 174.0 * float(thr)
		if _gwi_val + 0.0001 >= float(thr):
			_warmth_marks.draw_line(Vector2(x, 2.0), Vector2(x, h - 2.0), Palette.GOLD_L, 1.0)
		elif not next_marked:
			_warmth_marks.draw_line(Vector2(x, 1.0), Vector2(x, h - 1.0), Palette.AMBER, 2.0)
			next_marked = true
		else:
			_warmth_marks.draw_line(Vector2(x, 2.0), Vector2(x, h - 2.0), Palette.UI_EDGE_D, 1.0)

# ---------------------------------------------------------------------------
# Progression readout: combat = the live Kindle/succession bar (self-polled in
# _process); village = the Soil head-start meter (how far up the succession the
# next descent begins). Plus the Bloom banner and a toggle character sheet —
# the "growing stronger" feedback (QA D-01, PROGRESSION §6).

# Village skin: paint the bottom-left bar as the Soil meter. In combat the
# _process self-poll owns it, so this only sets the village state.
func _refresh_progress_bar() -> void:
	if _combat:
		return
	if _level_label != null:
		_level_label.text = Loc.t("SOIL")
	if _xp_fill != null:
		var soil: float = GameState.soil_value()
		_xp_fill.color = Palette.MOSS_L
		_xp_fill.size = Vector2(XP_W * clampf(soil, 0.0, 1.0), 5)

# Paint the combat Kindle bar from the hero: label = current succession stage,
# fill = progress along the whole track. Called by the _process self-poll and once
# more when a boon card opens (so the paused card shows the just-reached stage).
func _sync_kindle_bar(hero: Node) -> void:
	if _xp_fill == null or hero == null or not is_instance_valid(hero):
		return
	var kv: Variant = hero.get("kindle")
	if kv == null:
		return
	var frac: float = clampf(float(kv) / KINDLE_MAX, 0.0, 1.0)
	_xp_fill.size = Vector2(XP_W * frac, 5)
	_xp_fill.color = Palette.EMBER.lerp(Palette.GOLD_L, frac)
	var ksv: Variant = hero.get("kindle_stage")
	var stg: int = int(ksv) if ksv != null else 0
	if _level_label != null:
		_level_label.text = Loc.t(STAGE_LABELS[clampi(stg, 0, STAGE_LABELS.size() - 1)])

# The succession stage-boundary ticks over the combat Kindle bar.
func _draw_kindle_notches() -> void:
	if _kindle_notches == null:
		return
	var h: float = _kindle_notches.size.y
	for thr in [8.0, 20.0, 40.0]:
		var x: float = 2.0 + XP_W * (thr / KINDLE_MAX)
		_kindle_notches.draw_line(Vector2(x, 1.0), Vector2(x, h - 1.0), Color(0, 0, 0, 0.7), 1.0)

# Retained for the (now dormant) xp_changed signal wiring; the run-scoped bar is
# driven by Kindle/Soil, so this just keeps the village meter honest.
func set_ember(_total: int = 0, _level: int = 0, _into: int = 0, _span: int = 0) -> void:
	_refresh_progress_bar()

# A husk-kill crossed one or more level thresholds. Coalesce a burst of levels
# (e.g. the Warden's bounty) into ONE banner via an 0.08s debounce, so five
# thresholds don't stack five cards mid-fight (QA F-25/F-29). Badge pulses now.
func _on_level_up(level: int) -> void:
	if _lvl_from == 0:
		_lvl_from = level
	_lvl_to = level
	if _level_label != null:
		_level_label.pivot_offset = _level_label.size * 0.5
		var tw := _level_label.create_tween()
		_level_label.scale = Vector2(1.5, 1.5)
		tw.tween_property(_level_label, "scale", Vector2.ONE, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not _lvl_armed:
		_lvl_armed = true
		get_tree().create_timer(0.08).timeout.connect(_flush_levelup)

# Fire the single coalesced level-up banner once the burst settles.
func _flush_levelup() -> void:
	var a: int = _lvl_from
	var b: int = _lvl_to
	_lvl_from = 0
	_lvl_to = 0
	_lvl_armed = false
	if b <= 0:
		return
	var gained: int = b - a + 1
	var title: String = "EMBER LEVEL %d" % b if a == b else "EMBER LEVEL %d → %d" % [a, b]
	big_banner(title, "+%d Max HP   ·   +%d%% Damage" % [gained, gained * 8], Palette.GOLD_L)

# A big, momentary centred banner (level-ups, attunements): scale-pop in, hold, fade.
# Uses TOP_LEFT anchoring (so the PanelContainer auto-grows to its content — a
# CENTER preset pins all anchors to 0.5 and stays zero-size) and is centred by hand.
func big_banner(title: String, sub: String = "", color: Color = Palette.GOLD_L) -> void:
	var card := _panel()
	card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_ignore(card)
	# Stack under any banner already on screen so back-to-back events don't overlap
	# (e.g. rescuing a survivor and levelling up on the same husk).
	var slot: int = get_tree().get_nodes_in_group("banner").size()
	card.add_to_group("banner")
	_root.add_child(card)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	_ignore(vb)
	card.add_child(vb)
	var t := _make_label(title, 26, color)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	if sub != "":
		var s := _make_label(sub, 15, Palette.UI_TEXT)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(s)
	# Let it lay out, then centre horizontally against the viewport, high on screen.
	await get_tree().process_frame
	var sz: Vector2 = card.size
	if sz.x < 2.0:
		sz = card.get_combined_minimum_size()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	# 78px slot pitch clears a two-line (title + subtitle) card, so simultaneous
	# banners (e.g. attunement + level-up on one kill) never clip (QA F-32).
	var y0: float = 122.0 + float(slot) * 78.0
	card.pivot_offset = sz * 0.5
	card.position = Vector2((vp.x - sz.x) * 0.5, y0)
	card.scale = Vector2(0.6, 0.6)
	card.modulate.a = 0.0
	var tw := card.create_tween()
	tw.tween_property(card, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(card, "modulate:a", 1.0, 0.18)
	tw.tween_interval(1.4)
	tw.tween_property(card, "position:y", y0 - 34.0, 0.5)
	tw.parallel().tween_property(card, "modulate:a", 0.0, 0.5)
	tw.tween_callback(card.queue_free)

# The run-summary card shown on returning home (banked) or dying (fell): the beat
# that gives a run an arc and makes the stakes legible (QA F-02). Auto-fades.
func show_run_summary(data: Dictionary) -> void:
	if _root == null:
		return
	var alive: bool = bool(data.get("alive", true))
	var card := _panel()
	card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_ignore(card)
	_root.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	vb.custom_minimum_size = Vector2(288, 0)
	_ignore(vb)
	card.add_child(vb)
	var title := _make_label("RUN BANKED" if alive else "YOU FELL IN THE DARK",
		23, Palette.GOLD_L if alive else Palette.BLOOD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	vb.add_child(_make_label(Loc.t("Chambers cleared     %d") % int(data.get("rooms", 0)), 15, Palette.UI_TEXT))
	vb.add_child(_make_label(Loc.t("Husks felled         %d") % int(data.get("husks", 0)), 15, Palette.UI_TEXT))
	var rescues: Array = data.get("rescues", [] as Array)
	if not rescues.is_empty():
		var names: Array[String] = []
		for r in rescues:
			names.append(Loc.t(String(r).capitalize()))
		vb.add_child(_make_label(Loc.t("Rescued: ") + ", ".join(names), 15, Palette.MOSS_L))
	vb.add_child(_make_label(Loc.t("Kindle gathered     +%d") % int(data.get("kindle", 0)), 15, Palette.GOLD_L))
	var blooms: int = int(data.get("blooms", 0))
	if blooms > 0:
		vb.add_child(_make_label(Loc.t("Blooms              %d") % blooms, 15, Palette.EMBER))
	var kept_str: String = _loot_str(data.get("kept", {}))
	if alive:
		vb.add_child(_make_label(Loc.t("Loot banked: ") + (kept_str if kept_str != "" else Loc.t("nothing")), 15, Palette.AMBER))
	else:
		vb.add_child(_make_label(Loc.t("Salvaged: ") + (kept_str if kept_str != "" else Loc.t("nothing")), 15, Palette.AMBER))
		var lost_str: String = _loot_str(data.get("lost", {}))
		vb.add_child(_make_label(Loc.t("Lost to the dark: ") + (lost_str if lost_str != "" else Loc.t("nothing")), 14, Palette.UI_DIM))
	# Lay out, centre against the viewport, pop in, hold, fade.
	await get_tree().process_frame
	var sz: Vector2 = card.size
	if sz.x < 2.0:
		sz = card.get_combined_minimum_size()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	card.pivot_offset = sz * 0.5
	card.position = (vp - sz) * 0.5
	card.scale = Vector2(0.7, 0.7)
	card.modulate.a = 0.0
	var tw := card.create_tween()
	tw.tween_property(card, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(card, "modulate:a", 1.0, 0.2)
	tw.tween_interval(6.0)
	tw.tween_property(card, "modulate:a", 0.0, 0.7)
	tw.tween_callback(card.queue_free)

# "3 wood, 1 iron" style summary of a loot dict (empty string if nothing).
func _loot_str(d: Dictionary) -> String:
	var parts: Array[String] = []
	for k in ["wood", "stone", "iron"]:
		var n: int = int(d.get(k, 0))
		if n > 0:
			parts.append("%d %s" % [n, Loc.t(k)])
	return ", ".join(parts)

# Toggle the character / progression sheet (key C). Rebuilt on open so its numbers
# reflect the hero's current strength.
func toggle_character() -> void:
	if _char_panel != null and is_instance_valid(_char_panel):
		_char_panel.queue_free()
		_char_panel = null
		return
	_char_panel = _panel()
	_char_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	_char_panel.position = Vector2(20, 0)
	_ignore(_char_panel)
	_root.add_child(_char_panel)
	_populate_character()

func _populate_character() -> void:
	if _char_panel == null or not is_instance_valid(_char_panel):
		return
	for c in _char_panel.get_children():
		c.queue_free()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	vb.custom_minimum_size = Vector2(210, 0)
	_ignore(vb)
	_char_panel.add_child(vb)
	vb.add_child(_make_label("THE KINDLED", 16, Palette.EMBER))
	# Succession (run-scoped) + Soil (the meta head-start the next descent begins at).
	var hero: Node = get_tree().get_first_node_in_group("player")
	var stage: int = int(hero.get("kindle_stage")) if hero != null and is_instance_valid(hero) else 0
	vb.add_child(_make_label(Loc.t("Succession   %s  (stage %d)")
		% [Loc.t(STAGE_LABELS[clampi(stage, 0, STAGE_LABELS.size() - 1)]), stage], 14, Palette.GOLD_L))
	vb.add_child(_make_label(Loc.t("Soil head-start   stage %d") % GameState.soil_start_stage(), 13, Palette.MOSS_L))
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
			vb.add_child(_make_label(line, 14, Palette.UI_TEXT))
		# Boons drafted this run (the build identity — empty in the village).
		var blist: Variant = hero.get("boons")
		if blist is Array and not (blist as Array).is_empty():
			vb.add_child(_make_label("Boons", 14, Palette.EMBER))
			var counts: Dictionary = {}
			for bid in (blist as Array):
				counts[bid] = int(counts.get(bid, 0)) + 1
			for bid in counts:
				var nm: String = Loc.t(_boon_name(String(bid)))
				var c: int = int(counts[bid])
				vb.add_child(_make_label("• %s%s" % [nm, ("  x%d" % c) if c > 1 else ""], 13, Palette.UI_TEXT))
		# Provisions carried this run (the farm's yield — Agriculture, QA D-02).
		var pv: Variant = hero.get("provisions")
		if pv != null and int(pv) > 0:
			vb.add_child(_make_label(Loc.t("Provisions   x%d  (auto-heal when hurt)") % int(pv), 13, Palette.MOSS_L))
	# Attunements earned (rescued survivors), by element.
	vb.add_child(_make_label("Attunements", 14, Palette.EMBER))
	if GameState.rescued.is_empty():
		vb.add_child(_make_label("—  none yet", 13, Palette.UI_DIM))
	else:
		for pillar in GameState.rescued:
			var a: Dictionary = GameState.ATTUNEMENTS.get(pillar, {})
			var nm: String = Loc.t(String(a.get("name", pillar)))
			var ds: String = Loc.t(String(a.get("desc", "")))
			var el: String = Loc.t(String(a.get("element", "")))
			vb.add_child(_make_label("• %s  (%s) — %s" % [nm, el, ds], 13, Palette.UI_TEXT))
	vb.add_child(_make_label("[C] close    ·    [K] Codex", 12, Palette.UI_DIM))

# ---------------------------------------------------------------------------
# The knowledge Codex — "the Ember's memories" (QA D-06). A centred reference
# panel of recovered, science-vetted facts (Lore.ENTRIES); locked entries read
# as undiscovered. Toggled with K. Non-modal (like the character sheet).
# ---------------------------------------------------------------------------
func toggle_codex() -> void:
	if _codex_panel != null and is_instance_valid(_codex_panel):
		_codex_panel.queue_free()
		_codex_panel = null
		return
	_codex_panel = Control.new()
	_codex_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_codex_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_codex_panel)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_codex_panel.add_child(cc)
	var card := _panel()
	cc.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 9)
	col.custom_minimum_size = Vector2(516, 0)
	_ignore(col)
	card.add_child(col)
	col.add_child(_make_label("THE EMBER'S MEMORIES", 21, Palette.EMBER))
	col.add_child(_make_label(Loc.t("Recovered knowledge   %d / %d") % [GameState.codex.size(), Lore.ENTRIES.size()],
		13, Palette.UI_DIM))
	for e: Dictionary in Lore.ENTRIES:
		var id: String = String(e.get("id", ""))
		var known: bool = GameState.has_codex(id)
		var head: String = ("%s      %s" % [Loc.t(String(e.get("title", ""))), Loc.t(String(e.get("era", "")))]) if known else "? ? ?"
		col.add_child(_make_label(head, 16, Palette.GOLD_L if known else Palette.UI_DIM))
		var body: Label = _make_label(
			String(e.get("fact", "")) if known else "Undiscovered — rescue this craft's survivor, or raise their building.",
			13, Palette.UI_TEXT if known else Palette.UI_DIM)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD
		body.custom_minimum_size = Vector2(500, 0)
		col.add_child(body)
	col.add_child(_make_label("[K] close", 12, Palette.UI_DIM))

func _refresh_roster(_a := 0) -> void:
	if _roster_box == null:
		return
	for c in _roster_box.get_children():
		c.queue_free()
	for pillar in GameState.rescued:
		# A portrait behind a gilded medallion whose centre is transparent.
		var frame := Control.new()
		frame.custom_minimum_size = Vector2(30, 30)
		_ignore(frame)
		var portrait := TextureRect.new()
		var key := "survivor_" + str(pillar)
		portrait.texture = Assets.tex(key) if Assets.has(key) else Assets.tex("survivor_farmer")
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		portrait.offset_top = 3
		portrait.offset_bottom = -3
		_ignore(portrait)
		frame.add_child(portrait)
		var med := TextureRect.new()
		med.texture = Assets.tex("ui_medallion")
		med.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		med.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_ignore(med)
		frame.add_child(med)
		_roster_box.add_child(frame)

# ---------------------------------------------------------------------------
# Depth banner (the run's rogue-lite heartbeat)
func set_depth(depth: int) -> void:
	if _depth_panel == null:
		return
	_depth_val = depth
	if _depth_label != null and depth > 0:
		_depth_label.text = Loc.t("RUIN  ·  DEPTH %d") % depth
	# The Warden bar owns the top-centre — stay folded away while a boss is up.
	if depth <= 0 or _boss_active:
		_depth_panel.visible = false
		return
	_depth_panel.visible = true

# ---------------------------------------------------------------------------
# Onboarding: a persistent objective line and a one-time controls card.
func set_objective(text: String) -> void:
	if _objective == null:
		return
	_objective_src = text                # keep the source so L can relocalize it live
	_objective.text = Loc.t(text)
	_objective.visible = text != ""

# Re-translate the persistent, on-screen UI when the language changes (L). Transient
# chrome (toasts, banners, a fading controls card) just appears in the new language
# next time; the lasting elements refresh here so the switch reads as immediate.
func _relocalize(_lang: String) -> void:
	set_objective(_objective_src)
	set_depth(_depth_val)
	if _warmth_label != null:
		_warmth_label.text = Loc.t("WARMTH")
	_refresh_resources()
	_refresh_roster()
	_refresh_satchel()
	_refresh_progress_bar()
	set_gwi(GameState.gwi)
	if _char_panel != null and is_instance_valid(_char_panel):
		_populate_character()
	if _codex_panel != null and is_instance_valid(_codex_panel):
		toggle_codex()   # close…
		toggle_codex()   # …and rebuild in the new language
	toast("Ngôn ngữ: Tiếng Việt" if GameState.lang == "vi" else "Language: English", Palette.CYAN)

# A gilded card listing the controls, bottom-left, fading out on its own so it
# teaches the first session without becoming permanent clutter.
func show_controls() -> void:
	if _controls_card != null and is_instance_valid(_controls_card):
		return
	var card := _panel()
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	# Stacked ABOVE the vitals cluster (hearts + pips), which owns the very corner.
	card.position = Vector2(14, -262)
	_root.add_child(card)
	_controls_card = card
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	_ignore(vb)
	card.add_child(vb)
	vb.add_child(_make_label("CONTROLS", 14, Palette.EMBER))
	for line in [
		"WASD  —  move",
		"Left mouse  —  attack",
		"Right mouse  —  guard",
		"Space  —  dash",
		"E  —  interact    B  —  build",
		"Tab  —  run map    C  —  character",
		"K  —  codex (recovered knowledge)",
		"L  —  language (English / Tiếng Việt)",
	]:
		vb.add_child(_make_label(line, 15, Palette.UI_TEXT))
	# Hold, then fade away.
	var tw := card.create_tween()
	tw.tween_interval(11.0)
	tw.tween_property(card, "modulate:a", 0.0, 1.5)
	tw.tween_callback(card.queue_free)

# ---------------------------------------------------------------------------
# Dialogue ("talking") + scripted onboarding
# ---------------------------------------------------------------------------

# Show one line and suspend until the player advances it. A typewriter reveal
# gives it voice; a click while still typing snaps it to full first.
func say(speaker: String, text: String) -> void:
	if _dlg_panel == null:
		return
	var line: String = Loc.t(text)
	_dlg_speaker.text = Loc.t(speaker)
	_dlg_text.text = line
	_dlg_hint.visible = true
	_dlg_panel.visible = true
	_dlg_panel.modulate.a = 1.0
	if _dlg_type_tw != null and _dlg_type_tw.is_valid():
		_dlg_type_tw.kill()
	_dlg_text.visible_ratio = 0.0
	_dlg_type_tw = _dlg_text.create_tween()
	_dlg_type_tw.tween_property(_dlg_text, "visible_ratio", 1.0,
		clampf(float(line.length()) * 0.022, 0.2, 2.2))
	_dlg_await = true
	await dialogue_advanced
	_dlg_await = false

# Show an instruction and suspend until the player performs `action` — the
# interactive beats of the tutorial (move, dash, …).
func gate_action(text: String, poll: Callable) -> void:
	if _dlg_panel == null:
		return
	_dlg_speaker.text = Loc.t("The Ember")
	_dlg_text.text = Loc.t(text)
	_dlg_text.visible_ratio = 1.0
	_dlg_hint.visible = false
	_dlg_panel.visible = true
	_dlg_panel.modulate.a = 1.0
	while true:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		if bool(poll.call()):
			break
	# A beat of acknowledgement before moving on.
	await get_tree().create_timer(0.35).timeout

func dialogue_hide() -> void:
	_dlg_await = false
	if _dlg_panel != null:
		_dlg_panel.visible = false

# Fire a one-time contextual tutorial line for `key`. Non-blocking: it slides in,
# holds, and fades — the game keeps running. Skipped while a blocking dialogue is up.
func tip(key: String, text: String) -> void:
	if _tip_panel == null or GameState.tips_seen.has(key):
		return
	if _dlg_await:
		return   # a scripted line owns the screen; teach this one next time
	GameState.tips_seen[key] = true
	_tip_label.text = Loc.t(text)
	_tip_panel.visible = true
	if _tip_tw != null and _tip_tw.is_valid():
		_tip_tw.kill()
	_tip_panel.modulate.a = 0.0
	_tip_tw = _tip_panel.create_tween()
	_tip_tw.tween_property(_tip_panel, "modulate:a", 1.0, 0.25)
	_tip_tw.tween_interval(5.5)
	_tip_tw.tween_property(_tip_panel, "modulate:a", 0.0, 0.7)
	_tip_tw.tween_callback(func() -> void: _tip_panel.visible = false)

# Show/point the off-screen guidance arrow (driven by Main). `pos` is screen-space,
# `ang` the direction toward the target.
func set_guide_arrow(on: bool, pos: Vector2 = Vector2.ZERO, ang: float = 0.0) -> void:
	if _guide_arrow == null:
		_build_guide_arrow()
	_guide_arrow.visible = on
	if on:
		_guide_arrow.position = pos
		_guide_arrow.rotation = ang

func _build_guide_arrow() -> void:
	_guide_arrow = Node2D.new()
	_guide_arrow.visible = false
	add_child(_guide_arrow)   # on the HUD CanvasLayer → screen space
	# A gold chevron with a dark backing, pointing +x (Main rotates it toward the goal).
	var back := Polygon2D.new()
	back.polygon = PackedVector2Array([Vector2(-16, -15), Vector2(20, 0), Vector2(-16, 15)])
	back.color = Palette.BLACK
	_guide_arrow.add_child(back)
	var tri := Polygon2D.new()
	tri.polygon = PackedVector2Array([Vector2(-12, -11), Vector2(15, 0), Vector2(-12, 11)])
	tri.color = Palette.GOLD_L
	_guide_arrow.add_child(tri)

# --- The scripted flows -----------------------------------------------------

func start_village_intro() -> void:
	var gen: int = _dlg_gen
	await get_tree().create_timer(0.5).timeout
	if gen != _dlg_gen: return
	await say("The Ember", "You carried me through the long dark. I am nearly spent… but not yet.")
	if gen != _dlg_gen: return
	await say("The Ember", "This was a village once. Rebuild it, and my light returns — warmth, and hope with it.")
	if gen != _dlg_gen: return
	await gate_action("Let me see you move — walk with W, A, S, D.", _player_is_moving)
	if gen != _dlg_gen: return
	await say("The Ember", "Good. You remember. Hold Right-Mouse to raise a guard; tap Space to dash.")
	if gen != _dlg_gen: return
	await gate_action("Try a dash — press Space.", _player_dashed_since)
	if gen != _dlg_gen: return
	await say("The Ember", "Beneath us sleeps the ruin, thick with husks and the things they hoard.")
	if gen != _dlg_gen: return
	await say("The Ember", "Descend at the Supply Gate below. Bring home survivors and materials — then build.")
	if gen != _dlg_gen: return
	dialogue_hide()
	set_objective("Descend at the Supply Gate  (walk to it, press E)")

func start_dungeon_intro() -> void:
	var gen: int = _dlg_gen
	await get_tree().create_timer(0.5).timeout
	if gen != _dlg_gen: return
	# The scripted lines must not run mid-fight (QA F-25): a click that advances the
	# dialogue also swung the sword, and husks kept attacking while you read. Freeze
	# combat — husks hold, the hero is untouchable and can't swing — until it ends.
	_freeze_combat(true)
	await say("The Ember", "Husks. Hollow things I left behind when the world went cold. They feel nothing.")
	if gen != _dlg_gen:
		_freeze_combat(false)
		return
	await say("The Ember", "Left-Mouse swings. Right-Mouse guards a blow. Space dashes you clean THROUGH them.")
	if gen != _dlg_gen:
		_freeze_combat(false)
		return
	await say("The Ember", "Clear every husk and the sealed gates open — then choose: deeper for spoils, or home to build.")
	dialogue_hide()
	_freeze_combat(false)
	set_objective("The exits are sealed — clear every husk")

# Suspend / resume the fight around a scripted line (QA F-25). Husks stop their AI
# in place; the hero can't be hit and can't attack (so a dialogue-advancing click
# never leaks into a sword swing). Symmetric — every true is undone by a false.
func _freeze_combat(on: bool) -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Node and is_instance_valid(e):
			(e as Node).set_physics_process(not on)
	var p := _player()
	if p == null or not is_instance_valid(p):
		return
	if on:
		p.set("_invuln", 1.0e9)
		p.set("combat_enabled", false)
	else:
		p.set("_invuln", 0.0)
		p.set("combat_enabled", true)

# --- Poll helpers for the gates ---------------------------------------------

func _player() -> Node:
	return get_tree().get_first_node_in_group("player")

func _player_is_moving() -> bool:
	var p := _player()
	if p == null or not is_instance_valid(p):
		return false
	var v: Vector2 = p.velocity
	return v.length() > 20.0

# The player node exposes _dash_cd; a dash was just used when it is near its max.
func _player_dashed_since() -> bool:
	var p := _player()
	if p == null or not is_instance_valid(p):
		return false
	return float(p.get("_dash_cd")) > 0.4

# ---------------------------------------------------------------------------
# Run map overlay (Cult-of-the-Lamb style), toggled with Tab
# ---------------------------------------------------------------------------
func toggle_map() -> void:
	var rm = GameState.run_map
	if rm == null:
		toast("No active run — descend first", Palette.UI_DIM)
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
	_root.add_child(_map_root)
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
	canvas.draw_string(font, Vector2(area.position.x, area.end.y + 34.0),
		"Tab to close   ·   clear the room, then walk into a glowing gate to take that path",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.UI_DIM)

# ---------------------------------------------------------------------------
func show_prompt(text: String) -> void:
	if _prompt:
		# Catch-all for any literal prompt; interpolated ones are localized at source.
		_prompt.text = Loc.t(text)
		_prompt.visible = true

func hide_prompt() -> void:
	if _prompt:
		_prompt.visible = false

func toast(text: String, color: Color = Color("f7c59f")) -> void:
	if _toast_box == null:
		return
	var l := _make_label(text, 18, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(280, 0)
	_toast_box.add_child(l)
	l.modulate.a = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.18)
	tw.tween_interval(1.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)

# ---------------------------------------------------------------------------
# The build menu is a stack of information cards — icon, name, one-line effect,
# per-resource cost (red where you're short), and a warmth badge — instead of a bare
# cost list. Modelled on a farming/city-builder's build palette (Stardew carpenter,
# Cities:Skylines cost preview): you choose by what a structure DOES, and can see at a
# glance which material is blocking you. Keyboard 1-4 and click both still select.
func open_build_menu(entries: Array) -> void:
	_menu_open = true
	_menu_ids.clear()
	for c in _menu.get_children():
		c.queue_free()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_ignore(vb)
	_menu.add_child(vb)
	vb.add_child(_make_label("BUILD   (Esc to cancel)", 20, Palette.EMBER))
	var n := 1
	for e in entries:
		var id: String = str(e["id"])
		_menu_ids.append(id)
		vb.add_child(_build_card(n, e))
		n += 1
	_menu.visible = true

# One build-menu card. Left-clickable (and number-key selectable via open_build_menu);
# greyed when unaffordable, but its costs still read so the player sees what to gather.
func _build_card(n: int, e: Dictionary) -> Button:
	var id: String = str(e["id"])
	var affordable: bool = bool(e.get("affordable", true))
	var b := Button.new()
	b.custom_minimum_size = Vector2(360, 128)   # room for header + 2-line desc + cost row
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not affordable
	b.add_theme_stylebox_override("normal", _button_style(false))
	b.add_theme_stylebox_override("hover", _button_style(true))
	b.add_theme_stylebox_override("pressed", _button_style(true))
	b.add_theme_stylebox_override("disabled", _button_style(false))
	b.pressed.connect(_select.bind(id))

	# A Button is not a Container: anchor a VBox to the button's full rect so its rows
	# get real widths and lay out (the same trick the boon cards use). Inset a little so
	# content clears the gilded border.
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 14
	vb.offset_top = 8
	vb.offset_right = -14
	vb.offset_bottom = -8
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 4)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)

	# Header row: building thumbnail + "n. Name", with a warmth badge pushed right.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(header)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 44)
	# IGNORE_SIZE so a big building texture doesn't force the TextureRect to its own
	# native size (which would balloon the card) — keep it a fixed 44px thumbnail.
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex_key: String = String(e.get("tex", ""))
	if tex_key != "" and Assets.has(tex_key):
		icon.texture = Assets.tex(tex_key)
	_ignore(icon)
	header.add_child(icon)
	var name_lab := _make_label("%d.  %s" % [n, Loc.t(str(e.get("label", "?")))], 18, Palette.GOLD_L)
	name_lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(name_lab)
	var warm: float = float(e.get("warm", 0.0))
	if warm > 0.0:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_ignore(spacer)
		header.add_child(spacer)
		var flame := TextureRect.new()
		flame.texture = Assets.tex("ui_flame")
		flame.custom_minimum_size = Vector2(13, 16)
		flame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		flame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_ignore(flame)
		header.add_child(flame)
		var wl := _make_label("+%d%%" % int(round(warm * 100.0)), 13, Palette.AMBER)
		wl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(wl)

	var desc: String = String(e.get("desc", ""))
	if desc != "":
		var d := _make_label(desc, 13, Palette.UI_TEXT)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD
		d.custom_minimum_size = Vector2(0, 34)   # reserve 2 lines so autowrap can't collapse it
		vb.add_child(d)

	vb.add_child(_cost_row(e.get("cost", {})))
	return b

# A row of cost chips: material icon + amount, amount reddened when you can't afford it
# (the at-a-glance "which resource is short" cue every city-builder gives you).
func _cost_row(cost: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in cost:
		var need: int = int(cost[k])
		var have: int = GameState.amount(String(k))
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 3)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		var ikey: String = String(RES_ICON.get(String(k), ""))
		if ikey != "" and Assets.has(ikey):
			icon.texture = Assets.tex(ikey)
		icon.custom_minimum_size = Vector2(16, 16)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_ignore(icon)
		chip.add_child(icon)
		chip.add_child(_make_label(str(need), 15, Palette.WHITE if have >= need else Palette.BLOOD))
		row.add_child(chip)
	return row

func _button_style(hot: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.UI_BG2 if hot else Color(Palette.UI_BG.r, Palette.UI_BG.g, Palette.UI_BG.b, 0.9)
	sb.set_border_width_all(2)
	sb.border_color = Palette.UI_EDGE if hot else Palette.UI_EDGE_D
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	return sb

func close_build_menu() -> void:
	_menu_open = false
	_menu.visible = false

# Raise / drop the "Placing X…" banner (the Village calls these around a build ghost).
func show_place_banner(build_name: String, _cost: Dictionary = {}) -> void:
	_place_active = true
	if _place_panel == null:
		return
	_place_label.text = Loc.t("Placing %s — left-click a tended tile to build   ·   Esc to cancel") % Loc.t(build_name)
	_place_panel.visible = true

func hide_place_banner() -> void:
	_place_active = false
	if _place_panel != null:
		_place_panel.visible = false

# ---------------------------------------------------------------------------
# Title screen + pause menu (CRITIQUE B1). Both are paused full-screen overlays with
# big menu buttons; they share the _big_button helper and the _menu_style panel.

# A large stacked menu button used by the title and pause screens.
func _big_button(text: String) -> Button:
	var b := Button.new()
	b.text = Loc.t(text)
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(300, 46)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Palette.UI_TEXT)
	b.add_theme_stylebox_override("normal", _button_style(false))
	b.add_theme_stylebox_override("hover", _button_style(true))
	b.add_theme_stylebox_override("pressed", _button_style(true))
	b.pressed.connect(_ui_click)   # a soft click on every title/pause button (B3)
	return b

func _ui_click() -> void:
	Sfx.play("ui", -9.0)

func _quit_game() -> void:
	get_tree().quit()

func show_title() -> void:
	if _title_root != null and is_instance_valid(_title_root):
		return
	get_tree().paused = true
	_title_root = Control.new()
	_title_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.add_child(_title_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.97)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_title_root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_root.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(vb)
	var seal := TextureRect.new()
	seal.texture = Assets.tex("ui_ember_seal")
	seal.custom_minimum_size = Vector2(76, 76)
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	seal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ignore(seal)
	vb.add_child(seal)
	var title := _make_label("REKINDLED", 52, Palette.GOLD_L)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := _make_label("Carry the last ember home.", 18, Palette.AMBER)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	_ignore(spacer)
	vb.add_child(spacer)
	var nb := _big_button("New Game")
	nb.pressed.connect(_title_new)
	vb.add_child(nb)
	if GameState.has_save():
		var cb := _big_button("Continue")
		cb.pressed.connect(_title_continue)
		vb.add_child(cb)
	var stb := _big_button("Settings")
	stb.pressed.connect(show_settings)
	vb.add_child(stb)
	var qb := _big_button("Quit")
	qb.pressed.connect(_quit_game)
	vb.add_child(qb)

func _dismiss_title() -> void:
	get_tree().paused = false
	if _title_root != null and is_instance_valid(_title_root):
		_title_root.queue_free()
		_title_root = null

func _title_new() -> void:
	_dismiss_title()
	Main.start_new_game()

func _title_continue() -> void:
	_dismiss_title()
	Main.continue_game()

# --- Pause menu (Esc during play) ---
func toggle_pause() -> void:
	if _pause_root != null and is_instance_valid(_pause_root):
		_close_pause()
		return
	# Never pause on top of another modal.
	if _title_root != null and is_instance_valid(_title_root): return
	if _victory_root != null and is_instance_valid(_victory_root): return
	if _boon_root != null and is_instance_valid(_boon_root): return
	if _menu_open or _place_active or _dlg_await: return
	get_tree().paused = true
	_pause_root = Control.new()
	_pause_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.add_child(_pause_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_root.add_child(cc)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _menu_style())
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vb)
	var t := _make_label("PAUSED", 30, Palette.GOLD_L)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var rb := _big_button("Resume")
	rb.pressed.connect(_close_pause)
	vb.add_child(rb)
	var sb := _big_button("Save Game")
	sb.pressed.connect(_pause_save)
	vb.add_child(sb)
	var setb := _big_button("Settings")
	setb.pressed.connect(show_settings)
	vb.add_child(setb)
	var qb := _big_button("Quit to Title")
	qb.pressed.connect(_pause_quit_title)
	vb.add_child(qb)

# --- Settings screen (CRITIQUE B6): audio + accessibility, opened over title/pause ---
func show_settings() -> void:
	if _settings_root != null and is_instance_valid(_settings_root):
		return
	# The tree is already paused by the title/pause menu beneath; this stacks on top.
	_settings_root = Control.new()
	_settings_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.add_child(_settings_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings_root.add_child(cc)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _menu_style())
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(440, 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vb)
	var t := _make_label("SETTINGS", 28, Palette.GOLD_L)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	# Volume: a labelled slider.
	var vrow := HBoxContainer.new()
	vrow.add_theme_constant_override("separation", 12)
	vrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(vrow)
	var vlab := _make_label("Volume", 18, Palette.UI_TEXT)
	vlab.custom_minimum_size = Vector2(150, 0)
	vrow.add_child(vlab)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = GameState.volume
	slider.custom_minimum_size = Vector2(240, 26)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_volume_slider)
	vrow.add_child(slider)
	# Toggles — each rebuilds the screen so its On/Off label refreshes.
	vb.add_child(_settings_toggle("Mute", GameState.muted, _toggle_mute))
	vb.add_child(_settings_toggle("High-contrast telegraphs", GameState.high_contrast, _toggle_contrast))
	vb.add_child(_settings_toggle("Colorblind cues", GameState.colorblind, _toggle_colorblind))
	var langb := _big_button(Loc.t("Language") + ":  " + ("Tiếng Việt" if GameState.lang == "vi" else "English"))
	langb.pressed.connect(_toggle_lang_setting)
	vb.add_child(langb)
	var back := _big_button("Back")
	back.pressed.connect(_close_settings)
	vb.add_child(back)

func _settings_toggle(label: String, on: bool, handler: Callable) -> Button:
	var b := _big_button("%s:  %s" % [Loc.t(label), Loc.t("On") if on else Loc.t("Off")])
	b.pressed.connect(handler)
	return b

func _on_volume_slider(v: float) -> void:
	GameState.set_volume(v)

func _toggle_mute() -> void:
	GameState.set_muted(not GameState.muted)
	_rebuild_settings()

func _toggle_contrast() -> void:
	GameState.set_high_contrast(not GameState.high_contrast)
	_rebuild_settings()

func _toggle_colorblind() -> void:
	GameState.set_colorblind(not GameState.colorblind)
	_rebuild_settings()

func _toggle_lang_setting() -> void:
	GameState.toggle_lang()
	_rebuild_settings()

func _rebuild_settings() -> void:
	_close_settings()
	show_settings()

func _close_settings() -> void:
	if _settings_root != null and is_instance_valid(_settings_root):
		_settings_root.queue_free()
		_settings_root = null

func _close_pause() -> void:
	get_tree().paused = false
	if _pause_root != null and is_instance_valid(_pause_root):
		_pause_root.queue_free()
		_pause_root = null

func _pause_save() -> void:
	Main.save_now()
	_close_pause()
	toast(Loc.t("Game saved."), Palette.MOSS_L)

func _pause_quit_title() -> void:
	_close_pause()
	Main.quit_to_title()

# ---------------------------------------------------------------------------
# Win screen (CRITIQUE B4/A1): the world fully rekindled. Pause and raise the Ember's
# epilogue over a warm glow, with the run tally and a button to keep tending the village.
func show_victory(stats: Dictionary) -> void:
	if _victory_root != null and is_instance_valid(_victory_root):
		return
	get_tree().paused = true
	_victory_root = Control.new()
	_victory_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_victory_root.process_mode = Node.PROCESS_MODE_ALWAYS   # alive while the world is paused
	_root.add_child(_victory_root)
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.07, 0.02, 0.9)               # warm dark, not the cold void
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP           # swallow clicks behind it
	_victory_root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_victory_root.add_child(cc)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _menu_style())
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.custom_minimum_size = Vector2(580, 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vb)
	var seal := TextureRect.new()
	seal.texture = Assets.tex("ui_ember_seal")
	seal.custom_minimum_size = Vector2(56, 56)
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	seal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ignore(seal)
	vb.add_child(seal)
	var title := _make_label("THE WORLD IS REKINDLED", 30, Palette.GOLD_L)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	for line in [
		"The long dark breaks. Warmth climbs back into the world — and it was you who carried it.",
		"Rest now, ember-bearer. What you remembered, and rebuilt, will outlast us both.",
	]:
		var l := _make_label(line, 16, Palette.UI_TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.custom_minimum_size = Vector2(540, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(l)
	var tally := "%s %d      %s %d      %s %d      %s 100%%" % [
		Loc.t("Runs survived"), int(stats.get("runs", 0)),
		Loc.t("Rescued"), int(stats.get("rescued", 0)),
		Loc.t("Buildings"), int(stats.get("buildings", 0)),
		Loc.t("Warmth")]
	var tl := _make_label(tally, 15, Palette.AMBER)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tl)
	var btn := Button.new()
	btn.text = Loc.t("Keep tending your village  ▸")
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Palette.UI_TEXT)
	btn.add_theme_stylebox_override("normal", _button_style(false))
	btn.add_theme_stylebox_override("hover", _button_style(true))
	btn.add_theme_stylebox_override("pressed", _button_style(true))
	btn.pressed.connect(_dismiss_victory)
	vb.add_child(btn)

func _dismiss_victory() -> void:
	get_tree().paused = false
	if _victory_root != null and is_instance_valid(_victory_root):
		_victory_root.queue_free()
		_victory_root = null

func _select(id: String) -> void:
	Sfx.play("ui", -8.0)
	close_build_menu()
	build_selected.emit(id)

# ---------------------------------------------------------------------------
# Boon draft overlay (QA D-01): a paused pick-1-of-3 card raised on every Bloom.
# It MUST swallow the pointer (a click behind it is a sword swing — attack is LMB)
# and stay live while the tree is paused; there is deliberately NO cancel path —
# you always take a boon, so the run can't stall un-paused.
# ---------------------------------------------------------------------------
func open_boon_cards(cards: Array, cb: Callable) -> void:
	_boon_cb = cb
	_boon_ids.clear()
	# The world is about to pause (freezing the _process self-poll), so refresh the
	# Kindle bar now — otherwise it shows the pre-Bloom stage behind the card.
	_sync_kindle_bar(get_tree().get_first_node_in_group("player"))
	if _boon_root != null and is_instance_valid(_boon_root):
		_boon_root.queue_free()
	_boon_root = Control.new()
	_boon_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boon_root.process_mode = Node.PROCESS_MODE_ALWAYS   # alive while the world is paused
	_root.add_child(_boon_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP        # swallow the click behind the card
	_boon_root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boon_root.add_child(cc)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 16)
	cc.add_child(col)
	var title := _make_label("CHOOSE A BLOOM", 28, Palette.GOLD_L)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	var num := 1
	for card: Dictionary in cards:
		_boon_ids.append(String(card.get("id", "")))
		row.add_child(_boon_card(card, num))
		num += 1
	# Keyboard-selectable now (CRITIQUE B5): the HUD processes during the paused draft.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var hint := _make_label("Pick one — click a card, or press 1 / 2 / 3", 14, Palette.UI_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)

# One boon card: a styled button whose whole face reacts, name over effect line.
func _boon_card(card: Dictionary, num: int = 0) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(198, 152)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", _button_style(false))
	b.add_theme_stylebox_override("hover", _button_style(true))
	b.add_theme_stylebox_override("pressed", _button_style(true))
	b.pressed.connect(_pick_boon.bind(String(card.get("id", ""))))
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE       # clicks fall through to the button
	b.add_child(vb)
	var nm_text := Loc.t(String(card.get("name", "?")))
	if num > 0:
		nm_text = "[%d]  %s" % [num, nm_text]   # the number key that also picks this card
	var nm := _make_label(nm_text, 20, Palette.GOLD_L)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD
	nm.custom_minimum_size = Vector2(176, 0)
	vb.add_child(nm)
	var ds := _make_label(String(card.get("desc", "")), 15, Palette.UI_TEXT)
	ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD
	ds.custom_minimum_size = Vector2(176, 0)
	vb.add_child(ds)
	return b

func _pick_boon(id: String) -> void:
	Sfx.play("bloom", -8.0)   # a bright confirm on locking in a boon
	var cb := _boon_cb
	_boon_cb = Callable()
	_boon_ids.clear()
	process_mode = Node.PROCESS_MODE_INHERIT   # stop processing under pause again
	if _boon_root != null and is_instance_valid(_boon_root):
		_boon_root.queue_free()
		_boon_root = null
	if cb.is_valid():
		cb.call(id)

# Harness hooks so the autoplay bot / capture tool can resolve a card without a
# mouse (otherwise a Bloom pauses the tree forever with no picker).
func boon_open() -> bool:
	return _boon_root != null and is_instance_valid(_boon_root)

func pick_boon_index(i: int) -> void:
	if _boon_ids.is_empty():
		return
	_pick_boon(_boon_ids[clampi(i, 0, _boon_ids.size() - 1)])

# id → display name, read from the shared Player.BOON_POOL so the char sheet and
# the draft card never disagree.
func _boon_name(id: String) -> String:
	for b: Dictionary in Player.BOON_POOL:
		if String(b.get("id", "")) == id:
			return String(b.get("name", id))
	return id.capitalize()

func _input(event: InputEvent) -> void:
	# The Bloom draft is keyboard-selectable (CRITIQUE B5): 1/2/3 pick a card. While the
	# draft is up it swallows other HUD keys so nothing else fires under the paused world.
	if _boon_root != null and is_instance_valid(_boon_root):
		if event is InputEventKey and event.pressed and not event.echo:
			match event.physical_keycode:
				KEY_1:
					pick_boon_index(0)
					get_viewport().set_input_as_handled()
				KEY_2:
					pick_boon_index(1)
					get_viewport().set_input_as_handled()
				KEY_3:
					pick_boon_index(2)
					get_viewport().set_input_as_handled()
		return
	# A waiting dialogue line takes input first (click / E / Enter — never Space,
	# so advancing never also dashes). First press finishes the typewriter.
	if _dlg_await:
		var adv: bool = false
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			adv = true
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_E or event.physical_keycode == KEY_ENTER \
					or event.physical_keycode == KEY_KP_ENTER:
				adv = true
		if adv:
			if _dlg_text != null and _dlg_text.visible_ratio < 1.0:
				if _dlg_type_tw != null and _dlg_type_tw.is_valid():
					_dlg_type_tw.kill()
				_dlg_text.visible_ratio = 1.0
			else:
				dialogue_advanced.emit()
			get_viewport().set_input_as_handled()
		return
	# Tab toggles the run map overview (consumed so it never shifts UI focus).
	if event.is_action_pressed("map"):
		toggle_map()
		get_viewport().set_input_as_handled()
		return
	# C toggles the character / progression sheet.
	if event.is_action_pressed("character"):
		toggle_character()
		get_viewport().set_input_as_handled()
		return
	# K toggles the knowledge Codex ("the Ember's memories").
	if event.is_action_pressed("codex"):
		toggle_codex()
		get_viewport().set_input_as_handled()
		return
	# L cycles the UI language (English / Tiếng Việt).
	if event.is_action_pressed("lang"):
		GameState.toggle_lang()
		get_viewport().set_input_as_handled()
		return
	# Esc (cancel): the build menu and an in-progress placement own it; otherwise it
	# toggles the pause menu (CRITIQUE B1). Overlays that manage themselves are skipped.
	if event.is_action_pressed("cancel"):
		if _menu_open:
			close_build_menu()
			build_cancelled.emit()
			get_viewport().set_input_as_handled()
			return
		if _settings_root != null and is_instance_valid(_settings_root):
			_close_settings()
			get_viewport().set_input_as_handled()
			return
		if _pause_root != null and is_instance_valid(_pause_root):
			_close_pause()
			get_viewport().set_input_as_handled()
			return
		if _place_active or (_title_root != null and is_instance_valid(_title_root)) \
				or (_victory_root != null and is_instance_valid(_victory_root)) \
				or (_boon_root != null and is_instance_valid(_boon_root)):
			return   # placement cancel handled by the village; other modals use buttons
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if not _menu_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var idx := -1
		match event.physical_keycode:
			KEY_1: idx = 0
			KEY_2: idx = 1
			KEY_3: idx = 2
			KEY_4: idx = 3
		if idx >= 0 and idx < _menu_ids.size():
			_select(_menu_ids[idx])
			get_viewport().set_input_as_handled()
