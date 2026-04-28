extends Node

# 伤害计算器
# 实现伤害类型与公式，包括三种伤害类型、基础减法公式和最小伤害限制

# 伤害类型枚举
enum DamageType {
	WAI_GONG,    # 外功伤害
	NEI_GONG,    # 内功伤害
	ZHEN_SHI     # 真实伤害
}

# 伤害计算结果结构
class DamageResult:
	var final_damage: int
	var damage_type: DamageType
	var is_critical: bool
	var base_damage: int
	var defense_reduced: int

# 信号定义
signal damage_calculated(damage_result)

# 计算基础伤害
func calculate_base_damage(attacker, defender, damage_type: DamageType) -> int:
	# 根据伤害类型选择攻防计算方式
	var attack_power: int = 0
	var defense_value: int = 0
	
	match damage_type:
		DamageType.WAI_GONG:
			# 外功伤害：力道 + 武器攻击力 vs 根骨 + 护甲
			attack_power = get_attribute(attacker, "STR") + get_weapon_attack(attacker)
			defense_value = get_attribute(defender, "CON") + get_armor_value(defender)
		DamageType.NEI_GONG:
			# 内功伤害：悟性 + 内力强度 vs 悟性 + 内力抗性
			attack_power = get_attribute(attacker, "WIS") + get_internal_energy(attacker)
			defense_value = get_attribute(defender, "WIS") + get_internal_resist(defender)
		DamageType.ZHEN_SHI:
			# 真实伤害：无视防御
			attack_power = get_attribute(attacker, "WIS") + get_internal_energy(attacker)  # 真实伤害通常基于内力
			defense_value = 0  # 真实伤害无视防御
	
	# 计算基础伤害（减法公式）
	var base_damage: int = attack_power - defense_value
	
	# 确保最小伤害为1
	base_damage = max(1, base_damage)
	
	return base_damage

# 应用伤害类型规则
func apply_damage_type_rules(damage_type: DamageType, base_damage: int) -> int:
	# 目前主要区别在于计算方式，实际伤害值在calculate_base_damage中已处理
	# 这里可以添加额外的类型特定规则
	var final_damage = base_damage
	
	match damage_type:
		DamageType.WAI_GONG:
			# 外功伤害特殊规则
			pass
		DamageType.NEI_GONG:
			# 内功伤害特殊规则
			pass
		DamageType.ZHEN_SHI:
			# 真实伤害特殊规则
			pass
	
	return final_damage

# 确保最小伤害为1
func enforce_minimum_damage(damage: int) -> int:
	return max(1, damage)

# 完整的伤害计算流程
func calculate_damage(attacker, defender, damage_type: DamageType, is_critical: bool = false) -> DamageResult:
	# 计算基础伤害
	var base_damage = calculate_base_damage(attacker, defender, damage_type)
	
	# 应用伤害类型规则
	var processed_damage = apply_damage_type_rules(damage_type, base_damage)
	
	# 确保最小伤害限制
	var final_damage = enforce_minimum_damage(processed_damage)
	
	# 如果是暴击，应用暴击倍率
	if is_critical:
		final_damage = int(final_damage * 1.5)  # 暴击倍率1.5倍
	
	# 创建伤害结果对象
	var damage_result = DamageResult.new()
	damage_result.final_damage = final_damage
	damage_result.damage_type = damage_type
	damage_result.is_critical = is_critical
	damage_result.base_damage = base_damage
	damage_result.defense_reduced = calculate_base_damage(attacker, defender, damage_type) - base_damage
	
	# 发送伤害计算完成信号
	emit_signal("damage_calculated", damage_result)
	
	return damage_result

# 获取角色属性
func get_attribute(character, attribute_name: String) -> int:
	# 这里应该从角色数据中获取属性值
	# 为了示例，我们返回一个默认值
	if character.has_method("get_attribute"):
		return character.get_attribute(attribute_name)
	else:
		# 如果角色没有get_attribute方法，则返回默认值
		match attribute_name:
			"STR": return 100  # 力道
			"WIS": return 80   # 悟性
			"CON": return 70   # 根骨
			"AGI": return 60   # 身法
			"WIL": return 50   # 定力
			"LUK": return 30   # 福缘
		return 50

