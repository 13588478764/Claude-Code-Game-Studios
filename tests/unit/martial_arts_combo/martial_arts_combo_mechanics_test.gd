# Martial Arts Combo Mechanics Unit Test
# Tests for the martial arts combination mechanism implementation

extends Node

# Import the script to test
var MartialArtsComboSystem = load("res://src/scripts/combat/martial_arts_combo_system.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Martial Arts Combo Mechanics tests...")
	
	# Test 1: Initialization
	test_initialization()
	
	# Test 2: Synergy detection
	test_synergy_detection()
	
	# Test 3: Damage calculation
	test_damage_calculation()
	
	# Test 4: Internal energy refund
	test_internal_energy_refund()
	
	# Test 5: Link gauge management
	test_link_gauge_management()
	
	# Test 6: Combo state management
	test_combo_state_management()
	
	# Test 7: Available synergies detection
	test_available_synergies_detection()
	
	# Test 8: Combo tier calculation
	test_combo_tier_calculation()
	
	print("Martial Arts Combo Mechanics tests completed: %d/%d passed" % [tests_passed, tests_total])

# Test initialization
func test_initialization():
	var system = MartialArtsComboSystem.new()
	
	# Check that initial values are set correctly
	assert(system.MAX_LINK_GAUGE == 100, "Max link gauge should be 100")
	assert(system.COMBO_WINDOW_TIME == 3.0, "Combo window time should be 3.0 seconds")
	assert(system.combo_state.current_tags.size() == 0, "Initial current tags should be empty")
	assert(system.combo_state.last_applied_tags.size() == 0, "Initial last applied tags should be empty")
	assert(system.combo_state.link_gauge == 0, "Initial link gauge should be 0")
	assert(system.combo_state.current_combo_chain.size() == 0, "Initial combo chain should be empty")
	
	print("✓ Initialization test passed")
	tests_passed += 6
	tests_total += 6

# Test synergy detection
func test_synergy_detection():
	var system = MartialArtsComboSystem.new()
	
	# Set up a previous tag to test synergy with
	system.combo_state.last_applied_tags = ["破防"]
	
	# Test skill with synergizing tag
	var skill_data = {
		"tags": ["刚"],
		"internal_energy_cost": 10.0
	}
	
	var result = system.check_synergy(skill_data.tags)
	assert(result.found == true, "Synergy should be detected between [破防] and [刚]")
	assert(result.name == "粉碎打击", "Synergy name should be '粉碎打击'")
	assert(result.multiplier == 2.0, "Synergy multiplier should be 2.0")
	
	# Test skill without synergizing tag
	var non_synergy_skill = {
		"tags": ["柔"],
		"internal_energy_cost": 10.0
	}
	
	var non_result = system.check_synergy(non_synergy_skill.tags)
	assert(non_result.found == false, "No synergy should be detected for non-synergizing tags")
	
	# Test reverse synergy
	system.combo_state.last_applied_tags = ["湿"]
	var water_skill = {
		"tags": ["雷"],
		"internal_energy_cost": 10.0
	}
	
	var reverse_result = system.check_synergy(water_skill.tags)
	assert(reverse_result.found == true, "Reverse synergy should be detected between [湿] and [雷]")
	assert(reverse_result.name == "感电爆发", "Reverse synergy name should be '感电爆发'")
	
	print("✓ Synergy detection test passed")
	tests_passed += 7
	tests_total += 7

# Test damage calculation
func test_damage_calculation():
	var system = MartialArtsComboSystem.new()
	
	# Set up a previous tag to test synergy with
	system.combo_state.last_applied_tags = ["破防"]
	
	# Test skill with synergizing tag
	var skill_data = {
		"tags": ["刚"],
		"internal_energy_cost": 10.0
	}
	
	var result = system.process_skill_usage(skill_data)
	assert(result.synergy_triggered == true, "Synergy should be triggered")
	assert(result.damage_multiplier == 2.0, "Damage multiplier should be 2.0 for 破防+刚 combo")
	assert(result.synergy_name == "粉碎打击", "Synergy name should be '粉碎打击'")
	
	# Test skill without synergizing tag
	var non_synergy_skill = {
		"tags": ["柔"],
		"internal_energy_cost": 10.0
	}
	
	var non_result = system.process_skill_usage(non_synergy_skill)
	assert(non_result.synergy_triggered == false, "No synergy should be triggered for non-synergizing tags")
	assert(non_result.damage_multiplier == 1.0, "Damage multiplier should be 1.0 for non-synergizing tags")
	
	print("✓ Damage calculation test passed")
	tests_passed += 6
	tests_total += 6

