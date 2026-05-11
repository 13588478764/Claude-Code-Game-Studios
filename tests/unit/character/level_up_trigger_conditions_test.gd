# Level Up Trigger Conditions Unit Test
# Tests for the level up trigger conditions implementation

extends Node

# Import the script to test
var LevelUpManager = load("res://src/scripts/character/level_up_manager.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Level Up Trigger Conditions tests...")
	
	# Test 1: Initialization
	test_initialization()
	
	# Test 2: Minor realm up functionality
	test_minor_realm_up_functionality()
	
	# Test 3: Major realm breakthrough functionality
	test_major_realm_breakthrough_functionality()
	
	# Test 4: EXP threshold calculation
	test_exp_threshold_calculation()
	
	# Test 5: Perfect state detection
	test_perfect_state_detection()
	
	# Test 6: EXP addition and level progression
	test_exp_addition_and_level_progression()
	
	# Test 7: Realm structure validation
	test_realm_structure_validation()
	
	# Test 8: Player status and realm info
	test_player_status_and_realm_info()
	
	print("Level Up Trigger Conditions tests completed: %d/%d passed" % [tests_passed, tests_total])

# Test initialization
func test_initialization():
	var manager = LevelUpManager.new()
	
	# Check that initial values are set correctly
	var initial_data = manager.player_data
	assert(initial_data.level == 1, "Initial level should be 1")
	assert(initial_data.exp == 0, "Initial exp should be 0")
	assert(initial_data.current_realm == "Qi_Refining", "Initial realm should be Qi_Refining")
	assert(initial_data.attribute_points == 0, "Initial attribute points should be 0")
	assert(initial_data.talent_points == 0, "Initial talent points should be 0")
	assert(initial_data.perfect_state == false, "Initial perfect state should be false")
	
	print("✓ Initialization test passed")
	tests_passed += 5
	tests_total += 5

# Test minor realm up functionality
func test_minor_realm_up_functionality():
	var manager = LevelUpManager.new()
	
	# Add enough EXP to trigger a level up
	var current_level = manager.player_data.level
	var exp_needed = manager.calculate_exp_threshold(current_level)
	manager.player_data.exp = exp_needed
	
	# Trigger minor realm up
	var result = manager.trigger_minor_realm_up("player1")
	
	assert(result == true, "Minor realm up should succeed when EXP threshold is met")
	assert(manager.player_data.level == current_level + 1, "Level should increase by 1")
	assert(manager.player_data.exp == 0, "EXP should reset to 0 after level up")
	assert(manager.player_data.attribute_points == 5, "Should gain 5 attribute points")
	assert(manager.player_data.talent_points == 1, "Should gain 1 talent point")
	
	print("✓ Minor realm up functionality test passed")
	tests_passed += 5
	tests_total += 5

# Test major realm breakthrough functionality
func test_major_realm_breakthrough_functionality():
	var manager = LevelUpManager.new()
	
	# Set player to the last level of the first realm (炼气期10层)
	manager.player_data.level = 10
	manager.player_data.current_realm = "Qi_Refining"
	manager.player_data.perfect_state = true  # Manually set to perfect state
	
	# Add required breakthrough item
	manager.player_data.breakthrough_items["Foundation_Pill"] = 1
	
	# Attempt breakthrough
	var result = manager.trigger_major_realm_breakthrough("player1")
	
	# Check if breakthrough was successful
	assert(result == true, "Major realm breakthrough should succeed when conditions are met")
	assert(manager.player_data.current_realm != "Qi_Refining", "Should move to next realm after breakthrough")
	assert(manager.player_data.perfect_state == false, "Perfect state should be reset after breakthrough")
	
	print("✓ Major realm breakthrough functionality test passed")
	tests_passed += 3
	tests_total += 3

# Test EXP threshold calculation
func test_exp_threshold_calculation():
	var manager = LevelUpManager.new()
	
	# Test level 1 threshold
	var threshold_level_1 = manager.calculate_exp_threshold(1)
	var expected_level_1 = int(100 * pow(1, 1.5) * 1.0)  # Base EXP * (sub_level^exponent) * difficulty
	assert(threshold_level_1 == expected_level_1, "Level 1 threshold should match formula")
	
	# Test level 5 threshold (still in first realm)
	var threshold_level_5 = manager.calculate_exp_threshold(5)
	var expected_level_5 = int(100 * pow(5, 1.5) * 1.0)
	assert(threshold_level_5 == expected_level_5, "Level 5 threshold should match formula")
	
	# Test level 11 threshold (first level of second realm)
	var threshold_level_11 = manager.calculate_exp_threshold(11)
	var expected_level_11 = int(100 * pow(1, 1.5) * 1.5)  # Sub-level 1 of Foundation_Building
	assert(threshold_level_11 == expected_level_11, "Level 11 threshold should match formula for new realm")
	
	# Test edge case: unknown level
	var threshold_unknown = manager.calculate_exp_threshold(999)
	assert(threshold_unknown == 999999, "Unknown level should return large number to prevent accidental leveling")
	
	print("✓ EXP threshold calculation test passed")
	tests_passed += 4
	tests_total += 4

