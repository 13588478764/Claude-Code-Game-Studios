# 旅行成本机制单元测试
# 验证旅行费用计算、旅行时间计算、余额验证和货币回收功能

extends Node

# 导入需要测试的脚本
var TravelCostManager = load("res://src/scripts/fast_travel/travel_cost_manager.gd")

# 测试结果统计
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("开始运行旅行成本机制单元测试...")
	
	# 运行旅行费用计算测试
	test_travel_cost_calculation_same_region()
	test_travel_cost_calculation_different_region()
	test_travel_cost_calculation_max_cost()
	
	# 运行旅行时间计算测试
	test_travel_time_calculation_short_distance()
	test_travel_time_calculation_long_distance()
	test_travel_time_calculation_max_time()
	
	# 运行余额验证机制测试
	test_balance_verification_sufficient_funds()
	test_balance_verification_insufficient_funds()
	test_balance_verification_exact_amount()
	
	# 运行货币回收功能测试
	test_currency_recovery_after_payment()
	test_refund_functionality()
	
	print("\n测试完成: %d/%d 个测试通过" % [tests_passed, tests_total])

# 测试同区域旅行费用计算
func test_travel_cost_calculation_same_region():
	var cost_manager = TravelCostManager.new()
	
	# 添加两个同区域的地点
	cost_manager.add_world_node("test_loc1", "测试地点1", "青州", Vector2(0, 0))
	cost_manager.add_world_node("test_loc2", "测试地点2", "青州", Vector2(50, 50))
	
	# 计算旅行费用
	var cost = cost_manager.calculate_travel_cost("test_loc1", "test_loc2")
	
	# 由于距离较近且同区域，费用应该较低
	assert(cost > 0, "旅行费用应大于0")
	assert(cost <= cost_manager.BASE_TRAVEL_COST + (0.1 * cost_manager.DISTANCE_COST_MULTIPLIER) * cost_manager.SAME_REGION_MULTIPLIER, "同区域旅行费用应应用折扣")
	
	print("✓ 同区域旅行费用计算测试通过")
	tests_passed += 2
	tests_total += 2

