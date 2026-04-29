## EquipmentManager
## 装备管理器
负责管理玩家的装备获取、存储、筛选、排序、拆解和绑定功能
##
## 主要功能：
## - 待补充

extends Node

class_name EquipmentManager

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

# 装备数据结构
class EquipmentData:
	var id: String
	var name: String
	var type: String  # weapon, armor, accessory
	var slot: String  # weapon_main, weapon_offhand, head, body, hands, feet, necklace, ring_1, ring_2, belt
	var tier: int  # 1=普通, 2=稀有, 3=史诗, 4=传说
	var base_attributes: Dictionary
	var enhancement_level: int
	var gems: Array
	var is_bound: bool
	var acquisition_source: String  # drop, craft, quest, shop
	
	func _init(p_id: String, p_name: String, p_type: String, p_slot: String):
		id = p_id
		name = p_name
		type = p_type
		slot = p_slot
		tier = 1
		base_attributes = {}
		enhancement_level = 0
		gems = []
		is_bound = false
		acquisition_source = "unknown"

# 信号定义
signal equipment_changed(equipment_id: String, change_type: String)
signal equipment_added(equipment: EquipmentData)
signal equipment_removed(equipment_id: String)
signal equipment_disassembled(equipment_id: String, resources_gained: Dictionary)

# 装备背包（存储所有装备）
var equipment_inventory: Array[EquipmentData] = []

# 初始化
func _ready():
	print("装备管理器已初始化")

# 添加装备到背包
func add_equipment(equipment_data: EquipmentData) -> bool:
	if equipment_data:
		equipment_inventory.append(equipment_data)
		emit_signal("equipment_added", equipment_data)
		emit_signal("equipment_changed", equipment_data.id, "added")
		return true
	return false

# 从背包移除装备
func remove_equipment(equipment_id: String) -> EquipmentData:
	for i in range(equipment_inventory.size()):
		if equipment_inventory[i].id == equipment_id:
			var equipment = equipment_inventory.pop_at(i)
			emit_signal("equipment_removed", equipment_id)
			emit_signal("equipment_changed", equipment_id, "removed")
			return equipment
	return null

# 根据过滤条件获取装备
func get_equipment_by_filter(filter_params: Dictionary) -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []
	
	for equipment in equipment_inventory:
		var matches = true
		
		# 检查品阶过滤
		if filter_params.has("tier") and equipment.tier != filter_params.tier:
			matches = false
		
		# 检查类型过滤
		if filter_params.has("type") and equipment.type != filter_params.type:
			matches = false
		
		# 检查槽位过滤
		if filter_params.has("slot") and equipment.slot != filter_params.slot:
			matches = false
		
		# 检查绑定状态过滤
		if filter_params.has("is_bound") and equipment.is_bound != filter_params.is_bound:
			matches = false
		
		if matches:
			result.append(equipment)
	
	return result

# 排序装备
func sort_equipment(sort_params: Dictionary) -> Array[EquipmentData]:
	var sorted_list = equipment_inventory.duplicate()
	
	# 根据不同参数排序
	if sort_params.has("by_attribute"):
		var attr = sort_params.by_attribute
		sorted_list.sort_custom(Callable(self, "_sort_by_attribute"), attr)
	elif sort_params.has("by_tier"):
		sorted_list.sort_custom(Callable(self, "_sort_by_tier"))
	elif sort_params.has("by_name"):
		sorted_list.sort_custom(Callable(self, "_sort_by_name"))
	
	return sorted_list

# 排序辅助函数
func _sort_by_attribute(a: EquipmentData, b: EquipmentData, attr_name: String) -> bool:
	var a_value = a.base_attributes.get(attr_name, 0)
	var b_value = b.base_attributes.get(attr_name, 0)
	return a_value > b_value

func _sort_by_tier(a: EquipmentData, b: EquipmentData) -> bool:
	return a.tier > b.tier

func _sort_by_name(a: EquipmentData, b: EquipmentData) -> bool:
	return a.name < b.name

