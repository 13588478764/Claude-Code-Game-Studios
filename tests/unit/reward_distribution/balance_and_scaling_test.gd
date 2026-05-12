extends "res://addons/gut/test.gd"

class_name BalanceAndScalingTest

# 测试奖励平衡与缩放机制
# 覆盖等级挂钩缩放、通胀控制、背包容量管理和物品层级锁定

var reward_type_manager: RewardTypeManager
var distribution_manager: RewardDistributionManager
var balance_manager: RewardBalanceManager

func before_all():
	# 初始化所有管理器
	reward_type_manager = RewardTypeManager.new()
	distribution_manager = RewardDistributionManager.new()
	balance_manager = RewardBalanceManager.new()
	
	distribution_manager.set_reward_type_manager(reward_type_manager)
	balance_manager.set_reward_managers(reward_type_manager, distribution_manager)

func after_all():
	# 清理测试资源
	if reward_type_manager:
		reward_type_manager.queue_free()
	if distribution_manager:
		distribution_manager.queue_free()
	if balance_manager:
		balance_manager.queue_free()

# 测试等级/境界挂钩的数值缩放
func test_level_realm_scaling():
	# Given: 不同玩家等级和基础奖励数量
	var base_amount_100 = 100
	var player_level_1 = 1
	var player_level_50 = 50
	var player_realm_0 = 0
	var player_realm_5 = 5
	
	# When: 计算缩放后的奖励数量
	var scaled_1 = balance_manager.calculate_scaled_reward_amount(base_amount_100, player_level_1, player_realm_0)
	var scaled_50 = balance_manager.calculate_scaled_reward_amount(base_amount_100, player_level_50, player_realm_0)
	var scaled_50_realm5 = balance_manager.calculate_scaled_reward_amount(base_amount_100, player_level_50, player_realm_5)
	
	# Then: 正确应用缩放公式
	# 公式: 基础奖励数量 × (1 + 玩家等级 × 等级缩放系数) × (1 + 境界 × 境界缩放系数)
	# 默认系数: level_scaling_coefficient = 0.1, realm_scaling_coefficient = 0.05
	assert_eq(scaled_1, 110, "玩家等级1时，100基础奖励应缩放为110 (100 * (1 + 1 * 0.1))")
	assert_eq(scaled_50, 600, "玩家等级50时，100基础奖励应缩放为600 (100 * (1 + 50 * 0.1))")
	assert_eq(scaled_50_realm5, 750, "玩家等级50境界5时，100基础奖励应缩放为750 (100 * (1 + 50 * 0.1) * (1 + 5 * 0.05))")

# 测试通胀控制机制
func test_inflation_control_mechanism():
	# Given: 游戏后期阶段（高等级）的奖励
	var rewards = [
		{"item_id": "iron_ore", "quantity": 10, "type": "random"},
		{"item_id": "silver", "quantity": 100, "type": "random"},
		{"item_id": "rare_sword", "quantity": 1, "type": "random"}
	]
	var player_level_60 = 60  # 超过通胀控制阈值50
	
	# When: 应用通胀控制
	var adjusted_rewards = balance_manager.apply_inflation_control(rewards, player_level_60)
	
	# Then: 低级材料奖励大幅减少，高级奖励增加
	var has_low_tier_reduction = false
	var has_high_tier_compensation = false
	
	for reward in adjusted_rewards:
		if reward.item_id == "iron_ore":
			# 低级材料应减少80% (10 * (1 - 0.8) = 2)
			assert_eq(reward.quantity, 2, "低级材料应减少80%")
			has_low_tier_reduction = true
		elif reward.type == "inflation_compensation":
			has_high_tier_compensation = true
	
	assert_true(has_low_tier_reduction, "应包含低级材料减少")
	assert_true(has_high_tier_compensation, "应包含高级补偿奖励")

