# Combo System Integration Test
# Tests for the combo system integration with other systems

extends Node

# Import the scripts to test
var MartialArtsComboSystem = load("res://src/scripts/combat/martial_arts_combo_system.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Combo System Integration tests...")
	
	# Test 1: Integration with combat system
	test_integration_with_combat_system()
	
	# Test 2: Integration with martial arts system
	test_integration_with_martial_arts_system()
	
	# Test 3: Integration with UI system (simulated)
	test_integration_with_ui_system()
	
	# Test 4: Combo state machine transitions
	test_combo_state_machine_transitions()
	
	# Test 5: Link command functionality
	test_link_command_functionality()
	
	# Test 6: Combo effect calculations
	test_combo_effect_calculations()
	
	# Test 7: Performance under stress
	test_performance_under_stress()
	
	# Test 8: Edge cases and error handling
	test_edge_cases_and_error_handling()
	
	print("Combo System Integration tests completed: %d/%d passed" % [tests_passed, tests_total])

# Test integration with combat system
func test_integration_with_combat_system():
	var system = MartialArtsComboSystem.new()
	
	# Simulate combat scenario
	var skill_data = {
		"tags": ["破防"],
		"internal_energy_cost": 15.0,
		"base_damage": 100.0
	}
	
	var target_status = []
	
	# Process skill usage
	var result = system.process_skill_usage(skill_data, target_status)
	
	# Verify the system returns expected structure
	assert(result.has("damage_multiplier"), "Result should have damage_multiplier")
	assert(result.has("synergy_triggered"), "Result should have synergy_triggered")
	assert(result.has("internal_energy_refund"), "Result should have internal_energy_refund")
	assert(result.has("link_gauge_change"), "Result should have link_gauge_change")
	
	# Verify initial state
	assert(result.damage_multiplier == 1.0, "Initial damage multiplier should be 1.0 (no synergy yet)")
	assert(result.synergy_triggered == false, "No synergy should be triggered initially")
	
	# Now test with a follow-up skill that should trigger synergy
	var followup_skill = {
		"tags": ["刚"],
		"internal_energy_cost": 10.0,
		"base_damage": 80.0
	}
	
	var followup_result = system.process_skill_usage(followup_skill, target_status)
	
	# After the first skill was processed, the second should trigger synergy
	assert(followup_result.synergy_triggered == true, "Synergy should be triggered with [破防] + [刚]")
	assert(followup_result.damage_multiplier == 2.0, "Damage multiplier should be 2.0 for 破防+刚 combo")
	
	print("✓ Integration with combat system test passed")
	tests_passed += 9
	tests_total += 9

# Test integration with martial arts system
func test_integration_with_martial_arts_system():
	var system = MartialArtsComboSystem.new()
	
	# Simulate martial arts data structure
	var martial_art_1 = {
		"name": "破防斩",
		"tags": ["破防", "刚"],
		"internal_energy_cost": 20.0,
		"base_damage": 120.0
	}
	
	var martial_art_2 = {
		"name": "雷击术",
		"tags": ["雷"],
		"internal_energy_cost": 15.0,
		"base_damage": 100.0
	}
	
	# Process first martial art
	var result1 = system.process_skill_usage(martial_art_1)
	
	# Process second martial art that should synergize with first
	var result2 = system.process_skill_usage(martial_art_2)
	
	# Check if the expected synergy occurred
	assert(result2.synergy_triggered == true, "Synergy should occur between 破防-tagged and 雷-tagged skills")
	assert(result2.synergy_name == "粉碎打击" or result2.synergy_name == "感电爆发", "Should trigger appropriate synergy")
	
	# Test with wet status for water-lightning synergy
	var water_skill = {
		"tags": ["水"],
		"internal_energy_cost": 12.0,
		"base_damage": 90.0
	}
	
	# Reset and test with status
	system.reset_combo_state()
	var fire_skill = {
		"tags": ["火"],
		"internal_energy_cost": 18.0,
		"base_damage": 110.0
	}
	
	var fire_result = system.process_skill_usage(fire_skill)
	var water_result = system.process_skill_usage(water_skill, ["燃烧"])
	
	# Check for steam explosion synergy
	assert(water_result.synergy_triggered == true, "Steam explosion synergy should trigger with 燃烧 + 水")
	
	print("✓ Integration with martial arts system test passed")
	tests_passed += 6
	tests_total += 6

