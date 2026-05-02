## EquipmentAttributeCalculator
## 装备属性计算器
## 负责计算装备的基础属性、强化加成、宝石效果和流派加成

extends Node

class_name EquipmentAttributeCalculator

# 装备数据结构（内部使用，避免与全局 EquipmentData 冲突）
class EquipmentInfo:
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

# 角色属性结构
class CharacterAttributes:
	var base: Dictionary
	var equipment: Dictionary
	var total: Dictionary
	
	func _init():
		base = {}
		equipment = {}
		total = {}

# 信号定义
signal attributes_calculated(character_id: String, new_attributes: Dictionary)

# 初始化
func _ready():
	print("装备属性计算器已初始化")

# 计算装备基础属性
func calculate_base_attributes(equipment_data: EquipmentInfo) -> Dictionary:
	var calculated_attributes = {}
	
	# 复制基础属性
	for attr_name in equipment_data.base_attributes:
		calculated_attributes[attr_name] = equipment_data.base_attributes[attr_name]
	
	return calculated_attributes

# 计算强化属性加成
func calculate_enhancement_bonus(equipment_data: EquipmentInfo, enhancement_level: int = -1) -> Dictionary:
	var bonus_attributes = {}
	
	# 使用传入的强化等级，如果未传入则使用装备的当前强化等级
	var level = enhancement_level if enhancement_level != -1 else equipment_data.enhancement_level
	
	# 根据强化等级计算属性加成
	# 使用公式：基础属性 × (1 + 强化倍率 × 强化等级)
	var enhancement_multiplier = 0.03  # 强化倍率
	
	for attr_name in equipment_data.base_attributes:
		var base_value = equipment_data.base_attributes[attr_name]
		var enhancement_bonus = base_value * enhancement_multiplier * level
		bonus_attributes[attr_name] = enhancement_bonus
	
	return bonus_attributes

# 计算宝石效果
func calculate_gem_effects(equipment_data: EquipmentInfo) -> Dictionary:
	var gem_attributes = {}
	
	# 遍历所有宝石
	for gem in equipment_data.gems:
		if gem is Dictionary:
			# 假设宝石数据包含属性加成
			for attr_name in gem:
				if attr_name != "type" and gem[attr_name] is float or gem[attr_name] is int:
					if gem_attributes.has(attr_name):
						gem_attributes[attr_name] += gem[attr_name]
					else:
						gem_attributes[attr_name] = gem[attr_name]
	
	return gem_attributes

# 计算流派加成
func calculate_school_bonus(equipment_data: EquipmentInfo, martial_art_school: String) -> Dictionary:
	var school_bonus = {}
	
	# 检查装备是否有流派加成
	if equipment_data.name.to_lower().find(martial_art_school.to_lower()) != -1 or \
		equipment_data.name.to_lower().find("武当") != -1 or \
		equipment_data.name.to_lower().find("少林") != -1 or \
		equipment_data.name.to_lower().find("峨眉") != -1:
		# 如果装备名称包含门派名称，提供额外20%属性加成
		for attr_name in equipment_data.base_attributes:
			var base_value = equipment_data.base_attributes[attr_name]
			var school_bonus_value = base_value * 0.2  # 20%流派加成
			school_bonus[attr_name] = school_bonus_value
	
	return school_bonus

# 计算装备套装效果
func calculate_set_bonus(equipped_items: Array[EquipmentInfo]) -> Dictionary:
	var set_bonus = {}
	
	# 统计宝石颜色
	var gem_colors = {"red": 0, "blue": 0, "green": 0, "yellow": 0, "purple": 0, "diamond": 0}
	
	for item in equipped_items:
		for gem in item.gems:
			if gem is Dictionary and gem.has("color"):
				var color = gem.color.to_lower()
				if gem_colors.has(color):
					gem_colors[color] += 1
	
	# 检查套装效果
	if gem_colors.red >= 3:
		# 3红宝石套装效果：增加攻击力
		set_bonus["attack"] = (set_bonus.get("attack", 0) + 10) if set_bonus.has("attack") else 10
	if gem_colors.red >= 6:
		# 6红宝石套装效果：增加更多攻击力和暴击率
		set_bonus["attack"] = (set_bonus.get("attack", 0) + 20) if set_bonus.has("attack") else 20
		set_bonus["critical_rate"] = (set_bonus.get("critical_rate", 0) + 0.05) if set_bonus.has("critical_rate") else 0.05
	if gem_colors.red >= 9:
		# 9红宝石套装效果：增加攻击力、暴击率和暴击伤害
		set_bonus["attack"] = (set_bonus.get("attack", 0) + 30) if set_bonus.has("attack") else 30
		set_bonus["critical_rate"] = (set_bonus.get("critical_rate", 0) + 0.1) if set_bonus.has("critical_rate") else 0.1
		set_bonus["critical_damage"] = (set_bonus.get("critical_damage", 0) + 0.2) if set_bonus.has("critical_damage") else 0.2
	
	return set_bonus

