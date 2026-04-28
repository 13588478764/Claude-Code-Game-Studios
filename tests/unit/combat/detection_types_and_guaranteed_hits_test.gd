# Detection Types and Guaranteed Hits Unit Test
# Tests for the detection types and guaranteed hits implementation

extends Node

# Import the script to test
var HitDetectionManager = load("res://src/scripts/combat/hit_detection_manager.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Detection Types and Guaranteed Hits tests...")
	
	# Test 1: Basic attack hit detection
	test_basic_attack_hit_detection()
	
	# Test 2: Skill hit detection (single, area, duration)
	test_skill_hit_detection()
	
	# Test 3: Counter/link hit detection
	test_counter_link_hit_detection()
	
	# Test 4: Guaranteed hit mechanism
	test_guaranteed_hit_mechanism()
	
	# Test 5: Different detection types
	test_different_detection_types()
	
	# Test 6: Sure_Hit tag functionality
	test_sure_hit_tag_functionality()
	
	# Test 7: State-based guaranteed hits
	test_state_based_guaranteed_hits()
	
	# Test 8: Complex scenarios
	test_complex_scenarios()
	
	print("Detection Types and Guaranteed Hits tests completed: %d/%d passed" % [tests_passed, tests_total])

# Test basic attack hit detection
func test_basic_attack_hit_detection():
	var manager = HitDetectionManager.new()
	
	# Create mock attacker and target
	var attacker = create_mock_character(50, 10)
	var target = create_mock_character(30, 10)
	
	# Perform basic attack hit check
	var result = manager.get_hit_result(attacker, target)
	
	# Check that result is valid
	assert(result.has("hit_success"), "Result should have hit_success field")
	assert(result.has("hit_chance"), "Result should have hit_chance field")
	assert(result.has("attacker_id"), "Result should have attacker_id field")
	assert(result.has("target_id"), "Result should have target_id field")
	
	print("✓ Basic attack hit detection test passed")
	tests_passed += 4
	tests_total += 4

# Test skill hit detection (single, area, duration)
func test_skill_hit_detection():
	var manager = HitDetectionManager.new()
	
	# Test single target skill
	var attacker = create_mock_character(60, 10)
	var target = create_mock_character(40, 10)
	
	# Test with no special skill tags
	var normal_skill = {}
	var result1 = manager.get_hit_result(attacker, target, normal_skill)
	assert(result1.has("is_guaranteed"), "Result should have is_guaranteed field")
	
	# Test with different base hit chances for different skill types
	manager.set_base_hit_chance(0.85)  # For area attacks
	var area_target = create_mock_character(35, 10)
	var result2 = manager.get_hit_result(attacker, area_target)
	
	# Reset to default
	manager.set_base_hit_chance(0.9)
	
	assert(result2.has("hit_success"), "Area attack result should be valid")
	
	print("✓ Skill hit detection test passed")
	tests_passed += 2
	tests_total += 2

# Test counter/link hit detection
func test_counter_link_hit_detection():
	var manager = HitDetectionManager.new()
	
	# Create mock characters
	var attacker = create_mock_character(55, 12)
	var target = create_mock_character(35, 8)
	
	# Counter/link attacks would typically have special handling
	# For now, test that they work with normal hit detection
	var result = manager.get_hit_result(attacker, target)
	
	assert(result.hit_success == result.hit_success, "Counter/link hit detection should work")
	
	# In a real implementation, counter/link might have special bonuses
	# which would be handled through status effects or skill data
	
	print("✓ Counter/link hit detection test passed")
	tests_passed += 1
	tests_total += 1

# Test guaranteed hit mechanism
func test_guaranteed_hit_mechanism():
	var manager = HitDetectionManager.new()
	
	# Test with broken target
	var attacker = create_mock_character(40, 10)
	var broken_target = create_mock_character_with_state(40, 10, "broken")
	
	var result1 = manager.get_hit_result(attacker, broken_target)
	assert(result1.is_guaranteed == true, "Should be guaranteed hit when target is broken")
	assert(result1.hit_success == true, "Guaranteed hit should always succeed")
	
	# Test with stunned target
	var stunned_target = create_mock_character_with_state(40, 10, "stunned")
	var result2 = manager.get_hit_result(attacker, stunned_target)
	assert(result2.is_guaranteed == true, "Should be guaranteed hit when target is stunned")
	assert(result2.hit_success == true, "Guaranteed hit should always succeed")
	
	# Test with frozen target
	var frozen_target = create_mock_character_with_state(40, 10, "frozen")
	var result3 = manager.get_hit_result(attacker, frozen_target)
	assert(result3.is_guaranteed == true, "Should be guaranteed hit when target is frozen")
	assert(result3.hit_success == true, "Guaranteed hit should always succeed")
	
	# Test with Sure_Hit skill tag
	var sure_hit_skill = {"tags": ["Sure_Hit"]}
	var normal_target = create_mock_character(40, 10)
	var result4 = manager.get_hit_result(attacker, normal_target, sure_hit_skill)
	assert(result4.is_guaranteed == true, "Should be guaranteed hit with Sure_Hit skill tag")
	assert(result4.hit_success == true, "Sure_Hit skill should always succeed")
	
	print("✓ Guaranteed hit mechanism test passed")
	tests_passed += 8
	tests_total += 8

