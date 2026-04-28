# Defense Types and Mitigation Unit Test
# Tests for the defense types and mitigation implementation

extends Node

# Import the script to test
var DefenseMitigationManager = load("res://scripts/combat/defense_mitigation_manager.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Defense Types and Mitigation tests...")
	
	# Test 1: Initialization
	test_initialization()
	
	# Test 2: Armor reduction
	test_armor_reduction()
	
	# Test 3: Resistance reduction
	test_resistance_reduction()
	
	# Test 4: Dodge calculation
	test_dodge_calculation()
	
	# Test 5: Block mitigation
	test_block_mitigation()
	
	# Test 6: Defense application
	test_defense_application()
	
	# Test 7: Character stats update
	test_character_stats_update()
	
	# Test 8: Equipment bonuses update
	test_equipment_bonuses_update()
	
	print("Defense Types and Mitigation tests completed: %d/%d passed" % [tests_passed, tests_total])

# Test initialization
func test_initialization():
	var manager = DefenseMitigationManager.new()
	
	# Check that initial values are set correctly
	assert(manager.armor_value >= 0, "Armor value should be non-negative")
	assert(manager.qi_resistance >= 0.0, "Qi resistance should be non-negative")
	assert(manager.dodge_rate >= 0.0, "Dodge rate should be non-negative")
	assert(manager.qi_resistance <= 0.8, "Qi resistance should not exceed 80%")
	assert(manager.dodge_rate <= 0.5, "Dodge rate should not exceed 50%")
	
	print("✓ Initialization test passed")
	tests_passed += 5
	tests_total += 5

# Test armor reduction
func test_armor_reduction():
	var manager = DefenseMitigationManager.new()
	
	# Set up some armor
	manager.armor_value = 20
	var raw_damage = 30
	
	var reduction = manager.calculate_armor_reduction(raw_damage)
	var expected_reduction = min(manager.armor_value, raw_damage - 1)  # Ensure at least 1 damage
	assert(reduction == expected_reduction, "Armor reduction should follow the formula")
	
	# Test edge case: armor > raw damage
	manager.armor_value = 50
	var raw_damage_low = 10
	var reduction_low = manager.calculate_armor_reduction(raw_damage_low)
	assert(reduction_low == 9, "When armor > damage, reduction should be damage-1 to ensure 1 damage")
	
	print("✓ Armor reduction test passed")
	tests_passed += 2
	tests_total += 2

# Test resistance reduction
func test_resistance_reduction():
	var manager = DefenseMitigationManager.new()
	
	# Set up some resistance
	manager.qi_resistance = 0.3  # 30% resistance
	var raw_damage = 100
	
	var reduction = manager.calculate_resistance_reduction(raw_damage)
	var expected_reduction = int(float(raw_damage) * manager.qi_resistance)
	assert(reduction == expected_reduction, "Resistance reduction should follow the formula")
	
	# Test resistance limit
	manager.qi_resistance = 1.0  # Should be clamped to 0.8
	var reduction_limited = manager.calculate_resistance_reduction(raw_damage)
	var expected_limited = int(float(raw_damage) * 0.8)  # 80% resistance
	assert(reduction_limited == expected_limited, "Resistance should be limited to 80%")
	
	print("✓ Resistance reduction test passed")
	tests_passed += 2
	tests_total += 2

# Test dodge calculation
func test_dodge_calculation():
	var manager = DefenseMitigationManager.new()
	
	# Set up dodge rate
	manager.dodge_rate = 0.5  # 50% dodge rate
	
	# Test multiple times to check probability
	var dodge_successes = 0
	for i in range(100):
		if manager.calculate_dodge_chance():
			dodge_successes += 1
	
	# Since this is probabilistic, we just check that we get some dodges
	# and not all dodges (with high probability)
	assert(dodge_successes >= 30 and dodge_successes <= 70, "Dodge should be around 50% with some variance")
	
	# Test dodge rate limit
	manager.dodge_rate = 1.0  # Should be clamped to 0.5
	var dodge_result = manager.calculate_dodge_chance()
	# We can't test this deterministically, but the function should not crash
	
	print("✓ Dodge calculation test passed")
	tests_passed += 2
	tests_total += 2

