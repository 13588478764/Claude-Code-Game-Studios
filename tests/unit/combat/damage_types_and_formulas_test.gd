# 伤害类型与公式单元测试
# 验证三种伤害类型、基础公式和最小伤害限制

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_damage_types_correctly_implemented())
	results.append(test_base_damage_formula_correct())
	results.append(test_defense_attributes_correctly_applied())
	results.append(test_minimum_damage_limit_normal())
	
	return results

# 测试1: 三种伤害类型正确实现
func test_damage_types_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "三种伤害类型正确实现"
	
	# 创建伤害计算器实例
	var damage_calculator = load("res://src/scripts/combat/damage_calculator.gd").new()
	
	# 测试外功伤害
	var dummy_attacker = {
		"STR": 100,
		"WIS": 80,
		"get_attribute": func(attr): return attr == "STR" and 100 or 80,
		"get_weapon_attack": func(): return 50,
		"get_internal_energy": func(): return 60
	}
	
	var dummy_defender = {
		"CON": 50,
		"WIS": 70,
		"get_attribute": func(attr): return attr == "CON" and 50 or 70,
		"get_armor_value": func(): return 30,
		"get_internal_resist": func(): return 20
	}
	
	# 测试外功伤害
	var result_waigong = damage_calculator.calculate_damage(dummy_attacker, dummy_defender, damage_calculator.DamageType.WAI_GONG)
	var expected_waigong = max(1, (100 + 50) - (50 + 30))  # max(1, 150 - 80) = 70
	var actual_waigong = result_waigong.final_damage
	
	# 测试内功伤害
	var result_neigong = damage_calculator.calculate_damage(dummy_attacker, dummy_defender, damage_calculator.DamageType.NEI_GONG)
	var expected_neigong = max(1, (80 + 60) - (70 + 20))  # max(1, 140 - 90) = 50
	var actual_neigong = result_neigong.final_damage
	
	# 测试真实伤害
	var result_zhenshi = damage_calculator.calculate_damage(dummy_attacker, dummy_defender, damage_calculator.DamageType.ZHEN_SHI)
	var expected_zhenshi = max(1, (80 + 60) - 0)  # max(1, 140) = 140 (真实伤害无视防御)
	var actual_zhenshi = result_zhenshi.final_damage
	
	# 验证结果
	if actual_waigong == expected_waigong and actual_neigong == expected_neigong and actual_zhenshi == expected_zhenshi:
		result.passed = true
		result.message = "外功伤害: %d (期望 %d), 内功伤害: %d (期望 %d), 真实伤害: %d (期望 %d)" % [actual_waigong, expected_waigong, actual_neigong, expected_neigong, actual_zhenshi, expected_zhenshi]
	else:
		result.passed = false
		result.message = "伤害类型计算错误 - 外功: %d (期望 %d), 内功: %d (期望 %d), 真实伤害: %d (期望 %d)" % [actual_waigong, expected_waigong, actual_neigong, expected_neigong, actual_zhenshi, expected_zhenshi]
	
	return result

# 测试2: 基础伤害计算公式正确
func test_base_damage_formula_correct() -> TestResult:
	var result = TestResult.new()
	result.test_name = "基础伤害计算公式正确"
	
	# 创建伤害计算器实例
	var damage_calculator = load("res://src/scripts/combat/damage_calculator.gd").new()
	
	# 创建测试角色
	var attacker = {
		"STR": 150,
		"get_attribute": func(attr): return 150,
		"get_weapon_attack": func(): return 0,
		"get_internal_energy": func(): return 0
	}
	
	var defender = {
		"CON": 80,
		"get_attribute": func(attr): return 80,
		"get_armor_value": func(): return 0,
		"get_internal_resist": func(): return 0
	}
	
	# 计算伤害 (攻击力150 - 防御力80 = 70)
	var damage_result = damage_calculator.calculate_damage(attacker, defender, damage_calculator.DamageType.WAI_GONG)
	var expected_damage = 70
	var actual_damage = damage_result.final_damage
	
	if actual_damage == expected_damage:
		result.passed = true
		result.message = "基础伤害计算正确: %d - %d = %d" % [150, 80, actual_damage]
	else:
		result.passed = false
		result.message = "基础伤害计算错误: 期望 %d, 实际 %d" % [expected_damage, actual_damage]
	
	return result

