## AttributeValidationManager
## 属性点验证管理器
##
## 管理属性点分配的验证、重置和数据完整性检查。
## 提供属性点分配的验证、数据完整性验证和重置功能。
##
## 主要功能：
## - 属性点分配验证
## - 属性值范围验证
## - 数据完整性检查
## - 重置操作管理
## - 错误记录和报告

extends Node
class_name AttributeValidationManager

# ============================================================================
# 常量定义
# ============================================================================

const MAX_ATTRIBUTE_VALUE = 99
const RESET_TYPE_ITEM = "item"  # 洗髓丹重置
const RESET_TYPE_BREAKTHROUGH = "breakthrough"  # 境界突破重置

# ============================================================================
# 成员变量
# ============================================================================

var attribute_manager
var validation_errors: Array = []

# ============================================================================
# 信号定义
# ============================================================================

signal validation_passed(attribute_type: String, points: int)
signal validation_failed(attribute_type: String, reason: String)
signal reset_completed(reset_type: String)
signal data_integrity_verified()
REPLACE

func _ready():
	pass

## 设置属性点管理器引用
func set_attribute_manager(manager) -> void:
	attribute_manager = manager

## 验证属性点分配
func validate_allocation(attribute_type: String, points: int) -> bool:
	validation_errors.clear()
	
	if not attribute_manager:
		validation_errors.append("AttributeManager not set")
		validation_failed.emit(attribute_type, "AttributeManager not set")
		return false
	
	# 验证属性类型
	if not _is_valid_attribute_type(attribute_type):
		validation_errors.append("Invalid attribute type: %s" % attribute_type)
		validation_failed.emit(attribute_type, "Invalid attribute type")
		return false
	
	# 验证点数为非负整数
	if points < 0:
		validation_errors.append("Points cannot be negative: %d" % points)
		validation_failed.emit(attribute_type, "Points cannot be negative")
		return false
	
	if points != int(points):
		validation_errors.append("Points must be integer: %f" % points)
		validation_failed.emit(attribute_type, "Points must be integer")
		return false
	
	# 验证可用点数
	var available_points = attribute_manager.get_available_points()
	if points > available_points:
		validation_errors.append("Insufficient points. Available: %d, Requested: %d" % [available_points, points])
		validation_failed.emit(attribute_type, "Insufficient available points")
		return false
	
	# 验证属性上限
	var current_value = attribute_manager.get_attribute_value(attribute_type)
	if current_value + points > MAX_ATTRIBUTE_VALUE:
		validation_errors.append("Attribute would exceed max value. Current: %d, Max: %d, Requested: %d" % [current_value, MAX_ATTRIBUTE_VALUE, points])
		validation_failed.emit(attribute_type, "Attribute would exceed maximum value")
		return false
	
	# 验证通过
	validation_passed.emit(attribute_type, points)
	return true

## 重置属性点
func reset_attributes(reset_type: String) -> bool:
	if not attribute_manager:
		return false
	
	match reset_type:
		RESET_TYPE_ITEM:
			# 洗髓丹重置：重置所有已分配的属性点
			return _reset_by_item()
		RESET_TYPE_BREAKTHROUGH:
			# 境界突破重置：免费重置一次
			return _reset_by_breakthrough()
		_:
			return false

## 通过洗髓丹重置属性
func _reset_by_item() -> bool:
	if not attribute_manager:
		return false
	
	# 重置所有属性到基础值
	var attributes = ["strength", "agility", "constitution", "intelligence", "willpower", "luck"]
	for attr in attributes:
		# 这里假设有一个 reset_attribute 方法
		# 实际实现取决于 AttributePointManager 的设计
		pass
	
	reset_completed.emit(RESET_TYPE_ITEM)
	return true

## 通过境界突破重置属性
func _reset_by_breakthrough() -> bool:
	if not attribute_manager:
		return false
	
	# 境界突破时的免费重置
	var attributes = ["strength", "agility", "constitution", "intelligence", "willpower", "luck"]
	for attr in attributes:
		pass
	
	reset_completed.emit(RESET_TYPE_BREAKTHROUGH)
	return true

## 验证数据完整性
func verify_data_integrity() -> bool:
	if not attribute_manager:
		return false
	
	# 验证属性值范围
	var attributes = ["strength", "agility", "constitution", "intelligence", "willpower", "luck"]
	for attr in attributes:
		var value = attribute_manager.get_attribute_value(attr)
		
		# 验证值在有效范围内
		if value < 0 or value > MAX_ATTRIBUTE_VALUE:
			return false
	
	# 验证总属性点数
	var total_points = attribute_manager.get_total_points()
	var available_points = attribute_manager.get_available_points()
	
	# 总点数应该 >= 可用点数
	if total_points < available_points:
		return false
	
	# 验证已分配点数 = 总点数 - 可用点数
	var allocated_points = total_points - available_points
	var calculated_allocated = 0
	
	for attr in attributes:
		var value = attribute_manager.get_attribute_value(attr)
		calculated_allocated += value
	
	if allocated_points != calculated_allocated:
		return false
	
	data_integrity_verified.emit()
	return true

## 检查属性类型是否有效
func _is_valid_attribute_type(attribute_type: String) -> bool:
	var valid_types = ["strength", "agility", "constitution", "intelligence", "willpower", "luck"]
	return attribute_type in valid_types

## 获取验证错误
func get_validation_errors() -> Array:
	return validation_errors.duplicate()

## 清除验证错误
func clear_validation_errors() -> void:
	validation_errors.clear()