extends SceneTree

## 独立测试运行器 - 不依赖GUT框架
## 用于验证RandomEventTrigger的功能

var RandomEventTrigger = preload("res://scripts/random_event/random_event_trigger.gd")
var test_count = 0
var passed_count = 0
var failed_count = 0

func _init():
	print("============================================================")
	print("开始测试 RandomEventTrigger")
	print("============================================================")
	
	# 运行所有测试
	test_distance_tracking()
	test_time_tracking()
	test_safe_zone_detection()
	test_warning_mechanism()
	test_trigger_probability()
	test_helper_functions()
	
	# 输出测试结果
	print("\n============================================================")
	print("测试完成")
	print("总计: %d 个测试" % test_count)
	print("通过: %d 个测试 (%.1f%%)" % [passed_count, (passed_count * 100.0 / test_count) if test_count > 0 else 0])
	print("失败: %d 个测试" % failed_count)
	print("============================================================")
	
	# 退出
	quit(0 if failed_count == 0 else 1)

func assert_true(condition: bool, message: String):
	test_count += 1
	if condition:
		passed_count += 1
		print("  ✓ PASS: %s" % message)
	else:
		failed_count += 1
		print("  ✗ FAIL: %s" % message)

func assert_false(condition: bool, message: String):
	assert_true(not condition, message)

func assert_eq(actual, expected, message: String):
	test_count += 1
	if actual == expected:
		passed_count += 1
		print("  ✓ PASS: %s" % message)
	else:
		failed_count += 1
		print("  ✗ FAIL: %s (expected: %s, got: %s)" % [message, str(expected), str(actual)])

func assert_almost_eq(actual: float, expected: float, tolerance: float, message: String):
	test_count += 1
	if abs(actual - expected) <= tolerance:
		passed_count += 1
		print("  ✓ PASS: %s" % message)
	else:
		failed_count += 1
		print("  ✗ FAIL: %s (expected: ~%s±%s, got: %s)" % [message, str(expected), str(tolerance), str(actual)])

# ============================================================================
# AC-1: 距离跟踪测试
# ============================================================================

func test_distance_tracking():
	print("\n[AC-1] 测试基于移动距离的触发机制")
	
	var trigger = RandomEventTrigger.new()
	
	# 测试1: 距离累计
	trigger.set_current_region("wilderness")
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(50, 0))
	var stats = trigger.get_tracking_stats()
	assert_eq(stats.distance_since_check, 50.0, "距离应该累计为50")
	
	# 测试2: 距离阈值触发
	var signal_emitted = false
	trigger.distance_threshold_reached.connect(func(_distance):
		signal_emitted = true
	)
	trigger.update_player_position(Vector2(150, 0))
	assert_true(signal_emitted, "距离达到100应该触发信号")
	
	# 测试3: 距离重置
	stats = trigger.get_tracking_stats()
	assert_eq(stats.distance_since_check, 0.0, "距离计数器应该重置")
	
	# 测试4: 边界值测试
	trigger.reset_distance_tracking()
	var threshold_reached = false
	trigger.distance_threshold_reached.connect(func(_distance):
		threshold_reached = true
	)
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(99.9, 0))
	assert_false(threshold_reached, "99.9格子不应该触发")
	
	# 测试5: 多次移动累计
	trigger.reset_distance_tracking()
	var trigger_count = 0
	trigger.distance_threshold_reached.connect(func(_distance):
		trigger_count += 1
	)
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(30, 0))
	trigger.update_player_position(Vector2(60, 0))
	trigger.update_player_position(Vector2(90, 0))
	trigger.update_player_position(Vector2(120, 0))
	assert_eq(trigger_count, 1, "应该触发一次距离检查")
	
	trigger.free()

# ============================================================================
# AC-2: 时间跟踪测试
# ============================================================================

