# World Streaming Manager
# Manages seamless world streaming and region loading/unloading

extends Node

# Constants
const LOAD_DISTANCE_MULTIPLIER = 1.5  # Multiplies screen width to determine load distance
const REGION_SIZE = 2048  # Size of each region in pixels
const PLAYER_DETECTION_RADIUS = 50  # Radius around player to check for region loading

# Signals
signal region_loaded(region_id: String)
signal region_unloaded(region_id: String)
signal player_region_changed(from_region: String, to_region: String)

# Data structures
class RegionData:
	var id: String
	var position: Vector2
	var scene_instance: Node2D
	var loaded: bool
	var last_access_time: int
	
	func _init(p_id: String, p_position: Vector2):
		id = p_id
		position = p_position
		scene_instance = null
		loaded = false
		last_access_time = Time.get_ticks_msec()

# Properties
var regions: Dictionary = {}
var current_player_region: String = ""
var player_node: Node2D = null
var screen_size: Vector2
var load_distance: float = 0.0
var unload_timer: Timer

# Initialize the world streaming manager
func _ready():
	screen_size = DisplayServer.window_get_size()
	load_distance = screen_size.x * LOAD_DISTANCE_MULTIPLIER
	print("World Streaming Manager initialized with load distance: ", load_distance)
	
	# Setup unload timer to periodically check for regions to unload
	unload_timer = Timer.new()
	unload_timer.wait_time = 5.0  # Check every 5 seconds
	unload_timer.timeout.connect(_check_regions_for_unload)
	add_child(unload_timer)
	unload_timer.start()

# Set the player node for tracking
func set_player_node(player: Node2D):
	player_node = player

# Register a region with the streaming manager
func register_region(region_id: String, position: Vector2):
	if not regions.has(region_id):
		regions[region_id] = RegionData.new(region_id, position)
		print("Registered region: ", region_id, " at position: ", position)
	else:
		print("Region already registered: ", region_id)

# Main update function - call this regularly to manage region loading/unloading
func update_streaming():
	if not player_node:
		return
	
	var player_pos = player_node.global_position
	var player_region_id = _get_region_id_at_position(player_pos)
	
	# Check if player moved to a new region
	if player_region_id != current_player_region:
		var old_region = current_player_region
		current_player_region = player_region_id
		emit_signal("player_region_changed", old_region, player_region_id)
		print("Player moved to new region: ", player_region_id)
	
	# Determine which regions should be loaded based on player position
	var regions_to_load = _get_regions_in_range(player_pos, load_distance)
	
	# Load necessary regions
	for region_id in regions_to_load:
		if regions.has(region_id):
			_load_region_if_needed(region_id)
	
	# Update access times for nearby regions
	for region_id in regions_to_load:
		if regions.has(region_id):
			regions[region_id].last_access_time = Time.get_ticks_msec()

# Get the region ID at a specific position
func _get_region_id_at_position(pos: Vector2) -> String:
	var region_x = floor(pos.x / REGION_SIZE)
	var region_y = floor(pos.y / REGION_SIZE)
	return "region_%d_%d" % [region_x, region_y]

# Get all regions within a certain range of a position
func _get_regions_in_range(center_pos: Vector2, range: float) -> Array:
	var regions_list = []
	
	# Calculate the range in terms of regions
	var region_range = ceil(range / REGION_SIZE)
	
	# Get the center region
	var center_region_x = floor(center_pos.x / REGION_SIZE)
	var center_region_y = floor(center_pos.y / REGION_SIZE)
	
	# Add all regions in the range
	for x in range(int(center_region_x - region_range), int(center_region_x + region_range + 1)):
		for y in range(int(center_region_y - region_range), int(center_region_y + region_range + 1)):
			var region_id = "region_%d_%d" % [x, y]
			regions_list.append(region_id)
	
	return regions_list

# Load a region if it's not already loaded
func _load_region_if_needed(region_id: String):
	if not regions.has(region_id):
		return
	
	var region = regions[region_id]
	if region.loaded:
		return
	
	# Try to load the region scene
	var region_scene_path = "res://src/scenes/regions/" + region_id + ".tscn"
	var region_scene = load(region_scene_path)
	
	if region_scene:
		region.scene_instance = region_scene.instantiate()
		region.scene_instance.position = region.position
		get_parent().add_child(region_scene.instantiate())
		region.loaded = true
		region.last_access_time = Time.get_ticks_msec()
		emit_signal("region_loaded", region_id)
		print("Loaded region: ", region_id)
	else:
		print("Could not load region scene: ", region_scene_path)

# Unload a region
func _unload_region(region_id: String):
	if not regions.has(region_id):
		return
	
	var region = regions[region_id]
	if not region.loaded or not region.scene_instance:
		return
	
	# Remove the scene instance
	if is_instance_valid(region.scene_instance):
		region.scene_instance.queue_free()
	
	region.loaded = false
	region.scene_instance = null
	emit_signal("region_unloaded", region_id)
	print("Unloaded region: ", region_id)

# Check for regions to unload based on distance and time
func _check_regions_for_unload():
	if not player_node:
		return
	
	var player_pos = player_node.global_position
	var current_time = Time.get_ticks_msec()
	
	# Unload regions that are far away and haven't been accessed recently
	# (More than 2x load distance away and not accessed in the last 30 seconds)
	var unload_distance = load_distance * 2.0
	var time_threshold = 30000  # 30 seconds in milliseconds
	
	for region_id in regions:
		var region = regions[region_id]
		
		# Skip if region is not loaded
		if not region.loaded:
			continue
		
		# Calculate distance to player
		var region_center = region.position + Vector2(REGION_SIZE/2, REGION_SIZE/2)
		var distance_to_player = player_pos.distance_to(region_center)
		
		# Unload if far away and not accessed recently
		if distance_to_player > unload_distance and \
		   (current_time - region.last_access_time) > time_threshold:
			_unload_region(region_id)

# Get the current load distance
func get_load_distance() -> float:
	return load_distance

# Set the load distance multiplier
func set_load_distance_multiplier(multiplier: float):
	if multiplier > 0:
		LOAD_DISTANCE_MULTIPLIER = multiplier
		load_distance = screen_size.x * multiplier

# Get region info
func get_region_info(region_id: String) -> Dictionary:
	if regions.has(region_id):
		var region = regions[region_id]
		return {
			"id": region.id,
			"position": region.position,
			"loaded": region.loaded,
			"last_access": region.last_access_time
		}
	return {}

# Force load a specific region
func force_load_region(region_id: String) -> bool:
	if regions.has(region_id):
		_load_region_if_needed(region_id)
		return true
	return false

# Force unload a specific region
func force_unload_region(region_id: String) -> bool:
	if regions.has(region_id):
		_unload_region(region_id)
		return true
	return false

# Get all loaded regions
func get_loaded_regions() -> Array:
	var loaded = []
	for region_id in regions:
		if regions[region_id].loaded:
			loaded.append(region_id)
	return loaded

# Get player's current region
func get_player_current_region() -> String:
	return current_player_region