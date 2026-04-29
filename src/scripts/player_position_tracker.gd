# PlayerPositionTracker - 玩家位置追踪器
#
# 负责基于玩家位置的智能加载策略
# 符合 ADR-001 架构决策：组件化设计，使用 Godot 信号系统
#
# 信号:
#   - fast_movement_detected(velocity)
#   - important_block_marked(block_position, priority)

extends Node

class_name PlayerPositionTracker

# ============================================================================
# 依赖注入
# ============================================================================

@onready var world_streaming_manager = $WorldStreamingManager

# ============================================================================
# 常量定义 - 配置参数
# ============================================================================

const MIN_STAY_TIME_MS: int = 500
const FAST_MOVEMENT_THRESHOLD: float = 500.0
const PREDICTION_LOOKAHEAD_BLOCKS: int = 3
const MOVEMENT_HISTORY_SIZE: int = 10

# ============================================================================
# 常量定义 - 其他
# ============================================================================

const LOG_PREFIX: String = "[PlayerPositionTracker]"

# ============================================================================
# 信号定义
# ============================================================================

## 快速移动检测信号
signal fast_movement_detected(velocity: Vector2)

## 重要区块标记信号
signal important_block_marked(block_position: Vector2i, priority: float)

# ============================================================================
# 成员变量 - 玩家状态
# ============================================================================

var player_position: Vector2 = Vector2.ZERO
var player_velocity: Vector2 = Vector2.ZERO
var last_position_update: float = 0.0
var current_block: Vector2i = Vector2i.ZERO
var previous_block: Vector2i = Vector2i.ZERO

# ============================================================================
# 成员变量 - 移动状态
# ============================================================================

var is_moving_fast: bool = false
var movement_history: Array = []
var stay_timers: Dictionary = {}

# ============================================================================
# 成员变量 - 其他
# ============================================================================

var high_priority_blocks: Dictionary = {}
var debug_enabled: bool = true

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化
func _ready() -> void:
	# 连接信号
	connect("fast_movement_detected", Callable(self, "_on_fast_movement_detected"))
	connect("important_block_marked", Callable(self, "_on_important_block_marked"))
	
	# 初始化移动历史
	movement_history.resize(MOVEMENT_HISTORY_SIZE)
	for i in range(movement_history.size()):
		movement_history[i] = Vector2.ZERO
	
	if debug_enabled:
		print("%s 初始化完成" % LOG_PREFIX)

func _process(delta: float) -> void:
	# 更新玩家位置和速度
	_update_player_state(delta)
	
	# 检测快速移动
	_detect_fast_movement()
	
	# 更新区块停留计时器
	_update_stay_timers()
	
	# 执行智能加载策略
	_execute_smart_loading_strategy()

# 更新玩家状态
func _update_player_state(delta: float) -> void:
	# 获取当前玩家位置（实际项目中应从玩家系统获取）
	var new_position = get_player_position_from_system()
	
	# 计算速度
	if last_position_update > 0:
		var time_diff = Time.get_ticks_msec() - last_position_update
		if time_diff > 0:
			player_velocity = (new_position - player_position) / (time_diff / 1000.0)
	
	player_position = new_position
	last_position_update = Time.get_ticks_msec()
	
	# 更新移动历史
	movement_history.pop_front()
	movement_history.append(player_position)
	
	# 更新当前区块
	var new_block = world_streaming_manager._world_to_block_coord(player_position)
	if new_block != current_block:
		previous_block = current_block
		current_block = new_block

# 从玩家系统获取位置（占位符）
func get_player_position_from_system() -> Vector2:
	# 在实际项目中，这里应该从玩家控制器获取真实位置
	# return PlayerController.get_position()
	return player_position

# 检测快速移动
func _detect_fast_movement() -> void:
	var speed = player_velocity.length()
	var was_moving_fast = is_moving_fast
	
	is_moving_fast = speed > FAST_MOVEMENT_THRESHOLD
	
	if is_moving_fast and not was_moving_fast:
		emit_signal("fast_movement_detected", player_velocity)

# 更新区块停留计时器
func _update_stay_timers() -> void:
	# 更新当前区块的停留时间
	if not stay_timers.has(current_block):
		stay_timers[current_block] = Time.get_ticks_msec()
	
	# 清理过期的计时器（只保留最近访问的区块）
	var blocks_to_remove = []
	for block in stay_timers:
		if block != current_block and (current_block - block).length() > 2:
			blocks_to_remove.append(block)
	
	for block in blocks_to_remove:
		stay_timers.erase(block)

# 执行智能加载策略
func _execute_smart_loading_strategy() -> void:
	if is_moving_fast:
		_execute_fast_movement_strategy()
	else:
		_execute_normal_movement_strategy()
	
	# 执行路径预测
	_execute_path_prediction()
	
	# 处理高优先级区块
	_handle_high_priority_blocks()

