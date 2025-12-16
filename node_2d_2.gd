# AscendLinesLocked.gd
extends Node

@export var player_path: NodePath = NodePath("")

# Ascend tunables
const HOLD_TIME_TO_ACTIVATE: float = 3.0
const MAX_ASCEND_TIME: float = 10.0
const ASCEND_SPEED: float = 420.0  # faster upward speed

# Visual tunables
const LINES_COUNT: int = 14
const BASE_LINE_WIDTH: float = 2.0
const THICK_LINE_WIDTH: float = 6.0
const LINE_ALPHA: float = 0.6
const MIN_LINE_HEIGHT_RATIO: float = 0.18  # smallest line height as fraction of screen
const MAX_LINE_HEIGHT_RATIO: float = 0.48  # largest line height as fraction of screen
const LINES_VERTICAL_CENTER_RATIO: float = 0.45 # center band vertical position (0..1)

# Internal state
var player: CharacterBody2D = null
var hold_timer: float = 0.0
var ascend_timer: float = 0.0
var is_ascending: bool = false

# runtime nodes
var overlay_layer: CanvasLayer = null
var lines: Array = []  # holds Line2D nodes
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	# find player (auto-detect parent if not set)
	if player_path != NodePath(""):
		player = get_node_or_null(player_path)
	if not player:
		var p = get_parent()
		if p and p is CharacterBody2D:
			player = p

	# create overlay layer for lines
	overlay_layer = CanvasLayer.new()
	overlay_layer.name = "AscendLinesLayer"
	if get_tree() and get_tree().root:
		get_tree().root.add_child(overlay_layer)
	else:
		add_child(overlay_layer)

	rng.randomize()
	_create_vertical_lines()

func _create_vertical_lines() -> void:
	# clear existing
	for l in lines:
		if l and l.is_inside_tree():
			l.queue_free()
	lines.clear()

	# viewport size
	var vs: Vector2 = Vector2(800, 600)
	if get_viewport():
		vs = get_viewport().get_visible_rect().size

	# compute vertical band where lines will appear (centered band, not full height)
	var band_center_y = vs.y * LINES_VERTICAL_CENTER_RATIO
	# each line will have a random height between MIN and MAX ratio of screen height
	for i in range(LINES_COUNT):
		var x = vs.x * float(i + 1) / float(LINES_COUNT + 1)
		# jitter x slightly so lines aren't perfectly evenly spaced
		x += rng.randf_range(-vs.x * 0.03, vs.x * 0.03)

		var height_ratio = rng.randf_range(MIN_LINE_HEIGHT_RATIO, MAX_LINE_HEIGHT_RATIO)
		var half_h = (vs.y * height_ratio) * 0.5
		var y0 = clamp(band_center_y - half_h, 0, vs.y)
		var y1 = clamp(band_center_y + half_h, 0, vs.y)

		var line = Line2D.new()
		line.name = "AscendLine_%d" % i
		# make some lines thicker: every 3rd line thicker for variety
		if i % 3 == 0:
			line.width = THICK_LINE_WIDTH
		else:
			# small random variation around base width
			line.width = BASE_LINE_WIDTH + rng.randi_range(0, 2)
		line.default_color = Color(1, 1, 1, 0.0) # start invisible
		line.antialiased = true
		line.points = [Vector2(x, y0), Vector2(x, y1)]
		overlay_layer.add_child(line)
		lines.append(line)

func _physics_process(delta: float) -> void:
	# if viewport resized, recreate lines to match new size
	if overlay_layer and get_viewport():
		var rect = get_viewport().get_visible_rect()
		if lines.size() > 0:
			var first = lines[0]
			if first.points.size() == 2 and first.points[1].y != rect.size.y * (LINES_VERTICAL_CENTER_RATIO + MAX_LINE_HEIGHT_RATIO * 0.5):
				_create_vertical_lines()

	if not player:
		return

	var vel: Vector2 = player.velocity

	var pressing: bool = Input.is_action_pressed("shiftr")
	var just_pressed: bool = Input.is_action_just_pressed("shiftr")

	# If ascending and user taps the key, stop ascending
	if is_ascending and just_pressed:
		_stop_ascending()
		return

	# If not ascending, accumulate hold time to activate
	if not is_ascending:
		if pressing:
			hold_timer += delta
			if hold_timer >= HOLD_TIME_TO_ACTIVATE:
				_start_ascending(vel)
		else:
			hold_timer = 0.0
	else:
		# maintain ascend and check stop conditions
		ascend_timer += delta

		var hit_wall: bool = false
		if player.has_method("is_on_wall"):
			hit_wall = player.is_on_wall()

		if ascend_timer >= MAX_ASCEND_TIME or hit_wall:
			_stop_ascending()
			return

		# lock horizontal movement by zeroing x velocity while ascending
		vel.x = 0.0

		# apply upward velocity (respect optional gravity_direction)
		var gdir: int = 1
		if player.has_method("get") and player.get("gravity_direction") != null:
			gdir = int(player.get("gravity_direction"))
		vel.y = -ASCEND_SPEED * gdir
		player.velocity = vel

func _start_ascending(initial_vel: Vector2) -> void:
	is_ascending = true
	hold_timer = 0.0
	ascend_timer = 0.0

	# set immediate upward velocity and zero horizontal movement
	var gdir: int = 1
	if player.has_method("get") and player.get("gravity_direction") != null:
		gdir = int(player.get("gravity_direction"))
	initial_vel.x = 0.0
	initial_vel.y = -ASCEND_SPEED * gdir
	player.velocity = initial_vel

	_show_lines(true)

func _stop_ascending() -> void:
	is_ascending = false
	hold_timer = 0.0
	ascend_timer = 0.0

	_show_lines(false)

func _show_lines(visible: bool) -> void:
	var a = LINE_ALPHA if visible else 0.0
	for line in lines:
		if line and line.is_inside_tree():
			var c = line.default_color
			line.default_color = Color(c.r, c.g, c.b, a)
