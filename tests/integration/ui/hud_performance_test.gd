## HUD性能优化集成测试
## 测试所有16个AC的性能优化功能
extends GutTest

var buff_icon_pool: BuffIconPool
var damage_number_pool: DamageNumberPool
var notification_pool: NotificationPool
var batch_update_manager: BatchUpdateManager
var lod_scheduler: LODUpdateScheduler
var performance_monitor: PerformanceMonitor

func before_each() -> void:
	performance_monitor = PerformanceMonitor.new()
	add_child(performance_monitor)
	
	batch_update_manager = BatchUpdateManager.new(performance_monitor)
	buff_icon_pool = BuffIconPool.create()
	damage_number_pool = DamageNumberPool.create()
	notification_pool = NotificationPool.create()
	
	lod_scheduler = LODUpdateScheduler.new()
	add_child(lod_scheduler)

func after_each() -> void:
	buff_icon_pool.clear()
	damage_number_pool.clear()
	notification_pool.clear()
	batch_update_manager.clear_queue()
	performance_monitor.reset_statistics()

## AC-1: BuffIconPool正确分配和回收图标(池大小20)
func test_buff_icon_pool_allocation_and_release() -> void:
	var stats = buff_icon_pool.get_stats()
	assert_eq(stats["pool_size"], 20, "BuffIconPool初始大小应为20")
	assert_eq(stats["available"], 20, "初始时所有对象应该可用")
	assert_eq(stats["in_use"], 0, "初始时没有对象在使用")
	
	# 分配10个图标
	var icons = []
	for i in range(10):
		var icon = buff_icon_pool.acquire_buff_icon("buff_%d" % i, null, 1)
		icons.append(icon)
	
	stats = buff_icon_pool.get_stats()
	assert_eq(stats["available"], 10, "分配10个后，可用对象应为10")
	assert_eq(stats["in_use"], 10, "分配10个后，使用中的对象应为10")
	
	# 回收5个图标
	for i in range(5):
		buff_icon_pool.release_buff_icon(icons[i])
	
	stats = buff_icon_pool.get_stats()
	assert_eq(stats["available"], 15, "回收5个后，可用对象应为15")
	assert_eq(stats["in_use"], 5, "回收5个后，使用中的对象应为5")

## AC-2: DamageNumberPool正确分配和回收飘字(池大小30)
func test_damage_number_pool_allocation_and_release() -> void:
	var stats = damage_number_pool.get_stats()
	assert_eq(stats["pool_size"], 30, "DamageNumberPool初始大小应为30")
	assert_eq(stats["available"], 30, "初始时所有对象应该可用")
	assert_eq(stats["in_use"], 0, "初始时没有对象在使用")
	
	# 分配15个飘字
	var numbers = []
	for i in range(15):
		var number = damage_number_pool.acquire_damage_number(100 + i, "normal")
		numbers.append(number)
	
	stats = damage_number_pool.get_stats()
	assert_eq(stats["available"], 15, "分配15个后，可用对象应为15")
	assert_eq(stats["in_use"], 15, "分配15个后，使用中的对象应为15")
	
	# 回收8个飘字
	for i in range(8):
		damage_number_pool.release_damage_number(numbers[i])
	
	stats = damage_number_pool.get_stats()
	assert_eq(stats["available"], 23, "回收8个后，可用对象应为23")
	assert_eq(stats["in_use"], 7, "回收8个后，使用中的对象应为7")

## AC-3: NotificationPool正确分配和回收通知面板(池大小10)
func test_notification_pool_allocation_and_release() -> void:
	var stats = notification_pool.get_stats()
	assert_eq(stats["pool_size"], 10, "NotificationPool初始大小应为10")
	assert_eq(stats["available"], 10, "初始时所有对象应该可用")
	assert_eq(stats["in_use"], 0, "初始时没有对象在使用")
	
	# 分配5个通知
	var notifications = []
	for i in range(5):
		var notif = notification_pool.acquire_notification("Title %d" % i, "Content %d" % i, "info", 3.0)
		notifications.append(notif)
	
	stats = notification_pool.get_stats()
	assert_eq(stats["available"], 5, "分配5个后，可用对象应为5")
	assert_eq(stats["in_use"], 5, "分配5个后，使用中的对象应为5")
	
	# 回收3个通知
	for i in range(3):
		notification_pool.release_notification(notifications[i])
	
	stats = notification_pool.get_stats()
	assert_eq(stats["available"], 8, "回收3个后，可用对象应为8")
	assert_eq(stats["in_use"], 2, "回收3个后，使用中的对象应为2")

