class_name HudMenus
extends RefCounted
## The full-screen menu / overlay shell, split out of the Hud god-object (CRITIQUE C3):
## title, pause, settings, the yes/no confirm dialog, the victory epilogue, and the
## player-paced run-summary / death card. Owned by the Hud (one instance), it builds its
## overlays under the Hud's `_root` and reaches back through `_hud` for the handful of
## HUD-owned facts it needs (combat flag, other modal roots, toast). The Hud keeps thin
## public delegators, and routes the Esc / modal-key stack here via handle_modal_input()
## and handle_cancel(). Behaviour is identical to the old in-Hud code.

# Untyped on purpose: keeps this off a circular class_name dependency with Hud (which
# already types `var _menus: HudMenus`). Accesses like _hud._root are resolved at runtime.
var _hud = null

# The full-screen modal roots this shell owns.
var _title_root: Control = null
var _pause_root: Control = null
var _settings_root: Control = null
var _confirm_root: Control = null    # yes/no guard over a destructive action (CRITIQUE N1/N2)
var _victory_root: Control = null
var _summary_root: Control = null    # player-paced run-summary / death card (CRITIQUE B7)

func _init(hud) -> void:
	_hud = hud

# --- Modal-state queries used by the Hud's _input routing ---------------------
func title_open() -> bool:
	return _title_root != null and is_instance_valid(_title_root)

func victory_open() -> bool:
	return _victory_root != null and is_instance_valid(_victory_root)

func confirm_open() -> bool:
	return _confirm_root != null and is_instance_valid(_confirm_root)

func summary_open() -> bool:
	return _summary_root != null and is_instance_valid(_summary_root)

func dismiss_summary() -> void:
	_dismiss_summary()

# The confirm dialog and the run-summary card are the two topmost modals: while either is
# up it handles Esc / dismiss keys and swallows the other HUD hotkeys. Returns true if it
# consumed the event (so the Hud's _input returns immediately). Mirrors the old guards.
func handle_modal_input(event: InputEvent) -> bool:
	if _confirm_root != null and is_instance_valid(_confirm_root):
		if event.is_action_pressed("cancel"):
			_close_confirm()
			_hud.get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo:
			match event.physical_keycode:
				KEY_TAB, KEY_C, KEY_K, KEY_L, KEY_B:
					_hud.get_viewport().set_input_as_handled()
		return true
	if _summary_root != null and is_instance_valid(_summary_root):
		if event.is_action_pressed("cancel"):
			_dismiss_summary()
			_hud.get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo:
			match event.physical_keycode:
				KEY_E, KEY_ENTER, KEY_KP_ENTER:
					_dismiss_summary()
					_hud.get_viewport().set_input_as_handled()
				KEY_TAB, KEY_C, KEY_K, KEY_L, KEY_B:
					_hud.get_viewport().set_input_as_handled()
		return true
	return false

# Esc routing for the menu modals (called by the Hud after it checks the build menu):
# settings and pause close; returns true if it consumed the cancel. Title/victory consume
# via their own buttons (the Hud checks title_open()/victory_open() separately).
func handle_cancel() -> bool:
	if _settings_root != null and is_instance_valid(_settings_root):
		_close_settings()
		return true
	if _pause_root != null and is_instance_valid(_pause_root):
		_close_pause()
		return true
	return false

# --- Shared button helper (title / pause / settings / confirm) ----------------
# Keyboard/controller navigable (CRITIQUE N3): arrow-keys move focus, Enter/Space activate,
# the focus stylebox makes the current selection legible without a mouse.
func _big_button(text: String) -> Button:
	var b := Button.new()
	b.text = Loc.t(text)
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(300, 46)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Palette.UI_TEXT)
	b.add_theme_stylebox_override("normal", UiKit.button_style(false))
	b.add_theme_stylebox_override("hover", UiKit.button_style(true))
	b.add_theme_stylebox_override("pressed", UiKit.button_style(true))
	b.add_theme_stylebox_override("focus", UiKit.button_style(true))
	b.pressed.connect(_ui_click)   # a soft click on every title/pause button (B3)
	return b

func _ui_click() -> void:
	Sfx.play("ui", -9.0)

func _quit_game() -> void:
	_hud.get_tree().quit()