func test_time_tracking():
	print("\n[AC-2] 测试基于时间的触发机制")
	
	var trigger = RandomEventTrigger.new()
	
	# 测试1: 时间累计
	trigger.set_current_region("wilderness")
	trigger._process(60.0)
	var stats = trigger.get_tracking_stats()
	assert_eq(stats.time_since_check, 60.0, "时间应该累计为60秒")
	
	# 测试2: 时间阈值触发
	var signal_emitted = false
	trigger.time_threshold_reached.connect(func(_time):
		signal_emitted = true
	)
	trigger._process(240.0)  # 总共300秒
	assert_true(signal_emitted, "时间达到300秒应该触发信号")
	
	# 测试3: 时间重置
	stats = trigger.get_tracking_stats()
	assert_eq(stats.time_since_check, 0.0, "时间计数器应该重置")
	
	# 测试4: 暂停/恢复
	trigger._process(100.0)
	trigger.pause_time_tracking()
	trigger._process(100.0)
	stats = trigger.get_tracking_stats()
	assert_eq(stats.time_since_check, 100.0, "暂停期间时间不应增加")
	
	trigger.resume_time_tracking()
	trigger._process(50.0)
	stats = trigger.get_tracking_stats()
	assert_eq(stats.time_since_check, 150.0, "恢复后时间应该继续累计")
	
	# 测试5: 边界值测试
	trigger.reset_time_tracking()
	var threshold_reached = false
	trigger.time_threshold_reached.connect(func(_time):
		threshold_reached = true
	)
	trigger._process(300.0)
	assert_true(threshold_reached, "恰好300秒应该触发")
	
	trigger.free()

# ============================================================================
# AC-3: 安全区检测测试
# ============================================================================

func test_safe_zone_detection():
	print("\n[AC-3] 测试安全区检测")
	
	var trigger = RandomEventTrigger.new()
	
	# 测试1: 非安全区
	trigger.set_current_region("wilderness")
	assert_false(trigger.is_in_safe_zone(), "野外不是安全区")
	
	# 测试2: 进入安全区
	var entered = false
	var entered_type = null
	trigger.safe_zone_entered.connect(func(zone_type):
		entered = true
		entered_type = zone_type
	)
	trigger.set_current_region("village")
	assert_true(entered, "应该发出进入安全区信号")
	assert_true(trigger.is_in_safe_zone(), "城镇是安全区")
	assert_eq(entered_type, RandomEventTrigger.SafeZoneType.TOWN, "应该是城镇类型")
	
	# 测试3: 安全区阻止距离触发
	var trigger_requested = false
	trigger.trigger_check_requested.connect(func(_type):
		trigger_requested = true
	)
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(150, 0))
	assert_false(trigger_requested, "安全区内不应触发距离检查")
	
	# 测试4: 安全区阻止时间触发
	trigger.set_current_region("inn_01")
	trigger_requested = false
	trigger._process(350.0)
	assert_false(trigger_requested, "安全区内不应触发时间检查")
	
	# 测试5: 离开安全区
	var exited = false
	var exited_type = null
	trigger.safe_zone_exited.connect(func(zone_type):
		exited = true
		exited_type = zone_type
	)
	trigger.set_current_region("wilderness")
	assert_true(exited, "应该发出离开安全区信号")
	assert_eq(exited_type, RandomEventTrigger.SafeZoneType.INN, "应该是驿站类型")
	
	# 测试6: 动态添加安全区
	trigger.set_current_region("custom_area")
	assert_false(trigger.is_in_safe_zone(), "自定义区域初始不是安全区")
	trigger.add_safe_zone("custom_area", RandomEventTrigger.SafeZoneType.SAFE_HOUSE)
	trigger.set_current_region("custom_area")
	assert_true(trigger.is_in_safe_zone(), "添加后应该是安全区")
	
	trigger.free()

# ============================================================================
# AC-4: 预警机制测试
# ============================================================================

func test_warning_mechanism():
	print("\n[AC-4] 测试预警机制")
	
	var trigger = RandomEventTrigger.new()
	
	# 测试1: 预警激活
	trigger.set_current_region("wilderness")
	trigger._start_warning("test")
	assert_true(trigger.is_warning_active, "预警应该激活")
	
	# 测试2: 预警时间
	var stats = trigger.get_tracking_stats()
	assert_true(stats.is_warning_active, "统计信息应该显示预警激活")
	
	# 测试3: 安全区取消预警
	trigger._start_warning("distance")
	assert_true(trigger.is_warning_active, "预警应该激活")
	trigger.set_current_region("village")
	assert_false(trigger.is_warning_active, "进入安全区后预警应该被取消")
	
	# 测试4: 防止重复预警
	trigger.set_current_region("wilderness")
	var warning_count = 0
	trigger.event_trigger_warning.connect(func(_time):
		warning_count += 1
	)
	trigger._start_warning("distance")
	trigger._perform_trigger_check("time")
	assert_eq(warning_count, 1, "预警期间不应重复触发")
	
	trigger.free()

