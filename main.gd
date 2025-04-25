extends Node2D

@onready var moon: AnimatedSprite2D = $moon
@onready var sun: AnimatedSprite2D = $sun

# State for both characters
var moon_state = {
	"is_facing_right": true,
	"is_jumping": false,
	"velocity": Vector2.ZERO  # This will store both x and y velocities
}

var sun_state = {
	"is_facing_right": true,
	"is_jumping": false,
	"velocity": Vector2.ZERO
}

var gravity = 400
var jump_force = -200
var ground_y = 0
var move_speed = 150  # Horizontal movement speed
var active_body = "moon"  # default control

func _ready():
	ground_y = moon.position.y  # assumes both start at the same y
	moon.visible = true
	sun.visible = false

func _process(delta):
	# Switch bodies and preserve velocity and direction
	if Input.is_action_just_pressed("switch_body"):
		# Save the current position and velocity of the active character
		var current_pos = moon.position if active_body == "moon" else sun.position
		var current_velocity = moon_state["velocity"] if active_body == "moon" else sun_state["velocity"]
		var current_facing_right = moon_state["is_facing_right"] if active_body == "moon" else sun_state["is_facing_right"]

		# Switch the active body
		active_body = "sun" if active_body == "moon" else "moon"

		# Toggle visibility based on the active body
		moon.visible = (active_body == "moon")
		sun.visible = (active_body == "sun")

		# Set both characters to the same position to keep the switch seamless
		moon.position = current_pos
		sun.position = current_pos

		# Transfer the velocity and facing direction to the new active character
		if active_body == "moon":
			moon_state["is_facing_right"] = current_facing_right
			moon_state["velocity"] = current_velocity  # Preserve the velocity
		else:
			sun_state["is_facing_right"] = current_facing_right
			sun_state["velocity"] = current_velocity  # Preserve the velocity

	# Control the active character
	if active_body == "moon":
		control_character(moon, delta, "moon", moon_state)
	else:
		control_character(sun, delta, "sun", sun_state)

func control_character(sprite: AnimatedSprite2D, delta: float, prefix: String, state: Dictionary):
	# Jump
	if not state["is_jumping"] and Input.is_action_just_pressed("jump"):
		state["is_jumping"] = true
		state["velocity"].y = jump_force
		var direction = "right" if state["is_facing_right"] else "left"
		# Play the jumping animation based on character prefix and facing direction
		if prefix == "sun":
			sprite.play("sun-jumping-" + direction)  # sun-specific jumping animation
		else:
			sprite.play("moon-jumping-" + direction)  # moon-specific jumping animation

	# Gravity & vertical movement
	state["velocity"].y += gravity * delta  # Always apply gravity
	sprite.position.y += state["velocity"].y * delta

	# Check for landing
	if sprite.position.y >= ground_y:
		sprite.position.y = ground_y
		state["velocity"].y = 0
		state["is_jumping"] = false

	# Horizontal movement
	# Apply horizontal velocity based on the movement input
	if Input.is_action_pressed("move_left"):
		state["is_facing_right"] = false
		sprite.play(prefix + "-moving-left")
		state["velocity"].x = -move_speed  # Move left
	elif Input.is_action_pressed("move_right"):
		state["is_facing_right"] = true
		sprite.play(prefix + "-moving-right")
		state["velocity"].x = move_speed  # Move right
	else:
		# Stop moving if no horizontal input
		state["velocity"].x = 0
		# Ensure facing direction is consistent with the last direction
		var stand_dir = "" if state["is_facing_right"] else "-left"
		sprite.play(prefix + "-standing" + stand_dir)

	# Apply horizontal velocity to position
	sprite.position.x += state["velocity"].x * delta

	# Mid-air facing direction update
	if state["is_jumping"]:
		# Update facing direction based on horizontal velocity (current movement direction)
		if state["velocity"].x < 0:
			state["is_facing_right"] = false  # Moving left
		elif state["velocity"].x > 0:
			state["is_facing_right"] = true  # Moving right