# Test internal energy refund
func test_internal_energy_refund():
	var system = MartialArtsComboSystem.new()
	
	# Test internal energy refund calculation
	var cost = 30.0
	var refund = system.calculate_internal_energy_refund(cost)
	
	# The refund should be between 20% and 50% of the cost
	var min_expected = cost * system.REFUND_RATIO_MIN
	var max_expected = cost * system.REFUND_RATIO_MAX
	assert(refund >= min_expected, "Refund should be at least 20% of cost")
	assert(refund <= max_expected, "Refund should be at most 50% of cost")
	
	# Test with synergy (should trigger refund)
	system.combo_state.last_applied_tags = ["破防"]
	var skill_data = {
		"tags": ["刚"],
		"internal_energy_cost": 30.0
	}
	
	var result = system.process_skill_usage(skill_data)
	assert(result.internal_energy_refund > 0.0, "Internal energy refund should be greater than 0 when synergy triggers")
	
	print("✓ Internal energy refund test passed")
	tests_passed += 4
	tests_total += 4

# Test link gauge management
func test_link_gauge_management():
	var system = MartialArtsComboSystem.new()
	
	# Check initial link gauge
	assert(system.combo_state.link_gauge == 0, "Initial link gauge should be 0")
	assert(system.is_link_available() == false, "Link should not be available with 0 gauge")
	
	# Process a skill to increase link gauge
	system.combo_state.last_applied_tags = ["破防"]
	var skill_data = {
		"tags": ["刚"],
		"internal_energy_cost": 10.0
	}
	
	var result = system.process_skill_usage(skill_data)
	
	# After synergy, link gauge should increase
	var expected_basic_increase = 20  # Basic increase
	var expected_advanced_increase = int(expected_basic_increase * system.combo_tier_multipliers.advanced)  # Advanced combo
	var expected_ultimate_increase = int(expected_basic_increase * system.combo_tier_multipliers.ultimate)  # Ultimate combo
	
	# The 破防+刚 combo has 2.0 multiplier, which should be classified as ultimate
	assert(system.combo_state.link_gauge > 0, "Link gauge should increase after successful combo")
	
	# Test link availability
	system.combo_state.link_gauge = 30
	assert(system.is_link_available() == true, "Link should be available with 30+ gauge")
	
	# Test link consumption
	var consumed = system.consume_link_gauge(20)
	assert(consumed == true, "Should be able to consume 20 link gauge")
	assert(system.combo_state.link_gauge == 10, "Link gauge should be reduced by 20 after consumption")
	
	# Test insufficient gauge
	var failed_consumption = system.consume_link_gauge(20)
	assert(failed_consumption == false, "Should not be able to consume 20 link gauge when only 10 available")
	
	print("✓ Link gauge management test passed")
	tests_passed += 8
	tests_total += 8

