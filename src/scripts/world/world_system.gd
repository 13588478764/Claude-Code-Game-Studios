## WorldSystem
## 武侠奇遇录 - 世界系统
## 
## 负责管理开放世界探索、区域加载、兴趣点和快速旅行。
## 
## 主要功能：
## - 区域加载和卸载管理
## - 兴趣点（POI）发现和收集
## - 快速旅行点解锁和传送
## - 境界限制检查和伤害处理
## - 玩家位置追踪和区域边界检查
## - 探索奖励分配

extends Node

class_name WorldSystem

# ============================================================================
# 常量定义
# ============================================================================

## 区域大小（像素）
const REGION_SIZE: Vector2 = Vector2(2048, 2048)

## 加载距离倍数（屏幕宽度）
const LOAD_DISTANCE_MULTIPLIER: float = 1.5

## 宝箱稀有度 - 普通
const TREASURE_RARITY_COMMON: float = 0.7

## 宝箱稀有度 - 稀有
const TREASURE_RARITY_RARE: float = 0.25

## 宝箱稀有度 - 传奇
const TREASURE_RARITY_LEGENDARY: float = 0.05

## 新手村兴趣点密度
const POI_DENSITY_START_VILLAGE: int = 5

## 黑风寨兴趣点密度
const POI_DENSITY_BANDIT_FORTRESS: int = 8

## 青云山兴趣点密度
const POI_DENSITY_QINGYUN_MOUNTAIN: int = 10

## 江南水乡兴趣点密度
const POI_DENSITY_JIANGNAN_WATER: int = 7

## 境界不足伤害比例
const REALM_DAMAGE_RATIO: float = 0.1

## 轻功消耗系数
const STAMINA_CONSUMPTION: float = 1.0

## 探索奖励基础概率
const EXPLORATION_REWARD_BASE_PROBABILITY: float = 0.03

## 福缘概率加成
const LUCK_PROBABILITY_BONUS: float = 0.002

# ============================================================================
# 信号定义
# ============================================================================

## 区域进入信号
signal region_entered(region_id: String)

## 区域卸载信号
signal region_unloaded(region_id: String)

## 兴趣点发现信号
signal poi_discovered(poi_id: String)

## 兴趣点收集信号
signal poi_collected(poi_id: String)

## 快速旅行点解锁信号
signal fast_travel_unlocked(fast_travel_id: String)

## 玩家传送信号
signal player_teleported(fast_travel_id: String)

## 境界限制触发信号
signal realm_restriction_triggered(region_id: String)

# ============================================================================
# 成员变量
# ============================================================================

## 当前区域ID
var current_region: String = "start_village"

## 玩家当前位置
var player_position: Vector2 = Vector2.ZERO

## 已探索区域ID列表
var explored_regions: Array[String] = []

## 已解锁快速旅行点列表
var unlocked_fast_travel: Array[String] = []

## 已发现兴趣点ID列表
var discovered_poi: Array[String] = []

## 已收集兴趣点ID列表
var collected_poi: Array[String] = []

## 当前加载的区域列表
var active_regions: Array[String] = []

## 探索配置字典
var config: Dictionary = {
	"region_size": REGION_SIZE,
	"load_distance_multiplier": LOAD_DISTANCE_MULTIPLIER,
	"treasure_chest_rarity": {
		"common": TREASURE_RARITY_COMMON,
		"rare": TREASURE_RARITY_RARE,
		"legendary": TREASURE_RARITY_LEGENDARY
	},
	"poi_density": {
		"start_village": POI_DENSITY_START_VILLAGE,
		"bandit_fortress": POI_DENSITY_BANDIT_FORTRESS,
		"qingyun_mountain": POI_DENSITY_QINGYUN_MOUNTAIN,
		"jiangnan_water": POI_DENSITY_JIANGNAN_WATER
	},
	"realm_damage_ratio": REALM_DAMAGE_RATIO,
	"stamina_consumption": STAMINA_CONSUMPTION,
	"exploration_reward_base_probability": EXPLORATION_REWARD_BASE_PROBABILITY,
	"luck_probability_bonus": LUCK_PROBABILITY_BONUS
}

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化世界系统
func _ready() -> void:
	print("世界系统初始化完成")
	load_world_data()

# ============================================================================
# 公共方法
# ============================================================================

## 加载世界数据
func load_world_data() -> void:
	"""加载世界数据"""
	print("加载世界数据...")

