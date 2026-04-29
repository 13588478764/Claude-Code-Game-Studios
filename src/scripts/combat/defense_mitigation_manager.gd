## DefenseMitigationManager
## 防御减伤管理器
##
## 管理各种防御类型的系统，实现护甲减伤、内力抗性、闪避和格挡机制。
## 
## 功能：
## - 护甲减伤（外功防御）
## - 内力抗性（内功/元素防御）
## - 闪避机制（基于身法）
## - 格挡机制（普通格挡和完美格挡）
##
## 依赖系统：
## - EquipmentSystem（装备系统）
## - CharacterProgressionSystem（角色成长系统）

extends Node
class_name DefenseMitigationManager

# ============================================================================
# 常量定义
# ============================================================================

const DEFAULT_CON_STAT: int = 10  # 默认根骨
const DEFAULT_WIS_STAT: int = 10  # 默认悟性
const DEFAULT_AGI_STAT: int = 10  # 默认身法

const ARMOR_PER_CON: int = 1  # 每点根骨提供的护甲值
const RESISTANCE_PER_WIS: float = 0.01  # 每点悟性提供的抗性（1%）
const DODGE_PER_AGI: float = 0.02  # 每点身法提供的闪避率（2%）

const MIN_RESISTANCE: float = 0.0  # 最小抗性
const MAX_RESISTANCE: float = 0.8  # 最大抗性（80%）
const MIN_DODGE_RATE: float = 0.0  # 最小闪避率
const MAX_DODGE_RATE: float = 0.5  # 最大闪避率（50%）

const DEFAULT_BLOCK_REDUCTION: float = 0.5  # 普通格挡减伤比例（50%）
const PERFECT_BLOCK_REDUCTION: float = 1.0  # 完美格挡减伤比例（100%）

# ============================================================================
# 信号定义
# ============================================================================

signal defense_applied(defense_type: String, reduction_amount: int)
signal dodge_triggered()
signal block_triggered()
signal defense_values_updated(armor: int, resistance: float, dodge: float)

# ============================================================================
# 属性定义
# ============================================================================

# 角色属性
var con_stat: int = DEFAULT_CON_STAT  # 根骨
var wis_stat: int = DEFAULT_WIS_STAT  # 悟性
var agi_stat: int = DEFAULT_AGI_STAT  # 身法

# 装备加成
var equipment_armor_bonus: int = 0
var equipment_resistance_bonus: float = 0.0

# 防御值（计算结果）
var armor_value: int = 0  # 护甲值（外功减伤）
var qi_resistance: float = 0.0  # 内力抗性（内功/元素减伤）
var dodge_rate: float = 0.0  # 闪避率

# 格挡效果
var block_reduction: float = DEFAULT_BLOCK_REDUCTION  # 格挡时减少的伤害比例
var perfect_block_multiplier: float = PERFECT_BLOCK_REDUCTION  # 完美格挡时的伤害减免

# 系统引用
var equipment_system: Node = null
var character_progression_system: Node = null

# 初始化
func _ready():
	# 初始化防御属性
	update_defense_values()

# 更新防御属性值
func update_defense_values():
	# 计算护甲值（来自装备和根骨）
	armor_value = equipment_armor_bonus + con_stat
	
	# 计算内力抗性（来自装备和悟性）
	qi_resistance = equipment_resistance_bonus + (wis_stat * 0.01)
	qi_resistance = clamp(qi_resistance, 0.0, 0.8)  # 限制在0-80%范围内
	
	# 计算闪避率（来自身法）
	dodge_rate = agi_stat * 0.02
	dodge_rate = clamp(dodge_rate, 0.0, 0.5)  # 限制在0-50%范围内

# 计算护甲减伤
func calculate_armor_reduction(raw_damage: int) -> int:
	var reduction = min(armor_value, raw_damage - 1)  # 确保最终伤害至少为1
	reduction = max(reduction, 0)  # 确保减伤值不为负
	
	emit_signal("defense_applied", "armor", reduction)
	return reduction

