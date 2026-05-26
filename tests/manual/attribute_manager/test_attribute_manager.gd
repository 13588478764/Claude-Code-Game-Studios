extends Node

## AttributePointManager 单元测试场景
## 独立测试场景，不依赖主游戏场景

func _ready():
	print("\n" + "=".repeat(60))
	print("AttributePointManager 单元测试")
	print("=".repeat(60) + "\n")
	
	run_all_tests()
	
	print("\n" + "=".repeat(60))
	print("测试完成 - 按 ESC 退出")
	print("=".repeat(60) + "\n")

func run_all_tests():
	var manager = AttributePointManager.new()
	add_child(manager)
	
	var total_tests = 0
	var passed_tests = 0
	
	# 测试 1: 属性点获取机制
	print("【测试 1】属性点获取机制")
	total_tests += 1
	if test_attribute_point_acquisition(manager):
		passed_tests += 1
		print("  ✓ 通过\n")
	else:
		print("  ✗ 失败\n")
	
	# 测试 2: 属性点分配规则
	print("【测试 2】属性点分配规则")
	total_tests += 1
	if test_attribute_point_allocation(manager):
		passed_tests += 1
		print("  ✓ 通过\n")
	else:
		print("  ✗ 失败\n")
	
	# 测试 3: 六维属性体系
	print("【测试 3】六维属性体系")
	total_tests += 1
	if test_six_dimensional_attributes(manager):
		passed_tests += 1
		print("  ✓ 通过\n")
	else:
		print("  ✗ 失败\n")
	
	# 测试 4: 数据保存和加载
	print("【测试 4】数据保存和加载")
	total_tests += 1
	if test_data_persistence(manager):
		passed_tests += 1
		print("  ✓ 通过\n")
	else:
		print("  ✗ 失败\n")
	
	# 测试 5: 边缘情况处理
	print("【测试 5】边缘情况处理")
	total_tests += 1
	if test_edge_cases(manager):
		passed_tests += 1
		print("  ✓ 通过\n")
	else:
		print("  ✗ 失败\n")
	
	# 测试 6: 数据完整性验证
	print("【测试 6】数据完整性验证")
	total_tests += 1
	if test_data_integrity(manager):
		passed_tests += 1
		print("  ✓ 通过\n")
	else:
		print("  ✗ 失败\n")
	
	# 测试 7: 信号发射
	print("【测试 7】信号发射")
	total_tests += 1
	if await test_signals(manager):
		passed_tests += 1
		print("  ✓ 通过\n")
	else:
		print("  ✗ 失败\n")
	
	# 测试 8: 智能推荐接口
	print("【测试 8】智能推荐接口")
	total_tests += 1
	if test_smart_recommendation(manager):
		passed_tests += 1
		print("  ✓ 通过\n")
	else:
		print("  ✗ 失败\n")
	
	# 测试总结
	print("\n" + "-".repeat(60))
	print("测试总结: %d/%d 通过" % [passed_tests, total_tests])
	if passed_tests == total_tests:
		print("状态: ✓ 所有测试通过")
	else:
		print("状态: ✗ 有 %d 个测试失败" % (total_tests - passed_tests))
	print("-".repeat(60))

func test_attribute_point_acquisition(manager: AttributePointManager) -> bool:
	# 重置管理器
	manager.load_data({
		"total_points": 0,
		"allocated_points": 0,
		"attributes": {"strength": 0, "agility": 0, "constitution": 0, "intelligence": 0, "willpower": 0, "luck": 0},
		"reset_count": 0
	})
	
	# 测试初始状态
	if manager.get_total_points() != 0:
		print("  错误: 初始总属性点应为 0，实际为 %d" % manager.get_total_points())
		return false
	
	if manager.get_available_points() != 0:
		print("  错误: 初始可用属性点应为 0，实际为 %d" % manager.get_available_points())
		return false
	
	# 添加属性点
	manager.add_total_points(10)
	
	if manager.get_total_points() != 10:
		print("  错误: 添加后总属性点应为 10，实际为 %d" % manager.get_total_points())
		return false
	
	if manager.get_available_points() != 10:
		print("  错误: 添加后可用属性点应为 10，实际为 %d" % manager.get_available_points())
		return false
	
	print("  - 初始状态正确")
	print("  - 属性点获取正确")
	return true

