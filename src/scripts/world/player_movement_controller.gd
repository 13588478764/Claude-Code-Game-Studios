## PlayerMovementController
## Player Movement Controller
Handles player movement in the open world with stamina/inertia management
##
## 主要功能：
## - 待补充

extends Node

class_name PlayerMovementController

# ============================================================================
# 常量定义
# ============================================================================

# ============================================================================
# 信号定义
# ============================================================================

# ============================================================================
# 成员变量
# ============================================================================

# ============================================================================
# 生命周期方法
# ============================================================================

# ============================================================================
# 公共方法
# ============================================================================

# ============================================================================
# 私有方法
# ============================================================================

# Movement constants
const MOVE_SPEED := 200.0  # Base movement speed
const RUN_MULTIPLIER := 1.5  # Speed multiplier when running
const JUMP_VELOCITY := -400.0  # Jump impulse
const GRAVITY := 980.0  # Gravity acceleration
const STAMINA_DRAIN_RATE := 5.0  # Stamina drain per second when moving fast
const STAMINA_RESTORE_RATE := 10.0  # Stamina restore per second when idle
const MIN_STAMINA_FOR_ACTIONS := 10.0  # Minimum stamina for special actions
const LIGHTNESS_FACTOR := 0.1  # Factor affecting climbing/sprinting based on lightness attribute

# Signals
signal stamina_changed(current: float, max: float)
signal player_moved(new_position: Vector2)
signal vertical_movement_attempted(action: String, success: bool)

# Player attributes (these would typically come from a character stats system)
var attributes: Dictionary = {
	"speed": 50.0,  # Base speed attribute
	"lightness": 50.0,  # Lightness attribute affecting climbing/sprinting
	"stamina": 100.0,  # Current stamina
	"max_stamina": 100.0  # Max stamina
}

# Movement states
var is_running := false
var is_climbing := false
var is_gliding := false
var is_jumping := false
var can_glide := true  # Whether gliding is unlocked
var can_climb := true  # Whether climbing is unlocked

# Internal state
var _target_velocity := Vector2.ZERO
var _movement_input := Vector2.ZERO
var _last_direction := Vector2.RIGHT  # Last horizontal movement direction

func _ready():
	# Initialize player attributes
	attributes["stamina"] = attributes["max_stamina"]
	print("Player movement controller initialized")

func _physics_process(delta):
	# Apply gravity if not on floor and not climbing
	if not is_on_floor() and not is_climbing:
		velocity.y += GRAVITY * delta
	else:
		# Reset jump state when on ground
		if is_jumping:
			is_jumping = false
	
	# Process movement input
	_process_movement_input(delta)
	
	# Update stamina
	_update_stamina(delta)
	
	# Move the character
	move_and_slide()

# Process movement input
func _process_movement_input(delta):
	# Get input direction
	_movement_input = Vector2.ZERO
	_movement_input.x = Input.get_axis("move_left", "move_right")
	_movement_input.y = Input.get_axis("move_up", "move_down")
	
	# Normalize to prevent faster diagonal movement
	if _movement_input.length() > 0:
		_movement_input = _movement_input.normalized()
	
	# Determine if player is trying to run
	is_running = Input.is_action_pressed("run") and _movement_input.length() > 0.1
	
	# Calculate base speed based on attributes
	var base_speed = MOVE_SPEED + attributes["speed"]
	var current_speed = base_speed
	
	# Apply running multiplier if stamina allows
	if is_running and attributes["stamina"] > 5.0:
		current_speed *= RUN_MULTIPLIER
	elif is_running:
		# If trying to run but low on stamina, slow down
		current_speed *= 0.7  # Reduced speed when out of stamina
	
	# Handle special movement abilities
	if can_climb and is_climbing:
		_handle_climbing(current_speed, delta)
	elif can_glide and is_gliding:
		_handle_gliding(current_speed, delta)
	else:
		# Regular movement
		velocity.x = _movement_input.x * current_speed
		
		# Update facing direction
		if _movement_input.x != 0:
			_last_direction.x = _movement_input.x
	
	# Handle jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true

# Handle climbing movement
func _handle_climbing(speed: float, delta: float):
	# Climbing movement is slower and controlled differently
	velocity.x = _movement_input.x * speed * 0.5  # Slower horizontal movement when climbing
	velocity.y = _movement_input.y * speed * 0.7  # Slower vertical movement when climbing
	
	# Check if still near climbable surface
	if not _is_near_climbable_surface():
		is_climbing = false
		emit_signal("vertical_movement_attempted", "climbing_end", false)

