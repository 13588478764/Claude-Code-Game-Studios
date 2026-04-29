## EquipmentBonusApplier
## 装备加成应用器
负责应用装备特殊效果、状态抗性和属性叠加逻辑
##
## 主要功能：
## - 待补充

extends Node

class_name EquipmentBonusApplier

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

# 六维基础属性结构
class BaseAttributes:
	var strength: int = 0      # 力道
	var agility: int = 0       # 身法
	var constitution: int = 0  # 根骨
	var intelligence: int = 0   # 悟性
	var willpower: int = 0     # 定力
	var luck: int = 0         # 福缘

# 战斗属性结构
class CombatAttributes:
	var attack: int = 0                    # 攻击力
	var defense: int = 0                   # 防御力
	var max_health: int = 0               # 生命值上限
	var critical_rate: float = 0.0         # 暴击率
	var critical_damage: float = 0.0       # 暴击伤害
	var hit_rate: float = 0.0             # 命中率
	var evasion: float = 0.0              # 闪避率
	var max_internal_energy: int = 0      # 内力上限
	var internal_energy_regen: float = 0.0 # 内力回复率

# 状态抗性结构
class StatusResistances:
	var poison: float = 0.0  # 中毒抗性
	var stun: float = 0.0    # 眩晕抗性
	var freeze: float = 0.0  # 冰冻抗性
	var burn: float = 0.0    # 燃烧抗性

# 装备属性结构
class EquipmentAttributes:
	var base_attributes: BaseAttributes
	var combat_attributes: CombatAttributes
	var status_resistances: StatusResistances
	var martial_art_bonuses: float = 0.0  # 武学技能效果增强
	var cooldown_reduction: float = 0.0    # 冷却时间减少

# 角色总属性结构
class CharacterTotalAttributes:
	var base: BaseAttributes
	var combat: CombatAttributes
	var resistances: StatusResistances

# 信号定义
signal bonus_applied(character_id: String, applied_bonuses: Dictionary)

# 初始化
func _ready():
	print("装备加成应用器已初始化")

# 应用装备特殊效果
func apply_special_effects(equipped_items: Array) -> Dictionary:
	var special_effects = {}
	
	for item in equipped_items:
		if item.has("attributes") and item.attributes.has("martial_art_bonuses"):
			var bonus = item.attributes.martial_art_bonuses
			if bonus != 0:
				if not special_effects.has("martial_art_bonuses"):
					special_effects["martial_art_bonuses"] = 0
				special_effects["martial_art_bonuses"] += bonus
		
		if item.has("attributes") and item.attributes.has("cooldown_reduction"):
			var reduction = item.attributes.cooldown_reduction
			if reduction != 0:
				if not special_effects.has("cooldown_reduction"):
					special_effects["cooldown_reduction"] = 0
				special_effects["cooldown_reduction"] += reduction
	
	return special_effects

# 计算状态抗性
func calculate_status_resistances(equipped_items: Array) -> StatusResistances:
	var resistances = StatusResistances.new()
	
	for item in equipped_items:
		if item.has("attributes") and item.attributes.has("status_resistances"):
			var attr = item.attributes.status_resistances
			resistances.poison += attr.get("poison", 0.0)
			resistances.stun += attr.get("stun", 0.0)
			resistances.freeze += attr.get("freeze", 0.0)
			resistances.burn += attr.get("burn", 0.0)
	
	return resistances

# 处理线性叠加属性
func apply_linear_bonuses(equipped_items: Array) -> BaseAttributes:
	var linear_bonuses = BaseAttributes.new()
	
	for item in equipped_items:
		if item.has("attributes") and item.attributes.has("base_attributes"):
			var attr = item.attributes.base_attributes
			linear_bonuses.strength += attr.get("strength", 0)
			linear_bonuses.agility += attr.get("agility", 0)
			linear_bonuses.constitution += attr.get("constitution", 0)
			linear_bonuses.intelligence += attr.get("intelligence", 0)
			linear_bonuses.willpower += attr.get("willpower", 0)
			linear_bonuses.luck += attr.get("luck", 0)
	
	return linear_bonuses