# ============================================================================
# 触发概率公式测试
# ============================================================================

func test_trigger_probability():
	print("\n[触发概率公式] 测试概率计算")
	
	var trigger = RandomEventTrigger.new()
	
	# 测试1: 基础概率
	trigger.set_player_luck(0)
	trigger.set_consecutive_combat_count(0)
	var probability = trigger.calculate_trigger_probability()
	assert_eq(probability, 0.3, "基础概率应该是30%")
	
	# 测试2: 福缘加成
	trigger.set_player_luck(10)
	trigger.set_consecutive_combat_count(0)
	probability = trigger.calculate_trigger_probability()
	assert_eq(probability, 0.4, "福缘10应该增加10%概率")
	
	# 测试3: 战斗惩罚
	trigger.set_player_luck(0)
	trigger.set_consecutive_combat_count(2)
	probability = trigger.calculate_trigger_probability()
	assert_eq(probability, 0.2, "连续战斗2次应该减少10%概率")
	
	# 测试4: 组合计算
	trigger.set_player_luck(20)
	trigger.set_consecutive_combat_count(3)
	probability = trigger.calculate_trigger_probability()
	assert_eq(probability, 0.35, "组合计算应该正确")
	
	# 测试5: 下限限制
	trigger.set_player_luck(0)
	trigger.set_consecutive_combat_count(10)
	probability = trigger.calculate_trigger_probability()
	assert_eq(probability, 0.0, "概率不应低于0")
	
	# 测试6: 上限限制
	trigger.set_player_luck(100)
	trigger.set_consecutive_combat_count(0)
	probability = trigger.calculate_trigger_probability()
	assert_eq(probability, 1.0, "概率不应高于1")
	
	trigger.free()

# ============================================================================
# 辅助功能测试
# ============================================================================

func test_helper_functions():
	print("\n[辅助功能] 测试辅助函数")
	
	var trigger = RandomEventTrigger.new()
	
	# 测试1: 重置距离跟踪
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(50, 0))
	trigger.reset_distance_tracking()
	var stats = trigger.get_tracking_stats()
	assert_eq(stats.total_distance, 0.0, "总距离应该清零")
	assert_eq(stats.distance_since_check, 0.0, "检查距离应该清零")
	
	# 测试2: 重置时间跟踪
	trigger._process(100.0)
	trigger.reset_time_tracking()
	stats = trigger.get_tracking_stats()
	assert_eq(stats.total_time, 0.0, "总时间应该清零")
	assert_eq(stats.time_since_check, 0.0, "检查时间应该清零")
	
	# 测试3: 战斗计数增加
	trigger.set_consecutive_combat_count(0)
	trigger.increment_combat_count()
	trigger.increment_combat_count()
	stats = trigger.get_tracking_stats()
	assert_eq(stats.consecutive_combat, 2, "战斗次数应该是2")
	
	# 测试4: 战斗计数重置
	trigger.set_consecutive_combat_count(5)
	trigger.reset_combat_count()
	stats = trigger.get_tracking_stats()
	assert_eq(stats.consecutive_combat, 0, "战斗次数应该清零")
	
	# 测试5: 获取统计信息
	trigger.set_player_luck(15)
	trigger.set_consecutive_combat_count(3)
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(25, 0))
	trigger._process(60.0)
	stats = trigger.get_tracking_stats()
	assert_true(stats.has("total_distance"), "应该包含总距离")
	assert_true(stats.has("player_luck"), "应该包含玩家福缘")
	assert_true(stats.has("trigger_probability"), "应该包含触发概率")
	assert_eq(stats.player_luck, 15, "福缘应该是15")
	assert_eq(stats.consecutive_combat, 3, "战斗次数应该是3")
	
	trigger.free()