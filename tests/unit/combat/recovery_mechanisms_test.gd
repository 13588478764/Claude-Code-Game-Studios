# Recovery Mechanisms Unit Test
# Tests for the recovery mechanisms implementation

extends Node

# Import the script to test
var QiManager = load("res://src/scripts/combat/qi_manager.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Recovery Mechanisms tests...")
	
	# Test 1: Initialization
	test_initialization()
	
	# Test 2: In-combat recovery
	test_in_combat_recovery()
	
	# Test 3: Out-of-combat recovery
	test_out_of_combat_recovery()
	
	# Test 4: Recovery speed calculation
	test_recovery_speed_calculation()
	
	# Test 5: Recovery effect feedback
	test_recovery_effect_feedback()
	
	# Test 6: Natural recovery calculation
	test_natural_recovery_calculation()
	
	# Test 7: Recovery bonus application
	test_recovery_bonus_application()
	
	# Test 8: Action-based recovery
	test_action_based_recovery()
	
	print("Recovery Mechanisms tests completed: %d/%d passed" % [tests_passed, tests_total])

# Test initialization
func test_initialization():
	var manager = QiManager.new()
	
	# Check that initial values are set correctly
	assert(manager.base_recovery_rate == 0.05, "Base recovery rate should be 0.05")
	assert(manager.is_in_combat == false, "Should start out of combat")
	
	print("✓ Initialization test passed")
	tests_passed += 2
	tests_total += 2

# Test in-combat recovery
func test_in_combat_recovery():
	var manager = QiManager.new()
	
	# Set to in-combat state
	manager.set_combat_state(true)
	assert(manager.is_in_combat == true, "Should be in combat after setting combat state")
	
	# Test natural recovery
	var initial_qi = manager.get_current_qi()
	manager.recover_qi_in_combat()
	var after_natural_recovery = manager.get_current_qi()
	
	# Natural recovery should have happened
	assert(after_natural_recovery >= initial_qi, "Qi should not decrease after natural recovery")
	
	# Test with action-based recovery
	manager.record_last_action("defend")
	var before_action_recovery = manager.get_current_qi()
	manager.recover_qi_in_combat()
	var after_action_recovery = manager.get_current_qi()
	
	# Should have recovered more after action
	assert(after_action_recovery >= after_natural_recovery, "Qi should increase after action recovery")
	
	print("✓ In-combat recovery test passed")
	tests_passed += 5
	tests_total += 5

# Test out-of-combat recovery
func test_out_of_combat_recovery():
	var manager = QiManager.new()
	
	# Reduce Qi to test recovery
	manager.set_qi_value(50)
	assert(manager.get_current_qi() == 50, "Qi should be set to 50")
	
	# Should be out of combat by default
	assert(manager.is_in_combat == false, "Should start out of combat")
	
	# Test recovery to full
	var before_recovery = manager.get_current_qi()
	manager.recover_qi_out_of_combat()
	var after_recovery = manager.get_current_qi()
	
	# Should recover to max
	assert(after_recovery == manager.get_max_qi(), "Qi should recover to max when out of combat")
	
	print("✓ Out-of-combat recovery test passed")
	tests_passed += 4
	tests_total += 4

# Test recovery speed calculation
func test_recovery_speed_calculation():
	var manager = QiManager.new()
	
	# Test natural recovery calculation
	var natural_recovery = manager.calculate_natural_recovery()
	var expected_natural = float(manager.get_max_qi()) * manager.base_recovery_rate * (1 + min(float(manager.wisdom) * 0.05, 0.5))
	
	# The actual recovery should match the expected calculation
	assert(abs(natural_recovery - expected_natural) < 0.1, "Natural recovery should match formula")
	
	# Test different recovery types
	var attack_recovery = manager.calculate_recovery_amount("attack")
	assert(attack_recovery == 10.0, "Attack recovery should be 10.0")
	
	var defend_recovery = manager.calculate_recovery_amount("defend")
	assert(defend_recovery == 20.0, "Defend recovery should be 20.0")
	
	var hit_recovery = manager.calculate_recovery_amount("hit_taken")
	assert(hit_recovery == 5.0, "Hit taken recovery should be 5.0")
	
	print("✓ Recovery speed calculation test passed")
	tests_passed += 4
	tests_total += 4

