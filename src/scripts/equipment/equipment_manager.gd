# 武侠奇遇录 - 装备管理系统
# 实现装备获取、存储、筛选、排序、拆解和绑定机制

extends Node

# 信号定义
signal equipment_added(equipment_id, quantity)
signal equipment_removed(equipment_id, quantity)
signal equipment_changed(equipment_id, change_type)
signal equipment_bound(equipment_id)

# 装备品阶枚举
enum EquipmentRarity {
	COMMON,      # 普通(白)
	UNCOMMON,    # 稀有(蓝)
	RARE,        # 史诗(紫)
	LEGENDARY    # 传说(金)
}

# 装备类型枚举
enum EquipmentType {
	WEAPON_MAIN_HAND,    # 主手武器
	WEAPON_OFF_HAND,     # 副手/离手
	HELMET,              # 头饰
	ARMOR,               # 衣袍
	GLOVES,              # 护手
	BOOTS,               # 靴子
	NECKLACE,            # 项链
	RING_LEFT,           # 左戒指
	RING_RIGHT,          # 右戒指
	WAIST,               # 腰带
	COSMETIC_HEAD,       # 头部外观
	COSMETIC_BODY,       # 身体外观
	COSMETIC_WEAPON      # 武器外观
}

# 装备槽位枚举
enum EquipmentSlot {
	MAIN_HAND,
	OFF_HAND,
	HEAD,
	BODY,
	HANDS,
	FEET,
	NECKLACE,
	RING_LEFT,
	RING_RIGHT,
	WAIST
}

# 装备数据结构
class EquipmentData:
	var id: String
	var name: String
	var type: EquipmentType
	var rarity: EquipmentRarity
	var level_requirement: int
	var attributes: Dictionary  # 基础属性
	var enhancement_level: int
	var gems: Array  # 镶嵌的宝石
	var is_bound: bool
	var acquisition_source: String  # 获取来源
	var additional_affixes: Array  # 附加词条
	
	func _init(p_id: String, p_name: String, p_type: EquipmentType, p_rarity: EquipmentRarity):
		id = p_id
		name = p_name
		type = p_type
		rarity = p_rarity
		level_requirement = 1
		attributes = {}
		enhancement_level = 0
		gems = []
		is_bound = false
		acquisition_source = "unknown"
		additional_affixes = []

# 背包容量
const MAX_BACKPACK_SIZE = 60

# 状态变量
var backpack: Array[EquipmentData] = []  # 背包中的装备
var equipped_items: Dictionary = {}  # 已装备的装备，键为EquipmentSlot

func _ready():
	print("装备管理系统初始化完成")

# 添加装备到背包
func add_equipment(equipment_data: EquipmentData) -> bool:
	if backpack.size() >= MAX_BACKPACK_SIZE:
		print("背包已满，无法添加装备: %s" % equipment_data.name)
		return false
	
	backpack.append(equipment_data)
	emit_signal("equipment_added", equipment_data.id, 1)
	emit_signal("equipment_changed", equipment_data.id, "added")
	return true

# 从背包移除装备
func remove_equipment(equipment_id: String) -> bool:
	for i in range(backpack.size()):
		if backpack[i].id == equipment_id:
			var removed_equipment = backpack.pop_at(i)
			emit_signal("equipment_removed", removed_equipment.id, 1)
			emit_signal("equipment_changed", removed_equipment.id, "removed")
			return true
	
	print("未找到ID为 %s 的装备" % equipment_id)
	return false

# 根据过滤条件获取装备
func get_equipment_by_filter(filter_params: Dictionary) -> Array[EquipmentData]:
	var filtered_equipment = []
	
	for equipment in backpack:
		var match = true
		
		# 检查品阶过滤
		if filter_params.has("rarity") and equipment.rarity != filter_params.rarity:
			match = false
		
		# 检查类型过滤
		if filter_params.has("type") and equipment.type != filter_params.type:
			match = false
		
		# 检查等级过滤
		if filter_params.has("min_level") and equipment.level_requirement < filter_params.min_level:
			match = false
		
		if filter_params.has("max_level") and equipment.level_requirement > filter_params.max_level:
			match = false
		
		# 检查绑定状态
		if filter_params.has("bound_only") and filter_params.bound_only != equipment.is_bound:
			match = false
		
		if match:
			filtered_equipment.append(equipment)
	
	return filtered_equipment

# 根据参数排序装备
func sort_equipment(sort_params: Dictionary) -> Array[EquipmentData]:
	var sorted_equipment = backpack.duplicate()
	
	# 默认按品阶和等级排序
	sorted_equipment.sort_custom(func(a, b):
		# 首先按品阶排序（从高到低）
		if a.rarity != b.rarity:
			return a.rarity > b.rarity
		
		# 然后按强化等级排序（从高到低）
		if a.enhancement_level != b.enhancement_level:
			return a.enhancement_level > b.enhancement_level
		
		# 最后按等级需求排序（从高到低）
		return a.level_requirement > b.level_requirement
	)
	
	return sorted_equipment

# 拆解装备
func disassemble_equipment(equipment_id: String) -> Dictionary:
	var result = {
		"success": false,
		"materials_gained": {},
		"message": ""
	}
	
	# 查找装备
	var equipment_to_disassemble: EquipmentData = null
	var equipment_index = -1
	
	for i in range(backpack.size()):
		if backpack[i].id == equipment_id:
			equipment_to_disassemble = backpack[i]
			equipment_index = i
			break
	
	if not equipment_to_disassemble:
		result.message = "未找到要拆解的装备"
		return result
	
	# 计算拆解获得的材料
	var materials_gained = calculate_disassembly_rewards(equipment_to_disassemble)
	
	# 从背包中移除装备
	backpack.remove_at(equipment_index)
	
	# 发送信号
	emit_signal("equipment_removed", equipment_to_disassemble.id, 1)
	emit_signal("equipment_changed", equipment_to_disassemble.id, "disassembled")
	
	result.success = true
	result.materials_gained = materials_gained
	result.message = "装备拆解成功"
	
	return result

