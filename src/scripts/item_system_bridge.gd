## 道具系统桥接器 / 背包管理
## 负责物品的增删改查、元数据查找、与货币系统联动
## Autoload 名称: InventorySystem

extends Node

# ============================================================================
# 常量定义
# ============================================================================

const ITEMS_DATA_PATH: String = "res://src/data/items.json"
const LOG_PREFIX: String = "[InventorySystem]"
const MAX_INVENTORY_SIZE: int = 50

# ============================================================================
# 信号定义
# ============================================================================

## 道具被使用信号
signal item_used(item_id: String, user: Node)
## 道具从背包移除信号
signal item_removed_from_inventory(item_id: String, count: int)
## 道具添加到背包信号
signal item_added_to_inventory(item_id: String, count: int)
## 背包已满信号
signal inventory_full
## 装备变更信号
signal equipment_changed(slot_id: String, item_id: String)

# ============================================================================
# 成员变量
# ============================================================================

## 背包: item_id → 数量
var inventory: Dictionary = {}
## 装备槽位: slot_id → item_id (空为 "")
var equipped_slots: Dictionary = {
	"weapon_main": "",
	"weapon_offhand": "",
	"head": "",
	"body": "",
	"hands": "",
	"feet": "",
	"necklace": "",
	"ring_1": "",
	"ring_2": "",
}
## 物品元数据库: item_id → 完整物品数据 (从 items.json 加载)
var _item_database: Dictionary = {}

# ============================================================================
# 生命周期方法
# ============================================================================

func _ready() -> void:
	_load_item_database()


# ============================================================================
# 公共方法 - 背包操作
# ============================================================================

## 添加道具到背包
func add_item(item_id: String, count: int = 1) -> bool:
	if item_id.is_empty() or count <= 0:
		return false

	var total_items = _get_total_item_count()
	if total_items + count > MAX_INVENTORY_SIZE:
		push_warning("%s 背包容量不足 (当前: %d, 最大: %d)" % [LOG_PREFIX, total_items, MAX_INVENTORY_SIZE])
		inventory_full.emit()
		return false

	if not inventory.has(item_id):
		inventory[item_id] = 0
	inventory[item_id] += count

	item_added_to_inventory.emit(item_id, count)
	return true


## 移除道具
func remove_item(item_id: String, count: int = 1) -> bool:
	if item_id.is_empty() or count <= 0:
		return false

	if not inventory.has(item_id) or inventory[item_id] < count:
		return false

	inventory[item_id] -= count
	if inventory[item_id] <= 0:
		inventory.erase(item_id)

	item_removed_from_inventory.emit(item_id, count)
	return true


## 使用道具（自动执行消耗品效果）
func use_item(item_id: String, user: Node = null) -> bool:
	if not has_item(item_id):
		return false

	var item_data := get_item_data(item_id)
	if item_data.get("type", "") != "consumable":
		push_warning("%s 物品 %s 不是消耗品，无法使用" % [LOG_PREFIX, item_id])
		return false

	var effect: Dictionary = item_data.get("consumable_effect", {})
	if effect.is_empty():
		push_warning("%s 消耗品 %s 没有定义效果" % [LOG_PREFIX, item_id])
		return false

	_apply_consumable_effect(item_id, effect)
	item_used.emit(item_id, user)
	remove_item(item_id, 1)
	return true


## 执行消耗品效果
func _apply_consumable_effect(item_id: String, effect: Dictionary) -> void:
	var effect_type: String = effect.get("type", "")
	var value: int = int(effect.get("value", 0))

	var char_sys = get_node_or_null("/root/CharacterSystem")
	var currency_mgr = get_node_or_null("/root/CurrencyManager")

	match effect_type:
		"heal":
			if char_sys and char_sys.attributes:
				var max_hp: int = char_sys.attributes.constitution * 10
				print("%s 使用 %s：恢复 %d 生命值" % [LOG_PREFIX, item_id, value])
		"exp_boost":
			if char_sys and char_sys.has_method("add_experience"):
				char_sys.add_experience(value)
				print("%s 使用 %s：获得 %d 经验" % [LOG_PREFIX, item_id, value])
		"breakthrough":
			if char_sys and char_sys.has_method("breakthrough_realm"):
				var old_realm: int = char_sys.realm_index
				char_sys.breakthrough_realm()
				if char_sys.realm_index > old_realm:
					print("%s 使用 %s：境界突破成功！" % [LOG_PREFIX, item_id])
				else:
					print("%s 使用 %s：已达最高境界" % [LOG_PREFIX, item_id])
					add_item(item_id, 1)
		"reset_attributes":
			if char_sys and char_sys.has_method("reset_attributes"):
				char_sys.reset_attributes()
				print("%s 使用 %s：属性点已重置" % [LOG_PREFIX, item_id])
		"random":
			var rand_value: int = randi_range(int(value * 0.5), int(value * 1.5))
			if char_sys and char_sys.has_method("add_experience"):
				char_sys.add_experience(rand_value)
				print("%s 使用 %s：随机获得 %d 经验" % [LOG_PREFIX, item_id, rand_value])
		_:
			print("%s 未知消耗品效果类型: %s" % [LOG_PREFIX, effect_type])


