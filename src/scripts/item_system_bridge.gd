## ItemSystemBridge
## 道具系统桥接器 - 用于状态效果系统与道具系统的解耦通信
## 
## AC6: 道具使用获得状态
## 遵循ADR-001: 使用信号系统实现跨系统通信

extends Node

## 信号: 道具被使用
## @param item_id: 道具ID
## @param user: 使用者节点
signal item_used(item_id: String, user: Node)

## 信号: 道具从背包移除
## @param item_id: 道具ID
## @param count: 移除数量
signal item_removed_from_inventory(item_id: String, count: int)

## 道具ID常量
const ITEM_GOLDEN_WOUND_MEDICINE: String = "golden_wound_medicine"

## 模拟背包(实际应该由道具系统管理)
var inventory: Dictionary = {}

## 初始化
func _ready() -> void:
	# 测试用: 添加一些道具到背包
	inventory[ITEM_GOLDEN_WOUND_MEDICINE] = 3

## AC6: 使用道具
## @param item_id: 道具ID
## @param user: 使用者节点
## @return: 是否成功使用
func use_item(item_id: String, user: Node) -> bool:
	# 检查背包中是否有该道具
	if not inventory.has(item_id) or inventory[item_id] <= 0:
		push_warning("Cannot use item %s: not in inventory or count is 0" % item_id)
		return false
	
	# 发射道具使用信号
	item_used.emit(item_id, user)
	
	# 从背包移除道具
	inventory[item_id] -= 1
	item_removed_from_inventory.emit(item_id, 1)
	
	print("[ItemSystem] Used item: %s, remaining: %d" % [item_id, inventory[item_id]])
	
	return true

## 获取道具数量
## @param item_id: 道具ID
## @return: 数量
func get_item_count(item_id: String) -> int:
	if inventory.has(item_id):
		return inventory[item_id]
	return 0

## 添加道具到背包(测试用)
## @param item_id: 道具ID
## @param count: 数量
func add_item(item_id: String, count: int) -> void:
	if not inventory.has(item_id):
		inventory[item_id] = 0
	inventory[item_id] += count
	print("[ItemSystem] Added item: %s, count: %d, total: %d" % [item_id, count, inventory[item_id]])