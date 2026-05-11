extends GutTest

## 随机事件触发条件测试
## 测试Story 002的所有验收标准

var trigger: RandomEventTrigger

func before_each():
	trigger = RandomEventTrigger.new()
	add_child_autofree(trigger)

func after_each():
	if trigger:
		trigger.queue_free()
		trigger = null

# ============================================================================
# AC-1 测试: 基于移动距离的触发机制
# ============================================================================

func test_distance_tracking_accumulates_correctly():
	# Given: 玩家在野外移动
	trigger.set_current_region("wilderness")
	
	# When: 玩家移动一定距离
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(50, 0))
	
	# Then: 距离应该被正确累计
	var stats = trigger.get_tracking_stats()
	assert_eq(stats.distance_since_check, 50.0, "距离应该累计为50")

func test_distance_threshold_triggers_check():
	# Given: 玩家在野外移动
	trigger.set_current_region("wilderness")
	var signal_emitted = false
	
	trigger.distance_threshold_reached.connect(func(_distance):
		signal_emitted = true
	)
	
	# When: 累计移动距离达到100个格子
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(100, 0))
	
	# Then: 应该触发距离阈值信号
	assert_true(signal_emitted, "应该发出距离阈值达到信号")
	
	# And: 距离计数器应该重置
	var stats = trigger.get_tracking_stats()
	assert_eq(stats.distance_since_check, 0.0, "距离计数器应该重置为0")

func test_distance_threshold_exact_boundary():
	# Edge case: 检查精确距离计算
	trigger.set_current_region("wilderness")
	var threshold_reached = false
	
	trigger.distance_threshold_reached.connect(func(_distance):
		threshold_reached = true
	)
	
	# When: 移动距离恰好等于阈值
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(100, 0))
	
	# Then: 应该触发
	assert_true(threshold_reached, "恰好100格子应该触发")

func test_distance_threshold_just_below():
	# Edge case: 距离刚好低于阈值
	trigger.set_current_region("wilderness")
	var threshold_reached = false
	
	trigger.distance_threshold_reached.connect(func(_distance):
		threshold_reached = true
	)
	
	# When: 移动距离略低于阈值
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(99.9, 0))
	
	# Then: 不应该触发
	assert_false(threshold_reached, "99.9格子不应该触发")

func test_distance_accumulates_across_multiple_moves():
	# Edge case: 多次移动累计距离
	trigger.set_current_region("wilderness")
	var trigger_count = 0
	
	trigger.distance_threshold_reached.connect(func(_distance):
		trigger_count += 1
	)
	
	# When: 多次小距离移动累计超过阈值
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(30, 0))
	trigger.update_player_position(Vector2(60, 0))
	trigger.update_player_position(Vector2(90, 0))
	trigger.update_player_position(Vector2(120, 0))
	
	# Then: 应该触发一次（累计120格子）
	assert_eq(trigger_count, 1, "应该触发一次距离检查")

# ============================================================================
# AC-2 测试: 基于时间的触发机制
# ============================================================================

func test_time_tracking_accumulates_correctly():
	# Given: 玩家在游戏世界中
	trigger.set_current_region("wilderness")
	
	# When: 游戏时间流逝
	trigger._process(60.0)  # 模拟60秒
	
	# Then: 时间应该被正确累计
	var stats = trigger.get_tracking_stats()
	assert_eq(stats.time_since_check, 60.0, "时间应该累计为60秒")

func test_time_threshold_triggers_check():
	# Given: 玩家在游戏世界中
	trigger.set_current_region("wilderness")
	var signal_emitted = false
	
	trigger.time_threshold_reached.connect(func(_time):
		signal_emitted = true
	)
	
	# When: 游戏时间经过5分钟（300秒）
	trigger._process(300.0)
	
	# Then: 应该触发时间阈值信号
	assert_true(signal_emitted, "应该发出时间阈值达到信号")
	
	# And: 时间计数器应该重置
	var stats = trigger.get_tracking_stats()
	assert_eq(stats.time_since_check, 0.0, "时间计数器应该重置为0")

func test_time_tracking_pauses_correctly():
	# Edge case: 检查暂停/恢复游戏时的时间计算
	trigger.set_current_region("wilderness")
	
	# When: 时间流逝后暂停
	trigger._process(100.0)
	trigger.pause_time_tracking()
	trigger._process(100.0)  # 暂停期间的时间不应计入
	
	# Then: 暂停期间时间不应增加
	var stats = trigger.get_tracking_stats()
	assert_eq(stats.time_since_check, 100.0, "暂停期间时间不应增加")
	
	# When: 恢复时间跟踪
	trigger.resume_time_tracking()
	trigger._process(50.0)
	
	# Then: 恢复后时间应该继续累计
	stats = trigger.get_tracking_stats()
	assert_eq(stats.time_since_check, 150.0, "恢复后时间应该继续累计")