func test_attribute_point_allocation(manager: AttributePointManager) -> bool:
	# 重置管理器
	manager.load_data({
		"total_points": 5,
		"allocated_points": 0,
		"attributes": {"strength": 0, "agility": 0, "constitution": 0, "intelligence": 0, "willpower": 0, "luck": 0},
		"reset_count": 0
	})
	
	# 测试分配
	var success = manager.allocate_point("strength")
	
	if not success:
		print("  错误: 分配应该成功")
		return false
	
	if manager.get_attribute_value("strength") != 1:
		print("  错误: 力道应为 1，实际为 %d" % manager.get_attribute_value("strength"))
		return false
	
	if manager.get_available_points() != 4:
		print("  错误: 可用点数应为 4，实际为 %d" % manager.get_available_points())
		return false
	
	if manager.get_allocated_points() != 1:
		print("  错误: 已分配点数应为 1，实际为 %d" % manager.get_allocated_points())
		return false
	
	print("  - 属性点分配成功")
	print("  - 可用点数正确减少")
	print("  - 已分配点数正确增加")
	return true

func test_six_dimensional_attributes(manager: AttributePointManager) -> bool:
	var attributes = ["strength", "agility", "constitution", "intelligence", "willpower", "luck"]
	var attribute_names = {
		"strength": "力道",
		"agility": "身法",
		"constitution": "根骨",
		"intelligence": "悟性",
		"willpower": "定力",
		"luck": "福缘"
	}
	
	for attr in attributes:
		var value = manager.get_attribute_value(attr)
		print("  - %s (%s): %d" % [attribute_names[attr], attr, value])
	
	# 测试无效属性
	var invalid_value = manager.get_attribute_value("invalid_attribute")
	if invalid_value != 0:
		print("  错误: 无效属性应返回 0，实际为 %d" % invalid_value)
		return false
	
	print("  - 所有六维属性可查询")
	print("  - 无效属性正确处理")
	return true

func test_data_persistence(manager: AttributePointManager) -> bool:
	# 设置测试数据
	manager.load_data({
		"total_points": 10,
		"allocated_points": 3,
		"attributes": {"strength": 2, "agility": 1, "constitution": 0, "intelligence": 0, "willpower": 0, "luck": 0},
		"reset_count": 1
	})
	
	# 保存数据
	var saved_data = manager.save_data()
	
	# 验证保存的数据
	if saved_data["total_points"] != 10:
		print("  错误: 保存的总点数应为 10")
		return false
	
	if saved_data["allocated_points"] != 3:
		print("  错误: 保存的已分配点数应为 3")
		return false
	
	if saved_data["attributes"]["strength"] != 2:
		print("  错误: 保存的力道应为 2")
		return false
	
	if saved_data["reset_count"] != 1:
		print("  错误: 保存的重置次数应为 1")
		return false
	
	# 创建新管理器并加载
	var new_manager = AttributePointManager.new()
	new_manager.load_data(saved_data)
	
	if new_manager.get_total_points() != 10:
		print("  错误: 加载的总点数应为 10")
		return false
	
	if new_manager.get_attribute_value("strength") != 2:
		print("  错误: 加载的力道应为 2")
		return false
	
	print("  - 数据保存正确")
	print("  - 数据加载正确")
	return true

