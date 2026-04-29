# GameConfigManager - 游戏全局配置管理器
#
# 负责管理游戏全局配置，包括内存监控和降级模式
# 遵循 ADR-001: 使用单例模式管理全局配置
#
# 信号:
#   - low_memory_mode_changed(enabled: bool)

extends Node

class_name GameConfigManager

# ============================================================================
# 常量定义
# ============================================================================

const LOW_MEMORY_THRESHOLD_GB: float = 2.0
const MEMORY_CHECK_INTERVAL: float = 5.0  # 每 5 秒检查一次内存
const LOG_PREFIX: String = "[GameConfig]"

# ============================================================================
# 信号定义
# ============================================================================

## 低内存模式状态改变信号
signal low_memory_mode_changed(enabled: bool)

# ============================================================================
# 成员变量
# ============================================================================

var low_memory_mode: bool = false
var manual_override: bool = false
var manual_low_memory_mode: bool = false
var debug_enabled: bool = true
var memory_check_timer: float = 0.0

# ============================================================================
# 生命周期方法
# ============================================================================

## 游戏启动时调用
func _ready() -> void:
	check_memory_and_update_mode()

## 每帧更新
func _process(delta: float) -> void:
	# 定期检查内存
	memory_check_timer += delta
	if memory_check_timer >= MEMORY_CHECK_INTERVAL:
		memory_check_timer = 0.0
		check_memory_and_update_mode()

# ============================================================================
# 公共方法
# ============================================================================

## 检测内存并更新降级模式
func check_memory_and_update_mode() -> void:
	# 验证状态
	if not is_node_ready():
		return
	
	# 如果手动覆盖，使用手动设置的值
	if manual_override:
		_set_low_memory_mode(manual_low_memory_mode)
		return
	
	# 获取系统内存使用情况
	var memory_gb = get_current_memory_usage_gb()
	
	# 判断是否需要启用低内存模式
	var should_enable = memory_gb < LOW_MEMORY_THRESHOLD_GB
	
	# 记录日志
	if debug_enabled:
		print("%s Memory usage: %.2f GB, Threshold: %.2f GB, Low memory mode: %s" % [
			LOG_PREFIX,
			memory_gb,
			LOW_MEMORY_THRESHOLD_GB,
			"ENABLED" if should_enable else "DISABLED"
		])
	
	_set_low_memory_mode(should_enable)

## 手动设置低内存模式 (用于测试或玩家配置)
## 参数:
##   - enabled: 是否启用低内存模式
func set_manual_low_memory_mode(enabled: bool) -> void:
	if not is_node_ready():
		push_error("%s 节点未就绪" % LOG_PREFIX)
		return
	
	manual_override = true
	manual_low_memory_mode = enabled
	_set_low_memory_mode(enabled)

## 清除手动覆盖，恢复自动检测
func clear_manual_override() -> void:
	if not is_node_ready():
		push_error("%s 节点未就绪" % LOG_PREFIX)
		return
	
	manual_override = false
	check_memory_and_update_mode()

## 获取当前内存使用情况 (GB)
## 返回: 内存使用量 (GB)
func get_current_memory_usage_gb() -> float:
	var memory_bytes = OS.get_static_memory_usage()
	if memory_bytes <= 0:
		push_warning("%s 无法获取内存信息" % LOG_PREFIX)
		return 0.0
	
	return memory_bytes / 1024.0 / 1024.0 / 1024.0

## 是否处于低内存模式
## 返回: true 表示低内存模式
func is_low_memory_mode() -> bool:
	return low_memory_mode

## 设置调试日志开关
## 参数:
##   - enabled: 是否启用调试日志
func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled

# ============================================================================
# 私有方法
# ============================================================================

## 设置低内存模式
## 参数:
##   - enabled: 是否启用
func _set_low_memory_mode(enabled: bool) -> void:
	if low_memory_mode == enabled:
		return  # 状态未改变，无需处理
	
	low_memory_mode = enabled
	low_memory_mode_changed.emit(enabled)
	
	if debug_enabled:
		if enabled:
			print("%s Low memory mode ENABLED - disabling particles and audio feedback" % LOG_PREFIX)
		else:
			print("%s Low memory mode DISABLED - enabling full visual and audio effects" % LOG_PREFIX)