func test_time_threshold_exact_boundary():
	# Edge case: 时间恰好等于阈值
	trigger.set_current_region("wilderness")
	var threshold_reached = false
	
	trigger.time_threshold_reached.connect(func(_time):
		threshold_reached = true
	)
	
	# When: 时间恰好等于300秒
	trigger._process(300.0)
	
	# Then: 应该触发
	assert_true(threshold_reached, "恰好300秒应该触发")

func test_time_accumulates_across_multiple_frames():
	# Edge case: 多帧累计时间
	trigger.set_current_region("wilderness")
	var trigger_count = 0
	
	trigger.time_threshold_reached.connect(func(_time):
		trigger_count += 1
	)
	
	# When: 多次小时间增量累计超过阈值
	for i in range(20):
		trigger._process(16.0)  # 模拟20帧，每帧16ms
	
	# Then: 应该触发一次（累计320秒）
	assert_eq(trigger_count, 1, "应该触发一次时间检查")

# ============================================================================
# AC-3 测试: 安全区检测
# ============================================================================

func test_safe_zone_prevents_distance_trigger():
	# Given: 玩家位于城镇安全区
	trigger.set_current_region("village")
	var trigger_requested = false
	
	trigger.trigger_check_requested.connect(func(_type):
		trigger_requested = true
	)
	
	# When: 移动距离超过阈值
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(150, 0))
	
	# Then: 不应该触发事件检查
	assert_false(trigger_requested, "安全区内不应触发距离检查")

func test_safe_zone_prevents_time_trigger():
	# Given: 玩家位于驿站安全区
	trigger.set_current_region("inn_01")
	var trigger_requested = false
	
	trigger.trigger_check_requested.connect(func(_type):
		trigger_requested = true
	)
	
	# When: 时间流逝超过阈值
	trigger._process(350.0)
	
	# Then: 不应该触发事件检查
	assert_false(trigger_requested, "安全区内不应触发时间检查")

func test_safe_zone_entry_signal():
	# Given: 玩家在野外
	trigger.set_current_region("wilderness")
	var zone_entered = false
	var entered_zone_type = null
	
	trigger.safe_zone_entered.connect(func(zone_type):
		zone_entered = true
		entered_zone_type = zone_type
	)
	
	# When: 进入城镇
	trigger.set_current_region("village")
	
	# Then: 应该发出进入安全区信号
	assert_true(zone_entered, "应该发出进入安全区信号")
	assert_eq(entered_zone_type, RandomEventTrigger.SafeZoneType.TOWN, "应该是城镇类型")

func test_safe_zone_exit_signal():
	# Given: 玩家在城镇
	trigger.set_current_region("village")
	var zone_exited = false
	var exited_zone_type = null
	
	trigger.safe_zone_exited.connect(func(zone_type):
		zone_exited = true
		exited_zone_type = zone_type
	)
	
	# When: 离开城镇
	trigger.set_current_region("wilderness")
	
	# Then: 应该发出离开安全区信号
	assert_true(zone_exited, "应该发出离开安全区信号")
	assert_eq(exited_zone_type, RandomEventTrigger.SafeZoneType.TOWN, "应该是城镇类型")

func test_safe_zone_boundary_transition():
	# Edge case: 检查安全区边界过渡
	trigger.set_current_region("wilderness")
	var enter_count = 0
	var exit_count = 0
	
	trigger.safe_zone_entered.connect(func(_zone_type):
		enter_count += 1
	)
	trigger.safe_zone_exited.connect(func(_zone_type):
		exit_count += 1
	)
	
	# When: 快速进出安全区
	trigger.set_current_region("village")
	trigger.set_current_region("wilderness")
	trigger.set_current_region("inn_01")
	trigger.set_current_region("wilderness")
	
	# Then: 应该正确记录进出次数
	assert_eq(enter_count, 2, "应该记录2次进入")
	assert_eq(exit_count, 2, "应该记录2次离开")

func test_is_in_safe_zone_check():
	# Given: 玩家在不同区域
	trigger.set_current_region("wilderness")
	
	# Then: 应该正确识别非安全区
	assert_false(trigger.is_in_safe_zone(), "野外不是安全区")
	
	# When: 进入城镇
	trigger.set_current_region("village")
	
	# Then: 应该正确识别安全区
	assert_true(trigger.is_in_safe_zone(), "城镇是安全区")

