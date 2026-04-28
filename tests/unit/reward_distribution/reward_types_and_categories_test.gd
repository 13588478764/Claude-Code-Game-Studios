extends "res://addons/gut/test.gd"

class_name RewardTypesAndCategoriesTest

# 测试奖励类型与分类功能
# 覆盖四大类奖励类型的验证和分类

var reward_manager: RewardTypeManager

func before_all():
	# 初始化奖励类型管理器
	reward_manager = RewardTypeManager.new()

func after_all():
	# 清理测试资源
	if reward_manager:
		reward_manager.queue_free()

# 测试物质资源奖励类型
func test_material_resources_reward_types():
	# Given: 物质资源奖励ID
	var silver_id = "silver"
	var iron_ore_id = "iron_ore"
	var thousand_year_ginseng_id = "thousand_year_ginseng"
	
	# When: 验证奖励类别
	var silver_category = reward_manager.get_reward_category(silver_id)
	var iron_ore_category = reward_manager.get_reward_category(iron_ore_id)
	var ginseng_category = reward_manager.get_reward_category(thousand_year_ginseng_id)
	
	# Then: 正确识别为物质资源类别
	assert_equal(silver_category, RewardTypeManager.RewardCategory.MATERIAL_RESOURCES, "银两应属于物质资源类别")
	assert_equal(iron_ore_category, RewardTypeManager.RewardCategory.MATERIAL_RESOURCES, "铁矿石应属于物质资源类别")
	assert_equal(ginseng_category, RewardTypeManager.RewardCategory.MATERIAL_RESOURCES, "千年灵芝应属于物质资源类别")
	
	# 验证配置正确加载
	var silver_config = reward_manager.get_reward_config(silver_id)
	assert_true(silver_config.has("name"), "银两配置应包含名称")
	assert_equal(silver_config.name, "银两", "银两名称应正确")
	assert_true(silver_config.stackable, "银两应可堆叠")

# 测试成长资源奖励类型
func test_progression_resources_reward_types():
	# Given: 成长资源奖励ID
	var exp_id = "experience"
	var proficiency_id = "proficiency_fragment"
	var attribute_points_id = "attribute_points"
	var talent_points_id = "talent_points"
	
	# When: 验证奖励类别
	var exp_category = reward_manager.get_reward_category(exp_id)
	var proficiency_category = reward_manager.get_reward_category(proficiency_id)
	var attr_category = reward_manager.get_reward_category(attribute_points_id)
	var talent_category = reward_manager.get_reward_category(talent_points_id)
	
	# Then: 正确识别为成长资源类别
	assert_equal(exp_category, RewardTypeManager.RewardCategory.PROGRESSION_RESOURCES, "经验值应属于成长资源类别")
	assert_equal(proficiency_category, RewardTypeManager.RewardCategory.PROGRESSION_RESOURCES, "武学熟练度残页应属于成长资源类别")
	assert_equal(attr_category, RewardTypeManager.RewardCategory.PROGRESSION_RESOURCES, "属性点应属于成长资源类别")
	assert_equal(talent_category, RewardTypeManager.RewardCategory.PROGRESSION_RESOURCES, "天赋点应属于成长资源类别")
	
	# 验证配置正确加载
	var exp_config = reward_manager.get_reward_config(exp_id)
	assert_equal(exp_config.name, "经验值", "经验值名称应正确")
	assert_equal(exp_config.max_stack, 999999999, "经验值最大堆叠数应正确")

# 测试装备物品奖励类型
func test_equipment_items_reward_types():
	# Given: 装备物品奖励ID
	var sword_id = "common_sword"
	var health_potion_id = "health_potion"
	var key_id = "key"
	
	# When: 验证奖励类别
	var sword_category = reward_manager.get_reward_category(sword_id)
	var potion_category = reward_manager.get_reward_category(health_potion_id)
	var key_category = reward_manager.get_reward_category(key_id)
	
	# Then: 正确识别为装备物品类别
	assert_equal(sword_category, RewardTypeManager.RewardCategory.EQUIPMENT_ITEMS, "普通剑应属于装备物品类别")
	assert_equal(potion_category, RewardTypeManager.RewardCategory.EQUIPMENT_ITEMS, "回血丹应属于装备物品类别")
	assert_equal(key_category, RewardTypeManager.RewardCategory.EQUIPMENT_ITEMS, "钥匙应属于装备物品类别")
	
	# 验证不同子类型的配置
	var sword_config = reward_manager.get_reward_config(sword_id)
	assert_false(sword_config.stackable, "成品装备不应可堆叠")
	assert_equal(sword_config.rarity, "common", "普通剑稀有度应为common")
	
	var potion_config = reward_manager.get_reward_config(health_potion_id)
	assert_true(potion_config.stackable, "消耗品应可堆叠")
	assert_equal(potion_config.max_stack, 99, "消耗品最大堆叠数应为99")

