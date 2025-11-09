extends CharacterBody2D

const SPEED = 155
const JUMP_VELOCITY = -250
const WALL_JUMP_FORCE = Vector2(200, -250)

var jump_count = 0
var max_jumps = 2
var can_wall_jump = false
var is_wall_clinging = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jump_count = 0

	can_wall_jump = is_on_wall() and not is_on_floor()
	is_wall_clinging = can_wall_jump and velocity.y > 0

	if is_wall_clinging:
		velocity.y = 0
		jump_count = 0
		$AnimatedSprite2D.play("jump")

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			$jumpSFX.play()
			$AnimatedSprite2D.play("jump")
		elif jump_count < max_jumps:
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			$jumpSFX.play()
			$AnimatedSprite2D.play("jump")
		elif can_wall_jump:
			var wall_direction = -1 if $AnimatedSprite2D.flip_h else 1
			velocity = Vector2(WALL_JUMP_FORCE.x * wall_direction, WALL_JUMP_FORCE.y)
			jump_count = 1
			$jumpSFX.play()
			$AnimatedSprite2D.play("jump")

	var sprint_multiplier = 1.0
	if Input.is_action_pressed("sprint"):
		sprint_multiplier = 1.5

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = direction * SPEED * sprint_multiplier
		if is_on_floor():
			$AnimatedSprite2D.play("run")
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		if is_on_floor():
			$AnimatedSprite2D.play("idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if not is_on_floor() and velocity.y < 0 and not is_wall_clinging:
		$AnimatedSprite2D.play("jump")

	move_and_slide()