# 拆解装备
func disassemble_equipment(equipment_id: String) -> Dictionary:
	for i in range(equipment_inventory.size()):
		if equipment_inventory[i].id == equipment_id:
			var equipment = equipment_inventory[i]
			
			# 计算拆解返还的资源
			var resources = _calculate_disassembly_resources(equipment)
			
			# 从背包移除装备
			equipment_inventory.remove_at(i)
			
			emit_signal("equipment_disassembled", equipment_id, resources)
			emit_signal("equipment_changed", equipment_id, "disassembled")
			
			return resources
	
	return {}

# 计算拆解资源
func _calculate_disassembly_resources(equipment: EquipmentData) -> Dictionary:
	var resources = {
		"refinement_stone": 0,
		"gem_slot_drill": 0,
		"silver": 0
	}
	
	# 根据装备品阶和强化等级计算返还资源
	resources.refinement_stone = equipment.tier * (equipment.enhancement_level + 1)
	resources.gem_slot_drill = max(0, equipment.tier - 2)  # 高品阶装备可能返还打孔钻
	resources.silver = equipment.tier * 100 * (equipment.enhancement_level + 1)
	
	return resources

# 绑定装备
func bind_equipment(equipment_id: String) -> bool:
	for equipment in equipment_inventory:
		if equipment.id == equipment_id:
			equipment.is_bound = true
			emit_signal("equipment_changed", equipment_id, "bound")
			return true
	return false

# 获取背包中装备数量
func get_equipment_count() -> int:
	return equipment_inventory.size()

# 获取指定ID的装备
func get_equipment_by_id(equipment_id: String) -> EquipmentData:
	for equipment in equipment_inventory:
		if equipment.id == equipment_id:
			return equipment
	return null

# 获取指定槽位的装备
func get_equipment_by_slot(slot_type: String) -> EquipmentData:
	for equipment in equipment_inventory:
		if equipment.slot == slot_type:
			return equipment
	return null

# 更新装备强化等级
func update_equipment_enhancement(equipment_id: String, new_level: int) -> bool:
	for equipment in equipment_inventory:
		if equipment.id == equipment_id:
			equipment.enhancement_level = new_level
			emit_signal("equipment_changed", equipment_id, "enhanced")
			return true
	return false

# 镶嵌宝石
func insert_gem(equipment_id: String, gem_data: Dictionary) -> bool:
	for equipment in equipment_inventory:
		if equipment.id == equipment_id:
			if equipment.gems.size() < 3:  # 最多3个宝石孔
				equipment.gems.append(gem_data)
				emit_signal("equipment_changed", equipment_id, "gem_inserted")
				return true
	return false

# 移除宝石
func remove_gem(equipment_id: String, gem_index: int) -> bool:
	for equipment in equipment_inventory:
		if equipment.id == equipment_id:
			if gem_index < equipment.gems.size():
				equipment.gems.remove_at(gem_index)
				emit_signal("equipment_changed", equipment_id, "gem_removed")
				return true
	return false

# 测试函数
func test_equipment_management():
	print("开始测试装备管理功能...")
	
	# 创建测试装备
	var test_sword = EquipmentData.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 添加装备
	var add_result = add_equipment(test_sword)
	if add_result:
		print("✅ 装备添加功能正常")
	else:
		print("❌ 装备添加功能异常")
	
	# 获取装备
	var retrieved_equipment = get_equipment_by_id("sword_001")
	if retrieved_equipment:
		print("✅ 装备获取功能正常")
	else:
		print("❌ 装备获取功能异常")
	
	# 过滤测试
	var tier2_items = get_equipment_by_filter({"tier": 2})
	if tier2_items.size() > 0:
		print("✅ 装备筛选功能正常")
	else:
		print("❌ 装备筛选功能异常")
	
	# 拆解测试
	var disassemble_result = disassemble_equipment("sword_001")
	if disassemble_result.size() > 0:
		print("✅ 装备拆解功能正常")
	else:
		print("❌ 装备拆解功能异常")
	
	print("装备管理功能测试完成")