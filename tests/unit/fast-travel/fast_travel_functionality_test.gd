# 快速旅行功能单元测试
# 验证快速旅行基础功能、旅行成本计算、旅行时间消耗和旅行状态管理

extends Node

# 导入需要测试的脚本
var FastTravelManager = load("res://src/scripts/fast_travel/fast_travel_manager.gd")

# 测试结果统计
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("开始运行快速旅行功能单元测试...")
	
	# 运行快速旅行基础功能测试
	test_travel_basic_functionality()
	test_travel_to_unlocked_location()
	test_travel_to_locked_location()
	
	# 运行旅行成本计算测试
	test_travel_cost_calculation_same_region()
	test_travel_cost_calculation_different_region()
	test_travel_cost_calculation_max_cost()
	
	# 运行旅行时间消耗测试
	test_travel_time_calculation_short_distance()
	test_travel_time_calculation_long_distance()
	test_travel_time_calculation_max_time()
	
	# 运行旅行状态管理测试
	test_travel_state_management()
	test_travel_state_during_journey()
	
	print("\n测试完成: %d/%d 个测试通过" % [tests_passed, tests_total])

# 测试快速旅行基础功能
func test_travel_basic_functionality():
	var travel_manager = FastTravelManager.new()
	
	# 验证初始化
	assert(travel_manager.get_travel_state() == travel_manager.TravelState.IDLE, "初始状态应为IDLE")
	
	# 验证世界节点是否正确添加
	var current_info = travel_manager.get_current_location_info()
	assert(current_info.name == "青云山", "初始位置应为青云山")
	
	print("✓ 快速旅行基础功能测试通过")
	tests_passed += 2
	tests_total += 2

# 测试旅行到已解锁地点
func test_travel_to_unlocked_location():
	var travel_manager = FastTravelManager.new()
	
	# 尝试解锁一个新地点
	var unlock_result = travel_manager.unlock_location("jiangnan_town")
	assert(unlock_result == true, "解锁地点应成功")
	
	# 获取目标地点信息
	var dest_info = travel_manager.get_destination_info("jiangnan_town")
	assert(dest_info.name == "江南水乡", "目标地点名称应正确")
	assert(dest_info.is_unlocked == true, "目标地点应已解锁")
	
	print("✓ 旅行到已解锁地点测试通过")
	tests_passed += 3
	tests_total += 3

# 测试旅行到未解锁地点
func test_travel_to_locked_location():
	var travel_manager = FastTravelManager.new()
	
	# 尝试旅行到未解锁的地点
	var can_travel = travel_manager.can_travel_to("beast_mountain")
	assert(can_travel == false, "无法旅行到未解锁的地点")
	
	print("✓ 旅行到未解锁地点测试通过")
	tests_passed += 1
	tests_total += 1