# 处理乘法叠加属性
func apply_multiplicative_bonuses(equipped_items: Array, base_values: CombatAttributes) -> CombatAttributes:
	var result = CombatAttributes.new()
	
	# 复制基础值
	result.attack = base_values.attack
	result.defense = base_values.defense
	result.max_health = base_values.max_health
	result.critical_rate = base_values.critical_rate
	result.critical_damage = base_values.critical_damage
	result.hit_rate = base_values.hit_rate
	result.evasion = base_values.evasion
	result.max_internal_energy = base_values.max_internal_energy
	result.internal_energy_regen = base_values.internal_energy_regen
	
	# 计算乘法加成
	var crit_rate_multiplier = 1.0
	var crit_dmg_multiplier = 1.0
	var hit_rate_multiplier = 1.0
	var evasion_multiplier = 1.0
	
	for item in equipped_items:
		if item.has("attributes") and item.attributes.has("combat_attributes"):
			var attr = item.attributes.combat_attributes
			
			# 暴击率乘法叠加
			if attr.has("critical_rate"):
				crit_rate_multiplier *= (1.0 + attr.critical_rate)
			
			# 暴击伤害乘法叠加
			if attr.has("critical_damage"):
				crit_dmg_multiplier *= (1.0 + attr.critical_damage)
			
			# 命中率乘法叠加
			if attr.has("hit_rate"):
				hit_rate_multiplier *= (1.0 + attr.hit_rate)
			
			# 闪避率乘法叠加
			if attr.has("evasion"):
				evasion_multiplier *= (1.0 + attr.evasion)
	
	# 应用乘法结果
	result.critical_rate = (result.critical_rate + 1.0) * crit_rate_multiplier - 1.0
	result.critical_damage = (result.critical_damage + 1.0) * crit_dmg_multiplier - 1.0
	result.hit_rate = (result.hit_rate + 1.0) * hit_rate_multiplier - 1.0
	result.evasion = (result.evasion + 1.0) * evasion_multiplier - 1.0
	
	return result

# 应用装备加成到角色属性
func apply_equipment_bonuses(character_attributes: CharacterTotalAttributes, equipped_items: Array) -> CharacterTotalAttributes:
	var result = CharacterTotalAttributes.new()
	
	# 复制基础属性
	result.base = BaseAttributes.new()
	result.base.strength = character_attributes.base.strength
	result.base.agility = character_attributes.base.agility
	result.base.constitution = character_attributes.base.constitution
	result.base.intelligence = character_attributes.base.intelligence
	result.base.willpower = character_attributes.base.willpower
	result.base.luck = character_attributes.base.luck
	
	result.combat = CombatAttributes.new()
	result.combat.attack = character_attributes.combat.attack
	result.combat.defense = character_attributes.combat.defense
	result.combat.max_health = character_attributes.combat.max_health
	result.combat.critical_rate = character_attributes.combat.critical_rate
	result.combat.critical_damage = character_attributes.combat.critical_damage
	result.combat.hit_rate = character_attributes.combat.hit_rate
	result.combat.evasion = character_attributes.combat.evasion
	result.combat.max_internal_energy = character_attributes.combat.max_internal_energy
	result.combat.internal_energy_regen = character_attributes.combat.internal_energy_regen
	
	result.resistances = StatusResistances.new()
	result.resistances.poison = character_attributes.resistances.poison
	result.resistances.stun = character_attributes.resistances.stun
	result.resistances.freeze = character_attributes.resistances.freeze
	result.resistances.burn = character_attributes.resistances.burn
	
	# 应用线性叠加的基础属性
	var linear_bonuses = apply_linear_bonuses(equipped_items)
	result.base.strength += linear_bonuses.strength
	result.base.agility += linear_bonuses.agility
	result.base.constitution += linear_bonuses.constitution
	result.base.intelligence += linear_bonuses.intelligence
	result.base.willpower += linear_bonuses.willpower
	result.base.luck += linear_bonuses.luck
	
	# 应用乘法叠加的战斗属性
	result.combat = apply_multiplicative_bonuses(equipped_items, result.combat)
	
	# 应用状态抗性
	var resistance_bonuses = calculate_status_resistances(equipped_items)
	result.resistances.poison += resistance_bonuses.poison
	result.resistances.stun += resistance_bonuses.stun
	result.resistances.freeze += resistance_bonuses.freeze
	result.resistances.burn += resistance_bonuses.burn
	
	# 应用特殊效果
	var special_effects = apply_special_effects(equipped_items)
	
	# 发出应用完成信号
	emit_signal("bonus_applied", "unknown", {
		"linear_bonuses": linear_bonuses,
		"multiplicative_bonuses": result.combat,
		"resistance_bonuses": resistance_bonuses,
		"special_effects": special_effects
	})
	
	return result

