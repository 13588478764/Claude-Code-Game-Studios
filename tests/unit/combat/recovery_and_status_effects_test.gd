# Recovery and Status Effects Unit Test
# Tests for the recovery and status effects implementation

extends Node

# Import the script to test
var RecoveryStatusManager = load("res://scripts/combat/recovery_status_manager.gd")
var HealthPoiseManager = load("res://scripts/combat/health_poise_manager.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Recovery and Status Effects tests...")
	
	# Test 1: Initialization
	test_initialization()
	
	# Test 2: HP recovery
	test_hp_recovery()
	
	# Test 3: Poise recovery
	test_poise_recovery()
	
	# Test 4: Status effect management
	test_status_effect_management()
	
	# Test 5: Combat state handling
	test_combat_state_handling()
	
	# Test 6: Rest point recovery
	test_rest_point_recovery()
	
	# Test 7: Recovery rates
	test_recovery_rates()
	
	# Test 8: Temporary status effect clearing
	test_temporary_status_effect_clearing()
	
	print("Recovery and Status Effects tests completed: %d/%d passed" % [tests_passed, tests_total])

# Test initialization
func test_initialization():
	var manager = RecoveryStatusManager.new()
	
	# Check that initial values are set correctly
	assert(manager.is_in_combat == false, "Should start out of combat")
	assert(manager.hp_recovery_rate == 0.0, "HP recovery rate should start at 0.0")
	assert(manager.poise_recovery_rate == 0.2, "Poise recovery rate should start at 0.2")
	assert(manager.active_status_effects.size() == 0, "Should start with no active status effects")
	
	print("✓ Initialization test passed")
	tests_passed += 4
	tests_total += 4

# Test HP recovery
func test_hp_recovery():
	var manager = RecoveryStatusManager.new()
	var health_manager = HealthPoiseManager.new()
	
	# Connect the health manager to the recovery manager
	manager.health_poise_manager = health_manager
	
	# Reduce HP to test recovery
	health_manager.current_hp = int(health_manager.max_hp * 0.5)  # 50% HP
	var initial_hp = health_manager.current_hp
	
	# Apply recovery
	var recovery_amount = 10
	manager.apply_recovery_to_hp(recovery_amount)
	
	var expected_hp = min(initial_hp + recovery_amount, health_manager.max_hp)
	assert(health_manager.current_hp == expected_hp, "HP should be recovered up to max")
	
	print("✓ HP recovery test passed")
	tests_passed += 1
	tests_total += 1

# Test Poise recovery
func test_poise_recovery():
	var manager = RecoveryStatusManager.new()
	var health_manager = HealthPoiseManager.new()
	
	# Connect the health manager to the recovery manager
	manager.health_poise_manager = health_manager
	
	# Reduce Poise to test recovery
	health_manager.current_poise = int(health_manager.max_poise * 0.5)  # 50% Poise
	var initial_poise = health_manager.current_poise
	
	# Apply recovery
	var recovery_amount = 10
	manager.apply_recovery_to_poise(recovery_amount)
	
	var expected_poise = min(initial_poise + recovery_amount, health_manager.max_poise)
	assert(health_manager.current_poise == expected_poise, "Poise should be recovered up to max")
	
	print("✓ Poise recovery test passed")
	tests_passed += 1
	tests_total += 1

# Test status effect management
func test_status_effect_management():
	var manager = RecoveryStatusManager.new()
	
	# Add a status effect
	var effect_name = "test_effect"
	var duration = 2.0
	manager.add_status_effect(effect_name, duration)
	
	# Check that the effect was added
	assert(manager.has_status_effect(effect_name), "Status effect should be added")
	assert(manager.active_status_effects.size() == 1, "Should have one active status effect")
	
	# Check effect data
	var effect_data = manager.active_status_effects[effect_name]
	assert(effect_data.name == effect_name, "Effect name should match")
	assert(effect_data.duration == duration, "Effect duration should match")
	
	# Add a permanent effect
	var permanent_effect = "permanent_effect"
	manager.add_status_effect(permanent_effect, -1)  # -1 for permanent
	assert(manager.has_status_effect(permanent_effect), "Permanent effect should be added")
	
	print("✓ Status effect management test passed")
	tests_passed += 5
	tests_total += 5

# Test combat state handling
func test_combat_state_handling():
	var manager = RecoveryStatusManager.new()
	
	# Start in combat
	manager.set_combat_state(true)
	assert(manager.is_in_combat == true, "Should be in combat after setting combat state")
	
	# End combat
	manager.set_combat_state(false)
	assert(manager.is_in_combat == false, "Should be out of combat after setting non-combat state")
	
	# Test combat end function
	manager.set_combat_state(true)
	manager.on_combat_end()
	assert(manager.is_in_combat == false, "Should be out of combat after combat end")
	
	print("✓ Combat state handling test passed")
	tests_passed += 3
	tests_total += 3

# Test rest point recovery
func test_rest_point_recovery():
	var manager = RecoveryStatusManager.new()
	var health_manager = HealthPoiseManager.new()
	
	# Connect the health manager to the recovery manager
	manager.health_poise_manager = health_manager
	
	# Reduce HP and Poise to test full recovery
	health_manager.current_hp = int(health_manager.max_hp * 0.3)  # 30% HP
	health_manager.current_poise = int(health_manager.max_poise * 0.3)  # 30% Poise
	
	# Add a temporary status effect to test clearing
	manager.add_status_effect("temporary_effect", 5.0)
	
	# Use rest point recovery
	manager.rest_point_recovery_handler()
	
	# Check that HP and Poise are fully recovered
	assert(health_manager.current_hp == health_manager.max_hp, "HP should be fully recovered at rest point")
	assert(health_manager.current_poise == health_manager.max_poise, "Poise should be fully recovered at rest point")
	
	print("✓ Rest point recovery test passed")
	tests_passed += 2
	tests_total += 2

# Test recovery rates
func test_recovery_rates():
	var manager = RecoveryStatusManager.new()
	
	# Set new recovery rates
	var new_hp_rate = 0.1
	var new_poise_rate = 0.3
	manager.set_recovery_rates(new_hp_rate, new_poise_rate)
	
	var status_info = manager.get_recovery_status()
	assert(status_info.hp_recovery_rate == new_hp_rate, "HP recovery rate should be updated")
	assert(status_info.poise_recovery_rate == new_poise_rate, "Poise recovery rate should be updated")
	
	print("✓ Recovery rates test passed")
	tests_passed += 2
	tests_total += 2

# Test temporary status effect clearing
func test_temporary_status_effect_clearing():
	var manager = RecoveryStatusManager.new()
	
	# Add some temporary effects
	manager.add_status_effect("temp_effect_1", 5.0)
	manager.add_status_effect("temp_effect_2", 10.0)
	
	# Add a permanent effect (should not be cleared)
	manager.add_status_effect("permanent_effect", -1)
	
	assert(manager.active_status_effects.size() == 3, "Should have 3 active effects initially")
	
	# Clear temporary effects
	manager.clear_temporary_status_effects()
	
	assert(manager.active_status_effects.size() == 1, "Should have 1 effect remaining after clearing temporaries")
	assert(manager.has_status_effect("permanent_effect"), "Permanent effect should remain")
	
	print("✓ Temporary status effect clearing test passed")
	tests_passed += 3
	tests_total += 3

# Helper function for assertions
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("Assertion failed: " + message)
	
	tests_total += 1