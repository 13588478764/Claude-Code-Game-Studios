# 装备属性计算系统单元测试
# 验证装备基础属性、强化加成、宝石效果和流派加成的计算

extends Node

# 加载装备属性计算器
var EquipmentAttributeCalculator = load("res://src/scripts/equipment/equipment_attribute_calculator.gd")

var calculator
var test_result = {
	"passed": 0,
	"failed": 0,
	"total": 0,
	"details": []
}

func _ready():
	print("开始装备属性计算系统单元测试...")
	
	# 运行所有测试
	test_equipment_base_attribute_calculation()
	test_equipment_enhancement_bonus_calculation()
	test_gem_effect_calculation()
	test_school_bonus_calculation()
	
	# 输出测试结果
	print("\n=== 装备属性计算系统单元测试结果 ===")
	print("通过: %d" % test_result.passed)
	print("失败: %d" % test_result.failed)
	print("总计: %d" % test_result.total)
	
	if test_result.failed == 0:
		print("✅ 所有测试通过！")
	else:
		print("❌ 有 %d 个测试失败" % test_result.failed)
	
	for detail in test_result.details:
		print(detail)

# 测试装备基础属性计算
func test_equipment_base_attribute_calculation():
	print("\n--- 测试装备基础属性计算 ---")
	
	calculator = EquipmentAttributeCalculator.new()
	
	# 创建测试装备
	var test_sword = calculator.EquipmentData.new(
		"sword_001",
		"青锋剑",
		calculator.EquipmentType.WEAPON_MAIN_HAND,
		calculator.EquipmentRarity.RARE
	)
	test_sword.base_attributes = {"attack": 50, "critical_rate": 5}
	test_sword.level_requirement = 10
	
	# 测试基础属性计算（考虑品阶加成）
	var base_attrs = calculator.calculate_base_attributes(test_sword)
	
	# 稀有度装备应该有2.0倍的品阶加成
	if base_attrs.has("attack") and base_attrs.attack == 100:  # 50 * 2.0
		add_test_result("装备基础属性计算", true, "稀有度装备品阶加成正确")
	else:
		add_test_result("装备基础属性计算", false, "稀有度装备品阶加成错误: 期望100，实际%f" % base_attrs.get("attack", 0))
	
	if base_attrs.has("critical_rate") and base_attrs.critical_rate == 10:  # 5 * 2.0
		add_test_result("装备基础属性计算", true, "稀有度装备次要属性品阶加成正确")
	else:
		add_test_result("装备基础属性计算", false, "稀有度装备次要属性品阶加成错误")

# 测试装备强化加成计算
func test_equipment_enhancement_bonus_calculation():
	print("\n--- 测试装备强化加成计算 ---")
	
	calculator = EquipmentAttributeCalculator.new()
	
	# 创建测试装备
	var test_armor = calculator.EquipmentData.new(
		"armor_001",
		"铁甲",
		calculator.EquipmentType.ARMOR,
		calculator.EquipmentRarity.UNCOMMON
	)
	test_armor.base_attributes = {"defense": 30, "hp": 100}
	test_armor.enhancement_level = 10  # +10强化
	
	# 测试强化加成计算
	var enhancement_bonus = calculator.calculate_enhancement_bonus(test_armor)
	
	# +10强化应该提供 30 * 0.03 * 10 = 9 的防御加成
	if enhancement_bonus.has("defense") and abs(enhancement_bonus.defense - 9.0) < 0.01:
		add_test_result("装备强化加成计算", true, "+10强化防御加成计算正确")
	else:
		add_test_result("装备强化加成计算", false, "+10强化防御加成计算错误: 期望9.0，实际%f" % enhancement_bonus.get("defense", 0))
	
	# +10强化应该提供 100 * 0.03 * 10 = 30 的生命加成
	if enhancement_bonus.has("hp") and abs(enhancement_bonus.hp - 30.0) < 0.01:
		add_test_result("装备强化加成计算", true, "+10强化生命加成计算正确")
	else:
		add_test_result("装备强化加成计算", false, "+10强化生命加成计算错误: 期望30.0，实际%f" % enhancement_bonus.get("hp", 0))
	
	# +10强化应该提供10%的全局加成
	if enhancement_bonus.has("global_multiplier") and abs(enhancement_bonus.global_multiplier - 0.1) < 0.01:
		add_test_result("装备强化加成计算", true, "+10强化全局加成计算正确")
	else:
		add_test_result("装备强化加成计算", false, "+10强化全局加成计算错误: 期望0.1，实际%f" % enhancement_bonus.get("global_multiplier", 0))

