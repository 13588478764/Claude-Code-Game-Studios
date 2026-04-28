extends Node

# 世界流式加载管理器 - 负责处理大型开放世界的动态加载和卸载
# 符合ADR-001架构决策：使用Godot 4.6 Scene-Node架构，组件化设计

# 区块配置
const BLOCK_SIZE = Vector2(2048, 2048)  # 2048x2048像素区块
const MAX_LOADED_BLOCKS = 16  # 最多同时加载16个区块（4x4网格）
const LOAD_DISTANCE_MULTIPLIER = 1.5  # 加载距离倍数（1.5个屏幕宽度）
const UNLOAD_DISTANCE_MULTIPLIER = 3.0  # 卸载距离倍数（3.0个屏幕宽度）

# 区块状态枚举
enum BlockState {
	UNLOADED,
	LOADING,
	LOADED,
	UNLOADING
}

# 区块数据结构
class BlockData:
	var position: Vector2i  # 区块坐标（整数坐标）
	var state: int = BlockState.UNLOADED  # 当前状态
	var scene_instance: Node = null  # 场景实例引用
	var load_priority: float = 0.0  # 加载优先级
	var last_access_time: float = 0.0  # 最后访问时间
	
	func _init(pos: Vector2i):
		position = pos
		last_access_time = Time.get_ticks_msec()

# 玩家位置追踪
var player_position: Vector2 = Vector2.ZERO
var screen_width: int = 1920  # 默认屏幕宽度

# 区块管理
var loaded_blocks: Dictionary = {}  # 已加载区块字典 {Vector2i: BlockData}
var loading_queue: Array = []  # 加载队列
var unloading_queue: Array = []  # 卸载队列

# 内存管理
var current_memory_usage: float = 0.0  # 当前内存使用量（MB）
var max_memory_limit: float = 0.0  # 最大内存限制（MB）

# 信号：区块加载完成
signal block_loaded(block_position: Vector2i)
# 信号：区块卸载完成
signal block_unloaded(block_position: Vector2i)
# 信号：加载进度更新
signal loading_progress(current: int, total: int)

func _ready() -> void:
	# 初始化内存限制（基于可用内存）
	_initialize_memory_limit()
	
	# 连接信号
	connect("block_loaded", _on_block_loaded)
	connect("block_unloaded", _on_block_unloaded)

func _process(delta: float) -> void:
	# 更新玩家位置（实际项目中应从玩家系统获取）
	_update_player_position()
	
	# 检查需要加载/卸载的区块
	_check_loading_unloading()
	
	# 处理加载队列
	_process_loading_queue()
	
	# 处理卸载队列
	_process_unloading_queue()

# 初始化内存限制
func _initialize_memory_limit() -> void:
	# 获取系统可用内存（MB）
	var system_info = OS.get_system_memory_info()
	max_memory_limit = min(system_info["available"] / (1024 * 1024), 2000.0)  # 限制最大2GB
	
	# 根据内存限制调整最大加载区块数
	var estimated_block_memory = 25.0  # 估算每个区块平均占用25MB
	var calculated_max_blocks = int(max_memory_limit / estimated_block_memory)
	max_memory_limit = min(calculated_max_blocks, MAX_LOADED_BLOCKS)

# 更新玩家位置（占位符，实际应从玩家系统获取）
func _update_player_position() -> void:
	# 在实际项目中，这里应该从玩家控制器获取真实位置
	# player_position = PlayerController.get_position()
	pass

# 检查需要加载/卸载的区块
func _check_loading_unloading() -> void:
	# 计算加载和卸载距离
	var load_distance = screen_width * LOAD_DISTANCE_MULTIPLIER
	var unload_distance = screen_width * UNLOAD_DISTANCE_MULTIPLIER
	
	# 获取玩家所在的区块坐标
	var player_block = _world_to_block_coord(player_position)
	
	# 检查周围区块（4x4网格范围）
	for x in range(-2, 3):
		for y in range(-2, 3):
			var block_pos = Vector2i(player_block.x + x, player_block.y + y)
			var world_pos = _block_to_world_coord(block_pos)
			var distance = player_position.distance_to(world_pos)
			
			if distance <= load_distance:
				# 需要加载此区块
				if not loaded_blocks.has(block_pos) or loaded_blocks[block_pos].state == BlockState.UNLOADED:
					_queue_block_for_loading(block_pos)
			elif distance > unload_distance:
				# 需要卸载此区块
				if loaded_blocks.has(block_pos) and loaded_blocks[block_pos].state == BlockState.LOADED:
					_queue_block_for_unloading(block_pos)

