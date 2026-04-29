extends GutTest

# 加载价格平衡管理器
var PriceBalancingManager = load("res://src/scripts/economy/price_balancing_manager.gd")

var price_balancing_manager

func before_each():
	# 初始化系统
	price_balancing_manager = PriceBalancingManager.new()

func after_each():
	# 清理
	if price_balancing_manager:
		price_balancing_manager.queue_free()

# 测试强化费用计算
func test_upgrade_cost_calculation():
	# 测试强化费用计算 - 基础测试
	var cost_level_1 = price_balancing_manager.calculate_upgrade_cost(1)
	var expected_cost_1 = int(200 * pow(1.5, 1))  # 200 * 1.5 = 300
	assert_eq(cost_level_1, expected_cost_1, "强化+1费用应该等于300")
	
	# 测试强化费用计算 - 更高等级
	var cost_level_6 = price_balancing_manager.calculate_upgrade_cost(6, 50)  # 基础费用50
	var expected_cost_6 = int(50 * pow(1.5, 6))  # 50 * 11.390625 ≈ 569
	assert_true(abs(cost_level_6 - expected_cost_6) <= 1, "强化+6费用应该约等于569")
	
	# 测试边界情况：等级为0
	var cost_level_0 = price_balancing_manager.calculate_upgrade_cost(0)
	assert_eq(cost_level_0, 0, "强化0级费用应该为0")

# 测试掉落修正机制
func test_drop_correction_mechanism():
	# 测试掉落修正 - 福缘为0
	var corrected_drop_0 = price_balancing_manager.calculate_drop_amount(100, 0)
	var expected_drop_0 = int(100 * (1.0 + 0.0/100.0))  # 100 * 1 = 100
	assert_eq(corrected_drop_0, expected_drop_0, "福缘0掉落修正应该等于100")
	
	# 测试掉落修正 - 福缘为30
	var corrected_drop_30 = price_balancing_manager.calculate_drop_amount(100, 30)
	var expected_drop_30 = int(100 * (1.0 + 30.0/100.0))  # 100 * 1.3 = 130
	assert_eq(corrected_drop_30, expected_drop_30, "福缘30掉落修正应该等于130")
	
	# 测试掉落修正 - 福缘为100
	var corrected_drop_100 = price_balancing_manager.calculate_drop_amount(100, 100)
	var expected_drop_100 = int(100 * (1.0 + 100.0/100.0))  # 100 * 2 = 200
	assert_eq(corrected_drop_100, expected_drop_100, "福缘100掉落修正应该等于200")
	
	# 测试边界情况：基础掉落为0
	var corrected_drop_zero = price_balancing_manager.calculate_drop_amount(0, 50)
	assert_eq(corrected_drop_zero, 0, "基础掉落为0时修正应该为0")

# 测试出售价格计算
func test_sell_price_calculation():
	# 测试出售价格计算 - 基础测试
	var sell_price_1000 = price_balancing_manager.calculate_sell_price(1000)
	var expected_sell_price_1000 = int(1000 * 0.5)  # 500
	assert_eq(sell_price_1000, expected_sell_price_1000, "价值1000物品出售价格应该为500")
	
	# 测试出售价格计算 - 其他值
	var sell_price_750 = price_balancing_manager.calculate_sell_price(750)
	var expected_sell_price_750 = int(750 * 0.5)  # 375
	assert_eq(sell_price_750, expected_sell_price_750, "价值750物品出售价格应该为375")
	
	# 测试边界情况：基础价值为0
	var sell_price_zero = price_balancing_manager.calculate_sell_price(0)
	assert_eq(sell_price_zero, 0, "价值0物品出售价格应该为0")

# 测试黑市价格机制
func test_blackmarket_price_mechanism():
	# 测试黑市价格 - 境界等级2（筑基丹）
	var blackmarket_price_2 = price_balancing_manager.calculate_blackmarket_price(2)
	var expected_price_2 = int(5000 * 2)  # 10000
	assert_eq(blackmarket_price_2, expected_price_2, "境界等级2黑市价格应该为10000")
	
	# 测试黑市价格 - 境界等级1（炼气丹）
	var blackmarket_price_1 = price_balancing_manager.calculate_blackmarket_price(1)
	var expected_price_1 = int(5000 * 1)  # 5000
	assert_eq(blackmarket_price_1, expected_price_1, "境界等级1黑市价格应该为5000")
	
	# 测试边界情况：境界等级为0
	var blackmarket_price_0 = price_balancing_manager.calculate_blackmarket_price(0)
	assert_eq(blackmarket_price_0, 0, "境界等级0黑市价格应该为0")