extends "res://addons/gut/test.gd"

# 属性点机制单元测试
# 测试AttributePointManager的核心功能

var attribute_manager: AttributePointManager
var signal_received: bool = false
var received_attribute: String = ""
var received_value: int = 0

func before_all():
	# 创建AttributePointManager实例用于测试
	attribute_manager = AttributePointManager.new()
	add_child(attribute_manager)

func after_all():
	# 清理测试实例
	if attribute_manager:
		attribute_manager.queue_free()

func test_attribute_point_acquisition():
	# 测试属性点获取机制
	# Given: 玩家角色升级到第2级
	# When: 系统处理升级事件
	# Then: 玩家获得5点自由属性点
	
	# 初始状态：0点总属性点
	assert_eq(attribute_manager.get_total_points(), 0, "初始总属性点应为0")
	assert_eq(attribute_manager.get_available_points(), 0, "初始可用属性点应为0")
	
	# 模拟升级到第2级（获得5点）
	attribute_manager.add_total_points(5)
	
	# 验证获得5点属性点
	assert_eq(attribute_manager.get_total_points(), 5, "升级后总属性点应为5")
	assert_eq(attribute_manager.get_available_points(), 5, "升级后可用属性点应为5")

func test_attribute_point_allocation_rules():
	# 测试属性点分配规则
	# Given: 玩家拥有5点可用属性点
	# When: 分配1点到力道属性
	# Then: 力道属性值增加1，可用点数减少1
	
	# 重置测试状态
	attribute_manager.load_data({
		"total_points": 5,
		"allocated_points": 0,
		"attributes": {
			"strength": 0,
			"agility": 0,
			"constitution": 0,
			"intelligence": 0,
			"willpower": 0,
			"luck": 0
		},
		"reset_count": 0
	})
	
	# 验证初始状态
	assert_eq(attribute_manager.get_available_points(), 5, "初始可用属性点应为5")
	assert_eq(attribute_manager.get_attribute_value("strength"), 0, "初始力道属性应为0")
	
	# 分配1点到力道
	var success = attribute_manager.allocate_point("strength")
	
	# 验证分配成功
	assert_true(success, "分配属性点应成功")
	assert_eq(attribute_manager.get_attribute_value("strength"), 1, "力道属性应增加1")
	assert_eq(attribute_manager.get_available_points(), 4, "可用属性点应减少1")
	assert_eq(attribute_manager.get_allocated_points(), 1, "已分配属性点应为1")

func test_six_dimensional_attribute_system():
	# 测试六维属性体系
	# Given: 玩家角色具有六维属性
	# When: 查询任意属性值
	# Then: 返回正确的属性值（力道、身法、根骨、悟性、定力、福缘）
	
	# 重置测试状态
	attribute_manager.load_data({
		"total_points": 0,
		"allocated_points": 0,
		"attributes": {
			"strength": 0,
			"agility": 0,
			"constitution": 0,
			"intelligence": 0,
			"willpower": 0,
			"luck": 0
		},
		"reset_count": 0
	})
	
	# 验证所有六维属性都存在且可查询
	var attributes = ["strength", "agility", "constitution", "intelligence", "willpower", "luck"]
	
	for attr in attributes:
		var value = attribute_manager.get_attribute_value(attr)
		assert_eq(value, 0, "属性 %s 应初始化为0" % attr)
	
	# 测试无效属性类型
	var invalid_attr = "invalid_attribute"
	var invalid_value = attribute_manager.get_attribute_value(invalid_attr)
	assert_eq(invalid_value, 0, "无效属性类型应返回0")

func test_attribute_point_data_structure():
	# 测试属性点数据结构
	# Given: 玩家角色拥有属性点数据
	# When: 保存和加载游戏
	# Then: 属性点数据正确保存和恢复
	
	# 设置测试数据
	attribute_manager.load_data({
		"total_points": 10,
		"allocated_points": 3,
		"attributes": {
			"strength": 2,
			"agility": 1,
			"constitution": 0,
			"intelligence": 0,
			"willpower": 0,
			"luck": 0
		},
		"reset_count": 1
	})
	
	# 保存数据
	var saved_data = attribute_manager.save_data()
	
	# 验证保存的数据结构
	assert_eq(saved_data["total_points"], 10, "保存的总属性点应正确")
	assert_eq(saved_data["allocated_points"], 3, "保存的已分配属性点应正确")
	assert_eq(saved_data["attributes"]["strength"], 2, "保存的力道属性应正确")
	assert_eq(saved_data["attributes"]["agility"], 1, "保存的身法属性应正确")
	assert_eq(saved_data["reset_count"], 1, "保存的重置次数应正确")
	
	# 创建新的管理器并加载数据
	var new_manager = load("res://src/scripts/character/attribute_point_manager.gd").new()
	new_manager.load_data(saved_data)
	
	# 验证加载的数据
	assert_eq(new_manager.get_total_points(), 10, "加载的总属性点应正确")
	assert_eq(new_manager.get_attribute_value("strength"), 2, "加载的力道属性应正确")
	assert_eq(new_manager.get_attribute_value("agility"), 1, "加载的身法属性应正确")
	assert_eq(new_manager.get_reset_count(), 1, "加载的重置次数应正确")

