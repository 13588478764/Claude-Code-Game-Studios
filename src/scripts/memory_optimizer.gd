# MemoryOptimizer - 内存优化器
#
# 负责资源优先级加载、LOD系统、对象池和性能预算管理
# 符合 ADR-001 架构决策：组件化设计，利用 PC 平台硬件优势
#
# 信号:
#   - performance_warning(warning_type, severity)
#   - lod_level_changed(block_position, old_lod, new_lod)

extends Node

class_name MemoryOptimizer

# ============================================================================
# 依赖注入
# ============================================================================

@onready var world_streaming_manager = $WorldStreamingManager
@onready var player_position_tracker = $PlayerPositionTracker

# ============================================================================
# 常量定义 - 资源优先级
# ============================================================================

const PRIORITY_TERRAIN: float = 1.0      # 背景地形（最高优先级）
const PRIORITY_BUILDINGS: float = 0.8    # 建筑物
const PRIORITY_NPCS: float = 0.6         # NPC
const PRIORITY_EFFECTS: float = 0.4      # 特效（最低优先级）

# ============================================================================
# 常量定义 - LOD 配置
# ============================================================================

const MAX_LOD_LEVELS: int = 4
const LOD_DISTANCE_THRESHOLDS: Array = [0, 500, 1000, 2000]

# ============================================================================
# 常量定义 - 性能预算
# ============================================================================

const TARGET_FPS: int = 60
const MAX_FRAME_TIME_MS: float = 1000.0 / TARGET_FPS
const MAX_ALLOWED_FRAME_DROP_PERCENTAGE: float = 10.0

# ============================================================================
# 常量定义 - 其他
# ============================================================================

const LOG_PREFIX: String = "[MemoryOptimizer]"
const MIN_RETAINED_BLOCKS: int = 4
const MIN_RETAINED_POOL_OBJECTS: int = 5

# ============================================================================
# 信号定义
# ============================================================================

## 性能警告信号
signal performance_warning(warning_type: String, severity: int)

## LOD 级别变更信号
signal lod_level_changed(block_position: Vector2i, old_lod: int, new_lod: int)

# ============================================================================
# 成员变量 - 硬件配置
# ============================================================================

var hardware_tier: int = 0
var available_memory_mb: float = 0.0
var cpu_cores: int = 0
var gpu_performance: float = 0.0

# ============================================================================
# 成员变量 - 对象池和性能监控
# ============================================================================

var object_pools: Dictionary = {}
var frame_times: Array = []
var memory_usage_history: Array = []
var loading_times: Array = []
var debug_enabled: bool = true

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化
func _ready() -> void:
	# 检测硬件配置
	_detect_hardware_configuration()
	
	# 初始化对象池
	_initialize_object_pools()
	
	# 连接信号
	connect("performance_warning", Callable(self, "_on_performance_warning"))
	connect("lod_level_changed", Callable(self, "_on_lod_level_changed"))
	
	# 初始化性能监控数组
	frame_times.resize(60)
	memory_usage_history.resize(60)
	loading_times.resize(30)
	
	if debug_enabled:
		print("%s 初始化完成 (硬件等级: %d)" % [LOG_PREFIX, hardware_tier])

func _process(delta: float) -> void:
	# 监控性能
	_monitor_performance(delta)
	
	# 更新LOD级别
	_update_lod_levels()
	
	# 管理对象池
	_manage_object_pools()

# 检测硬件配置
func _detect_hardware_configuration() -> void:
	# 获取系统信息
	var system_info = OS.get_system_memory_info()
	available_memory_mb = system_info["available"] / (1024 * 1024)
	cpu_cores = OS.get_processor_count()
	
	# 估算GPU性能（简化版本）
	gpu_performance = _estimate_gpu_performance()
	
	# 根据硬件配置确定硬件等级
	if available_memory_mb < 2000 or cpu_cores < 4:
		hardware_tier = 0  # 低配
	elif available_memory_mb < 4000 or cpu_cores < 8:
		hardware_tier = 1  # 中配
	else:
		hardware_tier = 2  # 高配
	
	# 根据硬件等级调整配置参数
	_adjust_configuration_for_hardware_tier()

# 估算GPU性能（简化版本）
func _estimate_gpu_performance() -> float:
	# 在实际项目中，这里可能需要更复杂的检测逻辑
	# 或者使用第三方库来检测GPU型号和性能
	return 1.0  # 默认值

