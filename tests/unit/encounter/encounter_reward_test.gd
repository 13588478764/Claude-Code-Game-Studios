# 奇遇奖励系统单元测试
# 验证奇遇奖励类型、奖励发放机制、福缘影响和奖励冲突处理

extends Node

# 加载奇遇奖励管理器
var EncounterRewardManager = load("res://src/scripts/encounter/encounter_reward_manager.gd")

var encounter_reward_manager
var test_result = {
	"passed": 0,
	"failed": 0,
	"total": 0,
	"details": []
}

func _ready():
	print("开始奇遇奖励系统单元测试...")
	
	# 运行所有测试
	test_encounter_reward_types()
	test_reward_distribution_mechanism()
	test_luck_impact_on_reward_quality()
	test_reward_conflict_handling()
	
	# 输出测试结果
	print("\n=== 奇遇奖励系统单元测试结果 ===")
	print("通过: %d" % test_result.passed)
	print("失败: %d" % test_result.failed)
	print("总计: %d" % test_result.total)
	
	if test_result.failed == 0:
		print("✅ 所有测试通过！")
	else:
		print("❌ 有 %d 个测试失败" % test_result.failed)
	
	for detail in test_result.details:
		print(detail)

# 测试奇遇奖励类型
func test_encounter_reward_types():
	print("\n--- 测试奇遇奖励类型 ---")
	
	encounter_reward_manager = EncounterRewardManager.new()
	
	# 测试江湖传闻奖励
	var jianghu_rewards = encounter_reward_manager.generate_reward_package(encounter_reward_manager.EncounterType.JIANGHU_RUMOR, 0)
	var has_silver = false
	var has_material = false
	for reward in jianghu_rewards:
		if reward.type == encounter_reward_manager.RewardType.SILVER:
			has_silver = true
		if reward.type == encounter_reward_manager.RewardType.MATERIAL:
			has_material = true
	
	if has_silver and has_material:
		add_test_result("奇遇奖励类型", true, "江湖传闻奖励类型正确（银两和材料）")
	else:
		add_test_result("奇遇奖励类型", false, "江湖传闻奖励类型不完整")
	
	# 测试天材地宝奖励
	var tiancai_rewards = encounter_reward_manager.generate_reward_package(encounter_reward_manager.EncounterType.TIANCAI_DIBAO, 0)
	var has_pill = false
	var has_rare_material = false
	for reward in tiancai_rewards:
		if reward.item_id in ["pill_realm_breakthrough", "pill_attribute_reset"]:
			has_pill = true
		if reward.description == "稀有材料":
			has_rare_material = true
	
	if has_pill and has_rare_material:
		add_test_result("奇遇奖励类型", true, "天材地宝奖励类型正确（丹药和稀有材料）")
	else:
		add_test_result("奇遇奖励类型", false, "天材地宝奖励类型不完整")

# 测试奖励发放机制
func test_reward_distribution_mechanism():
	print("\n--- 测试奖励发放机制 ---")
	
	# 创建模拟的依赖系统
	var mock_economy_manager = MockEconomyManager.new()
	var mock_character_stats = MockCharacterStats.new()
	var mock_martial_arts_manager = MockMartialArtsManager.new()
	var mock_inventory_manager = MockInventoryManager.new()
	
	encounter_reward_manager = EncounterRewardManager.new()
	encounter_reward_manager.initialize(mock_economy_manager, mock_character_stats, mock_martial_arts_manager, mock_inventory_manager)
	
	# 测试高人指点奖励发放
	var gaoren_rewards = encounter_reward_manager.distribute_reward(encounter_reward_manager.EncounterType.GAOREN_ZHIDIAN, 50)
	
	# 检查是否尝试分发属性点和天赋点
	if mock_character_stats.attribute_points_added > 0 and mock_character_stats.talent_points_added > 0:
		add_test_result("奖励发放机制", true, "高人指点奖励发放成功")
	else:
		add_test_result("奖励发放机制", false, "高人指点奖励发放失败")
	
	# 测试银两奖励发放
	if mock_economy_manager.currency_added[0] > 0:  # 假设银两是第一种货币
		add_test_result("奖励发放机制", true, "银两奖励发放成功")
	else:
		add_test_result("奖励发放机制", false, "银两奖励发放失败")

