# Qi Types and Pools Unit Test
# Tests for the qi types and pools implementation

extends Node

# Import the script to test
var QiManager = load("res://src/scripts/combat/qi_manager.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Qi Types and Pools tests...")
	
	# Test 1: Initialization
	test_initialization()
	
	# Test 2: Qi pool implementation
	test_qi_pool_implementation()
	
	# Test 3: Passive Qi implementation
	test_passive_qi_implementation()
	
	# Test 4: Active Qi implementation
	test_active_qi_implementation()
	
	# Test 5: Attribute difference implementation
	test_attribute_difference_implementation()
	
	# Test 6: Qi value setting and getting
	test_qi_value_setting_and_getting()
	
	# Test 7: Max Qi calculation
	test_max_qi_calculation()
	
	# Test 8: Qi status information
	test_qi_status_information()
	
	print("Qi Types and Pools tests completed: %d/%d passed" % [tests_passed, tests_total])

# Test initialization
func test_initialization():
	var manager = QiManager.new()
	
	# Check that initial values are set correctly
	assert(manager.get_current_qi() > 0, "Current Qi should be greater than 0")
	assert(manager.get_max_qi() > 0, "Max Qi should be greater than 0")
	assert(manager.get_current_qi() == manager.get_max_qi(), "Current Qi should equal Max Qi at start")
	
	print("✓ Initialization test passed")
	tests_passed += 3
	tests_total += 3

# Test Qi pool implementation
func test_qi_pool_implementation():
	var manager = QiManager.new()
	
	# Test basic Qi operations
	var initial_qi = manager.get_current_qi()
	var initial_max = manager.get_max_qi()
	
	assert(initial_qi > 0, "Qi should be greater than 0")
	assert(initial_max >= initial_qi, "Max Qi should be greater than or equal to current Qi")
	
	# Test setting Qi value
	manager.set_qi_value(50)
	assert(manager.get_current_qi() == 50, "Qi should be set to 50")
	
	# Test adding Qi
	var added = manager.add_qi(20)
	assert(manager.get_current_qi() == 70, "Qi should be 70 after adding 20 to 50")
	
	# Test clamping
	manager.set_qi_value(manager.get_max_qi() + 100)  # Should be clamped
	assert(manager.get_current_qi() == manager.get_max_qi(), "Qi should be clamped to max value")
	
	print("✓ Qi pool implementation test passed")
	tests_passed += 6
	tests_total += 6

# Test Passive Qi implementation
func test_passive_qi_implementation():
	var manager = QiManager.new()
	
	# Test base Qi
	var base_qi = manager.base_qi
	assert(base_qi == 100, "Base Qi should be 100")
	
	# Test wisdom effect on max Qi
	var original_wisdom = manager.wisdom
	var original_max = manager.get_max_qi()
	
	manager.wisdom = 20
	var new_max = manager.get_max_qi()
	
	# Each point of wisdom should add 5 to max Qi
	assert(new_max == original_max + (20 - original_wisdom) * 5, "Max Qi should increase with wisdom")
	
	# Test wisdom boundary
	manager.wisdom = 100  # High wisdom
	var high_wisdom_max = manager.get_max_qi()
	assert(high_wisdom_max <= 1000, "Max Qi should be clamped to 1000")
	
	print("✓ Passive Qi implementation test passed")
	tests_passed += 4
	tests_total += 4

# Test Active Qi implementation
func test_active_qi_implementation():
	var manager = QiManager.new()
	
	# Test equipment bonus
	var original_max = manager.get_max_qi()
	manager.update_equipment_bonus(50)
	var new_max = manager.get_max_qi()
	
	assert(new_max == original_max + 50, "Max Qi should increase by equipment bonus")
	
	# Test skill bonus
	var original_max2 = manager.get_max_qi()
	manager.update_skill_bonus(30)
	var new_max2 = manager.get_max_qi()
	
	assert(new_max2 == original_max2 + 30, "Max Qi should increase by skill bonus")
	
	# Test combined bonuses
	var total_bonus = 50 + 30
	var expected_max = manager.base_qi + (manager.wisdom * 5) + total_bonus
	assert(manager.get_max_qi() == expected_max, "Max Qi should reflect all bonuses")
	
	print("✓ Active Qi implementation test passed")
	tests_passed += 4
	tests_total += 4