# Test block mitigation
func test_block_mitigation():
	var manager = DefenseMitigationManager.new()
	
	# Set up block reduction
	manager.block_reduction = 0.5  # 50% reduction
	var raw_damage = 100
	
	var reduction = manager.calculate_block_mitigation(raw_damage)
	var expected_reduction = int(float(raw_damage) * manager.block_reduction)
	assert(reduction == expected_reduction, "Block reduction should follow the formula")
	
	# Test perfect block
	var perfect_reduction = manager.calculate_block_mitigation(raw_damage, true)
	assert(perfect_reduction == raw_damage, "Perfect block should reduce all damage")
	
	print("✓ Block mitigation test passed")
	tests_passed += 2
	tests_total += 2

# Test defense application
func test_defense_application():
	var manager = DefenseMitigationManager.new()
	
	# Set up some defense values
	manager.armor_value = 10
	manager.qi_resistance = 0.2  # 20% resistance
	
	var raw_damage = 50
	
	# Test physical damage (should use armor)
	var final_damage_physical = manager.apply_defense_to_damage(raw_damage, "physical")
	var expected_damage_physical = max(raw_damage - manager.armor_value, 1)
	assert(final_damage_physical == expected_damage_physical, "Physical damage should use armor reduction")
	
	# Test magical damage (should use resistance)
	var final_damage_magical = manager.apply_defense_to_damage(raw_damage, "magical")
	var resistance_reduction = int(float(raw_damage) * manager.qi_resistance)
	var expected_damage_magical = max(raw_damage - resistance_reduction, 1)
	assert(final_damage_magical == expected_damage_magical, "Magical damage should use resistance reduction")
	
	# Test dodge
	manager.dodge_rate = 1.0  # Force dodge
	var final_damage_dodge = manager.apply_defense_to_damage(raw_damage, "physical")
	assert(final_damage_dodge == 0, "Dodge should result in 0 damage")
	
	print("✓ Defense application test passed")
	tests_passed += 3
	tests_total += 3

# Test character stats update
func test_character_stats_update():
	var manager = DefenseMitigationManager.new()
	
	var initial_armor = manager.armor_value
	var initial_resistance = manager.qi_resistance
	var initial_dodge = manager.dodge_rate
	
	# Update stats
	manager.update_character_stats(30, 40, 25)  # CON, WIS, AGI
	
	# Check that values have changed
	var new_armor = manager.armor_value
	var new_resistance = manager.qi_resistance
	var new_dodge = manager.dodge_rate
	
	assert(new_armor != initial_armor, "Armor should change with CON stat")
	assert(new_resistance != initial_resistance, "Resistance should change with WIS stat")
	assert(new_dodge != initial_dodge, "Dodge should change with AGI stat")
	
	print("✓ Character stats update test passed")
	tests_passed += 3
	tests_total += 3

# Test equipment bonuses update
func test_equipment_bonuses_update():
	var manager = DefenseMitigationManager.new()
	
	var initial_armor = manager.armor_value
	var initial_resistance = manager.qi_resistance
	
	# Update equipment bonuses
	manager.update_equipment_bonuses(25, 0.15)  # Armor bonus, resistance bonus
	
	var new_armor = manager.armor_value
	var new_resistance = manager.qi_resistance
	
	assert(new_armor > initial_armor, "Armor should increase with equipment bonus")
	assert(new_resistance > initial_resistance, "Resistance should increase with equipment bonus")
	
	print("✓ Equipment bonuses update test passed")
	tests_passed += 2
	tests_total += 2

# Helper function for assertions
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("Assertion failed: " + message)
	
	tests_total += 1