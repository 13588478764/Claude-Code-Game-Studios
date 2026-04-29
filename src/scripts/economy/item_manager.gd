## ItemManager
## ItemManager
item manager
经济系统模块
武侠奇遇录 - 物品管理器
负责管理玩家的物品库存，包括洗髓丹等特殊物品
##
## 主要功能：
## - 待补充

extends Node

class_name ItemManager

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

# 物品类型常量
const ITEM_WASH_MARROW_PILL = "wash_marrow_pill"  # 洗髓丹

# 玩家物品库存
var inventory = {
	ITEM_WASH_MARROW_PILL: 0
}

func _ready():
	# 初始化物品管理器
	pass

func add_item(item_id, quantity=1):
	"""添加物品到库存"""
	if inventory.has(item_id):
		inventory[item_id] += quantity
	else:
		inventory[item_id] = quantity

func remove_item(item_id, quantity=1):
	"""从库存中移除物品"""
	if inventory.has(item_id) and inventory[item_id] >= quantity:
		inventory[item_id] -= quantity
		return true
	return false

func has_item(item_id, quantity=1):
	"""检查是否拥有指定数量的物品"""
	return inventory.has(item_id) and inventory[item_id] >= quantity

func get_item_count(item_id):
	"""获取指定物品的数量"""
	if inventory.has(item_id):
		return inventory[item_id]
	return 0

# 调试函数
func debug_print_inventory():
	"""打印物品库存用于调试"""
	print("=== 物品库存 ===")
	for item_id in inventory:
		print("%s: %d" % [item_id, inventory[item_id]])
	print("================")