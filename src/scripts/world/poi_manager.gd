## PoiManager
## 兴趣点管理器
管理游戏中所有的兴趣点（POI）及其状态
##
## 主要功能：
## - 待补充

extends Node

class_name PoiManager

# ============================================================================
# 常量定义
# ============================================================================

# ============================================================================
# 信号定义
# ============================================================================

# ============================================================================
# 成员变量
# ============================================================================

# ============================================================================
# 生命周期方法
# ============================================================================

# ============================================================================
# 公共方法
# ============================================================================

# ============================================================================
# 私有方法
# ============================================================================

# 信号定义
signal poi_discovered(poi_id: String)
signal poi_revealed_by_perception(poi_id: String)  # 通过感知技能发现
signal poi_status_changed(poi_id: String, old_status: String, new_status: String)

# 兴趣点类型枚举
enum POI_TYPE {
	RESOURCE_NODE,      # 资源采集点
	QUEST_TARGET,       # 任务目标
	SECRET_ENCOUNTER,   # 奇遇/隐藏点
	FACILITY            # 功能设施
}

# 兴趣点状态枚举
enum POI_STATUS {
	UNDISCOVERED,       # 未发现
	DISCOVERED,         # 已发现
	ACTIVATED,          # 已激活
	COMPLETED          # 已完成
}

# 兴趣点数据结构
class POI:
	var id: String
	var position: Vector2
	var type: POI_TYPE
	var status: POI_STATUS
	var name: String
	var description: String
	var is_hidden: bool  # 是否为隐藏点（需要特殊技能才能发现）
	var discovery_radius: float  # 发现半径
	var perception_required: int  # 需要的感知属性才能发现（仅对隐藏点有效）
	
	func _init(p_id: String, p_position: Vector2, p_type: POI_TYPE, p_name: String, p_description: String, p_is_hidden: bool = false, p_discovery_radius: float = 50.0, p_perception_required: int = 0):
		id = p_id
		position = p_position
		type = p_type
		status = POI_STATUS.UNDISCOVERED
		name = p_name
		description = p_description
		is_hidden = p_is_hidden
		discovery_radius = p_discovery_radius
		perception_required = p_perception_required

# 兴趣点字典 (ID -> POI)
var pois: Dictionary = {}

# 玩家相关信息
var player_node: Node2D = null
var player_perception: int = 50  # 玩家当前感知属性

# 天眼通技能相关
var perception_skill_cooldown: float = 0.0
var perception_skill_max_cooldown: float = 10.0  # 10秒冷却
var perception_skill_range: float = 120.0  # 技能范围

# 初始化
func _ready():
	print("POI Manager initialized")

# 设置玩家节点
func set_player_node(player: Node2D):
	player_node = player

# 设置玩家感知属性
func set_player_perception(perception_value: int):
	player_perception = perception_value

# 注册一个新的兴趣点
func register_poi(poi_id: String, position: Vector2, type: POI_TYPE, name: String, description: String, is_hidden: bool = false, discovery_radius: float = 50.0, perception_required: int = 0) -> bool:
	if pois.has(poi_id):
		print("POI ID already exists: ", poi_id)
		return false
	
	var new_poi = POI.new(poi_id, position, type, name, description, is_hidden, discovery_radius, perception_required)
	pois[poi_id] = new_poi
	print("Registered POI: ", poi_id, " at position ", position)
	return true

# 获取兴趣点信息
func get_poi_info(poi_id: String) -> Dictionary:
	if not pois.has(poi_id):
		return {}
	
	var poi = pois[poi_id]
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

# 检查玩家附近是否有可发现的兴趣点
func check_nearby_pois():
	if not player_node:
		return
	
	var player_pos = player_node.global_position
	
	for poi_id in pois:
		var poi = pois[poi_id]
		
		# 只处理未发现的兴趣点
		if poi.status != POI_STATUS.UNDISCOVERED:
			continue
		
		# 计算距离
		var distance = player_pos.distance_to(poi.position)
		
		# 检查是否在发现范围内
		if distance <= poi.discovery_radius:
			# 对于隐藏点，需要检查感知属性
			if poi.is_hidden and player_perception < poi.perception_required:
				continue  # 感知不够，无法发现
			
			# 发现兴趣点
			_set_poi_status(poi_id, POI_STATUS.DISCOVERED)
			emit_signal("poi_discovered", poi_id)
			print("Discovered POI: ", poi.name)

