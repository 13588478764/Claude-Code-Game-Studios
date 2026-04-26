# 武侠奇遇录 - 装备系统
# 负责管理装备槽位、装备属性计算、强化镶嵌和外观系统

extends Node

# 装备槽位类型
enum EquipmentSlot {
	WEAPON_MAIN,      # 主手武器
	WEAPON_OFFHAND,   # 副手/离手
	HEAD,            # 头饰
	BODY,            # 衣袍
	HANDS,           # 护手
	FEET,            # 靴子
	NECKLACE,        # 项链
	RING_1,          # 戒指1
	RING_2,          # 戒指2
	BELT             # 腰带
}

# 装备品阶
enum EquipmentTier {
	COMMON,    # 普通 (白色)
	RARE,      # 稀有 (蓝色) 
	EPIC,      # 史诗 (紫色)
	LEGENDARY  # 传说 (金色)
}

# 强化配置
var enhancement_config = {
	"max_level": 20,
	"success_rates": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,  # +0 to +10: 100%
					  0.8, 0.75, 0.7, 0.65, 0.6,  # +11 to +15: 80%->60%
					  0.5, 0.45, 0.4, 0.3, 0.2],  # +16 to +20: 50%->20%
	"failure_penalty": {
		"level_11_15": "no_downgrade",     # +11~+15失败不降级
		"level_16_20": "downgrade_1_2"    # +16~+20失败降级1-2级
	},
	"attribute_multiplier": 0.03,  # 每级强化提升3%基础属性
	"bonus_thresholds": [10, 15, 20]  # 特殊加成等级
}

# 宝石类型
enum GemType {
	RED,    # 攻击/火
	BLUE,   # 防御/水  
	GREEN,  # 生命/毒
	YELLOW, # 暴击/雷
	PURPLE, # 冷却/内力
	DIAMOND # 全抗/幸运
}

# 装备槽位解锁配置（基于境界）
var slot_unlock_realm = {
	EquipmentSlot.WEAPON_MAIN: 0,    # 炼气期 (1-9级)
	EquipmentSlot.BODY: 0,           # 炼气期
	EquipmentSlot.FEET: 0,           # 炼气期
	EquipmentSlot.HEAD: 1,           # 筑基期 (10-19级)
	EquipmentSlot.HANDS: 1,          # 筑基期
	EquipmentSlot.RING_1: 2,         # 金丹期 (20-29级)
	EquipmentSlot.WEAPON_OFFHAND: 3, # 元婴期 (30-39级)
	EquipmentSlot.NECKLACE: 3,       # 元婴期
	EquipmentSlot.BELT: 4,           # 化神期 (40-49级)
	EquipmentSlot.RING_2: 8          # 渡劫期 (80-89级)
}

# 当前装备状态
var equipped_items = {
	EquipmentSlot.WEAPON_MAIN: null,
	EquipmentSlot.WEAPON_OFFHAND: null,
	EquipmentSlot.HEAD: null,
	EquipmentSlot.BODY: null,
	EquipmentSlot.HANDS: null,
	EquipmentSlot.FEET: null,
	EquipmentSlot.NECKLACE: null,
	EquipmentSlot.RING_1: null,
	EquipmentSlot.RING_2: null,
	EquipmentSlot.BELT: null
}

# 宝石镶嵌状态
var gem_slots = {
	EquipmentSlot.WEAPON_MAIN: [],
	EquipmentSlot.WEAPON_OFFHAND: [],
	EquipmentSlot.HEAD: [],
	EquipmentSlot.BODY: [],
	EquipmentSlot.HANDS: [],
	EquipmentSlot.FEET: [],
	EquipmentSlot.NECKLACE: [],
	EquipmentSlot.RING_1: [],
	EquipmentSlot.RING_2: [],
	EquipmentSlot.BELT: []
}

# 幻化外观
var appearance_overrides = {}

func _ready():
	print("装备系统初始化完成")

func can_equip_item(item_id, character_level, character_realm):
	"""检查是否可以装备指定物品"""
	var database_manager = get_node_or_null("/root/DatabaseManager")
	if database_manager == null:
		push_warning("无法访问DatabaseManager")
		return false
	var item_data = database_manager.get_item(item_id)
	if item_data == null:
		return false
	
	# 检查等级要求
	if character_level < item_data["required_level"]:
		return false
	
	# 检查境界要求
	if character_realm < item_data["required_realm"]:
		return false
	
	# 检查槽位是否已解锁
	var slot = get_slot_type_from_item(item_data)
	if not is_slot_unlocked(slot, character_realm):
		return false
	
	return true

