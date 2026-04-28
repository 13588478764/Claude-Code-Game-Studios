# Exploration Tracker
# Tracks player exploration progress and manages rewards

extends Node

# Signals
signal exploration_progress_updated(region_id: String, progress: float)
signal poi_discovered(poi_id: String, poi_type: String)
signal exploration_reward_granted(reward_type: String, reward_data: Dictionary)
signal achievement_unlocked(achievement_id: String, name: String)

# Constants
enum POI_TYPE { RESOURCE_NODE, QUEST_TARGET, SECRET_ENCOUNTER, FACILITY }
enum POI_STATUS { UNDISCOVERED, DISCOVERED, ACTIVATED, COMPLETED }

# Data structures
class PointOfInterest:
	var id: String
	var position: Vector2
	var type: POI_TYPE
	var status: POI_STATUS
	var name: String
	var description: String
	var reward_data: Dictionary
	var region_id: String
	
	func _init(p_id: String, p_position: Vector2, p_type: POI_TYPE, p_name: String, p_desc: String, p_region: String):
		id = p_id
		position = p_position
		type = p_type
		status = POI_STATUS.UNDISCOVERED
		name = p_name
		description = p_desc
		reward_data = {}
		region_id = p_region

class RegionData:
	var id: String
	var total_poi_count: int
	var discovered_poi_count: int
	var explored_percentage: float
	var pois: Dictionary  # poi_id -> PointOfInterest
	
	func _init(p_id: String):
		id = p_id
		total_poi_count = 0
		discovered_poi_count = 0
		explored_percentage = 0.0
		pois = {}

# Properties
var regions: Dictionary = {}  # region_id -> RegionData
var discovered_poi_count: int = 0
var total_poi_count: int = 0
var overall_exploration_percentage: float = 0.0
var achievements: Dictionary = {}
var exploration_history: Array = []

func _ready():
	print("Exploration tracker initialized")
	_initialize_achievements()

# Initialize predefined achievements
func _initialize_achievements():
	achievements["first_discovery"] = {
		"name": "初探江湖",
		"description": "发现第一个兴趣点",
		"unlocked": false,
		"condition": {"type": "discover_count", "target": 1}
	}
	
	achievements["explorer_apprentice"] = {
		"name": "探索学徒",
		"description": "发现10个兴趣点",
		"unlocked": false,
		"condition": {"type": "discover_count", "target": 10}
	}
	
	achievements["seasoned_explorer"] = {
		"name": "资深探索者",
		"description": "发现50个兴趣点",
		"unlocked": false,
		"condition": {"type": "discover_count", "target": 50}
	}
	
	achievements["region_master"] = {
		"name": "区域大师",
		"description": "完全探索一个区域",
		"unlocked": false,
		"condition": {"type": "region_complete", "target": 1}
	}
	
	achievements["treasure_hunter"] = {
		"name": "寻宝猎人",
		"description": "发现10个宝箱",
		"unlocked": false,
		"condition": {"type": "poi_type_discover", "target": 10, "subtype": "treasure"}
	}

# Register a region with the exploration tracker
func register_region(region_id: String) -> bool:
	if not regions.has(region_id):
		regions[region_id] = RegionData.new(region_id)
		print("Registered region for exploration tracking: ", region_id)
		return true
	return false

# Add a point of interest to a region
func add_poi_to_region(region_id: String, poi_id: String, position: Vector2, poi_type: POI_TYPE, name: String, description: String) -> bool:
	if not regions.has(region_id):
		print("Region not registered: ", region_id)
		return false
	
	var region = regions[region_id]
	if region.pois.has(poi_id):
		print("POI already exists: ", poi_id)
		return false
	
	var poi = PointOfInterest.new(poi_id, position, poi_type, name, description, region_id)
	region.pois[poi_id] = poi
	region.total_poi_count += 1
	total_poi_count += 1
	
	print("Added POI to region ", region_id, ": ", name, " (", poi_id, ")")
	return true