# 使用天眼通技能探测隐藏兴趣点
func use_perception_skill():
	if perception_skill_cooldown > 0:
		print("Perception skill is on cooldown")
		return false
	
	# 检查玩家位置
	if not player_node:
		return false
	
	var player_pos = player_node.global_position
	
	# 遍历所有隐藏且未发现的兴趣点
	for poi_id in pois:
		var poi = pois[poi_id]
		
		# 只处理隐藏的未发现兴趣点
		if not poi.is_hidden or poi.status != POI_STATUS.UNDISCOVERED:
			continue
		
		# 检查是否在技能范围内
		var distance = player_pos.distance_to(poi.position)
		if distance <= perception_skill_range:
			# 发现兴趣点
			_set_poi_status(poi_id, POI_STATUS.DISCOVERED)
			emit_signal("poi_revealed_by_perception", poi_id)
			print("Revealed hidden POI with perception skill: ", poi.name)
	
	# 设置冷却
	perception_skill_cooldown = perception_skill_max_cooldown
	print("Used perception skill, cooldown started")
	return true

# 更新技能冷却
func _process(delta):
	# 更新技能冷却
	if perception_skill_cooldown > 0:
		perception_skill_cooldown = max(0, perception_skill_cooldown - delta)

# 设置兴趣点状态
func _set_poi_status(poi_id: String, new_status: POI_STATUS):
	if not pois.has(poi_id):
		return
	
	var poi = pois[poi_id]
	var old_status = poi.status
	
	if old_status == new_status:
		return  # 状态未改变
	
	poi.status = new_status
	emit_signal("poi_status_changed", poi_id, POI_STATUS.keys()[old_status], POI_STATUS.keys()[new_status])
	print("POI status changed: ", poi.name, " from ", POI_STATUS.keys()[old_status], " to ", POI_STATUS.keys()[new_status])

# 激活兴趣点（开始互动）
func activate_poi(poi_id: String) -> bool:
	if not pois.has(poi_id):
		return false
	
	var poi = pois[poi_id]
	if poi.status != POI_STATUS.DISCOVERED:
		return false  # 只能激活已发现的兴趣点
	
	_set_poi_status(poi_id, POI_STATUS.ACTIVATED)
	return true

# 完成兴趣点（结束互动）
func complete_poi(poi_id: String) -> bool:
	if not pois.has(poi_id):
		return false
	
	var poi = pois[poi_id]
	if poi.status != POI_STATUS.ACTIVATED:
		return false  # 只能完成已激活的兴趣点
	
	_set_poi_status(poi_id, POI_STATUS.COMPLETED)
	return true

# 获取指定状态的兴趣点列表
func get_pois_with_status(status: POI_STATUS) -> Array:
	var result = []
	for poi_id in pois:
		if pois[poi_id].status == status:
			result.append(poi_id)
	return result

# 获取指定类型的兴趣点列表
func get_pois_of_type(type: POI_TYPE) -> Array:
	var result = []
	for poi_id in pois:
		if pois[poi_id].type == type:
			result.append(poi_id)
	return result

# 获取玩家附近的所有兴趣点
func get_nearby_pois(max_distance: float = 200.0) -> Array:
	if not player_node:
		return []
	
	var result = []
	var player_pos = player_node.global_position
	
	for poi_id in pois:
		var poi = pois[poi_id]
		var distance = player_pos.distance_to(poi.position)
		
		if distance <= max_distance:
			result.append({
				"poi_id": poi_id,
				"distance": distance,
				"direction": (poi.position - player_pos).normalized(),
				"status": poi.status,
				"type": poi.type
			})
	
	# 按距离排序
	result.sort_custom(func(a, b): return a.distance < b.distance)
	return result

# 获取当前技能冷却时间
func get_perception_skill_cooldown() -> float:
	return perception_skill_cooldown

# 获取技能最大冷却时间
func get_perception_skill_max_cooldown() -> float:
	return perception_skill_max_cooldown

# 获取技能范围
func get_perception_skill_range() -> float:
	return perception_skill_range

# 保存POI数据
func save_poi_data() -> Dictionary:
	var save_data = {}
	
	for poi_id in pois:
		var poi = pois[poi_id]
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

# 加载POI数据
func load_poi_data(data: Dictionary):
	for poi_id in data:
		if pois.has(poi_id):
			# 如果POI已存在，更新其状态
			var poi_data = data[poi_id]
			pois[poi_id].status = poi_data.status
		else:
			# 如果POI不存在，创建新的
			var poi_data = data[poi_id]
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