func get_slot_type_from_item(item_data):
	"""根据物品数据获取槽位类型"""
	match item_data["slot"]:
		"weapon_main":
			return EquipmentSlot.WEAPON_MAIN
		"weapon_offhand":
			return EquipmentSlot.WEAPON_OFFHAND
		"head":
			return EquipmentSlot.HEAD
		"body":
			return EquipmentSlot.BODY
		"hands":
			return EquipmentSlot.HANDS
		"feet":
			return EquipmentSlot.FEET
		"necklace":
			return EquipmentSlot.NECKLACE
		"ring":
			# 戒指需要选择空的槽位
			if equipped_items[EquipmentSlot.RING_1] == null:
				return EquipmentSlot.RING_1
			elif equipped_items[EquipmentSlot.RING_2] == null:
				return EquipmentSlot.RING_2
			else:
				return EquipmentSlot.RING_1  # 默认替换第一个
		"belt":
			return EquipmentSlot.BELT
		_:
			return -1

func is_slot_unlocked(slot, character_realm):
	"""检查槽位是否已解锁"""
	if slot_unlock_realm.has(slot):
		return character_realm >= slot_unlock_realm[slot]
	return false

func equip_item(item_id, character_level, character_realm):
	"""装备物品"""
	if not can_equip_item(item_id, character_level, character_realm):
		push_warning("无法装备物品: %s" % item_id)
		return false
	
	var database_manager = get_node_or_null("/root/DatabaseManager")
	if database_manager == null:
		push_warning("无法访问DatabaseManager")
		return false
	var item_data = database_manager.get_item(item_id)
	var slot = get_slot_type_from_item(item_data)
	
	# 卸下当前装备（如果有）
	if equipped_items[slot] != null:
		unequip_item(slot)
	
	# 装备新物品
	equipped_items[slot] = item_id
	
	# 初始化宝石槽位
	initialize_gem_slots(slot, item_data)
	
	print("成功装备 %s 到 %s 槽位" % [item_data["name"], get_slot_name(slot)])
	return true

func unequip_item(slot):
	"""卸下装备"""
	if equipped_items[slot] == null:
		return false
	
	var item_id = equipped_items[slot]
	equipped_items[slot] = null
	gem_slots[slot] = []
	appearance_overrides.erase(slot)
	
	print("成功卸下 %s" % item_id)
	return true

func initialize_gem_slots(slot, item_data):
	"""初始化宝石槽位"""
	# 根据物品品阶确定初始孔洞数量
	var tier = get_tier_from_string(item_data["tier"])
	var initial_slots = 0
	
	match tier:
		EquipmentTier.COMMON:
			initial_slots = 0
		EquipmentTier.RARE:
			initial_slots = 1
		EquipmentTier.EPIC:
			initial_slots = 2
		EquipmentTier.LEGENDARY:
			initial_slots = 3
	
	# 初始化宝石槽位
	gem_slots[slot] = []
	for i in range(initial_slots):
		gem_slots[slot].append(null)

func get_tier_from_string(tier_string):
	"""将字符串品阶转换为枚举值"""
	match tier_string:
		"common":
			return EquipmentTier.COMMON
		"rare":
			return EquipmentTier.RARE
		"epic":
			return EquipmentTier.EPIC
		"legendary":
			return EquipmentTier.LEGENDARY
		_:
			return EquipmentTier.COMMON

func get_slot_name(slot):
	"""获取槽位名称"""
	match slot:
		EquipmentSlot.WEAPON_MAIN:
			return "主手武器"
		EquipmentSlot.WEAPON_OFFHAND:
			return "副手"
		EquipmentSlot.HEAD:
			return "头饰"
		EquipmentSlot.BODY:
			return "衣袍"
		EquipmentSlot.HANDS:
			return "护手"
		EquipmentSlot.FEET:
			return "靴子"
		EquipmentSlot.NECKLACE:
			return "项链"
		EquipmentSlot.RING_1:
			return "戒指1"
		EquipmentSlot.RING_2:
			return "戒指2"
		EquipmentSlot.BELT:
			return "腰带"
		_:
			return "未知"