## 进入指定区域
func enter_region(region_id: String) -> void:
	"""
	进入指定区域
	
	参数：
	- region_id: 区域ID
	"""
	if current_region == region_id:
		return
	
	# 卸载当前区域
	unload_region(current_region)
	
	# 加载新区域
	load_region(region_id)
	current_region = region_id
	
	# 标记为已探索
	if not explored_regions.has(region_id):
		explored_regions.append(region_id)
		print("探索新区域: %s" % region_id)
	
	# 检查境界限制
	check_realm_restriction(region_id)
	
	# 发出信号
	region_entered.emit(region_id)

## 加载区域
func load_region(region_id: String) -> void:
	"""
	加载指定区域
	
	参数：
	- region_id: 区域ID
	"""
	if active_regions.has(region_id):
		return
	
	print("加载区域: %s" % region_id)
	active_regions.append(region_id)

## 卸载区域
func unload_region(region_id: String) -> void:
	"""
	卸载指定区域
	
	参数：
	- region_id: 区域ID
	"""
	if active_regions.has(region_id):
		active_regions.erase(region_id)
		print("卸载区域: %s" % region_id)
		region_unloaded.emit(region_id)

## 检查境界限制
func check_realm_restriction(region_id: String) -> void:
	"""
	检查玩家是否满足区域的境界要求
	
	参数：
	- region_id: 区域ID
	"""
	var region_data: Dictionary = get_region_data(region_id)
	if region_data.is_empty():
		return
	
	var character_system: Node = get_node_or_null("/root/CharacterSystem")
	if character_system != null and character_system.has_method("get_realm_index"):
		var realm_index: int = character_system.get_realm_index()
		var required_realm: int = region_data.get("required_realm", 0)
		
		if realm_index < required_realm:
			start_realm_damage_timer(region_id)
			print("境界不足！进入危险区域: %s" % region_id)
			realm_restriction_triggered.emit(region_id)

## 启动境界不足伤害计时器
func start_realm_damage_timer(region_id: String) -> void:
	"""
	启动境界不足伤害计时器
	
	参数：
	- region_id: 区域ID
	"""
	print("开始境界不足伤害计时器")

## 发现兴趣点
func discover_poi(poi_id: String) -> void:
	"""
	发现指定兴趣点
	
	参数：
	- poi_id: 兴趣点ID
	"""
	if discovered_poi.has(poi_id):
		return
	
	discovered_poi.append(poi_id)
	print("发现兴趣点: %s" % poi_id)
	poi_discovered.emit(poi_id)

## 收集兴趣点
func collect_poi(poi_id: String) -> void:
	"""
	收集指定兴趣点
	
	参数：
	- poi_id: 兴趣点ID
	"""
	if collected_poi.has(poi_id):
		return
	
	var poi_data: Dictionary = get_poi_data(poi_id)
	if poi_data.is_empty():
		push_error("无法获取兴趣点数据: %s" % poi_id)
		return
	
	# 发放奖励
	distribute_poi_rewards(poi_data)
	
	collected_poi.append(poi_id)
	print("收集兴趣点: %s" % poi_id)
	poi_collected.emit(poi_id)

## 发放兴趣点奖励
func distribute_poi_rewards(poi_data: Dictionary) -> void:
	"""
	发放兴趣点奖励
	
	参数：
	- poi_data: 兴趣点数据字典
	"""
	if not poi_data.is_empty():
		# 发放物品奖励
		if poi_data.has("items"):
			var items: Array = poi_data.get("items", [])
			for item_reward in items:
				var item_id: String = item_reward.get("item_id", "")
				var quantity: int = item_reward.get("quantity", 0)
				if not item_id.is_empty():
					print("获得物品: %s x%d" % [item_id, quantity])
		
		# 发放经验值奖励
		if poi_data.has("exp"):
			var exp: int = poi_data.get("exp", 0)
			var character_system: Node = get_node_or_null("/root/CharacterSystem")
			if character_system != null and character_system.has_method("add_experience"):
				character_system.add_experience(exp)
			print("获得经验值: %d" % exp)
		
		# 发放银两奖励
		if poi_data.has("silver"):
			var silver: int = poi_data.get("silver", 0)
			print("获得银两: %d" % silver)

## 解锁快速旅行点
func unlock_fast_travel(fast_travel_id: String) -> void:
	"""
	解锁指定快速旅行点
	
	参数：
	- fast_travel_id: 快速旅行点ID
	"""
	if unlocked_fast_travel.has(fast_travel_id):
		return
	
	unlocked_fast_travel.append(fast_travel_id)
	print("解锁快速旅行点: %s" % fast_travel_id)
	fast_travel_unlocked.emit(fast_travel_id)

