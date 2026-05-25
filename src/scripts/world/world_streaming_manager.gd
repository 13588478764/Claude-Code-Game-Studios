## WorldStreamingManager (区域加载版 - 新版)
## 世界流式加载管理器
##
## 负责管理无缝世界流式加载和区域的动态加载/卸载。
##
## 主要功能：
## - 根据玩家位置动态加载/卸载区域
## - 管理区域场景实例
## - 追踪玩家所在区域
## - 优化内存使用和性能
##
## ⚠️ 冲突说明 (polish-fixlist-2026-05-25 #5):
## src/scripts/world_streaming_manager.gd (像素区块版, 708 行) 与本文件功能重叠但 API 完全不同。
## 旧版被 player_position_tracker / memory_outpimizer 通过节点路径调用; 本新版被 tests/integration 通过 load() 调用。
## 待 lead-programmer 决策合并/废弃 (本文件已去掉 class_name 以消除 Godot 全局符号冲突)。

extends Node

# class_name WorldStreamingManager  # 暂禁用 - 避免与旧版冲突, tests 用 load(path) 不依赖此符号

# ============================================================================
# 常量定义
# ============================================================================

## 加载距离倍数（屏幕宽度）
const LOAD_DISTANCE_MULTIPLIER: float = 1.5

## 区域大小（像素）
const REGION_SIZE: int = 2048

## 玩家检测半径（像素）
const PLAYER_DETECTION_RADIUS: int = 50

## 卸载检查间隔（秒）
const UNLOAD_CHECK_INTERVAL: float = 5.0

## 卸载距离倍数
const UNLOAD_DISTANCE_MULTIPLIER: float = 2.0

## 卸载时间阈值（毫秒）
const UNLOAD_TIME_THRESHOLD: int = 30000

## 区域场景路径前缀
const REGION_SCENE_PATH_PREFIX: String = "res://src/scenes/regions/"

## 区域场景路径后缀
const REGION_SCENE_PATH_SUFFIX: String = ".tscn"

# ============================================================================
# 信号定义
# ============================================================================

## 区域加载信号
signal region_loaded(region_id: String)

## 区域卸载信号
signal region_unloaded(region_id: String)

## 玩家区域变化信号
signal player_region_changed(from_region: String, to_region: String)

# ============================================================================
# 成员变量
# ============================================================================

## 所有注册的区域字典
var regions: Dictionary = {}

## 当前玩家所在区域ID
var current_player_region: String = ""

## 玩家节点引用
var player_node: Node2D = null

## 屏幕大小
var screen_size: Vector2 = Vector2.ZERO

## 区域加载距离
var load_distance: float = 0.0

## 卸载检查计时器
var unload_timer: Timer = null

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化世界流式加载管理器
func _ready() -> void:
	screen_size = DisplayServer.window_get_size()
	load_distance = screen_size.x * LOAD_DISTANCE_MULTIPLIER
	print("世界流式加载管理器初始化，加载距离: ", load_distance)
	
	# 设置卸载检查计时器
	unload_timer = Timer.new()
	unload_timer.wait_time = UNLOAD_CHECK_INTERVAL
	unload_timer.timeout.connect(_check_regions_for_unload)
	add_child(unload_timer)
	unload_timer.start()

# ============================================================================
# 公共方法
# ============================================================================

## 设置玩家节点用于追踪
func set_player_node(player: Node2D) -> void:
	"""
	设置玩家节点
	
	参数：
	- player: 玩家节点
	"""
	player_node = player

## 注册区域
func register_region(region_id: String, position: Vector2) -> void:
	"""
	注册一个区域
	
	参数：
	- region_id: 区域ID
	- position: 区域位置
	"""
	if not regions.has(region_id):
		regions[region_id] = RegionData.new(region_id, position)
		print("注册区域: ", region_id, " 位置: ", position)
	else:
		print("区域已注册: ", region_id)

## 更新流式加载状态
func update_streaming() -> void:
	"""更新区域流式加载状态"""
	if not player_node:
		return
	
	var player_pos: Vector2 = player_node.global_position
	var player_region_id: String = _get_region_id_at_position(player_pos)
	
	# 检查玩家是否进入新区域
	if player_region_id != current_player_region:
		var old_region: String = current_player_region
		current_player_region = player_region_id
		player_region_changed.emit(old_region, player_region_id)
		print("玩家进入新区域: ", player_region_id)
	
	# 获取加载范围内的区域
	var regions_to_load: Array = _get_regions_in_range(player_pos, load_distance)
	
	# 加载必要的区域
	for region_id in regions_to_load:
		if regions.has(region_id):
			_load_region_if_needed(region_id)
	
	# 更新附近区域的访问时间
	for region_id in regions_to_load:
		if regions.has(region_id):
			regions[region_id].last_access_time = Time.get_ticks_msec()

## 获取加载距离
func get_load_distance() -> float:
	"""
	获取区域加载距离
	
	返回：
	- 加载距离（像素）
	"""
	return load_distance

## 设置加载距离倍数
func set_load_distance_multiplier(multiplier: float) -> void:
	"""
	设置加载距离倍数
	
	参数：
	- multiplier: 倍数值
	"""
	if multiplier > 0:
		load_distance = screen_size.x * multiplier

## 获取区域信息
func get_region_info(region_id: String) -> Dictionary:
	"""
	获取指定区域的信息
	
	参数：
	- region_id: 区域ID
	
	返回：
	- 区域信息字典
	"""
	if regions.has(region_id):
		var region: RegionData = regions[region_id]
		return {
			"id": region.id,
			"position": region.position,
			"loaded": region.loaded,
			"last_access": region.last_access_time
		}
	return {}