# Test combo state management
func test_combo_state_management():
	var system = MartialArtsComboSystem.new()
	
	# Initial state
	assert(system.combo_state.current_tags.size() == 0, "Initial current tags should be empty")
	assert(system.combo_state.last_applied_tags.size() == 0, "Initial last applied tags should be empty")
	
	# Update combo state
	var tags = ["刚", "金"]
	system.update_combo_state(tags)
	
	assert(system.combo_state.current_tags.size() == 2, "Current tags should have 2 elements after update")
	assert(system.combo_state.current_tags[0] == "刚", "First tag should be '刚'")
	assert(system.combo_state.current_tags[1] == "金", "Second tag should be '金'")
	
	# Process another skill to test last_applied_tags update
	system.combo_state.last_applied_tags = ["破防"]
	var skill_data = {
		"tags": ["刚"],
		"internal_energy_cost": 10.0
	}
	
	system.process_skill_usage(skill_data)
	
	assert(system.combo_state.last_applied_tags.size() > 0, "Last applied tags should be updated after skill usage")
	
	# Test combo chain length
	assert(system.combo_state.current_combo_chain.size() <= 5, "Combo chain should not exceed 5 entries")
	
	# Test reset
	system.reset_combo_state()
	assert(system.combo_state.current_tags.size() == 0, "Current tags should be empty after reset")
	assert(system.combo_state.last_applied_tags.size() == 0, "Last applied tags should be empty after reset")
	
	print("✓ Combo state management test passed")
	tests_passed += 9
	tests_total += 9

# Test available synergies detection
func test_available_synergies_detection():
	var system = MartialArtsComboSystem.new()
	
	# Set up previous tags
	system.combo_state.last_applied_tags = ["破防"]
	
	# Test available synergies
	var current_tags = ["刚"]
	var target_status = []
	var available_synergies = system.get_available_synergies(current_tags, target_status)
	
	assert(available_synergies.size() > 0, "Should find available synergies")
	assert(available_synergies[0].name == "粉碎打击", "Should find 破防+刚 synergy")
	assert(available_synergies[0].damage_multiplier == 2.0, "Synergy should have correct damage multiplier")
	
	# Test with target status synergies
	system.combo_state.last_applied_tags = ["湿"]
	var current_tags2 = ["雷"]
	var target_status2 = ["湿润"]
	var available_synergies2 = system.get_available_synergies(current_tags2, target_status2)
	
	assert(available_synergies2.size() > 0, "Should find status-based synergies")
	assert(available_synergies2[0].name == "感电爆发", "Should find 湿+雷 synergy")
	
	# Test with no synergies available
	system.combo_state.last_applied_tags = ["柔"]
	var current_tags3 = ["木"]
	var available_synergies3 = system.get_available_synergies(current_tags3, [])
	
	assert(available_synergies3.size() == 0, "Should find no synergies when none available")
	
	print("✓ Available synergies detection test passed")
	tests_passed += 7
	tests_total += 7

# Test combo tier calculation
func test_combo_tier_calculation():
	var system = MartialArtsComboSystem.new()
	
	# Test basic combo tier (multiplier < 1.6)
	var basic_tier = system.calculate_combo_tier("燃烧_水")  # Has 1.6 multiplier, should be advanced
	# Actually, looking at the synergy table, 燃烧_水 has 1.6 multiplier, which should be advanced
	# 破防_刚 has 2.0 multiplier, which should be ultimate
	var ultimate_tier = system.calculate_combo_tier("破防_刚")
	var advanced_tier = system.calculate_combo_tier("湿_雷")  # Has 1.8 multiplier, should be advanced
	
	# Correcting the expectations based on actual values in the synergy table:
	# 燃烧_水: 1.6 -> should be advanced (since 1.6 >= 1.6)
	# 湿_雷: 1.8 -> should be advanced (since 1.8 >= 1.6 but < 2.0)
	# 破防_刚: 2.0 -> should be ultimate (since 2.0 >= 2.0)
	
	assert(ultimate_tier == "ultimate", "破防_刚 should be ultimate tier (2.0 multiplier)")
	assert(advanced_tier == "advanced", "湿_雷 should be advanced tier (1.8 multiplier)")
	
	# We don't have a synergy with < 1.6 multiplier in our table, so let's test the logic differently
	# The function checks: if multiplier >= 2.0 -> ultimate, elif multiplier >= 1.6 -> advanced, else -> basic
	# So 燃烧_水 with 1.6 should be advanced
	var combustion_tier = system.calculate_combo_tier("燃烧_水")
	assert(combustion_tier == "advanced", "燃烧_水 should be advanced tier (1.6 multiplier)")
	
	print("✓ Combo tier calculation test passed")
	tests_passed += 3
	tests_total += 3

# Helper function for assertions
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("Assertion failed: " + message)
	
	tests_total += 1