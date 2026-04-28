extends "res://addons/gut/test.gd"

class_name DistributionMechanismsTest

# 测试奖励分配机制
# 覆盖固定基础奖励、权重化随机池、层级掉落表和唯一性限制

var reward_type_manager: RewardTypeManager
var distribution_manager: RewardDistributionManager

func before_all():
	# 初始化奖励类型管理器和分配管理器
	reward_type_manager = RewardTypeManager.new()
	distribution_manager = RewardDistributionManager.new()
	distribution_manager.set_reward_type_manager(reward_type_manager)

func after_all():
	# 清理测试资源
	if reward_type_manager:
		reward_type_manager.queue_free()
	if distribution_manager:
		distribution_manager.queue_free()

# 测试固定基础奖励机制
func test_fixed_base_rewards_mechanism():
	# Given: 奇遇类型配置包含固定基础奖励
	var encounter_type = "encounter_basic"
	
	# When: 获取固定基础奖励
	var fixed_rewards = distribution_manager.get_fixed_base_rewards(encounter_type)
	
	# Then: 正确返回固定奖励
	assert_true(fixed_rewards.has("silver"), "应包含银两奖励")
	assert_true(fixed_rewards.has("experience"), "应包含经验值奖励")
	assert_equal(fixed_rewards.silver, 50, "银两数量应为50")
	assert_equal(fixed_rewards.experience, 30, "经验值数量应为30")
	
	# 测试不存在的奇遇类型
	var invalid_type = "non_existent_encounter"
	var empty_rewards = distribution_manager.get_fixed_base_rewards(invalid_type)
	assert_true(empty_rewards.is_empty(), "不存在的奇遇类型应返回空字典")

# 测试权重化随机池机制
func test_weighted_random_pool_mechanism():
	# Given: 玩家具有不同福缘属性值
	var pool = {"silver": 100, "rare_sword": 10, "thousand_year_ginseng": 5}
	var luck_0 = 0    # 福缘为0
	var luck_80 = 80  # 福缘为80
	
	# When: 计算权重修正
	var adjusted_pool_0 = distribution_manager.calculate_weighted_pool(pool, luck_0)
	var adjusted_pool_80 = distribution_manager.calculate_weighted_pool(pool, luck_80)
	
	# Then: 稀有物品权重正确修正
	assert_equal(adjusted_pool_0.silver, 100, "普通物品权重不应受福缘影响")
	assert_equal(adjusted_pool_0.rare_sword, 10, "福缘为0时稀有物品权重不变")
	assert_equal(adjusted_pool_0.thousand_year_ginseng, 5, "福缘为0时稀有材料权重不变")
	
	# 福缘为80时，稀有物品权重应增加80%
	assert_equal(adjusted_pool_80.silver, 100, "普通物品权重不应受福缘影响")
	assert_equal(adjusted_pool_80.rare_sword, 18, "福缘为80时稀有物品权重应为18 (10 * 1.8)")
	assert_equal(adjusted_pool_80.thousand_year_ginseng, 9, "福缘为80时稀有材料权重应为9 (5 * 1.8)")

# 测试层级掉落表机制
func test_tier_drop_table_mechanism():
	# Given: 不同玩家等级和区域等级
	var player_level_5 = 5   # 玩家等级5
	var player_level_25 = 25 # 玩家等级25
	var region_tier_2 = 2    # 区域层级2
	
	# When: 计算掉落层级
	var tier_5 = distribution_manager.calculate_drop_tier(player_level_5)
	var tier_25 = distribution_manager.calculate_drop_tier(player_level_25)
	var tier_from_region = distribution_manager.calculate_drop_tier(player_level_25, 3, 10) # 使用区域层级
	
	# Then: 正确计算掉落层级
	assert_equal(tier_5, 0, "玩家等级5应计算为层级0 (5/10=0.5，向下取整)")
	assert_equal(tier_25, 2, "玩家等级25应计算为层级2 (25/10=2.5，向下取整)")
	
	# 测试获取掉落表
	var drop_table_1 = distribution_manager.get_tier_drop_table(1)
	var drop_table_3 = distribution_manager.get_tier_drop_table(3)
	
	assert_false(drop_table_1.is_empty(), "层级1掉落表不应为空")
	assert_false(drop_table_3.is_empty(), "层级3掉落表不应为空")
	assert_true(drop_table_1.has("material_resources"), "掉落表应包含物质资源")
	assert_true(drop_table_3.has("equipment_items"), "高级掉落表应包含装备物品")

