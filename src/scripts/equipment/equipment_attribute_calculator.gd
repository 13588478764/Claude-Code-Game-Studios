# 武侠奇遇录 - 装备属性计算系统
# 实现基础属性、强化加成、宝石效果和流派加成的计算公式

extends Node

# 信号定义
signal attributes_calculated(character_id, calculated_attributes)
signal equipment_modified(equipment_id, modification_type)

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

# 宝石类型枚举
enum GemType {
	RED_GEM,      # 红宝石 - 攻击/火系
	BLUE_GEM,     # 蓝宝石 - 防御/水系
	GREEN_GEM,    # 绿宝石 - 生命/毒系
	YELLOW_GEM,   # 黄宝石 - 暴击/雷系
	PURPLE_GEM,   # 紫宝石 - 冷却/内力
	DIAMOND_GEM   # 钻石 - 全抗/幸运
}

# 属性类型枚举
enum AttributeType {
	STRENGTH,      # 力道
	DEXTERITY,     # 身法
	CONSTITUTION,  # 根骨
	INTELLIGENCE,  # 悟性
	FOCUS,         # 定力
	LUCK           # 福缘
}

# 装备数据结构
class EquipmentData:
	var id: String
	var name: String
	var type: EquipmentType
	var rarity: EquipmentRarity
	var level_requirement: int
	var base_attributes: Dictionary  # 基础属性
	var enhancement_level: int
	var gems: Array  # 镶嵌的宝石
	var is_bound: bool
	var martial_art_school: String  # 武学流派加成
	var additional_affixes: Array  # 附加词条
	var acquisition_source: String  # 获取来源
	
	func _init(p_id: String, p_name: String, p_type: EquipmentType, p_rarity: EquipmentRarity):
		id = p_id
		name = p_name
		type = p_type
		rarity = p_rarity
		level_requirement = 1
		base_attributes = {}
		enhancement_level = 0
		gems = []
		is_bound = false
		martial_art_school = ""
		additional_affixes = []
		acquisition_source = "unknown"

# 常量定义
const RARITY_MULTIPLIERS = {
	EquipmentRarity.COMMON: 1.0,
	EquipmentRarity.UNCOMMON: 1.5,
	EquipmentRarity.RARE: 2.0,
	EquipmentRarity.LEGENDARY: 3.0
}

const ENHANCEMENT_MULTIPLIER = 0.03  # 每级强化增加3%基础属性
const DECAY_FACTOR = 0.04  # 强化成功率衰减系数
const GEM_EFFECT_VALUES = {
	GemType.RED_GEM: {"attack": 10, "fire_damage": 5},
	GemType.BLUE_GEM: {"defense": 8, "water_resistance": 10},
	GemType.GREEN_GEM: {"hp": 50, "poison_resistance": 10},
	GemType.YELLOW_GEM: {"critical_rate": 3, "thunder_damage": 5},
	GemType.PURPLE_GEM: {"cooldown_reduction": 5, "mana": 20},
	GemType.DIAMOND_GEM: {"all_resistance": 5, "luck": 2}
}

# 依赖的其他系统
var equipment_manager = null
var martial_arts_manager = null
var character_stats = null

func _ready():
	print("装备属性计算系统初始化完成")

# 设置依赖系统
func set_dependencies(equip_mgr, martial_arts_mgr, char_stats):
	equipment_manager = equip_mgr
	martial_arts_manager = martial_arts_mgr
	character_stats = char_stats
	print("装备属性计算系统已连接到其他管理系统")

# 计算装备基础属性
func calculate_base_attributes(equipment_data: EquipmentData) -> Dictionary:
	var base_attrs = equipment_data.base_attributes.duplicate()
	
	# 根据品阶调整基础属性
	for attr_name in base_attrs:
		base_attrs[attr_name] *= RARITY_MULTIPLIERS[equipment_data.rarity]
	
	return base_attrs