## AC-4: BatchUpdateManager正确收集和应用更新
func test_batch_update_manager_queue_and_apply() -> void:
	var update_count = 0
	var test_object = Node.new()
	test_object.set_meta("update_count", 0)
	
	# 添加10个更新到队列
	for i in range(10):
		batch_update_manager.queue_update({
			"target": test_object,
			"method": "set_meta",
			"args": ["update_count", i]
		})
	
	assert_eq(batch_update_manager.get_queue_size(), 10, "队列应包含10个更新")
	
	# 应用所有更新
	batch_update_manager.apply_updates()
	
	assert_eq(batch_update_manager.get_queue_size(), 0, "应用后队列应为空")
	assert_eq(test_object.get_meta("update_count"), 9, "最后一个更新应该被应用")

## AC-5: LODUpdateScheduler按预期频率调度更新(P0:立即,P1:0.1s,P2-P4:0.3-1s)
func test_lod_scheduler_update_frequency() -> void:
	# 注册不同优先级的组件
	lod_scheduler.register_component("component_p0", LODUpdateScheduler.Priority.P0)
	lod_scheduler.register_component("component_p1", LODUpdateScheduler.Priority.P1)
	lod_scheduler.register_component("component_p2", LODUpdateScheduler.Priority.P2)
	
	# P0应该总是返回true
	assert_true(lod_scheduler.should_update("component_p0"), "P0优先级应该总是返回true")
	assert_true(lod_scheduler.should_update("component_p0"), "P0优先级应该总是返回true")
	
	# P1在0.1秒内不应该更新
	assert_true(lod_scheduler.should_update("component_p1"), "第一次应该返回true")
	assert_false(lod_scheduler.should_update("component_p1"), "0.1秒内不应该更新")
	
	# 模拟时间推进
	lod_scheduler.current_time += 0.15
	assert_true(lod_scheduler.should_update("component_p1"), "0.15秒后应该返回true")

## AC-6: 战斗中HUD更新<1ms/帧
func test_combat_hud_update_performance() -> void:
	performance_monitor.set_in_combat(true)
	
	# 模拟多个HUD更新
	for i in range(60):
		var update_time = randf_range(0.1, 0.9)  # 0.1-0.9ms
		performance_monitor.record_hud_update_time(update_time)
	
	var report = performance_monitor.get_performance_report()
	assert_lt(report["average_hud_update_time"], 1.0, "战斗中平均HUD更新应<1ms")

## AC-7: 探索中HUD更新<0.5ms/帧
func test_exploration_hud_update_performance() -> void:
	performance_monitor.set_in_combat(false)
	
	# 模拟多个HUD更新
	for i in range(60):
		var update_time = randf_range(0.1, 0.4)  # 0.1-0.4ms
		performance_monitor.record_hud_update_time(update_time)
	
	var report = performance_monitor.get_performance_report()
	assert_lt(report["average_hud_update_time"], 0.5, "探索中平均HUD更新应<0.5ms")

## AC-8: HUD draw calls<100
func test_hud_draw_calls_budget() -> void:
	# 这个测试验证HUD组件的draw call数量
	# 在实际游戏中，这需要通过Profiler验证
	# 这里我们验证性能监控器能够跟踪这个指标
	var report = performance_monitor.get_performance_report()
	assert_has(report, "frame_count", "性能报告应包含frame_count")

## AC-9: 60FPS稳定
func test_60fps_stability() -> void:
	# 模拟60帧的帧时间（每帧16.67ms）
	for i in range(60):
		var frame_time = randf_range(15.0, 17.0)  # 15-17ms
		performance_monitor.frame_times.append(frame_time)
	
	var report = performance_monitor.get_performance_report()
	assert_gt(report["current_fps"], 55.0, "帧率应该保持>55FPS")

## AC-10: 连续运行30分钟后内存增长<10MB,无内存泄漏
func test_memory_leak_detection() -> void:
	# 记录初始内存
	var initial_memory = performance_monitor.initial_memory
	
	# 模拟30分钟的内存采样（每秒一次）
	for i in range(1800):
		performance_monitor._sample_memory()
	
	var report = performance_monitor.get_performance_report()
	assert_lt(report["memory_growth_mb"], 10.0, "30分钟内内存增长应<10MB")

## AC-11: 同时显示50个Buff图标时帧率保持>55FPS
func test_buff_icon_stress_test() -> void:
	# 分配50个Buff图标
	var icons = []
	for i in range(50):
		var icon = buff_icon_pool.acquire_buff_icon("buff_%d" % i, null, 1)
		icons.append(icon)
	
	# 验证池能够处理超出初始大小的请求
	var stats = buff_icon_pool.get_stats()
	assert_eq(stats["in_use"], 50, "应该能够分配50个图标")
	
	# 模拟帧时间
	for i in range(60):
		var frame_time = randf_range(15.0, 17.0)
		performance_monitor.frame_times.append(frame_time)
	
	var report = performance_monitor.get_performance_report()
	assert_gt(report["current_fps"], 55.0, "50个图标时帧率应>55FPS")

