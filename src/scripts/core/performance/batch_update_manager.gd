## BatchUpdateManager - 批量更新管理器
## 收集更新，减少信号调用次数，提高性能
class_name BatchUpdateManager
extends Node

## 更新队列
var update_queue: Array = []
## 最大队列大小（超过此大小时分帧处理）
var max_queue_size: int = 100
## 是否正在处理更新
var is_processing: bool = false
## 性能监控器引用
var performance_monitor: PerformanceMonitor

func _init(p_monitor: PerformanceMonitor = null) -> void:
	performance_monitor = p_monitor

## 添加更新到队列
func queue_update(update_data: Dictionary) -> void:
	update_queue.append(update_data)
	
	# 如果队列超过最大大小，立即处理
	if update_queue.size() > max_queue_size:
		apply_updates()

## 应用所有待处理的更新
func apply_updates() -> void:
	if is_processing or update_queue.is_empty():
		return
	
	is_processing = true
	var start_time = Time.get_ticks_msec()
	
	# 处理所有更新
	for update in update_queue:
		_apply_single_update(update)
	
	update_queue.clear()
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	if performance_monitor:
		performance_monitor.record_hud_update_time(elapsed_time)
	
	is_processing = false

## 应用单个更新
func _apply_single_update(update_data: Dictionary) -> void:
	if update_data.has("target") and update_data.has("method"):
		var target = update_data["target"]
		var method = update_data["method"]
		var args = update_data.get("args", [])
		
		if target and target.has_method(method):
			target.callv(method, args)

## 获取队列大小
func get_queue_size() -> int:
	return update_queue.size()

## 清空队列
func clear_queue() -> void:
	update_queue.clear()

## 获取统计信息
func get_stats() -> Dictionary:
	return {
		"queue_size": update_queue.size(),
		"max_queue_size": max_queue_size,
		"is_processing": is_processing
	}