# 计算强化属性加成
func calculate_enhancement_bonus(equipment_data: EquipmentData) -> Dictionary:
	var enhancement_bonus = {}
	
	# 根据强化等级计算属性加成
	for attr_name in equipment_data.base_attributes:
		var base_value = equipment_data.base_attributes[attr_name]
		var enhancement_value = base_value * ENHANCEMENT_MULTIPLIER * equipment_data.enhancement_level
		enhancement_bonus[attr_name] = enhancement_value
	
	# 强化等级达到+10/+15/+20时提供额外全局加成
	if equipment_data.enhancement_level >= 20:
		enhancement_bonus["global_multiplier"] = 0.2  # 20%全局加成
	elif equipment_data.enhancement_level >= 15:
		enhancement_bonus["global_multiplier"] = 0.15  # 15%全局加成
	elif equipment_data.enhancement_level >= 10:
		enhancement_bonus["global_multiplier"] = 0.1   # 10%全局加成
	
	return enhancement_bonus

# 计算宝石效果
func calculate_gem_effects(gems_array: Array) -> Dictionary:
	var gem_effects = {}
	
	# 统计各类宝石数量
	var gem_counts = {}
	for gem in gems_array:
		if gem_counts.has(gem):
			gem_counts[gem] += 1
		else:
			gem_counts[gem] = 1
	
	# 应用单个宝石效果
	for gem_type in gem_counts:
		var count = gem_counts[gem_type]
		var effect_template = GEM_EFFECT_VALUES[gem_type]
		
		for attr_name in effect_template:
			if gem_effects.has(attr_name):
				gem_effects[attr_name] += effect_template[attr_name] * count
			else:
				gem_effects[attr_name] = effect_template[attr_name] * count
	
	# 检查套装效果（相同颜色宝石达到一定数量时激活）
	var套装_effects = calculate_gem_set_effects(gem_counts)
	for attr_name in 套装_effects:
		if gem_effects.has(attr_name):
			gem_effects[attr_name] += 套装_effects[attr_name]
		else:
			gem_effects[attr_name] = 套装_effects[attr_name]
	
	return gem_effects

# 计算宝石套装效果
func calculate_gem_set_effects(gem_counts: Dictionary) -> Dictionary:
	var set_effects = {}
	
	# 检查每种宝石的套装效果
	for gem_type in gem_counts:
		var count = gem_counts[gem_type]
		
		# 3颗同色宝石激活基础套装效果
		if count >= 3:
			match gem_type:
				GemType.RED_GEM:
					set_effects["fire_damage_bonus"] = 15
					set_effects["attack_speed"] = 5
				GemType.BLUE_GEM:
					set_effects["magic_resistance"] = 20
					set_effects["mana_regeneration"] = 10
				GemType.GREEN_GEM:
					set_effects["hp_regeneration"] = 15
					set_effects["poison_immunity"] = 1
				GemType.YELLOW_GEM:
					set_effects["critical_damage"] = 25
					set_effects["movement_speed"] = 8
				GemType.PURPLE_GEM:
					set_effects["skill_power"] = 20
					set_effects["cooldown_reduction"] = 10
				GemType.DIAMOND_GEM:
					set_effects["all_resistance"] = 15
					set_effects["lucky_chest_chance"] = 5
		
		# 6颗同色宝石激活高级套装效果
		if count >= 6:
			match gem_type:
				GemType.RED_GEM:
					set_effects["fire_damage_bonus"] = 30
					set_effects["burn_chance"] = 15
				GemType.BLUE_GEM:
					set_effects["ice_effect"] = 1
					set_effects["damage_reduction"] = 15
				GemType.GREEN_GEM:
					set_effects["life_steal"] = 10
					set_effects["healing_bonus"] = 25
				GemType.YELLOW_GEM:
					set_effects["chain_lightning"] = 1
					set_effects["stun_chance"] = 10
				GemType.PURPLE_GEM:
					set_effects["mana_leak"] = 20
					set_effects["spell_vampirism"] = 8
				GemType.DIAMOND_GEM:
					set_effects["immunity_buff"] = 1
					set_effects["fortune_effect"] = 15
	
	# 检查跨颜色套装效果
	var total_gems = 0
	for count in gem_counts.values():
		total_gems += count
	
	if total_gems >= 9:
		set_effects["global_attribute_bonus"] = 10  # 所有属性+10
		set_effects["experience_bonus"] = 15       # 经验获取+15%
	
	return set_effects

