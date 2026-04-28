# 装备属性计算单元测试
# 验证装备基础属性、强化加成、宝石效果和流派加成的计算

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_equipment_base_attributes_calculated_correctly())
	results.append(test_enhancement_attribute_bonus_works_normally())
	results.append(test_gem_set_effect_calculated_correctly())
	results.append(test_equipment_school_bonus_works_normally())
	
	return results

# 测试1: 装备基础属性计算正确
func test_equipment_base_attributes_calculated_correctly() -> TestResult:
	var result = TestResult.new()
	result.test_name = "装备基础属性计算正确"
	
	# 创建装备属性计算器实例
	var calculator = load("res://src/scripts/equipment/equipment_attribute_calculator.gd").new()
	
	# 创建测试装备
	var test_sword = calculator.EquipmentData.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 计算基础属性
	var base_attrs = calculator.calculate_base_attributes(test_sword)
	
	# 检查基础属性是否正确计算
	if base_attrs.has("attack") and base_attrs.attack == 50 and base_attrs.has("attack_speed") and base_attrs.attack_speed == 1.2:
		result.passed = true
		result.message = "装备基础属性计算正确"
	else:
		result.passed = false
		result.message = "装备基础属性计算错误"
	
	return result

# 测试2: 强化属性加成正常
func test_enhancement_attribute_bonus_works_normally() -> TestResult:
	var result = TestResult.new()
	result.test_name = "强化属性加成正常"
	
	# 创建装备属性计算器实例
	var calculator = load("res://src/scripts/equipment/equipment_attribute_calculator.gd").new()
	
	# 创建测试装备
	var test_sword = calculator.EquipmentData.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	test_sword.enhancement_level = 10
	
	# 计算强化加成
	var enhancement_bonus = calculator.calculate_enhancement_bonus(test_sword)
	
	# 检查强化加成是否正确计算
	# 使用公式：基础属性 × (1 + 强化倍率 × 强化等级) - 基础属性
	var expected_attack_bonus = 50 * 0.03 * 10  # 50 * 0.03 * 10 = 15
	var actual_attack_bonus = enhancement_bonus.get("attack", 0)
	
	if abs(actual_attack_bonus - expected_attack_bonus) < 0.01:
		result.passed = true
		result.message = "强化属性加成正常"
	else:
		result.passed = false
		result.message = "强化属性加成计算错误"
	
	return result

# 测试3: 宝石套装效果计算正确
func test_gem_set_effect_calculated_correctly() -> TestResult:
	var result = TestResult.new()
	result.test_name = "宝石套装效果计算正确"
	
	# 创建装备属性计算器实例
	var calculator = load("res://src/scripts/equipment/equipment_attribute_calculator.gd").new()
	
	# 创建测试装备
	var test_sword = calculator.EquipmentData.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 添加宝石
	test_sword.gems.append({"type": "ruby", "color": "red", "attack": 5})
	test_sword.gems.append({"type": "ruby", "color": "red", "attack": 5})
	test_sword.gems.append({"type": "ruby", "color": "red", "attack": 5})
	
	# 计算宝石效果
	var gem_effects = calculator.calculate_gem_effects(test_sword)
	
	# 检查宝石效果是否正确计算
	var total_gem_attack = gem_effects.get("attack", 0)
	
	if total_gem_attack >= 15:  # 3个宝石，每个提供5点攻击力
		result.passed = true
		result.message = "宝石套装效果计算正确"
	else:
		result.passed = false
		result.message = "宝石套装效果计算错误"
	
	return result

# 测试4: 装备流派加成正常
func test_equipment_school_bonus_works_normally() -> TestResult:
	var result = TestResult.new()
	result.test_name = "装备流派加成正常"
	
	# 创建装备属性计算器实例
	var calculator = load("res://src/scripts/equipment/equipment_attribute_calculator.gd").new()
	
	# 创建测试装备
	var test_sword = calculator.EquipmentData.new("sword_001", "武当剑", "weapon", "weapon_main")  # 武当剑
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 60, "attack_speed": 1.2}
	
	# 计算流派加成
	var school_bonus = calculator.calculate_school_bonus(test_sword, "武当")
	
	# 检查流派加成是否正确计算
	# 武当剑应该有20%的流派加成
	var expected_attack_bonus = 60 * 0.2  # 20%流派加成
	var actual_attack_bonus = school_bonus.get("attack", 0)
	
	if abs(actual_attack_bonus - expected_attack_bonus) < 0.01:
		result.passed = true
		result.message = "装备流派加成正常"
	else:
		result.passed = false
		result.message = "装备流派加成计算错误"
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行装备属性计算测试...")
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