extends Node

# 奇遇奖励管理器
# 负责处理奇遇奖励的生成、发放和冲突处理

# 信号定义
signal reward_distributed(encounter_type: String, rewards: Array)

# 奖励配置
const REWARD_CONFIG = {
	"JiangHuRumor": {  # 江湖传闻
		"silver": {"min": 200, "max": 500},
		"materials": {"min": 5, "max": 10, "type": "common"},
		"description": "江湖传闻"
	},
	"TianCaiDiBao": {  # 天材地宝
		"breakthrough_pills": {"min": 1, "max": 1, "type": "breakthrough"},
		"reset_pills": {"min": 1, "max": 1, "type": "reset"},
		"rare_materials": {"min": 3, "max": 5, "type": "rare"},
		"description": "天材地宝"
	},
	"GaoRenZhiDian": {  # 高人指点
		"attribute_points": {"min": 2, "max": 5},
		"talent_points": {"min": 1, "max": 2},
		"martial_arts_exp": {"min": 50, "max": 100},
		"description": "高人指点"
	},
	"ShiChuanMiJi": {  # 失传秘籍
		"martial_art_fragment": {"min": 1, "max": 1, "type": "fragment"},
		"full_martial_art": {"min": 0, "max": 1, "type": "low_level"},
		"exp": {"min": 500, "max": 1000},
		"description": "失传秘籍"
	},
	"MiJingChallenge": {  # 秘境挑战
		"purple_equipment": {"min": 1, "max": 1, "type": "purple"},
		"exp": {"min": 1000, "max": 2000},
		"legendary_fragment": {"min": 0, "max": 5, "chance": 0.05, "type": "legendary"},
		"description": "秘境挑战"
	}
}

# 变量定义
var player_inventory = null  # 玩家背包引用
var character_stats = null  # 角色属性引用
var martial_arts_manager = null  # 武学管理器引用

# 初始化
func _ready():
	print("奇遇奖励管理器已初始化")
	
	# 初始化各种系统引用（在实际游戏中，这些会通过适当的方式获取）
	# player_inventory = get_inventory_reference()
	# character_stats = get_character_stats_reference()
	# martial_arts_manager = get_martial_arts_manager_reference()

# 分发奖励
func distribute_reward(encounter_type: String, luck_stat: float = 0.0) -> Array:
	var rewards = generate_reward_package(encounter_type, luck_stat)
	
	# 处理奖励冲突
	var processed_rewards = handle_reward_conflicts(rewards)
	
	# 发放奖励
	emit_signal("reward_distributed", encounter_type, processed_rewards)
	
	return processed_rewards

# 生成奖励包
func generate_reward_package(encounter_type: String, luck_stat: float) -> Array:
	var reward_config = REWARD_CONFIG.get(encounter_type, {})
	var rewards = []
	
	if reward_config.is_empty():
		print("错误：未找到奇遇类型 '%s' 的奖励配置" % encounter_type)
		return rewards
	
	# 根据福缘调整奖励质量
	var luck_multiplier = 1.0 + luck_stat / 100.0
	
	# 生成各种奖励
	if reward_config.has("silver"):
		var silver_amount = randi_range(reward_config.silver.min, reward_config.silver.max)
		if luck_stat >= 100:  # 高福缘可能触发双倍奖励
			if randf() < 0.1:  # 10%概率
				silver_amount *= 2
		rewards.append({"type": "silver", "amount": silver_amount})
	
	if reward_config.has("materials"):
		var material_amount = randi_range(reward_config.materials.min, reward_config.materials.max)
		if luck_stat >= 100:  # 高福缘可能触发双倍奖励
			if randf() < 0.1:  # 10%概率
				material_amount *= 2
		rewards.append({"type": "material", "amount": material_amount, "subtype": reward_config.materials.type})
	
	if reward_config.has("attribute_points"):
		var attr_points = randi_range(reward_config.attribute_points.min, reward_config.attribute_points.max)
		rewards.append({"type": "attribute_point", "amount": attr_points})
	
	if reward_config.has("talent_points"):
		var talent_points = randi_range(reward_config.talent_points.min, reward_config.talent_points.max)
		rewards.append({"type": "talent_point", "amount": talent_points})
	
	if reward_config.has("martial_arts_exp"):
		var martial_exp = randi_range(reward_config.martial_arts_exp.min, reward_config.martial_arts_exp.max)
		rewards.append({"type": "martial_art_exp", "amount": martial_exp})
	
	if reward_config.has("breakthrough_pills"):
		var pill_count = randi_range(reward_config.breakthrough_pills.min, reward_config.breakthrough_pills.max)
		rewards.append({"type": "breakthrough_pill", "amount": pill_count})
	
	if reward_config.has("reset_pills"):
		var pill_count = randi_range(reward_config.reset_pills.min, reward_config.reset_pills.max)
		rewards.append({"type": "reset_pill", "amount": pill_count})
	
	if reward_config.has("rare_materials"):
		var material_count = randi_range(reward_config.rare_materials.min, reward_config.rare_materials.max)
		if luck_stat >= 100:  # 高福缘可能触发双倍奖励
			if randf() < 0.1:  # 10%概率
				material_count *= 2
		rewards.append({"type": "material", "amount": material_count, "subtype": reward_config.rare_materials.type})
	
	if reward_config.has("martial_art_fragment"):
		var fragment_count = randi_range(reward_config.martial_art_fragment.min, reward_config.martial_art_fragment.max)
		rewards.append({"type": "martial_art_fragment", "amount": fragment_count})
	
	if reward_config.has("full_martial_art"):
		var art_count = randi_range(reward_config.full_martial_art.min, reward_config.full_martial_art.max)
		if art_count > 0:
			rewards.append({"type": "full_martial_art", "amount": art_count})
	
	if reward_config.has("exp"):
		var exp_amount = randi_range(reward_config.exp.min, reward_config.exp.max)
		rewards.append({"type": "exp", "amount": exp_amount})
	
	if reward_config.has("purple_equipment"):
		var equip_count = randi_range(reward_config.purple_equipment.min, reward_config.purple_equipment.max)
		rewards.append({"type": "purple_equipment", "amount": equip_count})
	
	if reward_config.has("legendary_fragment"):
		if randf() < reward_config.legendary_fragment.chance:
			var fragment_count = randi_range(reward_config.legendary_fragment.min, reward_config.legendary_fragment.max)
			rewards.append({"type": "legendary_fragment", "amount": fragment_count})
	
	return rewards