# 测试背包容量管理
func test_backpack_capacity_management():
	# Given: 背包已满状态和不可堆叠物品
	balance_manager.set_backpack_capacity(5)
	balance_manager.update_backpack_usage(5)  # 背包已满
	
	var rewards = [
		{"item_id": "legendary_sword", "quantity": 1, "type": "random"},  # 不可堆叠物品
		{"item_id": "silver", "quantity": 100, "type": "random"}         # 可堆叠物品
	]
	var player_id = "player_001"
	
	# When: 处理背包容量
	var processed_rewards = balance_manager.handle_backpack_capacity(rewards, player_id)
	
	# Then: 不可堆叠物品转换为等值银两，可堆叠物品也转换为银两
	var total_silver = 0
	for reward in processed_rewards:
		if reward.item_id == "silver":
			total_silver += reward.quantity
	
	# 传奇剑价值1000银两，加上原有的100银两
	assert_true(total_silver >= 1000, "背包满时不可堆叠物品应转换为等值银两")

# 测试物品层级锁定
func test_item_tier_locking():
	# Given: 不同区域等级和物品奖励
	var rewards = [
		{"item_id": "iron_ore", "quantity": 5, "type": "random"},        # 低级物品
		{"item_id": "legendary_sword", "quantity": 1, "type": "random"}  # 高级物品
	]
	var region_tier_3 = 3    # 高等级区域
	var region_tier_1 = 1    # 低等级区域
	var player_level_25 = 25
	
	# When: 在高等级区域应用层级锁定
	var high_tier_rewards = balance_manager.apply_item_tier_locking(rewards, region_tier_3, player_level_25)
	
	# Then: 高等级区域不应掉落低级垃圾
	var has_low_tier_in_high = false
	for reward in high_tier_rewards:
		if reward.item_id == "iron_ore":
			has_low_tier_in_high = true
			break
	
	assert_false(has_low_tier_in_high, "高等级区域不应掉落低级物品")
	
	# When: 在低等级区域应用层级锁定
	var low_tier_rewards = balance_manager.apply_item_tier_locking(rewards, region_tier_1, player_level_25)
	
	# Then: 低等级区域不应掉落神级装备
	var has_high_tier_in_low = false
	for reward in low_tier_rewards:
		if reward.item_id == "legendary_sword":
			has_high_tier_in_low = true
			break
	
	assert_false(has_high_tier_in_low, "低等级区域不应掉落神级装备")

# 边缘情况测试：等级边界值
func test_edge_cases_level_boundary_values():
	# Given: 等级边界值
	var base_amount = 50
	var player_level_1 = 1
	var player_level_99 = 99
	
	# When: 计算边界值缩放
	var scaled_1 = balance_manager.calculate_scaled_reward_amount(base_amount, player_level_1)
	var scaled_99 = balance_manager.calculate_scaled_reward_amount(base_amount, player_level_99)
	
	# Then: 边界值应正确处理
	assert_eq(scaled_1, 55, "等级1边界值应正确计算")
	assert_eq(scaled_99, 545, "等级99边界值应正确计算")

# 边缘情况测试：部分背包空间可用
func test_edge_cases_partial_backpack_space():
	# Given: 部分背包空间可用
	# 注意：balance_manager 在 before_all 中创建并复用，必须显式重置
	# backpack 状态，避免被前序测试污染
	balance_manager.reset_backpack_usage()
	balance_manager.set_backpack_capacity(10)
	balance_manager.update_backpack_usage(7)  # 还有3个空间
	
	var rewards = [
		{"item_id": "health_potion", "quantity": 5, "type": "random"}  # 可堆叠物品
	]
	var player_id = "player_002"
	
	# When: 处理部分空间
	var processed_rewards = balance_manager.handle_backpack_capacity(rewards, player_id)
	
	# Then: 部分物品（3 个 potion）放入背包，剩余 2 个转换为 silver overflow
	# 修正断言：原测试把 silver 数量和 potion 数量加和，但 silver 是按价值计算的，
	# 不能与 potion 数量直接相加。改为：分别验证"有部分进入背包"和"有 overflow 转换"。
	var potion_quantity_in_backpack = 0
	var has_overflow_conversion = false
	
	for reward in processed_rewards:
		if reward.item_id == "health_potion":
			potion_quantity_in_backpack += reward.quantity
		if reward.type == "overflow_conversion":
			has_overflow_conversion = true
	
	# 背包有 3 个空间，应放入 3 个 potion
	assert_eq(potion_quantity_in_backpack, 3,
		"背包剩余 3 空间应放入 3 个 potion（总共要求 5 个）")
	assert_true(has_overflow_conversion, "应包含溢出转换（剩 2 个 potion 转 silver）")

