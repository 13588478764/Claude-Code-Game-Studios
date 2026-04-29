## AttributePointManager
## 属性点管理器
##
## 管理玩家的属性点分配和六维属性系统。
## 提供属性点的获取、分配、重置和数据持久化功能。
##
## 主要功能：
## - 属性点总数管理
## - 单个属性点分配
## - 属性点重置
## - 数据保存和加载
## - 智能推荐分配方案

extends Node
class_name AttributePointManager

# ============================================================================
# 常量定义
# ============================================================================

const MAX_TOTAL_POINTS = 495  # 99级 × 5点
const MAX_ATTRIBUTE_VALUE = 99
const POINTS_PER_LEVEL = 5

# ============================================================================
# 成员变量
# ============================================================================

var total_points: int = 0  # 总获得属性点数
var allocated_points: int = 0  # 已分配属性点数
var attributes: Dictionary = {
	"strength": 0,      # 力道
	"agility": 0,       # 身法
	"constitution": 0,  # 根骨
	"intelligence": 0,  # 悟性
	"willpower": 0,     # 定力
	"luck": 0           # 福缘
}
var reset_count: int = 0  # 免费重置次数

# ============================================================================
# 信号定义
# ============================================================================

signal attribute_allocated(attribute_type: String, new_value: int)
signal attributes_reset()
REPLACE

func _ready():
	pass

## 获取总属性点数
func get_total_points() -> int:
	return total_points

## 获取可用属性点数
func get_available_points() -> int:
	return total_points - allocated_points

## 获取已分配属性点数
func get_allocated_points() -> int:
	return allocated_points

## 获取属性值
func get_attribute_value(attribute_type: String) -> int:
	if attribute_type in attributes:
		return attributes[attribute_type]
	return 0

## 获取重置次数
func get_reset_count() -> int:
	return reset_count

## 添加总属性点数
func add_total_points(points: int) -> void:
	total_points = min(total_points + points, MAX_TOTAL_POINTS)

## 分配属性点
func allocate_point(attribute_type: String) -> bool:
	# 验证属性类型
	if not attribute_type in attributes:
		return false
	
	# 检查是否有可用点数
	if get_available_points() <= 0:
		return false
	
	# 检查属性是否已达到上限
	if attributes[attribute_type] >= MAX_ATTRIBUTE_VALUE:
		return false
	
	# 分配属性点
	attributes[attribute_type] += 1
	allocated_points += 1
	
	# 发射信号
	attribute_allocated.emit(attribute_type, attributes[attribute_type])
	
	return true

## 重置属性
func reset_attributes(use_free_reset: bool = false) -> bool:
	if use_free_reset:
		if reset_count <= 0:
			return false
		reset_count -= 1
	
	# 重置所有属性
	for attr in attributes:
		attributes[attr] = 0
	
	allocated_points = 0
	
	# 发射信号
	attributes_reset.emit()
	
	return true

## 加载数据
func load_data(data: Dictionary) -> void:
	# 加载总属性点数
	total_points = int(data.get("total_points", 0))
	total_points = clamp(total_points, 0, MAX_TOTAL_POINTS)
	
	# 加载属性值
	var loaded_attributes = data.get("attributes", {})
	for attr in attributes:
		if attr in loaded_attributes:
			attributes[attr] = clamp(int(loaded_attributes[attr]), 0, MAX_ATTRIBUTE_VALUE)
	
	# 重新计算已分配属性点数
	allocated_points = 0
	for attr in attributes:
		allocated_points += attributes[attr]
	
	# 加载重置次数
	reset_count = int(data.get("reset_count", 0))

## 保存数据
func save_data() -> Dictionary:
	return {
		"total_points": total_points,
		"allocated_points": allocated_points,
		"attributes": attributes.duplicate(),
		"reset_count": reset_count
	}

## 获取智能推荐
func get_smart_recommendation(current_skills: Array) -> Dictionary:
	# 返回推荐的属性分配方案
	return {
		"strength": 20,
		"agility": 15,
		"constitution": 20,
		"intelligence": 15,
		"willpower": 15,
		"luck": 10
	}