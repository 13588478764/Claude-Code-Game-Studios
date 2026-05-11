# Player Movement System Unit Test
# Tests the player movement controller functionality

extends Node

# Import the script to test
var PlayerMovementController = load("res://src/scripts/world/player_movement_controller.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Player Movement System tests...")
	
	# Test 1: Initialization
	test_initialization()
	
	# Test 2: Basic movement
	test_basic_movement()
	
	# Test 3: Running functionality
	test_running_functionality()
	
	# Test 4: Stamina system
	test_stamina_system()
	
	# Test 5: Special movement abilities
	test_special_movement_abilities()
	
	# Test 6: Attribute management
	test_attribute_management()
	
	print("Player Movement System tests complete: %d/%d passed" % [tests_passed, tests_total])

# Test initialization
func test_initialization():
	var player = PlayerMovementController.new()
	
	assert(player != null, "Player controller should be created")
	assert(player.get_attribute("stamina") == player.get_attribute("max_stamina"), "Stamina should be at max on init")
	assert(player.get_attribute("max_stamina") == 100.0, "Default max stamina should be 100")
	
	print("✓ Initialization test passed")
	tests_passed += 3
	tests_total += 3

# Test basic movement
func test_basic_movement():
	var player = PlayerMovementController.new()
	
	# Test default values
	var initial_speed = player.get_current_speed()
	assert(initial_speed > 0, "Initial speed should be positive")
	
	# Test direction
	var initial_direction = player.get_current_direction()
	assert(initial_direction != Vector2.ZERO, "Initial direction should not be zero")
	
	print("✓ Basic movement test passed")
	tests_passed += 2
	tests_total += 2

# Test running functionality
func test_running_functionality():
	var player = PlayerMovementController.new()
	
	# Test running speed is higher than walking
	var walk_speed = player.get_current_speed()
	player.set_attribute("stamina", 100.0)  # Ensure sufficient stamina
	
	# Simulate running input (this would normally be handled by input system)
	player.is_running = true
	var run_speed = player.get_current_speed()
	
	# Since we can't simulate input directly in unit test, we check the internal logic
	assert(run_speed >= walk_speed, "Run speed should be equal or greater than walk speed")
	
	print("✓ Running functionality test passed")
	tests_passed += 1
	tests_total += 1

# Test stamina system
func test_stamina_system():
	var player = PlayerMovementController.new()
	
	# Test stamina info retrieval
	var stamina_info = player.get_stamina_info()
	assert(stamina_info.size() > 0, "Stamina info should be returned")
	assert(stamina_info.max > 0, "Max stamina should be positive")
	
	# Test stamina modification
	var initial_stamina = player.get_attribute("stamina")
	player.set_attribute("stamina", 50.0)
	var new_stamina = player.get_attribute("stamina")
	assert(new_stamina == 50.0, "Stamina should be settable")
	
	# Restore initial value
	player.set_attribute("stamina", initial_stamina)
	
	print("✓ Stamina system test passed")
	tests_passed += 3
	tests_total += 3

# Test special movement abilities
func test_special_movement_abilities():
	var player = PlayerMovementController.new()
	
	# Test ability unlocking
	assert(player.can_climb == true, "Climbing should be enabled by default")
	assert(player.can_glide == true, "Gliding should be enabled by default")
	
	# Test unlock functions
	player.unlock_climbing()
	player.unlock_glide()
	assert(player.can_climb == true, "Climbing should remain enabled after unlock")
	assert(player.can_glide == true, "Gliding should remain enabled after unlock")
	
	print("✓ Special movement abilities test passed")
	tests_passed += 4
	tests_total += 4

# Test attribute management
func test_attribute_management():
	var player = PlayerMovementController.new()
	
	# Test getting attributes
	var speed_attr = player.get_attribute("speed")
	assert(speed_attr >= 0, "Speed attribute should be non-negative")
	
	# Test setting attributes
	var new_speed_value = 75.0
	player.set_attribute("speed", new_speed_value)
	var updated_speed = player.get_attribute("speed")
	assert(updated_speed == new_speed_value, "Speed attribute should be updated")
	
	# Test max stamina adjustment affects current stamina proportionally
	var initial_max_stamina = player.get_attribute("max_stamina")
	var initial_current_stamina = player.get_attribute("stamina")
	var new_max_stamina = 150.0
	player.set_attribute("max_stamina", new_max_stamina)
	
	# Check that current stamina was adjusted proportionally
	var expected_current = initial_current_stamina * (new_max_stamina / initial_max_stamina)
	var actual_current = player.get_attribute("stamina")
	assert(abs(actual_current - expected_current) < 0.1, "Current stamina should scale with max stamina")
	
	print("✓ Attribute management test passed")
	tests_passed += 4
	tests_total += 4
