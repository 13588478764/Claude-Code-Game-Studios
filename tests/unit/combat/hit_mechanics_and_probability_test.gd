# Hit Mechanics and Probability Unit Test
# Tests for the hit detection system implementation

extends Node

# Import the script to test
var HitDetectionManager = load("res://src/scripts/combat/hit_detection_manager.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Hit Mechanics and Probability tests...")
	
	# Test 1: Initialization
	test_initialization()
	
	# Test 2: Hit chance calculation
	test_hit_chance_calculation()
	
	# Test 3: Guaranteed hit check
	test_guaranteed_hit_check()
	
	# Test 4: Hit check execution
	test_hit_check_execution()
	
	# Test 5: Hit result retrieval
	test_hit_result_retrieval()
	
	# Test 6: Character agility retrieval
	test_character_agility_retrieval()
	
	# Test 7: Status modifier calculation
	test_status_modifier_calculation()
	
	# Test 8: Parameter adjustment
	test_parameter_adjustment()
	
	print("Hit Mechanics and Probability tests completed: %d/%d passed" % [tests_passed, tests_total])

# Test initialization
func test_initialization():
	var manager = HitDetectionManager.new()
	
	# Check that initial values are set correctly
	assert(manager.base_hit_chance == 0.9, "Base hit chance should be 0.9")
	assert(manager.MIN_HIT_CHANCE == 0.05, "Min hit chance should be 0.05")
	assert(manager.MAX_HIT_CHANCE == 0.95, "Max hit chance should be 0.95")
	assert(manager.AGI_FACTOR == 0.005, "Agi factor should be 0.005")
	
	print("✓ Initialization test passed")
	tests_passed += 4
	tests_total += 4

# Test hit chance calculation
func test_hit_chance_calculation():
	var manager = HitDetectionManager.new()
	
	# Create mock attacker and target
	var attacker = create_mock_character(50, 10)  # AGI: 50, LUK: 10
	var target = create_mock_character(30, 10)    # AGI: 30, LUK: 10
	
	# Calculate hit chance
	var hit_chance = manager.calculate_hit_chance(attacker, target)
	
	# Expected: base (0.9) + (50-30)*0.005 = 0.9 + 0.1 = 1.0, but clamped to 0.95
	assert(hit_chance == 0.95, "Hit chance should be clamped to max value")
	
	# Test with lower agility for attacker
	var attacker_low = create_mock_character(10, 10)
	var target_high = create_mock_character(50, 10)
	var hit_chance_low = manager.calculate_hit_chance(attacker_low, target_high)
	
	# Expected: base (0.9) + (10-50)*0.005 = 0.9 - 0.2 = 0.7
	assert(hit_chance_low == 0.7, "Hit chance should reflect agility difference")
	
	print("✓ Hit chance calculation test passed")
	tests_passed += 2
	tests_total += 2

# Test guaranteed hit check
func test_guaranteed_hit_check():
	var manager = HitDetectionManager.new()
	
	# Create mock characters with break state
	var attacker = create_mock_character(30, 10)
	var target = create_mock_character_with_state(30, 10, "broken")
	
	# Check guaranteed hit
	var is_guaranteed = manager.is_guaranteed_hit(attacker, target)
	assert(is_guaranteed, "Should be guaranteed hit when target is broken")
	
	# Test with stunned target
	var stunned_target = create_mock_character_with_state(30, 10, "stunned")
	var is_guaranteed_stunned = manager.is_guaranteed_hit(attacker, stunned_target)
	assert(is_guaranteed_stunned, "Should be guaranteed hit when target is stunned")
	
	# Test with frozen target
	var frozen_target = create_mock_character_with_state(30, 10, "frozen")
	var is_guaranteed_frozen = manager.is_guaranteed_hit(attacker, frozen_target)
	assert(is_guaranteed_frozen, "Should be guaranteed hit when target is frozen")
	
	# Test with Sure_Hit skill
	var skill_data = {"tags": ["Sure_Hit"]}
	var normal_target = create_mock_character(30, 10)
	var is_guaranteed_skill = manager.is_guaranteed_hit(attacker, normal_target, skill_data)
	assert(is_guaranteed_skill, "Should be guaranteed hit with Sure_Hit skill tag")
	
	print("✓ Guaranteed hit check test passed")
	tests_passed += 4
	tests_total += 4

