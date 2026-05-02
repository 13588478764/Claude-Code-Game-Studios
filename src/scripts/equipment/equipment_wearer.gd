## EquipmentWearer
## 装备穿戴器
## 负责管理装备穿戴、卸下、兼容性验证和外观渲染

extends Node

class_name EquipmentWearer

# 装备槽位枚举
enum EquipmentSlot {
	WEAPON_MAIN,
	WEAPON_OFFHAND,
	HEAD,
	BODY,
	HANDS,
	FEET,
	NECKLACE,
	RING_1,
	RING_2,
	BELT
}

# 装备数据类型别名（使用 EquipmentManager 中的 EquipmentInfo）
# 注意：实际使用时通过 EquipmentManager.EquipmentInfo 访问

# 当前装备槽位状态
var equipped_items: Dictionary = {
	"weapon_main": null,
	"weapon_offhand": null,
	"head": null,
	"body": null,
	"hands": null,
	"feet": null,
	"necklace": null,
	"ring_1": null,
	"ring_2": null,
	"belt": null
}

# 信号定义
signal equipment_equipped(equipment_id: String, slot_type: String)
signal equipment_unequipped(slot_type: String)
signal compatibility_validated(equipment_id: String, is_compatible: bool)
signal equipment_visuals_rendered(equipment_id: String)

# 初始化
func _ready():
	print("装备穿戴器已初始化")

# 穿戴装备
func equip_item(equipment_id: String, slot_type: String) -> bool:
	# 获取装备数据
	var equipment_manager = get_equipment_manager()
	if not equipment_manager:
		print("错误：无法获取装备管理器")
		return false
	
	var equipment = equipment_manager.get_equipment_by_id(equipment_id)
	if not equipment:
		print("错误：装备不存在 - ", equipment_id)
		return false
	
	# 验证兼容性
	if not validate_compatibility(equipment_id, slot_type):
		print("错误：装备与槽位不兼容")
		return false
	
	# 检查槽位是否已占用
	if equipped_items.has(slot_type) and equipped_items[slot_type] != null:
		# 先卸下当前装备
		unequip_item(slot_type)
	
	# 将装备添加到对应槽位
	equipped_items[slot_type] = equipment
	
	# 从背包中移除装备（如果是从背包穿戴的）
	equipment_manager.remove_equipment(equipment_id)
	
	emit_signal("equipment_equipped", equipment_id, slot_type)
	
	# 渲染装备外观
	render_equipment_visuals()
	
	return true

# 卸下装备
func unequip_item(slot_type: String) -> bool:
	if not equipped_items.has(slot_type):
		print("错误：无效的槽位类型 - ", slot_type)
		return false
	
	var equipment = equipped_items[slot_type]
	if not equipment:
		print("错误：槽位为空 - ", slot_type)
		return false
	
	# 获取装备管理器并添加装备回背包
	var equipment_manager = get_equipment_manager()
	if equipment_manager:
		equipment_manager.add_equipment(equipment)
	
	# 清空槽位
	equipped_items[slot_type] = null
	
	emit_signal("equipment_unequipped", slot_type)
	
	# 重新渲染装备外观
	render_equipment_visuals()
	
	return true

# 验证兼容性
func validate_compatibility(equipment_id: String, slot_type: String) -> bool:
	var equipment_manager = get_equipment_manager()
	if not equipment_manager:
		return false
	
	var equipment = equipment_manager.get_equipment_by_id(equipment_id)
	if not equipment:
		return false
	
	# 检查装备槽位是否匹配
	if equipment.slot != slot_type:
		emit_signal("compatibility_validated", equipment_id, false)
		return false
	
	# 检查角色等级限制（如果有的话）
	# 这里可以添加角色等级检查逻辑
	
	# 检查武学流派兼容性（武器类型）
	if equipment.type == "weapon":
		if not validate_weapon_school_compatibility(equipment, slot_type):
			emit_signal("compatibility_validated", equipment_id, false)
			return false
	
	emit_signal("compatibility_validated", equipment_id, true)
	return true

# 验证武器与武学流派兼容性
func validate_weapon_school_compatibility(equipment, slot_type: String) -> bool:
	# 这里可以实现具体的武器与武学流派兼容性检查
	# 例如：剑类武器只能装备在剑法流派下
	if equipment.name.find("剑") != -1:
		# 检查当前是否为剑法流派
		# 这里简化为总是返回true，实际实现需要检查当前武学流派
		return true
	
	return true

# 获取当前已装备的装备
func get_equipped_item(slot_type: String):
	return equipped_items.get(slot_type, null)

# 获取所有已装备的装备
func get_all_equipped_items() -> Dictionary:
	return equipped_items.duplicate()

# 获取装备管理器引用
func get_equipment_manager():
	# 尝试获取场景中的EquipmentManager节点
	var equipment_manager = get_tree().get_first_node_in_group("equipment_manager")
	if equipment_manager:
		return equipment_manager
	
	# 如果没有找到，尝试通过其他方式获取
	# 这里可以实现其他获取方式
	return null

# 处理装备外观渲染
func render_equipment_visuals():
	# 这里应该处理3D模型的挂载和渲染
	# 由于这是一个脚本文件，我们只模拟这个过程
	print("渲染装备外观...")
	
	for slot in equipped_items:
		var equipment = equipped_items[slot]
		if equipment:
			print("  - 槽位: ", slot, ", 装备: ", equipment.name)
	
	emit_signal("equipment_visuals_rendered", "all_equipment")

# 获取装备槽位管理
func get_equipment_slots() -> Dictionary:
	return equipped_items

# 检查指定槽位是否已装备
func is_slot_occupied(slot_type: String) -> bool:
	return equipped_items.has(slot_type) and equipped_items[slot_type] != null

# 批量穿戴装备
func equip_multiple_items(equipment_list: Array) -> Array:
	var results = []
	
	for item in equipment_list:
		var equipment_id = item.get("id", "")
		var slot_type = item.get("slot", "")
		var result = equip_item(equipment_id, slot_type)
		results.append({"id": equipment_id, "slot": slot_type, "success": result})
	
	return results

# 批量卸下装备
func unequip_multiple_items(slot_list: Array) -> Array:
	var results = []
	
	for slot_type in slot_list:
		var result = unequip_item(slot_type)
		results.append({"slot": slot_type, "success": result})
	
	return results

# 获取装备统计信息
func get_equipment_stats() -> Dictionary:
	var stats = {
		"total_equipped": 0,
		"by_tier": {1: 0, 2: 0, 3: 0, 4: 0},
		"by_type": {"weapon": 0, "armor": 0, "accessory": 0}
	}
	
	for slot in equipped_items:
		var equipment = equipped_items[slot]
		if equipment:
			stats.total_equipped += 1
			stats.by_tier[equipment.tier] += 1
			stats.by_type[equipment.type] += 1
	
	return stats

# 测试函数
func test_equipment_wearing():
	print("开始测试装备穿戴系统...")
	
	# 这里可以添加测试代码
	# 由于需要与其他系统交互，实际测试可能需要在游戏环境中运行
	
	print("装备穿戴系统测试完成")