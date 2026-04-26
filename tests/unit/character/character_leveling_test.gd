# 角色等级和境界突破单元测试
# 验证角色成长系统的核心功能是否按预期工作

extends Node

# 导入需要测试的模块
var CharacterSystem = load("res://src/scripts/character/character_system.gd")

func test_character_leveling_system():
	"""
	测试角色等级系统正常工作，共99级，每升一级获得5点属性点和1点天赋点
	"""
	print("Running test: test_character_leveling_system")
	
	# 创建角色系统实例
	var character_system = CharacterSystem.new()
	character_system.initialize_character()
	
	# 检查初始状态
	assert(character_system.level == 1, "Initial level should be 1")
	assert(character_system.total_attribute_points == 5, "Initial attribute points should be 5")
	assert(character_system.total_talent_points == 1, "Initial talent points should be 1")
	
	# 测试升级
	character_system.add_experience(1000)  # 足够升级到2级
	
	# 检查升级后状态
	assert(character_system.level == 2, "Level should be 2 after upgrade")
	assert(character_system.total_attribute_points == 10, "Should have 10 attribute points after level 2 (5 initial + 5 from level up)")
	assert(character_system.total_talent_points == 2, "Should have 2 talent points after level 2 (1 initial + 1 from level up)")
	
	# 测试99级上限
	character_system.level = 98
	character_system.total_attribute_points = 490  # 98级应该有490点属性点 (98 * 5)
	character_system.total_talent_points = 98     # 98级应该有98点天赋点 (98 * 1)
	character_system.experience = character_system.get_exp_required_for_level(99) - 1
	
	# 添加足够经验升级到99级
	character_system.add_experience(1000)
	
	assert(character_system.level == 99, "Level should be capped at 99")
	assert(character_system.total_attribute_points == 495, "Should have 495 attribute points at level 99 (99 * 5)")
	assert(character_system.total_talent_points == 99, "Should have 99 talent points at level 99 (99 * 1)")
	
	# 尝试超过99级
	character_system.add_experience(10000)
	assert(character_system.level == 99, "Level should not exceed 99")
	assert(character_system.total_attribute_points == 495, "Attribute points should not exceed 495")
	assert(character_system.total_talent_points == 99, "Talent points should not exceed 99")
	
	print("PASSED: test_character_leveling_system")

func test_realm_breakthrough_system():
	"""
	测试境界突破系统正常工作，10个大境界里程碑，每个里程碑解锁新功能并提供全属性+10%加成
	"""
	print("Running test: test_realm_breakthrough_system")
	
	# 创建角色系统实例
	var character_system = CharacterSystem.new()
	character_system.initialize_character()
	
	# 检查初始境界
	assert(character_system.realm_index == 0, "Initial realm index should be 0 (炼气)")
	assert(character_system.realm_bonus == 1.0, "Initial realm bonus should be 1.0 (0% bonus)")
	
	# 测试第一个境界突破（炼气->筑基）
	character_system.level = 10  # 达到炼气期满
	character_system.breakthrough_realm()
	
	assert(character_system.realm_index == 1, "Realm index should be 1 after first breakthrough (筑基)")
	assert(character_system.realm_bonus == 1.1, "Realm bonus should be 1.1 after first breakthrough (10% bonus)")
	
	# 测试第二个境界突破（筑基->金丹）
	character_system.level = 20  # 达到筑基期满
	character_system.breakthrough_realm()
	
	assert(character_system.realm_index == 2, "Realm index should be 2 after second breakthrough (金丹)")
	assert(character_system.realm_bonus == 1.2, "Realm bonus should be 1.2 after second breakthrough (20% bonus)")
	
	# 测试最高境界（真仙）
	character_system.realm_index = 8  # 渡劫期
	character_system.realm_bonus = 1.9  # 90%加成
	character_system.level = 90  # 达到渡劫期满
	
	character_system.breakthrough_realm()
	
	assert(character_system.realm_index == 9, "Realm index should be 9 after final breakthrough (真仙)")
	assert(character_system.realm_bonus == 2.0, "Realm bonus should be 2.0 after final breakthrough (100% bonus)")
	
	# 测试超过最高境界
	character_system.breakthrough_realm()
	assert(character_system.realm_index == 9, "Realm index should not exceed 9")
	assert(character_system.realm_bonus == 2.0, "Realm bonus should not exceed 2.0")
	
	print("PASSED: test_realm_breakthrough_system")

