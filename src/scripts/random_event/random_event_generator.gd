# 随机事件生成器
# 基于区域的权重池算法实现，支持4类事件

extends Node

class_name RandomEventGenerator

# 基于区域的权重池算法实现
# 支持4类事件：战斗遭遇、奇遇/叙事事件、资源/宝藏事件、环境/状态事件

# 事件类型枚举
enum EventType {
	COMBAT_ENCOUNTER,      # 战斗遭遇
	ENCOUNTER_NARRATIVE,   # 奇遇/叙事事件
	RESOURCE_TREASURE,     # 资源/宝藏事件
	ENVIRONMENTAL_STATUS   # 环境/状态事件
}

# 事件结构体
class EventData:
	var event_id: String
	var event_type: EventType
	var base_weight: int
	var description: String
	var region_specific: bool

# 区域事件池
var region_event_pools: Dictionary = {}

# 伪随机数生成器
var seeded_random: RandomNumberGenerator

func _init():
	seeded_random = RandomNumberGenerator.new()
	# 初始化默认事件池
	_initialize_default_events()

# 初始化默认事件
func _initialize_default_events():
	# 示例：新手村区域事件池
	var village_pool: Array[EventData] = []
	
	# 添加战斗遭遇事件
	var combat_event = EventData.new()
	combat_event.event_id = "combat_001"
	combat_event.event_type = EventType.COMBAT_ENCOUNTER
	combat_event.base_weight = 20
	combat_event.description = "野兽袭击"
	combat_event.region_specific = true
	village_pool.append(combat_event)
	
	# 添加奇遇/叙事事件
	var narrative_event = EventData.new()
	narrative_event.event_id = "narrative_001"
	narrative_event.event_type = EventType.ENCOUNTER_NARRATIVE
	narrative_event.base_weight = 30
	narrative_event.description = "迷路的孩子"
	narrative_event.region_specific = true
	village_pool.append(narrative_event)
	
	# 添加资源/宝藏事件
	var treasure_event = EventData.new()
	treasure_event.event_id = "treasure_001"
	treasure_event.event_type = EventType.RESOURCE_TREASURE
	treasure_event.base_weight = 25
	treasure_event.description = "路边包裹"
	treasure_event.region_specific = true
	village_pool.append(treasure_event)
	
	# 添加环境/状态事件
	var env_event = EventData.new()
	env_event.event_id = "env_001"
	env_event.event_type = EventType.ENVIRONMENTAL_STATUS
	env_event.base_weight = 15
	env_event.description = "天气变化"
	env_event.region_specific = true
	village_pool.append(env_event)
	
	region_event_pools["village"] = village_pool

# 设置区域事件池
func set_region_event_pool(region_id: String, events: Array[EventData]):
	region_event_pools[region_id] = events

# 获取区域事件池
func get_region_event_pool(region_id: String) -> Array[EventData]:
	if region_event_pools.has(region_id):
		return region_event_pools[region_id]
	else:
		print("警告: 区域 ", region_id, " 没有定义事件池，使用默认池")
		return region_event_pools.get("village", [])

# 生成伪随机种子
# 种子 = (区域ID × 1000000) + (日期 × 1000) + 玩家ID
func generate_seed(region_id: String, date_value: int, player_id: int) -> int:
	var region_hash = hash(region_id) % 1000  # 限制区域ID部分在合理范围内
	# 确保日期值在1-365范围内
	var normalized_date = ((date_value - 1) % 365) + 1
	# 确保玩家ID在1-999范围内
	var normalized_player_id = ((player_id - 1) % 999) + 1
	
	var seed_value = (region_hash * 1000000) + (normalized_date * 1000) + normalized_player_id
	return seed_value

# 根据玩家福缘属性和区域特性调整事件权重
# 最终权重 = 基础权重 × (1 + (福缘属性 × 福缘系数)) × 区域倍数
func calculate_weight_with_modifiers(base_weight: int, luck_stat: int, luck_coefficient: float = 0.02, zone_multiplier: float = 1.0) -> float:
	var luck_modifier = 1.0 + (luck_stat * luck_coefficient)
	var final_weight = base_weight * luck_modifier * zone_multiplier
	# 确保权重不小于0.5
	return max(0.5, final_weight)

