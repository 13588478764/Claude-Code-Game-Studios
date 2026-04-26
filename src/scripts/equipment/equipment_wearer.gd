# 武侠奇遇录 - 装备穿戴系统
# 实现6+3槽位结构的装备穿戴、兼容性验证和外观渲染

extends Node

# 信号定义
signal equipment_equipped(equipment_id, slot_type)
signal equipment_unequipped(equipment_id, slot_type)
signal compatibility_validated(equipment_id, is_compatible)
signal visuals_rendered

# 装备品阶枚举（与装备管理器保持一致）
enum EquipmentRarity {
	COMMON,      # 普通(白)
	UNCOMMON,    # 稀有(蓝)
	RARE,        # 史诗(紫)
	LEGENDARY    # 传说(金)
}

# 装备类型枚举（与装备管理器保持一致）
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

# 装备数据结构（简化版，只包含穿戴系统需要的信息）
class EquipmentData:
	var id: String
	var name: String
	var type: EquipmentType
	var slot: EquipmentSlot
	var level_requirement: int
	var martial_art_compatibility: Array  # 兼容的武学类型
	var model_path: String  # 3D模型路径
	var texture_path: String  # 材质路径
	
	func _init(p_id: String, p_name: String, p_type: EquipmentType, p_slot: EquipmentSlot):
		id = p_id
		name = p_name
		type = p_type
		slot = p_slot
		level_requirement = 1
		martial_art_compatibility = []
		model_path = ""
		texture_path = ""

# 依赖的其他系统
var equipment_manager = null
var character_model = null
var battle_manager = null
var martial_arts_manager = null

# 已装备的装备
var equipped_items: Dictionary = {}

func _ready():
	print("装备穿戴系统初始化完成")
	initialize_equipped_slots()

# 初始化装备槽位
func initialize_equipped_slots():
	for slot in EquipmentSlot:
		equipped_items[slot] = null

# 设置依赖系统
func set_dependencies(equip_mgr, char_model, battle_mgr, martial_arts_mgr):
	equipment_manager = equip_mgr
	character_model = char_model
	battle_manager = battle_mgr
	martial_arts_manager = martial_arts_mgr
	print("装备穿戴系统已连接到其他管理系统")

# 穿戴装备
func equip_item(equipment_id: String, target_slot: EquipmentSlot = -1) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"previous_item": null
	}
	
	# 从装备管理器获取装备数据
	if not equipment_manager:
		result.message = "装备管理器未设置"
		return result
	
	var equipment_data = equipment_manager.find_equipment_by_id(equipment_id)
	if not equipment_data:
		result.message = "未找到ID为 %s 的装备" % equipment_id
		return result
	
	# 确定目标槽位
	var slot_to_use = target_slot
	if slot_to_use == -1:
		slot_to_use = get_slot_for_equipment_type(equipment_data.type)
	
	# 检查槽位是否有效
	if not is_valid_slot_for_equipment(equipment_data.type, slot_to_use):
		result.message = "装备类型 %s 不能装备到槽位 %s" % [equipment_data.type, slot_to_use]
		return result
	
	# 验证兼容性
	var compatibility_result = validate_compatibility(equipment_id, slot_to_use)
	if not compatibility_result.compatible:
		result.message = "装备不兼容: %s" % compatibility_result.reason
		return result
	
	# 检查角色等级是否满足要求
	if character_model and character_model.get_level() < equipment_data.level_requirement:
		result.message = "角色等级不足，需要等级 %d" % equipment_data.level_requirement
		return result
	
	# 如果槽位已有装备，则先卸下
	var previous_item = null
	if equipped_items[slot_to_use] != null:
		var unequip_result = unequip_item(slot_to_use)
		if unequip_result.success:
			previous_item = unequip_result.item
		else:
			result.message = "无法卸下当前装备: %s" % unequip_result.message
			return result
	
	# 从背包中移除装备（实际游戏中可能是移动而不是移除）
	if equipment_manager.remove_equipment(equipment_id):
		# 将装备添加到对应槽位
		var new_equipment = create_equipment_from_data(equipment_data)
		equipped_items[slot_to_use] = new_equipment
		
		# 更新角色模型外观
		update_character_appearance(new_equipment, slot_to_use)
		
		# 发送信号
		emit_signal("equipment_equipped", equipment_id, slot_to_use)
		
		result.success = true
		result.previous_item = previous_item
		result.message = "成功装备 %s 到槽位 %s" % [new_equipment.name, slot_to_use]
	else:
		result.message = "无法从背包中移除装备"
		# 如果失败，需要恢复之前的装备
		if previous_item:
			equipped_items[slot_to_use] = previous_item
			update_character_appearance(previous_item, slot_to_use)
	
	return result

