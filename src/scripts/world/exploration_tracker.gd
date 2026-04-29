## ExplorationTracker
## 探索追踪器
## 
## 负责追踪玩家的探索进度、管理兴趣点发现和探索奖励。
## 
## 主要功能：
## - 追踪区域探索进度
## - 管理兴趣点（POI）的发现和激活
## - 发放探索奖励
## - 成就系统管理
## - 探索历史记录

extends Node

class_name ExplorationTracker

# ============================================================================
# 常量定义
# ============================================================================

## 区域大小（像素）
const REGION_SIZE: int = 2048

## 发现半径（像素）
const DISCOVERY_RADIUS: float = 50.0

## 历史记录最大条数
const MAX_HISTORY_SIZE: int = 1000

# ============================================================================
# 信号定义
# ============================================================================

## 探索进度更新信号
signal exploration_progress_updated(region_id: String, progress: float)

## 兴趣点发现信号
signal poi_discovered(poi_id: String, poi_type: String)

## 探索奖励发放信号
signal exploration_reward_granted(reward_type: String, reward_data: Dictionary)

## 成就解锁信号
signal achievement_unlocked(achievement_id: String, name: String)

## 兴趣点激活信号
signal poi_activated(poi_id: String)

## 兴趣点完成信号
signal poi_completed(poi_id: String)

# ============================================================================
# 成员变量
# ============================================================================

## 所有区域字典
var regions: Dictionary = {}

## 已发现兴趣点总数
var discovered_poi_count: int = 0

## 兴趣点总数
var total_poi_count: int = 0

## 总体探索百分比
var overall_exploration_percentage: float = 0.0

## 成就字典
var achievements: Dictionary = {}

## 探索历史记录
var exploration_history: Array = []

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化探索追踪器
func _ready() -> void:
	print("探索追踪器初始化完成")
	_initialize_achievements()

# ============================================================================
# 公共方法
# ============================================================================

## 注册区域
func register_region(region_id: String) -> bool:
	"""
	注册一个区域
	
	参数：
	- region_id: 区域ID
	
	返回：
	- 注册是否成功
	"""
	if not regions.has(region_id):
		regions[region_id] = RegionData.new(region_id)
		print("注册区域用于探索追踪: ", region_id)
		return true
	return false

## 添加兴趣点到区域
func add_poi_to_region(region_id: String, poi_id: String, position: Vector2, poi_type: int, name: String, description: String) -> bool:
	"""
	添加兴趣点到指定区域
	
	参数：
	- region_id: 区域ID
	- poi_id: 兴趣点ID
	- position: 兴趣点位置
	- poi_type: 兴趣点类型
	- name: 兴趣点名称
	- description: 兴趣点描述
	
	返回：
	- 添加是否成功
	"""
	if not regions.has(region_id):
		print("区域未注册: ", region_id)
		return false
	
	var region: RegionData = regions[region_id]
	if region.pois.has(poi_id):
		print("兴趣点已存在: ", poi_id)
		return false
	
	var poi: PointOfInterest = PointOfInterest.new(poi_id, position, poi_type, name, description, region_id)
	region.pois[poi_id] = poi
	region.total_poi_count += 1
	total_poi_count += 1
	
	print("添加兴趣点到区域 ", region_id, ": ", name, " (", poi_id, ")")
	return true

## 在指定位置发现兴趣点
func discover_poi_at_position(player_position: Vector2, discovery_radius: float = DISCOVERY_RADIUS) -> Array:
	"""
	在指定位置发现附近的兴趣点
	
	参数：
	- player_position: 玩家位置
	- discovery_radius: 发现半径
	
	返回：
	- 发现的兴趣点ID列表
	"""
	var discovered: Array = []
	var player_region_id: String = _get_region_id_at_position(player_position)
	
	if not regions.has(player_region_id):
		return discovered
	
	var region: RegionData = regions[player_region_id]
	
	for poi_id in region.pois:
		var poi: PointOfInterest = region.pois[poi_id]
		
		# 检查兴趣点是否足够接近且未被发现
		if poi.status == POIStatus.UNDISCOVERED and \
		   player_position.distance_to(poi.position) <= discovery_radius:
			discover_poi(poi_id)
			discovered.append(poi_id)
	
	return discovered