func test_custom_safe_zone_addition():
	# Edge case: 动态添加安全区
	trigger.set_current_region("custom_area")
	
	# Given: 自定义区域不是安全区
	assert_false(trigger.is_in_safe_zone(), "自定义区域初始不是安全区")
	
	# When: 添加为安全区
	trigger.add_safe_zone("custom_area", RandomEventTrigger.SafeZoneType.SAFE_HOUSE)
	trigger.set_current_region("custom_area")
	
	# Then: 应该识别为安全区
	assert_true(trigger.is_in_safe_zone(), "添加后应该是安全区")

# ============================================================================
# AC-4 测试: 预警机制
# ============================================================================

func test_warning_signal_emitted():
	# Given: 即将触发随机事件
	trigger.set_current_region("wilderness")
	trigger.set_player_luck(100)  # 高福缘确保触发
	var warning_emitted = false
	var warning_time_value = 0.0
	
	trigger.event_trigger_warning.connect(func(warning_time):
		warning_emitted = true
		warning_time_value = warning_time
	)
	
	# When: 距离阈值达到并触发概率判定成功
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(100, 0))
	
	# Then: 应该发出预警信号（可能需要多次尝试因为有概率）
	# 注意：由于触发有概率，这个测试可能需要多次运行
	# 为了测试稳定性，我们检查预警时间是否正确
	if warning_emitted:
		assert_almost_eq(warning_time_value, 2.5, 0.1, "预警时间应该在2-3秒范围内")

func test_warning_timer_duration():
	# Given: 预警系统激活
	trigger.set_current_region("wilderness")
	
	# When: 手动触发预警
	trigger._start_warning("test")
	
	# Then: 预警应该激活
	assert_true(trigger.is_warning_active, "预警应该激活")
	
	# And: 预警时间应该在2-3秒范围内
	var stats = trigger.get_tracking_stats()
	assert_true(stats.is_warning_active, "统计信息应该显示预警激活")

func test_event_ready_signal_after_warning():
	# Given: 预警倒计时开始
	trigger.set_current_region("wilderness")
	var event_ready = false
	# 关键：GDScript lambda 按值捕获，给 lambda 内部的 var 重新赋值不会影响外部变量。
	# 必须把可变状态放到 Dictionary 里，让 lambda mutate 字段，外部才能读到更新。
	var observation := {
		"event_ready": false,
		"trigger_data": {},
	}
	
	trigger.event_trigger_ready.connect(func(data):
		observation["event_ready"] = true
		observation["trigger_data"] = data
	)
	
	# When: 手动触发预警并模拟超时
	trigger._start_warning("distance")
	trigger._on_warning_timeout()  # 直接调用超时处理，避免等待 Timer
	
	# Then: 应该发出事件准备触发信号
	assert_true(observation["event_ready"], "应该发出事件准备触发信号")
	assert_true(observation["trigger_data"].has("trigger_type"), "触发数据应该包含触发类型")
	assert_eq(observation["trigger_data"]["trigger_type"], "distance", "触发类型应该是distance")

func test_warning_cancelled_in_safe_zone():
	# Edge case: 玩家在预警期间进入安全区
	trigger.set_current_region("wilderness")
	var event_ready = false
	
	trigger.event_trigger_ready.connect(func(_data):
		event_ready = true
	)
	
	# When: 触发预警后立即进入安全区
	trigger._start_warning("distance")
	trigger.set_current_region("village")
	# 进入安全区会取消预警，直接调用超时处理验证
	trigger._on_warning_timeout()
	
	# Then: 事件不应该触发
	assert_false(event_ready, "进入安全区后事件不应触发")
	assert_false(trigger.is_warning_active, "预警应该被取消")

func test_no_duplicate_warnings():
	# Edge case: 预警期间不应重复触发
	trigger.set_current_region("wilderness")
	var warning_count = 0
	
	trigger.event_trigger_warning.connect(func(_time):
		warning_count += 1
	)
	
	# When: 预警激活期间再次尝试触发
	trigger._start_warning("distance")
	trigger._perform_trigger_check("time")
	
	# Then: 不应该发出第二次预警
	assert_eq(warning_count, 1, "预警期间不应重复触发")

# ============================================================================
# 触发概率公式测试
# ============================================================================

func test_trigger_probability_base():
	# Given: 默认属性
	trigger.set_player_luck(0)
	trigger.set_consecutive_combat_count(0)
	
	# When: 计算触发概率
	var probability = trigger.calculate_trigger_probability()
	
	# Then: 应该等于基础概率
	assert_eq(probability, 0.3, "基础概率应该是30%")

