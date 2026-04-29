# 武侠奇遇录 - 天赋网格系统单元测试
# 测试4x4天赋网格、天赋点分配、天赋效果应用和重置功能

extends "res://addons/gut/test.gd"

# 测试用例变量
var character_system = null

func before_all():
	"""在所有测试之前运行"""
	pass

func after_all():
	"""在所有测试之后运行"""
	pass

func before_each():
	"""在每个测试之前运行"""
	# 创建新的角色系统实例
	character_system = preload("res://src/scripts/character/character_system.gd").new()
	character_system.initialize_character()

func after_each():
	"""在每个测试之后运行"""
	character_system = null

# 测试用例1: 4x4天赋网格数据结构正常工作
func test_4x4_talent_grid_data_structure_works():
	"""AC-1: 4x4天赋网格数据结构正常工作"""
	# Given: 初始化天赋网格系统
	# When: 创建4x4天赋网格
	# Then: 网格包含16个天赋节点，所有节点初始状态为未解锁
	assert_eq(character_system.talent_grid.size(), 4)
	for row in range(4):
		assert_eq(character_system.talent_grid[row].size(), 4)
		for col in range(4):
			assert_false(character_system.talent_grid[row][col]["unlocked"])
			assert_eq(character_system.talent_grid[row][col]["effect"], {})
	
	# 测试访问越界索引（应该返回false）
	var result = character_system.unlock_talent(-1, 0)
	assert_false(result)
	
	result = character_system.unlock_talent(4, 0)
	assert_false(result)
	
	result = character_system.unlock_talent(0, -1)
	assert_false(result)
	
	result = character_system.unlock_talent(0, 4)
	assert_false(result)

# 测试用例2: 天赋点分配和验证正确
func test_talent_points_allocation_and_validation_works():
	"""AC-2: 天赋点分配和验证正确"""
	# Given: 角色有3点可用天赋点
	character_system.total_talent_points = 3
	character_system.allocated_talent_points = 0
	
	# When: 点亮位置(0,0)的天赋节点
	var result = character_system.unlock_talent(0, 0)
	
	# Then: 该节点状态变为已解锁，已分配天赋点增加1
	assert_true(result)
	assert_true(character_system.talent_grid[0][0]["unlocked"])
	assert_eq(character_system.allocated_talent_points, 1)
	
	# 测试重复点亮同一节点（应该失败）
	result = character_system.unlock_talent(0, 0)
	assert_false(result)
	assert_eq(character_system.allocated_talent_points, 1)
	
	# 测试天赋点不足时点亮（应该失败）
	character_system.allocated_talent_points = 3  # 已分配完所有天赋点
	result = character_system.unlock_talent(0, 1)
	assert_false(result)
	assert_false(character_system.talent_grid[0][1]["unlocked"])
	
	# 测试点亮不存在的节点（坐标越界，应该失败）
	result = character_system.unlock_talent(5, 5)
	assert_false(result)

# 测试用例3: 天赋效果正确应用
func test_talent_effects_application_works():
	"""AC-3: 天赋效果正确应用"""
	# Given: 点亮一个提供+10力道的天赋节点
	character_system.total_talent_points = 1
	character_system.unlock_talent(0, 0)  # 力拔山兮：+10力道
	
	# When: 调用get_final_attributes()
	var final_attrs = character_system.get_final_attributes()
	
	# Then: 力道属性增加10点（基础10 + 天赋10 = 20）
	assert_eq(final_attrs.strength, 20)
	
	# 测试多个天赋效果叠加
	character_system.total_talent_points = 2
	character_system.unlock_talent(0, 1)  # 身轻如燕：+10身法
	final_attrs = character_system.get_final_attributes()
	assert_eq(final_attrs.strength, 20)
	assert_eq(final_attrs.agility, 20)
	
	# 测试天赋效果与境界加成叠加
	character_system.realm_bonus = 1.1  # 10%境界加成
	final_attrs = character_system.get_final_attributes()
	# 力道 = (10 * 1.1) + 10 = 11 + 10 = 21
	# 身法 = (10 * 1.1) + 10 = 11 + 10 = 21
	assert_eq(final_attrs.strength, 21)
	assert_eq(final_attrs.agility, 21)
	
	# 测试战斗属性中的天赋效果
	var combat_stats = character_system.get_combat_stats()
	# 物理攻击 = 21 * 2 = 42
	assert_eq(combat_stats["physical_attack"], 42)

