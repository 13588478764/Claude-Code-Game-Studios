# 装备属性计算机制单元测试
# 验证六维基础属性和战斗属性的计算，以及属性转换公式和品阶差异

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_six_core_attributes_calculation_correctly())
	results.append(test_combat_attributes_calculation_correctly())
	results.append(test_attribute_conversion_formula_correctly_implemented())
	results.append(test_quality_tier_attribute_differences_correctly_reflected())
	
	return results

# 测试1: 六维基础属性计算正确
func test_six_core_attributes_calculation_correctly() -> TestResult:
	var result = TestResult.new()
	result.test_name = "六维基础属性计算正确"
	
	# 创建测试角色
	var test_character = {
		"id": "test_char_001",
		"base_attributes": {
			"strength": 10,
			"agility": 10,
			"constitution": 10,
			"intelligence": 10,
			"willpower": 10,
			"luck": 10
		}
	}
	
	# 创建测试装备
	var test_equipment = [
		{
			"id": "weapon_001",
			"attributes": {
				"base_attributes": {
					"strength": 5,
					"agility": 3
				},
				"combat_attributes": {
					"attack": 10,
					"critical_rate": 0.05  # 5%暴击率
				}
			}
		},
		{
			"id": "armor_001",
			"attributes": {
				"base_attributes": {
					"constitution": 8
				},
				"combat_attributes": {
					"defense": 15,
					"max_health": 50
				}
			}
		}
	]
	
	# 创建属性计算器实例
	var calculator = load("res://src/scripts/equipment/equipment_attribute_calculator.gd").new()
	
	# 计算总属性
	var total_attrs = calculator.calculate_total_attributes(test_character, test_equipment)
	
	# 验证基础属性计算
	if total_attrs.base.strength == 25 and total_attrs.base.agility == 13 and total_attrs.base.constitution == 26:
		result.passed = true
		result.message = "六维基础属性计算正确"
	else:
		result.passed = false
		result.message = "六维基础属性计算错误"
	
	return result

# 测试2: 战斗属性计算正确
func test_combat_attributes_calculation_correctly() -> TestResult:
	var result = TestResult.new()
	result.test_name = "战斗属性计算正确"
	
	# 创建测试角色
	var test_character = {
		"id": "test_char_002",
		"base_attributes": {
			"strength": 20,
			"agility": 15,
			"constitution": 18,
			"intelligence": 12,
			"willpower": 14,
			"luck": 10
		}
	}
	
	# 创建测试装备
	var test_equipment = [
		{
			"id": "weapon_002",
			"attributes": {
				"combat_attributes": {
					"attack": 25,
					"critical_rate": 0.08  # 8%暴击率
				}
			}
		},
		{
			"id": "armor_002",
			"attributes": {
				"combat_attributes": {
					"defense": 30,
					"max_health": 100
				}
			}
		}
	]
	
	# 创建属性计算器实例
	var calculator = load("res://src/scripts/equipment/equipment_attribute_calculator.gd").new()
	
	# 计算总属性
	var total_attrs = calculator.calculate_total_attributes(test_character, test_equipment)
	
	# 验证战斗属性计算
	if total_attrs.combat.attack >= 85 and total_attrs.combat.defense == 45 and total_attrs.combat.max_health == 298:
		result.passed = true
		result.message = "战斗属性计算正确"
	else:
		result.passed = false
		result.message = "战斗属性计算错误"
	
	return result

# 测试3: 属性转换公式正确实施
func test_attribute_conversion_formula_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "属性转换公式正确实施"
	
	# 创建测试角色
	var test_character = {
		"id": "test_char_003",
		"base_attributes": {
			"strength": 30,
			"agility": 20,
			"constitution": 25,
			"intelligence": 15,
			"willpower": 18,
			"luck": 12
		}
	}
	
	# 创建无装备测试（只测试基础转换）
	var test_equipment = []
	
	# 创建属性计算器实例
	var calculator = load("res://src/scripts/equipment/equipment_attribute_calculator.gd").new()
	
	# 计算总属性
	var total_attrs = calculator.calculate_total_attributes(test_character, test_equipment)
	
	# 验证属性转换公式
	# 力道 → 物理攻击力：1点力道 = 2点物理攻击力
	var expected_attack_from_strength = 30 * 2
	# 根骨 → 生命值：1点根骨 = 10点生命值上限
	var expected_health_from_constitution = 25 * 10
	
	if total_attrs.combat.attack >= expected_attack_from_strength and total_attrs.combat.max_health >= expected_health_from_constitution:
		result.passed = true
		result.message = "属性转换公式正确实施"
	else:
		result.passed = false
		result.message = "属性转换公式实施错误"
	
	return result

# 测试4: 品阶属性差异正确体现
func test_quality_tier_attribute_differences_correctly_reflected() -> TestResult:
	var result = TestResult.new()
	result.test_name = "品阶属性差异正确体现"
	
	# 创建测试角色
	var test_character = {
		"id": "test_char_004",
		"base_attributes": {
			"strength": 15,
			"agility": 15,
			"constitution": 15,
			"intelligence": 15,
			"willpower": 15,
			"luck": 15
		}
	}
	
	# 创建不同品阶的装备
	var common_equipment = [  # 普通品阶
		{
			"id": "common_weapon",
			"rarity": "common",
			"attributes": {
				"base_attributes": {
					"strength": 3,
					"agility": 2
				}
			}
		}
	]
	
	var epic_equipment = [  # 史诗品阶
		{
			"id": "epic_weapon",
			"rarity": "epic",
			"attributes": {
				"base_attributes": {
					"strength": 10,
					"agility": 8
				},
				"combat_attributes": {
					"critical_rate": 0.05,
					"critical_damage": 0.10
				}
			}
		}
	]
	
	# 创建属性计算器实例
	var calculator = load("res://src/scripts/equipment/equipment_attribute_calculator.gd").new()
	
	# 计算普通装备属性
	var common_attrs = calculator.calculate_total_attributes(test_character, common_equipment)
	# 计算史诗装备属性
	var epic_attrs = calculator.calculate_total_attributes(test_character, epic_equipment)
	
	# 验证史诗装备提供更多的属性加成
	if epic_attrs.base.strength > common_attrs.base.strength and epic_attrs.base.agility > common_attrs.base.agility:
		result.passed = true
		result.message = "品阶属性差异正确体现"
	else:
		result.passed = false
		result.message = "品阶属性差异未正确体现"
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行装备属性计算机制测试...")
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