# --- Confirmation dialog (CRITIQUE N1/N2) -------------------------------------
func confirm(title: String, body: String, yes_label: String, on_yes: Callable) -> void:
	if _confirm_root != null and is_instance_valid(_confirm_root):
		return
	_confirm_root = Control.new()
	_confirm_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_hud._root.add_child(_confirm_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_root.add_child(cc)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.menu_style())
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.custom_minimum_size = Vector2(460, 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vb)
	var t := UiKit.label(title, 24, Palette.GOLD_L)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var b := UiKit.label(body, 16, Palette.UI_TEXT)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD
	b.custom_minimum_size = Vector2(440, 0)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	var yes := _big_button(yes_label)
	yes.custom_minimum_size = Vector2(210, 46)
	yes.add_theme_color_override("font_color", Palette.BLOOD)   # danger read on the destructive choice
	yes.pressed.connect(func() -> void:
		_close_confirm()
		on_yes.call())
	row.add_child(yes)
	var no := _big_button("Cancel")
	no.custom_minimum_size = Vector2(210, 46)
	no.pressed.connect(_close_confirm)
	row.add_child(no)
	no.grab_focus.call_deferred()   # default to the safe choice

func _close_confirm() -> void:
	if _confirm_root != null and is_instance_valid(_confirm_root):
		_confirm_root.queue_free()
		_confirm_root = null

# --- Title screen -------------------------------------------------------------
func show_title() -> void:
	if _title_root != null and is_instance_valid(_title_root):
		return
	_hud.get_tree().paused = true
	_title_root = Control.new()
	_title_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_hud._root.add_child(_title_root)
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
	UiKit.ignore(seal)
	vb.add_child(seal)
	var title := UiKit.label("REKINDLED", 52, Palette.GOLD_L)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := UiKit.label("Carry the last ember home.", 18, Palette.AMBER)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	# A rekindled-world seal on the title once you've won (CRITIQUE N4) — the finisher leaves
	# a mark on the menu, and the deep-ruins record is shown as the standing challenge.
	var sm: Dictionary = GameState.save_summary()
	if bool(sm.get("won", false)):
		var seal_line := UiKit.label("✦  " + Loc.t("The world you rekindled") + "  ✦", 15, Palette.GOLD_L)
		seal_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(seal_line)
		var deep: int = int(sm.get("deepest_run", 0))
		if deep > 0:
			var rec := UiKit.label(Loc.t("Deepest ruin: %d chambers") % deep, 13, Palette.CYAN)
			rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vb.add_child(rec)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	UiKit.ignore(spacer)
	vb.add_child(spacer)
	var nb := _big_button("New Game")
	nb.pressed.connect(_title_new)
	vb.add_child(nb)
	if GameState.has_save():
		var cb := _big_button("Continue")
		cb.pressed.connect(_title_continue)
		vb.add_child(cb)
		# Context under Continue so a returning player knows what they're loading into,
		# rather than a bare button (CRITIQUE N5). Reuses the summary peeked above.
		if not sm.is_empty():
			var ctx := UiKit.label(_continue_context(sm), 13, Palette.UI_DIM)
			ctx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vb.add_child(ctx)
	var stb := _big_button("Settings")
	stb.pressed.connect(show_settings)
	vb.add_child(stb)
	var qb := _big_button("Quit")
	qb.pressed.connect(_quit_game)
	vb.add_child(qb)
	nb.grab_focus.call_deferred()   # keyboard/controller starts on New Game (CRITIQUE N3)

func _dismiss_title() -> void:
	_hud.get_tree().paused = false
	if _title_root != null and is_instance_valid(_title_root):
		_title_root.queue_free()
		_title_root = null

# One dim line of Continue context (CRITIQUE N5): how far in, who's home, how warm, and
# when it was last saved — built from a lightweight peek at the save (GameState.save_summary).
func _continue_context(sm: Dictionary) -> String:
	var runs: int = int(sm.get("run_count", 0))
	var rescued: int = int(sm.get("rescued", 0))
	var warm: int = int(round(clampf(float(sm.get("gwi", 0.0)), 0.0, 1.0) * 100.0))
	# A save can be written in the village before the first descent (run_count == 0) — say
	# so, rather than an ordinal-zero "Descent 0" that never happened.
	var head: String = Loc.t("Not yet descended") if runs <= 0 else (Loc.t("Descent %d") % runs)
	var line: String = "%s   ·   %s   ·   %s" % [head, Loc.t("%d rescued") % rescued, Loc.t("%d%% warm") % warm]
	var at: int = int(sm.get("saved_at", 0))
	if at > 0:
		line += "   ·   " + _saved_when(at)
	return line

