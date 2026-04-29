## AttributeAssignmentUI
## 属性点分配UI管理器
##
## 管理属性点分配界面的显示、交互和与AttributePointManager的集成。
## 提供属性点分配的UI交互、历史记录和智能推荐功能。
##
## 主要功能：
## - 属性点分配UI显示
## - 属性点分配交互处理
## - 分配历史记录管理
## - 撤销/重做功能
## - 智能推荐分配方案

extends Control
class_name AttributeAssignmentUI

# ============================================================================
# 成员变量
# ============================================================================

var attribute_manager
var temp_allocation: Dictionary = {
	"strength": 0,
	"agility": 0,
	"constitution": 0,
	"intelligence": 0,
	"willpower": 0,
	"luck": 0
}
var allocation_history: Array = []
var history_index: int = -1

# UI 组件引用
var strength_label: Label
var agility_label: Label
var constitution_label: Label
var intelligence_label: Label
var willpower_label: Label
var luck_label: Label
var available_points_label: Label

# ============================================================================
# 信号定义
# ============================================================================

signal allocation_applied(allocation: Dictionary)
signal allocation_reset()
REPLACE

func _ready():
	# 初始化UI组件（在实际项目中这些会从场景中获取）
	_initialize_ui_components()

## 初始化UI组件
func _initialize_ui_components() -> void:
	# 创建标签（在实际项目中这些会从场景中获取）
	strength_label = Label.new()
	strength_label.name = "StrengthLabel"
	add_child(strength_label)
	
	agility_label = Label.new()
	agility_label.name = "AgilityLabel"
	add_child(agility_label)
	
	constitution_label = Label.new()
	constitution_label.name = "ConstitutionLabel"
	add_child(constitution_label)
	
	intelligence_label = Label.new()
	intelligence_label.name = "IntelligenceLabel"
	add_child(intelligence_label)
	
	willpower_label = Label.new()
	willpower_label.name = "WillpowerLabel"
	add_child(willpower_label)
	
	luck_label = Label.new()
	luck_label.name = "LuckLabel"
	add_child(luck_label)
	
	available_points_label = Label.new()
	available_points_label.name = "AvailablePointsLabel"
	add_child(available_points_label)

## 设置属性点管理器引用
func set_attribute_manager(manager) -> void:
	attribute_manager = manager
	if attribute_manager:
		attribute_manager.attribute_allocated.connect(_on_attribute_allocated)

## 显示属性点分配界面
func show_assignment_interface() -> void:
	visible = true
	refresh_ui()

## 隐藏属性点分配界面
func hide_assignment_interface() -> void:
	visible = false

## 刷新UI显示
func refresh_ui() -> void:
	if not attribute_manager:
		return
	
	# 更新属性值显示
	strength_label.text = "力道: %d" % attribute_manager.get_attribute_value("strength")
	agility_label.text = "身法: %d" % attribute_manager.get_attribute_value("agility")
	constitution_label.text = "根骨: %d" % attribute_manager.get_attribute_value("constitution")
	intelligence_label.text = "悟性: %d" % attribute_manager.get_attribute_value("intelligence")
	willpower_label.text = "定力: %d" % attribute_manager.get_attribute_value("willpower")
	luck_label.text = "福缘: %d" % attribute_manager.get_attribute_value("luck")
	
	# 更新可用点数显示
	available_points_label.text = "可用点数: %d" % attribute_manager.get_available_points()

## 分配属性点（力道）
func _on_strength_add_pressed() -> void:
	if temp_allocation["strength"] < 99:
		temp_allocation["strength"] += 1

## 分配属性点（身法）
func _on_agility_add_pressed() -> void:
	if temp_allocation["agility"] < 99:
		temp_allocation["agility"] += 1

## 分配属性点（根骨）
func _on_constitution_add_pressed() -> void:
	if temp_allocation["constitution"] < 99:
		temp_allocation["constitution"] += 1

## 分配属性点（悟性）
func _on_intelligence_add_pressed() -> void:
	if temp_allocation["intelligence"] < 99:
		temp_allocation["intelligence"] += 1

## 分配属性点（定力）
func _on_willpower_add_pressed() -> void:
	if temp_allocation["willpower"] < 99:
		temp_allocation["willpower"] += 1

## 分配属性点（福缘）
func _on_luck_add_pressed() -> void:
	if temp_allocation["luck"] < 99:
		temp_allocation["luck"] += 1

## 获取临时分配
func get_temp_allocation() -> Dictionary:
	return temp_allocation.duplicate()

## 重置临时分配
func reset_temp_allocation() -> void:
	temp_allocation = {
		"strength": 0,
		"agility": 0,
		"constitution": 0,
		"intelligence": 0,
		"willpower": 0,
		"luck": 0
	}
	allocation_reset.emit()

## 应用分配变更
func apply_allocation_changes() -> bool:
	if not attribute_manager:
		return false
	
	# 保存当前状态到历史记录
	_save_to_history()
	
	# 应用临时分配
	var total_allocated = 0
	for attr in temp_allocation:
		for _i in range(temp_allocation[attr]):
			if not attribute_manager.allocate_point(attr):
				return false
			total_allocated += 1
	
	# 清空临时分配
	reset_temp_allocation()
	
	# 刷新UI
	refresh_ui()
	
	# 发射信号
	allocation_applied.emit(temp_allocation)
	
	return true

## 保存到历史记录
func _save_to_history() -> void:
	# 移除当前索引之后的历史记录
	if history_index < allocation_history.size() - 1:
		allocation_history.resize(history_index + 1)
	
	# 添加新的历史记录
	allocation_history.append(temp_allocation.duplicate())
	history_index += 1

## 撤销分配
func undo_allocation() -> bool:
	if history_index > 0:
		history_index -= 1
		temp_allocation = allocation_history[history_index].duplicate()
		refresh_ui()
		return true
	return false

## 重做分配
func redo_allocation() -> bool:
	if history_index < allocation_history.size() - 1:
		history_index += 1
		temp_allocation = allocation_history[history_index].duplicate()
		refresh_ui()
		return true
	return false

## 获取智能推荐分配方案
func recommend_allocation_scheme(martial_arts: Array) -> Dictionary:
	var recommendation = {
		"strength": 0,
		"agility": 0,
		"constitution": 0,
		"intelligence": 0,
		"willpower": 0,
		"luck": 0
	}
	
	# 分析武学类型并提供推荐
	for martial_art in martial_arts:
		if martial_art is Dictionary:
			var name_str = martial_art.get("name", "").to_lower()
			
			# 剑法类武学 - 推荐力道和悟性
			if "剑" in name_str:
				recommendation["strength"] += 2
				recommendation["intelligence"] += 1
			
			# 掌法类武学 - 推荐力道和根骨
			elif "掌" in name_str:
				recommendation["strength"] += 2
				recommendation["constitution"] += 1
			
			# 身法类武学 - 推荐身法和定力
			elif "身法" in name_str or "轻功" in name_str:
				recommendation["agility"] += 2
				recommendation["willpower"] += 1
			
			# 内功类武学 - 推荐悟性和定力
			elif "内功" in name_str or "心法" in name_str:
				recommendation["intelligence"] += 2
				recommendation["willpower"] += 1
			
			# 默认推荐 - 均衡分配
			else:
				recommendation["strength"] += 1
				recommendation["agility"] += 1
				recommendation["constitution"] += 1
				recommendation["intelligence"] += 1
				recommendation["willpower"] += 1
				recommendation["luck"] += 1
	
	return recommendation

## 处理属性点分配信号
func _on_attribute_allocated(attribute_type: String, new_value: int) -> void:
	refresh_ui()