# 将世界坐标转换为区块坐标
func _world_to_block_coord(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / BLOCK_SIZE.x)),
		int(floor(world_pos.y / BLOCK_SIZE.y))
	)

# 将区块坐标转换为世界坐标
func _block_to_world_coord(block_pos: Vector2i) -> Vector2:
	return Vector2(
		block_pos.x * BLOCK_SIZE.x + BLOCK_SIZE.x / 2,
		block_pos.y * BLOCK_SIZE.y + BLOCK_SIZE.y / 2
	)

# 将区块加入加载队列
func _queue_block_for_loading(block_pos: Vector2i) -> void:
	if not loading_queue.has(block_pos):
		loading_queue.append(block_pos)

# 将区块加入卸载队列
func _queue_block_for_unloading(block_pos: Vector2i) -> void:
	if not unloading_queue.has(block_pos):
		unloading_queue.append(block_pos)

# 处理加载队列
func _process_loading_queue() -> void:
	if loading_queue.is_empty():
		return
	
	# 检查是否达到最大加载区块数限制
	if loaded_blocks.size() >= max_memory_limit:
		return
	
	# 获取下一个要加载的区块
	var next_block = loading_queue.pop_front()
	
	# 创建区块数据
	var block_data = BlockData.new(next_block)
	block_data.state = BlockState.LOADING
	loaded_blocks[next_block] = block_data
	
	# 异步加载区块场景
	_load_block_async(next_block)

# 异步加载区块
func _load_block_async(block_pos: Vector2i) -> void:
	# 在后台线程中加载场景
	var thread = Thread.new()
	thread.start(_load_block_thread.bind(block_pos))

# 后台线程加载函数
func _load_block_thread(block_pos: Vector2i) -> void:
	var result = _perform_block_load(block_pos)
	if result.success:
		call_deferred("_on_block_load_completed", block_pos, result.scene_instance)
	else:
		call_deferred("_on_block_load_failed", block_pos, result.error_message)

# 执行区块加载
func _perform_block_load(block_pos: Vector2i) -> Dictionary:
	var result = {"success": false, "error_message": "", "scene_instance": null}
	
	# 构建区块场景路径
	var block_path = "res://scenes/world/blocks/block_" + str(block_pos.x) + "_" + str(block_pos.y) + ".tscn"
	
	# 检查文件是否存在
	var dir = Directory.new()
	if not dir.file_exists(block_path):
		# 如果区块文件不存在，创建一个空的区块场景
		result.scene_instance = _create_empty_block_scene(block_pos)
		result.success = true
		return result
	
	# 异步加载场景
	var loader = ResourceLoader.load_interactive(block_path)
	if loader == null:
		result.error_message = "Failed to create loader for: " + block_path
		return result
	
	# 加载场景资源
	while loader.poll() == ERR_BUSY:
		# 继续加载...
		pass
	
	var resource = loader.get_resource()
	if resource == null:
		result.error_message = "Failed to load resource: " + block_path
		return result
	
	# 实例化场景
	var scene_instance = resource.instantiate()
	if scene_instance == null:
		result.error_message = "Failed to instantiate scene: " + block_path
		return result
	
	# 设置区块位置
	scene_instance.position = _block_to_world_coord(block_pos)
	
	result.scene_instance = scene_instance
	result.success = true
	return result

# 创建空的区块场景
func _create_empty_block_scene(block_pos: Vector2i) -> Node:
	var empty_node = Node2D.new()
	empty_node.name = "EmptyBlock_" + str(block_pos.x) + "_" + str(block_pos.y)
	empty_node.position = _block_to_world_coord(block_pos)
	return empty_node

