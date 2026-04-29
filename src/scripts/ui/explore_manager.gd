## ExploreManager
## 探索管理器
管理游戏世界的探索状态、迷雾系统和探索进度
##
## 主要功能：
## - 待补充

extends Node

class_name ExploreManager

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
signal exploration_progress_updated(region_name: String, percentage: float)
signal fog_of_war_revealed(position: Vector2, radius: float)
signal region_explored(region_name: String)

# 常量定义
const EXPLORE_RADIUS = 50  # 探索半径（像素）
const REGION_SIZE = 1000   # 区域大小（像素）

# 探索数据结构
class RegionData:
	var name: String
	var total_tiles: int
	var explored_tiles: Array[Vector2]
	var fog_texture: ImageTexture
	var exploration_percentage: float
	
	func _init(region_name: String, tiles_count: int):
		name = region_name
		total_tiles = tiles_count
		explored_tiles = []
		exploration_percentage = 0.0
		fog_texture = create_fog_texture()

# 探索管理器属性
var regions: Dictionary = {}  # 区域数据
var current_region: String = ""
var player_position: Vector2 = Vector2.ZERO
var last_explore_position: Vector2 = Vector2(-1000, -1000)  # 初始化为远离玩家的位置

# 初始化
func _ready():
	print("探索管理器已初始化")

# 设置当前区域
func set_current_region(region_name: String, total_tiles: int = 100):
	if !regions.has(region_name):
		regions[region_name] = RegionData.new(region_name, total_tiles)
	
	current_region = region_name
	print("切换到区域: ", region_name)

# 更新玩家位置并检查探索
func update_player_position(pos: Vector2):
	player_position = pos
	
	# 检查是否需要更新探索状态
	if pos.distance_to(last_explore_position) > EXPLORE_RADIUS / 2:
		check_exploration_at_position(pos)
		last_explore_position = pos

# 检查指定位置的探索状态
func check_exploration_at_position(pos: Vector2):
	if current_region == "":
		return
	
	var region_data = regions[current_region]
	var grid_pos = Vector2(floor(pos.x / 50), floor(pos.y / 50))  # 将位置转换为网格坐标
	
	# 检查这个网格点是否已经被探索
	if !is_tile_explored(grid_pos):
		region_data.explored_tiles.append(grid_pos)
		emit_signal("fog_of_war_revealed", pos, EXPLORE_RADIUS)
		
		# 更新探索百分比
		var new_percentage = float(region_data.explored_tiles.size()) / float(region_data.total_tiles) * 100.0
		region_data.exploration_percentage = new_percentage
		
		# 发送探索进度更新信号
		emit_signal("exploration_progress_updated", current_region, new_percentage)
		
		# 检查是否完成区域探索
		if new_percentage >= 100.0:
			emit_signal("region_explored", current_region)
		
		print("探索进度: ", current_region, " - ", new_percentage, "%")

# 检查指定瓦片是否已探索
func is_tile_explored(tile_pos: Vector2) -> bool:
	if current_region == "":
		return false
	
	var region_data = regions[current_region]
	return region_data.explored_tiles.has(tile_pos)

# 获取当前区域探索百分比
func get_current_region_exploration_percentage() -> float:
	if current_region == "":
		return 0.0
	
	var region_data = regions[current_region]
	return region_data.exploration_percentage

# 获取指定区域探索百分比
func get_region_exploration_percentage(region_name: String) -> float:
	if regions.has(region_name):
		return regions[region_name].exploration_percentage
	return 0.0

# 获取当前区域已探索瓦片数量
func get_current_region_explored_tiles_count() -> int:
	if current_region == "":
		return 0
	
	var region_data = regions[current_region]
	return region_data.explored_tiles.size()

# 获取当前区域总瓦片数量
func get_current_region_total_tiles_count() -> int:
	if current_region == "":
		return 0
	
	var region_data = regions[current_region]
	return region_data.total_tiles

# 创建迷雾纹理
func create_fog_texture() -> ImageTexture:
	# 创建一个简单的迷雾纹理（实际项目中会更复杂）
	var image = Image.create(REGION_SIZE/10, REGION_SIZE/10, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.2, 0.2, 0.7))  # 深灰色半透明，模拟迷雾
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# 获取迷雾纹理
func get_fog_texture(region_name: String) -> ImageTexture:
	if regions.has(region_name):
		return regions[region_name].fog_texture
	return null

# 保存探索数据
func save_exploration_data() -> Dictionary:
	var save_data = {}
	save_data.current_region = current_region
	
	var region_save_data = {}
	for region_name in regions:
		var region = regions[region_name]
		region_save_data[region_name] = {
			"explored_tiles": region.explored_tiles,
			"exploration_percentage": region.exploration_percentage,
			"total_tiles": region.total_tiles
		}
	
	save_data.regions = region_save_data
	return save_data

# 加载探索数据
func load_exploration_data(data: Dictionary):
	if data.has("current_region"):
		current_region = data.current_region
	
	if data.has("regions"):
		for region_name in data.regions:
			var region_data = data.regions[region_name]
			set_current_region(region_name, region_data.total_tiles)
			
			var region = regions[region_name]
			region.explored_tiles = region_data.explored_tiles
			region.exploration_percentage = region_data.exploration_percentage

# 重置指定区域的探索数据
func reset_region_exploration(region_name: String):
	if regions.has(region_name):
		var region = regions[region_name]
		region.explored_tiles.clear()
		region.exploration_percentage = 0.0
		print("已重置区域探索数据: ", region_name)

# 重置所有探索数据
func reset_all_exploration():
	for region_name in regions:
		reset_region_exploration(region_name)
	current_region = ""
	print("已重置所有探索数据")

# 获取所有已探索的区域名称
func get_explored_regions() -> Array[String]:
	var explored = []
	for region_name in regions:
		if regions[region_name].exploration_percentage > 0:
			explored.append(region_name)
	return explored

# 获取完全探索的区域名称
func get_fully_explored_regions() -> Array[String]:
	var fully_explored = []
	for region_name in regions:
		if regions[region_name].exploration_percentage >= 100:
			fully_explored.append(region_name)
	return fully_explored