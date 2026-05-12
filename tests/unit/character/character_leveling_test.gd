# 角色等级和境界突破单元测试
# 验证角色成长系统的核心功能是否按预期工作
extends GutTest

# 导入需要测试的模块
var CharacterSystemScript = load("res://src/scripts/character/character_system.gd")

var character_system = null

func before_each():
	character_system = CharacterSystemScript.new()
	character_system.initialize_character()

func after_each():
	if character_system:
		character_system.free()
		character_system = null

func test_character_leveling_system():
	# 检查初始状态
	assert_eq(character_system.level, 1, "初始等级应为1")
	assert_eq(character_system.total_attribute_points, 5, "初始属性点应为5")
	assert_eq(character_system.total_talent_points, 1, "初始天赋点应为1")

	# 测试升级
	var exp_for_level_2 = character_system.get_exp_required_for_level(2)
	character_system.add_experience(exp_for_level_2)

	assert_eq(character_system.level, 2, "升级后等级应为2")
	assert_eq(character_system.total_attribute_points, 10, "2级应有10属性点")
	assert_eq(character_system.total_talent_points, 2, "2级应有2天赋点")

	# 测试99级上限
	character_system.level = 98
	character_system.total_attribute_points = 490
	character_system.total_talent_points = 98
	character_system.experience = character_system.get_exp_required_for_level(99) - 1
	character_system.add_experience(1000)

	assert_eq(character_system.level, 99, "等级上限应为99")
	assert_eq(character_system.total_attribute_points, 495, "99级应有495属性点")
	assert_eq(character_system.total_talent_points, 99, "99级应有99天赋点")

	# 尝试超过99级
	character_system.add_experience(10000)
	assert_eq(character_system.level, 99, "等级不应超过99")

func test_realm_breakthrough_system():
	# 检查初始境界
	assert_eq(character_system.realm_index, 0, "初始境界索引应为0（炼气）")
	assert_eq(character_system.realm_bonus, 1.0, "初始境界加成应为1.0")

	# 测试第一个境界突破（炼气->筑基）
	character_system.level = 10
	character_system.breakthrough_realm()
	assert_eq(character_system.realm_index, 1, "突破后境界索引应为1（筑基）")
	assert_eq(character_system.realm_bonus, 1.1, "突破后境界加成应为1.1")

	# 测试第二个境界突破（筑基->金丹）
	character_system.level = 20
	character_system.breakthrough_realm()
	assert_eq(character_system.realm_index, 2, "突破后境界索引应为2（金丹）")
	assert_eq(character_system.realm_bonus, 1.2, "突破后境界加成应为1.2")

	# 测试最高境界
	character_system.realm_index = 8
	character_system.realm_bonus = 1.9
	character_system.level = 90
	character_system.breakthrough_realm()
	assert_eq(character_system.realm_index, 9, "最终境界索引应为9（真仙）")

	# 测试超过最高境界
	character_system.breakthrough_realm()
	assert_eq(character_system.realm_index, 9, "境界索引不应超过9")

func test_experience_and_level_up_mechanism():
	assert_eq(character_system.experience, 0, "初始经验值应为0")

	var exp_for_level_2 = character_system.get_exp_required_for_level(2)
	assert_gt(exp_for_level_2, 0, "升级所需经验应为正数")

	# 添加不足的经验
	character_system.add_experience(exp_for_level_2 - 1)
	assert_eq(character_system.level, 1, "经验不足时不应升级")

	# 添加足够的经验
	character_system.add_experience(1)
	assert_eq(character_system.level, 2, "经验足够时应升级到2")

	# 测试批量升级
	character_system.level = 1
	character_system.experience = 0
	var total_exp_for_level_5 = 0
	for i in range(2, 6):
		total_exp_for_level_5 += character_system.get_exp_required_for_level(i)

	character_system.add_experience(total_exp_for_level_5)
	assert_eq(character_system.level, 5, "批量经验应升级到5")

func test_character_data_persistence():
	# 设置测试数据
	character_system.level = 25
	character_system.experience = 5000
	character_system.total_attribute_points = 125
	character_system.total_talent_points = 25
	character_system.allocated_talent_points = 10
	character_system.realm_index = 2
	character_system.realm_bonus = 1.2
	character_system.free_reset_count = 2

	# 分配属性点
	character_system.allocate_attribute_points("strength", 20)
	character_system.allocate_attribute_points("agility", 15)
	character_system.allocate_attribute_points("constitution", 15)

	# 验证数据一致性
	assert_eq(character_system.level, 25, "等级应为25")
	assert_eq(character_system.total_attribute_points, 125, "总属性点应为125")
	assert_eq(character_system.allocated_attribute_points, 50, "已分配属性点应为50")
	assert_eq(character_system.attributes.strength, 30, "力道应为30")
	assert_eq(character_system.attributes.agility, 25, "身法应为25")
	assert_eq(character_system.attributes.constitution, 25, "根骨应为25")
	assert_eq(character_system.realm_index, 2, "境界索引应为2（金丹）")
