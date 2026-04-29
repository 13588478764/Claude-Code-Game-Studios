## PoiManager
## 兴趣点管理器
## 
## 负责管理游戏中所有的兴趣点（POI）及其状态、发现和交互。
## 
## 主要功能：
## - 注册和管理兴趣点
## - 处理兴趣点的发现和激活
## - 管理感知技能和隐藏兴趣点
## - 追踪兴趣点状态变化
## - 保存和加载兴趣点数据

extends Node

class_name PoiManager

# ============================================================================
# 常量定义
# ============================================================================

## 感知技能冷却时间（秒）
const PERCEPTION_SKILL_MAX_COOLDOWN: float = 10.0

## 感知技能范围（像素）
const PERCEPTION_SKILL_RANGE: float = 120.0

## 默认发现半径（像素）
const DEFAULT_DISCOVERY_RADIUS: float = 50.0

## 默认感知属性要求
const DEFAULT_PERCEPTION_REQUIRED: int = 0

## 附近兴趣点最大距离（像素）
const NEARBY_POI_MAX_DISTANCE: float = 200.0

# ============================================================================
# 信号定义
# ============================================================================

## 兴趣点发现信号
signal poi_discovered(poi_id: String)

## 兴趣点通过感知技能发现信号
signal poi_revealed_by_perception(poi_id: String)

## 兴趣点状态变化信号
signal poi_status_changed(poi_id: String, old_status: String, new_status: String)

## 兴趣点激活信号
signal poi_activated(poi_id: String)

## 兴趣点完成信号
signal poi_completed(poi_id: String)

## 感知技能使用信号
signal perception_skill_used()

## 感知技能冷却完成信号
signal perception_skill_ready()

# ============================================================================
# 成员变量
# ============================================================================

## 所有兴趣点字典
var pois: Dictionary = {}

## 玩家节点引用
var player_node: Node2D = null

## 玩家感知属性值
var player_perception: int = 50

## 感知技能冷却时间
var perception_skill_cooldown: float = 0.0

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化兴趣点管理器
func _ready() -> void:
	print("兴趣点管理器初始化完成")

## 物理处理
func _process(delta: float) -> void:
	# 更新感知技能冷却
	if perception_skill_cooldown > 0:
		perception_skill_cooldown = max(0, perception_skill_cooldown - delta)
		if perception_skill_cooldown == 0:
			perception_skill_ready.emit()

# ============================================================================
# 公共方法
# ============================================================================

## 设置玩家节点
func set_player_node(player: Node2D) -> void:
	"""
	设置玩家节点
	
	参数：
	- player: 玩家节点
	"""
	player_node = player

## 设置玩家感知属性
func set_player_perception(perception_value: int) -> void:
	"""
	设置玩家感知属性
	
	参数：
	- perception_value: 感知属性值
	"""
	player_perception = perception_value

## 注册兴趣点
func register_poi(poi_id: String, position: Vector2, type: int, name: String, description: String, is_hidden: bool = false, discovery_radius: float = DEFAULT_DISCOVERY_RADIUS, perception_required: int = DEFAULT_PERCEPTION_REQUIRED) -> bool:
	"""
	注册一个新的兴趣点
	
	参数：
	- poi_id: 兴趣点ID
	- position: 兴趣点位置
	- type: 兴趣点类型
	- name: 兴趣点名称
	- description: 兴趣点描述
	- is_hidden: 是否为隐藏点
	- discovery_radius: 发现半径
	- perception_required: 所需感知属性
	
	返回：
	- 注册是否成功
	"""
	if pois.has(poi_id):
		print("兴趣点ID已存在: ", poi_id)
		return false
	
	var new_poi: POI = POI.new(poi_id, position, type, name, description, is_hidden, discovery_radius, perception_required)
	pois[poi_id] = new_poi
	print("注册兴趣点: ", poi_id, " 位置 ", position)
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
	if not pois.has(poi_id):
		return {}
	
	var poi: POI = pois[poi_id]
	return {
		"id": poi.id,
		"position": poi.position,
		"type": poi.type,
		"status": poi.status,
		"name": poi.name,
		"description": poi.description,
		"is_hidden": poi.is_hidden,
		"discovery_radius": poi.discovery_radius,
		"perception_required": poi.perception_required
	}

