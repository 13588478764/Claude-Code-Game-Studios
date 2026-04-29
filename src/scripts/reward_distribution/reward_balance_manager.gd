# 奖励平衡管理器
# 实现等级/境界挂钩的数值缩放、通胀控制、背包容量管理和物品层级锁定

extends Node

class_name RewardBalanceManager

# 依赖的奖励类型管理器和分配管理器
var reward_type_manager: RewardTypeManager = null
var distribution_manager: RewardDistributionManager = null

# 背包容量配置
var backpack_capacity: int = 100
var current_backpack_usage: int = 0

# 等级缩放系数配置
var level_scaling_coefficient: float = 0.1
var realm_scaling_coefficient: float = 0.05

# 通胀控制配置
var inflation_control_threshold: int = 50  # 玩家等级超过50时启用通胀控制
var low_tier_material_reduction_rate: float = 0.8  # 低级材料减少率
var high_tier_reward_increase_rate: float = 1.5   # 高级奖励增加率

# 物品层级配置
var item_tier_lock_config: Dictionary = {}

func _init():
	# 初始化默认配置
	_initialize_default_config()

# 设置依赖管理器
func set_reward_managers(type_manager: RewardTypeManager, dist_manager: RewardDistributionManager):
	reward_type_manager = type_manager
	distribution_manager = dist_manager

# 初始化默认配置
func _initialize_default_config():
	# 初始化物品层级锁定配置
	item_tier_lock_config = {
		"low_tier_items": ["iron_ore", "herb_common", "wood", "common_sword"],
		"mid_tier_items": ["mystic_iron", "proficiency_fragment", "rare_sword", "health_potion", "qi_potion"],
		"high_tier_items": ["thousand_year_ginseng", "attribute_points", "talent_points", "manual", "legendary_sword"]
	}

# 实现等级/境界挂钩的数值缩放
# 公式: 最终奖励数量 = 基础奖励数量 × (1 + 玩家等级 × 等级缩放系数)
func calculate_scaled_reward_amount(base_amount: int, player_level: int, player_realm: int = 0) -> float:
	var level_scaling = 1.0 + (player_level * level_scaling_coefficient)
	var realm_scaling = 1.0 + (player_realm * realm_scaling_coefficient)
	return base_amount * level_scaling * realm_scaling

# 实现通胀控制机制
func apply_inflation_control(rewards: Array, player_level: int) -> Array:
	if player_level < inflation_control_threshold:
		return rewards  # 未达到通胀控制阈值，直接返回
	
	var adjusted_rewards = []
	
	for reward in rewards:
		var item_id = reward.item_id
		var quantity = reward.quantity
		var reward_type = reward.type
		
		# 检查是否为低级材料
		if _is_low_tier_material(item_id) and reward_type != "fixed":
			# 减少低级材料奖励
			var reduced_quantity = int(quantity * (1.0 - low_tier_material_reduction_rate))
			if reduced_quantity > 0:
				adjusted_rewards.append({"item_id": item_id, "quantity": reduced_quantity, "type": reward_type})
			
			# 添加高级强化石或稀有宝石作为补偿
			var high_tier_compensation = _get_high_tier_compensation(item_id)
			if not high_tier_compensation.is_empty():
				for comp_item in high_tier_compensation.keys():
					var comp_quantity = int(high_tier_compensation[comp_item] * high_tier_reward_increase_rate)
					if comp_quantity > 0:
						adjusted_rewards.append({"item_id": comp_item, "quantity": comp_quantity, "type": "inflation_compensation"})
		else:
			# 非低级材料，直接添加
			adjusted_rewards.append(reward)
	
	return adjusted_rewards

# 判断是否为低级材料
func _is_low_tier_material(item_id: String) -> bool:
	return item_tier_lock_config.low_tier_items.has(item_id)

