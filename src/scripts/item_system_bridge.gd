# ItemSystemBridge - 道具系统桥接器
#
# 负责状态效果系统与道具系统的解耦通信
# 遵循 ADR-001: 使用信号系统实现跨系统通信
#
# 信号:
#   - item_used(item_id, user)
#   - item_removed_from_inventory(item_id, count)

extends Node

class_name ItemSystemBridge

# ============================================================================
# 常量定义
# ============================================================================

const ITEM_GOLDEN_WOUND_MEDICINE: String = "golden_wound_medicine"
const LOG_PREFIX: String = "[ItemSystem]"
const MAX_INVENTORY_SIZE: int = 1000

# ============================================================================
# 信号定义
# ============================================================================

## 道具被使用信号
signal item_used(item_id: String, user: Node)

## 道具从背包移除信号
signal item_removed_from_inventory(item_id: String, count: int)

## 道具添加到背包信号
signal item_added_to_inventory(item_id: String, count: int)

# ============================================================================
# 成员变量
# ============================================================================

var inventory: Dictionary = {}  # 背包字典
var debug_enabled: bool = true  # 调试日志开关

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化
func _ready() -> void:
	# 测试用: 添加一些道具到背包
	add_item(ITEM_GOLDEN_WOUND_MEDICINE, 3)

# ============================================================================
# 公共方法
# ============================================================================

## 使用道具
## 参数:
##   - item_id: 道具ID
##   - user: 使用者节点
## 返回: 是否成功使用
func use_item(item_id: String, user: Node) -> bool:
	# 验证输入
	if not item_id or item_id.is_empty():
		push_error("%s item_id 不能为空" % LOG_PREFIX)
		return false
	
	if not user:
		push_error("%s user 不能为空" % LOG_PREFIX)
		return false
	
	# 检查背包中是否有该道具
	if not inventory.has(item_id):
		if debug_enabled:
			print("%s 道具不存在: %s" % [LOG_PREFIX, item_id])
		return false
	
	if inventory[item_id] <= 0:
		if debug_enabled:
			print("%s 道具数量不足: %s (当前: %d)" % [LOG_PREFIX, item_id, inventory[item_id]])
		return false
	
	# 发射道具使用信号
	item_used.emit(item_id, user)
	
	# 从背包移除道具
	inventory[item_id] -= 1
	item_removed_from_inventory.emit(item_id, 1)
	
	if debug_enabled:
		print("%s 使用道具: %s, 剩余: %d" % [LOG_PREFIX, item_id, inventory[item_id]])
	
	return true

## 获取道具数量
## 参数:
##   - item_id: 道具ID
## 返回: 道具数量
func get_item_count(item_id: String) -> int:
	if not item_id or item_id.is_empty():
		push_error("%s item_id 不能为空" % LOG_PREFIX)
		return 0
	
	if inventory.has(item_id):
		return inventory[item_id]
	return 0

## 添加道具到背包
## 参数:
##   - item_id: 道具ID
##   - count: 数量
## 返回: 是否成功添加
func add_item(item_id: String, count: int) -> bool:
	# 验证输入
	if not item_id or item_id.is_empty():
		push_error("%s item_id 不能为空" % LOG_PREFIX)
		return false
	
	if count <= 0:
		push_error("%s count 必须大于 0" % LOG_PREFIX)
		return false
	
	# 检查背包容量
	var total_items = 0
	for item in inventory.values():
		total_items += item
	
	if total_items + count > MAX_INVENTORY_SIZE:
		push_warning("%s 背包容量不足 (当前: %d, 最大: %d)" % [LOG_PREFIX, total_items, MAX_INVENTORY_SIZE])
		return false
	
	# 添加道具
	if not inventory.has(item_id):
		inventory[item_id] = 0
	
	inventory[item_id] += count
	item_added_to_inventory.emit(item_id, count)
	
	if debug_enabled:
		print("%s 添加道具: %s, 数量: %d, 总计: %d" % [LOG_PREFIX, item_id, count, inventory[item_id]])
	
	return true

## 移除道具
## 参数:
##   - item_id: 道具ID
##   - count: 数量
## 返回: 是否成功移除
func remove_item(item_id: String, count: int) -> bool:
	# 验证输入
	if not item_id or item_id.is_empty():
		push_error("%s item_id 不能为空" % LOG_PREFIX)
		return false
	
	if count <= 0:
		push_error("%s count 必须大于 0" % LOG_PREFIX)
		return false
	
	# 检查道具是否存在
	if not inventory.has(item_id) or inventory[item_id] < count:
		if debug_enabled:
			print("%s 道具数量不足: %s (需要: %d, 当前: %d)" % [LOG_PREFIX, item_id, count, get_item_count(item_id)])
		return false
	
	# 移除道具
	inventory[item_id] -= count
	item_removed_from_inventory.emit(item_id, count)
	
	if debug_enabled:
		print("%s 移除道具: %s, 数量: %d, 剩余: %d" % [LOG_PREFIX, item_id, count, inventory[item_id]])
	
	return true

## 清空背包
func clear_inventory() -> void:
	inventory.clear()
	if debug_enabled:
		print("%s 背包已清空" % LOG_PREFIX)

## 获取背包中所有道具
## 返回: 背包字典的副本
func get_inventory() -> Dictionary:
	return inventory.duplicate()

## 设置调试日志开关
## 参数:
##   - enabled: 是否启用调试日志
func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled