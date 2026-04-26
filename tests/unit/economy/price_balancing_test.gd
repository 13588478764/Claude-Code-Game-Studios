# 价格平衡机制单元测试
# 验证强化费用计算、掉落修正机制、出售价格计算和黑市价格机制

extends Node

# 加载价格平衡管理器
var PriceBalancingManager = load("res://src/scripts/economy/price_balancing_manager.gd")

var price_balancing_manager
var test_result = {
	"passed": 0,
	"failed": 0,
	"total": 0,
	"details": []
}

func _ready():
	print("开始价格平衡机制单元测试...")
	
	# 运行所有测试
	test_upgrade_cost_calculation()
	test_drop_correction_mechanism()
	test_sell_price_calculation()
	test_blackmarket_price_mechanism()
	
	# 输出测试结果
	print("\n=== 价格平衡机制单元测试结果 ===")
	print("通过: %d" % test_result.passed)
	print("失败: %d" % test_result.failed)
	print("总计: %d" % test_result.total)
	
	if test_result.failed == 0:
		print("✅ 所有测试通过！")
	else:
		print("❌ 有 %d 个测试失败" % test_result.failed)
	
	for detail in test_result.details:
		print(detail)

# 测试强化费用计算
func test_upgrade_cost_calculation():
	print("\n--- 测试强化费用计算 ---")
	
	price_balancing_manager = PriceBalancingManager.new()
	
	# 测试强化费用计算 - 基础测试
	var cost_level_1 = price_balancing_manager.calculate_upgrade_cost(1)
	var expected_cost_1 = int(200 * pow(1.5, 1))  # 200 * 1.5 = 300
	if cost_level_1 == expected_cost_1:
		add_test_result("强化费用计算", true, "强化+1费用计算正确: %d" % cost_level_1)
	else:
		add_test_result("强化费用计算", false, "强化+1费用计算错误: 期望%d, 实际%d" % [expected_cost_1, cost_level_1])
	
	# 测试强化费用计算 - 更高等级
	var cost_level_6 = price_balancing_manager.calculate_upgrade_cost(6, 50)  # 基础费用50
	var expected_cost_6 = int(50 * pow(1.5, 6))  # 50 * 11.390625 ≈ 569
	if abs(cost_level_6 - expected_cost_6) <= 1:  # 允许1的误差
		add_test_result("强化费用计算", true, "强化+6费用计算正确: %d" % cost_level_6)
	else:
		add_test_result("强化费用计算", false, "强化+6费用计算错误: 期望%d, 实际%d" % [expected_cost_6, cost_level_6])
	
	# 测试边界情况：等级为0
	var cost_level_0 = price_balancing_manager.calculate_upgrade_cost(0)
	if cost_level_0 == 0:
		add_test_result("强化费用计算", true, "强化0级费用为0正确")
	else:
		add_test_result("强化费用计算", false, "强化0级费用应为0，实际为%d" % cost_level_0)

# 测试掉落修正机制
func test_drop_correction_mechanism():
	print("\n--- 测试掉落修正机制 ---")
	
	price_balancing_manager = PriceBalancingManager.new()
	
	# 测试掉落修正 - 福缘为0
	var corrected_drop_0 = price_balancing_manager.calculate_drop_amount(100, 0)
	var expected_drop_0 = int(100 * (1 + 0/100))  # 100 * 1 = 100
	if corrected_drop_0 == expected_drop_0:
		add_test_result("掉落修正机制", true, "福缘0掉落修正正确: %d" % corrected_drop_0)
	else:
		add_test_result("掉落修正机制", false, "福缘0掉落修正错误: 期望%d, 实际%d" % [expected_drop_0, corrected_drop_0])
	
	# 测试掉落修正 - 福缘为30
	var corrected_drop_30 = price_balancing_manager.calculate_drop_amount(100, 30)
	var expected_drop_30 = int(100 * (1 + 30/100))  # 100 * 1.3 = 130
	if corrected_drop_30 == expected_drop_30:
		add_test_result("掉落修正机制", true, "福缘30掉落修正正确: %d" % corrected_drop_30)
	else:
		add_test_result("掉落修正机制", false, "福缘30掉落修正错误: 期望%d, 实际%d" % [expected_drop_30, corrected_drop_30])
	
	# 测试掉落修正 - 福缘为100
	var corrected_drop_100 = price_balancing_manager.calculate_drop_amount(100, 100)
	var expected_drop_100 = int(100 * (1 + 100/100))  # 100 * 2 = 200
	if corrected_drop_100 == expected_drop_100:
		add_test_result("掉落修正机制", true, "福缘100掉落修正正确: %d" % corrected_drop_100)
	else:
		add_test_result("掉落修正机制", false, "福缘100掉落修正错误: 期望%d, 实际%d" % [expected_drop_100, corrected_drop_100])
	
	# 测试边界情况：基础掉落为0
	var corrected_drop_zero = price_balancing_manager.calculate_drop_amount(0, 50)
	if corrected_drop_zero == 0:
		add_test_result("掉落修正机制", true, "基础掉落为0时修正正确")
	else:
		add_test_result("掉落修正机制", false, "基础掉落为0时修正错误: 期望0, 实际%d" % corrected_drop_zero)

# 测试出售价格计算
func test_sell_price_calculation():
	print("\n--- 测试出售价格计算 ---")
	
	price_balancing_manager = PriceBalancingManager.new()
	
	# 测试出售价格计算 - 基础测试
	var sell_price_1000 = price_balancing_manager.calculate_sell_price(1000)
	var expected_sell_price_1000 = int(1000 * 0.5)  # 500
	if sell_price_1000 == expected_sell_price_1000:
		add_test_result("出售价格计算", true, "价值1000物品出售价格正确: %d" % sell_price_1000)
	else:
		add_test_result("出售价格计算", false, "价值1000物品出售价格错误: 期望%d, 实际%d" % [expected_sell_price_1000, sell_price_1000])
	
	# 测试出售价格计算 - 其他值
	var sell_price_750 = price_balancing_manager.calculate_sell_price(750)
	var expected_sell_price_750 = int(750 * 0.5)  # 375
	if sell_price_750 == expected_sell_price_750:
		add_test_result("出售价格计算", true, "价值750物品出售价格正确: %d" % sell_price_750)
	else:
		add_test_result("出售价格计算", false, "价值750物品出售价格错误: 期望%d, 实际%d" % [expected_sell_price_750, sell_price_750])
	
	# 测试边界情况：基础价值为0
	var sell_price_zero = price_balancing_manager.calculate_sell_price(0)
	if sell_price_zero == 0:
		add_test_result("出售价格计算", true, "价值0物品出售价格为0正确")
	else:
		add_test_result("出售价格计算", false, "价值0物品出售价格错误: 期望0, 实际%d" % sell_price_zero)

# 测试黑市价格机制
func test_blackmarket_price_mechanism():
	print("\n--- 测试黑市价格机制 ---")
	
	price_balancing_manager = PriceBalancingManager.new()
	
	# 测试黑市价格 - 境界等级2（筑基丹）
	var blackmarket_price_2 = price_balancing_manager.calculate_blackmarket_price(2)
	var expected_price_2 = int(5000 * 2)  # 10000
	if blackmarket_price_2 == expected_price_2:
		add_test_result("黑市价格机制", true, "境界等级2黑市价格正确: %d" % blackmarket_price_2)
	else:
		add_test_result("黑市价格机制", false, "境界等级2黑市价格错误: 期望%d, 实际%d" % [expected_price_2, blackmarket_price_2])
	
	# 测试黑市价格 - 境界等级1（炼气丹）
	var blackmarket_price_1 = price_balancing_manager.calculate_blackmarket_price(1)
	var expected_price_1 = int(5000 * 1)  # 5000
	if blackmarket_price_1 == expected_price_1:
		add_test_result("黑市价格机制", true, "境界等级1黑市价格正确: %d" % blackmarket_price_1)
	else:
		add_test_result("黑市价格机制", false, "境界等级1黑市价格错误: 期望%d, 实际%d" % [expected_price_1, blackmarket_price_1])
	
	# 测试边界情况：境界等级为0
	var blackmarket_price_0 = price_balancing_manager.calculate_blackmarket_price(0)
	if blackmarket_price_0 == 0:
		add_test_result("黑市价格机制", true, "境界等级0黑市价格为0正确")
	else:
		add_test_result("黑市价格机制", false, "境界等级0黑市价格错误: 期望0, 实际%d" % blackmarket_price_0)

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