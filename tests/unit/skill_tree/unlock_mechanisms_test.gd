extends "res://addons/gut/test.gd"

class_name UnlockMechanismsTest

# 测试解锁机制
# 覆盖前置武学熟练度、境界门槛、物品/秘籍消耗和奇遇/事件解锁四种解锁机制

var unlock_manager: SkillUnlockManager
var mock_inventory: SkillUnlockManager.MockInventoryManager
var mock_event: SkillUnlockManager.MockEventManager

func before_each():
	# 初始化解锁管理器
	unlock_manager = SkillUnlockManager.new()
	
	# 初始化模拟管理器
	mock_inventory = SkillUnlockManager.MockInventoryManager.new()
	mock_event = SkillUnlockManager.MockEventManager.new()
	
	# 注入依赖
	unlock_manager.set_inventory_manager(mock_inventory)
	unlock_manager.set_event_manager(mock_event)

func after_each():
	# 清理测试资源
	if unlock_manager:
		unlock_manager.queue_free()
	mock_inventory = null
	mock_event = null

# 测试前置武学熟练度解锁
func test_proficiency_gate_unlock():
	# Given: 玩家华山剑法熟练度为5，崩字诀要求熟练度为5
	unlock_manager.set_proficiency_level("huashan_sword", 5)
	
	# When: 系统验证解锁条件
	var is_valid = unlock_manager.validate_proficiency_requirement("huashan_sword", 5)
	
	# Then: 熟练度条件满足，返回true
	assert_true(is_valid, "熟练度条件应满足")
	
	# 测试不满足的情况
	var is_invalid = unlock_manager.validate_proficiency_requirement("huashan_sword", 6)
	assert_false(is_invalid, "熟练度不足时应返回false")

# 测试境界门槛解锁
func test_realm_requirement_unlock():
	# Given: 玩家当前境界为筑基期（境界等级3），御剑术要求筑基期
	unlock_manager.set_current_realm(3)
	
	# When: 系统验证境界条件
	var is_valid = unlock_manager.validate_realm_requirement(3)
	
	# Then: 境界条件满足，返回true
	assert_true(is_valid, "境界条件应满足")
	
	# 测试不满足的情况
	var is_invalid = unlock_manager.validate_realm_requirement(4)
	assert_false(is_invalid, "境界不足时应返回false")

# 测试物品/秘籍消耗解锁
func test_item_cost_unlock():
	# Given: 玩家拥有2个武学残页，解锁需要2个武学残页
	mock_inventory.add_item("martial_fragment", 2)
	
	# When: 系统验证物品条件
	var required_items = {"martial_fragment": 2}
	var validation = unlock_manager.validate_item_requirements(required_items)
	
	# Then: 物品条件满足，返回true
	assert_true(validation.success, "物品条件应满足")
	
	# When: 消耗物品
	var consumed = unlock_manager.consume_items_for_unlock(required_items)
	
	# Then: 消耗成功，物品数量减少
	assert_true(consumed, "物品消耗应成功")
	assert_eq(mock_inventory.get_item_count("martial_fragment"), 0, "物品应被消耗")

# 测试奇遇/事件解锁
func test_event_unlock():
	# Given: 玩家触发山洞石壁参悟奇遇事件
	var event_id = "cave_stone_wall_enlightenment"
	var skill_id = "dugu_nine_swords_fragment"
	
	# When: 系统处理奇遇解锁
	var unlocked = unlock_manager.trigger_event_unlock(event_id, skill_id)
	
	# Then: 独孤九剑残篇解锁，添加到玩家武学列表
	assert_true(unlocked, "奇遇解锁应成功")
	assert_true(unlock_manager.is_skill_unlocked(skill_id), "武学应已解锁")
	assert_true(mock_event.is_event_triggered(event_id), "事件应已触发")

# 边缘情况测试：熟练度边界值
func test_edge_case_proficiency_boundaries():
	# Given: 测试熟练度为0和最大值15的边界情况
	unlock_manager.set_proficiency_level("test_martial", 0)
	
	# When: 验证熟练度为0
	var is_valid_zero = unlock_manager.validate_proficiency_requirement("test_martial", 0)
	
	# Then: 应满足条件
	assert_true(is_valid_zero, "熟练度为0时应满足0的要求")
	
	# Given: 设置熟练度为15（最大值）
	unlock_manager.set_proficiency_level("test_martial", 15)
	
	# When: 验证熟练度为15
	var is_valid_max = unlock_manager.validate_proficiency_requirement("test_martial", 15)
	
	# Then: 应满足条件
	assert_true(is_valid_max, "熟练度为15时应满足15的要求")
	
	# 测试超出范围的设置（应被限制）
	unlock_manager.set_proficiency_level("test_martial", 20)
	var clamped_level = unlock_manager.get_proficiency_level("test_martial")
	assert_eq(clamped_level, 15, "熟练度应被限制在15以内")