# Handle gliding movement
func _handle_gliding(speed: float, delta: float):
	# Gliding reduces gravity effect and allows controlled descent
	velocity.x = _movement_input.x * speed * 0.8  # Reduced horizontal control during glide
	velocity.y += (GRAVITY * 0.3) * delta  # Reduced gravity effect during glide
	
	# Check if gliding should end
	if is_on_floor() or _should_end_glide():
		is_gliding = false
		emit_signal("vertical_movement_attempted", "glide_end", true)

# Check if near a climbable surface
func _is_near_climbable_surface() -> bool:
	# This would typically involve checking for nearby climbable objects
	# For now, return true if moving vertically
	return abs(_movement_input.y) > 0.1

# Check if glide should end
func _should_end_glide() -> bool:
	# End glide if moving upward or if stamina is too low
	return _movement_input.y < -0.1 or attributes["stamina"] < 5.0

# Update stamina based on activity
func _update_stamina(delta: float):
	var stamina_change = 0.0
	
	# Drain stamina when running or performing special actions
	if is_running and attributes["stamina"] > 0:
		stamina_change -= STAMINA_DRAIN_RATE * delta
	elif is_climbing:
		stamina_change -= STAMINA_DRAIN_RATE * 1.5 * delta  # Climbing drains more stamina
	elif is_gliding:
		stamina_change -= STAMINA_DRAIN_RATE * 0.5 * delta  # Gliding drains less stamina
	
	# Restore stamina when not performing intensive actions
	if stamina_change >= 0:
		stamina_change += STAMINA_RESTORE_RATE * delta
	
	# Apply lightness factor to stamina efficiency
	var lightness_modifier = 1.0 - (attributes["lightness"] / 100.0) * LIGHTNESS_FACTOR
	stamina_change *= lightness_modifier
	
	# Update stamina value
	attributes["stamina"] = clamp(attributes["stamina"] + stamina_change, 0.0, attributes["max_stamina"])
	
	# Emit signal if stamina changed significantly
	if abs(stamina_change) > 0.01:
		emit_signal("stamina_changed", attributes["stamina"], attributes["max_stamina"])

# Attempt to start climbing
func attempt_climb() -> bool:
	if not can_climb or attributes["stamina"] < MIN_STAMINA_FOR_ACTIONS:
		emit_signal("vertical_movement_attempted", "climb_start", false)
		return false
	
	if _is_near_climbable_surface():
		is_climbing = true
		velocity = Vector2.ZERO  # Stop current movement
		emit_signal("vertical_movement_attempted", "climb_start", true)
		return true
	else:
		emit_signal("vertical_movement_attempted", "climb_start", false)
		return false

# Attempt to start gliding
func attempt_glide() -> bool:
	if not can_glide or attributes["stamina"] < MIN_STAMINA_FOR_ACTIONS:
		emit_signal("vertical_movement_attempted", "glide_start", false)
		return false
	
	if not is_on_floor() and not is_climbing:
		is_gliding = true
		emit_signal("vertical_movement_attempted", "glide_start", true)
		return true
	else:
		emit_signal("vertical_movement_attempted", "glide_start", false)
		return false

# Get the current movement direction
func get_current_direction() -> Vector2:
	return _last_direction

# Get the current movement speed
func get_current_speed() -> float:
	var base_speed = MOVE_SPEED + attributes["speed"]
	if is_running and attributes["stamina"] > 5.0:
		return base_speed * RUN_MULTIPLIER
	return base_speed

# Get stamina information
func get_stamina_info() -> Dictionary:
	return {
		"current": attributes["stamina"],
		"max": attributes["max_stamina"],
		"percent": attributes["stamina"] / attributes["max_stamina"] * 100.0
	}

# Set player attributes
func set_attribute(attr_name: String, value: float):
	if attributes.has(attr_name):
		attributes[attr_name] = value
		# If setting max stamina, adjust current stamina proportionally
		if attr_name == "max_stamina":
			var ratio = attributes["stamina"] / attributes.get("max_stamina", 1.0)
			attributes["stamina"] = value * ratio

# Get player attribute
func get_attribute(attr_name: String) -> float:
	return attributes.get(attr_name, 0.0)

# Unlock climbing ability
func unlock_climbing():
	can_climb = true
	print("Climbing ability unlocked")

# Unlock gliding ability
func unlock_glide():
	can_glide = true
	print("Gliding ability unlocked")

# Trigger exploration reward check at position
func check_exploration_rewards():
	# This would typically interact with an exploration system
	# For now, just emit a signal indicating the player moved
	emit_signal("player_moved", global_position)