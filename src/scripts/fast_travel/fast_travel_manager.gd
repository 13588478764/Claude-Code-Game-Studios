# 快速旅行管理器
# 实现快速旅行功能，包括传送点交互、旅行成本计算、时间消耗和状态管理

extends Node

class_name FastTravelManager

# 信号定义
signal travel_started(destination: String, cost: int, travel_time: int)
signal travel_completed(destination: String)
signal travel_failed(reason: String)
signal travel_cost_calculated(cost: int)

# 常量定义
const BASE_TRAVEL_COST = 10  # 基础旅行费用
const DISTANCE_COST_MULTIPLIER = 100  # 距离成本乘数
const SAME_REGION_MULTIPLIER = 0.5  # 同区域旅行费用折扣
const MAX_TRAVEL_COST = 1000  # 最大旅行费用

# 旅行状态枚举
enum TravelState { IDLE, CALCULATING, TRAVELING, COMPLETED, FAILED }

# 当前旅行状态
var current_state: TravelState = TravelState.IDLE

# 世界节点数据结构
class WorldNode:
	var id: String
	var name: String
	var region: String
	var is_unlocked: bool
	var is_discovered: bool
	var position: Vector2
	
	func _init(p_id: String, p_name: String, p_region: String, p_pos: Vector2):
		id = p_id
		name = p_name
		region = p_region
		is_unlocked = false
		is_discovered = false
		position = p_pos

# 存储世界节点
var world_nodes: Dictionary = {}

# 当前玩家位置
var current_location: String = ""

# 初始化世界节点
func _ready():
	# 添加示例世界节点
	add_world_node("qingyun_mountain", "青云山", "青州", Vector2(0, 0))
	add_world_node("jiangnan_town", "江南水乡", "江南", Vector2(100, 50))
	add_world_node("beast_mountain", "兽王山", "西域", Vector2(200, 150))
	add_world_node("dragon_temple", "龙王庙", "东海", Vector2(50, 200))
	add_world_node("heaven_peak", "天剑峰", "剑域", Vector2(300, 100))
	
	# 默认解锁起始位置
	if world_nodes.has("qingyun_mountain"):
		world_nodes["qingyun_mountain"].is_unlocked = true
		world_nodes["qingyun_mountain"].is_discovered = true
		current_location = "qingyun_mountain"

# 添加世界节点
func add_world_node(node_id: String, name: String, region: String, position: Vector2):
	var node = WorldNode.new(node_id, name, region, position)
	world_nodes[node_id] = node

# 计算两点间距离
func calculate_distance(start_node_id: String, end_node_id: String) -> float:
	if not world_nodes.has(start_node_id) or not world_nodes.has(end_node_id):
		return -1.0
	
	var start_node = world_nodes[start_node_id]
	var end_node = world_nodes[end_node_id]
	
	var distance = start_node.position.distance_to(end_node.position)
	return distance

# 计算旅行费用
func calculate_travel_cost(start_node_id: String, end_node_id: String) -> int:
	if not world_nodes.has(start_node_id) or not world_nodes.has(end_node_id):
		travel_failed.emit("起始点或目标点不存在")
		return -1
	
	var start_node = world_nodes[start_node_id]
	var end_node = world_nodes[end_node_id]
	
	# 检查目标点是否已解锁
	if not end_node.is_unlocked:
		travel_failed.emit("目标地点未解锁")
		return -1
	
	# 计算基础距离
	var distance = calculate_distance(start_node_id, end_node_id)
	if distance < 0:
		travel_failed.emit("无法计算距离")
		return -1
	
	# 计算距离系数（0.0-1.0）
	var distance_coefficient = min(1.0, distance / 500.0)  # 假设最大距离为500单位
	
	# 计算基础费用
	var base_cost = BASE_TRAVEL_COST + (distance_coefficient * DISTANCE_COST_MULTIPLIER)
	
	# 如果在同一区域，给予折扣
	if start_node.region == end_node.region:
		base_cost *= SAME_REGION_MULTIPLIER
	
	# 确保费用在合理范围内
	var final_cost = int(clamp(base_cost, BASE_TRAVEL_COST, MAX_TRAVEL_COST))
	
	# 发送费用计算信号
	travel_cost_calculated.emit(final_cost)
	
	return final_cost

# 计算旅行时间
func calculate_travel_time(distance: float) -> int:
	# 基础时间 + 距离相关时间
	# 距离越远，时间越长，但有上限
	var base_time_hours = 1  # 基础1小时
	var distance_time_hours = int(distance / 100)  # 每100单位距离1小时
	
	# 最大旅行时间限制
	var max_travel_time = 24  # 最多24小时
	
	var total_time = min(base_time_hours + distance_time_hours, max_travel_time)
	return total_time

# 检查是否可以旅行
func can_travel_to(destination_node_id: String) -> bool:
	if current_state != TravelState.IDLE:
		return false
	
	if not world_nodes.has(destination_node_id):
		return false
	
	var destination_node = world_nodes[destination_node_id]
	return destination_node.is_unlocked