# 测试叙事状态奖励类型
func test_narrative_status_reward_types():
	# Given: 叙事状态奖励ID
	var good_reputation_id = "good_reputation"
	var refreshed_mind_id = "refreshed_mind"
	var high_master_id = "high_master"
	
	# When: 验证奖励类别
	var rep_category = reward_manager.get_reward_category(good_reputation_id)
	var buff_category = reward_manager.get_reward_category(refreshed_mind_id)
	var title_category = reward_manager.get_reward_category(high_master_id)
	
	# Then: 正确识别为叙事状态类别
	assert_equal(rep_category, RewardTypeManager.RewardCategory.NARRATIVE_STATUS, "善名应属于叙事状态类别")
	assert_equal(buff_category, RewardTypeManager.RewardCategory.NARRATIVE_STATUS, "神清气爽应属于叙事状态类别")
	assert_equal(title_category, RewardTypeManager.RewardCategory.NARRATIVE_STATUS, "破庙高人应属于叙事状态类别")
	
	# 验证特殊属性
	var buff_config = reward_manager.get_reward_config(refreshed_mind_id)
	assert_equal(buff_config.duration, 3600, "神清气爽持续时间应为3600秒")
	
	var title_config = reward_manager.get_reward_config(high_master_id)
	assert_equal(title_config.bonus_luck, 5, "破庙高人称号应提供5点福缘加成")

# 边缘情况测试：无效奖励ID
func test_invalid_reward_ids():
	# Given: 无效的奖励ID
	var invalid_id = "non_existent_reward"
	var empty_id = ""
	
	# When: 验证奖励类别
	var invalid_category = reward_manager.get_reward_category(invalid_id)
	var empty_category = reward_manager.get_reward_category(empty_id)
	
	# Then: 返回-1表示无效
	assert_equal(invalid_category, -1, "无效奖励ID应返回-1")
	assert_equal(empty_category, -1, "空奖励ID应返回-1")
	
	# 验证有效性检查
	assert_false(reward_manager.is_valid_reward_id(invalid_id), "无效奖励ID应返回false")
	assert_false(reward_manager.is_valid_reward_id(empty_id), "空奖励ID应返回false")

# 边缘情况测试：边界值和负值
func test_edge_cases_boundary_values():
	# Given: 边界值测试
	var max_stack_exp = reward_manager.get_reward_config("experience").max_stack
	var min_stack_item = reward_manager.get_reward_config("thousand_year_ginseng").max_stack
	
	# When: 检查配置值
	# Then: 配置值应在合理范围内
	assert_true(max_stack_exp > 1000000, "经验值最大堆叠数应大于100万")
	assert_equal(min_stack_item, 1, "不可堆叠物品最大堆叠数应为1")
	
	# 测试缓存功能
	var first_lookup = reward_manager.get_reward_category("silver")
	var second_lookup = reward_manager.get_reward_category("silver")
	
	# 缓存应工作正常
	assert_equal(first_lookup, second_lookup, "缓存应返回相同结果")

# 测试自定义奖励类型添加
func test_custom_reward_type_addition():
	# Given: 自定义奖励类型
	var custom_category = "material_resources"
	var custom_subcategory = "basic_materials"
	var custom_id = "custom_ore"
	var custom_config = {"name": "自定义矿石", "stackable": true, "max_stack": 500}
	
	# When: 添加自定义奖励类型
	reward_manager.add_custom_reward_type(custom_category, custom_subcategory, custom_id, custom_config)
	
	# Then: 自定义奖励类型应可被识别
	var custom_category_result = reward_manager.get_reward_category(custom_id)
	assert_equal(custom_category_result, RewardTypeManager.RewardCategory.MATERIAL_RESOURCES, "自定义矿石应属于物质资源类别")
	
	var custom_config_result = reward_manager.get_reward_config(custom_id)
	assert_equal(custom_config_result.name, "自定义矿石", "自定义矿石名称应正确")
	assert_equal(custom_config_result.max_stack, 500, "自定义矿石最大堆叠数应正确")

# 测试配置重置功能
func test_configuration_reset():
	# Given: 修改后的配置
	reward_manager.add_custom_reward_type("material_resources", "basic_materials", "test_item", {"name": "测试物品"})
	
	# When: 重置为默认配置
	reward_manager.reset_to_default_config()
	
	# Then: 自定义项应被移除
	var test_item_category = reward_manager.get_reward_category("test_item")
	assert_equal(test_item_category, -1, "重置后自定义项应不存在")