# 测试不同区域旅行费用计算
func test_travel_cost_calculation_different_region():
	var cost_manager = TravelCostManager.new()
	
	# 添加两个不同区域的地点
	cost_manager.add_world_node("test_loc1", "测试地点1", "青州", Vector2(0, 0))
	cost_manager.add_world_node("test_loc2", "测试地点2", "西域", Vector2(200, 200))
	
	# 计算旅行费用
	var cost = cost_manager.calculate_travel_cost("test_loc1", "test_loc2")
	
	# 由于距离较远且不同区域，费用应该较高
	assert(cost > cost_manager.BASE_TRAVEL_COST, "不同区域且距离较远时费用应较高")
	
	print("✓ 不同区域旅行费用计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试最大旅行费用
func test_travel_cost_calculation_max_cost():
	var cost_manager = TravelCostManager.new()
	
	# 添加两个距离很远的地点
	cost_manager.add_world_node("far_loc1", "远地点1", "青州", Vector2(0, 0))
	cost_manager.add_world_node("far_loc2", "远地点2", "西域", Vector2(1000, 1000))
	
	# 计算旅行费用
	var cost = cost_manager.calculate_travel_cost("far_loc1", "far_loc2")
	
	# 费用不应超过最大值
	assert(cost <= cost_manager.MAX_TRAVEL_COST, "旅行费用不应超过最大值")
	
	print("✓ 最大旅行费用计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试短距离旅行时间计算
func test_travel_time_calculation_short_distance():
	var cost_manager = TravelCostManager.new()
	
	# 计算短距离旅行时间
	var travel_time = cost_manager.calculate_travel_time(50.0)  # 50单位距离
	
	# 短距离旅行时间应为1小时（基础时间）
	assert(travel_time == 1, "短距离旅行时间应为1小时")
	
	print("✓ 短距离旅行时间计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试长距离旅行时间计算
func test_travel_time_calculation_long_distance():
	var cost_manager = TravelCostManager.new()
	
	# 计算长距离旅行时间
	var travel_time = cost_manager.calculate_travel_time(500.0)  # 500单位距离
	
	# 长距离旅行时间应为1 + (5 * 6) = 31小时，但不超过最大值24小时
	var expected_time = min(1 + int(500 / 100) * 6, 24)  # 基础1小时 + 5*6小时，不超过24小时
	assert(travel_time == expected_time, "长距离旅行时间应正确计算")
	
	print("✓ 长距离旅行时间计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试最大旅行时间
func test_travel_time_calculation_max_time():
	var cost_manager = TravelCostManager.new()
	
	# 计算极长距离旅行时间
	var travel_time = cost_manager.calculate_travel_time(1000.0)  # 1000单位距离
	
	# 旅行时间不应超过最大值
	assert(travel_time == 24, "旅行时间不应超过24小时")
	
	print("✓ 最大旅行时间计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试余额充足验证
func test_balance_verification_sufficient_funds():
	var cost_manager = TravelCostManager.new()
	
	# 设置玩家有足够余额
	cost_manager.set_player_money(100)
	
	# 验证余额是否充足
	var has_funds = cost_manager.has_sufficient_funds(50)
	assert(has_funds == true, "余额充足时应返回true")
	
	print("✓ 余额充足验证测试通过")
	tests_passed += 1
	tests_total += 1

# 测试余额不足验证
func test_balance_verification_insufficient_funds():
	var cost_manager = TravelCostManager.new()
	
	# 设置玩家余额不足
	cost_manager.set_player_money(30)
	
	# 验证余额是否充足
	var has_funds = cost_manager.has_sufficient_funds(50)
	assert(has_funds == false, "余额不足时应返回false")
	
	print("✓ 余额不足验证测试通过")
	tests_passed += 1
	tests_total += 1

# 测试精确余额验证
func test_balance_verification_exact_amount():
	var cost_manager = TravelCostManager.new()
	
	# 设置玩家余额恰好等于所需费用
	cost_manager.set_player_money(50)
	
	# 验证余额是否充足
	var has_funds = cost_manager.has_sufficient_funds(50)
	assert(has_funds == true, "余额恰好相等时应返回true")
	
	print("✓ 精确余额验证测试通过")
	tests_passed += 1
	tests_total += 1

# 测试支付后的货币回收
func test_currency_recovery_after_payment():
	var cost_manager = TravelCostManager.new()
	
	# 设置初始状态
	cost_manager.set_player_money(100)
	var initial_system_income = cost_manager.get_total_travel_cost()
	
	# 处理支付
	var payment_success = cost_manager.process_payment(30)
	assert(payment_success == true, "支付应成功")
	
	# 检查玩家余额减少
	var player_money_after_payment = cost_manager.get_player_money()
	assert(player_money_after_payment == 70, "玩家余额应减少支付金额")
	
	# 检查系统总收入增加
	var system_income_after_payment = cost_manager.get_total_travel_cost()
	assert(system_income_after_payment == initial_system_income + 30, "系统总收入应增加支付金额")
	
	print("✓ 支付后货币回收测试通过")
	tests_passed += 3
	tests_total += 3

# 测试退款功能
func test_refund_functionality():
	var cost_manager = TravelCostManager.new()
	
	# 设置初始状态
	cost_manager.set_player_money(70)
	cost_manager.total_travel_cost = 30  # 直接设置系统总收入
	
	# 执行退款
	var refund_amount = 20
	var refund_success = cost_manager.refund_cost(refund_amount)
	assert(refund_success == true, "退款应成功")
	
	# 检查玩家余额增加
	var player_money_after_refund = cost_manager.get_player_money()
	assert(player_money_after_refund == 90, "玩家余额应增加退款金额")
	
	# 检查系统总收入减少
	var system_income_after_refund = cost_manager.get_total_travel_cost()
	assert(system_income_after_refund == 10, "系统总收入应减少退款金额")
	
	print("✓ 退款功能测试通过")
	tests_passed += 3
	tests_total += 3