# 实现事件冷却机制，防止相同类型事件连续触发
var last_event_types: Dictionary = {}  # 存储每个玩家最后触发的事件类型
var cooldown_time: float = 300.0  # 5分钟冷却时间（以秒为单位）
var last_event_times: Dictionary = {}  # 存储事件触发时间

# 检查事件是否在冷却中
func is_event_type_on_cooldown(player_id: String, event_type: EventType) -> bool:
	var current_time = Time.get_unix_time_from_system()
	
	if last_event_types.has(player_id) and last_event_times.has(player_id):
		var last_type = last_event_types[player_id]
		var last_time = last_event_times[player_id]
		
		# 检查是否是相同类型的事件且在冷却时间内
		if last_type == event_type and (current_time - last_time) < cooldown_time:
			return true
	
	return false

# 更新最后触发的事件类型和时间
func update_last_event(player_id: String, event_type: EventType):
	var current_time = Time.get_unix_time_from_system()
	last_event_types[player_id] = event_type
	last_event_times[player_id] = current_time

# 生成随机事件
# 参数:
# - region_id: 当前区域ID
# - player_id: 玩家ID
# - luck_stat: 玩家福缘属性
# - zone_multiplier: 区域倍数
# - date_value: 当前日期值（一年中的第几天）
func generate_random_event(region_id: String, player_id: String, luck_stat: int = 0, zone_multiplier: float = 1.0, date_value: int = -1) -> EventData:
	if date_value == -1:
		# 如果没有提供日期值，则使用系统当前日期
		var current_date = Time.get_date_dict_from_system()
		# 计算一年中的第几天
		date_value = _day_of_year(current_date.year, current_date.month, current_date.day)
	
	# 生成种子并设置随机数生成器
	var seed = generate_seed(region_id, date_value, hash(player_id) % 999 + 1)
	seeded_random.seed = seed
	
	# 获取区域事件池
	var event_pool = get_region_event_pool(region_id)
	if event_pool.is_empty():
		print("错误: 区域 ", region_id, " 没有可用的事件")
		return null
	
	# 应用权重调整并过滤冷却中的事件
	var weighted_events = []
	for event in event_pool:
		# 检查事件类型是否在冷却中
		if is_event_type_on_cooldown(player_id, event.event_type):
			continue  # 跳过冷却中的事件类型
		
		var adjusted_weight = calculate_weight_with_modifiers(event.base_weight, luck_stat, 0.02, zone_multiplier)
		weighted_events.append({"event": event, "weight": adjusted_weight})
	
	if weighted_events.is_empty():
		print("警告: 所有事件都在冷却中，返回第一个可用事件")
		# 如果所有事件都在冷却中，返回第一个事件而不考虑冷却
		return event_pool[0]
	
	# 使用加权随机选择算法选择事件
	var total_weight = 0.0
	for item in weighted_events:
		total_weight += item.weight
	
	if total_weight <= 0:
		print("错误: 总权重小于等于0")
		return null
	
	# 生成0到total_weight之间的随机数
	var random_value = seeded_random.randf_range(0, total_weight)
	
	# 找到对应的事件
	var current_weight = 0.0
	for item in weighted_events:
		current_weight += item.weight
		if random_value <= current_weight:
			var selected_event = item.event
			# 更新最后触发的事件类型和时间
			update_last_event(player_id, selected_event.event_type)
			return selected_event
	
	# 如果由于浮点精度问题没有选中事件，返回最后一个事件
	var last_event = weighted_events[-1].event
	update_last_event(player_id, last_event.event_type)
	return last_event

# 计算一年中的第几天
func _day_of_year(year: int, month: int, day: int) -> int:
	var days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	
	# 检查闰年
	if ((year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)):
		days_in_month[1] = 29
	
	var day_of_year = 0
	for i in range(month - 1):
		day_of_year += days_in_month[i]
	day_of_year += day
	
	return day_of_year