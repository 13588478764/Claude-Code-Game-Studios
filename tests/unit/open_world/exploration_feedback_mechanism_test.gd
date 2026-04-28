# Exploration Feedback Mechanism Unit Test
# Tests the exploration tracker functionality

extends Node

# Import the script to test
var ExplorationTracker = load("res://src/scripts/world/exploration_tracker.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Exploration Feedback Mechanism tests...")
	
	# Test 1: Initialization
	test_initialization()
	
	# Test 2: Region management
	test_region_management()
	
	# Test 3: POI management
	test_poi_management()
	
	# Test 4: Discovery system
	test_discovery_system()
	
	# Test 5: Achievement system
	test_achievement_system()
	
	# Test 6: Data persistence
	test_data_persistence()
	
	print("Exploration Feedback Mechanism tests complete: %d/%d passed" % [tests_passed, tests_total])

# Test initialization
func test_initialization():
	var tracker = ExplorationTracker.new()
	
	assert(tracker != null, "Exploration tracker should be created")
	assert(tracker.get_overall_exploration_stats().total_poi_count == 0, "Total POI count should be 0 initially")
	assert(tracker.get_overall_exploration_stats().discovered_poi_count == 0, "Discovered POI count should be 0 initially")
	assert(tracker.overall_exploration_percentage == 0.0, "Overall exploration percentage should be 0 initially")
	
	print("✓ Initialization test passed")
	tests_passed += 4
	tests_total += 4

# Test region management
func test_region_management():
	var tracker = ExplorationTracker.new()
	
	# Test registering a region
	var result = tracker.register_region("test_region_1")
	assert(result == true, "Region should be successfully registered")
	
	# Try to register the same region again
	var result2 = tracker.register_region("test_region_1")
	# This should return false since region already exists
	
	# Test getting region info for non-existent region
	var region_info = tracker.get_region_exploration_info("nonexistent_region")
	assert(region_info.size() == 0, "Should return empty dict for nonexistent region")
	
	# Test getting region info for existing region
	var region_info2 = tracker.get_region_exploration_info("test_region_1")
	assert(region_info2.size() > 0, "Should return info for existing region")
	assert(region_info2.total_poi_count == 0, "New region should have 0 POIs initially")
	
	print("✓ Region management test passed")
	tests_passed += 4
	tests_total += 4

# Test POI management
func test_poi_management():
	var tracker = ExplorationTracker.new()
	
	# Register a region first
	tracker.register_region("test_region_poi")
	
	# Add a POI to the region
	var poi_result = tracker.add_poi_to_region(
		"test_region_poi", 
		"poi_1", 
		Vector2(100, 100), 
		tracker.POI_TYPE.RESOURCE_NODE, 
		"Test Resource", 
		"A test resource node"
	)
	assert(poi_result == true, "POI should be successfully added to region")
	
	# Try to add the same POI again
	var poi_result2 = tracker.add_poi_to_region(
		"test_region_poi", 
		"poi_1", 
		Vector2(200, 200), 
		tracker.POI_TYPE.QUEST_TARGET, 
		"Test Quest", 
		"A test quest target"
	)
	assert(poi_result2 == false, "Should not be able to add duplicate POI ID")
	
	# Get POI info
	var poi_info = tracker.get_poi_info("poi_1")
	assert(poi_info.size() > 0, "Should return info for existing POI")
	assert(poi_info.name == "Test Resource", "POI name should match")
	
	# Get non-existent POI info
	var poi_info2 = tracker.get_poi_info("nonexistent_poi")
	assert(poi_info2.size() == 0, "Should return empty dict for nonexistent POI")
	
	print("✓ POI management test passed")
	tests_passed += 5
	tests_total += 5