# 边缘情况测试：境界边界值
func test_edge_case_realm_boundaries():
	# Given: 测试境界为1和最大值10的边界情况
	unlock_manager.set_current_realm(1)
	
	# When: 验证境界为1
	var is_valid_min = unlock_manager.validate_realm_requirement(1)
	
	# Then: 应满足条件
	assert_true(is_valid_min, "境界为1时应满足1的要求")
	
	# Given: 设置境界为10（最大值）
	unlock_manager.set_current_realm(10)
	
	# When: 验证境界为10
	var is_valid_max = unlock_manager.validate_realm_requirement(10)
	
	# Then: 应满足条件
	assert_true(is_valid_max, "境界为10时应满足10的要求")
	
	# 测试超出范围的设置（应被限制）
	unlock_manager.set_current_realm(15)
	var clamped_realm = unlock_manager.get_current_realm()
	assert_eq(clamped_realm, 10, "境界应被限制在10以内")

# 边缘情况测试：物品数量不足
func test_edge_case_insufficient_items():
	# Given: 玩家拥有1个武学残页，但需要2个
	mock_inventory.add_item("martial_fragment", 1)
	
	# When: 验证物品条件
	var required_items = {"martial_fragment": 2}
	var validation = unlock_manager.validate_item_requirements(required_items)
	
	# Then: 物品条件不满足
	assert_false(validation.success, "物品不足时应返回false")
	assert_false(validation.missing_conditions.is_empty(), "应有缺失物品记录")
	
	# 验证缺失物品信息
	var missing = validation.missing_conditions[0]
	assert_eq(missing["item_id"], "martial_fragment", "缺失物品ID应正确")
	assert_eq(missing["required"], 2, "需要数量应为2")
	assert_eq(missing["owned"], 1, "拥有数量应为1")
	assert_eq(missing["missing"], 1, "缺失数量应为1")

# 边缘情况测试：物品类型错误
func test_edge_case_wrong_item_type():
	# Given: 玩家拥有错误类型的物品
	mock_inventory.add_item("wrong_item", 5)
	
	# When: 验证需要的物品
	var required_items = {"martial_fragment": 2}
	var validation = unlock_manager.validate_item_requirements(required_items)
	
	# Then: 物品条件不满足
	assert_false(validation.success, "错误物品类型应不满足条件")

# 边缘情况测试：重复触发奇遇
func test_edge_case_duplicate_event_trigger():
	# Given: 玩家已触发过某个奇遇事件
	var event_id = "test_event"
	var skill_id = "test_skill"
	
	unlock_manager.trigger_event_unlock(event_id, skill_id)
	
	# When: 再次触发同一奇遇
	var second_unlock = unlock_manager.trigger_event_unlock(event_id, skill_id)
	
	# Then: 第二次解锁应失败（武学已解锁）
	assert_false(second_unlock, "重复解锁应失败")
	
	# 验证事件仍然标记为已触发
	assert_true(mock_event.is_event_triggered(event_id), "事件应保持已触发状态")

# 边缘情况测试：无效奇遇ID
func test_edge_case_invalid_event_id():
	# Given: 使用无效的奇遇ID
	var invalid_event_id = "non_existent_event"
	
	# When: 验证事件条件
	var is_valid = unlock_manager.validate_event_requirement(invalid_event_id)
	
	# Then: 应返回false
	assert_false(is_valid, "无效奇遇ID应返回false")

# 测试完整解锁流程
func test_complete_unlock_workflow():
	# Given: 设置所有解锁条件
	unlock_manager.set_proficiency_level("huashan_sword", 5)
	unlock_manager.set_current_realm(3)
	mock_inventory.add_item("martial_fragment", 2)
	
	# When: 执行完整解锁流程
	var result = unlock_manager.unlock_skill_with_conditions(
		"huashan_sword",
		"beng",
		5,  # required_proficiency
		3,  # required_realm
		{"martial_fragment": 2}  # required_items
	)
	
	# Then: 解锁应成功
	assert_true(result.success, "完整解锁流程应成功")
	assert_true(unlock_manager.is_skill_unlocked("beng"), "武学应已解锁")
	assert_eq(mock_inventory.get_item_count("martial_fragment"), 0, "物品应被消耗")

