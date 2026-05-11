## QuestItemData
## QuestItemData
## quest item data
## 数据定义模块
## QuestItemData
## 任务道具数据类，继承自ItemData，定义任务道具特有的属性
##
## 主要功能：
## - 待补充

extends Node

class_name QuestItemData

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

class_name QuestItemData

# 任务道具特有属性
@export var quest_id: String = ""  # 关联的任务ID
@export var is_consumable_on_use: bool = false  # 使用后是否消失
@export var required_for_quest: bool = true  # 是否为任务必需品
@export var reusable: bool = false  # 是否可重复使用
@export var quest_stage: int = 0  # 相关任务阶段
@export var trigger_event: String = ""  # 使用时触发的事件

# 构造函数
func _init(p_id: String = "", p_name: String = "", p_description: String = ""):
	super._init(p_id, p_name, p_description)
	quest_id = ""
	is_consumable_on_use = false
	required_for_quest = true
	reusable = false
	quest_stage = 0
	trigger_event = ""

# 重写获取物品类型
func get_item_type() -> String:
	return "QuestItem"

# 验证任务道具数据完整性
func validate() -> bool:
	var base_valid = super.validate()
	return base_valid and quest_id != ""

# 检查是否为任务必需品
func is_required_for_quest() -> bool:
	return required_for_quest

# 检查使用后是否消耗
func is_consumed_on_use() -> bool:
	return is_consumable_on_use

# 获取相关任务ID
func get_related_quest_id() -> String:
	return quest_id

# 检查是否可重复使用
func can_be_reused() -> bool:
	return reusable