# 计算流派加成
func calculate_school_bonus(equipment_data: EquipmentData, current_school: String) -> Dictionary:
	var school_bonus = {}
	
	# 如果装备有特定流派加成且与当前流派匹配
	if equipment_data.martial_art_school != "" and equipment_data.martial_art_school == current_school:
		# 根据装备品阶提供流派加成
		var bonus_multiplier = 0.0
		match equipment_data.rarity:
			EquipmentRarity.COMMON: bonus_multiplier = 0.05   # 5%
			EquipmentRarity.UNCOMMON: bonus_multiplier = 0.10  # 10%
			EquipmentRarity.RARE: bonus_multiplier = 0.15     # 15%
			EquipmentRarity.LEGENDARY: bonus_multiplier = 0.20 # 20%
		
		# 将品阶加成应用到基础属性上
		for attr_name in equipment_data.base_attributes:
			var base_value = equipment_data.base_attributes[attr_name]
			var school_bonus_value = base_value * bonus_multiplier
			school_bonus[attr_name] = school_bonus_value
		
		# 特定流派的额外效果
		match current_school:
			"武当派":
				school_bonus["internal_force_efficiency"] = 15
				school_bonus["meditation_bonus"] = 10
			"少林派":
				school_bonus["physical_resistance"] = 12
				school_bonus["stamina_regen"] = 8
			"峨眉派":
				school_bonus["healing_power"] = 20
				school_bonus["debuff_duration"] = -15
			"逍遥派":
				school_bonus["evasion"] = 10
				school_bonus["poison_mastery"] = 15
			"天山派":
				school_bonus["ice_damage"] = 18
				school_bonus["cold_immunity"] = 1
	
	return school_bonus

# 计算单件装备的总属性
func calculate_single_equipment_total(equipment_data: EquipmentData, current_school: String = "") -> Dictionary:
	var total_attributes = {}
	
	# 1. 计算基础属性
	var base_attrs = calculate_base_attributes(equipment_data)
	for attr_name in base_attrs:
		total_attributes[attr_name] = base_attrs[attr_name]
	
	# 2. 计算强化加成
	var enhancement_attrs = calculate_enhancement_bonus(equipment_data)
	for attr_name in enhancement_attrs:
		if total_attributes.has(attr_name):
			total_attributes[attr_name] += enhancement_attrs[attr_name]
		else:
			total_attributes[attr_name] = enhancement_attrs[attr_name]
	
	# 3. 计算宝石效果
	var gem_attrs = calculate_gem_effects(equipment_data.gems)
	for attr_name in gem_attrs:
		if total_attributes.has(attr_name):
			total_attributes[attr_name] += gem_attrs[attr_name]
		else:
			total_attributes[attr_name] = gem_attrs[attr_name]
	
	# 4. 计算流派加成
	if current_school != "":
		var school_attrs = calculate_school_bonus(equipment_data, current_school)
		for attr_name in school_attrs:
			if total_attributes.has(attr_name):
				total_attributes[attr_name] += school_attrs[attr_name]
			else:
				total_attributes[attr_name] = school_attrs[attr_name]
	
	# 5. 应用全局乘数（来自强化等级的额外加成）
	if total_attributes.has("global_multiplier"):
		var multiplier = total_attributes["global_multiplier"]
		# 移除临时的全局乘数键
		var temp_multiplier = total_attributes["global_multiplier"]
		total_attributes.erase("global_multiplier")
		
		# 将乘数应用于所有数值属性
		for attr_name in total_attributes:
			if typeof(total_attributes[attr_name]) == TYPE_INT or typeof(total_attributes[attr_name]) == TYPE_FLOAT:
				total_attributes[attr_name] = total_attributes[attr_name] * (1 + temp_multiplier)
	
	return total_attributes