## 检查玩家附近的兴趣点
func check_nearby_pois() -> void:
	"""检查玩家附近是否有可发现的兴趣点"""
	if not player_node:
		return
	
	var player_pos: Vector2 = player_node.global_position
	
	for poi_id in pois:
		var poi: POI = pois[poi_id]
		
		# 只处理未发现的兴趣点
		if poi.status != POIStatus.UNDISCOVERED:
			continue
		
		# 计算距离
		var distance: float = player_pos.distance_to(poi.position)
		
		# 检查是否在发现范围内
		if distance <= poi.discovery_radius:
			# 对于隐藏点，需要检查感知属性
			if poi.is_hidden and player_perception < poi.perception_required:
				continue
			
			# 发现兴趣点
			_set_poi_status(poi_id, POIStatus.DISCOVERED)
			poi_discovered.emit(poi_id)
			print("发现兴趣点: ", poi.name)

## 使用感知技能
func use_perception_skill() -> bool:
	"""
	使用感知技能探测隐藏兴趣点
	
	返回：
	- 技能是否成功使用
	"""
	if perception_skill_cooldown > 0:
		print("感知技能冷却中")
		return false
	
	if not player_node:
		return false
	
	var player_pos: Vector2 = player_node.global_position
	var revealed_count: int = 0
	
	# 遍历所有隐藏且未发现的兴趣点
	for poi_id in pois:
		var poi: POI = pois[poi_id]
		
		# 只处理隐藏的未发现兴趣点
		if not poi.is_hidden or poi.status != POIStatus.UNDISCOVERED:
			continue
		
		# 检查是否在技能范围内
		var distance: float = player_pos.distance_to(poi.position)
		if distance <= PERCEPTION_SKILL_RANGE:
			# 发现兴趣点
			_set_poi_status(poi_id, POIStatus.DISCOVERED)
			poi_revealed_by_perception.emit(poi_id)
			revealed_count += 1
			print("通过感知技能发现隐藏兴趣点: ", poi.name)
	
	# 设置冷却
	perception_skill_cooldown = PERCEPTION_SKILL_MAX_COOLDOWN
	perception_skill_used.emit()
	print("使用感知技能，冷却已启动")
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
	if not pois.has(poi_id):
		return false
	
	var poi: POI = pois[poi_id]
	if poi.status != POIStatus.DISCOVERED:
		return false
	
	_set_poi_status(poi_id, POIStatus.ACTIVATED)
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
	if not pois.has(poi_id):
		return false
	
	var poi: POI = pois[poi_id]
	if poi.status != POIStatus.ACTIVATED:
		return false
	
	_set_poi_status(poi_id, POIStatus.COMPLETED)
	poi_completed.emit(poi_id)
	return true

## 获取指定状态的兴趣点列表
func get_pois_with_status(status: int) -> Array:
	"""
	获取指定状态的所有兴趣点
	
	参数：
	- status: 兴趣点状态
	
	返回：
	- 兴趣点ID列表
	"""
	var result: Array = []
	for poi_id in pois:
		if pois[poi_id].status == status:
			result.append(poi_id)
	return result

## 获取指定类型的兴趣点列表
func get_pois_of_type(type: int) -> Array:
	"""
	获取指定类型的所有兴趣点
	
	参数：
	- type: 兴趣点类型
	
	返回：
	- 兴趣点ID列表
	"""
	var result: Array = []
	for poi_id in pois:
		if pois[poi_id].type == type:
			result.append(poi_id)
	return result