# A localized "saved N ago" phrase from a unix timestamp (each branch is one whole
# template, so Vietnamese word order stays natural).
func _saved_when(unix_ts: int) -> String:
	var s: int = maxi(0, int(Time.get_unix_time_from_system()) - unix_ts)
	if s < 90:
		return Loc.t("saved just now")
	if s < 3600:
		return Loc.t("saved %d min ago") % (s / 60)
	if s < 86400:
		return Loc.t("saved %d hr ago") % (s / 3600)
	return Loc.t("saved %d days ago") % (s / 86400)

func _title_new() -> void:
	# Guard the save: New Game wipes the village, survivors, and warmth (CRITIQUE N1).
	if GameState.has_save():
		confirm("Start a new game?",
			"This erases your saved village, survivors, and warmth — it cannot be undone.",
			"Erase & start",
			func() -> void:
				_dismiss_title()
				Main.start_new_game())
	else:
		_dismiss_title()
		Main.start_new_game()

func _title_continue() -> void:
	_dismiss_title()
	Main.continue_game()

# --- Pause menu (Esc during play) ---------------------------------------------
func toggle_pause() -> void:
	if _pause_root != null and is_instance_valid(_pause_root):
		_close_pause()
		return
	# Never pause on top of another modal.
	if _title_root != null and is_instance_valid(_title_root): return
	if _victory_root != null and is_instance_valid(_victory_root): return
	if _hud._boon_root != null and is_instance_valid(_hud._boon_root): return
	if _summary_root != null and is_instance_valid(_summary_root): return
	if _confirm_root != null and is_instance_valid(_confirm_root): return
	if _hud._menu_open or _hud._place_active or _hud._dlg_await: return
	_hud.get_tree().paused = true
	_pause_root = Control.new()
	_pause_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_hud._root.add_child(_pause_root)
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
	panel.add_theme_stylebox_override("panel", UiKit.menu_style())
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vb)
	var t := UiKit.label("PAUSED", 30, Palette.GOLD_L)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var rb := _big_button("Resume")
	rb.pressed.connect(_close_pause)
	vb.add_child(rb)
	var sb := _big_button("Save Game")
	sb.pressed.connect(_pause_save)
	vb.add_child(sb)
	# Once the world is rekindled, the ending is re-readable from here (CRITIQUE N4) —
	# the epilogue was a one-shot with no way back to it.
	if GameState.won:
		var eb := _big_button("The Ember's Epilogue")
		eb.pressed.connect(_replay_epilogue)
		vb.add_child(eb)
	var setb := _big_button("Settings")
	setb.pressed.connect(show_settings)
	vb.add_child(setb)
	var qb := _big_button("Quit to Title")
	qb.pressed.connect(_pause_quit_title)
	vb.add_child(qb)
	rb.grab_focus.call_deferred()   # keyboard/controller starts on Resume (CRITIQUE N3)

func _close_pause() -> void:
	_hud.get_tree().paused = false
	if _pause_root != null and is_instance_valid(_pause_root):
		_pause_root.queue_free()
		_pause_root = null

# Re-open the Ember's epilogue (CRITIQUE N4) — from the pause menu once the world is won.
# Rebuilds the tally from live state; show_victory re-pauses over the closed pause menu.
func _replay_epilogue() -> void:
	_close_pause()
	var built: int = 0
	for key in GameState.grid.keys():
		if bool((GameState.grid[key] as Dictionary).get("built", false)):
			built += 1
	show_victory({
		"runs": GameState.run_count,
		"rescued": GameState.rescued.size(),
		"buildings": built,
		"deepest": GameState.deepest_run,
	})

func _pause_save() -> void:
	Main.save_now()
	_close_pause()
	_hud.toast(Loc.t("Game saved."), Palette.MOSS_L)

func _pause_quit_title() -> void:
	# Mid-run, quitting to the title forfeits the descent and all unbanked loot (CRITIQUE N2).
	if _hud._combat:
		confirm("Abandon this run?",
			"You are still in the ruins. Quitting now forfeits this descent and every material you haven't banked.",
			"Abandon run",
			func() -> void:
				_close_pause()
				Main.quit_to_title())
	else:
		_close_pause()
		Main.quit_to_title()