# 获取高级补偿奖励
func _get_high_tier_compensation(original_item: String) -> Dictionary:
	var compensation = {}
	
	# 根据原始物品类型提供相应的高级补偿
	if original_item == "iron_ore":
		compensation["mystic_iron"] = 1
	elif original_item == "herb_common":
		compensation["thousand_year_ginseng"] = 1
	elif original_item == "wood":
		compensation["rare_sword"] = 1
	elif original_item == "common_sword":
		compensation["rare_sword"] = 1
	
	return compensation

# 实现背包容量管理
func handle_backpack_capacity(rewards: Array, player_id: String) -> Array:
	var processed_rewards = []
	var overflow_rewards = []
	
	for reward in rewards:
		var item_id = reward.item_id
		var quantity = reward.quantity
		var reward_type = reward.type
		
		# 获取物品配置
		var item_config = reward_type_manager.get_reward_config(item_id)
		var is_stackable = item_config.get("stackable", false)
		var max_stack = item_config.get("max_stack", 1)
		
		if is_stackable:
			# 可堆叠物品，检查背包空间
			var available_space = backpack_capacity - current_backpack_usage
			if available_space >= quantity:
				# 有足够的空间
				processed_rewards.append(reward)
				current_backpack_usage += quantity
			else:
				# 空间不足，部分放入背包，其余转换为银两
				if available_space > 0:
					processed_rewards.append({"item_id": item_id, "quantity": available_space, "type": reward_type})
					current_backpack_usage += available_space
				
				var overflow_quantity = quantity - available_space
				if overflow_quantity > 0:
					# 转换为等值银两
					var silver_value = _calculate_silver_value(item_id, overflow_quantity)
					if silver_value > 0:
						overflow_rewards.append({"item_id": "silver", "quantity": silver_value, "type": "overflow_conversion"})
		else:
			# 不可堆叠物品，每个占用一个格子
			var item_count = quantity  # 对于不可堆叠物品，quantity通常为1
			var available_slots = backpack_capacity - current_backpack_usage
			
			if available_slots >= item_count:
				# 有足够的格子
				processed_rewards.append(reward)
				current_backpack_usage += item_count
			else:
				# 格子不足，转换为等值银两或EXP
				var conversion_reward = _convert_unstackable_to_value(item_id, item_count)
				if not conversion_reward.is_empty():
					overflow_rewards.append(conversion_reward)
	
	# 合并处理后的奖励和溢出转换的奖励
	processed_rewards.append_array(overflow_rewards)
	return processed_rewards

# 计算物品的银两价值
func _calculate_silver_value(item_id: String, quantity: int) -> int:
	var base_value = 10  # 默认基础价值
	
	# 根据物品类型和稀有度调整价值
	var item_config = reward_type_manager.get_reward_config(item_id)
	if item_config.has("rarity"):
		match item_config.rarity:
			"common":
				base_value = 5
			"rare":
				base_value = 50
			"epic":
				base_value = 200
			"legendary":
				base_value = 1000
	
	return base_value * quantity

# 将不可堆叠物品转换为等值奖励
func _convert_unstackable_to_value(item_id: String, count: int) -> Dictionary:
	# 检查物品类型
	var category = reward_type_manager.get_reward_category(item_id)
	
	if category == RewardTypeManager.RewardCategory.EQUIPMENT_ITEMS:
		# 装备物品转换为银两
		var silver_value = _calculate_silver_value(item_id, count)
		if silver_value > 0:
			return {"item_id": "silver", "quantity": silver_value, "type": "overflow_conversion"}
	elif category == RewardTypeManager.RewardCategory.PROGRESSION_RESOURCES:
		# 成长资源保持原样（经验值、属性点等通常不会溢出）
		return {"item_id": item_id, "quantity": count, "type": "overflow_conversion"}
	else:
		# 其他类型转换为银两
		var silver_value = _calculate_silver_value(item_id, count)
		if silver_value > 0:
			return {"item_id": "silver", "quantity": silver_value, "type": "overflow_conversion"}
	
	return {}