# Test Attribute difference implementation
func test_attribute_difference_implementation():
	var manager = QiManager.new()
	
	# Test different cultivation levels
	var original_level = manager.cultivation_level
	var original_max = manager.get_max_qi()
	
	manager.cultivation_level = 10
	var new_max = manager.get_max_qi()
	
	# Cultivation level doesn't directly affect max Qi, but affects other calculations
	assert(new_max == original_max, "Max Qi should not change with cultivation level")
	
	# Test mind attribute (affects consumption reduction)
	var mind_reduction = manager.get_mind_reduction()
	assert(mind_reduction >= 0.0, "Mind reduction should be non-negative")
	assert(mind_reduction <= 0.3, "Mind reduction should be at most 30%")
	
	# Test high mind attribute
	manager.mind_attribute = 100
	var high_mind_reduction = manager.get_mind_reduction()
	assert(high_mind_reduction == 0.3, "High mind should result in 30% reduction cap")
	
	print("✓ Attribute difference implementation test passed")
	tests_passed += 5
	tests_total += 5

# Test Qi value setting and getting
func test_qi_value_setting_and_getting():
	var manager = QiManager.new()
	
	# Test setting Qi value
	manager.set_qi_value(150)
	assert(manager.get_current_qi() == 150, "Current Qi should be 150")
	
	# Test setting Qi value above max
	manager.set_qi_value(manager.get_max_qi() + 100)
	assert(manager.get_current_qi() == manager.get_max_qi(), "Qi should be clamped to max")
	
	# Test setting Qi value below 0
	manager.set_qi_value(-10)
	assert(manager.get_current_qi() == 0, "Qi should be clamped to 0")
	
	# Test add Qi
	var initial = manager.get_current_qi()
	var added = manager.add_qi(50)
	assert(manager.get_current_qi() == min(initial + 50, manager.get_max_qi()), "Qi should be increased by added amount, clamped to max")
	
	print("✓ Qi value setting and getting test passed")
	tests_passed += 5
	tests_total += 5

# Test Max Qi calculation
func test_max_qi_calculation():
	var manager = QiManager.new()
	
	# Calculate expected max Qi manually
	var expected_max = manager.base_qi + (manager.wisdom * 5) + manager.equipment_qi_bonus + manager.skill_qi_bonus
	expected_max = clamp(expected_max, 100, 1000)
	
	var actual_max = manager.calculate_max_qi()
	assert(actual_max == expected_max, "Calculated max Qi should match expected value")
	
	# Test with different values
	manager.wisdom = 50
	manager.update_equipment_bonus(100)
	manager.update_skill_bonus(50)
	
	var expected_max2 = manager.base_qi + (manager.wisdom * 5) + 100 + 50
	expected_max2 = clamp(expected_max2, 100, 1000)
	
	var actual_max2 = manager.calculate_max_qi()
	assert(actual_max2 == expected_max2, "Calculated max Qi should match expected value with new attributes")
	
	print("✓ Max Qi calculation test passed")
	tests_passed += 2
	tests_total += 2

# Test Qi status information
func test_qi_status_information():
	var manager = QiManager.new()
	
	# Get Qi status
	var status = manager.get_qi_status()
	
	# Check that all required fields are present
	assert(status.has("current"), "Status should have 'current' field")
	assert(status.has("max"), "Status should have 'max' field")
	assert(status.has("wisdom"), "Status should have 'wisdom' field")
	assert(status.has("mind_attribute"), "Status should have 'mind_attribute' field")
	assert(status.has("cultivation_level"), "Status should have 'cultivation_level' field")
	assert(status.has("combo_count"), "Status should have 'combo_count' field")
	assert(status.has("is_in_combat"), "Status should have 'is_in_combat' field")
	
	# Check that values match
	assert(status["current"] == manager.get_current_qi(), "Current Qi should match")
	assert(status["max"] == manager.get_max_qi(), "Max Qi should match")
	assert(status["wisdom"] == manager.wisdom, "Wisdom should match")
	assert(status["mind_attribute"] == manager.mind_attribute, "Mind attribute should match")
	assert(status["cultivation_level"] == manager.cultivation_level, "Cultivation level should match")
	assert(status["combo_count"] == manager.combo_count, "Combo count should match")
	assert(status["is_in_combat"] == manager.is_in_combat, "Combat state should match")
	
	print("✓ Qi status information test passed")
	tests_passed += 13
	tests_total += 13
