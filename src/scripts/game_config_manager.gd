## GameConfigManager单例
## 管理游戏全局配置,包括内存监控和降级模式
## 
## AC3: 内存不足降级处理
## 遵循ADR-001: 使用单例模式管理全局配置

extends Node

## 信号: 低内存模式状态改变
## @param enabled: 是否启用低内存模式
signal low_memory_mode_changed(enabled: bool)

## 低内存模式阈值(GB)
const LOW_MEMORY_THRESHOLD_GB: float = 2.0

## 当前是否处于低内存模式
var low_memory_mode: bool = false

## 是否允许手动覆盖低内存模式
var manual_override: bool = false

## 手动设置的低内存模式值
var manual_low_memory_mode: bool = false

## 游戏启动时调用
func _ready() -> void:
	check_memory_and_update_mode()

## AC3: 检测内存并更新降级模式
func check_memory_and_update_mode() -> void:
	# 如果手动覆盖,使用手动设置的值
	if manual_override:
		_set_low_memory_mode(manual_low_memory_mode)
		return
	
	# 获取系统内存使用情况
	var memory_bytes = OS.get_static_memory_usage()
	var memory_gb = memory_bytes / 1024.0 / 1024.0 / 1024.0
	
	# 判断是否需要启用低内存模式
	var should_enable = memory_gb < LOW_MEMORY_THRESHOLD_GB
	
	# 记录日志
	print("[GameConfig] Memory usage: %.2f GB, Threshold: %.2f GB, Low memory mode: %s" % [
		memory_gb,
		LOW_MEMORY_THRESHOLD_GB,
		"ENABLED" if should_enable else "DISABLED"
	])
	
	_set_low_memory_mode(should_enable)

## 设置低内存模式
## @param enabled: 是否启用
func _set_low_memory_mode(enabled: bool) -> void:
	if low_memory_mode != enabled:
		low_memory_mode = enabled
		low_memory_mode_changed.emit(enabled)
		
		if enabled:
			print("[GameConfig] Low memory mode ENABLED - disabling particles and audio feedback")
		else:
			print("[GameConfig] Low memory mode DISABLED - enabling full visual and audio effects")

## 手动设置低内存模式(用于测试或玩家配置)
## @param enabled: 是否启用
func set_manual_low_memory_mode(enabled: bool) -> void:
	manual_override = true
	manual_low_memory_mode = enabled
	_set_low_memory_mode(enabled)

## 清除手动覆盖,恢复自动检测
func clear_manual_override() -> void:
	manual_override = false
	check_memory_and_update_mode()

## 获取当前内存使用情况(GB)
## @return: 内存使用量(GB)
func get_current_memory_usage_gb() -> float:
	var memory_bytes = OS.get_static_memory_usage()
	return memory_bytes / 1024.0 / 1024.0 / 1024.0

## 是否处于低内存模式
## @return: true表示低内存模式
func is_low_memory_mode() -> bool:
	return low_memory_mode