# 实现物品层级锁定
func apply_item_tier_locking(rewards: Array, region_tier: int, player_level: int) -> Array:
	var filtered_rewards = []
	
	for reward in rewards:
		var item_id = reward.item_id
		var reward_type = reward.type
		
		# 固定奖励不受层级锁定影响
		if reward_type == "fixed":
			filtered_rewards.append(reward)
			continue
		
		# 检查物品层级
		var item_tier = _get_item_tier(item_id)
		
		# 高等级区域不应掉落低级垃圾
		if region_tier >= 2 and item_tier == 1:
			# 跳过低级物品，可以替换为中级物品
			var replacement = _get_tier_appropriate_replacement(item_id, region_tier)
			if not replacement.is_empty():
				filtered_rewards.append(replacement)
			continue
		
		# 低等级区域不应掉落神级装备
		if region_tier <= 1 and item_tier >= 3:
			# 跳过高级物品，可以替换为低级物品
			var replacement = _get_tier_appropriate_replacement(item_id, region_tier)
			if not replacement.is_empty():
				filtered_rewards.append(replacement)
			continue
		
		# 符合层级要求的物品，直接添加
		filtered_rewards.append(reward)
	
	return filtered_rewards

# 获取物品层级
func _get_item_tier(item_id: String) -> int:
	if item_tier_lock_config.low_tier_items.has(item_id):
		return 1
	elif item_tier_lock_config.mid_tier_items.has(item_id):
		return 2
	elif item_tier_lock_config.high_tier_items.has(item_id):
		return 3
	else:
		# 默认为中级
		return 2

# 获取符合层级的替代物品
func _get_tier_appropriate_replacement(original_item: String, target_tier: int) -> Dictionary:
	var original_tier = _get_item_tier(original_item)
	
	if original_tier < target_tier:
		# 升级到更高级别
		if target_tier >= 2:
			# 返回中级物品
			return {"item_id": "rare_sword", "quantity": 1, "type": "tier_adjustment"}
		else:
			# 返回低级物品
			return {"item_id": "common_sword", "quantity": 1, "type": "tier_adjustment"}
	elif original_tier > target_tier:
		# 降级到更低级别
		if target_tier <= 1:
			# 返回低级物品
			return {"item_id": "common_sword", "quantity": 1, "type": "tier_adjustment"}
		else:
			# 返回中级物品
			return {"item_id": "rare_sword", "quantity": 1, "type": "tier_adjustment"}
	
	return {}

# 设置背包容量
func set_backpack_capacity(capacity: int):
	backpack_capacity = max(1, capacity)

# 重置背包使用量（用于新游戏或测试）
func reset_backpack_usage():
	current_backpack_usage = 0

# 获取当前背包使用量
func get_current_backpack_usage() -> int:
	return current_backpack_usage

# 检查背包是否已满
func is_backpack_full() -> bool:
	return current_backpack_usage >= backpack_capacity

# 应用完整的奖励平衡逻辑
func apply_complete_reward_balance(rewards: Array, player_level: int, player_realm: int, player_id: String, region_tier: int) -> Array:
	var balanced_rewards = []
	
	# 1. 应用数值缩放
	for reward in rewards:
		var scaled_quantity = calculate_scaled_reward_amount(reward.quantity, player_level, player_realm)
		balanced_rewards.append({"item_id": reward.item_id, "quantity": int(scaled_quantity), "type": reward.type})
	
	# 2. 应用物品层级锁定
	balanced_rewards = apply_item_tier_locking(balanced_rewards, region_tier, player_level)
	
	# 3. 应用通胀控制
	balanced_rewards = apply_inflation_control(balanced_rewards, player_level)
	
	# 4. 处理背包容量
	balanced_rewards = handle_backpack_capacity(balanced_rewards, player_id)
	
	return balanced_rewards

# 更新玩家背包使用量（外部调用）
func update_backpack_usage(usage: int):
	current_backpack_usage = min(backpack_capacity, usage)

# 获取玩家可用背包空间
func get_available_backpack_space() -> int:
	return max(0, backpack_capacity - current_backpack_usage)