# 执行旅行到指定位置
func travel_to_location(destination_node_id: String) -> bool:
	# 检查旅行状态
	if current_state != TravelState.IDLE:
		travel_failed.emit("旅行状态错误：当前无法开始新旅行")
		return false
	
	# 检查目标点是否存在
	if not world_nodes.has(destination_node_id):
		travel_failed.emit("目标地点不存在")
		return false
	
	var destination_node = world_nodes[destination_node_id]
	
	# 检查目标点是否已解锁
	if not destination_node.is_unlocked:
		travel_failed.emit("目标地点未解锁")
		return false
	
	# 检查玩家是否在战斗状态（这里假设有一个战斗状态检查函数）
	if is_player_in_combat():
		travel_failed.emit("战斗状态下无法使用快速旅行")
		return false
	
	# 计算旅行费用
	var travel_cost = calculate_travel_cost(current_location, destination_node_id)
	if travel_cost <= 0:
		return false
	
	# 检查玩家是否有足够费用（这里假设有一个检查玩家银两的函数）
	if not has_player_enough_money(travel_cost):
		travel_failed.emit("银两不足，无法支付旅行费用")
		return false
	
	# 计算旅行时间
	var distance = calculate_distance(current_location, destination_node_id)
	var travel_time = calculate_travel_time(distance)
	
	# 更新状态
	current_state = TravelState.CALCULATING
	
	# 发送旅行开始信号
	travel_started.emit(destination_node.name, travel_cost, travel_time)
	
	# 扣除旅行费用（这里假设有一个扣除玩家银两的函数）
	deduct_travel_cost(travel_cost)
	
	# 开始旅行过程
	start_travel_process(destination_node_id, travel_time)
	
	return true

# 开始旅行过程
func start_travel_process(destination_node_id: String, travel_time_hours: int):
	current_state = TravelState.TRAVELING
	
	# TODO(beta): 接入异步加载、过场动画; 当前用短计时器模拟
	await get_tree().create_timer(travel_time_hours * 0.1).timeout  # 使用较短的模拟时间
	
	# 旅行完成
	complete_travel(destination_node_id)

# 完成旅行
func complete_travel(destination_node_id: String):
	# 更新玩家位置
	current_location = destination_node_id
	
	# 更新游戏时间
	advance_game_time()
	
	# 更新状态
	current_state = TravelState.COMPLETED
	
	# 发送旅行完成信号
	travel_completed.emit(world_nodes[destination_node_id].name)
	
	# 重置状态
	current_state = TravelState.IDLE

func is_player_in_combat() -> bool:
	var combat: Node = get_node_or_null("/root/CombatSystem")
	if combat and combat.has_method("is_battle_over"):
		return not combat.is_battle_over() and combat.battle_state != 0
	return false

func has_player_enough_money(cost: int) -> bool:
	var currency: Node = get_node_or_null("/root/CurrencyManager")
	if currency and currency.has_method("get_currency_amount"):
		return currency.get_currency_amount(0) >= cost
	return true

func deduct_travel_cost(cost: int) -> void:
	var currency: Node = get_node_or_null("/root/CurrencyManager")
	if currency and currency.has_method("spend_currency"):
		currency.spend_currency(0, cost)

func advance_game_time() -> void:
	pass

# 解锁地点
func unlock_location(node_id: String) -> bool:
	if not world_nodes.has(node_id):
		return false
	
	var node = world_nodes[node_id]
	node.is_unlocked = true
	node.is_discovered = true
	
	print("地点已解锁: %s" % node.name)
	return true

# 获取所有已解锁的地点
func get_unlocked_locations() -> Array:
	var unlocked = []
	for node_id in world_nodes:
		var node = world_nodes[node_id]
		if node.is_unlocked:
			unlocked.append(node)
	return unlocked

# 获取所有已发现的地点
func get_discovered_locations() -> Array:
	var discovered = []
	for node_id in world_nodes:
		var node = world_nodes[node_id]
		if node.is_discovered:
			discovered.append(node)
	return discovered

# 获取旅行状态
func get_travel_state() -> TravelState:
	return current_state

# 获取当前位置信息
func get_current_location_info() -> Dictionary:
	if not world_nodes.has(current_location):
		return {}
	
	var node = world_nodes[current_location]
	return {
		"id": node.id,
		"name": node.name,
		"region": node.region,
		"position": node.position,
		"is_unlocked": node.is_unlocked,
		"is_discovered": node.is_discovered
	}

# 获取目标位置信息
func get_destination_info(destination_id: String) -> Dictionary:
	if not world_nodes.has(destination_id):
		return {}
	
	var node = world_nodes[destination_id]
	var distance = calculate_distance(current_location, destination_id)
	var cost = calculate_travel_cost(current_location, destination_id)
	var travel_time = calculate_travel_time(distance)
	
	return {
		"id": node.id,
		"name": node.name,
		"region": node.region,
		"position": node.position,
		"is_unlocked": node.is_unlocked,
		"is_discovered": node.is_discovered,
		"distance": distance,
		"cost": cost,
		"travel_time": travel_time
	}