# 区块加载完成回调
func _on_block_load_completed(block_pos: Vector2i, scene_instance: Node) -> void:
	if not loaded_blocks.has(block_pos):
		return
	
	var block_data = loaded_blocks[block_pos]
	block_data.scene_instance = scene_instance
	block_data.state = BlockState.LOADED
	block_data.last_access_time = Time.get_ticks_msec()
	
	# 将场景添加到世界中
	add_child(scene_instance)
	
	# 发出区块加载完成信号
	emit_signal("block_loaded", block_pos)
	
	# 更新内存使用量
	current_memory_usage += _estimate_scene_memory_usage(scene_instance)

# 区块加载失败回调
func _on_block_load_failed(block_pos: Vector2i, error_message: String) -> void:
	print("Block load failed: ", block_pos, " - ", error_message)
	
	# 移除失败的区块数据
	if loaded_blocks.has(block_pos):
		loaded_blocks.erase(block_pos)
	
	# 可以选择重试或使用占位符

# 处理卸载队列
func _process_unloading_queue() -> void:
	if unloading_queue.is_empty():
		return
	
	# 获取下一个要卸载的区块
	var next_block = unloading_queue.pop_front()
	
	if not loaded_blocks.has(next_block):
		return
	
	var block_data = loaded_blocks[next_block]
	if block_data.state != BlockState.LOADED:
		return
	
	# 标记为卸载中
	block_data.state = BlockState.UNLOADING
	
	# 异步卸载区块
	_unload_block_async(next_block)

# 异步卸载区块
func _unload_block_async(block_pos: Vector2i) -> void:
	# 在下一帧卸载（避免在_process中直接操作）
	call_deferred("_perform_block_unload", block_pos)

# 执行区块卸载
func _perform_block_unload(block_pos: Vector2i) -> void:
	if not loaded_blocks.has(block_pos):
		return
	
	var block_data = loaded_blocks[block_pos]
	if block_data.scene_instance != null:
		# 从世界中移除场景
		remove_child(block_data.scene_instance)
		
		# 释放场景实例
		block_data.scene_instance.queue_free()
		
		# 更新内存使用量
		current_memory_usage -= _estimate_scene_memory_usage(block_data.scene_instance)
	
	# 清理区块数据
	loaded_blocks.erase(block_pos)
	
	# 发出区块卸载完成信号
	emit_signal("block_unloaded", block_pos)

# 估算场景内存使用量
func _estimate_scene_memory_usage(scene: Node) -> float:
	# 这是一个简化的估算，实际项目中可能需要更精确的计算
	# 基于场景中的节点数量和资源类型进行估算
	var node_count = scene.get_child_count()
	return node_count * 0.1  # 假设每个节点占用0.1MB

# 获取区块状态
func get_block_state(block_pos: Vector2i) -> int:
	if loaded_blocks.has(block_pos):
		return loaded_blocks[block_pos].state
	return BlockState.UNLOADED

# 获取已加载区块列表
func get_loaded_blocks() -> Array:
	var blocks = []
	for pos in loaded_blocks:
		blocks.append(pos)
	return blocks

# 设置屏幕宽度（用于动态调整加载距离）
func set_screen_width(width: int) -> void:
	screen_width = width

# 设置玩家位置（供外部系统调用）
func set_player_position(pos: Vector2) -> void:
	player_position = pos

# 获取当前内存使用情况
func get_memory_usage() -> Dictionary:
	return {
		"current": current_memory_usage,
		"limit": max_memory_limit,
		"blocks_loaded": loaded_blocks.size()
	}

# 强制加载特定区块
func force_load_block(block_pos: Vector2i) -> void:
	if loaded_blocks.has(block_pos) and loaded_blocks[block_pos].state == BlockState.LOADED:
		return
	
	_queue_block_for_loading(block_pos)
	_process_loading_queue()

# 强制卸载特定区块
func force_unload_block(block_pos: Vector2i) -> void:
	if not loaded_blocks.has(block_pos) or loaded_blocks[block_pos].state != BlockState.LOADED:
		return
	
	_queue_block_for_unloading(block_pos)
	_process_unloading_queue()

# 区块加载完成信号处理
func _on_block_loaded(block_position: Vector2i) -> void:
	# 通知其他系统（如小地图系统）区块已加载
	# emit_signal("world_block_updated", block_position, true)

# 区块卸载完成信号处理
func _on_block_unloaded(block_position: Vector2i) -> void:
	# 通知其他系统（如小地图系统）区块已卸载
	# emit_signal("world_block_updated", block_position, false)