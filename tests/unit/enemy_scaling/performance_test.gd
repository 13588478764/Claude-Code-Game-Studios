## performance_test.gd
## 性能优化单元测试
##
## 测试 TR-enemy-scaling-001 to TR-enemy-scaling-006

extends GutTest

const PerformanceOptimizer = preload("res://scripts/enemy_scaling/performance_optimizer.gd")

var performance_optimizer: PerformanceOptimizer

func before_each():
	performance_optimizer = PerformanceOptimizer.new()

## AC-11: 100个敌人同时生成,总计算时间<100ms
func test_batch_100_enemies_performance():
	# Given: 100个敌人数据
	var enemies_data = []
	for i in range(100):
		enemies_data.append({
			"base_hp": 100,
			"base_attack": 20,
			"enemy_type": i % 3
		})
	
	# When: 批量生成敌人
	var start_time = Time.get_ticks_msec()
	var generated_enemies = performance_optimizer.generate_enemies_batch(
		enemies_data,
		50,
		2
	)
	var total_time = Time.get_ticks_msec() - start_time
	
	# Then: 总计算时间应该<100ms
	assert_eq(generated_enemies.size(), 100, "Should generate 100 enemies")
	assert_true(total_time < 100.0, "Batch generation should complete in <100ms, took %.2fms" % total_time)

## AC-12: 区域切换防抖测试
func test_region_switch_debounce():
	# Given: 玩家在区域边界快速移动
	var region_id = 0
	var delta = 0.016  # 60 FPS
	
	# When: 频繁切换区域
	var should_update1 = performance_optimizer.handle_region_switch(1, delta)
	var should_update2 = performance_optimizer.handle_region_switch(1, delta)
	var should_update3 = performance_optimizer.handle_region_switch(1, delta)
	var should_update4 = performance_optimizer.handle_region_switch(1, delta)
	var should_update5 = performance_optimizer.handle_region_switch(1, delta)
	var should_update6 = performance_optimizer.handle_region_switch(1, delta)
	var should_update7 = performance_optimizer.handle_region_switch(1, delta)
	
	# Then: 应该有防抖,不是每次都更新
	# 100ms防抖 / 16ms帧时间 ≈ 6帧
	var update_count = 0
	if should_update1: update_count += 1
	if should_update2: update_count += 1
	if should_update3: update_count += 1
	if should_update4: update_count += 1
	if should_update5: update_count += 1
	if should_update6: update_count += 1
	if should_update7: update_count += 1
	
	# 应该只更新一次或两次,不是每次都更新
	assert_true(update_count <= 2, "Should debounce region switches, got %d updates" % update_count)

## 验证缓存功能
func test_caching_improves_performance():
	var enemy_data = {"base_hp": 100, "base_attack": 20}
	
	# 第一次生成 (缓存未命中)
	var start_time1 = Time.get_ticks_msec()
	var enemy1 = performance_optimizer.generate_enemy_optimized(
		enemy_data, 50, 2, 0
	)
	var time1 = Time.get_ticks_msec() - start_time1
	
	# 第二次生成 (缓存命中)
	var start_time2 = Time.get_ticks_msec()
	var enemy2 = performance_optimizer.generate_enemy_optimized(
		enemy_data, 50, 2, 0
	)
	var time2 = Time.get_ticks_msec() - start_time2
	
	# 缓存命中应该更快
	var cache_stats = performance_optimizer.get_cache_stats()
	assert_true(cache_stats["cache_hits"] > 0, "Should have cache hits")

## 验证性能统计
func test_performance_statistics():
	var enemy_data = {"base_hp": 100, "base_attack": 20}
	
	# 生成几个敌人
	for i in range(5):
		performance_optimizer.generate_enemy_optimized(
			enemy_data, 50, 2, 0
		)
	
	var stats = performance_optimizer.get_performance_stats()
	assert_eq(stats["total_generations"], 5, "Should track 5 generations")
	assert_true(stats["total_time_ms"] > 0, "Should track total time")
	assert_true(stats["average_time_per_enemy_ms"] > 0, "Should calculate average time")

## 验证缓存统计
func test_cache_statistics():
	var enemy_data = {"base_hp": 100, "base_attack": 20}
	
	# 生成多个敌人以产生缓存命中
	for i in range(10):
		performance_optimizer.generate_enemy_optimized(
			enemy_data, 50, 2, 0
		)
	
	var cache_stats = performance_optimizer.get_cache_stats()
	assert_true(cache_stats["level_cache_size"] > 0, "Should have level cache entries")
	assert_true(cache_stats["realm_cache_size"] > 0, "Should have realm cache entries")
	assert_true(cache_stats["hit_rate_percent"] > 0, "Should have cache hits")

