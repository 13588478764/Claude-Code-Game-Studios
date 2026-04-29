## ItemData
## item data
##
## 数据定义模块
# ItemData
# 物品数据基类，定义所有物品的通用属性

extends Resource
class_name ItemData

# 通用基础信息
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var rarity: int = 0  # 0: COMMON, 1: RARE, 2: EPIC, 3: LEGENDARY
@export var max_stack: int = 1
@export var vendor_price: int = 0
@export var tags: Array[String] = []

# 物品稀有度枚举
enum Rarity {
	COMMON = 0,
	RARE = 1,
	EPIC = 2,
	LEGENDARY = 3
}

# 构造函数
func _init(p_id: String = "", p_name: String = "", p_description: String = ""):
	id = p_id
	name = p_name
	description = p_description
	tags = []

# 获取稀有度颜色
func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON:
			return Color.WHITE
		Rarity.RARE:
			return Color.BLUE
		Rarity.EPIC:
			return Color.PURPLE
		Rarity.LEGENDARY:
			return Color.GOLD
		_:
			return Color.LIGHT_GRAY

# 获取稀有度名称
func get_rarity_name() -> String:
	match rarity:
		Rarity.COMMON:
			return "普通"
		Rarity.RARE:
			return "稀有"
		Rarity.EPIC:
			return "史诗"
		Rarity.LEGENDARY:
			return "传说"
		_:
			return "未知"

# 验证数据完整性
func validate() -> bool:
	return id != "" and name != ""

# 获取物品类型（子类需重写）
func get_item_type() -> String:
	return "Item"