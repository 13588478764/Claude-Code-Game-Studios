## PerformanceMonitor - 性能监控器
## 监控HUD更新时间、内存占用、帧率等性能指标
class_name PerformanceMonitor
extends Node

## 性能数据
var hud_update_times: Array = []
var frame_times: Array = []
var memory_samples: Array = []

## 性能预算（毫秒）
var combat_budget: float = 1.0      # 战斗中<1ms/帧
var exploration_budget: float = 0.5 # 探索中<0.5ms/帧
var target_fps: int = 60
var frame_budget: float = 16.67     # 60FPS = 16.67ms/帧

## 性能状态
var is_in_combat: bool = false
var current_fps: float = 60.0
var average_hud_update_time: float = 0.0
var max_hud_update_time: float = 0.0
var memory_growth: float = 0.0
var initial_memory: float = 0.0

## 性能降级标志
var is_performance_degraded: bool = false
var degradation_level: int = 0  # 0=正常, 1=轻度降级, 2=中度降级, 3=严重降级

## 采样窗口大小
var sample_window: int = 60  # 保留最近60帧的数据

func _ready() -> void:
	set_process(true)
	initial_memory = OS.get_static_memory_usage() / 1024.0 / 1024.0  # 转换为MB

func _process(delta: float) -> void:
	# 记录帧时间
	var frame_time = delta * 1000.0  # 转换为毫秒
	frame_times.append(frame_time)
	
	# 保持采样窗口大小
	if frame_times.size() > sample_window:
		frame_times.pop_front()
	
	# 计算当前FPS
	if frame_time > 0:
		current_fps = 1000.0 / frame_time
	
	# 定期采样内存
	if int(Engine.get_physics_frames()) % 60 == 0:
		_sample_memory()
	
	# 检查性能状态
	_check_performance_status()

## 记录HUD更新时间
func record_hud_update_time(time_ms: float) -> void:
	hud_update_times.append(time_ms)
	
	# 保持采样窗口大小
	if hud_update_times.size() > sample_window:
		hud_update_times.pop_front()
	
	# 更新统计信息
	_update_statistics()

## 采样内存
func _sample_memory() -> void:
	var current_memory = OS.get_static_memory_usage() / 1024.0 / 1024.0  # 转换为MB
	memory_samples.append(current_memory)
	
	# 保持采样窗口大小
	if memory_samples.size() > sample_window:
		memory_samples.pop_front()
	
	# 计算内存增长
	if memory_samples.size() > 0:
		memory_growth = memory_samples[-1] - initial_memory

## 更新统计信息
func _update_statistics() -> void:
	if hud_update_times.is_empty():
		return
	
	# 计算平均值
	var sum = 0.0
	var max_val = 0.0
	for time in hud_update_times:
		sum += time
		max_val = max(max_val, time)
	
	average_hud_update_time = sum / hud_update_times.size()
	max_hud_update_time = max_val

## 检查性能状态
func _check_performance_status() -> void:
	var budget = combat_budget if is_in_combat else exploration_budget
	
	# 检查HUD更新时间
	if average_hud_update_time > budget * 2.0:
		# 性能严重降级
		if degradation_level < 3:
			degradation_level = 3
			is_performance_degraded = true
	elif average_hud_update_time > budget * 1.5:
		# 性能中度降级
		if degradation_level < 2:
			degradation_level = 2
			is_performance_degraded = true
	elif average_hud_update_time > budget:
		# 性能轻度降级
		if degradation_level < 1:
			degradation_level = 1
			is_performance_degraded = true
	else:
		# 性能正常
		degradation_level = 0
		is_performance_degraded = false
	
	# 检查帧率
	if current_fps < 55.0:
		is_performance_degraded = true

## 获取性能报告
func get_performance_report() -> Dictionary:
	return {
		"average_hud_update_time": average_hud_update_time,
		"max_hud_update_time": max_hud_update_time,
		"current_fps": current_fps,
		"memory_growth_mb": memory_growth,
		"is_performance_degraded": is_performance_degraded,
		"degradation_level": degradation_level,
		"frame_count": frame_times.size(),
		"hud_update_count": hud_update_times.size()
	}

## 获取99百分位数据
func get_percentile_99() -> Dictionary:
	var hud_99 = _calculate_percentile(hud_update_times, 0.99)
	var frame_99 = _calculate_percentile(frame_times, 0.99)
	
	return {
		"hud_update_time_99": hud_99,
		"frame_time_99": frame_99
	}

## 计算百分位数
func _calculate_percentile(data: Array, percentile: float) -> float:
	if data.is_empty():
		return 0.0
	
	var sorted_data = data.duplicate()
	sorted_data.sort()
	
	var index = int(sorted_data.size() * percentile)
	index = clampi(index, 0, sorted_data.size() - 1)
	
	return sorted_data[index]

## 设置战斗状态
func set_in_combat(value: bool) -> void:
	is_in_combat = value

## 重置统计数据
func reset_statistics() -> void:
	hud_update_times.clear()
	frame_times.clear()
	memory_samples.clear()
	initial_memory = OS.get_static_memory_usage() / 1024.0 / 1024.0
	average_hud_update_time = 0.0
	max_hud_update_time = 0.0
	memory_growth = 0.0
	degradation_level = 0
	is_performance_degraded = false

## 获取统计信息
func get_stats() -> Dictionary:
	return {
		"average_hud_update_time": average_hud_update_time,
		"max_hud_update_time": max_hud_update_time,
		"current_fps": current_fps,
		"memory_growth": memory_growth,
		"is_degraded": is_performance_degraded,
		"degradation_level": degradation_level
	}