# Discover a POI at a position
func discover_poi_at_position(player_position: Vector2, discovery_radius: float = 50.0) -> Array:
	var discovered = []
	var player_region_id = _get_region_id_at_position(player_position)
	
	if not regions.has(player_region_id):
		return discovered
	
	var region = regions[player_region_id]
	
	for poi_id in region.pois:
		var poi = region.pois[poi_id]
		
		# Check if POI is close enough and undiscovered
		if poi.status == POI_STATUS.UNDISCOVERED and \
		   player_position.distance_to(poi.position) <= discovery_radius:
			discover_poi(poi_id)
			discovered.append(poi_id)
	
	return discovered

# Discover a specific POI by ID
func discover_poi(poi_id: String) -> bool:
	var poi = _find_poi_by_id(poi_id)
	if not poi:
		return false
	
	if poi.status != POI_STATUS.UNDISCOVERED:
		return false  # Already discovered
	
	poi.status = POI_STATUS.DISCOVERED
	
	# Update region statistics
	var region = regions[poi.region_id]
	region.discovered_poi_count += 1
	region.explored_percentage = float(region.discovered_poi_count) / float(region.total_poi_count) * 100.0
	
	# Update overall statistics
	discovered_poi_count += 1
	overall_exploration_percentage = float(discovered_poi_count) / float(total_poi_count) * 100.0
	
	# Emit discovery signal
	emit_signal("poi_discovered", poi.id, POI_TYPE.keys()[poi.type])
	
	# Grant discovery reward
	_grant_discovery_reward(poi)
	
	# Check for achievements
	_check_achievements_after_discovery(poi)
	
	# Add to exploration history
	_add_to_history({
		"type": "discovery",
		"poi_id": poi.id,
		"poi_type": POI_TYPE.keys()[poi.type],
		"time": Time.get_ticks_msec(),
		"region": poi.region_id
	})
	
	print("Discovered POI: ", poi.name, " in region ", poi.region_id)
	emit_signal("exploration_progress_updated", poi.region_id, region.explored_percentage)
	
	return true

# Activate a POI (begin interaction)
func activate_poi(poi_id: String) -> bool:
	var poi = _find_poi_by_id(poi_id)
	if not poi or poi.status != POI_STATUS.DISCOVERED:
		return false
	
	poi.status = POI_STATUS.ACTIVATED
	return true

# Complete a POI (finish interaction)
func complete_poi(poi_id: String) -> bool:
	var poi = _find_poi_by_id(poi_id)
	if not poi or poi.status != POI_STATUS.ACTIVATED:
		return false
	
	poi.status = POI_STATUS.COMPLETED
	return true

# Get POI information
func get_poi_info(poi_id: String) -> Dictionary:
	var poi = _find_poi_by_id(poi_id)
	if not poi:
		return {}
	
	return {
		"id": poi.id,
		"name": poi.name,
		"description": poi.description,
		"type": POI_TYPE.keys()[poi.type],
		"status": POI_STATUS.keys()[poi.status],
		"position": poi.position,
		"region_id": poi.region_id
	}

# Get region exploration information
func get_region_exploration_info(region_id: String) -> Dictionary:
	if not regions.has(region_id):
		return {}
	
	var region = regions[region_id]
	return {
		"id": region.id,
		"total_poi_count": region.total_poi_count,
		"discovered_poi_count": region.discovered_poi_count,
		"explored_percentage": region.explored_percentage,
		"is_complete": region.explored_percentage >= 100.0
	}

# Get overall exploration statistics
func get_overall_exploration_stats() -> Dictionary:
	return {
		"total_poi_count": total_poi_count,
		"discovered_poi_count": discovered_poi_count,
		"overall_exploration_percentage": overall_exploration_percentage,
		"total_regions": regions.size()
	}

# Get all discovered POIs in a region
func get_discovered_pois_in_region(region_id: String) -> Array:
	if not regions.has(region_id):
		return []
	
	var discovered = []
	var region = regions[region_id]
	
	for poi_id in region.pois:
		var poi = region.pois[poi_id]
		if poi.status != POI_STATUS.UNDISCOVERED:
			discovered.append(poi_id)
	
	return discovered

