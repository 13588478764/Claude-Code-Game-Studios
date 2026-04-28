# EquipmentData
# 装备数据类，继承自ItemData，定义装备特有的属性

extends "item_data.gd"
class_name EquipmentData

# 装备部位枚举
enum EquipmentSlot {
	WEAPON_MAIN,
	WEAPON_OFF,
	ARMOR_HEAD,
	ARMOR_CHEST,
	ARMOR_ARMS,
	ARMOR_LEGS,
	ACCESSORY_RING,
	ACCESSORY_NECKLACE,
	ACCESSORY_BRACELET
}

# 装备特有属性
@export var slot: int = 0  # 装备部位
@export var base_stats: Dictionary = {}  # 基础属性加成
@export var affixes: Array[Dictionary] = []  # 词缀或固定特效
@export var level_requirement: int = 1  # 装备所需等级
@export var model_scene: PackedScene = null  # 3D/2D模型引用
@export var weapon_type: String = ""  # 武器类型（剑、刀、拳等）

# 构造函数
func _init(p_id: String = "", p_name: String = "", p_description: String = ""):
	super._init(p_id, p_name, p_description)
	slot = EquipmentSlot.WEAPON_MAIN
	base_stats = {}
	affixes = []

# 重写获取物品类型
func get_item_type() -> String:
	return "Equipment"

# 获取装备部位名称
func get_slot_name() -> String:
	match slot:
		EquipmentSlot.WEAPON_MAIN:
			return "主手武器"
		EquipmentSlot.WEAPON_OFF:
			return "副手武器"
		EquipmentSlot.ARMOR_HEAD:
			return "头部护甲"
		EquipmentSlot.ARMOR_CHEST:
			return "胸部护甲"
		EquipmentSlot.ARMOR_ARMS:
			return "臂部护甲"
		EquipmentSlot.ARMOR_LEGS:
			return "腿部护甲"
		EquipmentSlot.ACCESSORY_RING:
			return "戒指"
		EquipmentSlot.ACCESSORY_NECKLACE:
			return "项链"
		EquipmentSlot.ACCESSORY_BRACELET:
			return "手镯"
		_:
			return "未知部位"

# 验证装备数据完整性
func validate() -> bool:
	var base_valid = super.validate()
	return base_valid and slot >= 0

# 添加基础属性
func add_base_stat(stat_name: String, stat_value: float):
	base_stats[stat_name] = stat_value

# 获取基础属性值
func get_base_stat(stat_name: String) -> float:
	if base_stats.has(stat_name):
		return base_stats[stat_name]
	return 0.0

# 添加词缀
func add_affix(affix_data: Dictionary):
	affixes.append(affix_data)

# 检查是否满足装备等级要求
func meets_level_requirement(character_level: int) -> bool:
	return character_level >= level_requirement