## 传送到快速旅行点
func teleport_to_fast_travel(fast_travel_id: String) -> bool:
	"""
	传送到指定快速旅行点
	
	参数：
	- fast_travel_id: 快速旅行点ID
	
	返回：
	- 传送是否成功
	"""
	if not unlocked_fast_travel.has(fast_travel_id):
		push_warning("快速旅行点未解锁: %s" % fast_travel_id)
		return false
	
	print("传送到快速旅行点: %s" % fast_travel_id)
	player_teleported.emit(fast_travel_id)
	return true

## 获取区域加载距离
func get_load_distance() -> float:
	"""
	获取区域加载距离
	
	返回：
	- 加载距离（像素）
	"""
	var screen_width: float = float(DisplayServer.window_get_size().x)
	return screen_width * LOAD_DISTANCE_MULTIPLIER

## 更新玩家位置
func update_player_position(new_position: Vector2) -> void:
	"""
	更新玩家位置
	
	参数：
	- new_position: 新位置
	"""
	player_position = new_position
	
	# 检查是否接近区域边界
	check_region_boundary()
	
	# 检查附近兴趣点
	check_nearby_poi()

## 检查区域边界
func check_region_boundary() -> void:
	"""检查玩家是否接近区域边界并预加载相邻区域"""
	pass

## 检查附近兴趣点
func check_nearby_poi() -> void:
	"""检查玩家附近的兴趣点并自动发现"""
	pass

## 获取区域数据
func get_region_data(region_id: String) -> Dictionary:
	"""
	获取指定区域的数据
	
	参数：
	- region_id: 区域ID
	
	返回：
	- 区域数据字典
	"""
	# 这里应该从世界数据库获取区域数据
	return {}

## 获取兴趣点数据
func get_poi_data(poi_id: String) -> Dictionary:
	"""
	获取指定兴趣点的数据
	
	参数：
	- poi_id: 兴趣点ID
	
	返回：
	- 兴趣点数据字典
	"""
	# 这里应该从世界数据库获取兴趣点数据
	return {}

## 检查区域是否已探索
func is_region_explored(region_id: String) -> bool:
	"""
	检查指定区域是否已探索
	
	参数：
	- region_id: 区域ID
	
	返回：
	- 是否已探索
	"""
	return explored_regions.has(region_id)

## 检查兴趣点是否已发现
func is_poi_discovered(poi_id: String) -> bool:
	"""
	检查指定兴趣点是否已发现
	
	参数：
	- poi_id: 兴趣点ID
	
	返回：
	- 是否已发现
	"""
	return discovered_poi.has(poi_id)

## 检查兴趣点是否已收集
func is_poi_collected(poi_id: String) -> bool:
	"""
	检查指定兴趣点是否已收集
	
	参数：
	- poi_id: 兴趣点ID
	
	返回：
	- 是否已收集
	"""
	return collected_poi.has(poi_id)

## 检查快速旅行点是否已解锁
func is_fast_travel_unlocked(fast_travel_id: String) -> bool:
	"""
	检查指定快速旅行点是否已解锁
	
	参数：
	- fast_travel_id: 快速旅行点ID
	
	返回：
	- 是否已解锁
	"""
	return unlocked_fast_travel.has(fast_travel_id)

# ============================================================================
# 私有方法
# ============================================================================

## 区域类型枚举
enum RegionType {
	START_VILLAGE,    # 新手村
	BANDIT_FORTRESS,  # 黑风寨
	QINGYUN_MOUNTAIN, # 青云山
	JIANGNAN_WATER,   # 江南水乡
	DUNGEON,          # 地牢/秘境
	BOSS_AREA         # BOSS区域
}

## 兴趣点类型枚举
enum POIType {
	TREASURE_CHEST,   # 宝箱
	COLLECTIBLE,      # 采集物
	HIDDEN_LOCATION,  # 隐藏地点
	FAST_TRAVEL,      # 快速旅行点
	QUEST_TARGET,     # 任务目标
	ENCOUNTER_SPOT    # 奇遇触发点
}

## 区域数据类
class RegionData:
	var id: String = ""
	var name: String = ""
	var type: int = RegionType.START_VILLAGE
	var position: Vector2 = Vector2.ZERO
	var size: Vector2 = Vector2.ZERO
	var is_explored: bool = false
	var fast_travel_unlocked: bool = false
	var poi_list: Array = []
	var required_realm: int = 0
	var danger_level: int = 0

## 兴趣点数据类
class POIData:
	var id: String = ""
	var type: int = POIType.TREASURE_CHEST
	var position: Vector2 = Vector2.ZERO
	var region_id: String = ""
	var is_discovered: bool = false
	var is_collected: bool = false
	var rewards: Dictionary = {}
	var requirements: Dictionary = {}

