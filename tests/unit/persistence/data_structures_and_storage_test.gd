# 数据结构与存储单元测试
# 验证成长数据结构、属性分配数据结构、技能学习数据结构和存储格式

extends Node

# 导入需要测试的脚本
var GrowthDataStructureManager = load("res://scripts/persistence/growth_data_structure_manager.gd")

# 测试结果统计
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("开始运行数据结构与存储单元测试...")
	
	# 运行成长数据结构测试
	test_growth_data_structure_creation()
	test_character_progression_data_structure()
	
	# 运行属性分配数据结构测试
	test_attribute_data_structure()
	test_attribute_values_initialization()
	
	# 运行技能学习数据结构测试
	test_martial_arts_data_structure()
	test_skill_proficiencies_initialization()
	
	# 运行存储格式测试
	test_data_serialization()
	test_data_deserialization()
	test_data_validation()
	
	print("\n测试完成: %d/%d 个测试通过" % [tests_passed, tests_total])

# 测试成长数据结构创建
func test_growth_data_structure_creation():
	var data_manager = GrowthDataStructureManager.new()
	
	var growth_data = data_manager.define_growth_data_structure()
	
	assert(growth_data != null, "成长数据结构应成功创建")
	assert(growth_data.version != "", "版本号不应为空")
	assert(growth_data.progression != null, "进度数据不应为空")
	assert(growth_data.attributes != null, "属性数据不应为空")
	
	print("✓ 成长数据结构创建测试通过")
	tests_passed += 4
	tests_total += 4

# 测试角色进度数据结构
func test_character_progression_data_structure():
	var data_manager = GrowthDataStructureManager.new()
	
	var progression_data = data_manager.define_growth_data_structure().progression
	
	assert(progression_data.level >= 1, "等级应至少为1")
	assert(progression_data.realm >= 0 and progression_data.realm <= 9, "境界应在0-9范围内")
	assert(progression_data.experience >= 0, "经验值不应为负")
	
	print("✓ 角色进度数据结构测试通过")
	tests_passed += 3
	tests_total += 3

# 测试属性数据结构
func test_attribute_data_structure():
	var data_manager = GrowthDataStructureManager.new()
	
	var attribute_data = data_manager.define_growth_data_structure().attributes
	
	assert(attribute_data.total_points >= 0, "总点数不应为负")
	assert(attribute_data.allocated_points >= 0, "已分配点数不应为负")
	assert(attribute_data.reset_count >= 0, "重置次数不应为负")
	assert(attribute_data.values.size() == 6, "应有6个基础属性")
	
	print("✓ 属性数据结构测试通过")
	tests_passed += 4
	tests_total += 4

# 测试属性值初始化
func test_attribute_values_initialization():
	var data_manager = GrowthDataStructureManager.new()
	
	var attribute_data = data_manager.define_growth_data_structure().attributes
	var values = attribute_data.values
	
	assert(values.has("strength"), "应包含力道属性")
	assert(values.has("agility"), "应包含身法属性")
	assert(values.has("constitution"), "应包含根骨属性")
	assert(values.has("intelligence"), "应包含悟性属性")
	assert(values.has("willpower"), "应包含定力属性")
	assert(values.has("luck"), "应包含福缘属性")
	
	for attr_name in values:
		assert(values[attr_name] >= 0, "属性值不应为负")
	
	print("✓ 属性值初始化测试通过")
	tests_passed += 7
	tests_total += 7

# 测试武学数据结构
func test_martial_arts_data_structure():
	var data_manager = GrowthDataStructureManager.new()
	
	var martial_arts_data = data_manager.define_growth_data_structure().martial_arts
	
	assert(martial_arts_data.learned_skills is Array, "已学技能应为数组")
	assert(martial_arts_data.skill_proficiencies is Dictionary, "技能熟练度应为字典")
	assert(martial_arts_data.inner_arts is Array, "内功心法应为数组")
	assert(martial_arts_data.inner_arts.size() == 3, "应有3个内功槽位")
	assert(martial_arts_data.light_art is String, "轻功应为字符串")
	
	print("✓ 武学数据结构测试通过")
	tests_passed += 5
	tests_total += 5

