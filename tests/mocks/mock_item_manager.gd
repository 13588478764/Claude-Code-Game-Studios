extends Node
## MockItemManager
## 用于测试的ItemManager模拟类

const ITEM_WASH_MARROW_PILL = "wash_marrow_pill"

var items = {}

func add_item(item_id: String, count: int) -> bool:
	if not items.has(item_id):
		items[item_id] = 0
	items[item_id] += count
	return true

func remove_item(item_id: String, count: int) -> bool:
	if not items.has(item_id):
		return false
	if items[item_id] < count:
		return false
	items[item_id] -= count
	return true

func get_item_count(item_id: String) -> int:
	return items.get(item_id, 0)