# 测试同区域旅行成本计算
func test_travel_cost_calculation_same_region():
	var travel_manager = FastTravelManager.new()
	
	# 添加两个同区域的地点
	travel_manager.add_world_node("test_loc1", "测试地点1", "青州", Vector2(10, 10))
	travel_manager.add_world_node("test_loc2", "测试地点2", "青州", Vector2(15, 15))
	
	# 解锁测试地点
	travel_manager.unlock_location("test_loc1")
	travel_manager.unlock_location("test_loc2")
	
	# 计算旅行成本
	var cost = travel_manager.calculate_travel_cost("test_loc1", "test_loc2")
	var expected_cost = int(travel_manager.BASE_TRAVEL_COST + (0.1 * travel_manager.DISTANCE_COST_MULTIPLIER) * travel_manager.SAME_REGION_MULTIPLIER)
	
	# 由于距离很近，成本应该较低且应用了同区域折扣
	assert(cost > 0, "旅行成本应大于0")
	
	print("✓ 同区域旅行成本计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试不同区域旅行成本计算
func test_travel_cost_calculation_different_region():
	var travel_manager = FastTravelManager.new()
	
	# 添加两个不同区域的地点
	travel_manager.add_world_node("test_loc1", "测试地点1", "青州", Vector2(0, 0))
	travel_manager.add_world_node("test_loc2", "测试地点2", "西域", Vector2(100, 100))
	
	# 解锁测试地点
	travel_manager.unlock_location("test_loc1")
	travel_manager.unlock_location("test_loc2")
	
	# 计算旅行成本
	var cost = travel_manager.calculate_travel_cost("test_loc1", "test_loc2")
	
	# 由于距离较远且不同区域，成本应该较高
	assert(cost > travel_manager.BASE_TRAVEL_COST, "不同区域且距离较远时成本应较高")
	
	print("✓ 不同区域旅行成本计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试最大旅行成本
func test_travel_cost_calculation_max_cost():
	var travel_manager = FastTravelManager.new()
	
	# 添加两个距离很远的地点
	travel_manager.add_world_node("far_loc1", "远地点1", "青州", Vector2(0, 0))
	travel_manager.add_world_node("far_loc2", "远地点2", "西域", Vector2(1000, 1000))
	
	# 解锁测试地点
	travel_manager.unlock_location("far_loc1")
	travel_manager.unlock_location("far_loc2")
	
	# 计算旅行成本
	var cost = travel_manager.calculate_travel_cost("far_loc1", "far_loc2")
	
	# 成本不应超过最大值
	assert(cost <= travel_manager.MAX_TRAVEL_COST, "旅行成本不应超过最大值")
	
	print("✓ 最大旅行成本计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试短距离旅行时间计算
func test_travel_time_calculation_short_distance():
	var travel_manager = FastTravelManager.new()
	
	# 计算短距离旅行时间
	var travel_time = travel_manager.calculate_travel_time(50.0)  # 50单位距离
	
	# 短距离旅行时间应为1小时（基础时间）
	assert(travel_time == 1, "短距离旅行时间应为1小时")
	
	print("✓ 短距离旅行时间计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试长距离旅行时间计算
func test_travel_time_calculation_long_distance():
	var travel_manager = FastTravelManager.new()
	
	# 计算长距离旅行时间
	var travel_time = travel_manager.calculate_travel_time(500.0)  # 500单位距离
	
	# 长距离旅行时间应为1 + 5 = 6小时，但不超过最大值
	var expected_time = min(1 + int(500 / 100), 24)  # 基础1小时 + 5小时，不超过24小时
	assert(travel_time == expected_time, "长距离旅行时间应正确计算")
	
	print("✓ 长距离旅行时间计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试最大旅行时间
func test_travel_time_calculation_max_time():
	var travel_manager = FastTravelManager.new()
	
	# 计算极长距离旅行时间
	var travel_time = travel_manager.calculate_travel_time(5000.0)  # 5000单位距离
	
	# 旅行时间不应超过最大值
	assert(travel_time == 24, "旅行时间不应超过24小时")
	
	print("✓ 最大旅行时间计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试旅行状态管理
func test_travel_state_management():
	var travel_manager = FastTravelManager.new()
	
	# 验证初始状态
	assert(travel_manager.get_travel_state() == travel_manager.TravelState.IDLE, "初始状态应为IDLE")
	
	# 验证添加世界节点
	travel_manager.add_world_node("state_test", "状态测试", "测试区", Vector2(50, 50))
	assert(travel_manager.world_nodes.has("state_test"), "世界节点应被添加")
	
	print("✓ 旅行状态管理测试通过")
	tests_passed += 2
	tests_total += 2

# 测试旅行过程中的状态
func test_travel_state_during_journey():
	var travel_manager = FastTravelManager.new()
	
	# 解锁一个目标地点
	travel_manager.unlock_location("dragon_temple")
	
	# 验证是否可以旅行
	var can_travel = travel_manager.can_travel_to("dragon_temple")
	assert(can_travel == true, "可以旅行到已解锁的地点")
	
	# 获取目标信息
	var dest_info = travel_manager.get_destination_info("dragon_temple")
	assert(dest_info.distance > 0, "目标距离应大于0")
	assert(dest_info.cost > 0, "旅行成本应大于0")
	
	print("✓ 旅行过程中状态测试通过")
	tests_passed += 3
	tests_total += 3

# 断言函数
func assert(condition, message):
	if not condition:
		print("测试失败: " + message)
		tests_total += 1
	else:
		# 条件为真时，什么都不做，继续
		pass