# 武侠奇遇录 - 奇遇奖励系统
# 实现五种核心奇遇类型的奖励发放，包含福缘影响和冲突处理

extends Node

# 信号定义
signal reward_distributed(reward_type, reward_value, encounter_type)
signal reward_conflict_handled(original_reward, converted_reward, reason)

# 奇遇类型枚举（与触发系统保持一致）
enum EncounterType {
	JIANGHU_RUMOR,      # 江湖传闻
	TIANCAI_DIBAO,      # 天材地宝
	GAOREN_ZHIDIAN,     # 高人指点
	SHICHUAN_MIJI,      # 失传秘籍
	MIJING_CHALLENGE    # 秘境挑战
}

# 奖励类型枚举
enum RewardType {
	SILVER,             # 银两
	MATERIAL,           # 材料
	ATTRIBUTE_POINT,    # 属性点
	TALENT_POINT,       # 天赋点
	EXP,                # 经验值
	ITEM,               # 物品
	MARTIAL_ART         # 武学
}

# 奖励结构定义
class Reward:
	var type: RewardType
	var value: int
	var item_id: String = ""
	var description: String = ""
	
	func _init(r_type: RewardType, r_value: int = 0, r_item_id: String = "", r_description: String = ""):
		type = r_type
		value = r_value
		item_id = r_item_id
		description = r_description

# 依赖的其他系统
var economy_manager = null
var character_stats = null
var martial_arts_manager = null
var inventory_manager = null

func _ready():
	print("奇遇奖励系统初始化完成")

# 初始化奖励系统
func initialize(econ_mgr, char_stats, martial_arts_mgr, inv_mgr):
	economy_manager = econ_mgr
	character_stats = char_stats
	martial_arts_manager = martial_arts_mgr
	inventory_manager = inv_mgr
	print("奇遇奖励系统已连接到其他管理系统")

# 分发奖励
func distribute_reward(encounter_type: EncounterType, luck_stat: int) -> Array[Reward]:
	var rewards = generate_reward_package(encounter_type, luck_stat)
	
	for reward in rewards:
		var handled_reward = handle_reward_conflicts([reward])[0]
		
		# 根据奖励类型分发奖励
		match handled_reward.type:
			RewardType.SILVER:
				if economy_manager:
					economy_manager.add_currency(economy_manager.CurrencyType.SILVER, handled_reward.value)
					emit_signal("reward_distributed", handled_reward.type, handled_reward.value, encounter_type)
			RewardType.MATERIAL:
				if economy_manager:
					economy_manager.add_currency(economy_manager.CurrencyType.PRIMARY_MATERIAL, handled_reward.value)
					emit_signal("reward_distributed", handled_reward.type, handled_reward.value, encounter_type)
			RewardType.ATTRIBUTE_POINT:
				if character_stats:
					character_stats.add_attribute_points(handled_reward.value)
					emit_signal("reward_distributed", handled_reward.type, handled_reward.value, encounter_type)
			RewardType.TALENT_POINT:
				if character_stats:
					character_stats.add_talent_points(handled_reward.value)
					emit_signal("reward_distributed", handled_reward.type, handled_reward.value, encounter_type)
			RewardType.EXP:
				if character_stats:
					character_stats.add_exp(handled_reward.value)
					emit_signal("reward_distributed", handled_reward.type, handled_reward.value, encounter_type)
			RewardType.ITEM:
				if inventory_manager:
					var add_result = inventory_manager.add_item(handled_reward.item_id, handled_reward.value)
					if !add_result:
						# 如果背包满了，转换为银两
						var silver_equivalent = convert_item_to_silver(handled_reward.item_id, handled_reward.value)
						if economy_manager:
							economy_manager.add_currency(economy_manager.CurrencyType.SILVER, silver_equivalent)
							emit_signal("reward_conflict_handled", handled_reward, silver_equivalent, "背包已满，物品转换为银两")
					emit_signal("reward_distributed", handled_reward.type, handled_reward.value, encounter_type)
			RewardType.MARTIAL_ART:
				if martial_arts_manager:
					var learn_result = martial_arts_manager.learn_art(handled_reward.item_id)
					if !learn_result:
						# 如果已学会武学，转换为熟练度或银两
						var exp_or_silver = convert_martial_art_to_other_reward(handled_reward.item_id)
						if economy_manager and exp_or_silver.type == RewardType.SILVER:
							economy_manager.add_currency(economy_manager.CurrencyType.SILVER, exp_or_silver.value)
						elif character_stats and exp_or_silver.type == RewardType.EXP:
							character_stats.add_exp(exp_or_silver.value)
						emit_signal("reward_conflict_handled", handled_reward, exp_or_silver.value, "武学已学会，转换为其他奖励")
					emit_signal("reward_distributed", handled_reward.type, handled_reward.value, encounter_type)
	
	return rewards