# Test perfect state detection
func test_perfect_state_detection():
	var manager = LevelUpManager.new()
	
	# Test perfect state for Qi_Refining realm (ends at level 10)
	var is_perfect_9 = manager.check_perfect_state(9, "Qi_Refining")
	assert(is_perfect_9 == false, "Level 9 should not be perfect state for Qi_Refining")
	
	var is_perfect_10 = manager.check_perfect_state(10, "Qi_Refining")
	assert(is_perfect_10 == true, "Level 10 should be perfect state for Qi_Refining")
	
	# Test perfect state for Foundation_Building realm (ends at level 20)
	var is_perfect_19 = manager.check_perfect_state(19, "Foundation_Building")
	assert(is_perfect_19 == false, "Level 19 should not be perfect state for Foundation_Building")
	
	var is_perfect_20 = manager.check_perfect_state(20, "Foundation_Building")
	assert(is_perfect_20 == true, "Level 20 should be perfect state for Foundation_Building")
	
	# Test with invalid realm
	var is_perfect_invalid = manager.check_perfect_state(5, "Invalid_Realm")
	assert(is_perfect_invalid == false, "Invalid realm should return false for perfect state")
	
	print("✓ Perfect state detection test passed")
	tests_passed += 5
	tests_total += 5

# Test EXP addition and level progression
func test_exp_addition_and_level_progression():
	var manager = LevelUpManager.new()
	
	# Add EXP that should trigger multiple level ups
	var initial_level = manager.player_data.level
	var exp_for_level_1 = manager.calculate_exp_threshold(1)
	
	# Add enough EXP to level up twice
	var total_exp_to_add = exp_for_level_1 + manager.calculate_exp_threshold(2) + 50
	manager.add_exp("player1", total_exp_to_add)
	
	# Check that the player leveled up appropriately
	assert(manager.player_data.level >= initial_level + 2, "Player should have leveled up at least twice")
	assert(manager.player_data.exp < exp_for_level_1, "Remaining EXP should be less than next threshold")
	
	# Check that attribute and talent points were awarded
	assert(manager.player_data.attribute_points >= 10, "Should have gained at least 10 attribute points")
	assert(manager.player_data.talent_points >= 2, "Should have gained at least 2 talent points")
	
	print("✓ EXP addition and level progression test passed")
	tests_passed += 3
	tests_total += 3

# Test realm structure validation
func test_realm_structure_validation():
	var manager = LevelUpManager.new()
	
	# Check that all realms are properly defined
	var realm_structure = manager.realm_structure
	assert(realm_structure.size() == 10, "Should have 10 realms defined")
	
	# Check specific realm properties
	var qi_refining = realm_structure["Qi_Refining"]
	assert(qi_refining.start_level == 1, "Qi_Refining should start at level 1")
	assert(qi_refining.end_level == 10, "Qi_Refining should end at level 10")
	assert(qi_refining.realm_name == "炼气期", "Qi_Refining should have correct name")
	assert(qi_refining.difficulty_coefficient == 1.0, "Qi_Refining should have correct difficulty coefficient")
	
	# Check highest realm
	var true_immortal = realm_structure["True_Immortal"]
	assert(true_immortal.start_level == 91, "True_Immortal should start at level 91")
	assert(true_immortal.end_level == 99, "True_Immortal should end at level 99")
	assert(true_immortal.realm_name == "真仙境", "True_Immortal should have correct name")
	assert(true_immortal.difficulty_coefficient == 6.0, "True_Immortal should have correct difficulty coefficient")
	
	print("✓ Realm structure validation test passed")
	tests_passed += 8
	tests_total += 8

# Test player status and realm info
func test_player_status_and_realm_info():
	var manager = LevelUpManager.new()
	
	# Get initial player status
	var status = manager.get_player_status("player1")
	assert(status.has("level"), "Status should have level field")
	assert(status.has("exp"), "Status should have exp field")
	assert(status.has("total_exp"), "Status should have total_exp field")
	assert(status.has("current_realm"), "Status should have current_realm field")
	assert(status.has("attribute_points"), "Status should have attribute_points field")
	assert(status.has("talent_points"), "Status should have talent_points field")
	assert(status.has("is_perfect_state"), "Status should have is_perfect_state field")
	
	# Get initial realm info
	var realm_info = manager.get_current_realm_info("player1")
	assert(realm_info.has("current_realm_key"), "Realm info should have current_realm_key field")
	assert(realm_info.has("current_realm_name"), "Realm info should have current_realm_name field")
	assert(realm_info.has("current_level_in_realm"), "Realm info should have current_level_in_realm field")
	assert(realm_info.has("total_levels_in_realm"), "Realm info should have total_levels_in_realm field")
	assert(realm_info.has("is_perfect_state"), "Realm info should have is_perfect_state field")
	assert(realm_info.has("exp_to_next"), "Realm info should have exp_to_next field")
	assert(realm_info.has("exp_progress"), "Realm info should have exp_progress field")
	
	# Check that the values make sense
	assert(status.level == 1, "Initial level should be 1")
	assert(realm_info.current_realm_name == "炼气期", "Initial realm name should be 炼气期")
	assert(realm_info.current_level_in_realm == 1, "Initial level in realm should be 1")
	assert(realm_info.total_levels_in_realm == 10, "Total levels in 炼气期 should be 10")
	
	print("✓ Player status and realm info test passed")
	tests_passed += 15
	tests_total += 15
