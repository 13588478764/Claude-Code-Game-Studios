extends Node

# 属性点验证管理器
# 负责验证属性点分配的合规性

# 信号定义
signal validation_passed
signal validation_failed(reason: String)

# 引用AttributePointManager
var attribute_manager: Node = null

# 验证配置常量
const MAX_ATTRIBUTE_VALUE = 99  # 单个属性最大值
const MAX_TOTAL_POINTS = 495     # 总属性点上限 (99级 * 5点)

# 设置AttributePointManager引用
func set_attribute_manager(manager: Node) -> void:
	attribute_manager = manager

# 验证属性点分配
func validate_allocation(attribute_type: String, points: int = 1) -> bool:
	if not attribute_manager:
		push_error("Attribute manager not set")
		return false
	
	# 检查是否有足够的可用点数
	var available_points = attribute_manager.get_available_points()
	if points > available_points:
		push_warning("Insufficient available points for allocation")
		emit_signal("validation_failed", "Insufficient available points")
		return false
	
	# 检查属性是否达到上限
	var current_value = attribute_manager.get_attribute_value(attribute_type)
	if current_value + points > MAX_ATTRIBUTE_VALUE:
		push_warning("Attribute value would exceed maximum limit")
		emit_signal("validation_failed", "Attribute value exceeds maximum limit")
		return false
	
	# 验证通过
	emit_signal("validation_passed")
	return true

# 验证重置操作
func validate_reset(reset_type: String) -> bool:
	if not attribute_manager:
		push_error("Attribute manager not set")
		return false
	
	# 根据重置类型验证
	if reset_type == "cultivation_breakthrough":
		# 境界突破重置 - 验证玩家是否达到突破条件
		# 这里可以添加境界突破的验证逻辑
		emit_signal("validation_passed")
		return true
	elif reset_type == "pills":
		# 洗髓丹重置 - 验证玩家是否拥有洗髓丹道具
		# 这里可以添加道具验证逻辑
		emit_signal("validation_passed")
		return true
	else:
		push_warning("Invalid reset type: " + reset_type)
		emit_signal("validation_failed", "Invalid reset type")
		return false

# 执行重置操作
func reset_attributes(reset_type: String) -> bool:
	if not validate_reset(reset_type):
		return false
	
	if not attribute_manager:
		push_error("Attribute manager not set")
		return false
	
	# 执行重置逻辑
	attribute_manager.reset_allocated_points()
	
	# 发送验证通过信号
	emit_signal("validation_passed")
	return true

# 验证数据完整性
func verify_data_integrity() -> bool:
	if not attribute_manager:
		push_error("Attribute manager not set")
		return false
	
	# 获取当前属性数据
	var attributes = attribute_manager.get_all_attributes()
	var available_points = attribute_manager.get_available_points()
	var total_allocated = attribute_manager.get_allocated_points()
	var total_points = attribute_manager.get_total_points()
	
	# 验证总点数一致性
	if total_allocated + available_points != total_points:
		push_error("Data integrity check failed: allocated + available != total")
		return false
	
	# 验证单个属性值不超过上限
	for attr_name in attributes:
		if attributes[attr_name] > MAX_ATTRIBUTE_VALUE:
			push_error("Data integrity check failed: attribute %s exceeds maximum value" % attr_name)
			return false
	
	# 验证总点数不超过上限
	if total_points > MAX_TOTAL_POINTS:
		push_error("Data integrity check failed: total points exceed maximum")
		return false
	
	# 验证通过
	emit_signal("validation_passed")
	return true

# 验证属性上限
func validate_attribute_limit(attribute_type: String, additional_points: int = 1) -> bool:
	if not attribute_manager:
		push_error("Attribute manager not set")
		return false
	
	var current_value = attribute_manager.get_attribute_value(attribute_type)
	if current_value + additional_points > MAX_ATTRIBUTE_VALUE:
		push_warning("Attribute %s would exceed limit of %d" % [attribute_type, MAX_ATTRIBUTE_VALUE])
		emit_signal("validation_failed", "Attribute exceeds maximum limit")
		return false
	
	emit_signal("validation_passed")
	return true

# 批量验证属性分配
func validate_batch_allocation(allocations: Dictionary) -> bool:
	if not attribute_manager:
		push_error("Attribute manager not set")
		return false
	
	# 计算总分配点数
	var total_points_to_allocate = 0
	for attr_type in allocations:
		total_points_to_allocate += allocations[attr_type]
	
	# 检查是否有足够的可用点数
	var available_points = attribute_manager.get_available_points()
	if total_points_to_allocate > available_points:
		push_warning("Insufficient available points for batch allocation")
		emit_signal("validation_failed", "Insufficient available points for batch allocation")
		return false
	
	# 检查每个属性是否超过上限
	for attr_type in allocations:
		var current_value = attribute_manager.get_attribute_value(attr_type)
		if current_value + allocations[attr_type] > MAX_ATTRIBUTE_VALUE:
			push_warning("Attribute %s would exceed maximum limit in batch allocation" % attr_type)
			emit_signal("validation_failed", "Attribute %s exceeds maximum limit" % attr_type)
			return false
	
	# 验证通过
	emit_signal("validation_passed")
	return true

# 验证升级获得的属性点
func validate_level_up_attributes(level: int, current_attributes: Dictionary) -> bool:
	# 验证升级后属性点总数是否合理
	var expected_total_points = level * 5  # 每级5点
	var actual_total_points = 0
	
	# 计算当前已分配点数
	for attr_value in current_attributes.values():
		actual_total_points += attr_value
	
	# 加上可用点数
	if attribute_manager:
		actual_total_points += attribute_manager.get_available_points()
	
	if actual_total_points > expected_total_points:
		push_warning("Attribute point total exceeds expected value for level %d" % level)
		emit_signal("validation_failed", "Attribute point total exceeds expected value")
		return false
	
	emit_signal("validation_passed")
	return true

# 验证属性点分配历史
func validate_allocation_history(history: Array) -> bool:
	# 验证分配历史的合理性
	# 这里可以实现对分配历史的验证逻辑
	# 例如：检查是否有非法的分配操作
	for entry in history:
		if entry.has("attribute") and entry.has("points"):
			if entry["points"] < 0:
				push_warning("Invalid negative allocation in history")
				emit_signal("validation_failed", "Invalid negative allocation in history")
				return false
	
	emit_signal("validation_passed")
	return true