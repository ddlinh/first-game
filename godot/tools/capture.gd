extends Node
## Verification harness (not shipped). Instances the real Main scene, drives the
## core loop through its interesting states, and saves screenshots to
## res://_shot_*.png so the build can be judged by eye rather than by compiling.
##   godot --path . res://tools/capture.tscn
##
## Deliberately defensive: it finds the player, hud and current layer by group and
## by duck-typing rather than by touching Main's private fields, so it keeps
## working while Main is being rewritten.

var main: Node
var f: int = 0

func _ready() -> void:
	# A Bloom's boon card (QA D-01) pauses the tree; keep THIS harness ticking through
	# the pause (ALWAYS) while the game world pauses normally (PAUSABLE), so we can
	# still shoot and then dismiss the card.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Skip the first-descent combat intro: it now freezes the fight until the player
	# advances it (QA F-25), and this harness never clicks through dialogue — so let
	# it shoot real post-tutorial combat instead of a frozen tutorial room.
	GameState.combat_tutorial_seen = true
	GameState.lang = "en"   # canonical English screenshots, regardless of the saved setting
	Main.skip_title = true  # boot straight into the village, past the new title menu
	main = Main.new()
	main.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(main)

func _process(_delta: float) -> void:
	f += 1
	match f:
		18:
			await _shot("01_village_cold")
		24:
			_warm_and_build()
		30:
			_prompt("Hammer  [E]  (34%)")
		38:
			_hud().call("toggle_codex")     # the knowledge Codex (QA D-06)
		44:
			await _shot("15_codex")         # metallurgy + construction recovered; rest locked
		48:
			_hud().call("toggle_codex")     # close it
		50:
			await _shot("02_village_warm")
		56:
			_open_menu()
		64:
			await _shot("03_build_menu")
		68:
			_close_menu()
		72:
			_zoom_in()
		80:
			await _shot("04_hero_closeup")
		86:
			_zoom_out()
			_descend()
		96:
			_prompt("Free farmer  [E]")
		110:
			_walk_into_the_room()
		120:
			_free_survivor()               # rescue → attunement banner + trailing companion
		126:
			await _shot("05_dungeon")
		128:
			_telegraph_husks()             # force wind-ups so the telegraph reads (QA F-04)
		131:
			await _shot("16_telegraph")    # glowing tells the player can parry/dodge
		132:
			_swing()
		136:
			await _shot("06_dungeon_fight")
		140:
			_bloom_now(9.0)                # +9 Kindle crosses the stage-1 (Pioneer) threshold
			                               # → a Bloom → the pick-1-of-3 BOON card (QA D-01)
		166:
			await _shot("07_bloom_boon")   # the boon draft card, world paused behind it
		172:
			_dismiss_boon()                # take the first boon → unpause + apply
		178:
			_hud().call("toggle_character")  # open the progression sheet
		186:
			await _shot("08_character_sheet")
		192:
			_hud().call("toggle_character")  # close it
		198:
			_force_boss_room()             # same-run advance → companion must carry over
		208:
			await _shot("09_companion_carried")
		216:
			_walk_into_the_room()
		228:
			await _shot("10_boss_warden")
		236:
			var carried := get_tree().get_nodes_in_group("companion").size()
			print("COMPANIONS_AFTER_TRANSITION=", carried)
			if main.has_method("return_to_village"):
				main.call("return_to_village")
		242:
			# Run-summary card (QA F-02): a live bank return with a full tally.
			_hud().call("show_run_summary", {
				"alive": true, "rooms": 3, "husks": 11, "rescues": ["farmer"],
				"kept": {"wood": 4, "stone": 2, "iron": 1}, "lost": {},
				"kindle": 46, "blooms": 3})
		252:
			await _shot("11_run_summary")
		258:
			# Enter build placement so the grid + cell box guide renders (QA F-20).
			var lyr := _layer()
			if lyr != null and lyr.has_method("_on_build_selected"):
				lyr.call("_on_build_selected", "cabin")
		266:
			await _shot("12_placement")
		272:
			# Exit placement and descend again so we can verify the death→revive loop
			# (the review-caught blocker: enter_village must clear _dead).
			var lyr2 := _layer()
			if lyr2 != null and lyr2.has_method("_exit_placement"):
				lyr2.call("_exit_placement")
			main.call("start_dungeon")
		286:
			var pd := _player()
			if pd != null:
				pd.call("take_damage", 999)   # force death
		298:
			await _shot("13_death")            # collapsed corpse in the ruin
		396:
			# ~1.8s after death: past Main's 1.6s return timer, we should be alive
			# in the village again, not a frozen corpse.
			var pr := _player()
			var dead := bool(pr.get("_dead")) if pr != null else true
			var enabled := bool(pr.get("combat_enabled")) if pr != null else true
			print("AFTER_DEATH  _dead=", dead, "  combat_enabled=", enabled)
		404:
			await _shot("14_revived_village")
		410:
			# Farm chain (VILLAGE_DESIGN P1): the Farmer lays out fallow ground that needs
			# supplies before it can be worked.
			if not GameState.has_rescued("farmer"):
				GameState.rescued.append("farmer")
			GameState.farm_state = "none"
			main.call("return_to_village")
		418:
			await _shot("17_farm_fallow")
		424:
			# Win screen (CRITIQUE B4/A1): the Ember's epilogue at full warmth.
			_hud().call("show_victory", {"runs": 4, "rescued": 3, "buildings": 5})
		432:
			await _shot("18_victory")
		438:
			_hud().call("_dismiss_victory")
		444:
			_hud().call("show_title")            # title screen (CRITIQUE B1)
		452:
			await _shot("19_title")
		458:
			_hud().call("_dismiss_title")
		464:
			_hud().call("toggle_pause")          # pause menu (CRITIQUE B1)
		472:
			await _shot("20_pause")
		480:
			get_tree().quit()