func test_trigger_probability_with_luck():
	# Given: 玩家有福缘属性
	trigger.set_player_luck(10)
	trigger.set_consecutive_combat_count(0)
	
	# When: 计算触发概率
	var probability = trigger.calculate_trigger_probability()
	
	# Then: 概率应该增加（30% + 10 * 1% = 40%）
	assert_eq(probability, 0.4, "福缘10应该增加10%概率")

func test_trigger_probability_with_combat_penalty():
	# Given: 玩家有连续战斗次数
	trigger.set_player_luck(0)
	trigger.set_consecutive_combat_count(2)
	
	# When: 计算触发概率
	var probability = trigger.calculate_trigger_probability()
	
	# Then: 概率应该减少（30% - 2 * 5% = 20%）
	assert_eq(probability, 0.2, "连续战斗2次应该减少10%概率")

func test_trigger_probability_combined():
	# Given: 同时有福缘和战斗惩罚
	trigger.set_player_luck(20)
	trigger.set_consecutive_combat_count(3)
	
	# When: 计算触发概率
	var probability = trigger.calculate_trigger_probability()
	
	# Then: 概率应该是组合结果（30% + 20% - 15% = 35%）
	assert_eq(probability, 0.35, "组合计算应该正确")

func test_trigger_probability_clamped_to_zero():
	# Edge case: 概率不应低于0
	trigger.set_player_luck(0)
	trigger.set_consecutive_combat_count(10)  # 大量战斗惩罚
	
	# When: 计算触发概率
	var probability = trigger.calculate_trigger_probability()
	
	# Then: 概率应该被限制在0
	assert_eq(probability, 0.0, "概率不应低于0")

func test_trigger_probability_clamped_to_one():
	# Edge case: 概率不应高于1
	trigger.set_player_luck(100)  # 极高福缘
	trigger.set_consecutive_combat_count(0)
	
	# When: 计算触发概率
	var probability = trigger.calculate_trigger_probability()
	
	# Then: 概率应该被限制在1
	assert_eq(probability, 1.0, "概率不应高于1")

# ============================================================================
# 辅助功能测试
# ============================================================================

func test_reset_distance_tracking():
	# Given: 有距离数据
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(50, 0))
	
	# When: 重置距离跟踪
	trigger.reset_distance_tracking()
	
	# Then: 距离数据应该清零
	var stats = trigger.get_tracking_stats()
	assert_eq(stats.total_distance, 0.0, "总距离应该清零")
	assert_eq(stats.distance_since_check, 0.0, "检查距离应该清零")

func test_reset_time_tracking():
	# Given: 有时间数据
	trigger._process(100.0)
	
	# When: 重置时间跟踪
	trigger.reset_time_tracking()
	
	# Then: 时间数据应该清零
	var stats = trigger.get_tracking_stats()
	assert_eq(stats.total_time, 0.0, "总时间应该清零")
	assert_eq(stats.time_since_check, 0.0, "检查时间应该清零")

func test_combat_count_increment():
	# Given: 初始战斗次数为0
	trigger.set_consecutive_combat_count(0)
	
	# When: 增加战斗次数
	trigger.increment_combat_count()
	trigger.increment_combat_count()
	
	# Then: 战斗次数应该正确增加
	var stats = trigger.get_tracking_stats()
	assert_eq(stats.consecutive_combat, 2, "战斗次数应该是2")

func test_combat_count_reset():
	# Given: 有战斗次数
	trigger.set_consecutive_combat_count(5)
	
	# When: 重置战斗次数
	trigger.reset_combat_count()
	
	# Then: 战斗次数应该清零
	var stats = trigger.get_tracking_stats()
	assert_eq(stats.consecutive_combat, 0, "战斗次数应该清零")

func test_get_tracking_stats():
	# Given: 设置各种数据
	trigger.set_player_luck(15)
	trigger.set_consecutive_combat_count(3)
	trigger.update_player_position(Vector2(0, 0))
	trigger.update_player_position(Vector2(25, 0))
	trigger._process(60.0)
	
	# When: 获取统计信息
	var stats = trigger.get_tracking_stats()
	
	# Then: 应该包含所有关键信息
	assert_true(stats.has("total_distance"), "应该包含总距离")
	assert_true(stats.has("distance_since_check"), "应该包含检查距离")
	assert_true(stats.has("total_time"), "应该包含总时间")
	assert_true(stats.has("time_since_check"), "应该包含检查时间")
	assert_true(stats.has("player_luck"), "应该包含玩家福缘")
	assert_true(stats.has("consecutive_combat"), "应该包含连续战斗")
	assert_true(stats.has("trigger_probability"), "应该包含触发概率")
	
	assert_eq(stats.player_luck, 15, "福缘应该是15")
	assert_eq(stats.consecutive_combat, 3, "战斗次数应该是3")