# Get all POIs of a specific type
func get_pois_by_type(poi_type: POI_TYPE) -> Array:
	var result = []
	
	for region_id in regions:
		var region = regions[region_id]
		for poi_id in region.pois:
			var poi = region.pois[poi_id]
			if poi.type == poi_type:
				result.append(poi_id)
	
	return result

# Grant reward for POI discovery
func _grant_discovery_reward(poi: PointOfInterest):
	var reward_type = ""
	var reward_data = {}
	
	# Determine reward based on POI type
	match poi.type:
		POI_TYPE.RESOURCE_NODE:
			reward_type = "resource"
			reward_data = {"item": "material", "quantity": randi_range(1, 3)}
		POI_TYPE.QUEST_TARGET:
			reward_type = "exp"
			reward_data = {"amount": randi_range(10, 50)}
		POI_TYPE.SECRET_ENCOUNTER:
			reward_type = "treasure"
			reward_data = {"item": "rare_item", "quantity": 1}
		POI_TYPE.FACILITY:
			reward_type = "benefit"
			reward_data = {"type": "unlock", "effect": "fast_travel"}
	
	emit_signal("exploration_reward_granted", reward_type, reward_data)
	poi.reward_data = reward_data

# Check achievements after a discovery
func _check_achievements_after_discovery(poi: PointOfInterest):
	# Check discovery count achievements
	for achievement_id in achievements:
		var achievement = achievements[achievement_id]
		if achievement.unlocked:
			continue
		
		match achievement.condition.type:
			"discover_count":
				if discovered_poi_count >= achievement.condition.target:
					unlock_achievement(achievement_id)
			"poi_type_discover":
				if poi.type == POI_TYPE.RESOURCE_NODE and poi.name.to_lower().contains("treasure"):
					# Count treasure discoveries separately
					var treasure_count = _count_poi_type_discovered(POI_TYPE.RESOURCE_NODE, "treasure")
					if treasure_count >= achievement.condition.target:
						unlock_achievement(achievement_id)

# Count how many POIs of a specific type have been discovered
func _count_poi_type_discovered(poi_type: POI_TYPE, subtype: String = "") -> int:
	var count = 0
	
	for region_id in regions:
		var region = regions[region_id]
		for poi_id in region.pois:
			var poi = region.pois[poi_id]
			if poi.type == poi_type and poi.status != POI_STATUS.UNDISCOVERED:
				if subtype == "" or poi.name.to_lower().contains(subtype):
					count += 1
	
	return count

# Unlock an achievement
func unlock_achievement(achievement_id: String) -> bool:
	if not achievements.has(achievement_id) or achievements[achievement_id].unlocked:
		return false
	
	var achievement = achievements[achievement_id]
	achievement.unlocked = true
	
	emit_signal("achievement_unlocked", achievement_id, achievement.name)
	
	_add_to_history({
		"type": "achievement",
		"achievement_id": achievement_id,
		"achievement_name": achievement.name,
		"time": Time.get_ticks_msec()
	})
	
	print("Achievement unlocked: ", achievement.name)
	return true

# Find POI by ID across all regions
func _find_poi_by_id(poi_id: String) -> PointOfInterest:
	for region_id in regions:
		var region = regions[region_id]
		if region.pois.has(poi_id):
			return region.pois[poi_id]
	
	return null

# Get region ID at a position
func _get_region_id_at_position(pos: Vector2) -> String:
	# This is a simplified version - in practice, you'd use the same logic as in WorldStreamingManager
	var region_x = floor(pos.x / 2048)  # Assuming 2048 is the region size
	var region_y = floor(pos.y / 2048)
	return "region_%d_%d" % [region_x, region_y]

