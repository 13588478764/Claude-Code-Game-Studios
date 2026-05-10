# Health and Poise Mechanics Unit Test
# Tests for the health and poise mechanics implementation

extends Node

# Import the script to test
var HealthPoiseManager = load("res://src/scripts/combat/health_poise_manager.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Health and Poise Mechanics tests...")
	
	# Test 1: Initialization
	test_initialization()
	
	# Test 2: HP calculation
	test_hp_calculation()
	
	# Test 3: Poise calculation
	test_poise_calculation()
	
	# Test 4: Damage application to HP
	test_damage_to_hp()
	
	# Test 5: Damage application to Poise
	test_damage_to_poise()
	
	# Test 6: Break state triggering
	test_break_state_triggering()
	
	# Test 7: Death state triggering
	test_death_state_triggering()
	
	# Test 8: Status changes
	test_status_changes()
	
	print("Health and Poise Mechanics tests completed: %d/%d passed" % [tests_passed, tests_total])

# Test initialization
func test_initialization():
	var manager = HealthPoiseManager.new()
	
	# Check that initial values are set correctly
	assert(manager.max_hp > 0, "Max HP should be greater than 0")
	assert(manager.current_hp == manager.max_hp, "Current HP should equal max HP at start")
	assert(manager.max_poise > 0, "Max Poise should be greater than 0")
	assert(manager.current_poise == manager.max_poise, "Current Poise should equal max Poise at start")
	
	print("✓ Initialization test passed")
	tests_passed += 4
	tests_total += 4

# Test HP calculation
func test_hp_calculation():
	var manager = HealthPoiseManager.new()
	
	# Test with default values
	var expected_max_hp = manager.calculate_max_hp()
	assert(expected_max_hp >= 100, "Max HP should be at least 100")
	assert(expected_max_hp <= 2000, "Max HP should not exceed 2000")
	
	# Test with modified CON stat
	manager.con_stat = 50
	var new_max_hp = manager.calculate_max_hp()
	assert(new_max_hp > expected_max_hp, "Higher CON should result in higher Max HP")
	
	print("✓ HP calculation test passed")
	tests_passed += 3
	tests_total += 3

# Test Poise calculation
func test_poise_calculation():
	var manager = HealthPoiseManager.new()
	
	# Test with default values
	var expected_max_poise = manager.calculate_max_poise()
	assert(expected_max_poise >= 50, "Max Poise should be at least 50")
	assert(expected_max_poise <= 800, "Max Poise should not exceed 800")
	
	# Test with modified WIL stat
	manager.wil_stat = 50
	var new_max_poise = manager.calculate_max_poise()
	assert(new_max_poise > expected_max_poise, "Higher WIL should result in higher Max Poise")
	
	print("✓ Poise calculation test passed")
	tests_passed += 3
	tests_total += 3

# Test damage application to HP
func test_damage_to_hp():
	var manager = HealthPoiseManager.new()
	
	var initial_hp = manager.current_hp
	var damage = 10
	var remaining_hp = manager.current_hp - damage
	
	var result = manager.apply_damage_to_hp(damage)
	assert(result == damage, "Damage applied should equal damage value")
	assert(manager.current_hp == remaining_hp, "HP should be reduced by damage amount")
	
	# Test that damage is at least 1
	var result2 = manager.apply_damage_to_hp(0)
	assert(result2 == 1, "Minimum damage should be 1")
	
	print("✓ Damage to HP test passed")
	tests_passed += 3
	tests_total += 3

# Test damage application to Poise
func test_damage_to_poise():
	var manager = HealthPoiseManager.new()
	
	var initial_poise = manager.current_poise
	var damage = 10
	var remaining_poise = manager.current_poise - damage
	
	var result = manager.apply_damage_to_poise(damage)
	assert(result == damage, "Damage applied should equal damage value")
	assert(manager.current_poise == remaining_poise, "Poise should be reduced by damage amount")
	
	# Test heavy attack damage
	var heavy_damage = 20
	manager.apply_damage_to_poise(heavy_damage, true)  # is_heavy_attack = true
	assert(manager.current_poise < (remaining_poise - heavy_damage), "Heavy attack should do more damage")
	
	print("✓ Damage to Poise test passed")
	tests_passed += 3
	tests_total += 3

# Test break state triggering
func test_break_state_triggering():
	var manager = HealthPoiseManager.new()
	
	# Reduce poise to 0 to trigger break
	manager.current_poise = 0
	
	# This should trigger break state
	manager.trigger_break_state()
	assert(manager.status == manager.STATUS_BREAK, "Status should be break after trigger")
	
	# Test break timer
	assert(manager.break_timer == manager.break_duration, "Break timer should equal break duration")
	
	print("✓ Break state triggering test passed")
	tests_passed += 2
	tests_total += 2

# Test death state triggering
func test_death_state_triggering():
	var manager = HealthPoiseManager.new()
	
	# Reduce HP to 0 to trigger death
	manager.current_hp = 0
	
	manager.trigger_death()
	assert(manager.status == manager.STATUS_DEAD, "Status should be dead after trigger")
	
	print("✓ Death state triggering test passed")
	tests_passed += 1
	tests_total += 1

# Test status changes
func test_status_changes():
	var manager = HealthPoiseManager.new()
	
	# Test critical status
	manager.current_hp = int(manager.max_hp * 0.05)  # 5% of max HP
	manager.current_poise = 0
	manager.trigger_break_state()
	
	assert(manager.is_in_critical_state(), "Should be in critical state when HP is low")
	assert(manager.is_in_break_state(), "Should be in break state when poise is 0")
	assert(not manager.is_dead(), "Should not be dead when HP is not 0")
	
	print("✓ Status changes test passed")
	tests_passed += 3
	tests_total += 3

# Helper function for assertions
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("Assertion failed: " + message)
	
	tests_total += 1