# 边缘情况测试：跨等级区域边界
func test_edge_cases_cross_tier_boundaries():
	# Given: 跨等级区域边界
	var rewards = [
		{"item_id": "common_sword", "quantity": 1, "type": "random"},
		{"item_id": "rare_sword", "quantity": 1, "type": "random"}
	]
	var region_tier_2 = 2  # 中级区域
	var player_level_15 = 15
	
	# When: 在中级区域应用层级锁定
	var tier_2_rewards = balance_manager.apply_item_tier_locking(rewards, region_tier_2, player_level_15)
	
	# Then: 中级区域应允许中级物品，可能调整低级物品
	var has_common_sword = false
	var has_rare_sword = false
	
	for reward in tier_2_rewards:
		if reward.item_id == "common_sword":
			has_common_sword = true
		elif reward.item_id == "rare_sword":
			has_rare_sword = true
	
	# 中级区域应该允许两种物品，但可能对低级物品进行调整
	assert_true(has_rare_sword, "中级区域应包含稀有剑")
	# common_sword可能被替换或保留，取决于具体实现

# 测试完整奖励平衡流程
func test_complete_reward_balance_flow():
	# Given: 完整的奖励平衡参数
	var rewards = [
		{"item_id": "silver", "quantity": 50, "type": "fixed"},
		{"item_id": "iron_ore", "quantity": 10, "type": "random"},
		{"item_id": "legendary_sword", "quantity": 1, "type": "random"}
	]
	var player_level = 60
	var player_realm = 6
	var player_id = "player_003"
	var region_tier = 3
	
	# 设置背包状态
	balance_manager.set_backpack_capacity(20)
	balance_manager.update_backpack_usage(15)
	
	# When: 应用完整的奖励平衡逻辑
	var balanced_rewards = balance_manager.apply_complete_reward_balance(rewards, player_level, player_realm, player_id, region_tier)
	
	# Then: 所有平衡机制应正确应用
	assert_true(balanced_rewards.size() > 0, "平衡后的奖励列表不应为空")
	
	# 检查是否包含固定奖励（不应受平衡影响）
	var has_fixed_silver = false
	for reward in balanced_rewards:
		if reward.item_id == "silver" and reward.type == "fixed":
			has_fixed_silver = true
			break
	
	assert_true(has_fixed_silver, "应包含未受影响的固定奖励")

# 测试配置参数调整
func test_configuration_parameter_adjustment():
	# Given: 自定义配置参数
	balance_manager.level_scaling_coefficient = 0.2
	balance_manager.inflation_control_threshold = 30
	balance_manager.low_tier_material_reduction_rate = 0.5
	
	# When: 使用自定义参数计算
	var base_amount = 100
	var player_level_40 = 40
	var scaled_amount = balance_manager.calculate_scaled_reward_amount(base_amount, player_level_40)
	
	var rewards = [{"item_id": "iron_ore", "quantity": 10, "type": "random"}]
	var inflation_rewards = balance_manager.apply_inflation_control(rewards, player_level_40)
	
	# Then: 自定义参数应正确应用
	assert_eq(scaled_amount, 900, "自定义缩放系数应正确应用 (100 * (1 + 40 * 0.2))")
	
	# 通胀控制应在等级30以上生效，减少率50%
	var iron_ore_quantity = 0
	for reward in inflation_rewards:
		if reward.item_id == "iron_ore":
			iron_ore_quantity = reward.quantity
			break
	
	assert_eq(iron_ore_quantity, 5, "自定义通胀控制参数应正确应用 (10 * (1 - 0.5))")