# 快速移动策略
func _execute_fast_movement_strategy() -> void:
	# 只加载最低细节级别的资源
	var nearby_blocks = _get_nearby_blocks(1)  # 只加载相邻区块
	
	for block_pos in nearby_blocks:
		if world_streaming_manager.get_block_state(block_pos) == world_streaming_manager.BlockState.UNLOADED:
			# 强制加载但使用最低细节级别
			world_streaming_manager.force_load_block(block_pos)
			_set_block_low_detail(block_pos)

# 正常移动策略
func _execute_normal_movement_strategy() -> void:
	# 优先加载玩家周围区块
	var surrounding_blocks = _get_surrounding_blocks(2)  # 加载2格范围内的区块
	
	for block_pos in surrounding_blocks:
		if world_streaming_manager.get_block_state(block_pos) == world_streaming_manager.BlockState.UNLOADED:
			world_streaming_manager.force_load_block(block_pos)

# 路径预测
func _execute_path_prediction() -> void:
	# 基于移动历史预测未来路径
	var predicted_path = _predict_future_path(PREDICTION_LOOKAHEAD_BLOCKS)
	
	for block_pos in predicted_path:
		if world_streaming_manager.get_block_state(block_pos) == world_streaming_manager.BlockState.UNLOADED:
			# 提前加载预测路径上的区块
			world_streaming_manager.force_load_block(block_pos)

# 预测未来路径
func _predict_future_path(lookahead: int) -> Array:
	var predicted_blocks = []
	
	if movement_history.size() < 2:
		return predicted_blocks
	
	# 计算移动方向
	var direction = player_position - movement_history[movement_history.size() - 2]
	if direction.length() == 0:
		return predicted_blocks
	
	direction = direction.normalized()
	
	# 预测未来位置
	var current_world_pos = player_position
	for i in range(lookahead):
		current_world_pos += direction * world_streaming_manager.BLOCK_SIZE.x
		var predicted_block = world_streaming_manager._world_to_block_coord(current_world_pos)
		predicted_blocks.append(predicted_block)
	
	return predicted_blocks

# 处理高优先级区块
func _handle_high_priority_blocks() -> void:
	# 确保高优先级区块被优先加载
	for block_pos in high_priority_blocks:
		if world_streaming_manager.get_block_state(block_pos) == world_streaming_manager.BlockState.UNLOADED:
			# 设置高优先级并强制加载
			_set_block_high_priority(block_pos)
			world_streaming_manager.force_load_block(block_pos)

# 获取附近区块
func _get_nearby_blocks(radius: int) -> Array:
	var blocks = []
	var center_block = current_block
	
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			blocks.append(Vector2i(center_block.x + x, center_block.y + y))
	
	return blocks

# 获取周围区块
func _get_surrounding_blocks(radius: int) -> Array:
	return _get_nearby_blocks(radius)

# 设置区块为低细节级别
func _set_block_low_detail(block_pos: Vector2i) -> void:
	# 在实际项目中，这里会设置LOD级别为最低
	# world_streaming_manager.set_block_lod_level(block_pos, 0)
	pass

# 设置区块为高优先级
func _set_block_high_priority(block_pos: Vector2i) -> void:
	# 在实际项目中，这里会提高区块的加载优先级
	# world_streaming_manager.set_block_priority(block_pos, 1.0)
	pass

# 标记重要区块（供外部系统调用）
func mark_important_block(block_pos: Vector2i, priority: float = 1.0) -> void:
	high_priority_blocks[block_pos] = priority
	emit_signal("important_block_marked", block_pos, priority)

# 取消重要区块标记
func unmark_important_block(block_pos: Vector2i) -> void:
	if high_priority_blocks.has(block_pos):
		high_priority_blocks.erase(block_pos)

# 检查是否应该卸载区块（防抖机制）
func should_unload_block(block_pos: Vector2i) -> bool:
	if not stay_timers.has(block_pos):
		return true
	
	var stay_time = Time.get_ticks_msec() - stay_timers[block_pos]
	return stay_time >= MIN_STAY_TIME_MS

# 获取玩家当前位置
func get_current_player_position() -> Vector2:
	return player_position

# 获取玩家当前区块
func get_current_player_block() -> Vector2i:
	return current_block

# 获取玩家速度
func get_player_velocity() -> Vector2:
	return player_velocity

# 检查是否在快速移动
func is_player_moving_fast() -> bool:
	return is_moving_fast

# 快速移动检测信号处理
func _on_fast_movement_detected(velocity: Vector2) -> void:
	print("Fast movement detected: ", velocity.length(), " pixels/second")
	# 可以在这里触发特定的优化策略

# 重要区块标记信号处理
func _on_important_block_marked(block_position: Vector2i, priority: float) -> void:
	print("Important block marked: ", block_position, " with priority: ", priority)
	# 确保重要区块立即开始加载
	if world_streaming_manager.get_block_state(block_position) == world_streaming_manager.BlockState.UNLOADED:
		world_streaming_manager.force_load_block(block_position)