# --- Settings screen (CRITIQUE B6): audio + accessibility, over title/pause ---
func show_settings() -> void:
	if _settings_root != null and is_instance_valid(_settings_root):
		return
	# The tree is already paused by the title/pause menu beneath; this stacks on top.
	_settings_root = Control.new()
	_settings_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_hud._root.add_child(_settings_root)
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
	panel.add_theme_stylebox_override("panel", UiKit.menu_style())
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(440, 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vb)
	var t := UiKit.label("SETTINGS", 28, Palette.GOLD_L)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	# Volume: a labelled slider.
	var vrow := HBoxContainer.new()
	vrow.add_theme_constant_override("separation", 12)
	vrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(vrow)
	var vlab := UiKit.label("Volume", 18, Palette.UI_TEXT)
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
	back.grab_focus.call_deferred()   # keyboard/controller can reach every setting (CRITIQUE N3)

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

# --- Win screen (CRITIQUE B4/A1): the Ember's epilogue when the world rekindles ---
func show_victory(stats: Dictionary) -> void:
	if _victory_root != null and is_instance_valid(_victory_root):
		return
	_hud.get_tree().paused = true
	_victory_root = Control.new()
	_victory_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_victory_root.process_mode = Node.PROCESS_MODE_ALWAYS   # alive while the world is paused
	_hud._root.add_child(_victory_root)
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
	panel.add_theme_stylebox_override("panel", UiKit.menu_style())
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
	UiKit.ignore(seal)
	vb.add_child(seal)
	var title := UiKit.label("THE WORLD IS REKINDLED", 30, Palette.GOLD_L)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	for line in [
		"The long dark breaks. Warmth climbs back into the world — and it was you who carried it.",
		"Rest now, ember-bearer. What you remembered, and rebuilt, will outlast us both.",
	]:
		var l := UiKit.label(Loc.t(line), 16, Palette.UI_TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.custom_minimum_size = Vector2(540, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(l)
	var tally := "%s %d      %s %d      %s %d      %s 100%%" % [
		Loc.t("Runs survived"), int(stats.get("runs", 0)),
		Loc.t("Rescued"), int(stats.get("rescued", 0)),
		Loc.t("Buildings"), int(stats.get("buildings", 0)),
		Loc.t("Warmth")]
	var tl := UiKit.label(tally, 15, Palette.AMBER)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tl)
	# The post-win destination (CRITIQUE N4): the ruins still run deeper than any light has
	# reached. Point the finisher somewhere — the endless deep-ruins chase is now open.
	var deepest: int = maxi(int(stats.get("deepest", GameState.deepest_run)), GameState.deepest_run)
	var signpost: String = Loc.t("The deep ruins lie open — descend to see how far the dark still goes.")
	if deepest > 0:
		signpost += " " + (Loc.t("Deepest reached: %d chambers.") % deepest)
	var sl := UiKit.label(signpost, 14, Palette.CYAN)
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD
	sl.custom_minimum_size = Vector2(540, 0)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sl)
	var btn := Button.new()
	btn.text = Loc.t("Keep tending your village  ▸")
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Palette.UI_TEXT)
	btn.add_theme_stylebox_override("normal", UiKit.button_style(false))
	btn.add_theme_stylebox_override("hover", UiKit.button_style(true))
	btn.add_theme_stylebox_override("pressed", UiKit.button_style(true))
	btn.pressed.connect(_dismiss_victory)
	vb.add_child(btn)

func _dismiss_victory() -> void:
	_hud.get_tree().paused = false
	if _victory_root != null and is_instance_valid(_victory_root):
		_victory_root.queue_free()
		_victory_root = null

