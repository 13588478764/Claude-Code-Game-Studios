# 武侠奇遇录 - 世界系统
# 负责管理开放世界探索、区域加载、兴趣点和快速旅行

extends Node

# 区域类型枚举
enum RegionType {
	START_VILLAGE,    # 新手村
	BANDIT_FORTRESS,  # 黑风寨
	QINGYUN_MOUNTAIN, # 青云山
	JIANGNAN_WATER,   # 江南水乡
	DUNGEON,          # 地牢/秘境
	BOSS_AREA         # BOSS区域
}

# 兴趣点类型枚举
enum POIType {
	TREASURE_CHEST,   # 宝箱
	COLLECTIBLE,      # 采集物
	HIDDEN_LOCATION,  # 隐藏地点
	FAST_TRAVEL,      # 快速旅行点
	QUEST_TARGET,     # 任务目标
	ENCOUNTER_SPOT    # 奇遇触发点
}

# 探索配置
var config = {
	"region_size": Vector2(2048, 2048),           # 区域大小（像素）
	"load_distance_multiplier": 1.5,             # 加载距离倍数（屏幕宽度）
	"treasure_chest_rarity": {                   # 宝箱稀有度分布
		"common": 0.7,
		"rare": 0.25,
		"legendary": 0.05
	},
	"poi_density": {                            # 兴趣点密度（每区域）
		"start_village": 5,
		"bandit_fortress": 8,
		"qingyun_mountain": 10,
		"jiangnan_water": 7
	},
	"realm_damage_ratio": 0.1,                  # 境界不足伤害比例（10%）
	"stamina_consumption": 1.0,                 # 轻功消耗系数
	"exploration_reward_base_probability": 0.03, # 探索奖励基础概率
	"luck_probability_bonus": 0.002             # 福缘概率加成
}

# 区域数据结构
class RegionData:
	var id = ""
	var name = ""
	var type = RegionType.START_VILLAGE
	var position = Vector2.ZERO  # 世界坐标
	var size = Vector2.ZERO
	var is_explored = false
	var fast_travel_unlocked = false
	var poi_list = []           # 兴趣点列表
	var required_realm = 0      # 所需境界
	var danger_level = 0        # 危险等级

# 兴趣点数据结构
class POIData:
	var id = ""
	var type = POIType.TREASURE_CHEST
	var position = Vector2.ZERO
	var region_id = ""
	var is_discovered = false
	var is_collected = false
	var rewards = {}           # 奖励数据
	var requirements = {}      # 前置条件

# 当前世界状态
var current_region = "start_village"
var player_position = Vector2.ZERO
var explored_regions = []      # 已探索区域ID列表
var unlocked_fast_travel = []  # 已解锁快速旅行点
var discovered_poi = []        # 已发现兴趣点ID列表
var collected_poi = []         # 已收集兴趣点ID列表
var active_regions = []        # 当前加载的区域

func _ready():
	print("世界系统初始化完成")
	load_world_data()

func load_world_data():
	"""加载世界数据"""
	# 这里应该从JSON文件加载世界数据
	# 简化实现：暂时只打印信息
	print("加载世界数据...")

func enter_region(region_id):
	"""进入区域"""
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

func load_region(region_id):
	"""加载区域"""
	# 这里应该加载区域场景
	# 简化实现：暂时只打印信息
	print("加载区域: %s" % region_id)
	active_regions.append(region_id)

func unload_region(region_id):
	"""卸载区域"""
	if active_regions.has(region_id):
		active_regions.erase(region_id)
		print("卸载区域: %s" % region_id)

func check_realm_restriction(region_id):
	"""检查境界限制"""
	var region_data = get_region_data(region_id)
	if region_data == null:
		return
	
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null and character_system.realm_index < region_data.required_realm:
		# 启动境界不足伤害
		start_realm_damage_timer(region_id)
		print("境界不足！进入危险区域: %s" % region_id)

func start_realm_damage_timer(region_id):
	"""启动境界不足伤害计时器"""
	# 这里应该创建定时器造成伤害
	# 简化实现：暂时只打印信息
	print("开始境界不足伤害计时器")

func discover_poi(poi_id):
	"""发现兴趣点"""
	if discovered_poi.has(poi_id):
		return
	
	discovered_poi.append(poi_id)
	print("发现兴趣点: %s" % poi_id)

func collect_poi(poi_id):
	"""收集兴趣点"""
	if collected_poi.has(poi_id):
		return
	
	var poi_data = get_poi_data(poi_id)
	if poi_data == null:
		return
	
	# 发放奖励
	distribute_poi_rewards(poi_data)
	
	collected_poi.append(poi_id)
	print("收集兴趣点: %s" % poi_id)

func distribute_poi_rewards(poi_data):
	"""发放兴趣点奖励"""
	if poi_data.rewards.has("items"):
		for item_reward in poi_data.rewards["items"]:
			var item_id = item_reward["item_id"]
			var quantity = item_reward["quantity"]
			# 这里应该调用物品系统
			print("获得物品: %s x%d" % [item_id, quantity])
	
	if poi_data.rewards.has("exp"):
		var exp = poi_data.rewards["exp"]
		var character_system = get_node_or_null("/root/CharacterSystem")
		if character_system != null:
			character_system.add_experience(exp)
		print("获得经验值: %d" % exp)
	
	if poi_data.rewards.has("silver"):
		var silver = poi_data.rewards["silver"]
		# 这里应该调用经济系统
		print("获得银两: %d" % silver)

