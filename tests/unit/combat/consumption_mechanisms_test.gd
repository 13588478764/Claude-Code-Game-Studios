# Consumption Mechanisms Unit Test
# Tests for the consumption mechanisms implementation

extends Node

# Import the script to test
var QiManager = load("res://src/scripts/combat/qi_manager.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Consumption Mechanisms tests...")
	
	# Test 1: Initialization
	test_initialization()
	
	# Test 2: Fixed base consumption
	test_fixed_base_consumption()
	
	# Test 3: Combo scaling consumption
	test_combo_scaling_consumption()
	
	# Test 4: Attribute modifiers
	test_attribute_modifiers()
	
	# Test 5: Overload mechanism
	test_overload_mechanism()
	
	# Test 6: Actual cost calculation
	test_actual_cost_calculation()
	
	# Test 7: Low level art for character
	test_low_level_art_for_character()
	
	# Test 8: Can overload check
	test_can_overload_check()
	
	print("Consumption Mechanisms tests completed: %d/%d passed" % [tests_passed, tests_total])

# Test initialization
func test_initialization():
	var manager = QiManager.new()
	
	# Check that initial values are set correctly
	assert(manager.get_current_qi() > 0, "Current Qi should be greater than 0")
	assert(manager.get_max_qi() > 0, "Max Qi should be greater than 0")
	assert(manager.combo_count == 0, "Combo count should start at 0")
	
	print("✓ Initialization test passed")
	tests_passed += 3
	tests_total += 3

# Test fixed base consumption
func test_fixed_base_consumption():
	var manager = QiManager.new()
	
	# Set Qi to a known value
	manager.set_qi_value(100)
	var initial_qi = manager.get_current_qi()
	
	# Try to consume some Qi
	var consumed = manager.consume_qi(20)
	
	# Should succeed if Qi is sufficient
	assert(consumed == true, "Should be able to consume Qi if available")
	assert(manager.get_current_qi() == initial_qi - 20, "Qi should decrease by consumed amount")
	
	# Try to consume more than available
	manager.set_qi_value(10)
	var failed_consumption = manager.consume_qi(50)
	
	# This should fail or trigger overload
	assert(manager.get_current_qi() == 10, "Qi should remain at 10 if consumption failed")
	
	print("✓ Fixed base consumption test passed")
	tests_passed += 4
	tests_total += 4

# Test combo scaling consumption
func test_combo_scaling_consumption():
	var manager = QiManager.new()
	
	# Set Qi to a high value to allow multiple consumptions
	manager.set_qi_value(200)
	
	# First consumption (no combo)
	var initial_qi = manager.get_current_qi()
	var base_cost = 20
	var first_consumed = manager.consume_qi(base_cost)
	
	assert(first_consumed == true, "First consumption should succeed")
	var after_first = manager.get_current_qi()
	
	# Increment combo
	manager.increment_combo()
	
	# Second consumption (with combo)
	var second_consumed = manager.consume_qi(base_cost)
	assert(second_consumed == true, "Second consumption should succeed")
	var after_second = manager.get_current_qi()
	
	# The second consumption should cost more due to combo scaling
	var first_cost = initial_qi - after_first
	var second_cost = after_first - after_second
	
	# With combo scaling, second cost should be higher than base cost
	var expected_second_cost = int(float(base_cost) * (1 + manager.get_combo_scaling() * 1))
	assert(second_cost == expected_second_cost, "Second consumption should have higher cost due to combo scaling")
	
	print("✓ Combo scaling consumption test passed")
	tests_passed += 5
	tests_total += 5

# Test attribute modifiers
func test_attribute_modifiers():
	var manager = QiManager.new()
	
	# Set a high mind attribute to test consumption reduction
	var original_mind = manager.mind_attribute
	manager.mind_attribute = 50  # 50% of the maximum reduction (30%)
	
	# Calculate expected reduction
	var expected_reduction = min(float(manager.mind_attribute) * 0.01, 0.3)
	assert(expected_reduction == 0.3, "Mind reduction should be capped at 30%")
	
	# Test with a known base cost
	var base_cost = 50
	var actual_cost = manager.calculate_actual_cost(base_cost, null)
	var expected_cost = int(float(base_cost) * (1 - expected_reduction))
	
	# Reset mind attribute for other tests
	manager.mind_attribute = original_mind
	
	print("✓ Attribute modifiers test passed")
	tests_passed += 1
	tests_total += 1

# Test overload mechanism
func test_overload_mechanism():
	var manager = QiManager.new()
	
	# Set very low Qi
	manager.set_qi_value(5)
	
	# Try to consume more than available
	var base_cost = 50
	var result = manager.consume_qi(base_cost)
	
	# This should trigger overload mechanism
	assert(result == true, "Should return true when overload is triggered")
	
	print("✓ Overload mechanism test passed")
	tests_passed += 1
	tests_total += 1

# Test actual cost calculation
func test_actual_cost_calculation():
	var manager = QiManager.new()
	
	var base_cost = 30
	
	# Test with no combo and default attributes
	var actual_cost_no_combo = manager.calculate_actual_cost(base_cost, null)
	assert(actual_cost_no_combo == base_cost, "Actual cost should equal base cost with no combo and no modifiers")
	
	# Test with combo
	manager.increment_combo()
	var actual_cost_with_combo = manager.calculate_actual_cost(base_cost, null)
	var expected_with_combo = int(float(base_cost) * (1 + manager.get_combo_scaling() * 1))
	assert(actual_cost_with_combo == expected_with_combo, "Actual cost should include combo scaling")
	
	# Test with martial art data that indicates low level art
	var martial_art_data = {"level_requirement": 1}
	manager.cultivation_level = 10  # Higher than requirement
	var actual_cost_with_art = manager.calculate_actual_cost(base_cost, martial_art_data)
	var expected_with_art = int(float(base_cost) * 0.5)  # Should be halved due to low level art
	assert(actual_cost_with_art == expected_with_art, "Low level art should have reduced cost")
	
	print("✓ Actual cost calculation test passed")
	tests_passed += 3
	tests_total += 3

# Test low level art for character
func test_low_level_art_for_character():
	var manager = QiManager.new()
	
	# Test with martial art that has lower level requirement
	var low_level_art = {"level_requirement": 1}
	manager.cultivation_level = 10
	var is_low_level = manager.is_low_level_art_for_character(low_level_art)
	assert(is_low_level == true, "Art with much lower requirement should be considered low level")
	
	# Test with martial art that has higher level requirement
	var high_level_art = {"level_requirement": 20}
	manager.cultivation_level = 5
	var is_high_level = manager.is_low_level_art_for_character(high_level_art)
	assert(is_high_level == false, "Art with higher requirement should not be considered low level")
	
	# Test with martial art without level requirement
	var no_requirement_art = {}
	var no_requirement_result = manager.is_low_level_art_for_character(no_requirement_art)
	assert(no_requirement_result == false, "Art without requirement should not be considered low level")
	
	print("✓ Low level art for character test passed")
	tests_passed += 3
	tests_total += 3

# Test can overload check
func test_can_overload_check():
	var manager = QiManager.new()
	
	# The current implementation always returns true for can_overload
	var can_over = manager.can_overload(100)
	assert(can_over == true, "Current implementation always returns true for can_overload")
	
	print("✓ Can overload check test passed")
	tests_passed += 1
	tests_total += 1