# 卸下装备
func unequip_item(slot_type: EquipmentSlot) -> Dictionary:
	var result = {
		"success": false,
		"item": null,
		"message": ""
	}
	
	if not equipped_items.has(slot_type) or equipped_items[slot_type] == null:
		result.message = "槽位 %s 没有装备" % slot_type
		return result
	
	var equipment = equipped_items[slot_type]
	
	# 从当前槽位移除
	equipped_items[slot_type] = null
	
	# 更新角色模型外观
	update_character_appearance(null, slot_type)
	
	# 尝试将装备添加回背包
	if equipment_manager:
		# 创建一个原始装备数据的副本用于返回背包
		var original_equipment = equipment_manager.EquipmentData.new(
			equipment.id,
			equipment.name,
			equipment.type,
			equipment.rarity if equipment.has_method("_get_rarity") else equipment_manager.EquipmentRarity.COMMON
		)
		original_equipment.level_requirement = equipment.level_requirement
		original_equipment.attributes = equipment.attributes if equipment.has_method("_get_attributes") else {}
		
		if equipment_manager.add_equipment(original_equipment):
			result.success = true
			result.item = equipment
			result.message = "成功卸下装备 %s 从槽位 %s，并添加到背包" % [equipment.name, slot_type]
		else:
			result.message = "无法将装备添加回背包，可能背包已满"
			# 如果无法添加回背包，需要恢复装备
			equipped_items[slot_type] = equipment
			update_character_appearance(equipment, slot_type)
	else:
		result.message = "装备管理器未设置，无法添加装备回背包"
	
	if result.success:
		emit_signal("equipment_unequipped", equipment.id, slot_type)
	
	return result

# 验证装备兼容性
func validate_compatibility(equipment_id: String, slot_type: EquipmentSlot) -> Dictionary:
	var result = {
		"compatible": false,
		"reason": ""
	}
	
	if not equipment_manager:
		result.reason = "装备管理器未设置"
		return result
	
	var equipment_data = equipment_manager.find_equipment_by_id(equipment_id)
	if not equipment_data:
		result.reason = "未找到装备"
		return result
	
	# 检查槽位兼容性
	var expected_slot = get_slot_for_equipment_type(equipment_data.type)
	if expected_slot != slot_type:
		result.reason = "装备类型与槽位不匹配"
		return result
	
	# 检查武学兼容性
	if martial_arts_manager and equipment_data.martial_art_compatibility.size() > 0:
		var current_martial_art = martial_arts_manager.get_current_martial_art()
		if current_martial_art not in equipment_data.martial_art_compatibility:
			result.reason = "武学类型不兼容"
			return result
	
	# 检查等级要求
	if character_model and character_model.get_level() < equipment_data.level_requirement:
		result.reason = "角色等级不足"
		return result
	
	result.compatible = true
	result.reason = "兼容"
	return result