# 根据硬件等级调整配置
func _adjust_configuration_for_hardware_tier() -> void:
	match hardware_tier:
		0:  # 低配
			world_streaming_manager.MAX_LOADED_BLOCKS = 8
			world_streaming_manager.BLOCK_SIZE = Vector2(1024, 1024)
		1:  # 中配
			world_streaming_manager.MAX_LOADED_BLOCKS = 12
			world_streaming_manager.BLOCK_SIZE = Vector2(2048, 2048)
		2:  # 高配
			world_streaming_manager.MAX_LOADED_BLOCKS = 16
			world_streaming_manager.BLOCK_SIZE = Vector2(2048, 2048)

# 初始化对象池
func _initialize_object_pools() -> void:
	# 创建常见资源类型的对象池
	object_pools["terrain"] = []
	object_pools["buildings"] = []
	object_pools["npcs"] = []
	object_pools["effects"] = []
	
	# 预分配一些对象（根据硬件等级）
	var pool_sizes = [10, 20, 30][hardware_tier]
	for resource_type in object_pools:
		for i in range(pool_sizes):
			var pooled_object = _create_pooled_object(resource_type)
			object_pools[resource_type].append(pooled_object)

# 创建池化对象
func _create_pooled_object(resource_type: String) -> Node:
	var node = Node2D.new()
	node.name = "Pooled_" + resource_type + "_" + str(OS.get_unix_time())
	# 在实际项目中，这里会根据资源类型创建具体的对象
	return node

# 监控性能
func _monitor_performance(delta: float) -> void:
	# 记录帧时间
	var frame_time_ms = delta * 1000.0
	frame_times.pop_front()
	frame_times.append(frame_time_ms)
	
	# 记录内存使用
	var current_memory = world_streaming_manager.get_memory_usage()["current"]
	memory_usage_history.pop_front()
	memory_usage_history.append(current_memory)
	
	# 检查性能是否超出预算
	if frame_time_ms > MAX_FRAME_TIME_MS * (1.0 + MAX_ALLOWED_FRAME_DROP_PERCENTAGE / 100.0):
		emit_signal("performance_warning", "frame_time_exceeded", 1)
	
	# 检查内存使用是否过高
	if current_memory > world_streaming_manager.get_memory_usage()["limit"] * 0.9:
		emit_signal("performance_warning", "memory_usage_high", 2)

# 更新LOD级别
func _update_lod_levels() -> void:
	var player_pos = player_position_tracker.get_current_player_position()
	
	# 遍历所有已加载的区块
	for block_pos in world_streaming_manager.get_loaded_blocks():
		var block_world_pos = world_streaming_manager._block_to_world_coord(block_pos)
		var distance = player_pos.distance_to(block_world_pos)
		
		# 计算新的LOD级别
		var new_lod = _calculate_lod_level(distance)
		
		# 如果LOD级别发生变化，更新区块
		if _get_block_lod_level(block_pos) != new_lod:
			_set_block_lod_level(block_pos, new_lod)
			emit_signal("lod_level_changed", block_pos, _get_block_lod_level(block_pos), new_lod)

# 计算LOD级别
func _calculate_lod_level(distance: float) -> int:
	for i in range(LOD_DISTANCE_THRESHOLDS.size() - 1, -1, -1):
		if distance >= LOD_DISTANCE_THRESHOLDS[i]:
			return min(i, MAX_LOD_LEVELS - 1)
	return 0

# 获取区块LOD级别
func _get_block_lod_level(block_pos: Vector2i) -> int:
	# 在实际项目中，这里会从区块数据中获取LOD级别
	# return world_streaming_manager.loaded_blocks[block_pos].lod_level
	return 0

# 设置区块LOD级别
func _set_block_lod_level(block_pos: Vector2i, lod_level: int) -> void:
	# 在实际项目中，这里会更新区块的LOD级别
	# world_streaming_manager.loaded_blocks[block_pos].lod_level = lod_level
	# 并触发相应的资源切换
	pass

# 管理对象池
func _manage_object_pools() -> void:
	# 清理未使用的对象
	for resource_type in object_pools:
		var pool = object_pools[resource_type]
		var unused_objects = []
		
		for obj in pool:
			if not obj.is_inside_tree():
				unused_objects.append(obj)
		
		# 如果未使用的对象过多，清理一部分
		if unused_objects.size() > pool.size() * 0.5:
			for i in range(min(5, unused_objects.size())):
				var obj = unused_objects[i]
				pool.erase(obj)
				obj.queue_free()

