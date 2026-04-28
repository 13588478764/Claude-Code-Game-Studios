extends Node

# 属性点分配系统 - 核心管理器
# 负责管理角色的属性点获取、分配和验证

# 信号定义
signal attribute_allocated(attribute_type, new_value)
signal available_points_changed(new_count)

# 属性类型常量
const ATTRIBUTE_STRENGTH = "strength"      # 力道
const ATTRIBUTE_AGILITY = "agility"        # 身法  
const ATTRIBUTE_CONSTITUTION = "constitution"  # 根骨
const ATTRIBUTE_INTELLIGENCE = "intelligence"  # 悟性
const ATTRIBUTE_WILLPOWER = "willpower"    # 定力
const ATTRIBUTE_LUCK = "luck"              # 福缘

# 属性数据结构
var total_points: int = 0          # 总获得属性点数（最大495点）
var allocated_points: int = 0       # 已分配属性点数
var attributes: Dictionary = {
	ATTRIBUTE_STRENGTH: 0,
	ATTRIBUTE_AGILITY: 0,
	ATTRIBUTE_CONSTITUTION: 0,
	ATTRIBUTE_INTELLIGENCE: 0,
	ATTRIBUTE_WILLPOWER: 0,
	ATTRIBUTE_LUCK: 0
}
var reset_count: int = 0           # 免费重置次数（境界突破获得）

# 最大属性值限制
const MAX_ATTRIBUTE_VALUE = 99
# 最大总属性点数（99级 * 5点）
const MAX_TOTAL_POINTS = 495

func _ready():
	# 初始化属性点管理器
	_setup_initial_attributes()

func _setup_initial_attributes():
	# 初始状态：1级角色，0点已分配
	total_points = 0
	allocated_points = 0
	reset_count = 0
	
	# 所有属性初始化为0
	for attr in attributes:
		attributes[attr] = 0

# 分配1点到指定属性
func allocate_point(attribute_type: String) -> bool:
	# 验证属性类型
	if not _is_valid_attribute(attribute_type):
		push_error("Invalid attribute type: %s" % attribute_type)
		return false
	
	# 检查是否有可用点数
	if get_available_points() <= 0:
		push_warning("No available points to allocate")
		return false
	
	# 检查属性是否达到上限
	if attributes[attribute_type] >= MAX_ATTRIBUTE_VALUE:
		push_warning("Attribute %s has reached maximum value (%d)" % [attribute_type, MAX_ATTRIBUTE_VALUE])
		return false
	
	# 分配属性点
	attributes[attribute_type] += 1
	allocated_points += 1
	
	# 发送信号通知其他系统
	emit_signal("attribute_allocated", attribute_type, attributes[attribute_type])
	
	return true

# 重置所有属性点（消耗免费重置次数或洗髓丹）
func reset_attributes(use_free_reset: bool = true) -> bool:
	# 如果使用免费重置，检查是否有免费重置次数
	if use_free_reset and reset_count <= 0:
		push_warning("No free reset available")
		return false
	
	# 消耗免费重置次数
	if use_free_reset:
		reset_count -= 1
	
	# 重置所有属性
	for attr in attributes:
		attributes[attr] = 0
	
	allocated_points = 0
	
	return true

# 获取可用属性点数
func get_available_points() -> int:
	return total_points - allocated_points

# 获取指定属性值
func get_attribute_value(attribute_type: String) -> int:
	if not _is_valid_attribute(attribute_type):
		push_error("Invalid attribute type: %s" % attribute_type)
		return 0
	
	return attributes[attribute_type]

# 增加总属性点数（通常在升级时调用）
func add_total_points(points: int) -> void:
	total_points = min(total_points + points, MAX_TOTAL_POINTS)
	emit_signal("available_points_changed", get_available_points())

# 设置免费重置次数（通常在境界突破时调用）
func set_reset_count(count: int) -> void:
	reset_count = count

# 获取当前免费重置次数
func get_reset_count() -> int:
	return reset_count

# 验证属性类型是否有效
func _is_valid_attribute(attribute_type: String) -> bool:
	return attribute_type in attributes

# 获取所有属性的副本（用于UI显示等）
func get_all_attributes() -> Dictionary:
	var result: Dictionary = {}
	for attr in attributes:
		result[attr] = attributes[attr]
	return result

# 获取总属性点数
func get_total_points() -> int:
	return total_points

# 获取已分配属性点数
func get_allocated_points() -> int:
	return allocated_points

# 保存属性点数据（用于持久化）
func save_data() -> Dictionary:
	return {
		"total_points": total_points,
		"allocated_points": allocated_points,
		"attributes": get_all_attributes(),
		"reset_count": reset_count
	}

# 加载属性点数据（用于持久化）
func load_data(data: Dictionary) -> void:
	if data.has("total_points"):
		total_points = data["total_points"]
	if data.has("allocated_points"):
		allocated_points = data["allocated_points"]
	if data.has("attributes"):
		for attr in data["attributes"]:
			if attributes.has(attr):
				attributes[attr] = data["attributes"][attr]
	if data.has("reset_count"):
		reset_count = data["reset_count"]
	
	# 验证数据完整性
	_validate_data_integrity()

# 验证数据完整性
func _validate_data_integrity() -> void:
	# 确保总点数不超过最大值
	total_points = min(total_points, MAX_TOTAL_POINTS)
	
	# 确保已分配点数不超过总点数
	allocated_points = min(allocated_points, total_points)
	
	# 确保属性值不超过最大值
	for attr in attributes:
		attributes[attr] = min(attributes[attr], MAX_ATTRIBUTE_VALUE)
	
	# 重新计算已分配点数（如果数据不一致）
	var recalculated_allocated = 0
	for attr in attributes:
		recalculated_allocated += attributes[attr]
	
	if recalculated_allocated != allocated_points:
		allocated_points = recalculated_allocated
		push_warning("Attribute point allocation recalculated due to data inconsistency")

# 获取属性描述（用于UI显示）
func get_attribute_description(attribute_type: String) -> String:
	match attribute_type:
		ATTRIBUTE_STRENGTH:
			return "影响物理攻击力、负重能力"
		ATTRIBUTE_AGILITY:
			return "影响闪避率、移动速度、先攻值"
		ATTRIBUTE_CONSTITUTION:
			return "影响生命值上限、防御力、内力上限"
		ATTRIBUTE_INTELLIGENCE:
			return "影响武学学习速度、暴击率、技能效果"
		ATTRIBUTE_WILLPOWER:
			return "影响抗控制能力、内力回复率、命中率"
		ATTRIBUTE_LUCK:
			return "影响奇遇触发概率、稀有物品掉落率、商人折扣"
		_:
			return "未知属性"

# 获取智能推荐分配方案（基于当前武学配置）
# 注意：此功能需要与武学系统集成，此处仅提供接口
func get_smart_recommendation(current_martial_arts: Array) -> Dictionary:
	# TODO: 实现基于武学配置的智能推荐
	# 这里返回一个空字典作为占位符
	return {}