# 生成奖励包
func generate_reward_package(encounter_type: EncounterType, luck_stat: int) -> Array[Reward]:
	var rewards = []
	
	match encounter_type:
		EncounterType.JIANGHU_RUMOR:  # 江湖传闻
			# 银两(200-500)、普通材料(5-10)
			var silver_min = 200
			var silver_max = 500
			var material_min = 5
			var material_max = 10
			
			# 根据福缘调整奖励范围
			var luck_multiplier = 1.0 + (float(luck_stat) / 200.0)  # 每100点福缘增加50%奖励
			var silver_amount = int(randf_range(silver_min, silver_max) * luck_multiplier)
			var material_amount = int(randf_range(material_min, material_max) * luck_multiplier)
			
			rewards.append(Reward.new(RewardType.SILVER, silver_amount, "", "江湖传闻奖励"))
			rewards.append(Reward.new(RewardType.MATERIAL, material_amount, "", "江湖传闻奖励"))
			
		EncounterType.TIANCAI_DIBAO:  # 天材地宝
			# 突破丹(1)、洗点丹(1)、稀有材料(3-5)，高福缘可能触发双倍奖励
			var rare_material_min = 3
			var rare_material_max = 5
			var rare_material_amount = int(randf_range(rare_material_min, rare_material_max))
			
			# 检查是否触发双倍奖励（福缘越高概率越大）
			var double_reward_chance = float(luck_stat) / 200.0  # 50%福缘时有25%双倍奖励概率
			if randf() < double_reward_chance:
				rare_material_amount *= 2
			
			rewards.append(Reward.new(RewardType.ITEM, 1, "pill_realm_breakthrough", "突破丹"))
			rewards.append(Reward.new(RewardType.ITEM, 1, "pill_attribute_reset", "洗点丹"))
			rewards.append(Reward.new(RewardType.MATERIAL, rare_material_amount, "", "稀有材料"))
			
		EncounterType.GAOREN_ZHIDIAN:  # 高人指点
			# 自由属性点(2-5)、天赋点(1-2)、武学熟练度(50-100)
			var attribute_min = 2
			var attribute_max = 5
			var talent_min = 1
			var talent_max = 2
			var exp_min = 50
			var exp_max = 100
			
			# 根据福缘调整奖励
			var luck_bonus = int(float(luck_stat) / 50.0)  # 每50点福缘增加1点奖励
			var attribute_amount = clamp(randi_range(attribute_min, attribute_max) + luck_bonus, attribute_min, 10)
			var talent_amount = clamp(randi_range(talent_min, talent_max) + int(luck_bonus/2), talent_min, 5)
			var exp_amount = int(randf_range(exp_min, exp_max) * (1.0 + float(luck_stat)/100.0))
			
			rewards.append(Reward.new(RewardType.ATTRIBUTE_POINT, attribute_amount, "", "高人指点-属性点"))
			rewards.append(Reward.new(RewardType.TALENT_POINT, talent_amount, "", "高人指点-天赋点"))
			rewards.append(Reward.new(RewardType.EXP, exp_amount, "", "高人指点-武学熟练度"))
			
		EncounterType.SHICHUAN_MIJI:  # 失传秘籍
			# 武学残页(1)、完整武学(低阶)、经验值(500-1000)
			var exp_min = 500
			var exp_max = 1000
			var exp_amount = int(randf_range(exp_min, exp_max) * (1.0 + float(luck_stat)/100.0))
			
			# 随机选择一个低阶武学
			var low_tier_martial_arts = ["basic_strike", "intermediate_block", "advanced_dodge"]
			var random_art = low_tier_martial_arts[randi() % low_tier_martial_arts.size()]
			
			rewards.append(Reward.new(RewardType.ITEM, 1, "martial_art_scroll", "武学残页"))
			rewards.append(Reward.new(RewardType.MARTIAL_ART, 1, random_art, "失传秘籍"))
			rewards.append(Reward.new(RewardType.EXP, exp_amount, "", "阅读秘籍经验"))
			
		EncounterType.MIJING_CHALLENGE:  # 秘境挑战
			# 战斗后发放奖励：紫色装备、大量EXP(1000-2000)、传说碎片(5%概率)
			var exp_min = 1000
			var exp_max = 2000
			var exp_amount = int(randf_range(exp_min, exp_max) * (1.0 + float(luck_stat)/100.0))
			
			rewards.append(Reward.new(RewardType.EXP, exp_amount, "", "秘境挑战-大量经验"))
			rewards.append(Reward.new(RewardType.ITEM, 1, "purple_equipment", "紫色装备"))
			
			# 传说碎片(5%概率)
			if randf() < 0.05 + (float(luck_stat) / 2000.0):  # 每100点福缘增加0.5%传说碎片概率
				rewards.append(Reward.new(RewardType.ITEM, 1, "legendary_fragment", "传说碎片"))
	
	return rewards