# 测试函数
func test_equipment_bonus_application():
	print("开始测试装备加成应用...")
	
	# 创建测试角色属性
	var test_character_attributes = CharacterTotalAttributes.new()
	test_character_attributes.base = BaseAttributes.new()
	test_character_attributes.base.strength = 20
	test_character_attributes.base.agility = 15
	test_character_attributes.base.constitution = 18
	test_character_attributes.base.intelligence = 12
	test_character_attributes.base.willpower = 14
	test_character_attributes.base.luck = 10
	
	test_character_attributes.combat = CombatAttributes.new()
	test_character_attributes.combat.attack = 50
	test_character_attributes.combat.defense = 30
	test_character_attributes.combat.max_health = 200
	test_character_attributes.combat.critical_rate = 0.05  # 5%暴击率
	test_character_attributes.combat.critical_damage = 0.25  # 25%暴击伤害
	test_character_attributes.combat.hit_rate = 0.95  # 95%命中率
	test_character_attributes.combat.evasion = 0.05  # 5%闪避率
	test_character_attributes.combat.max_internal_energy = 100
	test_character_attributes.combat.internal_energy_regen = 0.05
	
	test_character_attributes.resistances = StatusResistances.new()
	test_character_attributes.resistances.poison = 0.1  # 10%中毒抗性
	test_character_attributes.resistances.stun = 0.05   # 5%眩晕抗性
	test_character_attributes.resistances.freeze = 0.0  # 0%冰冻抗性
	test_character_attributes.resistances.burn = 0.05   # 5%燃烧抗性
	
	# 创建测试装备
	var test_equipment = [
		{
			"id": "weapon_001",
			"attributes": {
				"base_attributes": {
					"strength": 10,
					"intelligence": 5
				},
				"combat_attributes": {
					"attack": 20,
					"critical_rate": 0.03,  # 3%额外暴击率
					"critical_damage": 0.15  # 15%额外暴击伤害
				},
				"status_resistances": {
					"poison": 0.1,  # 10%额外中毒抗性
					"burn": 0.05    # 5%额外燃烧抗性
				},
				"martial_art_bonuses": 0.1,  # 10%武学效果增强
				"cooldown_reduction": 0.1     # 10%冷却缩减
			}
		},
		{
			"id": "armor_001",
			"attributes": {
				"base_attributes": {
					"constitution": 8,
					"agility": 3
				},
				"combat_attributes": {
					"defense": 25,
					"max_health": 80,
					"evasion": 0.08  # 8%额外闪避率
				},
				"status_resistances": {
					"stun": 0.15,    # 15%眩晕抗性
					"freeze": 0.1   # 10%冰冻抗性
				}
			}
		}
	]
	
	# 应用装备加成
	var result = apply_equipment_bonuses(test_character_attributes, test_equipment)
	
	print("应用装备加成后的角色属性:")
	print("  基础属性:")
	print("    力道: ", result.base.strength)
	print("    身法: ", result.base.agility)
	print("    根骨: ", result.base.constitution)
	print("    悟性: ", result.base.intelligence)
	print("    定力: ", result.base.willpower)
	print("    福缘: ", result.base.luck)
	print("  战斗属性:")
	print("    攻击力: ", result.combat.attack)
	print("    防御力: ", result.combat.defense)
	print("    生命上限: ", result.combat.max_health)
	print("    暴击率: ", result.combat.critical_rate)
	print("    暴击伤害: ", result.combat.critical_damage)
	print("    命中率: ", result.combat.hit_rate)
	print("    闪避率: ", result.combat.evasion)
	print("  状态抗性:")
	print("    中毒抗性: ", result.resistances.poison)
	print("    眩晕抗性: ", result.resistances.stun)
	print("    冰冻抗性: ", result.resistances.freeze)
	print("    燃烧抗性: ", result.resistances.burn)
	
	print("装备加成应用测试完成")