# --- Scene poking -----------------------------------------------------------

func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

# The Hud is the CanvasLayer child of Main that can toast.
func _hud() -> Node:
	for c in main.get_children():
		if c is CanvasLayer and c.has_method("toast"):
			return c
	return null

# The active world layer is the Node2D child of Main that can place the player.
func _layer() -> Node2D:
	for c in main.get_children():
		if c is Node2D and c.has_method("spawn_point"):
			return c as Node2D
	return null

func _camera() -> Camera2D:
	for c in main.get_children():
		if c is Camera2D:
			return c as Camera2D
	return null

# --- Staged states ----------------------------------------------------------

# Raise a couple of buildings and crank the warmth so the reignited village shows.
func _warm_and_build() -> void:
	var layer := _layer()
	if layer != null and layer.has_method("finish_building"):
		GameState.grid[Vector2i(3, 3)] = {"type": "cabin", "built": false}
		GameState.grid[Vector2i(5, 4)] = {"type": "forge", "built": false}
		layer.call("finish_building", Vector2i(3, 3), "cabin")
		layer.call("finish_building", Vector2i(5, 4), "forge")
	GameState.add_resource("wood", 9)
	GameState.add_resource("stone", 6)
	GameState.add_resource("iron", 3)
	GameState.set_gwi(0.62)

func _prompt(text: String) -> void:
	var h := _hud()
	if h != null:
		h.call("show_prompt", text)

func _open_menu() -> void:
	var h := _hud()
	if h == null:
		return
	# Full entries mirroring Village._open_build_menu (icon + effect blurb + warmth), so
	# the canonical screenshot shows the real build-menu card, not a bare stub.
	h.call("open_build_menu", [
		{"id": "cabin", "label": "Cabin", "cost": {"wood": 5, "stone": 2}, "affordable": true,
			"tex": "building_cabin", "warm": 0.18,
			"desc": "Shelter for a survivor. Toughens you (+Max HP) on your next descent."},
		{"id": "forge", "label": "Forge", "cost": {"stone": 4, "iron": 2}, "affordable": true,
			"tex": "building_forge", "warm": 0.15,
			"desc": "Work iron into blades. Sharpens your strikes (+Damage) below."},
		{"id": "crop_bed", "label": "Crop Bed", "cost": {"wood": 3}, "affordable": false,
			"tex": "building_crop_bed", "warm": 0.05,
			"desc": "Tilled soil to grow food — seeds become Provisions that heal mid-run."},
		{"id": "expand", "label": "Expand Clearing", "cost": {"wood": 10, "stone": 6}, "affordable": true,
			"tex": "tile_grass", "warm": 0.0,
			"desc": "Tend one more ring of wild land so you can build farther out."},
	])

func _close_menu() -> void:
	var h := _hud()
	if h != null:
		h.call("close_build_menu")

func _zoom_in() -> void:
	# Main drives the camera zoom every frame, so push its base rather than the node.
	main.set("_base_zoom", 4.4)

func _zoom_out() -> void:
	main.set("_base_zoom", 2.4)

func _descend() -> void:
	if main.has_method("start_dungeon"):
		main.call("start_dungeon")

# Nudge the hero off the entrance so the room is seen from inside it.
func _walk_into_the_room() -> void:
	var p := _player()
	if p != null:
		p.global_position += Vector2(0.0, -170.0 * Palette.SQUASH)

# Free the caged survivor in the current room (tests the attunement banner + the
# companion that must trail the hero across the next room transition).
func _free_survivor() -> void:
	var p := _player()
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.has_method("free_it"):
			n.call("free_it", p)
			return

# Swap in a boss room so the Warden bar is exercised. Builds a Dungeon directly
# and installs it through Main (same-run advance), bypassing the RunMap roll.
func _force_boss_room() -> void:
	var d := Dungeon.new()
	d.node_type = "boss"
	d.room_index = 3
	if main.has_method("_install_layer"):
		main.call("_install_layer", d, true, false)

# Fire one melee swing so slash + impact VFX land in the combat frame.
func _swing() -> void:
	var p := _player()
	if p != null and p.has_method("_start_attack"):
		p.call("_start_attack", 0)   # combo step 1 (the right crescent)

# Force up to two husks into their telegraphed wind-up so the tell is on screen
# (QA F-04 — the swelling warn-ring the player reacts to).
func _telegraph_husks() -> void:
	var p := _player()
	if p == null:
		return
	# Stage two husks close to the hero so the swelling warn-ring reads at this zoom.
	var offs := [Vector2(84.0, -12.0), Vector2(-80.0, 8.0)]
	var n := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if n >= 2:
			break
		if e.has_method("_begin_windup"):
			(e as Node2D).global_position = p.global_position + offs[n]
			e.call("_begin_windup", p)
			n += 1

# Feed the hero Kindle directly to force a Bloom (→ the boon card) for the shot.
func _bloom_now(amount: float) -> void:
	var p := _player()
	if p != null and p.has_method("gain_kindle"):
		p.call("gain_kindle", amount)

# Take the first offered boon, dismissing the card and un-pausing the world.
func _dismiss_boon() -> void:
	var h := _hud()
	if h != null and h.has_method("boon_open") and bool(h.call("boon_open")):
		h.call("pick_boon_index", 0)

func _shot(sname: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://_shot_%s.png" % sname)
	print("CAPTURED ", sname)
