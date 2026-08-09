class_name Main
extends Node
## Scene manager and glue. Owns the single persistent Player, the follow Camera2D
## (mouse-wheel zoom), and the Hud. Swaps between the Village and Dungeon layers,
## reparenting the player so it survives the transition, and runs the central
## interaction scan for the whole game.

var _layer: Node2D = null
var _player: Player = null
var _hud: Hud = null
var _camera: Camera2D = null
var _returning: bool = false

func _ready() -> void:
	randomize()

	_hud = Hud.new()
	add_child(_hud)

	_player = Player.new()
	add_child(_player)
	_player.z_index = 10
	_player.hp_changed.connect(_hud.set_hp)
	_player.died.connect(_on_player_died)

	_camera = Camera2D.new()
	add_child(_camera)
	# Hades-like framing: at 1.85 the view is ~692x389 world px, about 14x8 cells,
	# so a ~53 px-tall character occupies roughly an eighth of the screen height
	# and there is always floor visible around a fight.
	_camera.zoom = Vector2(1.85, 1.85)
	_camera.make_current()
	# Juice drives shake through the camera's offset, leaving the follow position
	# below free for us.
	Juice.register_camera(_camera)

	return_to_village()

# ---------------------------------------------------------------------------
# Layer transitions
# ---------------------------------------------------------------------------
func start_dungeon() -> void:
	var d := Dungeon.new()
	_install_layer(d, true)
	d.exited.connect(_on_dungeon_exited)

func return_to_village() -> void:
	_returning = false
	var v := Village.new()
	_install_layer(v, false)
	v.expedition_requested.connect(start_dungeon)

func _install_layer(layer: Node2D, is_dungeon: bool) -> void:
	# Cancel any in-flight shake/hit-stop: the world it belonged to is going away.
	Juice.reset()
	# Detach the player from the old layer so freeing it doesn't take the player.
	if is_instance_valid(_player) and _player.get_parent() != null:
		_player.get_parent().remove_child(_player)
	if is_instance_valid(_layer):
		_layer.queue_free()
	_layer = layer
	layer.hud = _hud
	add_child(layer)                    # runs layer._ready(): builds the world
	layer.add_child(_player)            # reparent the persistent player into it
	_player.global_position = layer.spawn_point()
	if is_dungeon:
		GameState.run_count += 1
		_player.begin_run()
		# Rescue buffs are permanent: re-apply one per rescued survivor on top of
		# the fresh baseline so descents keep the bonuses earned in past runs.
		for pillar in GameState.rescued:
			var b := _buff_for_pillar(pillar)
			if b != "":
				_player.apply_buff(b)
	else:
		_player.enter_village()
	_hud.set_hp(_player.hp, _player.max_hp)
	_hud.hide_prompt()
	_camera.global_position = _player.global_position
	_apply_camera_bounds(layer)

# Fence the camera into the layer's rendered extent. Without this, following the
# player to the edge of a room slides half the screen into black nothing — which
# only became visible once the camera was pulled back to Hades framing.
func _apply_camera_bounds(layer: Node2D) -> void:
	if not is_instance_valid(_camera):
		return
	if layer == null or not layer.has_method("camera_bounds"):
		return
	var b: Rect2 = layer.call("camera_bounds")
	if b.size.x <= 0.0 or b.size.y <= 0.0:
		return
	_camera.limit_left = int(floor(b.position.x))
	_camera.limit_top = int(floor(b.position.y))
	_camera.limit_right = int(ceil(b.end.x))
	_camera.limit_bottom = int(ceil(b.end.y))

# Same pillar→buff mapping the Survivor uses, so re-applied bonuses match rescues.
func _buff_for_pillar(pillar: String) -> String:
	match pillar:
		"farmer":
			return "armor"
		"smith":
			return "damage"
		"builder":
			return "speed"
	return ""

func _on_dungeon_exited() -> void:
	if _returning:
		return
	return_to_village()

func _on_player_died() -> void:
	if _returning:
		return
	_returning = true
	if _hud:
		_hud.toast("You fell in the dark...", Palette.BLOOD)
	get_tree().create_timer(1.6).timeout.connect(return_to_village)

# ---------------------------------------------------------------------------
# Per-frame: camera follow + interaction scan
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if is_instance_valid(_player) and is_instance_valid(_camera):
		_camera.global_position = _camera.global_position.lerp(
			_player.global_position, clampf(delta * 8.0, 0.0, 1.0))
	_scan_interaction()

func _scan_interaction() -> void:
	if not is_instance_valid(_player) or _player.get_parent() == null:
		if _hud:
			_hud.hide_prompt()
		return
	var best = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		if not (n is Node2D):
			continue
		if not n.has_method("can_interact") or not n.can_interact(_player):
			continue
		var r: float = 34.0
		if n.has_method("interact_radius"):
			r = float(n.interact_radius())
		var dist: float = n.global_position.distance_to(_player.global_position)
		if dist <= r and dist < best_d:
			best_d = dist
			best = n
	if best != null:
		var prompt := "[E]"
		if best.has_method("interact_prompt"):
			prompt = str(best.interact_prompt())
		if _hud:
			_hud.show_prompt(prompt)
		if Input.is_action_just_pressed("interact") and best.has_method("do_interact"):
			best.do_interact(_player)
	elif _hud:
		_hud.hide_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(0.2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(-0.2)

func _zoom(step: float) -> void:
	if not is_instance_valid(_camera):
		return
	var z := clampf(_camera.zoom.x + step, 1.2, 2.8)
	_camera.zoom = Vector2(z, z)