## 发现指定兴趣点
func discover_poi(poi_id: String) -> bool:
	"""
	发现指定的兴趣点
	
	参数：
	- poi_id: 兴趣点ID
	
	返回：
	- 发现是否成功
	"""
	var poi: PointOfInterest = _find_poi_by_id(poi_id)
	if not poi:
		return false
	
	if poi.status != POIStatus.UNDISCOVERED:
		return false
	
	poi.status = POIStatus.DISCOVERED
	
	# 更新区域统计
	var region: RegionData = regions[poi.region_id]
	region.discovered_poi_count += 1
	region.explored_percentage = float(region.discovered_poi_count) / float(region.total_poi_count) * 100.0
	
	# 更新总体统计
	discovered_poi_count += 1
	overall_exploration_percentage = float(discovered_poi_count) / float(total_poi_count) * 100.0
	
	# 发出发现信号
	poi_discovered.emit(poi.id, POIType.keys()[poi.type])
	
	# 发放发现奖励
	_grant_discovery_reward(poi)
	
	# 检查成就
	_check_achievements_after_discovery(poi)
	
	# 添加到历史记录
	_add_to_history({
		"type": "discovery",
		"poi_id": poi.id,
		"poi_type": POIType.keys()[poi.type],
		"time": Time.get_ticks_msec(),
		"region": poi.region_id
	})
	
	print("发现兴趣点: ", poi.name, " 在区域 ", poi.region_id)
	exploration_progress_updated.emit(poi.region_id, region.explored_percentage)
	
	return true

## 激活兴趣点
func activate_poi(poi_id: String) -> bool:
	"""
	激活指定兴趣点（开始交互）
	
	参数：
	- poi_id: 兴趣点ID
	
	返回：
	- 激活是否成功
	"""
	var poi: PointOfInterest = _find_poi_by_id(poi_id)
	if not poi or poi.status != POIStatus.DISCOVERED:
		return false
	
	poi.status = POIStatus.ACTIVATED
	poi_activated.emit(poi_id)
	return true

## 完成兴趣点
func complete_poi(poi_id: String) -> bool:
	"""
	完成指定兴趣点（结束交互）
	
	参数：
	- poi_id: 兴趣点ID
	
	返回：
	- 完成是否成功
	"""
	var poi: PointOfInterest = _find_poi_by_id(poi_id)
	if not poi or poi.status != POIStatus.ACTIVATED:
		return false
	
	poi.status = POIStatus.COMPLETED
	poi_completed.emit(poi_id)
	return true

## 获取兴趣点信息
func get_poi_info(poi_id: String) -> Dictionary:
	"""
	获取指定兴趣点的信息
	
	参数：
	- poi_id: 兴趣点ID
	
	返回：
	- 兴趣点信息字典
	"""
	var poi: PointOfInterest = _find_poi_by_id(poi_id)
	if not poi:
		return {}
	
	return {
		"id": poi.id,
		"name": poi.name,
		"description": poi.description,
		"type": POIType.keys()[poi.type],
		"status": POIStatus.keys()[poi.status],
		"position": poi.position,
		"region_id": poi.region_id
	}

## 获取区域探索信息
func get_region_exploration_info(region_id: String) -> Dictionary:
	"""
	获取指定区域的探索信息
	
	参数：
	- region_id: 区域ID
	
	返回：
	- 区域探索信息字典
	"""
	if not regions.has(region_id):
		return {}
	
	var region: RegionData = regions[region_id]
	return {
		"id": region.id,
		"total_poi_count": region.total_poi_count,
		"discovered_poi_count": region.discovered_poi_count,
		"explored_percentage": region.explored_percentage,
		"is_complete": region.explored_percentage >= 100.0
	}