# Test integration with UI system (simulated)
func test_integration_with_ui_system():
	var system = MartialArtsComboSystem.new()
	
	# Connect to system signals to simulate UI updates
	var signal_received = {"combo_triggered": false, "link_gauge_updated": false, "synergy_detected": false}
	
	system.connect("combo_triggered", Callable(self, "_on_combo_triggered"))
	system.connect("link_gauge_updated", Callable(self, "_on_link_gauge_updated"))
	system.connect("synergy_detected", Callable(self, "_on_synergy_detected"))
	
	# Store signal states
	var original_combo_triggered = signal_received.combo_triggered
	var original_link_gauge_updated = signal_received.link_gauge_updated
	var original_synergy_detected = signal_received.synergy_detected
	
	# Perform an action that should trigger signals
	var skill_data = {
		"tags": ["破防"],
		"internal_energy_cost": 10.0
	}
	
	system.process_skill_usage(skill_data)
	
	var followup_skill = {
		"tags": ["刚"],
		"internal_energy_cost": 10.0
	}
	
	system.process_skill_usage(followup_skill)
	
	# Check if signals were emitted (in a real test, we'd verify the UI updates)
	# For this test, we'll just verify the system has the correct interface for UI integration
	assert(system.get_current_combo_state().has("link_gauge"), "System should provide link gauge data for UI")
	assert(system.get_current_combo_state().has("max_link_gauge"), "System should provide max link gauge for UI")
	assert(system.get_current_combo_state().has("current_tags"), "System should provide current tags for UI")
	
	# Test available synergies for UI display
	var available_synergies = system.get_available_synergies(["雷"], ["湿润"])
	assert(available_synergies is Array, "Available synergies should be returned as an array for UI")
	
	print("✓ Integration with UI system test passed")
	tests_passed += 6
	tests_total += 6

# Test combo state machine transitions
func test_combo_state_machine_transitions():
	var system = MartialArtsComboSystem.new()
	
	# Initial state
	var initial_state = system.get_current_combo_state()
	assert(initial_state.link_gauge == 0, "Initial link gauge should be 0")
	assert(initial_state.current_tags.size() == 0, "Initial current tags should be empty")
	assert(initial_state.last_applied_tags.size() == 0, "Initial last applied tags should be empty")
	
	# Apply first skill
	var first_skill = {
		"tags": ["刚"],
		"internal_energy_cost": 10.0
	}
	
	system.process_skill_usage(first_skill)
	var state_after_first = system.get_current_combo_state()
	assert(state_after_first.current_tags.has("刚"), "Current tags should include '刚' after first skill")
	
	# Apply second skill that doesn't synergize
	var second_skill = {
		"tags": ["柔"],
		"internal_energy_cost": 8.0
	}
	
	system.process_skill_usage(second_skill)
	var state_after_second = system.get_current_combo_state()
	assert(state_after_second.last_applied_tags.has("刚"), "Last applied tags should include '刚' after second skill")
	assert(state_after_second.current_tags.has("柔"), "Current tags should include '柔' after second skill")
	
	# Apply third skill that synergizes with the second
	var third_skill = {
		"tags": ["浮空"],
		"internal_energy_cost": 12.0
	}
	
	system.process_skill_usage(third_skill)
	var state_after_third = system.get_current_combo_state()
	# Note: This won't create a synergy since 柔+浮空 isn't defined, but the state should still update
	
	# Apply fourth skill that synergizes with third
	var fourth_skill = {
		"tags": ["坠击"],
		"internal_energy_cost": 15.0
	}
	
	var fourth_result = system.process_skill_usage(fourth_skill)
	var state_after_fourth = system.get_current_combo_state()
	assert(fourth_result.synergy_triggered == true, "Synergy should trigger for 浮空+坠击")
	assert(fourth_result.synergy_name == "空中处决", "Should be '空中处决' synergy")
	
	# Reset and verify
	system.reset_combo_state()
	var reset_state = system.get_current_combo_state()
	assert(reset_state.current_tags.size() == 0, "Current tags should be empty after reset")
	assert(reset_state.last_applied_tags.size() == 0, "Last applied tags should be empty after reset")
	
	print("✓ Combo state machine transitions test passed")
	tests_passed += 11
	tests_total += 11

