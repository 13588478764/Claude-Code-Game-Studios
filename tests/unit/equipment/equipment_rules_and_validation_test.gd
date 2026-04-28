# 装备规则与验证单元测试
# 验证装备品阶、职业和性别限制的验证机制

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_equipment_tier_restrictions_correctly_implemented())
	results.append(test_profession_restrictions_correctly_applied())
	results.append(test_gender_restrictions_correctly_applied())
	results.append(test_equipment_validation_function_works_normally())
	
	return results

# 测试1: 装备品阶限制正确实施
func test_equipment_tier_restrictions_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "装备品阶限制正确实施"
	
	# 创建装备规则验证器实例
	var validator = load("res://src/scripts/equipment/equipment_rule_validator.gd").new()
	
	# 测试不同境界对装备品阶的限制
	var common_result = validator.validate_equipment_tier("sword_common_001", validator.RealmLevel.LIANG_QI)
	var rare_result = validator.validate_equipment_tier("sword_rare_001", validator.RealmLevel.ZHU_JI)
	var epic_result = validator.validate_equipment_tier("sword_epic_001", validator.RealmLevel.YUAN_YING)
	var legendary_result = validator.validate_equipment_tier("sword_legendary_001", validator.RealmLevel.DA_CHENG)
	
	# 测试境界不足的情况
	var epic_result_low_realm = validator.validate_equipment_tier("sword_epic_001", validator.RealmLevel.ZHU_JI)
	var legendary_result_low_realm = validator.validate_equipment_tier("sword_legendary_001", validator.RealmLevel.YUAN_YING)
	
	if common_result and rare_result and epic_result and legendary_result and not epic_result_low_realm and not legendary_result_low_realm:
		result.passed = true
		result.message = "装备品阶限制正确实施"
	else:
		result.passed = false
		result.message = "装备品阶限制实施错误"
	
	return result

# 测试2: 职业限制正确应用
func test_profession_restrictions_correctly_applied() -> TestResult:
	var result = TestResult.new()
	result.test_name = "职业限制正确应用"
	
	# 创建装备规则验证器实例
	var validator = load("res://src/scripts/equipment/equipment_rule_validator.gd").new()
	
	# 测试剑客职业
	var swordsman_result = validator.validate_profession_requirement("sword_rare_001", validator.CharacterClass.SWORDSMAN)
	var spearman_result = validator.validate_profession_requirement("sword_rare_001", validator.CharacterClass.SPEARMAN)
	
	# 测试无职业限制的装备
	var no_restriction_result = validator.validate_profession_requirement("sword_common_001", validator.CharacterClass.AXEMAN)
	
	if swordsman_result and not spearman_result and no_restriction_result:
		result.passed = true
		result.message = "职业限制正确应用"
	else:
		result.passed = false
		result.message = "职业限制应用错误"
	
	return result

# 测试3: 性别限制正确应用
func test_gender_restrictions_correctly_applied() -> TestResult:
	var result = TestResult.new()
	result.test_name = "性别限制正确应用"
	
	# 创建装备规则验证器实例
	var validator = load("res://src/scripts/equipment/equipment_rule_validator.gd").new()
	
	# 测试男性角色
	var male_result = validator.validate_gender_requirement("armor_male_001", validator.Gender.MALE)
	var female_result = validator.validate_gender_requirement("armor_male_001", validator.Gender.FEMALE)
	
	# 测试无性别限制的装备
	var no_gender_restriction_result = validator.validate_gender_requirement("sword_common_001", validator.Gender.FEMALE)
	
	if male_result and not female_result and no_gender_restriction_result:
		result.passed = true
		result.message = "性别限制正确应用"
	else:
		result.passed = false
		result.message = "性别限制应用错误"
	
	return result

# 测试4: 装备验证功能正常
func test_equipment_validation_function_works_normally() -> TestResult:
	var result = TestResult.new()
	result.test_name = "装备验证功能正常"
	
	# 创建装备规则验证器实例
	var validator = load("res://src/scripts/equipment/equipment_rule_validator.gd").new()
	
	# 创建一个符合条件的角色
	var valid_character = {
		"realm_level": validator.RealmLevel.ZHEN_XIAN,
		"character_class": validator.CharacterClass.SWORDSMAN,
		"gender": validator.Gender.MALE
	}
	
	# 测试可以装备的物品
	var valid_equipment_result = validator.can_equip_item("sword_rare_001", validator.SlotType.WEAPON_MAIN, valid_character)
	
	# 创建一个境界不足的角色
	var low_realm_character = {
		"realm_level": validator.RealmLevel.LIANG_QI,
		"character_class": validator.CharacterClass.SWORDSMAN,
		"gender": validator.Gender.MALE
	}
	
	# 测试境界不足时无法装备高品阶装备
	var invalid_tier_result = validator.can_equip_item("sword_legendary_001", validator.SlotType.WEAPON_MAIN, low_realm_character)
	
	# 创建一个职业不符的角色
	var wrong_class_character = {
		"realm_level": validator.RealmLevel.ZHEN_XIAN,
		"character_class": validator.CharacterClass.AXEMAN,
		"gender": validator.Gender.MALE
	}
	
	# 测试职业不符时无法装备
	var invalid_class_result = validator.can_equip_item("sword_rare_001", validator.SlotType.WEAPON_MAIN, wrong_class_character)
	
	if valid_equipment_result and not invalid_tier_result and not invalid_class_result:
		result.passed = true
		result.message = "装备验证功能正常"
	else:
		result.passed = false
		result.message = "装备验证功能异常"
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行装备规则与验证测试...")
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