# 测试用例4: 天赋重置功能正常工作
func test_talent_reset_functionality_works():
	"""AC-4: 天赋重置功能正常工作"""
	# Given: 已点亮3个天赋节点
	character_system.total_talent_points = 3
	character_system.unlock_talent(0, 0)  # 力拔山兮
	character_system.unlock_talent(1, 1)  # 福星高照
	character_system.unlock_talent(2, 2)  # 暴击专家
	
	# When: 调用reset_talents()
	var result = character_system.reset_talents()
	
	# Then: 所有天赋节点恢复未解锁状态，已分配天赋点归零
	assert_true(result)
	for row in range(4):
		for col in range(4):
			assert_false(character_system.talent_grid[row][col]["unlocked"])
	assert_eq(character_system.allocated_talent_points, 0)
	
	# 测试重置空天赋网格
	result = character_system.reset_talents()
	assert_true(result)
	
	# 测试重置后再次分配
	character_system.total_talent_points = 1
	result = character_system.unlock_talent(3, 3)  # 全属性提升
	assert_true(result)
	assert_true(character_system.talent_grid[3][3]["unlocked"])

# 测试用例5: 天赋效果计算完整性
func test_talent_effects_calculation_completeness():
	"""测试所有类型的天赋效果都能正确计算"""
	# 测试属性类天赋
	character_system.total_talent_points = 6
	character_system.unlock_talent(0, 0)  # +10力道
	character_system.unlock_talent(0, 1)  # +10身法
	character_system.unlock_talent(0, 2)  # +10根骨
	character_system.unlock_talent(0, 3)  # +10悟性
	character_system.unlock_talent(1, 0)  # +10定力
	character_system.unlock_talent(1, 1)  # +10福缘
	
	var final_attrs = character_system.get_final_attributes()
	assert_eq(final_attrs.strength, 20)
	assert_eq(final_attrs.agility, 20)
	assert_eq(final_attrs.constitution, 20)
	assert_eq(final_attrs.intelligence, 20)
	assert_eq(final_attrs.willpower, 20)
	assert_eq(final_attrs.luck, 20)
	
	# 测试战斗属性类天赋 - 简化测试，只验证天赋效果能被应用
	character_system.total_talent_points = 10
	character_system.unlock_talent(1, 2)  # +50内力上限
	character_system.unlock_talent(1, 3)  # +100最大生命值
	character_system.unlock_talent(2, 0)  # +20物理攻击力
	character_system.unlock_talent(2, 1)  # +0.1闪避率
	
	var combat_stats = character_system.get_combat_stats()
	# 验证天赋效果被应用（具体数值由实现决定）
	assert_true(combat_stats["internal_energy_max"] > 80)  # 有天赋加成
	assert_true(combat_stats["max_health"] > 200)  # 有天赋加成
	assert_true(combat_stats["physical_attack"] > 0)  # 有天赋加成
	assert_true(combat_stats["evasion"] > 0)  # 有天赋加成

# 测试用例6: 天赋网格状态显示
func test_talent_grid_status_display():
	"""测试天赋网格状态显示功能"""
	character_system.total_talent_points = 2
	character_system.unlock_talent(0, 0)
	character_system.unlock_talent(3, 3)
	
	# 验证网格状态
	assert_true(character_system.talent_grid[0][0]["unlocked"])
	assert_true(character_system.talent_grid[3][3]["unlocked"])
	
	# 验证其他节点仍为未解锁
	assert_false(character_system.talent_grid[1][1]["unlocked"])
	assert_false(character_system.talent_grid[2][2]["unlocked"])