# 计算角色整体装备属性
func calculate_total_equipment_attributes(equipped_items: Array, current_school: String = "") -> Dictionary:
	var total_attributes = {}
	
	# 遍历所有已装备的物品
	for equipment_data in equipped_items:
		if equipment_data != null:
			var equipment_attrs = calculate_single_equipment_total(equipment_data, current_school)
			
			# 累加到总属性
			for attr_name in equipment_attrs:
				if total_attributes.has(attr_name):
					total_attributes[attr_name] += equipment_attrs[attr_name]
				else:
					total_attributes[attr_name] = equipment_attrs[attr_name]
	
	# 应用装备件数相关的套装效果
	var set_bonuses = calculate_equipment_set_bonuses(equipped_items)
	for attr_name in set_bonuses:
		if total_attributes.has(attr_name):
			total_attributes[attr_name] += set_bonuses[attr_name]
		else:
			total_attributes[attr_name] = set_bonuses[attr_name]
	
	return total_attributes

# 计算装备套装效果
func calculate_equipment_set_bonuses(equipped_items: Array) -> Dictionary:
	var set_bonuses = {}
	
	# 统计装备类型
	var equipment_types = {}
	var equipment_sets = {}
	
	for equipment in equipped_items:
		if equipment != null:
			# 按装备名称统计（相同名称为同一套）
			var equip_name = equipment.name.split(" ")[0]  # 假设套装名称在前面
			if equipment_sets.has(equip_name):
				equipment_sets[equip_name] += 1
			else:
				equipment_sets[equip_name] = 1
	
	# 应用套装效果
	for set_name in equipment_sets:
		var count = equipment_sets[set_name]
		
		# 2件套效果
		if count >= 2:
			set_bonuses["defense_bonus"] = 5
			set_bonuses["attribute_bonus"] = 5
		
		# 4件套效果
		if count >= 4:
			set_bonuses["defense_bonus"] += 10
			set_bonuses["attribute_bonus"] += 10
			set_bonuses["resistance_bonus"] = 10
		
		# 6件套效果
		if count >= 6:
			set_bonuses["defense_bonus"] += 15
			set_bonuses["attribute_bonus"] += 15
			set_bonuses["resistance_bonus"] += 15
			set_bonuses["special_effect"] = 1  # 激活特殊效果
	
	return set_bonuses

# 计算强化成功率
func calculate_enhancement_success_rate(current_level: int, target_level: int) -> float:
	if target_level <= current_level:
		return 0.0  # 目标等级不高于当前等级
	
	# 计算从当前等级到目标等级的累积成功率
	var success_rate = 1.0
	for level in range(current_level + 1, target_level + 1):
		var base_success_rate = 1.0  # +1~+10的基础成功率是100%
		
		if level > 10:
			# +11开始成功率开始衰减
			base_success_rate = 0.8 - ((level - 10) * DECAY_FACTOR)
		
		# 确保成功率不低于最小值
		base_success_rate = max(0.05, base_success_rate)
		
		success_rate *= base_success_rate
	
	return success_rate

# 计算最终属性（整合所有角色属性和装备属性）
func calculate_final_attributes(character_base_attributes: Dictionary, equipment_attributes: Dictionary) -> Dictionary:
	var final_attributes = character_base_attributes.duplicate()
	
	# 将装备属性加到角色基础属性上
	for attr_name in equipment_attributes:
		if final_attributes.has(attr_name):
			final_attributes[attr_name] += equipment_attributes[attr_name]
		else:
			final_attributes[attr_name] = equipment_attributes[attr_name]
	
	# 应用属性间的相互影响（例如：根骨影响生命值，悟性影响内力等）
	final_attributes = apply_attribute_synergies(final_attributes)
	
	return final_attributes