# 测试部分条件不满足
func test_partial_conditions_not_met():
	# Given: 只满足部分条件
	unlock_manager.set_proficiency_level("huashan_sword", 5)
	unlock_manager.set_current_realm(2)  # 境界不足
	mock_inventory.add_item("martial_fragment", 2)
	
	# When: 验证解锁条件
	var result = unlock_manager.validate_unlock_conditions(
		"huashan_sword",
		"beng",
		5,  # required_proficiency
		3,  # required_realm (不满足)
		{"martial_fragment": 2}
	)
	
	# Then: 应返回失败，并列出缺失条件
	assert_false(result.success, "部分条件不满足时应返回false")
	assert_false(result.missing_conditions.is_empty(), "应有缺失条件记录")
	
	# 验证缺失条件类型
	var has_realm_missing = false
	for condition in result.missing_conditions:
		if condition.type == SkillUnlockManager.UnlockConditionType.REALM:
			has_realm_missing = true
			assert_eq(condition.required, 3, "需要境界应为3")
			assert_eq(condition.current, 2, "当前境界应为2")
	
	assert_true(has_realm_missing, "应检测到境界条件缺失")

# 测试解锁历史记录
func test_unlock_history_tracking():
	# Given: 解锁一个武学
	var skill_id = "test_skill"
	unlock_manager.unlock_skill(skill_id, "manual")
	
	# When: 获取解锁历史
	var history = unlock_manager.get_unlock_history(skill_id)
	
	# Then: 应有历史记录
	assert_false(history.is_empty(), "应有解锁历史记录")
	assert_true(history.has("timestamp"), "应记录时间戳")
	assert_eq(history["source"], "manual", "应记录解锁来源")

# 测试获取已解锁武学列表
func test_get_unlocked_skills_list():
	# Given: 解锁多个武学
	unlock_manager.unlock_skill("skill_1")
	unlock_manager.unlock_skill("skill_2")
	unlock_manager.unlock_skill("skill_3")
	
	# When: 获取已解锁列表
	var unlocked = unlock_manager.get_unlocked_skills()
	
	# Then: 应包含所有已解锁武学
	assert_eq(unlocked.size(), 3, "应有3个已解锁武学")
	assert_true(unlocked.has("skill_1"), "应包含skill_1")
	assert_true(unlocked.has("skill_2"), "应包含skill_2")
	assert_true(unlocked.has("skill_3"), "应包含skill_3")

# 测试重置玩家数据
func test_reset_player_data():
	# Given: 设置一些玩家数据
	unlock_manager.set_proficiency_level("test_martial", 10)
	unlock_manager.set_current_realm(5)
	unlock_manager.unlock_skill("test_skill")
	
	# When: 重置玩家数据
	unlock_manager.reset_player_data()
	
	# Then: 所有数据应被清空
	assert_eq(unlock_manager.get_proficiency_level("test_martial"), 0, "熟练度应重置为0")
	assert_eq(unlock_manager.get_current_realm(), 1, "境界应重置为1")
	assert_false(unlock_manager.is_skill_unlocked("test_skill"), "武学应未解锁")
	assert_true(unlock_manager.get_unlocked_skills().is_empty(), "已解锁列表应为空")

# 测试多物品消耗
func test_multiple_items_consumption():
	# Given: 玩家拥有多种物品
	mock_inventory.add_item("item_a", 3)
	mock_inventory.add_item("item_b", 2)
	mock_inventory.add_item("item_c", 1)
	
	# When: 需要消耗多种物品
	var required_items = {
		"item_a": 2,
		"item_b": 1,
		"item_c": 1
	}
	var consumed = unlock_manager.consume_items_for_unlock(required_items)
	
	# Then: 所有物品应被正确消耗
	assert_true(consumed, "多物品消耗应成功")
	assert_eq(mock_inventory.get_item_count("item_a"), 1, "item_a应剩余1个")
	assert_eq(mock_inventory.get_item_count("item_b"), 1, "item_b应剩余1个")
	assert_eq(mock_inventory.get_item_count("item_c"), 0, "item_c应被完全消耗")