# 处理奖励冲突
func handle_reward_conflicts(rewards: Array[Reward]) -> Array[Reward]:
	var handled_rewards = []
	
	for reward in rewards:
		var handled_reward = reward.duplicate()
		
		# 检查背包是否已满（仅针对物品类型）
		if reward.type == RewardType.ITEM or reward.type == RewardType.MARTIAL_ART:
			if inventory_manager and !inventory_manager.has_space_for_item(reward.item_id, reward.value):
				# 转换为银两
				handled_reward = convert_item_to_silver_object(reward)
				emit_signal("reward_conflict_handled", reward, handled_reward, "背包空间不足，奖励转换")
		
		handled_rewards.append(handled_reward)
	
	return handled_rewards

# 将物品转换为银两
func convert_item_to_silver(item_id: String, quantity: int) -> int:
	# 根据物品ID确定基础价值
	var base_value = get_item_base_value(item_id)
	return base_value * quantity

# 将物品奖励转换为银两奖励对象
func convert_item_to_silver_object(item_reward: Reward) -> Reward:
	var silver_amount = convert_item_to_silver(item_reward.item_id, item_reward.value)
	return Reward.new(RewardType.SILVER, silver_amount, "", "物品转换奖励")

# 将武学转换为其他奖励
func convert_martial_art_to_other_reward(art_id: String) -> Reward:
	# 检查是否已学会该武学
	if martial_arts_manager and martial_arts_manager.has_learned_art(art_id):
		# 已学会，转换为经验和银两
		var exp_value = 500  # 固定经验值
		var silver_value = 1000  # 固定银两值
		# 根据配置决定转换为何种奖励
		return Reward.new(RewardType.EXP, exp_value, "", "重复武学转换为经验")
	else:
		# 未学会，返回原奖励
		return Reward.new(RewardType.MARTIAL_ART, 1, art_id, "新武学")

# 获取物品基础价值
func get_item_base_value(item_id: String) -> int:
	# 这里应该从物品数据库获取实际的价值
	# 为了演示，我们使用一些默认值
	var default_values = {
		"pill_realm_breakthrough": 1000,
		"pill_attribute_reset": 500,
		"martial_art_scroll": 300,
		"purple_equipment": 2000,
		"legendary_fragment": 5000,
		"basic_strike": 100,
		"intermediate_block": 200,
		"advanced_dodge": 300
	}
	
	return default_values.get(item_id, 100)  # 默认价值100

# 获取奖励描述
func get_reward_description(rewards: Array[Reward]) -> String:
	var desc = "获得奖励:\n"
	for reward in rewards:
		match reward.type:
			RewardType.SILVER:
				desc += "• %d 银两\n" % reward.value
			RewardType.MATERIAL:
				desc += "• %d 材料\n" % reward.value
			RewardType.ATTRIBUTE_POINT:
				desc += "• %d 属性点\n" % reward.value
			RewardType.TALENT_POINT:
				desc += "• %d 天赋点\n" % reward.value
			RewardType.EXP:
				desc += "• %d 经验值\n" % reward.value
			RewardType.ITEM:
				desc += "• %d %s\n" % [reward.value, reward.description]
			RewardType.MARTIAL_ART:
				desc += "• %s\n" % reward.description
	
	return desc.trim_suffix("\n")

# 根据福缘调整奖励质量
func adjust_reward_quality_by_luck(rewards: Array[Reward], luck_stat: int) -> Array[Reward]:
	var adjusted_rewards = []
	
	for reward in rewards:
		var adjusted_reward = reward.duplicate()
		
		# 对于数值型奖励，根据福缘增加
		if reward.type in [RewardType.SILVER, RewardType.MATERIAL, RewardType.ATTRIBUTE_POINT, RewardType.TALENT_POINT, RewardType.EXP]:
			var luck_multiplier = 1.0 + (float(luck_stat) / 100.0)
			adjusted_reward.value = int(float(reward.value) * luck_multiplier)
		
		adjusted_rewards.append(adjusted_reward)
	
	return adjusted_rewards