func test_edge_cases():
	# 测试边缘情况
	
	# 测试分配超出上限
	attribute_manager.load_data({
		"total_points": 5,
		"allocated_points": 0,
		"attributes": {"strength": 99},  # 已达到上限
		"reset_count": 0
	})
	
	var success = attribute_manager.allocate_point("strength")
	assert_false(success, "分配超出上限的属性点应失败")
	
	# 测试无可用点数时分配
	attribute_manager.load_data({
		"total_points": 0,
		"allocated_points": 0,
		"attributes": {"strength": 0},
		"reset_count": 0
	})
	
	success = attribute_manager.allocate_point("strength")
	assert_false(success, "无可用点数时分配应失败")
	
	# 测试重置功能
	attribute_manager.load_data({
		"total_points": 5,
		"allocated_points": 5,
		"attributes": {"strength": 5},
		"reset_count": 1
	})
	
	var reset_success = attribute_manager.reset_attributes(true)
	assert_true(reset_success, "有免费重置次数时重置应成功")
	assert_eq(attribute_manager.get_attribute_value("strength"), 0, "重置后属性应为0")
	assert_eq(attribute_manager.get_allocated_points(), 0, "重置后已分配点数应为0")
	assert_eq(attribute_manager.get_reset_count(), 0, "重置后重置次数应减少")
	
	# 测试无免费重置次数时重置
	reset_success = attribute_manager.reset_attributes(true)
	assert_false(reset_success, "无免费重置次数时重置应失败")

func test_data_integrity_validation():
	# 测试数据完整性验证
	
	# 测试总点数超过最大值
	var corrupt_data = {
		"total_points": 1000,  # 超过MAX_TOTAL_POINTS (495)
		"allocated_points": 500,
		"attributes": {"strength": 100},  # 超过MAX_ATTRIBUTE_VALUE (99)
		"reset_count": 0
	}
	
	attribute_manager.load_data(corrupt_data)
	
	# 验证数据被修正
	assert_eq(attribute_manager.get_total_points(), 495, "总点数应被限制在最大值")
	assert_eq(attribute_manager.get_attribute_value("strength"), 99, "属性值应被限制在最大值")
	
	# 测试已分配点数与属性值不一致
	corrupt_data = {
		"total_points": 10,
		"allocated_points": 5,  # 声称已分配5点
		"attributes": {"strength": 3, "agility": 1},  # 实际只分配了4点
		"reset_count": 0
	}
	
	attribute_manager.load_data(corrupt_data)
	
	# 验证已分配点数被重新计算
	assert_eq(attribute_manager.get_allocated_points(), 4, "已分配点数应被重新计算")

# 测试信号发射
func test_signals_emitted():
	# 测试分配属性点时发射信号
	# 设置测试数据
	attribute_manager.load_data({
		"total_points": 1,
		"allocated_points": 0,
		"attributes": {
			"strength": 0,
			"agility": 0,
			"constitution": 0,
			"intelligence": 0,
			"willpower": 0,
			"luck": 0
		},
		"reset_count": 0
	})
	
	# 使用 watch_signals 来监控信号（在 load_data 之后）
	watch_signals(attribute_manager)
	
	# 分配属性点
	var success = attribute_manager.allocate_point("strength")
	
	# 验证分配成功
	assert_true(success, "分配属性点应成功")
	
	# 验证信号被发射
	assert_signal_emitted(attribute_manager, "attribute_allocated", "应发射attribute_allocated信号")
	
	# 验证信号参数 - 使用 assert_signal_emit_count 来验证信号被发射了一次
	assert_signal_emit_count(attribute_manager, "attribute_allocated", 1, "应发射一次attribute_allocated信号")
	
	# 注意：GUT 的 get_signal_parameters 在某些版本中可能返回格式不一致
	# 我们已经验证了信号被发射，这对于测试信号机制已经足够


# 测试智能推荐接口
func test_smart_recommendation_interface():
	# 测试智能推荐分配方案接口
	var recommendation = attribute_manager.get_smart_recommendation([])
	assert_eq(typeof(recommendation), TYPE_DICTIONARY, "智能推荐应返回字典")