# --- Run summary / death card, player-paced (CRITIQUE B7) ---------------------
func show_run_summary(data: Dictionary) -> void:
	if _hud._root == null or (_summary_root != null and is_instance_valid(_summary_root)):
		return
	var alive: bool = bool(data.get("alive", true))
	# Player-paced now (CRITIQUE B7): the world pauses and the card waits for a Continue —
	# no more 6-second auto-fade that could snatch the record of your run away unread.
	_hud.get_tree().paused = true
	_summary_root = Control.new()
	_summary_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_summary_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_hud._root.add_child(_summary_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.55) if alive else Color(0.14, 0.02, 0.02, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_summary_root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_summary_root.add_child(cc)
	var card := UiKit.panel()
	UiKit.ignore(card)
	cc.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.custom_minimum_size = Vector2(320, 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vb)
	var title := UiKit.label("RUN BANKED" if alive else "YOU FELL IN THE DARK",
		23, Palette.GOLD_L if alive else Palette.BLOOD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	vb.add_child(UiKit.label(Loc.t("Chambers cleared     %d") % int(data.get("rooms", 0)), 15, Palette.UI_TEXT))
	vb.add_child(UiKit.label(Loc.t("Husks felled         %d") % int(data.get("husks", 0)), 15, Palette.UI_TEXT))
	var rescues: Array = data.get("rescues", [] as Array)
	if not rescues.is_empty():
		var names: Array[String] = []
		for r in rescues:
			names.append(Loc.t(String(r).capitalize()))
		vb.add_child(UiKit.label(Loc.t("Rescued: ") + ", ".join(names), 15, Palette.MOSS_L))
	vb.add_child(UiKit.label(Loc.t("Kindle gathered     +%d") % int(data.get("kindle", 0)), 15, Palette.GOLD_L))
	var blooms: int = int(data.get("blooms", 0))
	if blooms > 0:
		vb.add_child(UiKit.label(Loc.t("Blooms              %d") % blooms, 15, Palette.EMBER))
	var kept_str: String = _loot_str(data.get("kept", {}))
	if alive:
		vb.add_child(UiKit.label(Loc.t("Loot banked: ") + (kept_str if kept_str != "" else Loc.t("nothing")), 15, Palette.AMBER))
	else:
		vb.add_child(UiKit.label(Loc.t("Salvaged: ") + (kept_str if kept_str != "" else Loc.t("nothing")), 15, Palette.AMBER))
		var lost_str: String = _loot_str(data.get("lost", {}))
		vb.add_child(UiKit.label(Loc.t("Lost to the dark: ") + (lost_str if lost_str != "" else Loc.t("nothing")), 14, Palette.UI_DIM))
	# The village stake (VILLAGE_DESIGN P6): report any cold snap that struck while you were
	# away — warded off by watchtowers, or a bite out of the village's warmth.
	var snap: Dictionary = GameState.last_cold_snap
	if bool(snap.get("hit", false)):
		var dp: int = int(round(float(snap.get("drop", 0.0)) * 100.0))
		if bool(snap.get("warded", false)) or dp <= 0:
			vb.add_child(UiKit.label("❄ " + Loc.t("The watchtowers held the cold at bay."), 14, Palette.MOSS_L))
		elif int(snap.get("towers", 0)) > 0:
			vb.add_child(UiKit.label("❄ " + (Loc.t("A cold snap struck — the watchtowers softened it to −%d%% warmth.") % dp), 14, Palette.WINE))
		else:
			vb.add_child(UiKit.label("❄ " + (Loc.t("A cold snap struck the village — warmth −%d%%.") % dp), 14, Palette.WINE))
	# Autosave cue (CRITIQUE N5): returning home banked your progress — say so, right here on
	# the card the player always sees on a bank/death return, so they know it's safe to stop.
	vb.add_child(UiKit.label("✓ " + Loc.t("Progress saved"), 13, Palette.CYAN))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	UiKit.ignore(sp)
	vb.add_child(sp)
	var cont := _big_button("Continue  ▸")
	cont.custom_minimum_size = Vector2(0, 42)
	cont.pressed.connect(_dismiss_summary)
	vb.add_child(cont)
	cont.grab_focus.call_deferred()

func _dismiss_summary() -> void:
	_hud.get_tree().paused = false
	if _summary_root != null and is_instance_valid(_summary_root):
		_summary_root.queue_free()
		_summary_root = null

# "3 wood, 1 iron" style summary of a loot dict (empty string if nothing).
func _loot_str(d: Dictionary) -> String:
	var parts: Array[String] = []
	for k in ["wood", "stone", "iron"]:
		var n: int = int(d.get(k, 0))
		if n > 0:
			parts.append("%d %s" % [n, Loc.t(k)])
	return ", ".join(parts)