# 测试唯一性限制机制
func test_uniqueness_limitation_mechanism():
	# Given: 玩家ID和唯一性物品
	var player_id = "player_001"
	var unique_item = "manual"  # 秘籍是唯一性物品
	var non_unique_item = "silver"  # 银两不是唯一性物品
	
	# When: 检查唯一性限制
	var can_obtain_unique_first = distribution_manager.check_unique_item_limitation(unique_item, player_id)
	var can_obtain_non_unique = distribution_manager.check_unique_item_limitation(non_unique_item, player_id)
	var can_obtain_unique_second = distribution_manager.check_unique_item_limitation(unique_item, player_id)
	
	# Then: 唯一性物品只能获得一次
	assert_true(can_obtain_unique_first, "第一次应能获得唯一性物品")
	assert_true(can_obtain_non_unique, "非唯一性物品应能正常获得")
	assert_false(can_obtain_unique_second, "第二次不应能获得同一唯一性物品")
	
	# 测试重置功能
	distribution_manager.reset_unique_items()
	var can_obtain_unique_after_reset = distribution_manager.check_unique_item_limitation(unique_item, player_id)
	assert_true(can_obtain_unique_after_reset, "重置后应能再次获得唯一性物品")

# 边缘情况测试：空奖励配置
func test_edge_cases_empty_reward_config():
	# Given: 空的奖励配置
	var empty_pool = {}
	var empty_encounter = "empty_encounter"
	
	# When: 处理空配置
	var adjusted_empty = distribution_manager.calculate_weighted_pool(empty_pool)
	var rewards_empty = distribution_manager.get_fixed_base_rewards(empty_encounter)
	var selected_empty = distribution_manager.select_from_weighted_pool(empty_pool)
	
	# Then: 应安全处理空配置
	assert_true(adjusted_empty.is_empty(), "空池应返回空字典")
	assert_true(rewards_empty.is_empty(), "空奇遇类型应返回空字典")
	assert_equal(selected_empty, "", "空池应返回空字符串")

# 边缘情况测试：福缘边界值
func test_edge_cases_luck_boundary_values():
	# Given: 福缘边界值
	var pool = {"rare_sword": 10}
	var luck_min = 0
	var luck_max = 100
	
	# When: 计算边界值权重
	var adjusted_min = distribution_manager.calculate_weighted_pool(pool, luck_min)
	var adjusted_max = distribution_manager.calculate_weighted_pool(pool, luck_max)
	
	# Then: 边界值应正确处理
	assert_equal(adjusted_min.rare_sword, 10, "福缘为0时权重不变")
	assert_equal(adjusted_max.rare_sword, 20, "福缘为100时权重翻倍 (10 * 2.0)")

# 边缘情况测试：层级边界值
func test_edge_cases_tier_boundary_values():
	# Given: 层级边界值
	var player_level_0 = 0
	var player_level_99 = 99
	var max_tier_5 = 5
	
	# When: 计算边界层级
	var tier_0 = distribution_manager.calculate_drop_tier(player_level_0)
	var tier_99 = distribution_manager.calculate_drop_tier(player_level_99, max_tier_5, 10)
	
	# Then: 边界值应正确处理
	assert_equal(tier_0, 0, "玩家等级0应计算为层级0")
	assert_equal(tier_99, 5, "玩家等级99在最大层级5时应返回5")

# 测试完整奖励生成流程
func test_complete_reward_generation_flow():
	# Given: 完整的奖励生成参数
	var encounter_type = "encounter_medium"
	var player_level = 15
	var player_luck = 50
	var player_id = "player_002"
	
	# When: 生成完整奖励列表
	var rewards = distribution_manager.generate_rewards(encounter_type, player_level, player_luck, player_id)
	
	# Then: 应包含固定奖励和随机奖励
	assert_true(rewards.size() > 0, "奖励列表不应为空")
	
	# 检查是否包含固定奖励
	var has_fixed_rewards = false
	for reward in rewards:
		if reward.type == "fixed":
			has_fixed_rewards = true
			break
	
	assert_true(has_fixed_rewards, "应包含固定基础奖励")
	
	# 检查奖励格式
	for reward in rewards:
		assert_true(reward.has("item_id"), "奖励应包含item_id")
		assert_true(reward.has("quantity"), "奖励应包含quantity")
		assert_true(reward.has("type"), "奖励应包含type")

# 测试自定义掉落表添加
func test_custom_drop_table_addition():
	# Given: 自定义掉落表
	var custom_tier = 4
	var custom_table = {
		"material_resources": {"silver": 1000, "mystic_iron": 50},
		"equipment_items": {"legendary_sword": 1}
	}
	
	# When: 添加自定义掉落表
	distribution_manager.add_custom_drop_table(custom_tier, custom_table)
	
	# Then: 自定义掉落表应可被获取
	var retrieved_table = distribution_manager.get_tier_drop_table(custom_tier)
	assert_equal(retrieved_table.material_resources.silver, 1000, "自定义掉落表应正确保存")
	assert_equal(retrieved_table.equipment_items.legendary_sword, 1, "自定义装备应正确保存")