# 测试3: 攻防属性正确应用
func test_defense_attributes_correctly_applied() -> TestResult:
	var result = TestResult.new()
	result.test_name = "攻防属性正确应用"
	
	# 创建伤害计算器实例
	var damage_calculator = load("res://src/scripts/combat/damage_calculator.gd").new()
	
	# 测试外功: 力道 vs 根骨
	var attacker = {
		"STR": 100,
		"WIS": 80,
		"get_attribute": func(attr): return attr == "STR" and 100 or 80,
		"get_weapon_attack": func(): return 0,
		"get_internal_energy": func(): return 0
	}
	
	var defender = {
		"CON": 50,
		"WIS": 90,
		"get_attribute": func(attr): return attr == "CON" and 50 or 90,
		"get_armor_value": func(): return 0,
		"get_internal_resist": func(): return 0
	}
	
	# 计算外功伤害 (力道 vs 根骨)
	var result_waigong = damage_calculator.calculate_damage(attacker, defender, damage_calculator.DamageType.WAI_GONG)
	var expected_waigong = max(1, 100 - 50)  # 50点伤害
	var actual_waigong = result_waigong.final_damage
	
	# 测试内功: 悟性 vs 悟性/内力抗性
	var attacker_neigong = {
		"STR": 80,
		"WIS": 120,
		"get_attribute": func(attr): return attr == "WIS" and 120 or 80,
		"get_weapon_attack": func(): return 0,
		"get_internal_energy": func(): return 30
	}
	
	var defender_neigong = {
		"CON": 70,
		"WIS": 100,
		"get_attribute": func(attr): return attr == "WIS" and 100 or 70,
		"get_armor_value": func(): return 0,
		"get_internal_resist": func(): return 10
	}
	
	var result_neigong = damage_calculator.calculate_damage(attacker_neigong, defender_neigong, damage_calculator.DamageType.NEI_GONG)
	var expected_neigong = max(1, (120 + 30) - (100 + 10))  # max(1, 150 - 110) = 40
	var actual_neigong = result_neigong.final_damage
	
	if actual_waigong == expected_waigong and actual_neigong == expected_neigong:
		result.passed = true
		result.message = "外功: 力道(100) vs 根骨(50) = %d, 内功: 悟性(150) vs 悟性/抗性(110) = %d" % [actual_waigong, actual_neigong]
	else:
		result.passed = false
		result.message = "攻防属性应用错误 - 外功: 期望 %d 实际 %d, 内功: 期望 %d 实际 %d" % [expected_waigong, actual_waigong, expected_neigong, actual_neigong]
	
	return result

# 测试4: 最小伤害限制正常
func test_minimum_damage_limit_normal() -> TestResult:
	var result = TestResult.new()
	result.test_name = "最小伤害限制正常"
	
	# 创建伤害计算器实例
	var damage_calculator = load("res://src/scripts/combat/damage_calculator.gd").new()
	
	# 创建攻击力很低但防御力很高的角色
	var low_attacker = {
		"STR": 10,
		"get_attribute": func(attr): return 10,
		"get_weapon_attack": func(): return 5,
		"get_internal_energy": func(): return 0
	}
	
	var high_defender = {
		"CON": 50,
		"get_attribute": func(attr): return 50,
		"get_armor_value": func(): return 60,
		"get_internal_resist": func(): return 0
	}
	
	# 计算伤害 (攻击力15 - 防御力110 = -95, 但最小伤害限制为1)
	var damage_result = damage_calculator.calculate_damage(low_attacker, high_defender, damage_calculator.DamageType.WAI_GONG)
	var expected_damage = 1  # 最小伤害限制
	var actual_damage = damage_result.final_damage
	
	if actual_damage == expected_damage:
		result.passed = true
		result.message = "最小伤害限制正常: 期望 %d, 实际 %d" % [expected_damage, actual_damage]
	else:
		result.passed = false
		result.message = "最小伤害限制错误: 期望 %d, 实际 %d" % [expected_damage, actual_damage]
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行伤害类型与公式测试...")
	print("================================")
	
	for result in test_results:
		if result.passed:
			print("✅ %s: %s" % [result.test_name, result.message])
			passed_count += 1
		else:
			print("❌ %s: %s" % [result.test_name, result.message])
	
	print("================================")
	print("测试结果: %d/%d 项测试通过" % [passed_count, total_count])
	
	if passed_count == total_count:
		print("🎉 所有测试都通过了！")
	else:
		print("⚠️  有 %d 项测试失败" % [total_count - passed_count])
	
	return passed_count == total_count