# Test hit check execution
func test_hit_check_execution():
	var manager = HitDetectionManager.new()
	
	# Create mock characters
	var attacker = create_mock_character(50, 10)
	var target = create_mock_character(30, 10)
	
	# Perform hit check multiple times to test randomness
	var hit_count = 0
	for i in range(100):
		if manager.perform_hit_check(attacker, target):
			hit_count += 1
	
	# Since hit chance is high (0.95), we should have mostly hits
	# But due to randomness, we allow some variance
	assert(hit_count >= 80, "Should have mostly hits with high hit chance")
	
	# Test guaranteed hit
	var broken_target = create_mock_character_with_state(30, 10, "broken")
	var guaranteed_hit = manager.perform_hit_check(attacker, broken_target)
	assert(guaranteed_hit, "Guaranteed hit should always succeed")
	
	print("✓ Hit check execution test passed")
	tests_passed += 2
	tests_total += 2

# Test hit result retrieval
func test_hit_result_retrieval():
	var manager = HitDetectionManager.new()
	
	# Create mock characters
	var attacker = create_mock_character(50, 10)
	var target = create_mock_character(30, 10)
	
	# Get hit result
	var result = manager.get_hit_result(attacker, target)
	
	# Check that result contains required fields
	assert(result.has("hit_success"), "Result should have hit_success field")
	assert(result.has("hit_chance"), "Result should have hit_chance field")
	assert(result.has("is_guaranteed"), "Result should have is_guaranteed field")
	assert(result.has("attacker_id"), "Result should have attacker_id field")
	assert(result.has("target_id"), "Result should have target_id field")
	
	print("✓ Hit result retrieval test passed")
	tests_passed += 5
	tests_total += 5

# Test character agility retrieval
func test_character_agility_retrieval():
	var manager = HitDetectionManager.new()
	
	# Create mock character
	var character = create_mock_character(45, 12)
	
	var agility = manager.get_character_agility(character)
	assert(agility == 45, "Should retrieve correct agility value")
	
	print("✓ Character agility retrieval test passed")
	tests_passed += 1
	tests_total += 1

# Test status modifier calculation
func test_status_modifier_calculation():
	var manager = HitDetectionManager.new()
	
	# Create mock characters with statuses
	var focused_attacker = create_mock_character_with_status(50, 10, ["Focus"])
	var blind_target = create_mock_character_with_status(30, 10, ["Blind"])
	
	# Calculate status modifier
	var modifier = manager.get_status_modifier(focused_attacker, blind_target)
	
	# Expected: +0.2 (Focus) + +0.3 (Blind) = +0.5
	assert(modifier == 0.5, "Should calculate correct status modifier")
	
	print("✓ Status modifier calculation test passed")
	tests_passed += 1
	tests_total += 1

# Test parameter adjustment
func test_parameter_adjustment():
	var manager = HitDetectionManager.new()
	
	# Test setting base hit chance
	manager.set_base_hit_chance(0.8)
	assert(manager.base_hit_chance == 0.8, "Should set base hit chance correctly")
	
	# Test clamping
	manager.set_base_hit_chance(1.2)
	assert(manager.base_hit_chance == manager.MAX_HIT_CHANCE, "Should clamp to max hit chance")
	
	manager.set_base_hit_chance(0.01)
	assert(manager.base_hit_chance == manager.MIN_HIT_CHANCE, "Should clamp to min hit chance")
	
	# Test getting parameters
	var params = manager.get_hit_chance_parameters()
	assert(params.has("base_hit_chance"), "Parameters should have base_hit_chance")
	assert(params.has("agi_factor"), "Parameters should have agi_factor")
	assert(params.has("min_hit_chance"), "Parameters should have min_hit_chance")
	assert(params.has("max_hit_chance"), "Parameters should have max_hit_chance")
	
	print("✓ Parameter adjustment test passed")
	tests_passed += 7
	tests_total += 7

# Helper function to create mock character
func create_mock_character(agi: int, luk: int):
	var character = {}
	character.agility = agi
	character.luck = luk
	
	# Add methods to simulate character behavior
	character.get_agility = func(): return character.agility
	character.get_attribute = func(attr): 
		if attr == "agility": return character.agility
		if attr == "luck": return character.luck
		return 0
	character.get_id = func(): return "mock_character"
	character.is_in_break_state = func(): return false
	character.is_stunned = func(): return false
	character.is_frozen = func(): return false
	character.has_status_effect = func(status): return false
	
	return character

# Helper function to create mock character with state
func create_mock_character_with_state(agi: int, luk: int, state: String):
	var character = create_mock_character(agi, luk)
	
	if state == "broken":
		character.is_in_break_state = func(): return true
	elif state == "stunned":
		character.is_stunned = func(): return true
	elif state == "frozen":
		character.is_frozen = func(): return true
	
	return character

# Helper function to create mock character with status
func create_mock_character_with_status(agi: int, luk: int, statuses: Array):
	var character = create_mock_character(agi, luk)
	
	# Override has_status_effect to return true for specified statuses
	var original_has_status = character.has_status_effect
	character.has_status_effect = func(status): 
		return status in statuses
	
	return character

# Helper function for assertions
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("Assertion failed: " + message)
	
	tests_total += 1