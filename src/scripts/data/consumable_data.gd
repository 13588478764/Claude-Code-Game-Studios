## ConsumableData
## ConsumableData
## consumable data
## 数据定义模块
## ConsumableData
## 消耗品数据类，继承自ItemData，定义消耗品特有的属性
##
## 主要功能：
## - 待补充

extends Node

class_name ConsumableData

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

class_name ConsumableData

# 效果类型枚举
enum EffectType {
	HEAL_HP,
	RESTORE_MANA,
	BUFF_TEMP,
	STATUS_CURE,
	ATTRIBUTE_BOOST
}

# 消耗品特有属性
@export var effect_type: int = 0  # 效果类型
@export var effect_value: float = 0.0  # 效果数值
@export var duration: float = 0.0  # 持续时间
@export var cooldown: float = 0.0  # 冷却时间
@export var vfx_prefab: PackedScene = null  # 使用时的特效
@export var usable_in_combat: bool = true  # 是否可在战斗中使用
@export var usable_out_of_combat: bool = true  # 是否可在战斗外使用

# 构造函数
func _init(p_id: String = "", p_name: String = "", p_description: String = ""):
	super._init(p_id, p_name, p_description)
	effect_type = EffectType.HEAL_HP
	effect_value = 0.0
	duration = 0.0
	cooldown = 0.0

# 重写获取物品类型
func get_item_type() -> String:
	return "Consumable"

# 验证消耗品数据完整性
func validate() -> bool:
	var base_valid = super.validate()
	return base_valid and effect_type >= 0

# 获取效果类型名称
func get_effect_type_name() -> String:
	match effect_type:
		EffectType.HEAL_HP:
			return "生命恢复"
		EffectType.RESTORE_MANA:
			return "内力恢复"
		EffectType.BUFF_TEMP:
			return "临时增益"
		EffectType.STATUS_CURE:
			return "状态治愈"
		EffectType.ATTRIBUTE_BOOST:
			return "属性提升"
		_:
			return "未知效果"

# 应用效果（虚拟方法，具体实现在游戏逻辑中）
func apply_effect(target):
	# 这个方法将在游戏逻辑中被具体实现
	print("Applying effect: ", get_effect_type_name(), " with value: ", effect_value)