# 计算拆解奖励
func calculate_disassembly_rewards(equipment: EquipmentData) -> Dictionary:
	var rewards = {}
	
	# 基础材料奖励
	rewards["enhancement_stones"] = max(1, equipment.rarity + 1)  # 品阶越高，获得强化石越多
	rewards["gem_dust"] = max(1, int(equipment.rarity / 2) + 1)  # 宝石粉尘
	rewards["silver"] = max(10, (equipment.rarity + 1) * 50)  # 银两
	
	# 根据强化等级增加奖励
	rewards["enhancement_stones"] += equipment.enhancement_level * 2
	rewards["silver"] += equipment.enhancement_level * 10
	
	# 根据镶嵌的宝石增加奖励
	rewards["gem_dust"] += equipment.gems.size() * 3
	
	return rewards

# 绑定装备
func bind_equipment(equipment_id: String) -> bool:
	for equipment in backpack:
		if equipment.id == equipment_id:
			if equipment.is_bound:
				print("装备 %s 已经是绑定状态" % equipment.name)
				return false
			
			equipment.is_bound = true
			emit_signal("equipment_bound", equipment_id)
			emit_signal("equipment_changed", equipment_id, "bound")
			return true
	
	print("未找到ID为 %s 的装备" % equipment_id)
	return false

# 获取背包中装备的数量
func get_backpack_size() -> int:
	return backpack.size()

# 获取背包容量
func get_max_backpack_size() -> int:
	return MAX_BACKPACK_SIZE

# 检查背包是否已满
func is_backpack_full() -> bool:
	return backpack.size() >= MAX_BACKPACK_SIZE

# 获取指定类型的装备数量
func get_equipment_count_by_type(equipment_type: EquipmentType) -> int:
	var count = 0
	for equipment in backpack:
		if equipment.type == equipment_type:
			count += 1
	return count

# 获取指定品阶的装备数量
func get_equipment_count_by_rarity(equipment_rarity: EquipmentRarity) -> int:
	var count = 0
	for equipment in backpack:
		if equipment.rarity == equipment_rarity:
			count += 1
	return count

# 获取背包中所有装备
func get_all_equipment() -> Array[EquipmentData]:
	return backpack.duplicate()

# 查找特定装备
func find_equipment_by_id(equipment_id: String) -> EquipmentData:
	for equipment in backpack:
		if equipment.id == equipment_id:
			return equipment
	return null

# 获取装备信息摘要
func get_equipment_summary() -> Dictionary:
	return {
		"total_count": backpack.size(),
		"common_count": get_equipment_count_by_rarity(EquipmentRarity.COMMON),
		"uncommon_count": get_equipment_count_by_rarity(EquipmentRarity.UNCOMMON),
		"rare_count": get_equipment_count_by_rarity(EquipmentRarity.RARE),
		"legendary_count": get_equipment_count_by_rarity(EquipmentRarity.LEGENDARY),
		"space_remaining": MAX_BACKPACK_SIZE - backpack.size()
	}

# 批量添加装备
func add_multiple_equipment(equipment_list: Array[EquipmentData]) -> Dictionary:
	var result = {
		"added_count": 0,
		"failed_count": 0,
		"messages": []
	}
	
	for equipment in equipment_list:
		if add_equipment(equipment):
			result.added_count += 1
		else:
			result.failed_count += 1
			result.messages.append("无法添加装备: %s" % equipment.name)
	
	return result

# 保存装备数据
func save_equipment_data() -> Dictionary:
	var save_data = {
		"backpack": [],
		"equipped_items": {}
	}
	
	# 保存背包数据
	for equipment in backpack:
		var equip_data = {
			"id": equipment.id,
			"name": equipment.name,
			"type": equipment.type,
			"rarity": equipment.rarity,
			"level_requirement": equipment.level_requirement,
			"attributes": equipment.attributes,
			"enhancement_level": equipment.enhancement_level,
			"gems": equipment.gems,
			"is_bound": equipment.is_bound,
			"acquisition_source": equipment.acquisition_source,
			"additional_affixes": equipment.additional_affixes
		}
		save_data.backpack.append(equip_data)
	
	# 保存已装备数据
	for slot in equipped_items:
		if equipped_items[slot] != null:
			save_data.equipped_items[slot] = equipped_items[slot].id
	
	return save_data

# 加载装备数据
func load_equipment_data(save_data: Dictionary):
	# 清空现有数据
	backpack.clear()
	
	# 加载背包数据
	if save_data.has("backpack"):
		for equip_data in save_data.backpack:
			var equipment = EquipmentData.new(
				equip_data.id,
				equip_data.name,
				equip_data.type,
				equip_data.rarity
			)
			equipment.level_requirement = equip_data.level_requirement
			equipment.attributes = equip_data.attributes
			equipment.enhancement_level = equip_data.enhancement_level
			equipment.gems = equip_data.gems
			equipment.is_bound = equip_data.is_bound
			equipment.acquisition_source = equip_data.acquisition_source
			equipment.additional_affixes = equip_data.additional_affixes
			
			backpack.append(equipment)
	
	# 加载已装备数据（需要外部系统提供装备实例）
	if save_data.has("equipped_items"):
		# 这里需要外部系统来实际装备这些物品
		print("待装备的物品: ", save_data.equipped_items)