## 获取总体探索统计
func get_overall_exploration_stats() -> Dictionary:
	"""
	获取总体探索统计信息
	
	返回：
	- 总体统计信息字典
	"""
	return {
		"total_poi_count": total_poi_count,
		"discovered_poi_count": discovered_poi_count,
		"overall_exploration_percentage": overall_exploration_percentage,
		"total_regions": regions.size()
	}

## 获取区域内所有已发现的兴趣点
func get_discovered_pois_in_region(region_id: String) -> Array:
	"""
	获取指定区域内所有已发现的兴趣点
	
	参数：
	- region_id: 区域ID
	
	返回：
	- 已发现兴趣点ID列表
	"""
	if not regions.has(region_id):
		return []
	
	var discovered: Array = []
	var region: RegionData = regions[region_id]
	
	for poi_id in region.pois:
		var poi: PointOfInterest = region.pois[poi_id]
		if poi.status != POIStatus.UNDISCOVERED:
			discovered.append(poi_id)
	
	return discovered

## 获取指定类型的所有兴趣点
func get_pois_by_type(poi_type: int) -> Array:
	"""
	获取指定类型的所有兴趣点
	
	参数：
	- poi_type: 兴趣点类型
	
	返回：
	- 兴趣点ID列表
	"""
	var result: Array = []
	
	for region_id in regions:
		var region: RegionData = regions[region_id]
		for poi_id in region.pois:
			var poi: PointOfInterest = region.pois[poi_id]
			if poi.type == poi_type:
				result.append(poi_id)
	
	return result

## 获取探索历史记录
func get_exploration_history() -> Array:
	"""
	获取探索历史记录
	
	返回：
	- 历史记录数组
	"""
	return exploration_history.duplicate()

## 重置探索数据
func reset_exploration_data() -> void:
	"""重置所有探索数据（用于测试）"""
	regions.clear()
	discovered_poi_count = 0
	total_poi_count = 0
	overall_exploration_percentage = 0.0
	exploration_history.clear()
	
	# 重置成就但保留定义
	for achievement_id in achievements:
		achievements[achievement_id].unlocked = false

## 保存探索数据
func save_exploration_data() -> Dictionary:
	"""
	保存探索数据
	
	返回：
	- 保存的数据字典
	"""
	var save_data: Dictionary = {
		"discovered_poi_count": discovered_poi_count,
		"total_poi_count": total_poi_count,
		"overall_exploration_percentage": overall_exploration_percentage,
		"exploration_history": exploration_history,
		"regions": {},
		"achievements": {}
	}
	
	# 保存区域数据
	for region_id in regions:
		var region: RegionData = regions[region_id]
		var region_data: Dictionary = {
			"id": region.id,
			"total_poi_count": region.total_poi_count,
			"discovered_poi_count": region.discovered_poi_count,
			"explored_percentage": region.explored_percentage,
			"pois": {}
		}
		
		for poi_id in region.pois:
			var poi: PointOfInterest = region.pois[poi_id]
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
	
	# 保存成就
	for achievement_id in achievements:
		var achievement: Dictionary = achievements[achievement_id]
		save_data.achievements[achievement_id] = {
			"name": achievement.name,
			"description": achievement.description,
			"unlocked": achievement.unlocked,
			"condition": achievement.condition
		}
	
	return save_data