# 测试福缘影响奖励质量
func test_luck_impact_on_reward_quality():
	print("\n--- 测试福缘影响奖励质量 ---")
	
	encounter_reward_manager = EncounterRewardManager.new()
	
	# 生成低福缘奖励包
	var low_luck_rewards = encounter_reward_manager.generate_reward_package(encounter_reward_manager.EncounterType.GAOREN_ZHIDIAN, 0)
	var low_luck_exp = 0
	for reward in low_luck_rewards:
		if reward.type == encounter_reward_manager.RewardType.EXP:
			low_luck_exp = reward.value
			break
	
	# 生成高福缘奖励包
	var high_luck_rewards = encounter_reward_manager.generate_reward_package(encounter_reward_manager.EncounterType.GAOREN_ZHIDIAN, 100)
	var high_luck_exp = 0
	for reward in high_luck_rewards:
		if reward.type == encounter_reward_manager.RewardType.EXP:
			high_luck_exp = reward.value
			break
	
	if high_luck_exp > low_luck_exp:
		add_test_result("福缘影响奖励质量", true, "高福缘奖励数量高于低福缘奖励")
	else:
		add_test_result("福缘影响奖励质量", false, "福缘未正确影响奖励数量")

# 测试奖励冲突处理
func test_reward_conflict_handling():
	print("\n--- 测试奖励冲突处理 ---")
	
	# 创建模拟的依赖系统
	var mock_inventory_full = MockInventoryManagerFull.new()  # 模拟背包已满
	
	encounter_reward_manager = EncounterRewardManager.new()
	encounter_reward_manager.initialize(null, null, null, mock_inventory_full)
	
	# 测试背包满时的奖励处理
	var test_reward = encounter_reward_manager.Reward.new(
		encounter_reward_manager.RewardType.ITEM, 
		1, 
		"test_item", 
		"测试物品"
	)
	
	var handled_rewards = encounter_reward_manager.handle_reward_conflicts([test_reward])
	
	# 检查是否进行了奖励转换
	if handled_rewards.size() > 0 and handled_rewards[0].type == encounter_reward_manager.RewardType.SILVER:
		add_test_result("奖励冲突处理", true, "背包满时奖励正确转换为银两")
	else:
		add_test_result("奖励冲突处理", false, "背包满时奖励未正确转换")

# 辅助函数：添加测试结果
func add_test_result(test_name: String, passed: bool, message: String):
	test_result.total += 1
	if passed:
		test_result.passed += 1
		print("✅ %s: %s" % [test_name, message])
	else:
		test_result.failed += 1
		print("❌ %s: %s" % [test_name, message])
	
	test_result.details.append("%s: %s" % [test_name, "通过" if passed else "失败 - " + message])

# 模拟经济管理器
class MockEconomyManager:
	var currency_added = [0, 0, 0, 0, 0]  # 假设5种货币类型
	
	func add_currency(currency_type, amount):
		if currency_type == 0:  # 假设银两是第一种货币
			currency_added[currency_type] += amount
		return true

# 模拟角色统计管理器
class MockCharacterStats:
	var attribute_points_added = 0
	var talent_points_added = 0
	var exp_added = 0
	
	func add_attribute_points(amount):
		attribute_points_added += amount
	
	func add_talent_points(amount):
		talent_points_added += amount
	
	func add_exp(amount):
		exp_added += amount

# 模拟武学管理器
class MockMartialArtsManager:
	func learn_art(art_id):
		return true  # 假设总是成功学习
	
	func has_learned_art(art_id):
		return false

# 模拟背包管理器
class MockInventoryManager:
	func has_space_for_item(item_id, quantity):
		return true  # 假设总有空间
	
	func add_item(item_id, quantity):
		return true

# 模拟背包已满的管理器
class MockInventoryManagerFull:
	func has_space_for_item(item_id, quantity):
		return false  # 总是返回没有空间