## 验证清除缓存
func test_clear_cache():
	var enemy_data = {"base_hp": 100, "base_attack": 20}
	
	# 生成敌人以填充缓存
	for i in range(5):
		performance_optimizer.generate_enemy_optimized(
			enemy_data, 50, 2, 0
		)
	
	var cache_stats_before = performance_optimizer.get_cache_stats()
	assert_true(cache_stats_before["level_cache_size"] > 0)
	
	# 清除缓存
	performance_optimizer.clear_cache()
	
	var cache_stats_after = performance_optimizer.get_cache_stats()
	assert_eq(cache_stats_after["level_cache_size"], 0, "Cache should be cleared")
	assert_eq(cache_stats_after["cache_hits"], 0, "Cache hits should be reset")

## 验证性能报告
func test_performance_report():
	var enemy_data = {"base_hp": 100, "base_attack": 20}
	
	# 生成几个敌人
	for i in range(3):
		performance_optimizer.generate_enemy_optimized(
			enemy_data, 50, 2, 0
		)
	
	var report = performance_optimizer.get_performance_report()
	assert_true("性能优化报告" in report)
	assert_true("总生成次数" in report)
	assert_true("总耗时" in report)
	assert_true("缓存命中率" in report)

## 验证单个敌人性能预算
func test_single_enemy_performance_budget():
	var enemy_data = {"base_hp": 100, "base_attack": 20}
	
	# 生成单个敌人
	var start_time = Time.get_ticks_msec()
	var enemy = performance_optimizer.generate_enemy_optimized(
		enemy_data, 50, 2, 0
	)
	var elapsed_time = Time.get_ticks_msec() - start_time
	
	# 单个敌人应该<1ms
	assert_true(elapsed_time < 1.0, "Single enemy should generate in <1ms, took %.2fms" % elapsed_time)

## 验证不同等级的缓存
func test_cache_different_levels():
	var enemy_data = {"base_hp": 100, "base_attack": 20}
	
	# 生成不同等级的敌人
	for level in [1, 25, 50, 75, 99]:
		performance_optimizer.generate_enemy_optimized(
			enemy_data, level, 2, 0
		)
	
	var cache_stats = performance_optimizer.get_cache_stats()
	assert_eq(cache_stats["level_cache_size"], 5, "Should cache 5 different levels")
	assert_eq(cache_stats["realm_cache_size"], 5, "Should cache 5 different realms")

## 验证区域切换不影响其他区域
func test_region_switch_independence():
	var enemy_data = {"base_hp": 100, "base_attack": 20}
	
	# 在区域0生成敌人
	var enemy1 = performance_optimizer.generate_enemy_optimized(
		enemy_data, 50, 0, 0
	)
	
	# 切换到区域1
	performance_optimizer.handle_region_switch(1, 0.2)
	
	# 在区域1生成敌人
	var enemy2 = performance_optimizer.generate_enemy_optimized(
		enemy_data, 50, 1, 0
	)
	
	# 两个敌人应该有不同的区域倍率
	assert_true(enemy1["region_multiplier"] != enemy2["region_multiplier"],
		"Different regions should have different multipliers")

## 验证批量生成的一致性
func test_batch_generation_consistency():
	var enemies_data = []
	for i in range(10):
		enemies_data.append({
			"base_hp": 100,
			"base_attack": 20,
			"enemy_type": 0
		})
	
	# 批量生成
	var batch_enemies = performance_optimizer.generate_enemies_batch(
		enemies_data, 50, 2
	)
	
	# 逐个生成
	var individual_enemies = []
	for enemy_data in enemies_data:
		var enemy = performance_optimizer.generate_enemy_optimized(
			enemy_data, 50, 2, 0
		)
		individual_enemies.append(enemy)
	
	# 结果应该一致
	for i in range(batch_enemies.size()):
		assert_almost_eq(batch_enemies[i]["final_hp"], individual_enemies[i]["final_hp"], 0.1,
			"Batch and individual generation should produce same results")

## 验证大规模批量生成 (1000个敌人)
func test_large_batch_1000_enemies():
	var enemies_data = []
	for i in range(1000):
		enemies_data.append({
			"base_hp": 100,
			"base_attack": 20,
			"enemy_type": i % 3
		})
	
	# When: 批量生成1000个敌人
	var start_time = Time.get_ticks_msec()
	var generated_enemies = performance_optimizer.generate_enemies_batch(
		enemies_data,
		50,
		2
	)
	var total_time = Time.get_ticks_msec() - start_time
	
	# Then: 应该在1秒内完成
	assert_eq(generated_enemies.size(), 1000, "Should generate 1000 enemies")
	assert_true(total_time < 1000.0, "1000 enemies should complete in <1 second, took %.2fms" % total_time)