# 获取武器攻击力
func get_weapon_attack(character) -> int:
	# 这里应该从角色装备中获取武器攻击力
	# 为了示例，我们返回一个默认值
	if character.has_method("get_weapon_attack"):
		return character.get_weapon_attack()
	else:
		return 50  # 默认武器攻击力

# 获取护甲值
func get_armor_value(character) -> int:
	# 这里应该从角色装备中获取护甲值
	# 为了示例，我们返回一个默认值
	if character.has_method("get_armor_value"):
		return character.get_armor_value()
	else:
		return 30  # 默认护甲值

# 获取内力强度
func get_internal_energy(character) -> int:
	# 这里应该从角色数据中获取内力强度
	# 为了示例，我们返回一个默认值
	if character.has_method("get_internal_energy"):
		return character.get_internal_energy()
	else:
		return 60  # 默认内力强度

# 获取内力抗性
func get_internal_resist(character) -> int:
	# 这里应该从角色装备或状态中获取内力抗性
	# 为了示例，我们返回一个默认值
	if character.has_method("get_internal_resist"):
		return character.get_internal_resist()
	else:
		return 20  # 默认内力抗性

# 获取伤害类型名称
func get_damage_type_name(damage_type: DamageType) -> String:
	match damage_type:
		DamageType.WAI_GONG: return "外功"
		DamageType.NEI_GONG: return "内功"
		DamageType.ZHEN_SHI: return "真实"
		_: return "未知"

# 测试函数
func test_damage_calculation():
	print("开始测试伤害计算...")
	
	# 创建虚拟攻击者和防御者
	var dummy_attacker = {
		"STR": 120,
		"WIS": 100,
		"get_attribute": func(attr): return self.get_attribute(self, attr),
		"get_weapon_attack": func(): return 60,
		"get_internal_energy": func(): return 80
	}
	
	var dummy_defender = {
		"CON": 80,
		"WIS": 90,
		"get_attribute": func(attr): return self.get_attribute(self, attr),
		"get_armor_value": func(): return 40,
		"get_internal_resist": func(): return 30
	}
	
	# 测试外功伤害
	var result_waigong = calculate_damage(dummy_attacker, dummy_defender, DamageType.WAI_GONG)
	print("外功伤害结果: ", result_waigong.final_damage, " 点")
	
	# 测试内功伤害
	var result_neigong = calculate_damage(dummy_attacker, dummy_defender, DamageType.NEI_GONG)
	print("内功伤害结果: ", result_neigong.final_damage, " 点")
	
	# 测试真实伤害
	var result_zhenshi = calculate_damage(dummy_attacker, dummy_defender, DamageType.ZHEN_SHI)
	print("真实伤害结果: ", result_zhenshi.final_damage, " 点")
	
	# 测试暴击
	var result_critical = calculate_damage(dummy_attacker, dummy_defender, DamageType.WAI_GONG, true)
	print("暴击外功伤害结果: ", result_critical.final_damage, " 点")
	
	# 测试低攻击力vs高防御力（确保最小伤害为1）
	var low_attacker = {
		"STR": 10,
		"WIS": 10,
		"get_attribute": func(attr): return self.get_attribute(self, attr),
		"get_weapon_attack": func(): return 5,
		"get_internal_energy": func(): return 5
	}
	
	var high_defender = {
		"CON": 150,
		"WIS": 150,
		"get_attribute": func(attr): return self.get_attribute(self, attr),
		"get_armor_value": func(): return 100,
		"get_internal_resist": func(): return 100
	}
	
	var result_min = calculate_damage(low_attacker, high_defender, DamageType.WAI_GONG)
	print("最小伤害测试结果: ", result_min.final_damage, " 点 (应为1)")
	
	print("伤害计算测试完成")