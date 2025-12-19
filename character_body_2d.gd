extends CharacterBody2D

const SPEED = 155
const JUMP_VELOCITY = -1000
const WALL_JUMP_FORCE = Vector2(200, -250)
const FLOAT_GRAVITY_SCALE = 0.05
const DASH_FORCE = 600
const DASH_DURATION = 0.2
const TIME_SLOW_SCALE = 0.4
const TIME_SLOW_DURATION = 1.5
const TIME_FAST_SCALE = 2.0
const TIME_FAST_DURATION = 5.0
const WALL_CLING_DURATION = 5.0
const TERMINAL_VELOCITY = 300

var gravity_direction = 1
var jump_count = 0
var max_jumps = 2
var is_wall_clinging = false
var wall_cling_timer = 0.0
var last_wall_normal = Vector2.ZERO
var is_dashing = false
var dash_timer = 0.0
var dash_direction = 0
var is_time_slowing = false
var time_slow_timer = 0.0
var is_time_speeding = false
var time_speed_timer = 0.0
var infinite_mode = false

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_infinite"):
		infinite_mode = not infinite_mode
		$CollisionShape2D.disabled = infinite_mode
		jump_count = 0

	if Input.is_action_just_pressed("time_slow") and not is_time_slowing and not is_time_speeding:
		is_time_slowing = true
		time_slow_timer = TIME_SLOW_DURATION
		Engine.time_scale = TIME_SLOW_SCALE
	if is_time_slowing:
		time_slow_timer -= delta
		if time_slow_timer <= 0:
			is_time_slowing = false
			Engine.time_scale = 1.0

	if Input.is_action_just_pressed("time_fast") and not is_time_speeding and not is_time_slowing:
		is_time_speeding = true
		time_speed_timer = TIME_FAST_DURATION
		Engine.time_scale = TIME_FAST_SCALE
	if is_time_speeding:
		time_speed_timer -= delta
		if time_speed_timer <= 0:
			is_time_speeding = false
			Engine.time_scale = 1.0

	if Input.is_action_just_pressed("flip_gravity"):
		gravity_direction *= -1
		scale.y *= -1
		$AnimatedSprite2D.scale.y *= -1

	if not is_on_floor():
		var gravity = get_gravity() * gravity_direction
		if Input.is_action_pressed("float") and velocity.y * gravity_direction > 0:
			velocity.y = lerp(velocity.y, 30.0 * gravity_direction, 0.2)
		else:
			velocity += gravity * delta
		if gravity_direction == 1:
			velocity.y = min(velocity.y, TERMINAL_VELOCITY)
		else:
			velocity.y = max(velocity.y, -TERMINAL_VELOCITY)
	else:
		jump_count = 0

	is_wall_clinging = is_on_wall() and not is_on_floor() and velocity.y * gravity_direction > 0
	if is_wall_clinging:
		var wall_normal = get_wall_normal()
		if wall_normal != last_wall_normal:
			wall_cling_timer = WALL_CLING_DURATION
			last_wall_normal = wall_normal
		wall_cling_timer -= delta
		if wall_cling_timer > 0:
			velocity.y = 0
			jump_count = 0
		else:
			is_wall_clinging = false

	if Input.is_action_just_pressed("dash") and not is_dashing:
		dash_direction = Input.get_axis("move_left", "move_right")
		if dash_direction != 0:
			is_dashing = true
			dash_timer = DASH_DURATION
			velocity.x = dash_direction * DASH_FORCE
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false

	if Input.is_action_just_pressed("jump"):
		var jump_force = JUMP_VELOCITY * gravity_direction
		if is_on_floor() or infinite_mode or jump_count < max_jumps or gravity_direction == -1:
			velocity.y = jump_force
			jump_count += 1
			$jumpSFX.play()

	var sprint_multiplier = 1.0
	if Input.is_action_pressed("sprint"):
		sprint_multiplier = 1.5

	if not is_dashing and not is_wall_clinging:
		var direction = Input.get_axis("move_left", "move_right")
		if direction != 0:
			velocity.x = direction * SPEED * sprint_multiplier
			$AnimatedSprite2D.flip_h = direction < 0
		else:
			velocity.x = 0

	if is_wall_clinging:
		$AnimatedSprite2D.play("wall_cling")
	elif is_dashing:
		$AnimatedSprite2D.play("dash")
	elif not is_on_floor() and velocity.y * gravity_direction < 0:
		$AnimatedSprite2D.play("jump")
	elif is_on_floor():
		if velocity.x != 0:
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("idle")

	move_and_slide()