# 处理奖励冲突
func handle_reward_conflicts(rewards_list: Array) -> Array:
	var processed_rewards = []
	
	for reward in rewards_list:
		var processed_reward = reward.duplicate()
		
		# 检查背包是否已满（假设背包容量为100）
		if reward.type in ["material", "breakthrough_pill", "reset_pill", "martial_art_fragment", "legendary_fragment"]:
			# 如果是可堆叠物品，检查背包是否已满
			# 在实际实现中，这里会检查实际的背包状态
			if is_inventory_full() and not is_stackable_item(reward.type):
				# 如果背包已满且物品不可堆叠，转换为等值银两或EXP
				processed_reward = convert_to_alternative_reward(reward)
		
		# 检查是否已学会武学
		if reward.type == "full_martial_art":
			if has_learned_martial_art(reward):
				# 如果已学会武学，转换为熟练度或银两
				processed_reward = {"type": "martial_art_exp", "amount": 100}
		
		processed_rewards.append(processed_reward)
	
	return processed_rewards

# 检查背包是否已满
func is_inventory_full() -> bool:
	# 在实际实现中，这里会检查实际的背包状态
	# 为了演示，我们随机返回false
	return false

# 检查物品是否可堆叠
func is_stackable_item(item_type: String) -> bool:
	var stackable_types = ["silver", "material", "exp", "breakthrough_pill", "reset_pill", "martial_art_fragment", "legendary_fragment"]
	return stackable_types.has(item_type)

# 检查是否已学会武学
func has_learned_martial_art(reward_data: Dictionary) -> bool:
	# 在实际实现中，这里会检查武学数据库
	# 为了演示，我们随机返回false
	return false

# 将不可堆叠物品转换为替代奖励
func convert_to_alternative_reward(reward: Dictionary) -> Dictionary:
	var value = reward.amount * 10  # 假设每件物品价值10银两
	return {"type": "silver", "amount": value}

# 随机整数范围函数
func randi_range(min_val: int, max_val: int) -> int:
	return min_val + (randi() % (max_val - min_val + 1))

# 测试函数
func test_reward_system():
	print("开始测试奇遇奖励系统...")
	
	# 测试不同类型的奇遇奖励
	var encounter_types = ["JiangHuRumor", "TianCaiDiBao", "GaoRenZhiDian", "ShiChuanMiJi", "MiJingChallenge"]
	
	for encounter_type in encounter_types:
		print("\n测试奇遇类型: %s" % REWARD_CONFIG[encounter_type]["description"])
		var rewards = distribute_reward(encounter_type, 50.0)  # 福缘50
		
		for reward in rewards:
			print("  奖励: %s, 数量: %s" % [reward.type, reward.amount if reward.has("amount") else "N/A"])
	
	print("\n奇遇奖励系统测试完成")

# 获取奖励描述
func get_reward_description(rewards: Array) -> String:
	var description = "获得奖励:\n"
	for reward in rewards:
		var reward_name = get_reward_name(reward.type)
		description += "- %s: %s\n" % [reward_name, reward.amount if reward.has("amount") else reward.type]
	return description

# 获取奖励名称
func get_reward_name(reward_type: String) -> String:
	var names = {
		"silver": "银两",
		"material": "材料",
		"attribute_point": "属性点",
		"talent_point": "天赋点",
		"martial_art_exp": "武学熟练度",
		"breakthrough_pill": "突破丹",
		"reset_pill": "洗点丹",
		"martial_art_fragment": "武学残页",
		"full_martial_art": "完整武学",
		"exp": "经验值",
		"purple_equipment": "紫色装备",
		"legendary_fragment": "传说碎片"
	}
	return names.get(reward_type, reward_type)