# 测试宝石效果计算
func test_gem_effect_calculation():
	print("\n--- 测试宝石效果计算 ---")
	
	calculator = EquipmentAttributeCalculator.new()
	
	# 测试单个宝石效果
	var single_gem_array = [calculator.GemType.RED_GEM]
	var single_gem_effects = calculator.calculate_gem_effects(single_gem_array)
	
	if single_gem_effects.has("attack") and single_gem_effects.attack == 10:
		add_test_result("宝石效果计算", true, "单个红宝石攻击加成计算正确")
	else:
		add_test_result("宝石效果计算", false, "单个红宝石攻击加成计算错误")
	
	# 测试多个相同宝石效果
	var multiple_gem_array = [
		calculator.GemType.RED_GEM,
		calculator.GemType.RED_GEM,
		calculator.GemType.RED_GEM
	]  # 3个红宝石，应该触发套装效果
	var multiple_gem_effects = calculator.calculate_gem_effects(multiple_gem_array)
	
	if multiple_gem_effects.has("attack") and multiple_gem_effects.attack == 30:  # 3 * 10
		add_test_result("宝石效果计算", true, "多个红宝石攻击加成计算正确")
	else:
		add_test_result("宝石效果计算", false, "多个红宝石攻击加成计算错误")
	
	# 检查是否触发了3红宝石套装效果
	if multiple_gem_effects.has("fire_damage_bonus") and multiple_gem_effects.fire_damage_bonus == 15:
		add_test_result("宝石效果计算", true, "3红宝石套装效果计算正确")
	else:
		add_test_result("宝石效果计算", false, "3红宝石套装效果计算错误")

# 测试流派加成计算
func test_school_bonus_calculation():
	print("\n--- 测试流派加成计算 ---")
	
	calculator = EquipmentAttributeCalculator.new()
	
	# 创建一个有武当派加成的装备
	var wudang_sword = calculator.EquipmentData.new(
		"wudang_sword_001",
		"武当剑",
		calculator.EquipmentType.WEAPON_MAIN_HAND,
		calculator.EquipmentRarity.RARE
	)
	wudang_sword.base_attributes = {"attack": 60, "internal_force": 20}
	wudang_sword.martial_art_school = "武当派"
	
	# 测试流派加成计算（当角色也使用武当派时）
	var school_bonus = calculator.calculate_school_bonus(wudang_sword, "武当派")
	
	# 稀有度装备应该提供15%的流派加成
	var expected_attack_bonus = 60 * 0.15  # 9
	if school_bonus.has("attack") and abs(school_bonus.attack - expected_attack_bonus) < 0.01:
		add_test_result("流派加成计算", true, "武当派装备流派加成计算正确")
	else:
		add_test_result("流派加成计算", false, "武当派装备流派加成计算错误: 期望%f，实际%f" % [expected_attack_bonus, school_bonus.get("attack", 0)])
	
	# 测试非匹配流派（应该没有加成）
	var other_school_bonus = calculator.calculate_school_bonus(wudang_sword, "少林派")
	if not other_school_bonus.has("attack") or other_school_bonus.attack == 0:
		add_test_result("流派加成计算", true, "非匹配流派无加成计算正确")
	else:
		add_test_result("流派加成计算", false, "非匹配流派错误地提供了加成")

# 辅助函数：添加测试结果
func add_test_result(test_name: String, passed: bool, message: String):
	test_result.total += 1
	if passed:
		test_result.passed += 1
		print("✅ %s: %s" % [test_name, message])
	else:
		test_result.failed += 1
		print("❌ %s: %s" % [test_name, message])
	
	test_result.details.append("%s: %s" % [test_name, "通过" if passed else "失败 - " + message])