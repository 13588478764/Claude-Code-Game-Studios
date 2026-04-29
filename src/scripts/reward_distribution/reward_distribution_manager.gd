# 奖励分配管理器
# 实现固定基础奖励、权重化随机池、层级掉落表和唯一性限制机制

extends Node

class_name RewardDistributionManager

# 依赖的奖励类型管理器
var reward_type_manager: RewardTypeManager = null

# 随机数生成器
var random_generator: RandomNumberGenerator = null

# 唯一性物品追踪
var unique_items_obtained: Dictionary = {}

# 层级掉落表配置
var tier_drop_tables: Dictionary = {}

# 固定基础奖励配置
var fixed_base_rewards: Dictionary = {}

func _init():
	random_generator = RandomNumberGenerator.new()
	# 初始化默认配置
	_initialize_default_config()

# 设置奖励类型管理器
func set_reward_type_manager(manager: RewardTypeManager):
	reward_type_manager = manager

# 初始化默认配置
func _initialize_default_config():
	# 初始化层级掉落表
	tier_drop_tables = {
		1: {  # 新手村层级
			"material_resources": {"silver": 100, "iron_ore": 50, "herb_common": 30},
			"progression_resources": {"experience": 80, "proficiency_fragment": 20},
			"equipment_items": {"common_sword": 10, "health_potion": 40, "key": 5}
		},
		2: {  # 中级区域层级
			"material_resources": {"silver": 200, "iron_ore": 80, "herb_common": 50, "mystic_iron": 10},
			"progression_resources": {"experience": 150, "proficiency_fragment": 40, "attribute_points": 5},
			"equipment_items": {"rare_sword": 15, "health_potion": 60, "qi_potion": 30, "manual": 3}
		},
		3: {  # 高级区域层级（禁地）
			"material_resources": {"silver": 500, "mystic_iron": 30, "thousand_year_ginseng": 5},
			"progression_resources": {"experience": 300, "proficiency_fragment": 80, "attribute_points": 10, "talent_points": 3},
			"equipment_items": {"rare_sword": 40, "health_potion": 80, "qi_potion": 60, "manual": 10}
		}
	}
	
	# 初始化固定基础奖励示例
	fixed_base_rewards = {
		"encounter_basic": {"silver": 50, "experience": 30},
		"encounter_medium": {"silver": 100, "experience": 60, "health_potion": 1},
		"encounter_hard": {"silver": 200, "experience": 120, "health_potion": 2, "qi_potion": 1}
	}

# 计算掉落层级
# 公式: min(最大层级, 玩家等级 / 层级间隔)
func calculate_drop_tier(player_level: int, max_tier: int = 3, tier_interval: int = 10) -> int:
	var calculated_tier = player_level / tier_interval
	return min(max_tier, calculated_tier)

# 获取指定层级的掉落表
func get_tier_drop_table(tier: int) -> Dictionary:
	if tier_drop_tables.has(tier):
		return tier_drop_tables[tier]
	else:
		# 如果层级不存在，返回最低层级
		return tier_drop_tables.get(1, {})

# 实现固定基础奖励机制
func get_fixed_base_rewards(encounter_type: String) -> Dictionary:
	if fixed_base_rewards.has(encounter_type):
		return fixed_base_rewards[encounter_type].duplicate()
	else:
		# 返回空字典
		return {}

# 实现权重化随机池机制
# 支持福缘属性对稀有物品权重的修正
# 公式: 修正后权重 = 原始权重 × (1 + 福缘/100)
func calculate_weighted_pool(pool: Dictionary, luck_stat: int = 0) -> Dictionary:
	var adjusted_pool = {}
	
	for item_id in pool.keys():
		var original_weight = pool[item_id]
		var adjusted_weight = original_weight
		
		# 检查是否为稀有物品（根据奖励类型判断）
		if _is_rare_item(item_id):
			# 应用福缘修正
			var luck_modifier = 1.0 + (luck_stat / 100.0)
			adjusted_weight = original_weight * luck_modifier
		
		adjusted_pool[item_id] = adjusted_weight
	
	return adjusted_pool

# 判断是否为稀有物品
func _is_rare_item(item_id: String) -> bool:
	if not reward_type_manager:
		return false
	
	var config = reward_type_manager.get_reward_config(item_id)
	if config.has("rarity"):
		return config.rarity == "rare" or config.rarity == "epic" or config.rarity == "legendary"
	
	# 检查是否为稀有材料
	if reward_type_manager.get_reward_category(item_id) == RewardTypeManager.RewardCategory.MATERIAL_RESOURCES:
		var materials = reward_type_manager.reward_type_config.get("material_resources", {})
		if materials.has("rare_materials"):
			return materials.rare_materials.has(item_id)
	
	return false