## 加载探索数据
func load_exploration_data(data: Dictionary) -> void:
	"""
	加载探索数据
	
	参数：
	- data: 要加载的数据字典
	"""
	if data.has("discovered_poi_count"):
		discovered_poi_count = data.discovered_poi_count
	if data.has("total_poi_count"):
		total_poi_count = data.total_poi_count
	if data.has("overall_exploration_percentage"):
		overall_exploration_percentage = data.overall_exploration_percentage
	if data.has("exploration_history"):
		exploration_history = data.exploration_history
	
	# 加载区域数据
	if data.has("regions"):
		for region_id in data.regions:
			var region_data: Dictionary = data.regions[region_id]
			
			# 如果区域不存在则创建
			if not regions.has(region_id):
				register_region(region_id)
			
			var region: RegionData = regions[region_id]
			region.total_poi_count = region_data.total_poi_count
			region.discovered_poi_count = region_data.discovered_poi_count
			region.explored_percentage = region_data.explored_percentage
			
			# 加载该区域的兴趣点
			if region_data.has("pois"):
				for poi_id in region_data.pois:
					var poi_data: Dictionary = region_data.pois[poi_id]
					
					# 如果兴趣点不存在则创建
					if not region.pois.has(poi_id):
						var poi: PointOfInterest = PointOfInterest.new(
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
						# 更新现有兴趣点
						var poi: PointOfInterest = region.pois[poi_id]
						poi.status = poi_data.status
						poi.reward_data = poi_data.reward_data
	
	# 加载成就
	if data.has("achievements"):
		for achievement_id in data.achievements:
			if achievements.has(achievement_id):
				var saved_data: Dictionary = data.achievements[achievement_id]
				var achievement: Dictionary = achievements[achievement_id]
				
				achievement.name = saved_data.name
				achievement.description = saved_data.description
				achievement.unlocked = saved_data.unlocked
				achievement.condition = saved_data.condition

# ============================================================================
# 私有方法
# ============================================================================

## 兴趣点类型枚举
enum POIType {
	RESOURCE_NODE,
	QUEST_TARGET,
	SECRET_ENCOUNTER,
	FACILITY
}

## 兴趣点状态枚举
enum POIStatus {
	UNDISCOVERED,
	DISCOVERED,
	ACTIVATED,
	COMPLETED
}

## 兴趣点数据类
class PointOfInterest:
	## 兴趣点ID
	var id: String = ""
	
	## 兴趣点位置
	var position: Vector2 = Vector2.ZERO
	
	## 兴趣点类型
	var type: int = POIType.RESOURCE_NODE
	
	## 兴趣点状态
	var status: int = POIStatus.UNDISCOVERED
	
	## 兴趣点名称
	var name: String = ""
	
	## 兴趣点描述
	var description: String = ""
	
	## 奖励数据
	var reward_data: Dictionary = {}
	
	## 所属区域ID
	var region_id: String = ""
	
	## 初始化兴趣点
	func _init(p_id: String, p_position: Vector2, p_type: int, p_name: String, p_desc: String, p_region: String) -> void:
		id = p_id
		position = p_position
		type = p_type
		status = POIStatus.UNDISCOVERED
		name = p_name
		description = p_desc
		reward_data = {}
		region_id = p_region

## 区域数据类
class RegionData:
	## 区域ID
	var id: String = ""
	
	## 兴趣点总数
	var total_poi_count: int = 0
	
	## 已发现兴趣点数
	var discovered_poi_count: int = 0
	
	## 探索百分比
	var explored_percentage: float = 0.0
	
	## 兴趣点字典
	var pois: Dictionary = {}
	
	## 初始化区域数据
	func _init(p_id: String) -> void:
		id = p_id
		total_poi_count = 0
		discovered_poi_count = 0
		explored_percentage = 0.0
		pois = {}

## 初始化成就
func _initialize_achievements() -> void:
	"""初始化预定义的成就"""
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

## 发放发现奖励
func _grant_discovery_reward(poi: PointOfInterest) -> void:
	"""
	发放兴趣点发现奖励
	
	参数：
	- poi: 兴趣点数据
	"""
	var reward_type: String = ""
	var reward_data: Dictionary = {}
	
	# 根据兴趣点类型确定奖励
	match poi.type:
		POIType.RESOURCE_NODE:
			reward_type = "resource"
			reward_data = {"item": "material", "quantity": randi_range(1, 3)}
		POIType.QUEST_TARGET:
			reward_type = "exp"
			reward_data = {"amount": randi_range(10, 50)}
		POIType.SECRET_ENCOUNTER:
			reward_type = "treasure"
			reward_data = {"item": "rare_item", "quantity": 1}
		POIType.FACILITY:
			reward_type = "benefit"
			reward_data = {"type": "unlock", "effect": "fast_travel"}
	
	exploration_reward_granted.emit(reward_type, reward_data)
	poi.reward_data = reward_data

## 发现后检查成就
func _check_achievements_after_discovery(poi: PointOfInterest) -> void:
	"""
	发现兴趣点后检查成就
	
	参数：
	- poi: 发现的兴趣点
	"""
	# 检查发现数量成就
	for achievement_id in achievements:
		var achievement: Dictionary = achievements[achievement_id]
		if achievement.unlocked:
			continue
		
		match achievement.condition.type:
			"discover_count":
				if discovered_poi_count >= achievement.condition.target:
					unlock_achievement(achievement_id)
			"poi_type_discover":
				if poi.type == POIType.RESOURCE_NODE and poi.name.to_lower().contains("treasure"):
					var treasure_count: int = _count_poi_type_discovered(POIType.RESOURCE_NODE, "treasure")
					if treasure_count >= achievement.condition.target:
						unlock_achievement(achievement_id)

## 统计已发现的特定类型兴趣点
func _count_poi_type_discovered(poi_type: int, subtype: String = "") -> int:
	"""
	统计已发现的特定类型兴趣点数量
	
	参数：
	- poi_type: 兴趣点类型
	- subtype: 子类型
	
	返回：
	- 已发现的兴趣点数量
	"""
	var count: int = 0
	
	for region_id in regions:
		var region: RegionData = regions[region_id]
		for poi_id in region.pois:
			var poi: PointOfInterest = region.pois[poi_id]
			if poi.type == poi_type and poi.status != POIStatus.UNDISCOVERED:
				if subtype == "" or poi.name.to_lower().contains(subtype):
					count += 1
	
	return count

## 解锁成就
func unlock_achievement(achievement_id: String) -> bool:
	"""
	解锁指定成就
	
	参数：
	- achievement_id: 成就ID
	
	返回：
	- 解锁是否成功
	"""
	if not achievements.has(achievement_id) or achievements[achievement_id].unlocked:
		return false
	
	var achievement: Dictionary = achievements[achievement_id]
	achievement.unlocked = true
	
	achievement_unlocked.emit(achievement_id, achievement.name)
	
	_add_to_history({
		"type": "achievement",
		"achievement_id": achievement_id,
		"achievement_name": achievement.name,
		"time": Time.get_ticks_msec()
	})
	
	print("成就解锁: ", achievement.name)
	return true

## 根据ID查找兴趣点
func _find_poi_by_id(poi_id: String) -> PointOfInterest:
	"""
	根据ID查找兴趣点
	
	参数：
	- poi_id: 兴趣点ID
	
	返回：
	- 兴趣点数据或null
	"""
	for region_id in regions:
		var region: RegionData = regions[region_id]
		if region.pois.has(poi_id):
			return region.pois[poi_id]
	
	return null

## 获取位置所在的区域ID
func _get_region_id_at_position(pos: Vector2) -> String:
	"""
	获取指定位置所在的区域ID
	
	参数：
	- pos: 位置坐标
	
	返回：
	- 区域ID
	"""
	var region_x: int = int(floor(pos.x / REGION_SIZE))
	var region_y: int = int(floor(pos.y / REGION_SIZE))
	return "region_%d_%d" % [region_x, region_y]

## 添加条目到历史记录
func _add_to_history(entry: Dictionary) -> void:
	"""
	添加条目到探索历史记录
	
	参数：
	- entry: 历史记录条目
	"""
	exploration_history.append(entry)
	
	# 限制历史记录大小以防止过度内存使用
	if exploration_history.size() > MAX_HISTORY_SIZE:
		exploration_history.pop_front()