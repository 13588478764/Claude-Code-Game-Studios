extends Node

# 伤害倍率与修正管理器
# 实现暴击、连击、弱点和状态效果等伤害修正

# 伤害类型枚举（与DamageCalculator保持一致）
enum DamageType {
	WAI_GONG,    # 外功伤害
	NEI_GONG,    # 内功伤害
	ZHEN_SHI     # 真实伤害
}

# 元素类型枚举
enum ElementType {
	WOOD,        # 木
	FIRE,        # 火
	EARTH,       # 土
	METAL,       # 金
	WATER,       # 水
	NONE         # 无
}

# 状态效果类型枚举
enum StatusType {
	VULNERABLE,  # 易伤
	BREAK,       # 破防
	WEAKENED,    # 虚弱
	FOCUSED,     # 专注
	NONE         # 无
}

# 伤害修正结果结构
class DamageMultiplierResult:
	var critical_multiplier: float = 1.0
	var combo_multiplier: float = 1.0
	var weakness_multiplier: float = 1.0
	var status_multiplier: float = 1.0
	var total_multiplier: float = 1.0

# 信号定义
signal multipliers_applied(damage_multiplier_result)

# 计算暴击系数
func calculate_critical_multiplier(critical_chance: float = 0.0, critical_damage_bonus: float = 0.5) -> float:
	# 暴击伤害 = 基础伤害 * (1 + 暴击伤害加成)
	# 例如：暴击伤害加成为0.5，则暴击时造成1.5倍伤害
	var crit_multiplier = 1.0 + critical_damage_bonus
	crit_multiplier = clamp(crit_multiplier, 1.0, 2.5)  # 限制在1.0-2.5倍之间
	return crit_multiplier

# 计算连击系数
func calculate_combo_multiplier(combo_count: int = 0) -> float:
	# 连击加成：每段连击增加5%伤害，最高30%
	var combo_bonus = min(combo_count * 0.05, 0.30)  # 最高30%加成
	return 1.0 + combo_bonus

# 计算弱点系数
func calculate_weakness_multiplier(attack_element: ElementType, target_weakness: ElementType) -> float:
	# 弱点克制：攻击目标弱点时伤害增加1.5倍
	if attack_element == target_weakness:
		return 1.5  # 弱点伤害1.5倍
	else:
		return 1.0  # 无克制关系

# 计算状态效果修正
func calculate_status_multiplier(status_effects: Array) -> float:
	var total_multiplier: float = 1.0
	
	for status in status_effects:
		match status.type:
			StatusType.VULNERABLE:
				# 易伤：受到的所有伤害增加20%-50%
				total_multiplier *= 1.0 + status.magnitude  # magnitude通常在0.2-0.5之间
			StatusType.BREAK:
				# 破防：防御力归零，且受到额外50%伤害
				total_multiplier *= 1.5
			StatusType.WEAKENED:
				# 虚弱：攻击力降低，这里处理受到的伤害变化（如果适用）
				# 对于受到的伤害，虚弱状态可能没有直接影响
				pass
			StatusType.FOCUSED:
				# 专注：可能影响攻击伤害
				# 这里处理对受到伤害的影响（如果适用）
				pass
			_:
				# 无特殊状态
				pass
	
	return total_multiplier

# 应用所有伤害修正
func apply_damage_multipliers(
	base_damage: int,
	critical_chance: float = 0.0,
	critical_damage_bonus: float = 0.5,
	combo_count: int = 0,
	attack_element: ElementType = ElementType.NONE,
	target_weakness: ElementType = ElementType.NONE,
	status_effects: Array = []) -> DamageMultiplierResult:
	
	var result = DamageMultiplierResult.new()
	
	# 计算各项修正系数
	result.critical_multiplier = calculate_critical_multiplier(critical_chance, critical_damage_bonus)
	result.combo_multiplier = calculate_combo_multiplier(combo_count)
	result.weakness_multiplier = calculate_weakness_multiplier(attack_element, target_weakness)
	result.status_multiplier = calculate_status_multiplier(status_effects)
	
	# 计算总修正系数
	result.total_multiplier = result.critical_multiplier * result.combo_multiplier * result.weakness_multiplier * result.status_multiplier
	
	# 计算最终伤害
	var final_damage = int(base_damage * result.total_multiplier)
	
	# 确保最小伤害为1
	final_damage = max(1, final_damage)
	
	# 创建结果对象
	result.final_damage = final_damage
	
	# 发送修正应用完成信号
	emit_signal("multipliers_applied", result)
	
	return result

# 获取元素克制关系
func get_element_weakness(attacker_element: ElementType) -> ElementType:
	# 五行相克关系：木克土、土克水、水克火、火克金、金克木
	match attacker_element:
		ElementType.WOOD: return ElementType.EARTH
		ElementType.EARTH: return ElementType.WATER
		ElementType.WATER: return ElementType.FIRE
		ElementType.FIRE: return ElementType.METAL
		ElementType.METAL: return ElementType.WOOD
		_: return ElementType.NONE

# 测试函数
func test_multipliers():
	print("开始测试伤害倍率与修正...")
	
	# 测试暴击系数
	var crit_mult = calculate_critical_multiplier(0.1, 0.5)
	print("暴击系数测试: 基础1.0 + 0.5加成 = %.2f" % crit_mult)
	
	# 测试连击系数
	var combo_mult = calculate_combo_multiplier(4)
	print("连击系数测试: 4连击 = %.2f" % combo_mult)
	
	# 测试弱点系数
	var weakness_mult = calculate_weakness_multiplier(ElementType.FIRE, ElementType.METAL)
	print("弱点系数测试: 火攻击金弱点 = %.2f" % weakness_mult)
	
	# 测试状态效果修正
	var status_effects = [
		{"type": StatusType.VULNERABLE, "magnitude": 0.3},  # 易伤30%
		{"type": StatusType.BREAK, "magnitude": 0.0}        # 破防
	]
	var status_mult = calculate_status_multiplier(status_effects)
	print("状态修正测试: 易伤30% + 破防 = %.2f" % status_mult)
	
	# 测试完整修正应用
	var test_status_effects = [
		{"type": StatusType.VULNERABLE, "magnitude": 0.25}
	]
	var full_result = apply_damage_multipliers(
		100,  # 基础伤害
		0.1,   # 暴击率
		0.8,   # 暴击伤害加成
		3,     # 连击数
		ElementType.FIRE,  # 攻击元素
		ElementType.METAL, # 目标弱点
		test_status_effects # 状态效果
	)
	
	print("完整修正测试:")
	print("  基础伤害: 100")
	print("  暴击系数: %.2f" % full_result.critical_multiplier)
	print("  连击系数: %.2f" % full_result.combo_multiplier)
	print("  弱点系数: %.2f" % full_result.weakness_multiplier)
	print("  状态系数: %.2f" % full_result.status_multiplier)
	print("  总系数: %.2f" % full_result.total_multiplier)
	print("  最终伤害: %d" % full_result.final_damage)
	
	print("伤害倍率与修正测试完成")

# 状态效果数据结构示例
class StatusEffect:
	var type: StatusType
	var magnitude: float
	var duration: int
	var stacks: int = 1
	
	func _init(effect_type: StatusType, effect_magnitude: float, effect_duration: int):
		type = effect_type
		magnitude = effect_magnitude
		duration = effect_duration