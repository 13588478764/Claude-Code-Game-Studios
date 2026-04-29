## TravelCostManager
## 旅行成本管理器
实现旅行费用计算、旅行时间计算、余额验证和货币回收功能
##
## 主要功能：
## - 待补充

extends Node

class_name TravelCostManager

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
signal travel_cost_calculated(cost: int)
signal travel_time_calculated(time: int)
signal payment_processed(cost: int, success: bool)
signal insufficient_funds(cost: int, available: int)

# 常量定义
const BASE_TRAVEL_COST = 10  # 基础旅行费用
const DISTANCE_COST_MULTIPLIER = 100  # 距离成本乘数
const SAME_REGION_MULTIPLIER = 0.5  # 同区域旅行费用折扣
const MAX_TRAVEL_COST = 1000  # 最大旅行费用

const BASE_TRAVEL_TIME = 1  # 基础旅行时间（小时）
const DISTANCE_TIME_MULTIPLIER = 6  # 距离时间乘数
const MAX_TRAVEL_TIME = 24  # 最大旅行时间（小时）

# 玩家经济数据
var player_money: int = 1000  # 玩家当前银两
var total_travel_cost: int = 0  # 系统总收入

# 世界节点数据结构
class WorldNode:
	var id: String
	var name: String
	var region: String
	var position: Vector2
	
	func _init(p_id: String, p_name: String, p_region: String, p_pos: Vector2):
		id = p_id
		name = p_name
		region = p_region
		position = p_pos

# 存储世界节点
var world_nodes: Dictionary = {}

# 初始化
func _ready():
	# 添加示例世界节点
	add_world_node("qingyun_mountain", "青云山", "青州", Vector2(0, 0))
	add_world_node("jiangnan_town", "江南水乡", "江南", Vector2(100, 50))
	add_world_node("beast_mountain", "兽王山", "西域", Vector2(200, 150))
	add_world_node("dragon_temple", "龙王庙", "东海", Vector2(50, 200))
	add_world_node("heaven_peak", "天剑峰", "剑域", Vector2(300, 100))

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
		return -1
	
	var start_node = world_nodes[start_node_id]
	var end_node = world_nodes[end_node_id]
	
	# 计算基础距离
	var distance = calculate_distance(start_node_id, end_node_id)
	if distance < 0:
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
	var base_time_hours = BASE_TRAVEL_TIME  # 基础1小时
	var distance_time_hours = int(distance / 100) * DISTANCE_TIME_MULTIPLIER  # 每100单位距离6小时
	
	# 最大旅行时间限制
	var max_travel_time = MAX_TRAVEL_TIME  # 最多24小时
	
	var total_time = min(base_time_hours + distance_time_hours, max_travel_time)
	
	# 发送时间计算信号
	travel_time_calculated.emit(total_time)
	
	return total_time

# 验证玩家是否有足够余额
func has_sufficient_funds(cost_amount: int) -> bool:
	return player_money >= cost_amount

# 处理支付
func process_payment(cost_amount: int) -> bool:
	if not has_sufficient_funds(cost_amount):
		# 发送余额不足信号
		insufficient_funds.emit(cost_amount, player_money)
		return false
	
	# 扣除费用
	player_money -= cost_amount
	
	# 更新系统总收入
	total_travel_cost += cost_amount
	
	# 发送支付处理信号
	payment_processed.emit(cost_amount, true)
	
	return true

# 获取玩家当前余额
func get_player_money() -> int:
	return player_money

# 设置玩家当前余额
func set_player_money(amount: int):
	player_money = amount

# 获取系统总收入
func get_total_travel_cost() -> int:
	return total_travel_cost

# 获取世界节点信息
func get_world_node_info(node_id: String) -> Dictionary:
	if not world_nodes.has(node_id):
		return {}
	
	var node = world_nodes[node_id]
	return {
		"id": node.id,
		"name": node.name,
		"region": node.region,
		"position": node.position
	}

# 执行完整的旅行成本处理流程
func process_travel(start_node_id: String, end_node_id: String) -> Dictionary:
	var result = {
		"success": false,
		"cost": 0,
		"time": 0,
		"error": ""
	}
	
	# 计算旅行费用
	var cost = calculate_travel_cost(start_node_id, end_node_id)
	if cost <= 0:
		result.error = "无法计算旅行费用"
		return result
	
	# 计算旅行时间
	var distance = calculate_distance(start_node_id, end_node_id)
	var travel_time = calculate_travel_time(distance)
	
	# 验证余额
	if not has_sufficient_funds(cost):
		result.error = "余额不足"
		insufficient_funds.emit(cost, player_money)
		return result
	
	# 处理支付
	var payment_success = process_payment(cost)
	if not payment_success:
		result.error = "支付失败"
		return result
	
	# 返回成功结果
	result.success = true
	result.cost = cost
	result.time = travel_time
	
	return result

# 退款功能（用于取消旅行等场景）
func refund_cost(cost_amount: int) -> bool:
	player_money += cost_amount
	total_travel_cost -= cost_amount
	
	# 确保系统总收入不为负
	if total_travel_cost < 0:
		total_travel_cost = 0
	
	return true

# 重置经济数据（仅用于测试）
func reset_economy_data():
	player_money = 1000
	total_travel_cost = 0