extends Node
## Verification harness (not shipped). Instances the real Main scene, drives it
## through its interesting states and saves screenshots to res://_shot_*.png so
## the build can be judged by eye.
##   godot --path . res://tools/capture.tscn
##
## Deliberately defensive: it finds the player, hud and current layer by group and
## by duck-typing rather than reaching into Main's private fields.

var main: Node
var f: int = 0

func _ready() -> void:
	main = Main.new()
	add_child(main)

func _process(_delta: float) -> void:
	f += 1
	match f:
		20:
			await _shot("01_village_cold")
		26:
			_warm_and_build()
		30:
			_place_scaffold()
		34:
			_hammer()
		36:
			await _shot("02_village_building")
		60:
			await _shot("03_village_warm")
		66:
			_descend()
		96:
			_drag_enemies_close()
		100:
			_swing()
		102:
			await _shot("04_dungeon_fight")
		116:
			_dash()
		119:
			await _shot("05_dungeon_dash")
		140:
			await _shot("06_dungeon_wide")
		146:
			get_tree().quit()

# --- Scene poking -----------------------------------------------------------

func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

# The active world layer is the Node2D child of Main that can place the player.
func _layer() -> Node2D:
	for c in main.get_children():
		if c is Node2D and c.has_method("spawn_point"):
			return c as Node2D
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

# Drop an unfinished plot next to the hero so the scaffold is in frame.
func _place_scaffold() -> void:
	var layer := _layer()
	if layer == null or not layer.has_method("_spawn_scaffold"):
		return
	var cell := Vector2i(4, 4)
	GameState.grid[cell] = {"type": "cabin", "built": false}
	layer.call("_spawn_scaffold", cell, "cabin")

# Swing the hammer at whatever scaffold is standing, for the construction FX.
func _hammer() -> void:
	var p := _player()
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.has_method("do_interact") and String(n.get_class()) == "Node2D" \
				and n.has_method("_apply_progress"):
			n.call("do_interact", p)
			return

func _descend() -> void:
	if main.has_method("start_dungeon"):
		main.call("start_dungeon")

# Walk a couple of husks into melee range so the fight frame has contact in it.
func _drag_enemies_close() -> void:
	var p := _player()
	if p == null:
		return
	var i := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		var en := e as Node2D
		if en == null:
			continue
		en.global_position = p.global_position + Vector2(34.0 + float(i) * 16.0, -6.0)
		i += 1
		if i >= 2:
			break

# Fire one melee swing so the arc, impact and hit reaction all land in frame.
func _swing() -> void:
	var p := _player()
	if p != null and p.has_method("_swing"):
		p.call("_swing")

func _dash() -> void:
	var p := _player()
	if p != null and p.has_method("_try_dash"):
		p.call("_try_dash")

func _shot(sname: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://_shot_%s.png" % sname)
	print("CAPTURED ", sname)