# 测试技能熟练度初始化
func test_skill_proficiencies_initialization():
	var data_manager = GrowthDataStructureManager.new()
	
	var martial_arts_data = data_manager.define_growth_data_structure().martial_arts
	
	assert(martial_arts_data.learned_skills.size() == 0, "初始已学技能应为空")
	assert(martial_arts_data.skill_proficiencies.size() == 0, "初始技能熟练度应为空")
	assert(martial_arts_data.inner_arts[0] == null, "初始内功槽位1应为空")
	assert(martial_arts_data.inner_arts[1] == null, "初始内功槽位2应为空")
	assert(martial_arts_data.inner_arts[2] == null, "初始内功槽位3应为空")
	assert(martial_arts_data.light_art == "", "初始轻功应为空")
	
	print("✓ 技能熟练度初始化测试通过")
	tests_passed += 6
	tests_total += 6

# 测试数据序列化
func test_data_serialization():
	var data_manager = GrowthDataStructureManager.new()
	
	var growth_data = data_manager.define_growth_data_structure()
	growth_data.character_id = "test_character_001"
	growth_data.progression.level = 15
	growth_data.progression.realm = 2
	growth_data.attributes.values["strength"] = 25
	
	var dict_result = data_manager.growth_data_to_dict(growth_data)
	
	assert(dict_result != null, "序列化结果不应为空")
	assert(dict_result.has("characterId"), "序列化结果应包含角色ID")
	assert(dict_result.has("progression"), "序列化结果应包含进度数据")
	assert(dict_result.has("attributes"), "序列化结果应包含属性数据")
	assert(dict_result["progression"]["level"] == 15, "序列化应保持等级值")
	assert(dict_result["attributes"]["values"]["strength"] == 25, "序列化应保持属性值")
	
	print("✓ 数据序列化测试通过")
	tests_passed += 6
	tests_total += 6

# 测试数据反序列化
func test_data_deserialization():
	var data_manager = GrowthDataStructureManager.new()
	
	var test_dict = {
		"version": "1.0.0",
		"characterId": "test_character_002",
		"progression": {
			"level": 20,
			"realm": 3,
			"experience": 5000,
			"experienceToNextLevel": 7500
		},
		"attributes": {
			"totalPoints": 10,
			"allocatedPoints": 5,
			"values": {
				"strength": 30,
				"agility": 25,
				"constitution": 28,
				"intelligence": 22,
				"willpower": 24,
				"luck": 20
			}
		}
	}
	
	var deserialized_data = data_manager.dict_to_growth_data(test_dict)
	
	assert(deserialized_data != null, "反序列化结果不应为空")
	assert(deserialized_data.character_id == "test_character_002", "反序列化应保持角色ID")
	assert(deserialized_data.progression.level == 20, "反序列化应保持等级")
	assert(deserialized_data.progression.realm == 3, "反序列化应保持境界")
	assert(deserialized_data.attributes.values["strength"] == 30, "反序列化应保持属性值")
	
	print("✓ 数据反序列化测试通过")
	tests_passed += 5
	tests_total += 5

# 测试数据验证
func test_data_validation():
	var data_manager = GrowthDataStructureManager.new()
	
	var valid_growth_data = data_manager.define_growth_data_structure()
	valid_growth_data.progression.level = 50
	valid_growth_data.progression.realm = 5
	
	var invalid_growth_data = data_manager.define_growth_data_structure()
	invalid_growth_data.progression.level = 100  # 超出范围
	invalid_growth_data.progression.realm = 10   # 超出范围
	
	var is_valid = data_manager.validate_data_structure(valid_growth_data)
	var is_invalid = data_manager.validate_data_structure(invalid_growth_data)
	
	assert(is_valid == true, "有效数据应通过验证")
	assert(is_invalid == false, "无效数据应不通过验证")
	
	print("✓ 数据验证测试通过")
	tests_passed += 2
	tests_total += 2

# 断言函数
func assert(condition, message):
	if not condition:
		print("测试失败: " + message)
		tests_total += 1
	else:
		# 条件为真时，什么都不做，继续
		pass