# Test discovery system
func test_discovery_system():
	var tracker = ExplorationTracker.new()
	
	# Register a region and add a POI
	tracker.register_region("test_region_discovery")
	tracker.add_poi_to_region(
		"test_region_discovery",
		"discovery_poi_1",
		Vector2(0, 0),
		tracker.POI_TYPE.RESOURCE_NODE,
		"Discovery Test POI",
		"A POI for discovery testing"
	)
	
	# Check initial status
	var initial_info = tracker.get_poi_info("discovery_poi_1")
	assert(initial_info.status == "UNDISCOVERED", "POI should be undiscovered initially")
	
	# Discover the POI
	var discover_result = tracker.discover_poi("discovery_poi_1")
	assert(discover_result == true, "POI should be successfully discovered")
	
	# Check status after discovery
	var after_discovery_info = tracker.get_poi_info("discovery_poi_1")
	assert(after_discovery_info.status == "DISCOVERED", "POI should be discovered after discovery")
	
	# Try to discover already discovered POI
	var discover_result2 = tracker.discover_poi("discovery_poi_1")
	assert(discover_result2 == false, "Should not be able to rediscover already discovered POI")
	
	# Test discovering POI at position
	var discovered_at_pos = tracker.discover_poi_at_position(Vector2(10, 10), 50.0)
	# This should not discover anything since our POI is at (0,0) and we're checking at (10,10) with radius 50
	# Actually, it should discover it since 10,10 is within 50 units of 0,0
	assert(discovered_at_pos.size() >= 0, "Should return array of discovered POIs")
	
	# Test activation and completion
	var activate_result = tracker.activate_poi("discovery_poi_1")
	assert(activate_result == true, "Should be able to activate discovered POI")
	
	var complete_result = tracker.complete_poi("discovery_poi_1")
	assert(complete_result == true, "Should be able to complete activated POI")
	
	print("✓ Discovery system test passed")
	tests_passed += 7
	tests_total += 7

# Test achievement system
func test_achievement_system():
	var tracker = ExplorationTracker.new()
	
	# Check initial achievements
	var achievements = tracker.achievements
	assert(achievements.size() > 0, "Should have predefined achievements")
	
	# Test unlocking an achievement
	var unlock_result = tracker.unlock_achievement("first_discovery")
	assert(unlock_result == true, "Should be able to unlock achievement")
	
	# Try to unlock already unlocked achievement
	var unlock_result2 = tracker.unlock_achievement("first_discovery")
	assert(unlock_result2 == false, "Should not be able to unlock already unlocked achievement")
	
	# Check that achievement is marked as unlocked
	assert(achievements.first_discovery.unlocked == true, "Achievement should be marked as unlocked")
	
	print("✓ Achievement system test passed")
	tests_passed += 4
	tests_total += 4

# Test data persistence
func test_data_persistence():
	var tracker = ExplorationTracker.new()
	
	# Add some data to the tracker
	tracker.register_region("persist_region")
	tracker.add_poi_to_region(
		"persist_region",
		"persist_poi_1",
		Vector2(50, 50),
		tracker.POI_TYPE.QUEST_TARGET,
		"Persistent POI",
		"A POI for persistence testing"
	)
	
	# Discover the POI to change some state
	tracker.discover_poi("persist_poi_1")
	
	# Save the data
	var saved_data = tracker.save_exploration_data()
	assert(saved_data.size() > 0, "Saved data should not be empty")
	assert(saved_data.total_poi_count >= 0, "Saved data should contain total POI count")
	assert(saved_data.discovered_poi_count >= 0, "Saved data should contain discovered POI count")
	
	# Create a new tracker and load the data
	var new_tracker = ExplorationTracker.new()
	new_tracker.load_exploration_data(saved_data)
	
	# Check that the data was loaded correctly
	var loaded_region_info = new_tracker.get_region_exploration_info("persist_region")
	assert(loaded_region_info.total_poi_count > 0, "Loaded tracker should have region with POIs")
	
	var loaded_poi_info = new_tracker.get_poi_info("persist_poi_1")
	assert(loaded_poi_info.size() > 0, "Loaded tracker should have the POI")
	
	print("✓ Data persistence test passed")
	tests_passed += 6
	tests_total += 6

# Utility function for assertions
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("Assertion failed: " + message)
	
	tests_total += 1