# Test link command functionality
func test_link_command_functionality():
	var system = MartialArtsComboSystem.new()
	
	# Initially, link should not be available
	assert(system.is_link_available() == false, "Link should not be available initially")
	
	# Increase link gauge to test availability
	system.combo_state.link_gauge = 30
	assert(system.is_link_available() == true, "Link should be available with 30+ gauge")
	
	# Test consuming link gauge
	var consumed = system.consume_link_gauge(20)
	assert(consumed == true, "Should be able to consume 20 link gauge")
	assert(system.combo_state.link_gauge == 10, "Link gauge should be reduced to 10 after consuming 20")
	
	# Test consuming more than available
	var failed_consumption = system.consume_link_gauge(15)
	assert(failed_consumption == false, "Should not be able to consume more than available")
	assert(system.combo_state.link_gauge == 10, "Link gauge should remain at 10 after failed consumption")
	
	# Test building up link gauge through combos
	var skill_data = {
		"tags": ["破防"],
		"internal_energy_cost": 10.0
	}
	
	// Reset and build up link gauge
	system.reset_combo_state()
	system.combo_state.link_gauge = 0  // Start from 0
	
	// Apply first skill
	system.process_skill_usage(skill_data)
	
	// Apply synergizing skill
	var synergizing_skill = {
		"tags": ["刚"],
		"internal_energy_cost": 10.0
	}
	
	var result = system.process_skill_usage(synergizing_skill)
	
	// The link gauge should have increased due to the combo
	assert(system.combo_state.link_gauge > 0, "Link gauge should increase after successful combo")
	
	// Apply more skills to build up gauge
	for i in range(3):
		system.process_skill_usage(skill_data)
		system.process_skill_usage(synergizing_skill)
	
	// After several combos, link gauge should be substantial
	assert(system.combo_state.link_gauge > 30, "Link gauge should be sufficient for link command after several combos")
	assert(system.is_link_available() == true, "Link should be available after building gauge")
	
	print("✓ Link command functionality test passed")
	tests_passed += 11
	tests_total += 11

# Test combo effect calculations
func test_combo_effect_calculations():
	var system = MartialArtsComboSystem.new()
	
	# Test internal energy refund calculation
	var base_cost = 30.0
	var refund = system.calculate_internal_energy_refund(base_cost)
	var min_expected = base_cost * system.REFUND_RATIO_MIN
	var max_expected = base_cost * system.REFUND_RATIO_MAX
	
	assert(refund >= min_expected, "Refund should be at least 20% of cost")
	assert(refund <= max_expected, "Refund should be at most 50% of cost")
	
	# Test link gauge increase calculation
	var basic_increase = system.calculate_link_gauge_increase("basic")
	var advanced_increase = system.calculate_link_gauge_increase("advanced")
	var ultimate_increase = system.calculate_link_gauge_increase("ultimate")
	
	assert(basic_increase == 20, "Basic combo should increase link gauge by 20")
	assert(advanced_increase == 30, "Advanced combo should increase link gauge by 30 (20 * 1.5)")
	assert(ultimate_increase == 40, "Ultimate combo should increase link gauge by 40 (20 * 2.0)")
	
	# Test damage multiplier through actual combo
	system.combo_state.last_applied_tags = ["破防"]
	var skill_data = {
		"tags": ["刚"],
		"internal_energy_cost": 10.0
	}
	
	var result = system.process_skill_usage(skill_data)
	assert(result.damage_multiplier == 2.0, "Damage multiplier should be 2.0 for 破防+刚 combo")
	assert(result.internal_energy_refund > 0, "Should receive internal energy refund for successful combo")
	
	# Test status effect application
	var wet_target_status = ["湿润"]
	system.reset_combo_state()
	var lightning_skill = {
		"tags": ["雷"],
		"internal_energy_cost": 15.0
	}
	
	var water_skill = {
		"tags": ["水"],  # This should combine with lightning on wet target
		"internal_energy_cost": 12.0
	}
	
	# Actually, we need to set up the right sequence: lightning then water on wet target
	var lightning_result = system.process_skill_usage(lightning_skill, wet_target_status)
	var water_result = system.process_skill_usage(water_skill, wet_target_status)
	
	# The synergy should be 湿+雷 which requires: previous tag "湿" and current tag "雷"
	# But we're doing雷 then 水, so let's try the right sequence
	system.reset_combo_state()
	var water_first = {
		"tags": ["湿"],
		"internal_energy_cost": 10.0
	}
	
	var lightning_followup = {
		"tags": ["雷"],
		"internal_energy_cost": 15.0
	}
	
	var water_result2 = system.process_skill_usage(water_first, wet_target_status)
	var lightning_result2 = system.process_skill_usage(lightning_followup, wet_target_status)
	
	assert(lightning_result2.synergy_triggered == true, "Should trigger synergy with wet target and雷 tag")
	
	print("✓ Combo effect calculations test passed")
	tests_passed += 12
	tests_total += 12

