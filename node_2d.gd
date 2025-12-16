# WallBurst.gd
extends Node

@export var player_path: NodePath = NodePath("")

# Tweakable
const WALL_BURST_FORCE: Vector2 = Vector2(220, -220) # x = horizontal push, y = vertical push (negative = up)
const WALL_BURST_COOLDOWN: float = 0.25

# Internal state
var player: CharacterBody2D = null
var burst_cooldown: float = 0.0

func _ready() -> void:
	if player_path != NodePath(""):
		player = get_node_or_null(player_path)
	if not player:
		var p = get_parent()
		if p and p is CharacterBody2D:
			player = p

func _physics_process(delta: float) -> void:
	if not player:
		return

	# cooldown tick
	if burst_cooldown > 0.0:
		burst_cooldown = max(0.0, burst_cooldown - delta)

	# read velocity safely
	var vel: Vector2 = player.velocity

	# input and conditions
	if Input.is_action_just_pressed("wall_burst") and burst_cooldown <= 0.0:
		# require player to be on a wall and not on floor
		var on_wall: bool = false
		var on_floor: bool = false
		if player.has_method("is_on_wall"):
			on_wall = player.is_on_wall()
		if player.has_method("is_on_floor"):
			on_floor = player.is_on_floor()

		if on_wall and not on_floor:
			# try to get wall normal if player exposes it
			var wn: Vector2 = Vector2.ZERO
			if player.has_method("get_wall_normal"):
				wn = player.get_wall_normal()

			# determine horizontal push direction
			var push_x: float = 0.0
			if wn != Vector2.ZERO:
				push_x = -wn.x * WALL_BURST_FORCE.x
			else:
				# fallback: use AnimatedSprite2D flip_h if present
				var facing: int = 1
				if player.has_node("AnimatedSprite2D"):
					var a = player.get_node("AnimatedSprite2D")
					if a:
						facing = -1 if a.flip_h else 1
				push_x = facing * WALL_BURST_FORCE.x

			# vertical push respects gravity_direction if exposed
			var gdir: int = 1
			if player.has_method("get"):
				var tmpg = null
				# safe get: only call if property exists
				if player.has_meta("gravity_direction") or player.has_method("gravity_direction"):
					# unlikely; skip
					pass
				# try direct property access with fallback
				if "gravity_direction" in player:
					tmpg = player.gravity_direction
				elif player.has_method("get"):
					# try get, but guard with exists check
					if player.get("gravity_direction") != null:
						tmpg = player.get("gravity_direction")
				if tmpg != null:
					gdir = int(tmpg)

			var push_y: float = WALL_BURST_FORCE.y * gdir

			# apply burst
			vel.x = push_x
			vel.y = push_y

			# write back velocity
			player.velocity = vel

			# start cooldown
			burst_cooldown = WALL_BURST_COOLDOWN
