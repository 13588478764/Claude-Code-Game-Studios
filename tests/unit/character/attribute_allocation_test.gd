# 武侠奇遇录 - 属性分配系统单元测试
# 测试六维核心属性分配、验证、计算和重置功能

extends "res://addons/gut/test.gd"

# 测试用例变量
var character_system = null
var item_manager = null

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
	
	# 创建物品管理器实例
	item_manager = preload("res://src/scripts/economy/item_manager.gd").new()
	
	# 将物品管理器添加到场景树以便角色系统可以找到它
	var main_game = Node.new()
	main_game.name = "MainGame"
	main_game.add_child(item_manager)
	item_manager.name = "ItemManager"
	
	# 将MainGame添加到根节点
	get_tree().get_root().add_child(main_game)

func after_each():
	"""在每个测试之后运行"""
	# 清理场景树
	var main_game = get_tree().get_root().get_node_or_null("MainGame")
	if main_game:
		main_game.queue_free()

# 测试用例1: 六维核心属性分配正常工作
func test_six_dimensional_attributes_allocation_works():
	"""AC-1: 六维核心属性分配正常工作"""
	# Given: 角色有5点可用属性点（初始状态）
	assert_eq(character_system.total_attribute_points, 5)
	assert_eq(character_system.allocated_attribute_points, 0)
	
	# When: 分配2点到力道属性
	var result = character_system.allocate_attribute_points("strength", 2)
	
	# Then: 力道属性增加2点，已分配属性点增加2点
	assert_true(result)
	assert_eq(character_system.attributes.strength, 12)  # 10 + 2
	assert_eq(character_system.allocated_attribute_points, 2)
	
	# 测试其他属性
	result = character_system.allocate_attribute_points("agility", 1)
	assert_true(result)
	assert_eq(character_system.attributes.agility, 11)  # 10 + 1
	
	result = character_system.allocate_attribute_points("constitution", 1)
	assert_true(result)
	assert_eq(character_system.attributes.constitution, 11)  # 10 + 1
	
	result = character_system.allocate_attribute_points("intelligence", 1)
	assert_true(result)
	assert_eq(character_system.attributes.intelligence, 11)  # 10 + 1
	
	# 测试分配0点（应该失败）
	result = character_system.allocate_attribute_points("willpower", 0)
	assert_false(result)
	assert_eq(character_system.attributes.willpower, 10)  # 保持不变
	
	# 测试分配负数点（应该失败）
	result = character_system.allocate_attribute_points("luck", -1)
	assert_false(result)
	assert_eq(character_system.attributes.luck, 10)  # 保持不变
	
	# 测试分配到不存在的属性（应该失败）
	result = character_system.allocate_attribute_points("invalid_attr", 1)
	assert_false(result)

# 测试用例2: 属性点分配验证正确
func test_attribute_points_allocation_validation_works():
	"""AC-2: 属性点分配验证正确"""
	# Given: 角色有10点可用属性点，已分配5点
	character_system.total_attribute_points = 10
	character_system.allocated_attribute_points = 5
	character_system.attributes.strength = 15  # 已分配5点到力道
	
	# When: 尝试分配6点到身法属性（超出可用点数）
	var result = character_system.allocate_attribute_points("agility", 6)
	
	# Then: 分配失败，返回false，属性值不变
	assert_false(result)
	assert_eq(character_system.attributes.agility, 10)  # 保持基础值
	assert_eq(character_system.allocated_attribute_points, 5)  # 保持不变
	
	# 测试恰好分配完所有点
	result = character_system.allocate_attribute_points("agility", 5)
	assert_true(result)
	assert_eq(character_system.allocated_attribute_points, 10)  # 全部分配完毕
	
	# 测试超出1点
	character_system.total_attribute_points = 10
	character_system.allocated_attribute_points = 9
	result = character_system.allocate_attribute_points("constitution", 2)
	assert_false(result)
	assert_eq(character_system.allocated_attribute_points, 9)  # 保持不变