func unlock_fast_travel(fast_travel_id):
	"""解锁快速旅行点"""
	if unlocked_fast_travel.has(fast_travel_id):
		return
	
	unlocked_fast_travel.append(fast_travel_id)
	print("解锁快速旅行点: %s" % fast_travel_id)

func teleport_to_fast_travel(fast_travel_id):
	"""传送到快速旅行点"""
	if not unlocked_fast_travel.has(fast_travel_id):
		push_warning("快速旅行点未解锁: %s" % fast_travel_id)
		return
	
	# 这里应该设置玩家位置
	# 简化实现：暂时只打印信息
	print("传送到快速旅行点: %s" % fast_travel_id)

func get_load_distance():
	"""获取区域加载距离"""
	var screen_width = DisplayServer.window_get_size().x
	return screen_width * config["load_distance_multiplier"]

func update_player_position(new_position):
	"""更新玩家位置"""
	player_position = new_position
	
	# 检查是否接近区域边界
	check_region_boundary()
	
	# 检查附近兴趣点
	check_nearby_poi()

func check_region_boundary():
	"""检查区域边界"""
	# 这里应该检查玩家是否接近区域边界并预加载相邻区域
	# 简化实现：暂时只打印信息
	pass

func check_nearby_poi():
	"""检查附近兴趣点"""
	# 这里应该检查玩家附近的兴趣点并自动发现
	# 简化实现：暂时只打印信息
	pass

func get_region_data(region_id):
	"""获取区域数据"""
	# 这里应该从世界数据库获取区域数据
	# 简化实现：返回null
	return null

func get_poi_data(poi_id):
	"""获取兴趣点数据"""
	# 这里应该从世界数据库获取兴趣点数据
	# 简化实现：返回null
	return null

func is_region_explored(region_id):
	"""检查区域是否已探索"""
	return explored_regions.has(region_id)

func is_poi_discovered(poi_id):
	"""检查兴趣点是否已发现"""
	return discovered_poi.has(poi_id)

func is_poi_collected(poi_id):
	"""检查兴趣点是否已收集"""
	return collected_poi.has(poi_id)

func is_fast_travel_unlocked(fast_travel_id):
	"""检查快速旅行点是否已解锁"""
	return unlocked_fast_travel.has(fast_travel_id)

# 事件监听函数
func on_player_move(new_position):
	"""玩家移动事件"""
	update_player_position(new_position)

func on_player_interact_with_poi(poi_id):
	"""玩家与兴趣点互动事件"""
	collect_poi(poi_id)

func on_player_reach_fast_travel(fast_travel_id):
	"""玩家到达快速旅行点事件"""
	unlock_fast_travel(fast_travel_id)

# 调试函数
func debug_print_world_info():
	"""打印世界信息用于调试"""
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

# UI回调函数
func _on_test_region_enter_pressed():
	"""测试区域进入按钮回调"""
	print("=== 区域进入测试 ===")
	
	# 初始化角色数据
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null:
		character_system.initialize_character()
		character_system.add_experience(1000)  # 升级到10级
	
	# 进入黑风寨区域
	enter_region("bandit_fortress")
	
	# 检查区域状态
	print("当前区域: %s" % current_region)
	print("已探索区域数量: %d" % explored_regions.size())
	
	print("====================")

func _on_test_poi_collect_pressed():
	"""测试兴趣点收集按钮回调"""
	print("=== 兴趣点收集测试 ===")
	
	# 创建测试兴趣点
	var test_poi = POIData.new()
	test_poi.id = "test_treasure_chest"
	test_poi.type = POIType.TREASURE_CHEST
	test_poi.region_id = "bandit_fortress"
	test_poi.rewards = {
		"items": [{"item_id": "rare_sword", "quantity": 1}],
		"exp": 500,
		"silver": 200
	}
	
	# 发现兴趣点
	discover_poi(test_poi.id)
	
	# 收集兴趣点
	collect_poi(test_poi.id)
	
	# 检查收集状态
	print("已发现兴趣点: %d" % discovered_poi.size())
	print("已收集兴趣点: %d" % collected_poi.size())
	
	print("====================")

func _on_test_fast_travel_pressed():
	"""测试快速旅行按钮回调"""
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

func _on_test_realm_restriction_pressed():
	"""测试境界限制按钮回调"""
	print("=== 境界限制测试 ===")
	
	var character_system = get_node_or_null("/root/CharacterSystem")
	
	# 设置低境界
	if character_system != null:
		character_system.realm_index = 0  # 炼气期
	
	# 尝试进入高难度区域
	enter_region("qingyun_mountain")  # 青云山需要更高境界
	
	# 检查是否触发境界限制
	if character_system != null:
		print("当前境界: %d" % character_system.realm_index)
	print("当前区域: %s" % current_region)
	
	# 提升境界后再次尝试
	if character_system != null:
		character_system.realm_index = 3  # 元婴期
	enter_region("qingyun_mountain")
	
	print("提升境界后区域: %s" % current_region)
	
	print("====================")