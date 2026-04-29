## PerformanceOptimizer
## performance_optimizer.gd
性能优化和批量计算系统
优化批量敌人生成性能,实现缓存和防抖机制
TR-enemy-scaling-001 to TR-enemy-scaling-006
##
## 主要功能：
## - 待补充

extends Node

class_name PerformanceOptimizer

# 导入敌人生成器
const EnemyGenerator = preload("res://scripts/enemy_scaling/enemy_generator.gd")
const LevelCoefficient = preload("res://scripts/enemy_scaling/level_coefficient.gd")
const RealmCoefficient = preload("res://scripts/enemy_scaling/realm_coefficient.gd")

# 性能预算 (毫秒)
const SINGLE_ENEMY_BUDGET = 1.0  # 单个敌人 < 1ms
const BATCH_100_BUDGET = 100.0   # 100个敌人 < 100ms

# 缓存
var _level_coefficient_cache: Dictionary = {}
var _realm_coefficient_cache: Dictionary = {}
var _last_region_id: int = -1
var _region_switch_debounce_timer: float = 0.0
var _debounce_delay: float = 0.1  # 100ms 防抖延迟

# 性能统计
var _performance_stats: Dictionary = {
	"total_generations": 0,
	"total_time_ms": 0.0,
	"average_time_per_enemy_ms": 0.0,
	"cache_hits": 0,
	"cache_misses": 0
}

var enemy_generator: EnemyGenerator

func _init():
	enemy_generator = EnemyGenerator.new()

## 生成单个敌人实例 (带缓存优化)
##
## @param enemy_base_data: 敌人基础数据
## @param player_level: 玩家等级
## @param region_id: 区域ID
## @param enemy_type: 敌人类型
## @return: 敌人实例
func generate_enemy_optimized(
	enemy_base_data: Dictionary,
	player_level: int,
	region_id: int,
	enemy_type: int
) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	# 使用缓存的系数
	var level_coeff = _get_cached_level_coefficient(player_level)
	var realm_coeff = _get_cached_realm_coefficient(player_level)
	
	# 调用敌人生成器
	var enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data,
		player_level,
		region_id,
		enemy_type
	)
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	_record_performance(elapsed_time)
	
	return enemy

## 批量生成敌人 (优化版本)
##
## AC-11: 100个敌人同时生成,总计算时间<100ms
##
## @param enemies_data: 敌人数据数组
## @param player_level: 玩家等级
## @param region_id: 区域ID
## @return: 敌人实例数组
func generate_enemies_batch(
	enemies_data: Array,
	player_level: int,
	region_id: int
) -> Array:
	var start_time = Time.get_ticks_msec()
	var generated_enemies = []
	
	# 预缓存等级和境界系数
	_prefetch_coefficients(player_level)
	
	for enemy_data in enemies_data:
		var enemy = generate_enemy_optimized(
			enemy_data,
			player_level,
			region_id,
			enemy_data.get("enemy_type", 0)
		)
		generated_enemies.append(enemy)
	
	var total_time = Time.get_ticks_msec() - start_time
	_record_batch_performance(enemies_data.size(), total_time)
	
	return generated_enemies

## 处理区域切换 (带防抖)
##
## AC-12: 玩家在区域边界快速移动,频繁切换区域难度,不应出现卡顿
##
## @param new_region_id: 新区域ID
## @param delta: 帧时间差
## @return: 是否应该更新区域
func handle_region_switch(new_region_id: int, delta: float) -> bool:
	# 如果区域没有改变,不需要处理
	if new_region_id == _last_region_id:
		return false
	
	# 防抖处理
	_region_switch_debounce_timer += delta
	
	if _region_switch_debounce_timer >= _debounce_delay:
		_last_region_id = new_region_id
		_region_switch_debounce_timer = 0.0
		return true
	
	return false