func enhance_item(slot, materials_available):
	"""强化装备"""
	if equipped_items[slot] == null:
		push_warning("槽位 %s 没有装备" % get_slot_name(slot))
		return false
	
	var current_enhancement = get_item_enhancement_level(slot)
	if current_enhancement >= enhancement_config["max_level"]:
		push_warning("装备已达到最大强化等级")
		return false
	
	# 检查材料是否足够
	if not check_enhancement_materials(current_enhancement + 1, materials_available):
		push_warning("强化材料不足")
		return false
	
	# 计算成功率
	var success_rate = enhancement_config["success_rates"][current_enhancement]
	var success = randf() < success_rate
	
	if success:
		# 强化成功
		set_item_enhancement_level(slot, current_enhancement + 1)
		consume_enhancement_materials(current_enhancement + 1, materials_available)
		print("强化成功！%s 强化到 +%d" % [get_slot_name(slot), current_enhancement + 1])
		return true
	else:
		# 强化失败
		handle_enhancement_failure(slot, current_enhancement, materials_available)
		print("强化失败！%s 保持 +%d" % [get_slot_name(slot), current_enhancement])
		return false

func check_enhancement_materials(target_level, materials_available):
	"""检查强化材料是否足够"""
	# 这里应该检查具体的材料数量
	# 简化实现：假设材料总是足够的
	return true

func consume_enhancement_materials(target_level, materials_available):
	"""消耗强化材料"""
	# 这里应该实际消耗材料
	pass

func handle_enhancement_failure(slot, current_level, materials_available):
	"""处理强化失败"""
	if current_level >= 10 and current_level <= 14:
		# +11~+15失败不降级，只消耗材料
		consume_enhancement_materials(current_level + 1, materials_available)
	elif current_level >= 15:
		# +16~+20失败降级
		var downgrade_amount = randi_range(1, 2)
		var new_level = max(0, current_level - downgrade_amount)
		set_item_enhancement_level(slot, new_level)
		consume_enhancement_materials(current_level + 1, materials_available)

func get_item_enhancement_level(slot):
	"""获取装备强化等级"""
	# 这里应该从装备数据中读取强化等级
	# 简化实现：返回0
	return 0

func set_item_enhancement_level(slot, level):
	"""设置装备强化等级"""
	# 这里应该保存强化等级到装备数据
	pass

func embed_gem(slot, gem_type, gem_index):
	"""镶嵌宝石"""
	if gem_index >= gem_slots[slot].size():
		push_warning("宝石槽位不足")
		return false
	
	if gem_slots[slot][gem_index] != null:
		push_warning("槽位已被占用")
		return false
	
	gem_slots[slot][gem_index] = gem_type
	print("成功在 %s 镶嵌 %s 宝石" % [get_slot_name(slot), get_gem_name(gem_type)])
	
	# 检查套装共鸣
	check_gem_set_bonus()
	return true

func remove_gem(slot, gem_index):
	"""移除宝石"""
	if gem_index >= gem_slots[slot].size():
		return false
	
	if gem_slots[slot][gem_index] == null:
		return false
	
	var removed_gem = gem_slots[slot][gem_index]
	gem_slots[slot][gem_index] = null
	
	print("成功从 %s 移除 %s 宝石" % [get_slot_name(slot), get_gem_name(removed_gem)])
	check_gem_set_bonus()
	return true

func get_gem_name(gem_type):
	"""获取宝石名称"""
	match gem_type:
		GemType.RED:
			return "红色"
		GemType.BLUE:
			return "蓝色"
		GemType.GREEN:
			return "绿色"
		GemType.YELLOW:
			return "黄色"
		GemType.PURPLE:
			return "紫色"
		GemType.DIAMOND:
			return "钻石"
		_:
			return "未知"

func check_gem_set_bonus():
	"""检查宝石套装共鸣"""
	var gem_counts = {
		GemType.RED: 0,
		GemType.BLUE: 0,
		GemType.GREEN: 0,
		GemType.YELLOW: 0,
		GemType.PURPLE: 0,
		GemType.DIAMOND: 0
	}
	
	# 统计所有装备的宝石数量
	for slot in gem_slots:
		for gem in gem_slots[slot]:
			if gem != null and gem_counts.has(gem):
				gem_counts[gem] += 1
	
	# 检查激活的套装效果
	var active_bonuses = []
	for gem_type in gem_counts:
		var count = gem_counts[gem_type]
		if count >= 9:
			active_bonuses.append({"type": gem_type, "tier": 3})
		elif count >= 6:
			active_bonuses.append({"type": gem_type, "tier": 2})
		elif count >= 3:
			active_bonuses.append({"type": gem_type, "tier": 1})
	
	print("激活的宝石套装效果: %s" % str(active_bonuses))
	return active_bonuses