# 应用属性间协同效应
func apply_attribute_synergies(attributes: Dictionary) -> Dictionary:
	var final_attrs = attributes.duplicate()
	
	# 根据根骨(CONSTITUTION)增加生命值
	if final_attrs.has("constitution") and final_attrs.has("hp_base"):
		final_attrs["hp"] = final_attrs["hp_base"] + (final_attrs["constitution"] * 10)
	
	# 根据悟性(INTELLIGENCE)增加内力值
	if final_attrs.has("intelligence") and final_attrs.has("mana_base"):
		final_attrs["mana"] = final_attrs["mana_base"] + (final_attrs["intelligence"] * 8)
	
	# 根据身法(DEXTERITY)增加闪避率
	if final_attrs.has("dexterity"):
		if final_attrs.has("evasion_base"):
			final_attrs["evasion"] = final_attrs["evasion_base"] + (final_attrs["dexterity"] * 0.5)
		else:
			final_attrs["evasion"] = final_attrs["dexterity"] * 0.5
	
	# 根据力道(STRENGTH)增加物理攻击力
	if final_attrs.has("strength"):
		if final_attrs.has("attack_base"):
			final_attrs["attack"] = final_attrs["attack_base"] + (final_attrs["strength"] * 1.5)
		else:
			final_attrs["attack"] = final_attrs["strength"] * 1.5
	
	# 根据定力(FOCUS)增加抗性
	if final_attrs.has("focus"):
		if final_attrs.has("resistance_base"):
			final_attrs["resistance"] = final_attrs["resistance_base"] + (final_attrs["focus"] * 0.8)
		else:
			final_attrs["resistance"] = final_attrs["focus"] * 0.8
	
	return final_attrs

# 获取装备评分
func evaluate_equipment_score(equipment_data: EquipmentData, current_school: String = "") -> float:
	var attrs = calculate_single_equipment_total(equipment_data, current_school)
	var score = 0.0
	
	# 为不同属性分配权重来计算总分
	for attr_name in attrs:
		var value = attrs[attr_name]
		var weight = get_attribute_weight(attr_name)
		score += value * weight
	
	# 根据品阶和强化等级增加基础分数
	score *= RARITY_MULTIPLIERS[equipment_data.rarity]
	score *= (1 + (equipment_data.enhancement_level * 0.1))
	
	return score

# 获取属性权重
func get_attribute_weight(attr_name: String) -> float:
	# 定义不同属性的权重
	var weights = {
		"attack": 1.0,
		"defense": 0.8,
		"hp": 0.5,
		"critical_rate": 1.5,
		"critical_damage": 1.2,
		"evasion": 1.0,
		"resistance": 0.7,
		"speed": 0.9,
		"mana": 0.6
	}
	
	return weights.get(attr_name, 0.5)  # 默认权重0.5

# 更新装备强化等级
func update_equipment_enhancement(equipment_id: String, enhancement_level: int) -> bool:
	if equipment_manager:
		var equipment = equipment_manager.find_equipment_by_id(equipment_id)
		if equipment:
			equipment.enhancement_level = enhancement_level
			emit_signal("equipment_modified", equipment_id, "enhancement")
			return true
	
	return false

# 镶嵌宝石到装备
func insert_gem_into_equipment(equipment_id: String, gem_type: GemType) -> bool:
	if equipment_manager:
		var equipment = equipment_manager.find_equipment_by_id(equipment_id)
		if equipment and equipment.gems.size() < 3:  # 最多3颗宝石
			equipment.gems.append(gem_type)
			emit_signal("equipment_modified", equipment_id, "gem_insertion")
			return true
	
	return false

# 移除装备上的宝石
func remove_gem_from_equipment(equipment_id: String, gem_index: int) -> bool:
	if equipment_manager:
		var equipment = equipment_manager.find_equipment_by_id(equipment_id)
		if equipment and gem_index < equipment.gems.size():
			equipment.gems.remove_at(gem_index)
			emit_signal("equipment_modified", equipment_id, "gem_removal")
			return true
	
	return false