# 获取资源加载优先级
func get_resource_priority(resource_type: String) -> float:
	match resource_type:
		"terrain":
			return PRIORITY_TERRAIN
		"buildings":
			return PRIORITY_BUILDINGS
		"npcs":
			return PRIORITY_NPCS
		"effects":
			return PRIORITY_EFFECTS
		_:
			return 0.5  # 默认优先级

# 从对象池获取对象
func acquire_from_pool(resource_type: String) -> Node:
	if not object_pools.has(resource_type):
		return null
	
	var pool = object_pools[resource_type]
	if pool.is_empty():
		# 池中没有可用对象，创建新对象
		return _create_pooled_object(resource_type)
	
	# 从池中获取对象
	return pool.pop_front()

# 将对象返回到池中
func release_to_pool(resource_type: String, obj: Node) -> void:
	if not object_pools.has(resource_type):
		return
	
	# 重置对象状态
	obj.position = Vector2.ZERO
	obj.visible = false
	
	# 返回到池中
	object_pools[resource_type].append(obj)

# 获取当前性能统计数据
func get_performance_stats() -> Dictionary:
	var avg_frame_time = 0.0
	var frame_count = 0
	for time in frame_times:
		if time > 0:
			avg_frame_time += time
			frame_count += 1
	
	if frame_count > 0:
		avg_frame_time /= frame_count
	
	var avg_memory_usage = 0.0
	var memory_count = 0
	for memory in memory_usage_history:
		if memory > 0:
			avg_memory_usage += memory
			memory_count += 1
	
	if memory_count > 0:
		avg_memory_usage /= memory_count
	
	return {
		"average_frame_time_ms": avg_frame_time,
		"current_fps": 1000.0 / avg_frame_time if avg_frame_time > 0 else 0,
		"average_memory_usage_mb": avg_memory_usage,
		"hardware_tier": hardware_tier,
		"available_memory_mb": available_memory_mb
	}

# 强制垃圾回收
func force_garbage_collection() -> void:
	# 在Godot中，可以调用以下方法强制垃圾回收
	GC.collect()

# 性能警告处理
func _on_performance_warning(warning_type: String, severity: int) -> void:
	print("Performance warning: ", warning_type, " (severity: ", severity, ")")
	
	# 根据警告类型采取相应措施
	match warning_type:
		"frame_time_exceeded":
			# 降低LOD级别或减少同时加载的区块数
			_reduce_quality_settings()
		"memory_usage_high":
			# 强制卸载一些区块或清理对象池
			_free_memory_resources()

# LOD级别变更处理
func _on_lod_level_changed(block_position: Vector2i, old_lod: int, new_lod: int) -> void:
	print("LOD level changed for block ", block_position, ": ", old_lod, " -> ", new_lod)
	# 可以在这里记录LOD变更日志或触发其他系统

# 降低质量设置
func _reduce_quality_settings() -> void:
	# 临时降低最大加载区块数
	world_streaming_manager.max_memory_limit = max(4, world_streaming_manager.max_memory_limit - 2)
	
	# 降低LOD距离阈值
	for i in range(LOD_DISTANCE_THRESHOLDS.size()):
		LOD_DISTANCE_THRESHOLDS[i] = int(LOD_DISTANCE_THRESHOLDS[i] * 0.8)

# 释放内存资源
func _free_memory_resources() -> void:
	# 强制卸载最远的区块
	var loaded_blocks = world_streaming_manager.get_loaded_blocks()
	if loaded_blocks.size() > 4:  # 保留至少4个区块
		var player_block = player_position_tracker.get_current_player_block()
		loaded_blocks.sort_custom(func(a, b):
			var dist_a = (a - player_block).length()
			var dist_b = (b - player_block).length()
			return dist_a > dist_b  # 远的在前面
		)
		
		# 卸载最远的区块
		for i in range(min(2, loaded_blocks.size() - 4)):
			world_streaming_manager.force_unload_block(loaded_blocks[i])
	
	# 清理对象池
	for resource_type in object_pools:
		var pool = object_pools[resource_type]
		if pool.size() > 5:  # 保留至少5个对象
			for j in range(pool.size() - 5):
				var obj = pool.pop_back()
				obj.queue_free()