# 从权重池中选择奖励
func select_from_weighted_pool(weighted_pool: Dictionary) -> String:
	if weighted_pool.is_empty():
		return ""
	
	# 计算总权重
	var total_weight = 0.0
	for weight in weighted_pool.values():
		total_weight += weight
	
	if total_weight <= 0:
		return ""
	
	# 生成随机值
	var random_value = random_generator.randf_range(0, total_weight)
	
	# 选择物品
	var current_weight = 0.0
	for item_id in weighted_pool.keys():
		current_weight += weighted_pool[item_id]
		if random_value <= current_weight:
			return item_id
	
	# 如果由于浮点精度问题没有选中，返回最后一个
	return weighted_pool.keys()[-1]

# 实现唯一性限制机制
func check_unique_item_limitation(item_id: String, player_id: String) -> bool:
	# 检查物品是否为唯一性物品
	if not _is_unique_item(item_id):
		return true  # 非唯一性物品，可以正常获得
	
	# 检查玩家是否已经拥有该物品
	var player_unique_items = unique_items_obtained.get(player_id, [])
	if item_id in player_unique_items:
		return false  # 已经拥有，不能重复获得
	else:
		# 标记为已获得
		if not unique_items_obtained.has(player_id):
			unique_items_obtained[player_id] = []
		unique_items_obtained[player_id].append(item_id)
		return true

# 判断是否为唯一性物品
func _is_unique_item(item_id: String) -> bool:
	if not reward_type_manager:
		return false
	
	var config = reward_type_manager.get_reward_config(item_id)
	# 唯一性物品通常不可堆叠且max_stack为1
	if config.has("stackable") and not config.stackable and config.get("max_stack", 1) == 1:
		# 进一步检查是否为特殊道具或秘籍等
		var category = reward_type_manager.get_reward_category(item_id)
		if category == RewardTypeManager.RewardCategory.EQUIPMENT_ITEMS:
			var equipment_config = reward_type_manager.get_equipment_config(item_id)
			if equipment_config.has("name") and ("秘籍" in equipment_config.name or "任务物品" in equipment_config.name):
				return true
		elif category == RewardTypeManager.RewardCategory.NARRATIVE_STATUS:
			return true  # 叙事状态奖励通常为唯一性
	
	return false

# 处理唯一性冲突 - 替换为等值银两或通用材料
func handle_unique_item_conflict(item_id: String) -> Dictionary:
	var replacement_rewards = {}
	
	# 获取原物品的配置
	var item_config = reward_type_manager.get_reward_config(item_id)
	
	# 计算等值银两
	var silver_value = 100  # 默认值
	if item_config.has("rarity"):
		match item_config.rarity:
			"common":
				silver_value = 50
			"rare":
				silver_value = 200
			"epic":
				silver_value = 500
			"legendary":
				silver_value = 1000
	
	replacement_rewards["silver"] = silver_value
	
	# 也可以添加通用材料作为替代
	replacement_rewards["iron_ore"] = 10
	
	return replacement_rewards

# 生成完整奖励列表
func generate_rewards(encounter_type: String, player_level: int, player_luck: int, player_id: String, region_tier: int = -1) -> Array:
	var rewards = []
	
	# 1. 添加固定基础奖励
	var fixed_rewards = get_fixed_base_rewards(encounter_type)
	for item_id in fixed_rewards.keys():
		var quantity = fixed_rewards[item_id]
		if quantity > 0:
			rewards.append({"item_id": item_id, "quantity": quantity, "type": "fixed"})
	
	# 2. 确定掉落层级
	var drop_tier = region_tier
	if drop_tier == -1:
		drop_tier = calculate_drop_tier(player_level)
	
	# 3. 获取对应层级的掉落表
	var drop_table = get_tier_drop_table(drop_tier)
	
	# 4. 为每个奖励类别生成随机奖励
	for category in drop_table.keys():
		var category_pool = drop_table[category]
		if not category_pool.is_empty():
			# 应用权重修正
			var adjusted_pool = calculate_weighted_pool(category_pool, player_luck)
			
			# 从池中选择一个物品
			var selected_item = select_from_weighted_pool(adjusted_pool)
			if selected_item != "":
				# 检查唯一性限制
				if check_unique_item_limitation(selected_item, player_id):
					rewards.append({"item_id": selected_item, "quantity": 1, "type": "random"})
				else:
					# 处理唯一性冲突
					var replacement = handle_unique_item_conflict(selected_item)
					for rep_item in replacement.keys():
						rewards.append({"item_id": rep_item, "quantity": replacement[rep_item], "type": "replacement"})
	
	return rewards

# 重置唯一性物品追踪（用于新游戏或测试）
func reset_unique_items():
	unique_items_obtained.clear()

# 添加自定义掉落表
func add_custom_drop_table(tier: int, drop_table: Dictionary):
	tier_drop_tables[tier] = drop_table

# 添加自定义固定奖励
func add_custom_fixed_rewards(encounter_type: String, rewards: Dictionary):
	fixed_base_rewards[encounter_type] = rewards

# 获取玩家已获得的唯一物品
func get_player_unique_items(player_id: String) -> Array:
	return unique_items_obtained.get(player_id, [])

# 检查玩家是否已获得特定唯一物品
func has_player_obtained_unique_item(player_id: String, item_id: String) -> bool:
	var player_items = unique_items_obtained.get(player_id, [])
	return item_id in player_items