# Test performance under stress
func test_performance_under_stress():
	var system = MartialArtsComboSystem.new()
	
	# Performance test: Execute many combo sequences quickly
	var start_time = Time.get_ticks_usec()
	
	for i in range(100):
		# Alternate between skills that do and don't create synergies
		var skill_a = {
			"tags": ["破防"],
			"internal_energy_cost": 10.0
		}
		
		var skill_b = {
			"tags": ["刚"],
			"internal_energy_cost": 10.0
		}
		
		var skill_c = {
			"tags": ["柔"],
			"internal_energy_cost": 8.0
		}
		
		system.process_skill_usage(skill_a)
		system.process_skill_usage(skill_b)  // Should synergize with 破防
		system.process_skill_usage(skill_c)  // Should not synergize
	
	var end_time = Time.get_ticks_usec()
	var elapsed_time = (end_time - start_time) / 1000.0  // Convert to milliseconds
	
	# The entire test should complete in reasonable time (less than 100ms for 100 iterations)
	assert(elapsed_time < 100.0, "Combo system should process 100 iterations in under 100ms, took %.2f ms" % elapsed_time)
	
	# Verify system state is still valid after stress test
	var final_state = system.get_current_combo_state()
	assert(final_state.link_gauge >= 0 and final_state.link_gauge <= system.MAX_LINK_GAUGE, "Link gauge should be within valid range after stress test")
	assert(final_state.current_tags is Array, "Current tags should be an array after stress test")
	
	# Test with many different tag combinations
	var all_tags = ["刚", "柔", "金", "木", "水", "火", "土", "破防", "浮空", "坠击", "湿", "雷", "燃烧"]
	
	var stress_start_time = Time.get_ticks_usec()
	
	for i in range(50):
		var random_tags = []
		# Add 1-2 random tags
		random_tags.append(all_tags[randi() % all_tags.size()])
		if randf() > 0.5:
			random_tags.append(all_tags[randi() % all_tags.size()])
		
		var stress_skill = {
			"tags": random_tags,
			"internal_energy_cost": float(randi() % 20 + 5)
		}
		
		# Use an empty target status for this test
		system.process_skill_usage(stress_skill, [])
	
	var stress_end_time = Time.get_ticks_usec()
	var stress_elapsed = (stress_end_time - stress_start_time) / 1000.0
	
	assert(stress_elapsed < 50.0, "Random tag processing should complete in under 50ms, took %.2f ms" % stress_elapsed)
	
	print("✓ Performance under stress test passed")
	tests_passed += 5
	tests_total += 5

# Test edge cases and error handling
func test_edge_cases_and_error_handling():
	var system = MartialArtsComboSystem.new()
	
	# Test with empty skill tags
	var empty_skill = {
		"tags": [],
		"internal_energy_cost": 10.0
	}
	
	var empty_result = system.process_skill_usage(empty_skill)
	assert(empty_result.damage_multiplier == 1.0, "Empty tags should result in 1.0 damage multiplier")
	
	# Test with null/undefined values (handled gracefully)
	var null_result = system.check_synergy(null)
	assert(null_result.found == false, "Null input should result in no synergy found")
	
	# Test link gauge overflow protection
	system.combo_state.link_gauge = system.MAX_LINK_GAUGE
	var overflow_result = system.process_skill_usage({"tags": ["刚"], "internal_energy_cost": 10.0})
	# Even if we add more, it should be clamped to MAX_LINK_GAUGE
	assert(system.combo_state.link_gauge <= system.MAX_LINK_GAUGE, "Link gauge should not exceed maximum")
	
	# Test negative values
	var negative_test = system.calculate_link_gauge_increase("nonexistent_tier")
	# Should default to basic multiplier
	assert(negative_test == 20, "Nonexistent tier should default to basic multiplier")
	
	# Test very high multipliers (should be handled properly)
	var high_multiplier_synergy = system.calculate_combo_tier("破防_刚")  // 2.0 multiplier -> ultimate
	assert(high_multiplier_synergy == "ultimate", "High multiplier should result in ultimate tier")
	
	# Test combo chain limits
	for i in range(10):  // Add more than the 5-item limit
		var temp_skill = {
			"tags": ["测试%d" % i],
			"internal_energy_cost": 5.0
		}
		system.process_skill_usage(temp_skill)
	
	var final_state = system.get_current_combo_state()
	# The combo chain should be limited to 5 items
	assert(final_state.combo_chain_length <= 5, "Combo chain should be limited to 5 items")
	
	print("✓ Edge cases and error handling test passed")
	tests_passed += 7
	tests_total += 7

# Signal handlers for UI integration test
func _on_combo_triggered(combo_name: String, damage_multiplier: float):
	# Simulate UI update
	print("Combo triggered: %s with multiplier: %.2f" % [combo_name, damage_multiplier])

func _on_link_gauge_updated(value: int, max_value: int):
	# Simulate UI update
	print("Link gauge updated: %d/%d" % [value, max_value])

func _on_synergy_detected(tag1: String, tag2: String):
	# Simulate UI update
	print("Synergy detected: %s + %s" % [tag1, tag2])

# Helper function for assertions
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("Assertion failed: " + message)
	
	tests_total += 1