func test_edge_cases(manager: AttributePointManager) -> bool:
	# 测试分配超出上限
	manager.load_data({
		"total_points": 5,
		"allocated_points": 0,
		"attributes": {"strength": 99, "agility": 0, "constitution": 0, "intelligence": 0, "willpower": 0, "luck": 0},
		"reset_count": 0
	})
	
	var success = manager.allocate_point("strength")
	if success:
		print("  错误: 分配超出上限应失败")
		return false
	
	# 测试无可用点数时分配
	manager.load_data({
		"total_points": 0,
		"allocated_points": 0,
		"attributes": {"strength": 0, "agility": 0, "constitution": 0, "intelligence": 0, "willpower": 0, "luck": 0},
		"reset_count": 0
	})
	
	success = manager.allocate_point("strength")
	if success:
		print("  错误: 无可用点数时分配应失败")
		return false
	
	# 测试重置功能
	manager.load_data({
		"total_points": 5,
		"allocated_points": 5,
		"attributes": {"strength": 5, "agility": 0, "constitution": 0, "intelligence": 0, "willpower": 0, "luck": 0},
		"reset_count": 1
	})
	
	var reset_success = manager.reset_attributes(true)
	if not reset_success:
		print("  错误: 有免费重置次数时重置应成功")
		return false
	
	if manager.get_attribute_value("strength") != 0:
		print("  错误: 重置后力道应为 0")
		return false
	
	if manager.get_allocated_points() != 0:
		print("  错误: 重置后已分配点数应为 0")
		return false
	
	print("  - 超出上限正确拒绝")
	print("  - 无可用点数正确拒绝")
	print("  - 重置功能正常")
	return true

func test_data_integrity(manager: AttributePointManager) -> bool:
	# 测试总点数超过最大值
	manager.load_data({
		"total_points": 1000,
		"allocated_points": 0,
		"attributes": {"strength": 100, "agility": 0, "constitution": 0, "intelligence": 0, "willpower": 0, "luck": 0},
		"reset_count": 0
	})
	
	if manager.get_total_points() != 495:
		print("  错误: 总点数应被限制在 495")
		return false
	
	if manager.get_attribute_value("strength") != 99:
		print("  错误: 属性值应被限制在 99")
		return false
	
	# 测试已分配点数与属性值不一致
	manager.load_data({
		"total_points": 10,
		"allocated_points": 5,
		"attributes": {"strength": 3, "agility": 1, "constitution": 0, "intelligence": 0, "willpower": 0, "luck": 0},
		"reset_count": 0
	})
	
	if manager.get_allocated_points() != 4:
		print("  错误: 已分配点数应被重新计算为 4")
		return false
	
	print("  - 总点数上限正确")
	print("  - 属性值上限正确")
	print("  - 已分配点数重新计算正确")
	return true

var signal_received = false
var received_attribute = ""
var received_value = 0

func test_signals(manager: AttributePointManager) -> bool:
	# 重置信号状态
	signal_received = false
	received_attribute = ""
	received_value = 0
	
	# 连接信号
	manager.attribute_allocated.connect(_on_attribute_allocated)
	
	# 设置测试数据
	manager.load_data({
		"total_points": 1,
		"allocated_points": 0,
		"attributes": {"strength": 0, "agility": 0, "constitution": 0, "intelligence": 0, "willpower": 0, "luck": 0},
		"reset_count": 0
	})
	
	# 分配属性点
	manager.allocate_point("strength")
	
	# 等待信号处理
	await get_tree().process_frame
	
	# 验证信号
	if not signal_received:
		print("  错误: 应接收到 attribute_allocated 信号")
		manager.attribute_allocated.disconnect(_on_attribute_allocated)
		return false
	
	if received_attribute != "strength":
		print("  错误: 信号应包含正确的属性类型")
		manager.attribute_allocated.disconnect(_on_attribute_allocated)
		return false
	
	if received_value != 1:
		print("  错误: 信号应包含正确的属性值")
		manager.attribute_allocated.disconnect(_on_attribute_allocated)
		return false
	
	# 断开信号
	manager.attribute_allocated.disconnect(_on_attribute_allocated)
	
	print("  - 信号正确发射")
	print("  - 信号参数正确")
	return true

func _on_attribute_allocated(attribute_type: String, new_value: int):
	signal_received = true
	received_attribute = attribute_type
	received_value = new_value

func test_smart_recommendation(manager: AttributePointManager) -> bool:
	var recommendation = manager.get_smart_recommendation([])
	
	if typeof(recommendation) != TYPE_DICTIONARY:
		print("  错误: 智能推荐应返回字典")
		return false
	
	print("  - 智能推荐接口正常")
	print("  - 返回类型正确")
	return true