# 计算单件装备的总属性
func calculate_equipment_total(equipment_data: EquipmentInfo, martial_art_school: String = "") -> Dictionary:
	var total_attributes = {}
	
	# 1. 基础属性
	var base_attrs = calculate_base_attributes(equipment_data)
	for attr in base_attrs:
		total_attributes[attr] = base_attrs[attr]
	
	# 2. 强化加成
	var enhancement_attrs = calculate_enhancement_bonus(equipment_data)
	for attr in enhancement_attrs:
		if total_attributes.has(attr):
			total_attributes[attr] += enhancement_attrs[attr]
		else:
			total_attributes[attr] = enhancement_attrs[attr]
	
	# 3. 宝石效果
	var gem_attrs = calculate_gem_effects(equipment_data)
	for attr in gem_attrs:
		if total_attributes.has(attr):
			total_attributes[attr] += gem_attrs[attr]
		else:
			total_attributes[attr] = gem_attrs[attr]
	
	# 4. 流派加成
	if martial_art_school != "":
		var school_attrs = calculate_school_bonus(equipment_data, martial_art_school)
		for attr in school_attrs:
			if total_attributes.has(attr):
				total_attributes[attr] += school_attrs[attr]
			else:
				total_attributes[attr] = school_attrs[attr]
	
	return total_attributes

# 计算角色总装备属性
func calculate_character_equipment_attributes(equipped_items: Array[EquipmentInfo], martial_art_school: String = "") -> Dictionary:
	var total_equipment_attributes = {}
	
	# 计算每件装备的属性
	for equipment in equipped_items:
		if equipment:
			var equipment_attrs = calculate_equipment_total(equipment, martial_art_school)
			for attr_name in equipment_attrs:
				if total_equipment_attributes.has(attr_name):
					total_equipment_attributes[attr_name] += equipment_attrs[attr_name]
				else:
					total_equipment_attributes[attr_name] = equipment_attrs[attr_name]
	
	# 计算套装效果
	var set_bonus = calculate_set_bonus(equipped_items)
	for attr_name in set_bonus:
		if total_equipment_attributes.has(attr_name):
			total_equipment_attributes[attr_name] += set_bonus[attr_name]
		else:
			total_equipment_attributes[attr_name] = set_bonus[attr_name]
	
	return total_equipment_attributes

# 计算最终角色属性（基础属性 + 装备属性）
func calculate_final_character_attributes(base_attributes: Dictionary, equipment_attributes: Dictionary) -> Dictionary:
	var final_attributes = base_attributes.duplicate()
	
	for attr_name in equipment_attributes:
		if final_attributes.has(attr_name):
			final_attributes[attr_name] += equipment_attributes[attr_name]
		else:
			final_attributes[attr_name] = equipment_attributes[attr_name]
	
	return final_attributes

# 获取装备强化成功率
func get_enhancement_success_rate(current_level: int, enhancement_level: int) -> float:
	# 使用公式：强化成功率 = 基础成功率 - (强化等级 - 10) × 衰减系数
	var base_success_rate = 1.0  # +1~+10的基础成功率（100%）
	var decay_factor = 0.04  # 每级强化的成功率衰减系数
	
	if enhancement_level <= 10:
		return 1.0  # +10以下都是100%
	elif enhancement_level <= 15:
		# +11~+15: 80% -> 60%
		return max(0.6, 0.8 - (enhancement_level - 11) * 0.05)
	else:
		# +16~+20: 50% -> 20%
		return max(0.2, 0.5 - (enhancement_level - 16) * 0.075)

# 获取强化属性提升倍率
func get_enhancement_multiplier() -> float:
	return 0.03  # 每级强化的属性提升倍率

# 测试函数
func test_equipment_attribute_calculation():
	print("开始测试装备属性计算...")
	
	# 创建测试装备
	var test_sword = EquipmentInfo.new("sword_001", "武当剑", "weapon", "weapon_main")
	test_sword.tier = 3  # 史诗
	test_sword.base_attributes = {"attack": 60, "attack_speed": 1.2}
	test_sword.enhancement_level = 10
	
	# 添加宝石
	test_sword.gems.append({"type": "ruby", "color": "red", "attack": 5})
	test_sword.gems.append({"type": "sapphire", "color": "blue", "defense": 3})
	
	# 计算装备属性
	var equipment_attrs = calculate_equipment_total(test_sword, "武当")
	
	if equipment_attrs.get("attack", 0) > 60:
		print("✅ 装备属性计算功能正常")
	else:
		print("❌ 装备属性计算功能异常")
	
	# 测试强化成功率
	var success_rate = get_enhancement_success_rate(0, 15)
	if success_rate > 0:
		print("✅ 强化成功率计算正常")
	else:
		print("❌ 强化成功率计算异常")
	
	print("装备属性计算测试完成")