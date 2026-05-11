# 装备属性计算单元测试
# 验证装备基础属性、强化加成、宝石效果和流派加成的计算

extends GutTest

# 导入要测试的脚本
var EquipmentAttributeCalculatorScript

# 测试计算器实例
var calculator

# 每个测试前执行
func before_all():
	EquipmentAttributeCalculatorScript = load("res://src/scripts/equipment/equipment_attribute_calculator.gd")

func before_each():
	calculator = EquipmentAttributeCalculatorScript.new()
	calculator._ready()  # 手动调用初始化

# 测试1: 装备基础属性计算正确
func test_equipment_base_attributes_calculated_correctly():
	# 创建测试装备
	var test_sword = calculator.EquipmentInfo.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 计算基础属性
	var base_attrs = calculator.calculate_base_attributes(test_sword)
	
	# 检查基础属性是否正确计算
	assert_true(base_attrs.has("attack"), "应该包含攻击力属性")
	assert_eq(base_attrs.attack, 50, "攻击力应该为50")
	assert_true(base_attrs.has("attack_speed"), "应该包含攻击速度属性")
	assert_eq(base_attrs.attack_speed, 1.2, "攻击速度应该为1.2")

# 测试2: 强化属性加成正常
func test_enhancement_attribute_bonus_works_normally():
	# 创建测试装备
	var test_sword = calculator.EquipmentInfo.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	test_sword.enhancement_level = 10
	
	# 计算强化加成
	var enhancement_bonus = calculator.calculate_enhancement_bonus(test_sword)
	
	# 检查强化加成是否正确计算
	# 使用公式：基础属性 × 强化倍率 × 强化等级
	var expected_attack_bonus = 50 * 0.03 * 10  # 50 * 0.03 * 10 = 15
	var actual_attack_bonus = enhancement_bonus.get("attack", 0)
	
	assert_true(enhancement_bonus.has("attack"), "应该包含攻击力加成")
	assert_almost_eq(actual_attack_bonus, expected_attack_bonus, 0.01, "攻击力加成应该约为15")

# 测试3: 宝石套装效果计算正确
func test_gem_set_effect_calculated_correctly():
	# 创建测试装备
	var test_sword = calculator.EquipmentInfo.new("sword_001", "青钢剑", "weapon", "weapon_main")
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
	
	assert_true(gem_effects.has("attack"), "应该包含攻击力加成")
	assert_eq(total_gem_attack, 15, "3个宝石应该提供15点攻击力")

# 测试4: 装备流派加成正常
func test_equipment_school_bonus_works_normally():
	# 创建测试装备
	var test_sword = calculator.EquipmentInfo.new("sword_001", "武当剑", "weapon", "weapon_main")  # 武当剑
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 60, "attack_speed": 1.2}
	
	# 计算流派加成
	var school_bonus = calculator.calculate_school_bonus(test_sword, "武当")
	
	# 检查流派加成是否正确计算
	# 武当剑应该有20%的流派加成
	var expected_attack_bonus = 60 * 0.2  # 20%流派加成
	var actual_attack_bonus = school_bonus.get("attack", 0)
	
	assert_true(school_bonus.has("attack"), "应该包含攻击力加成")
	assert_almost_eq(actual_attack_bonus, expected_attack_bonus, 0.01, "攻击力加成应该约为12（20%）")