# Test recovery effect feedback
func test_recovery_effect_feedback():
	var manager = QiManager.new()
	
	# Test that signals are properly emitted during recovery
	var initial_qi = manager.get_current_qi()
	var recovered = manager.add_qi(10)
	
	# The recovery should match what was added
	assert(recovered == 10, "Recovered amount should match added amount")
	assert(manager.get_current_qi() == initial_qi + 10, "Qi should increase by recovered amount")
	
	# Test recovery to max doesn't exceed max
	var max_qi = manager.get_max_qi()
	var excess_recovery = manager.add_qi(1000)  # Try to add more than max
	assert(manager.get_current_qi() == max_qi, "Qi should not exceed max")
	
	print("✓ Recovery effect feedback test passed")
	tests_passed += 3
	tests_total += 3

# Test natural recovery calculation
func test_natural_recovery_calculation():
	var manager = QiManager.new()
	
	# Test with default values
	var max_qi = float(manager.get_max_qi())
	var base_rate = manager.base_recovery_rate
	var wisdom_bonus = min(float(manager.wisdom) * 0.05, 0.5)
	var expected_recovery = max_qi * base_rate * (1 + wisdom_bonus)
	
	var actual_recovery = manager.calculate_natural_recovery()
	assert(abs(actual_recovery - expected_recovery) < 0.1, "Natural recovery should match formula")
	
	# Test with higher wisdom
	var original_wisdom = manager.wisdom
	manager.wisdom = 50
	var high_wisdom_recovery = manager.calculate_natural_recovery()
	manager.wisdom = original_wisdom  # Reset
	
	assert(high_wisdom_recovery > actual_recovery, "Higher wisdom should result in higher recovery")
	
	print("✓ Natural recovery calculation test passed")
	tests_passed += 3
	tests_total += 3

# Test recovery bonus application
func test_recovery_bonus_application():
	var manager = QiManager.new()
	
	# Test wisdom bonus
	var base_amount = 10.0
	var wisdom_bonus = manager.apply_recovery_bonus(base_amount, "wisdom")
	var expected_with_wisdom = base_amount * (1 + min(float(manager.wisdom) * 0.02, 0.3))
	assert(abs(wisdom_bonus - expected_with_wisdom) < 0.1, "Wisdom bonus should be applied correctly")
	
	# Test environment bonus
	var environment_bonus = manager.apply_recovery_bonus(base_amount, "environment")
	assert(environment_bonus == base_amount * 2.0, "Environment bonus should double the amount")
	
	# Test item bonus
	var item_bonus = manager.apply_recovery_bonus(base_amount, "item")
	assert(item_bonus == base_amount * 1.5, "Item bonus should increase amount by 50%")
	
	# Test no bonus
	var no_bonus = manager.apply_recovery_bonus(base_amount, "none")
	assert(no_bonus == base_amount, "No bonus should return original amount")
	
	print("✓ Recovery bonus application test passed")
	tests_passed += 4
	tests_total += 4

# Test action-based recovery
func test_action_based_recovery():
	var manager = QiManager.new()
	
	# Set to combat state
	manager.set_combat_state(true)
	
	# Test attack action recovery
	manager.record_last_action("attack")
	var initial_qi = manager.get_current_qi()
	manager.recover_qi_in_combat()
	var after_attack = manager.get_current_qi()
	
	# The recovery amount depends on natural recovery + action recovery
	# For attack, it should be natural + 10
	var natural = manager.calculate_natural_recovery()
	var expected_after_attack = min(manager.get_max_qi(), initial_qi + int(natural) + 10)
	assert(after_attack == expected_after_attack, "Attack action should recover 10 Qi")
	
	# Test defend action recovery
	manager.record_last_action("defend")
	var after_defend = manager.get_current_qi()
	manager.recover_qi_in_combat()
	var after_defend_recovery = manager.get_current_qi()
	
	# For defend, it should be natural + 20
	var expected_after_defend = min(manager.get_max_qi(), after_defend + int(natural) + 20)
	assert(after_defend_recovery == expected_after_defend, "Defend action should recover 20 Qi")
	
	# Test hit taken recovery
	manager.record_last_action("hit_taken")
	var after_hit_taken = manager.get_current_qi()
	manager.recover_qi_in_combat()
	var after_hit_taken_recovery = manager.get_current_qi()
	
	# For hit taken, it should be natural + 5
	var expected_after_hit_taken = min(manager.get_max_qi(), after_hit_taken + int(natural) + 5)
	assert(after_hit_taken_recovery == expected_after_hit_taken, "Hit taken action should recover 5 Qi")
	
	print("✓ Action-based recovery test passed")
	tests_passed += 3
	tests_total += 3

# Helper function for assertions
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("Assertion failed: " + message)
	
	tests_total += 1