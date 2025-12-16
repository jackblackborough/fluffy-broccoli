# AirDash.gd
extends Node

@export_node_path
var player_path: NodePath = NodePath("")

# Tweakable
const AIR_DASH_FORCE = 520
const AIR_DASH_DURATION = 0.18
const AIR_DASH_COOLDOWN = 0.25

# Internal state
var player: Node = null
var is_air_dashing = false
var dash_timer = 0.0
var dash_cooldown = 0.0
var dash_dir = 0

func _ready():
	if player_path != NodePath(""):
		player = get_node_or_null(player_path)
	if not player:
		var p = get_parent()
		if p and p is CharacterBody2D:
			player = p

func _physics_process(delta: float) -> void:
	if not player:
		return

	# safe access to velocity
	var vel = player.get("velocity")
	if vel == null:
		return

	# cooldown tick
	if dash_cooldown > 0:
		dash_cooldown = max(0, dash_cooldown - delta)

	# determine facing direction (best-effort)
	var facing = 1
	if player.has_node("AnimatedSprite2D"):
		var a = player.get_node("AnimatedSprite2D")
		if a and a.has_method("is_playing"):
			facing = -1 if a.flip_h else 1

	# input axis (requires move_left/move_right in InputMap)
	var move_axis = Input.get_axis("move_left", "move_right")

	# start air dash: only if airborne and cooldown ready and not already dashing
	var on_floor = player.has_method("is_on_floor") and player.is_on_floor()
	if Input.is_action_just_pressed("dash") and not on_floor and dash_cooldown <= 0 and not is_air_dashing:
		dash_dir = move_axis
		if dash_dir == 0:
			dash_dir = facing
		is_air_dashing = true
		dash_timer = AIR_DASH_DURATION
		dash_cooldown = AIR_DASH_COOLDOWN
		vel.x = dash_dir * AIR_DASH_FORCE

	# update dash
	if is_air_dashing:
		dash_timer -= delta
		# gentle lerp to keep movement smooth
		vel.x = lerp(vel.x, dash_dir * AIR_DASH_FORCE, 0.12)
		if dash_timer <= 0:
			is_air_dashing = false

	# write back velocity
	player.set("velocity", vel)
# tjhtksjzh dtjk gtnvdrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
#hngyjybvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvggvvvvvvvvvvvvvvvvvvvvvvvvv
