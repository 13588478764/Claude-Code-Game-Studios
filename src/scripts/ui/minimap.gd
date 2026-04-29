## Minimap
## 小地图系统实现
管理小地图的显示、玩家位置、朝向以及区域探索状态
##
## 主要功能：
## - 待补充

extends Node

class_name Minimap

# ============================================================================
# 常量定义
# ============================================================================

# ============================================================================
# 信号定义
# ============================================================================

# ============================================================================
# 成员变量
# ============================================================================

# ============================================================================
# 生命周期方法
# ============================================================================

# ============================================================================
# 公共方法
# ============================================================================

# ============================================================================
# 私有方法
# ============================================================================

# 信号定义
signal player_position_updated(position: Vector2)
signal minimap_expanded()
signal minimap_collapsed()

# 常量定义
const MINIMAP_SIZE = 150
const MINIMAP_MARGIN = 20
const EXPLORE_RADIUS = 50  # 探索半径（像素）

# 玩家相关属性
var player_node: Node2D = null
var player_last_position: Vector2 = Vector2.ZERO
var player_direction: float = 0.0  # 以弧度为单位

# 探索相关属性
var explored_areas: Array[Vector2] = []  # 已探索的位置
var current_region: String = ""
var exploration_percentage: float = 0.0

# UI元素
var minimap_container: ColorRect = null
var player_marker: TextureRect = null
var terrain_outline: TextureRect = null
var compass_ring: TextureRect = null

# 初始化
func _ready():
	setup_minimap()
	update_minimap_position()
	
	# 如果场景中有玩家节点，连接其位置更新信号
	if player_node == null:
		# 尝试查找玩家节点
		player_node = get_tree().get_first_node_in_group("player")
	
	if player_node:
		# 每帧更新玩家位置和朝向
		_process_player_update()

func setup_minimap():
	# 创建小地图容器
	minimap_container = ColorRect.new()
	minimap_container.color = Color(0.1, 0.1, 0.1, 0.6)  # 半透明深灰色背景
	minimap_container.size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	add_child(minimap_container)
	
	# 创建玩家标记
	player_marker = TextureRect.new()
	player_marker.texture = create_player_arrow_texture()
	player_marker.size = Vector2(16, 16)
	player_marker.pivot_offset = Vector2(8, 8)  # 设置中心点
	player_marker.position = Vector2(MINIMAP_SIZE/2, MINIMAP_SIZE/2)
	minimap_container.add_child(player_marker)
	
	# 创建地形轮廓（简化版本，实际项目中会根据当前区域加载）
	terrain_outline = TextureRect.new()
	terrain_outline.size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	terrain_outline.position = Vector2.ZERO
	minimap_container.add_child(terrain_outline)
	
	# 创建罗盘环
	compass_ring = TextureRect.new()
	compass_ring.texture = create_compass_ring_texture()
	compass_ring.size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	compass_ring.position = Vector2.ZERO
	minimap_container.add_child(compass_ring)

# 创建玩家朝向箭头纹理
func create_player_arrow_texture() -> ImageTexture:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 绘制一个简单的箭头形状
	for y in range(16):
		for x in range(16):
			# 创建一个简单的三角形箭头
			if (x > 5 and x < 11 and y < 10) and ((x >= 7 and x <= 9) or (y > x - 6 and y < 12 - x)):
				image.set_pixel(x, y, Color.YELLOW)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# 创建罗盘环纹理
func create_compass_ring_texture() -> ImageTexture:
	var image = Image.create(150, 150, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# 绘制圆圈
	var center = Vector2(75, 75)
	var radius = 70
	
	# 绘制外圆
	for angle in range(0, 360, 5):
		var rad = deg_to_rad(angle)
		var x = center.x + cos(rad) * radius
		var y = center.y + sin(rad) * radius
		if x >= 0 and x < 150 and y >= 0 and y < 150:
			image.set_pixelv(Vector2(x, y), Color.WHITE)
	
	# 绘制方向标记
	var directions = ["N", "E", "S", "W"]
	var dir_angles = [0, 90, 180, 270]
	
	for i in range(directions.size()):
		var angle = deg_to_rad(dir_angles[i])
		var pos_x = center.x + cos(angle) * (radius - 10)
		var pos_y = center.y + sin(angle) * (radius - 10)
		
		# 简单的文本绘制（实际上需要更复杂的文字渲染）
		# 这里我们用颜色点来表示方向
		if pos_x >= 0 and pos_x < 150 and pos_y >= 0 and pos_y < 150:
			image.set_pixelv(Vector2(pos_x, pos_y), Color.RED)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# 更新小地图位置（右上角）
func update_minimap_position():
	self.position = Vector2(
		DisplayServer.window_get_size().x - MINIMAP_SIZE - MINIMAP_MARGIN,
		MINIMAP_MARGIN
	)

# 处理玩家更新
func _process_player_update():
	if player_node:
		var current_pos = player_node.global_position
		var current_dir = 0.0
		
		# 获取玩家朝向（如果是CharacterBody2D或其他节点类型）
		if player_node.has_method("_get_direction"):
			current_dir = player_node._get_direction()
		elif player_node.has_method("get_angle"):
			current_dir = player_node.get_angle()
		else:
			# 默认朝向（向上）
			current_dir = -PI/2  # 向上
		
		# 更新玩家位置和朝向
		if current_pos.distance_to(player_last_position) > 10:  # 只有移动超过10像素才更新
			player_last_position = current_pos
			player_direction = current_dir
			
			# 更新玩家标记位置
			update_player_marker()
			
			# 检查探索状态
			check_exploration(current_pos)
			
			# 发送位置更新信号
			emit_signal("player_position_updated", current_pos)

# 更新玩家标记
func update_player_marker():
	if player_marker:
		# 将玩家位置映射到小地图坐标（简化处理）
		var map_pos = Vector2(MINIMAP_SIZE/2, MINIMAP_SIZE/2)  # 玩家始终在小地图中心
		player_marker.position = map_pos
		
		# 旋转玩家标记以显示朝向
		player_marker.rotation = player_direction

# 检查探索状态
func check_exploration(player_pos: Vector2):
	# 检查玩家是否到达了新的探索区域
	var is_new_area = true
	for explored_pos in explored_areas:
		if explored_pos.distance_to(player_pos) < EXPLORE_RADIUS:
			is_new_area = false
			break
	
	if is_new_area:
		explored_areas.append(player_pos)
		# 更新探索百分比（简化计算）
		update_exploration_percentage()

# 更新探索百分比
func update_exploration_percentage():
	# 这里简化处理，实际项目中需要根据区域大小和探索点数量计算
	# 假设每个区域有100个探索点
	var total_points = 100
	var explored_points = min(explored_areas.size(), total_points)
	exploration_percentage = (explored_points / total_points) * 100.0
	
	print("探索进度: ", exploration_percentage, "%")

# 设置玩家节点
func set_player(node: Node2D):
	player_node = node

# 获取当前探索百分比
func get_exploration_percentage() -> float:
	return exploration_percentage

# 获取已探索区域数量
func get_explored_areas_count() -> int:
	return explored_areas.size()

# 重置探索数据
func reset_exploration():
	explored_areas.clear()
	exploration_percentage = 0.0

# 设置当前区域
func set_current_region(region_name: String):
	current_region = region_name
	reset_exploration()  # 进入新区域时重置探索数据

# 获取当前区域
func get_current_region() -> String:
	return current_region

# 处理窗口大小变化
func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		update_minimap_position()

# 自定义绘制（如果需要更复杂的绘制）
func _draw():
	# 在这里可以添加自定义绘制代码
	pass