# ============================================================================
# 事件监听函数
# ============================================================================

## 玩家移动事件处理
func on_player_move(new_position: Vector2) -> void:
	"""
	处理玩家移动事件
	
	参数：
	- new_position: 新位置
	"""
	update_player_position(new_position)

## 玩家与兴趣点互动事件处理
func on_player_interact_with_poi(poi_id: String) -> void:
	"""
	处理玩家与兴趣点互动事件
	
	参数：
	- poi_id: 兴趣点ID
	"""
	collect_poi(poi_id)

## 玩家到达快速旅行点事件处理
func on_player_reach_fast_travel(fast_travel_id: String) -> void:
	"""
	处理玩家到达快速旅行点事件
	
	参数：
	- fast_travel_id: 快速旅行点ID
	"""
	unlock_fast_travel(fast_travel_id)

# ============================================================================
# 调试函数
# ============================================================================

## 打印世界信息用于调试
func debug_print_world_info() -> void:
	"""打印世界系统的调试信息"""
	print("=== 世界系统信息 ===")
	print("当前区域: %s" % current_region)
	print("已探索区域: %d" % explored_regions.size())
	for region_id in explored_regions:
		print("  %s" % region_id)
	
	print("已解锁快速旅行: %d" % unlocked_fast_travel.size())
	print("已发现兴趣点: %d" % discovered_poi.size())
	print("已收集兴趣点: %d" % collected_poi.size())
	print("当前加载区域: %d" % active_regions.size())
	print("====================")

# ============================================================================
# UI回调函数
# ============================================================================

## 测试区域进入按钮回调
func _on_test_region_enter_pressed() -> void:
	"""测试区域进入功能"""
	print("=== 区域进入测试 ===")
	
	# 初始化角色数据
	var character_system: Node = get_node_or_null("/root/CharacterSystem")
	if character_system != null and character_system.has_method("initialize_character"):
		character_system.initialize_character()
		if character_system.has_method("add_experience"):
			character_system.add_experience(1000)
	
	# 进入黑风寨区域
	enter_region("bandit_fortress")
	
	# 检查区域状态
	print("当前区域: %s" % current_region)
	print("已探索区域数量: %d" % explored_regions.size())
	
	print("====================")

## 测试兴趣点收集按钮回调
func _on_test_poi_collect_pressed() -> void:
	"""测试兴趣点收集功能"""
	print("=== 兴趣点收集测试 ===")
	
	# 创建测试兴趣点
	var test_poi: Dictionary = {
		"id": "test_treasure_chest",
		"type": POIType.TREASURE_CHEST,
		"region_id": "bandit_fortress",
		"rewards": {
			"items": [{"item_id": "rare_sword", "quantity": 1}],
			"exp": 500,
			"silver": 200
		}
	}
	
	# 发现兴趣点
	discover_poi(test_poi["id"])
	
	# 收集兴趣点
	collect_poi(test_poi["id"])
	
	# 检查收集状态
	print("已发现兴趣点: %d" % discovered_poi.size())
	print("已收集兴趣点: %d" % collected_poi.size())
	
	print("====================")

## 测试快速旅行按钮回调
func _on_test_fast_travel_pressed() -> void:
	"""测试快速旅行功能"""
	print("=== 快速旅行测试 ===")
	
	# 解锁新手村土地庙
	unlock_fast_travel("start_village_temple")
	
	# 解锁黑风寨驿站
	unlock_fast_travel("bandit_fortress_station")
	
	# 传送到新手村
	teleport_to_fast_travel("start_village_temple")
	
	# 检查解锁状态
	print("已解锁快速旅行点: %d" % unlocked_fast_travel.size())
	
	print("====================")

## 测试境界限制按钮回调
func _on_test_realm_restriction_pressed() -> void:
	"""测试境界限制功能"""
	print("=== 境界限制测试 ===")
	
	var character_system: Node = get_node_or_null("/root/CharacterSystem")
	
	# 设置低境界
	if character_system != null and character_system.has_method("set_realm_index"):
		character_system.set_realm_index(0)
	
	# 尝试进入高难度区域
	enter_region("qingyun_mountain")
	
	# 检查是否触发境界限制
	if character_system != null and character_system.has_method("get_realm_index"):
		print("当前境界: %d" % character_system.get_realm_index())
	print("当前区域: %s" % current_region)
	
	# 提升境界后再次尝试
	if character_system != null and character_system.has_method("set_realm_index"):
		character_system.set_realm_index(3)
	enter_region("qingyun_mountain")
	
	print("提升境界后区域: %s" % current_region)
	
	print("====================")