# 更新角色外观
func update_character_appearance(equipment: EquipmentData, slot_type: EquipmentSlot):
	if not character_model:
		print("警告: 角色模型未设置，无法更新外观")
		return
	
	# 根据槽位更新角色模型的不同部分
	match slot_type:
		EquipmentSlot.MAIN_HAND:
			if equipment and equipment.model_path:
				character_model.update_weapon_model(equipment.model_path, equipment.texture_path)
			else:
				character_model.reset_weapon_model()
		EquipmentSlot.HEAD:
			if equipment and equipment.model_path:
				character_model.update_head_model(equipment.model_path, equipment.texture_path)
			else:
				character_model.reset_head_model()
		EquipmentSlot.BODY:
			if equipment and equipment.model_path:
				character_model.update_body_model(equipment.model_path, equipment.texture_path)
			else:
				character_model.reset_body_model()
		EquipmentSlot.HANDS:
			if equipment and equipment.model_path:
				character_model.update_hand_model(equipment.model_path, equipment.texture_path)
			else:
				character_model.reset_hand_model()
		EquipmentSlot.FEET:
			if equipment and equipment.model_path:
				character_model.update_feet_model(equipment.model_path, equipment.texture_path)
			else:
				character_model.reset_feet_model()
		_:
			# 其他槽位可能不需要直接的3D模型更新
			pass
	
	emit_signal("visuals_rendered")

# 获取装备类型的对应槽位
func get_slot_for_equipment_type(equipment_type: EquipmentType) -> EquipmentSlot:
	match equipment_type:
		EquipmentType.WEAPON_MAIN_HAND: return EquipmentSlot.MAIN_HAND
		EquipmentType.WEAPON_OFF_HAND: return EquipmentSlot.OFF_HAND
		EquipmentType.HELMET: return EquipmentSlot.HEAD
		EquipmentType.ARMOR: return EquipmentSlot.BODY
		EquipmentType.GLOVES: return EquipmentSlot.HANDS
		EquipmentType.BOOTS: return EquipmentSlot.FEET
		EquipmentType.NECKLACE: return EquipmentSlot.NECKLACE
		EquipmentType.RING_LEFT: return EquipmentSlot.RING_LEFT
		EquipmentType.RING_RIGHT: return EquipmentSlot.RING_RIGHT
		EquipmentType.WAIST: return EquipmentSlot.WAIST
		_: return EquipmentSlot.MAIN_HAND  # 默认返回主手

# 检查装备类型是否适用于特定槽位
func is_valid_slot_for_equipment(equipment_type: EquipmentType, slot_type: EquipmentSlot) -> bool:
	var valid_slot = get_slot_for_equipment_type(equipment_type)
	return valid_slot == slot_type

# 获取指定槽位的已装备物品
func get_equipped_item_in_slot(slot_type: EquipmentSlot) -> EquipmentData:
	return equipped_items.get(slot_type, null)

# 获取所有已装备的物品
func get_all_equipped_items() -> Dictionary:
	return equipped_items.duplicate()

# 快速装备一套装备
func equip_set(equipment_ids: Array) -> Dictionary:
	var result = {
		"success_count": 0,
		"fail_count": 0,
		"messages": []
	}
	
	for equipment_id in equipment_ids:
		var equip_result = equip_item(equipment_id)
		if equip_result.success:
			result.success_count += 1
		else:
			result.fail_count += 1
			result.messages.append("装备 %s 失败: %s" % [equipment_id, equip_result.message])
	
	return result

# 检查是否有武器装备
func has_main_hand_weapon() -> bool:
	return equipped_items[EquipmentSlot.MAIN_HAND] != null

# 获取主手武器信息
func get_main_hand_weapon() -> EquipmentData:
	return equipped_items[EquipmentSlot.MAIN_HAND]

# 创建装备数据实例
func create_equipment_from_data(data) -> EquipmentData:
	var equipment = EquipmentData.new(data.id, data.name, data.type, get_slot_for_equipment_type(data.type))
	equipment.level_requirement = data.level_requirement
	if data.has_method("get_martial_art_compatibility"):
		equipment.martial_art_compatibility = data.get_martial_art_compatibility()
	if data.has_method("get_model_path"):
		equipment.model_path = data.get_model_path()
	if data.has_method("get_texture_path"):
		equipment.texture_path = data.get_texture_path()
	return equipment

# 获取装备槽位信息
func get_equipment_slot_info() -> Dictionary:
	var slot_info = {}
	for slot in EquipmentSlot:
		var equipment = equipped_items[slot]
		slot_info[slot] = {
			"occupied": equipment != null,
			"equipment_id": equipment.id if equipment else "",
			"equipment_name": equipment.name if equipment else ""
		}
	return slot_info