func apply_appearance_override(slot, appearance_item_id):
	"""应用外观幻化"""
	if equipped_items[slot] == null:
		push_warning("槽位 %s 没有装备" % get_slot_name(slot))
		return false
	
	# 检查幻化物品是否已收集
	var database_manager = get_node_or_null("/root/DatabaseManager")
	if database_manager == null:
		push_warning("无法访问DatabaseManager")
		return false
	var appearance_data = database_manager.get_item(appearance_item_id)
	if appearance_data == null:
		push_warning("幻化物品不存在: %s" % appearance_item_id)
		return false
	
	# 检查装备类型是否匹配
	var current_item = database_manager.get_item(equipped_items[slot])
	if not can_transmog(current_item, appearance_data):
		push_warning("装备类型不匹配，无法幻化")
		return false
	
	appearance_overrides[slot] = appearance_item_id
	print("成功将 %s 幻化为 %s 外观" % [get_slot_name(slot), appearance_data["name"]])
	return true

func can_transmog(current_item, appearance_item):
	"""检查是否可以幻化"""
	# 简化实现：只要都是武器或都是防具就可以幻化
	var current_type = current_item["type"]
	var appearance_type = appearance_item["type"]
	
	# 武器类型必须完全匹配
	if current_type == "weapon" and appearance_type == "weapon":
		return current_item["slot"] == appearance_item["slot"]
	
	# 防具类型可以跨部位幻化
	if (current_type == "armor" or current_type == "accessory") and \
	   (appearance_type == "armor" or appearance_type == "accessory"):
		return true
	
	return false

func get_equipment_attributes():
	"""获取所有装备的属性加成"""
	var total_attributes = {
		"base": {
			"strength": 0,
			"agility": 0,
			"constitution": 0,
			"intelligence": 0,
			"willpower": 0,
			"luck": 0
		},
		"combat": {
			"attack": 0,
			"defense": 0,
			"max_health": 0,
			"critical_rate": 0.0,
			"critical_damage": 0.0,
			"hit_rate": 0.0,
			"evasion": 0.0,
			"max_internal_energy": 0,
			"internal_energy_regen": 0.0
		},
		"elemental": {
			"fire": 0,
			"water": 0,
			"earth": 0,
			"metal": 0,
			"wood": 0
		},
		"resistances": {
			"poison": 0.0,
			"stun": 0.0,
			"freeze": 0.0,
			"burn": 0.0
		}
	}
	
	# 累加所有装备的属性
	for slot in equipped_items:
		if equipped_items[slot] != null:
			var database_manager = get_node_or_null("/root/DatabaseManager")
			if database_manager != null:
				var item_data = database_manager.get_item(equipped_items[slot])
				if item_data != null and item_data.has("attributes"):
					add_item_attributes(total_attributes, item_data["attributes"])
	
	# 应用宝石加成
	apply_gem_bonuses(total_attributes)
	
	return total_attributes

func add_item_attributes(total_attrs, item_attrs):
	"""累加物品属性"""
	if item_attrs.has("base"):
		for attr in item_attrs["base"]:
			if total_attrs["base"].has(attr):
				total_attrs["base"][attr] += item_attrs["base"][attr]
	
	if item_attrs.has("combat"):
		for attr in item_attrs["combat"]:
			if total_attrs["combat"].has(attr):
				total_attrs["combat"][attr] += item_attrs["combat"][attr]
	
	if item_attrs.has("elemental"):
		for attr in item_attrs["elemental"]:
			if total_attrs["elemental"].has(attr):
				total_attrs["elemental"][attr] += item_attrs["elemental"][attr]
	
	if item_attrs.has("resistances"):
		for attr in item_attrs["resistances"]:
			if total_attrs["resistances"].has(attr):
				total_attrs["resistances"][attr] += item_attrs["resistances"][attr]