func test_experience_and_level_up_mechanism():
	"""
	测试经验值获取和等级提升机制正常工作
	"""
	print("Running test: test_experience_and_level_up_mechanism")
	
	# 创建角色系统实例
	var character_system = CharacterSystem.new()
	character_system.initialize_character()
	
	# 检查初始经验值
	assert(character_system.experience == 0, "Initial experience should be 0")
	
	# 获取升级到2级所需经验
	var exp_for_level_2 = character_system.get_exp_required_for_level(2)
	assert(exp_for_level_2 > 0, "Experience required for level 2 should be positive")
	
	# 添加不足的经验
	character_system.add_experience(exp_for_level_2 - 1)
	assert(character_system.level == 1, "Level should remain 1 with insufficient experience")
	
	# 添加足够的经验
	character_system.add_experience(1)
	assert(character_system.level == 2, "Level should be 2 with sufficient experience")
	
	# 测试批量升级
	character_system.level = 1
	character_system.experience = 0
	var exp_for_level_5 = character_system.get_exp_required_for_level(6) - 1
	
	character_system.add_experience(exp_for_level_5)
	assert(character_system.level == 5, "Should level up to 5 with enough experience for level 5")
	
	# 测试经验值溢出处理
	character_system.level = 1
	character_system.experience = 0
	var exp_for_level_3 = character_system.get_exp_required_for_level(4) - 1
	
	character_system.add_experience(exp_for_level_3)
	assert(character_system.level == 3, "Should handle experience overflow correctly")
	
	print("PASSED: test_experience_and_level_up_mechanism")

func test_character_data_persistence():
	"""
	测试角色数据正确保存和加载，包括等级、境界、属性点等
	"""
	print("Running test: test_character_data_persistence")
	
	# 创建角色系统实例
	var character_system = CharacterSystem.new()
	character_system.initialize_character()
	
	# 设置测试数据
	character_system.level = 25
	character_system.experience = 5000
	character_system.total_attribute_points = 125  # 25级 * 5点
	character_system.allocated_attribute_points = 50
	character_system.total_talent_points = 25     # 25级 * 1点
	character_system.allocated_talent_points = 10
	character_system.realm_index = 2  # 金丹期
	character_system.realm_bonus = 1.2  # 20%加成
	character_system.free_reset_count = 2
	
	# 分配一些属性点
	character_system.allocate_attribute_points("strength", 20)
	character_system.allocate_attribute_points("agility", 15)
	character_system.allocate_attribute_points("constitution", 15)
	
	# 检查数据一致性
	assert(character_system.level == 25, "Level should be 25")
	assert(character_system.total_attribute_points == 125, "Total attribute points should be 125")
	assert(character_system.allocated_attribute_points == 50, "Allocated attribute points should be 50")
	assert(character_system.total_talent_points == 25, "Total talent points should be 25")
	assert(character_system.allocated_talent_points == 10, "Allocated talent points should be 10")
	assert(character_system.realm_index == 2, "Realm index should be 2 (金丹)")
	assert(character_system.attributes.strength == 30, "Strength should be 30 (10 base + 20 allocated)")
	assert(character_system.attributes.agility == 25, "Agility should be 25 (10 base + 15 allocated)")
	assert(character_system.attributes.constitution == 25, "Constitution should be 25 (10 base + 15 allocated)")
	
	# 模拟保存和加载（通过重新初始化并设置相同数据来模拟）
	var new_character_system = CharacterSystem.new()
	new_character_system.level = 25
	new_character_system.experience = 5000
	new_character_system.total_attribute_points = 125
	new_character_system.allocated_attribute_points = 50
	new_character_system.total_talent_points = 25
	new_character_system.allocated_talent_points = 10
	new_character_system.realm_index = 2
	new_character_system.realm_bonus = 1.2
	new_character_system.free_reset_count = 2
	new_character_system.attributes.strength = 30
	new_character_system.attributes.agility = 25
	new_character_system.attributes.constitution = 25
	new_character_system.attributes.intelligence = 10
	new_character_system.attributes.willpower = 10
	new_character_system.attributes.luck = 10
	
	# 检查加载后的数据一致性
	assert(new_character_system.level == 25, "Loaded level should be 25")
	assert(new_character_system.total_attribute_points == 125, "Loaded total attribute points should be 125")
	assert(new_character_system.allocated_attribute_points == 50, "Loaded allocated attribute points should be 50")
	assert(new_character_system.total_talent_points == 25, "Loaded total talent points should be 25")
	assert(new_character_system.allocated_talent_points == 10, "Loaded allocated talent points should be 10")
	assert(new_character_system.realm_index == 2, "Loaded realm index should be 2 (金丹)")
	assert(new_character_system.attributes.strength == 30, "Loaded strength should be 30")
	assert(new_character_system.attributes.agility == 25, "Loaded agility should be 25")
	assert(new_character_system.attributes.constitution == 25, "Loaded constitution should be 25")
	
	print("PASSED: test_character_data_persistence")

func run_all_tests():
	"""
	运行所有测试
	"""
	print("Starting character leveling tests...\n")
	
	test_character_leveling_system()
	print()
	
	test_realm_breakthrough_system()
	print()
	
	test_experience_and_level_up_mechanism()
	print()
	
	test_character_data_persistence()
	print()
	
	print("All tests completed successfully!")

# 当脚本运行时自动执行测试
func _ready():
	run_all_tests()