# 计算内力抗性减伤
func calculate_resistance_reduction(raw_damage: int) -> int:
	var resistance_effect = clamp(qi_resistance, 0.0, 0.8)  # 确保抗性在范围内
	var reduction = int(float(raw_damage) * resistance_effect)
	
	emit_signal("defense_applied", "resistance", reduction)
	return reduction

# 计算闪避概率
func calculate_dodge_chance() -> bool:
	var random_value = randf()
	var is_dodged = random_value < dodge_rate
	
	if is_dodged:
		emit_signal("dodge_triggered")
	
	return is_dodged

# 计算格挡减伤
func calculate_block_mitigation(raw_damage: int, is_perfect_block: bool = false) -> int:
	var reduction: int
	
	if is_perfect_block:
		# 完美格挡：完全抵消伤害并反弹少量架势伤害
		reduction = raw_damage
		# 可以在这里添加反击逻辑
	else:
		# 普通格挡：减少一定百分比的伤害
		reduction = int(float(raw_damage) * block_reduction)
	
	emit_signal("block_triggered")
	emit_signal("defense_applied", "block", reduction)
	return reduction

# 应用防御到伤害
func apply_defense_to_damage(raw_damage: int, damage_type: String = "physical", is_heavy_attack: bool = false) -> int:
	var final_damage = raw_damage
	
	# 检查是否闪避
	if calculate_dodge_chance():
		# 闪避成功，完全免伤
		return 0
	
	# 根据伤害类型应用不同的防御
	if damage_type == "physical" or damage_type == "external":
		# 物理/外功伤害主要受护甲影响
		var armor_reduction = calculate_armor_reduction(final_damage)
		final_damage -= armor_reduction
	elif damage_type == "magical" or damage_type == "internal" or damage_type == "elemental":
		# 魔法/内功/元素伤害主要受内力抗性影响
		var resistance_reduction = calculate_resistance_reduction(final_damage)
		final_damage -= resistance_reduction
	else:
		# 通用伤害类型，同时应用护甲和抗性
		var armor_reduction = calculate_armor_reduction(final_damage)
		final_damage -= armor_reduction
		
		var resistance_reduction = calculate_resistance_reduction(final_damage)
		final_damage -= resistance_reduction
	
	# 确保最终伤害至少为1（除非被闪避）
	if final_damage > 0:
		final_damage = max(final_damage, 1)
	
	return final_damage

# 应用格挡到伤害
func apply_block_to_damage(raw_damage: int, is_perfect_block: bool = false) -> int:
	var block_reduction = calculate_block_mitigation(raw_damage, is_perfect_block)
	var final_damage = max(raw_damage - block_reduction, 0)
	
	# 如果是完美格挡，确保伤害被完全抵消
	if is_perfect_block:
		final_damage = 0
	
	# 确保最终伤害至少为1（除非被完全格挡或完美格挡）
	if not is_perfect_block and final_damage > 0:
		final_damage = max(final_damage, 1)
	
	return final_damage

# 获取当前防御信息
func get_defense_info() -> Dictionary:
	return {
		"armor_value": armor_value,
		"qi_resistance": qi_resistance,
		"dodge_rate": dodge_rate,
		"block_reduction": block_reduction
	}

# 更新角色属性
func update_character_stats(con: int, wis: int, agi: int):
	con_stat = con
	wis_stat = wis
	agi_stat = agi
	
	update_defense_values()

# 更新装备加成
func update_equipment_bonuses(armor_bonus: int, resistance_bonus: float):
	equipment_armor_bonus = armor_bonus
	equipment_resistance_bonus = resistance_bonus
	
	update_defense_values()

# 检查防御类型是否有效
func is_valid_defense_type(defense_type: String) -> bool:
	var valid_types = ["armor", "resistance", "dodge", "block"]
	return defense_type in valid_types