## 获取玩家附近的兴趣点
func get_nearby_pois(max_distance: float = NEARBY_POI_MAX_DISTANCE) -> Array:
	"""
	获取玩家附近的所有兴趣点
	
	参数：
	- max_distance: 最大距离
	
	返回：
	- 附近兴趣点信息列表
	"""
	if not player_node:
		return []
	
	var result: Array = []
	var player_pos: Vector2 = player_node.global_position
	
	for poi_id in pois:
		var poi: POI = pois[poi_id]
		var distance: float = player_pos.distance_to(poi.position)
		
		if distance <= max_distance:
			result.append({
				"poi_id": poi_id,
				"distance": distance,
				"direction": (poi.position - player_pos).normalized(),
				"status": poi.status,
				"type": poi.type,
				"name": poi.name
			})
	
	# 按距离排序
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)
	return result

## 获取感知技能冷却时间
func get_perception_skill_cooldown() -> float:
	"""
	获取感知技能当前冷却时间
	
	返回：
	- 冷却时间（秒）
	"""
	return perception_skill_cooldown

## 获取感知技能最大冷却时间
func get_perception_skill_max_cooldown() -> float:
	"""
	获取感知技能最大冷却时间
	
	返回：
	- 最大冷却时间（秒）
	"""
	return PERCEPTION_SKILL_MAX_COOLDOWN

## 获取感知技能范围
func get_perception_skill_range() -> float:
	"""
	获取感知技能范围
	
	返回：
	- 技能范围（像素）
	"""
	return PERCEPTION_SKILL_RANGE

## 保存兴趣点数据
func save_poi_data() -> Dictionary:
	"""
	保存所有兴趣点数据
	
	返回：
	- 保存的数据字典
	"""
	var save_data: Dictionary = {}
	
	for poi_id in pois:
		var poi: POI = pois[poi_id]
		save_data[poi_id] = {
			"status": poi.status,
			"type": poi.type,
			"position": poi.position,
			"name": poi.name,
			"description": poi.description,
			"is_hidden": poi.is_hidden,
			"discovery_radius": poi.discovery_radius,
			"perception_required": poi.perception_required
		}
	
	return save_data

## 加载兴趣点数据
func load_poi_data(data: Dictionary) -> void:
	"""
	加载兴趣点数据
	
	参数：
	- data: 要加载的数据字典
	"""
	for poi_id in data:
		if pois.has(poi_id):
			# 如果兴趣点已存在，更新其状态
			var poi_data: Dictionary = data[poi_id]
			pois[poi_id].status = poi_data.status
		else:
			# 如果兴趣点不存在，创建新的
			var poi_data: Dictionary = data[poi_id]
			register_poi(
				poi_id,
				poi_data.position,
				poi_data.type,
				poi_data.name,
				poi_data.description,
				poi_data.is_hidden,
				poi_data.discovery_radius,
				poi_data.perception_required
			)
			# 设置加载的状态
			pois[poi_id].status = poi_data.status

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
class POI:
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
	
	## 是否为隐藏点
	var is_hidden: bool = false
	
	## 发现半径
	var discovery_radius: float = 50.0
	
	## 所需感知属性
	var perception_required: int = 0
	
	## 初始化兴趣点
	func _init(p_id: String, p_position: Vector2, p_type: int, p_name: String, p_description: String, p_is_hidden: bool = false, p_discovery_radius: float = 50.0, p_perception_required: int = 0) -> void:
		id = p_id
		position = p_position
		type = p_type
		status = POIStatus.UNDISCOVERED
		name = p_name
		description = p_description
		is_hidden = p_is_hidden
		discovery_radius = p_discovery_radius
		perception_required = p_perception_required

## 设置兴趣点状态
func _set_poi_status(poi_id: String, new_status: int) -> void:
	"""
	设置兴趣点状态
	
	参数：
	- poi_id: 兴趣点ID
	- new_status: 新状态
	"""
	if not pois.has(poi_id):
		return
	
	var poi: POI = pois[poi_id]
	var old_status: int = poi.status
	
	if old_status == new_status:
		return
	
	poi.status = new_status
	poi_status_changed.emit(poi_id, POIStatus.keys()[old_status], POIStatus.keys()[new_status])
	print("兴趣点状态变化: ", poi.name, " 从 ", POIStatus.keys()[old_status], " 到 ", POIStatus.keys()[new_status])