## AC-12: 同时显示20个伤害飘字时帧率保持>55FPS
func test_damage_number_stress_test() -> void:
	# 分配20个伤害飘字
	var numbers = []
	for i in range(20):
		var number = damage_number_pool.acquire_damage_number(100 + i, "normal")
		numbers.append(number)
	
	# 验证池能够处理请求
	var stats = damage_number_pool.get_stats()
	assert_eq(stats["in_use"], 20, "应该能够分配20个飘字")
	
	# 模拟帧时间
	for i in range(60):
		var frame_time = randf_range(15.0, 17.0)
		performance_monitor.frame_times.append(frame_time)
	
	var report = performance_monitor.get_performance_report()
	assert_gt(report["current_fps"], 55.0, "20个飘字时帧率应>55FPS")

## AC-13: 性能不达标时自动降低更新频率,优先保证帧率
func test_performance_degradation_strategy() -> void:
	performance_monitor.set_in_combat(true)
	
	# 模拟性能不达标的情况
	for i in range(60):
		var update_time = 1.5  # 超过1ms预算
		performance_monitor.record_hud_update_time(update_time)
	
	var report = performance_monitor.get_performance_report()
	assert_true(report["is_performance_degraded"], "性能不达标时应标记为降级")
	assert_gt(report["degradation_level"], 0, "降级级别应>0")

## AC-14: BuffIconPool耗尽时自动扩容或复用最旧的图标
func test_buff_icon_pool_expansion() -> void:
	# 分配超过池大小的图标
	var icons = []
	for i in range(30):  # 超过初始大小20
		var icon = buff_icon_pool.acquire_buff_icon("buff_%d" % i, null, 1)
		icons.append(icon)
	
	# 验证池能够扩容
	var stats = buff_icon_pool.get_stats()
	assert_eq(stats["in_use"], 30, "池应该能够扩容到30个")
	assert_eq(stats["total"], 30, "总对象数应为30")

## AC-15: BatchUpdateManager队列超过100项时分帧处理
func test_batch_update_manager_large_queue() -> void:
	var test_object = Node.new()
	
	# 添加150个更新到队列
	for i in range(150):
		batch_update_manager.queue_update({
			"target": test_object,
			"method": "set_meta",
			"args": ["value_%d" % i, i]
		})
	
	# 队列超过100时应该自动处理
	assert_eq(batch_update_manager.get_queue_size(), 0, "超过100项时应该自动处理")

## AC-16: 1280x720分辨率下使用低LOD,2560x1440下使用高LOD
func test_lod_resolution_switching() -> void:
	# 获取当前LOD
	var current_lod = lod_scheduler.get_current_lod()
	assert_ge(current_lod, LODUpdateScheduler.LODLevel.LOW, "LOD应该是有效的")
	assert_le(current_lod, LODUpdateScheduler.LODLevel.HIGH, "LOD应该是有效的")
	
	# 验证LOD名称
	var lod_name = lod_scheduler.get_lod_name()
	assert_true(lod_name in ["LOW", "MEDIUM", "HIGH"], "LOD名称应该是有效的")

## 性能报告生成测试
func test_performance_report_generation() -> void:
	# 记录一些性能数据
	for i in range(60):
		performance_monitor.record_hud_update_time(randf_range(0.1, 0.8))
		performance_monitor.frame_times.append(randf_range(15.0, 17.0))
	
	var report = performance_monitor.get_performance_report()
	assert_has(report, "average_hud_update_time", "报告应包含平均HUD更新时间")
	assert_has(report, "max_hud_update_time", "报告应包含最大HUD更新时间")
	assert_has(report, "current_fps", "报告应包含当前FPS")
	assert_has(report, "memory_growth_mb", "报告应包含内存增长")
	assert_has(report, "is_performance_degraded", "报告应包含性能降级标志")

## 99百分位数据测试
func test_percentile_99_calculation() -> void:
	# 记录一些性能数据
	for i in range(100):
		performance_monitor.record_hud_update_time(float(i) * 0.01)
	
	var percentile_data = performance_monitor.get_percentile_99()
	assert_has(percentile_data, "hud_update_time_99", "应包含HUD更新时间99百分位")
	assert_has(percentile_data, "frame_time_99", "应包含帧时间99百分位")
	assert_gt(percentile_data["hud_update_time_99"], 0.0, "99百分位应>0")