func apply_gem_bonuses(total_attrs):
	"""应用宝石加成"""
	# 这里应该根据宝石类型添加属性
	# 简化实现：暂时不处理
	pass

# 调试函数
func debug_print_equipment_info():
	"""打印装备信息用于调试"""
	print("=== 装备信息 ===")
	for slot in equipped_items:
		if equipped_items[slot] != null:
			var database_manager = get_node_or_null("/root/DatabaseManager")
			if database_manager != null:
				var item_data = database_manager.get_item(equipped_items[slot])
				var enhancement_level = get_item_enhancement_level(slot)
				print("%s: %s (+%d)" % [get_slot_name(slot), item_data["name"], enhancement_level])
			else:
				print("%s: %s (+%d)" % [get_slot_name(slot), "未知", 0])
		else:
			print("%s: 空" % get_slot_name(slot))
	
	print("宝石镶嵌:")
	for slot in gem_slots:
		if gem_slots[slot].size() > 0:
			var gems = []
			for gem in gem_slots[slot]:
				if gem != null:
					gems.append(get_gem_name(gem))
				else:
					gems.append("空")
			print("%s: %s" % [get_slot_name(slot), str(gems)])
	
	print("幻化外观:")
	for slot in appearance_overrides:
		if appearance_overrides.has(slot):
			var database_manager = get_node_or_null("/root/DatabaseManager")
			if database_manager != null:
				var appearance_data = database_manager.get_item(appearance_overrides[slot])
				print("%s: %s" % [get_slot_name(slot), appearance_data["name"]])
			else:
				print("%s: %s" % [get_slot_name(slot), "未知"])
	
	print("================")

# UI回调函数
func _on_test_equip_item_pressed():
	"""测试装备物品按钮回调"""
	# 测试装备普通铁剑（炼气期1级可装备）
	var can_equip = can_equip_item("common_sword", 1, 0)
	print("普通铁剑可装备: %s" % ("是" if can_equip else "否"))
	
	if can_equip:
		equip_item("common_sword", 1, 0)
	
	# 测试装备精钢剑（筑基期10级可装备）
	can_equip = can_equip_item("rare_sword", 5, 0)
	print("精钢剑(5级)可装备: %s" % ("是" if can_equip else "否"))
	
	can_equip = can_equip_item("rare_sword", 10, 1)
	print("精钢剑(10级筑基)可装备: %s" % ("是" if can_equip else "否"))
	
	if can_equip:
		equip_item("rare_sword", 10, 1)
	
	# 打印装备信息
	debug_print_equipment_info()

func _on_test_slot_unlock_pressed():
	"""测试槽位解锁按钮回调"""
	# 测试不同境界的槽位解锁情况
	var test_realms = [0, 1, 2, 3, 4, 8]  # 炼气、筑基、金丹、元婴、化神、渡劫
	var realm_names = ["炼气", "筑基", "金丹", "元婴", "化神", "渡劫"]
	
	for i in range(test_realms.size()):
		var realm = test_realms[i]
		var name = realm_names[i]
		print("=== %s 期槽位解锁情况 ===" % name)
		
		for slot in slot_unlock_realm:
			var unlocked = is_slot_unlocked(slot, realm)
			print("%s: %s" % [get_slot_name(slot), "已解锁" if unlocked else "未解锁"])
	
	print("==================")

func _on_test_enhancement_pressed():
	"""测试装备强化按钮回调"""
	# 先装备一个物品用于测试
	equip_item("common_sword", 1, 0)
	
	# 测试强化成功率
	print("=== 强化成功率测试 ===")
	for level in range(21):  # +0 to +20
		if level < enhancement_config["success_rates"].size():
			var success_rate = enhancement_config["success_rates"][level]
			print("+%d -> +%d: 成功率 %.0f%%" % [level, level + 1, success_rate * 100])
	
	# 测试强化失败处理
	print("=== 强化失败处理测试 ===")
	print("强化到+12失败: 不降级")
	print("强化到+18失败: 降级1-2级")
	
	# 获取装备属性
	var equipment_attrs = get_equipment_attributes()
	print("当前装备属性:")
	print("  力道: %d" % equipment_attrs["base"]["strength"])
	print("  攻击力: %d" % equipment_attrs["combat"]["attack"])
	print("  火属性: %d" % equipment_attrs["elemental"]["fire"])