## 强制加载指定区域
func force_load_region(region_id: String) -> bool:
	"""
	强制加载指定区域
	
	参数：
	- region_id: 区域ID
	
	返回：
	- 加载是否成功
	"""
	if regions.has(region_id):
		_load_region_if_needed(region_id)
		return true
	return false

## 强制卸载指定区域
func force_unload_region(region_id: String) -> bool:
	"""
	强制卸载指定区域
	
	参数：
	- region_id: 区域ID
	
	返回：
	- 卸载是否成功
	"""
	if regions.has(region_id):
		_unload_region(region_id)
		return true
	return false

## 获取所有已加载的区域
func get_loaded_regions() -> Array:
	"""
	获取所有已加载的区域
	
	返回：
	- 已加载区域ID列表
	"""
	var loaded: Array = []
	for region_id in regions:
		if regions[region_id].loaded:
			loaded.append(region_id)
	return loaded

## 获取玩家当前所在区域
func get_player_current_region() -> String:
	"""
	获取玩家当前所在区域
	
	返回：
	- 玩家所在区域ID
	"""
	return current_player_region

# ============================================================================
# 私有方法
# ============================================================================

## 区域数据类
class RegionData:
	## 区域ID
	var id: String = ""
	
	## 区域位置
	var position: Vector2 = Vector2.ZERO
	
	## 区域场景实例
	var scene_instance: Node2D = null
	
	## 是否已加载
	var loaded: bool = false
	
	## 最后访问时间（毫秒）
	var last_access_time: int = 0
	
	## 初始化区域数据
	func _init(p_id: String, p_position: Vector2) -> void:
		id = p_id
		position = p_position
		scene_instance = null
		loaded = false
		last_access_time = Time.get_ticks_msec()

## 获取指定位置所在的区域ID
func _get_region_id_at_position(pos: Vector2) -> String:
	"""
	获取指定位置所在的区域ID
	
	参数：
	- pos: 位置坐标
	
	返回：
	- 区域ID
	"""
	var region_x: int = int(floor(pos.x / REGION_SIZE))
	var region_y: int = int(floor(pos.y / REGION_SIZE))
	return "region_%d_%d" % [region_x, region_y]

## 获取指定范围内的所有区域
func _get_regions_in_range(center_pos: Vector2, range: float) -> Array:
	"""
	获取指定范围内的所有区域
	
	参数：
	- center_pos: 中心位置
	- range: 范围距离
	
	返回：
	- 区域ID列表
	"""
	var regions_list: Array = []
	
	# 计算范围内的区域数量
	var region_range: int = int(ceil(range / REGION_SIZE))
	
	# 获取中心区域
	var center_region_x: int = int(floor(center_pos.x / REGION_SIZE))
	var center_region_y: int = int(floor(center_pos.y / REGION_SIZE))
	
	# 添加范围内的所有区域
	for x in range(center_region_x - region_range, center_region_x + region_range + 1):
		for y in range(center_region_y - region_range, center_region_y + region_range + 1):
			var region_id: String = "region_%d_%d" % [x, y]
			regions_list.append(region_id)
	
	return regions_list

## 加载区域（如果需要）
func _load_region_if_needed(region_id: String) -> void:
	"""
	加载指定区域（如果还未加载）
	
	参数：
	- region_id: 区域ID
	"""
	if not regions.has(region_id):
		return
	
	var region: RegionData = regions[region_id]
	if region.loaded:
		return
	
	# 尝试加载区域场景
	var region_scene_path: String = REGION_SCENE_PATH_PREFIX + region_id + REGION_SCENE_PATH_SUFFIX
	var region_scene: PackedScene = load(region_scene_path)
	
	if region_scene:
		region.scene_instance = region_scene.instantiate() as Node2D
		if region.scene_instance:
			region.scene_instance.position = region.position
			get_parent().add_child(region.scene_instance)
			region.loaded = true
			region.last_access_time = Time.get_ticks_msec()
			region_loaded.emit(region_id)
			print("加载区域: ", region_id)
		else:
			push_error("无法实例化区域场景: ", region_scene_path)
	else:
		push_warning("无法加载区域场景: ", region_scene_path)

## 卸载区域
func _unload_region(region_id: String) -> void:
	"""
	卸载指定区域
	
	参数：
	- region_id: 区域ID
	"""
	if not regions.has(region_id):
		return
	
	var region: RegionData = regions[region_id]
	if not region.loaded or not region.scene_instance:
		return
	
	# 移除场景实例
	if is_instance_valid(region.scene_instance):
		region.scene_instance.queue_free()
	
	region.loaded = false
	region.scene_instance = null
	region_unloaded.emit(region_id)
	print("卸载区域: ", region_id)

## 检查并卸载不需要的区域
func _check_regions_for_unload() -> void:
	"""检查并卸载距离玩家过远且长时间未访问的区域"""
	if not player_node:
		return
	
	var player_pos: Vector2 = player_node.global_position
	var current_time: int = Time.get_ticks_msec()
	
	# 卸载距离过远且长时间未访问的区域
	var unload_distance: float = load_distance * UNLOAD_DISTANCE_MULTIPLIER
	
	for region_id in regions:
		var region: RegionData = regions[region_id]
		
		# 跳过未加载的区域
		if not region.loaded:
			continue
		
		# 计算到玩家的距离
		var region_center: Vector2 = region.position + Vector2(REGION_SIZE / 2, REGION_SIZE / 2)
		var distance_to_player: float = player_pos.distance_to(region_center)
		
		# 如果距离过远且长时间未访问，则卸载
		if distance_to_player > unload_distance and \
		   (current_time - region.last_access_time) > UNLOAD_TIME_THRESHOLD:
			_unload_region(region_id)