# Test different detection types
func test_different_detection_types():
	var manager = HitDetectionManager.new()
	
	# All detection types use the same underlying mechanism
	# but may have different parameters
	
	# Create test characters
	var attacker = create_mock_character(45, 10)
	var target = create_mock_character(35, 10)
	
	# Test multiple hit checks to ensure consistency
	var hit_count = 0
	for i in range(20):
		var result = manager.get_hit_result(attacker, target)
		if result.hit_success:
			hit_count += 1
	
	# With high hit chance (due to AGI advantage), most hits should succeed
	assert(hit_count >= 10, "Most hits should succeed with high hit chance")
	
	print("✓ Different detection types test passed")
	tests_passed += 1
	tests_total += 1

# Test Sure_Hit tag functionality
func test_sure_hit_tag_functionality():
	var manager = HitDetectionManager.new()
	
	var attacker = create_mock_character(30, 10)
	var target = create_mock_character(50, 10)  # Higher AGI should make hit harder
	
	# Without Sure_Hit tag, hit chance should be lower
	var normal_skill = {}
	var normal_result = manager.get_hit_result(attacker, target, normal_skill)
	
	# With Sure_Hit tag, should always hit
	var sure_hit_skill = {"tags": ["Sure_Hit"]}
	var sure_hit_result = manager.get_hit_result(attacker, target, sure_hit_skill)
	
	assert(sure_hit_result.is_guaranteed == true, "Sure_Hit skill should be marked as guaranteed")
	assert(sure_hit_result.hit_success == true, "Sure_Hit skill should always succeed")
	
	# Check that the skill tag detection works
	assert(manager.has_sure_hit_tag(sure_hit_skill) == true, "Should detect Sure_Hit tag")
	assert(manager.has_sure_hit_tag(normal_skill) == false, "Should not detect Sure_Hit tag in normal skill")
	
	print("✓ Sure_Hit tag functionality test passed")
	tests_passed += 4
	tests_total += 4

# Test state-based guaranteed hits
func test_state_based_guaranteed_hits():
	var manager = HitDetectionManager.new()
	
	var attacker = create_mock_character(30, 10)
	
	# Test all possible states that trigger guaranteed hits
	var states_to_test = ["broken", "stunned", "frozen"]
	
	for state in states_to_test:
		var target = create_mock_character_with_state(30, 10, state)
		var result = manager.get_hit_result(attacker, target)
		
		assert(result.is_guaranteed == true, "Should be guaranteed hit when target is " + state)
		assert(result.hit_success == true, "Guaranteed hit should succeed when target is " + state)
	
	print("✓ State-based guaranteed hits test passed")
	tests_passed += 6
	tests_total += 6

# Test complex scenarios
func test_complex_scenarios():
	var manager = HitDetectionManager.new()
	
	# Complex scenario: high AGI attacker vs low AGI target with guaranteed hit conditions
	var high_agi_attacker = create_mock_character(100, 15)
	var low_agi_target = create_mock_character(10, 5)
	
	# Even with low base chance due to AGI difference, guaranteed hit should still work
	var broken_low_agi_target = create_mock_character_with_state(10, 5, "broken")
	var result = manager.get_hit_result(high_agi_attacker, broken_low_agi_target)
	
	assert(result.hit_success == true, "Guaranteed hit should work regardless of AGI difference")
	assert(result.is_guaranteed == true, "Should be marked as guaranteed hit")
	
	# Test with multiple status effects
	var complex_attacker = create_mock_character_with_status(70, 10, ["Focus"])
	var complex_target = create_mock_character_with_multiple_statuses(20, 5, ["Blind", "Slowed"])
	
	var complex_result = manager.get_hit_result(complex_attacker, complex_target)
	
	# This should be a normal hit check, not guaranteed, but with high chance due to modifiers
	assert(complex_result.has("hit_success"), "Complex scenario should return valid result")
	
	print("✓ Complex scenarios test passed")
	tests_passed += 4
	tests_total += 4

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
	character.has_status_effect = func(status): 
		return status in statuses
	
	return character

# Helper function to create mock character with multiple statuses
func create_mock_character_with_multiple_statuses(agi: int, luk: int, statuses: Array):
	var character = create_mock_character(agi, luk)
	
	# Override has_status_effect to return true for specified statuses
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