# 测试用例3: 属性效果正确计算
func test_attribute_effects_calculation_works():
	"""AC-3: 属性效果正确计算"""
	# Given: 角色力道属性为20
	character_system.attributes.strength = 20
	
	# When: 调用get_combat_stats()
	var combat_stats = character_system.get_combat_stats()
	
	# Then: 物理攻击力 = 20 × 2 = 40
	assert_eq(combat_stats["physical_attack"], 40)
	
	# 测试属性为0的情况
	character_system.attributes.strength = 0
	combat_stats = character_system.get_combat_stats()
	assert_eq(combat_stats["physical_attack"], 0)
	
	# 测试属性为最大值的情况（假设最大值为100）
	character_system.attributes.strength = 100
	combat_stats = character_system.get_combat_stats()
	assert_eq(combat_stats["physical_attack"], 200)
	
	# 测试境界加成影响
	character_system.realm_bonus = 1.1  # 10%加成
	character_system.attributes.strength = 20
	combat_stats = character_system.get_combat_stats()
	# 最终力道 = 20 * 1.1 = 22, 物理攻击 = 22 * 2 = 44
	assert_eq(combat_stats["physical_attack"], 44)

# 测试用例4: 属性重置功能正常工作
func test_attribute_reset_functionality_works():
	"""AC-4: 属性重置功能正常工作"""
	# Given: 角色有1次免费重置机会
	character_system.free_reset_count = 1
	
	# 分配一些属性点
	character_system.allocate_attribute_points("strength", 3)
	character_system.allocate_attribute_points("agility", 2)
	
	# When: 调用reset_attributes()
	var result = character_system.reset_attributes()
	
	# Then: 所有属性恢复到基础值10，已分配点数归零，免费重置次数减1
	assert_true(result)
	assert_eq(character_system.attributes.strength, 10)
	assert_eq(character_system.attributes.agility, 10)
	assert_eq(character_system.allocated_attribute_points, 0)
	assert_eq(character_system.free_reset_count, 0)
	
	# 测试无免费重置次数时消耗洗髓丹
	character_system.free_reset_count = 0
	character_system.allocate_attribute_points("constitution", 5)
	
	# 给玩家一些洗髓丹
	item_manager.add_item(item_manager.ITEM_WASH_MARROW_PILL, 2)
	
	# 重置属性
	result = character_system.reset_attributes()
	assert_true(result)
	assert_eq(character_system.attributes.constitution, 10)
	assert_eq(character_system.allocated_attribute_points, 0)
	assert_eq(item_manager.get_item_count(item_manager.ITEM_WASH_MARROW_PILL), 1)  # 消耗了1个
	
	# 测试洗髓丹不足时重置失败
	item_manager.remove_item(item_manager.ITEM_WASH_MARROW_PILL, 1)  # 现在没有洗髓丹了
	character_system.allocate_attribute_points("intelligence", 3)
	result = character_system.reset_attributes()
	assert_false(result)
	assert_eq(character_system.attributes.intelligence, 13)  # 保持不变
	assert_eq(character_system.allocated_attribute_points, 3)  # 保持不变

# 测试用例5: 信号系统集成
func test_signal_system_integration():
	"""测试信号系统是否正确发射"""
	var signal_received = false
	var signal_data = {}
	
	# 连接信号
	character_system.connect("attribute_points_allocated", self, "_on_attribute_points_allocated", [signal_data])
	character_system.connect("attributes_reset", self, "_on_attributes_reset", [signal_received])
	
	# 测试属性分配信号
	character_system.allocate_attribute_points("strength", 2)
	assert_true(signal_data.has("attribute_name"))
	assert_eq(signal_data["attribute_name"], "strength")
	assert_eq(signal_data["points"], 2)
	assert_eq(signal_data["new_value"], 12)
	
	# 测试重置信号
	signal_received = false
	character_system.free_reset_count = 1
	character_system.reset_attributes()
	assert_true(signal_received)

# 信号回调函数
func _on_attribute_points_allocated(attribute_name, points, new_value, signal_data):
	signal_data["attribute_name"] = attribute_name
	signal_data["points"] = points
	signal_data["new_value"] = new_value

func _on_attributes_reset(free_reset_used, signal_received):
	signal_received = true