## 获取缓存的等级系数
##
## @param player_level: 玩家等级
## @return: 等级系数
func _get_cached_level_coefficient(player_level: int) -> float:
	if _level_coefficient_cache.has(player_level):
		_performance_stats["cache_hits"] += 1
		return _level_coefficient_cache[player_level]
	
	_performance_stats["cache_misses"] += 1
	var coefficient = LevelCoefficient.calculate_level_coefficient(player_level)
	_level_coefficient_cache[player_level] = coefficient
	return coefficient

## 获取缓存的境界系数
##
## @param player_level: 玩家等级
## @return: 境界系数
func _get_cached_realm_coefficient(player_level: int) -> float:
	if _realm_coefficient_cache.has(player_level):
		_performance_stats["cache_hits"] += 1
		return _realm_coefficient_cache[player_level]
	
	_performance_stats["cache_misses"] += 1
	var coefficient = RealmCoefficient.calculate_realm_coefficient(player_level)
	_realm_coefficient_cache[player_level] = coefficient
	return coefficient

## 预缓存系数 (用于批量操作)
##
## @param player_level: 玩家等级
func _prefetch_coefficients(player_level: int):
	_get_cached_level_coefficient(player_level)
	_get_cached_realm_coefficient(player_level)

## 记录单个敌人的性能数据
##
## @param elapsed_time: 耗时 (毫秒)
func _record_performance(elapsed_time: float):
	_performance_stats["total_generations"] += 1
	_performance_stats["total_time_ms"] += elapsed_time
	_performance_stats["average_time_per_enemy_ms"] = _performance_stats["total_time_ms"] / _performance_stats["total_generations"]

## 记录批量生成的性能数据
##
## @param count: 生成的敌人数量
## @param total_time: 总耗时 (毫秒)
func _record_batch_performance(count: int, total_time: float):
	var time_per_enemy = total_time / count if count > 0 else 0.0
	
	# 检查是否符合性能预算
	if total_time > BATCH_100_BUDGET and count == 100:
		push_warning("Batch generation exceeded budget: %.2fms > %.2fms" % [total_time, BATCH_100_BUDGET])
	
	if time_per_enemy > SINGLE_ENEMY_BUDGET:
		push_warning("Single enemy generation exceeded budget: %.2fms > %.2fms" % [time_per_enemy, SINGLE_ENEMY_BUDGET])

## 清除缓存
func clear_cache():
	_level_coefficient_cache.clear()
	_realm_coefficient_cache.clear()
	_performance_stats["cache_hits"] = 0
	_performance_stats["cache_misses"] = 0

## 获取性能统计
##
## @return: 性能统计字典
func get_performance_stats() -> Dictionary:
	return _performance_stats.duplicate()

## 获取缓存统计
##
## @return: 缓存统计字典
func get_cache_stats() -> Dictionary:
	var total_lookups = _performance_stats["cache_hits"] + _performance_stats["cache_misses"]
	var hit_rate = (total_lookups > 0) ? (_performance_stats["cache_hits"] / float(total_lookups)) * 100.0 : 0.0
	
	return {
		"level_cache_size": _level_coefficient_cache.size(),
		"realm_cache_size": _realm_coefficient_cache.size(),
		"cache_hits": _performance_stats["cache_hits"],
		"cache_misses": _performance_stats["cache_misses"],
		"hit_rate_percent": hit_rate
	}

## 获取性能报告
##
## @return: 性能报告字符串
func get_performance_report() -> String:
	var stats = get_performance_stats()
	var cache_stats = get_cache_stats()
	
	var report = "性能优化报告:\n"
	report += "  总生成次数: %d\n" % stats["total_generations"]
	report += "  总耗时: %.2fms\n" % stats["total_time_ms"]
	report += "  平均每个敌人: %.4fms\n" % stats["average_time_per_enemy_ms"]
	report += "  缓存命中率: %.1f%%\n" % cache_stats["hit_rate_percent"]
	report += "  等级系数缓存大小: %d\n" % cache_stats["level_cache_size"]
	report += "  境界系数缓存大小: %d\n" % cache_stats["realm_cache_size"]
	
	return report