# Save exploration data
func save_exploration_data() -> Dictionary:
	var save_data = {
		"discovered_poi_count": discovered_poi_count,
		"total_poi_count": total_poi_count,
		"overall_exploration_percentage": overall_exploration_percentage,
		"exploration_history": exploration_history,
		"achievements": {}
	}
	
	# Save region data
	save_data.regions = {}
	for region_id in regions:
		var region = regions[region_id]
		var region_data = {
			"id": region.id,
			"total_poi_count": region.total_poi_count,
			"discovered_poi_count": region.discovered_poi_count,
			"explored_percentage": region.explored_percentage,
			"pois": {}
		}
		
		for poi_id in region.pois:
			var poi = region.pois[poi_id]
			region_data.pois[poi_id] = {
				"id": poi.id,
				"position": poi.position,
				"type": poi.type,
				"status": poi.status,
				"name": poi.name,
				"description": poi.description,
				"region_id": poi.region_id,
				"reward_data": poi.reward_data
			}
		
		save_data.regions[region_id] = region_data
	
	# Save achievements
	for achievement_id in achievements:
		var achievement = achievements[achievement_id]
		save_data.achievements[achievement_id] = {
			"name": achievement.name,
			"description": achievement.description,
			"unlocked": achievement.unlocked,
			"condition": achievement.condition
		}
	
	return save_data

# Load exploration data
func load_exploration_data(data: Dictionary):
	if data.has("discovered_poi_count"):
		discovered_poi_count = data.discovered_poi_count
	if data.has("total_poi_count"):
		total_poi_count = data.total_poi_count
	if data.has("overall_exploration_percentage"):
		overall_exploration_percentage = data.overall_exploration_percentage
	if data.has("exploration_history"):
		exploration_history = data.exploration_history
	
	# Load region data
	if data.has("regions"):
		for region_id in data.regions:
			var region_data = data.regions[region_id]
			
			# Create region if it doesn't exist
			if not regions.has(region_id):
				register_region(region_id)
			
			var region = regions[region_id]
			region.total_poi_count = region_data.total_poi_count
			region.discovered_poi_count = region_data.discovered_poi_count
			region.explored_percentage = region_data.explored_percentage
			
			# Load POIs for this region
			if region_data.has("pois"):
				for poi_id in region_data.pois:
					var poi_data = region_data.pois[poi_id]
					
					# Create POI if it doesn't exist
					if not region.pois.has(poi_id):
						var poi = PointOfInterest.new(
							poi_data.id,
							poi_data.position,
							poi_data.type,
							poi_data.name,
							poi_data.description,
							poi_data.region_id
						)
						poi.status = poi_data.status
						poi.reward_data = poi_data.reward_data
						region.pois[poi_id] = poi
					else:
						# Update existing POI
						var poi = region.pois[poi_id]
						poi.status = poi_data.status
						poi.reward_data = poi_data.reward_data
	
	# Load achievements
	if data.has("achievements"):
		for achievement_id in data.achievements:
			if achievements.has(achievement_id):
				var saved_data = data.achievements[achievement_id]
				var achievement = achievements[achievement_id]
				
				achievement.name = saved_data.name
				achievement.description = saved_data.description
				achievement.unlocked = saved_data.unlocked
				achievement.condition = saved_data.condition
				
				# If achievement was unlocked in save data but not in our system, unlock it
				if saved_data.unlocked and not achievement.unlocked:
					achievement.unlocked = true

# Add entry to exploration history
func _add_to_history(entry: Dictionary):
	exploration_history.append(entry)
	
	# Limit history size to prevent excessive memory usage
	if exploration_history.size() > 1000:
		exploration_history.pop_front()

# Get exploration history
func get_exploration_history() -> Array:
	return exploration_history.duplicate()

# Reset exploration data (for testing purposes)
func reset_exploration_data():
	regions.clear()
	discovered_poi_count = 0
	total_poi_count = 0
	overall_exploration_percentage = 0.0
	exploration_history.clear()
	
	# Reset achievements but keep their definitions
	for achievement_id in achievements:
		achievements[achievement_id].unlocked = false