## 出售道具（联动 CurrencyManager 增加银两）
func sell_item(item_id: String, count: int = 1) -> bool:
	if not has_item(item_id, count):
		return false

	var item_data = get_item_data(item_id)
	var unit_price: int = item_data.get("value_gold", 0)
	var total_price: int = unit_price * count

	if not remove_item(item_id, count):
		return false

	# 联动货币系统
	var currency_mgr = get_node_or_null("/root/CurrencyManager")
	if currency_mgr:
		currency_mgr.add_currency(currency_mgr.CurrencyType.SILVER, total_price)

	return true


## 检查是否拥有指定数量的物品
func has_item(item_id: String, count: int = 1) -> bool:
	return inventory.has(item_id) and inventory[item_id] >= count


## 获取指定物品的数量
func get_item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)


## 获取背包中所有物品（含元数据+数量），供 UI 显示
func get_all_items_with_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in inventory:
		if inventory[item_id] <= 0:
			continue
		var data = get_item_data(item_id)
		data["quantity"] = inventory[item_id]
		result.append(data)
	return result


## 获取背包总物品种类数
func get_item_slot_count() -> int:
	return inventory.size()


## 清空背包
func clear_inventory() -> void:
	inventory.clear()


## 获取背包字典的副本
func get_inventory() -> Dictionary:
	return inventory.duplicate()


# ============================================================================
# 公共方法 - 装备管理
# ============================================================================

## 装备物品到指定槽位
func equip_item(item_id: String, slot_id: String) -> bool:
	if item_id.is_empty() or not equipped_slots.has(slot_id):
		return false

	if not has_item(item_id):
		return false

	# 如果槽位已有装备，先卸下
	if not equipped_slots[slot_id].is_empty():
		unequip_item(slot_id)

	# 从背包移除，放入槽位
	if not remove_item(item_id, 1):
		return false

	equipped_slots[slot_id] = item_id
	equipment_changed.emit(slot_id, item_id)
	return true


## 卸下指定槽位装备（放回背包）
func unequip_item(slot_id: String) -> bool:
	if not equipped_slots.has(slot_id):
		return false

	var item_id = equipped_slots[slot_id]
	if item_id.is_empty():
		return false

	equipped_slots[slot_id] = ""
	add_item(item_id, 1)
	equipment_changed.emit(slot_id, "")
	return true


## 获取所有已装备物品数据（slot_id → item_data dict, 空槽为null）
func get_equipped_items_data() -> Dictionary:
	var result: Dictionary = {}
	for slot_id in equipped_slots:
		var item_id = equipped_slots[slot_id]
		if item_id.is_empty():
			result[slot_id] = null
		else:
			var data = get_item_data(item_id)
			result[slot_id] = data
	return result


## 获取指定槽位装备数据
func get_equipped_item_in_slot(slot_id: String) -> Dictionary:
	if not equipped_slots.has(slot_id):
		return {}
	var item_id = equipped_slots[slot_id]
	if item_id.is_empty():
		return {}
	return get_item_data(item_id)


## 计算装备总战力
func get_equipment_power_score() -> int:
	var power: int = 0
	for slot_id in equipped_slots:
		var item_id = equipped_slots[slot_id]
		if item_id.is_empty():
			continue
		var data = get_item_data(item_id)
		if data.has("attributes"):
			var attrs = data.attributes
			if attrs.has("combat"):
				for stat in attrs.combat:
					var val = attrs.combat[stat]
					if val is float:
						power += int(val * 100)
					else:
						power += int(val)
			if attrs.has("base"):
				for stat in attrs.base:
					power += int(attrs.base[stat]) * 2
	return power


# ============================================================================
# 公共方法 - 物品数据库
# ============================================================================

## 获取物品元数据（从 items.json）
func get_item_data(item_id: String) -> Dictionary:
	if _item_database.has(item_id):
		return _item_database[item_id].duplicate()
	# 未在数据库中的物品，返回基本信息
	return {
		"id": item_id,
		"name": item_id,
		"description": "",
		"tier": "common",
		"type": "material",
		"value_gold": 0,
	}


## 检查物品是否存在于数据库
func has_item_in_database(item_id: String) -> bool:
	return _item_database.has(item_id)


# ============================================================================
# 私有方法
# ============================================================================

## 加载物品数据库
func _load_item_database() -> void:
	if not FileAccess.file_exists(ITEMS_DATA_PATH):
		push_warning("%s 物品数据文件不存在: %s" % [LOG_PREFIX, ITEMS_DATA_PATH])
		return

	var file = FileAccess.open(ITEMS_DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("%s 无法打开物品数据文件" % LOG_PREFIX)
		return

	var json_text = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)
	if parsed == null or not (parsed is Dictionary):
		push_warning("%s 物品数据解析失败" % LOG_PREFIX)
		return

	_item_database = parsed
	print("%s 加载了 %d 个物品定义" % [LOG_PREFIX, _item_database.size()])


## 获取背包内物品总数量（按个计算）
func _get_total_item_count() -> int:
	var total: int = 0
	for count in inventory.values():
		total += count
	return total
