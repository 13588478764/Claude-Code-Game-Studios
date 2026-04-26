# 武侠奇遇录 - 奇遇系统
# 负责管理奇遇触发、概率计算、奖励发放和状态管理

extends Node

# 奇遇类型枚举
enum EncounterType {
	JIANGHU_RUMOR,      # 江湖传闻
	HEAVENLY_TREASURE,  # 天材地宝  
	WISE_MASTER,        # 高人指点
	LOST_MARTIAL_SCROLL, # 失传秘籍
	SECRET_REALM        # 秘境挑战
}

# 触发时机枚举
enum TriggerContext {
	MAP_MOVEMENT,    # 大地图移动
	COMBAT_VICTORY,  # 战斗胜利后
	REST_SAVE,       # 休息/存档
	SPECIAL_LOCATION # 特定地点
}

# 奇遇配置
var config = {
	"base_trigger_chances": {
		TriggerContext.MAP_MOVEMENT: 0.05,      # 5%
		TriggerContext.COMBAT_VICTORY: 0.02,   # 2%
		TriggerContext.REST_SAVE: 0.03,        # 3%
		TriggerContext.SPECIAL_LOCATION: 0.12   # 12% (平均值)
	},
	"type_weights": {
		EncounterType.JIANGHU_RUMOR: 40,
		EncounterType.HEAVENLY_TREASURE: 30,
		EncounterType.WISE_MASTER: 15,
		EncounterType.LOST_MARTIAL_SCROLL: 10,
		EncounterType.SECRET_REALM: 5
	},
	"max_trigger_chance": 0.2,    # 20%上限
	"luck_influence_factor": 1.0, # 福缘影响系数
	"weight_redistribution_factor": 0.5, # 权重重分配系数
	"consecutive_failures_limit": 20, # 保底触发次数
	"cooldown_moves": 5           # 同区域冷却移动次数
}

# 状态管理
var completed_encounters = []    # 已完成的奇遇ID列表
var consecutive_failures = 0    # 连续未触发次数
var last_trigger_move_count = 0 # 上次触发的移动计数
var current_move_count = 0      # 当前移动计数

func _ready():
	print("奇遇系统初始化完成")
	load_encounter_state()

func can_trigger_encounter(trigger_context, character_luck, location_data=null):
	"""检查是否可以触发奇遇"""
	# 检查冷却时间
	if trigger_context == TriggerContext.MAP_MOVEMENT:
		if current_move_count - last_trigger_move_count < config["cooldown_moves"]:
			return false
	
	# 计算基础触发概率
	var base_chance = config["base_trigger_chances"][trigger_context]
	
	# 应用福缘修正
	var final_chance = base_chance * (1.0 + (character_luck / 100.0) * config["luck_influence_factor"])
	final_chance = min(final_chance, config["max_trigger_chance"])
	
	# 检查保底机制
	if consecutive_failures >= config["consecutive_failures_limit"]:
		return true
	
	# 随机判定
	return randf() < final_chance

func trigger_encounter(character_luck, character_level, character_realm, trigger_context):
	"""触发奇遇"""
	# 重置连续失败计数
	consecutive_failures = 0
	
	# 更新触发计数
	if trigger_context == TriggerContext.MAP_MOVEMENT:
		last_trigger_move_count = current_move_count
	
	# 选择奇遇类型
	var encounter_type = select_encounter_type(character_luck)
	
	# 获取可用的奇遇列表
	var available_encounters = get_available_encounters(encounter_type, character_level, character_realm)
	
	if available_encounters.size() == 0:
		push_warning("没有可用的奇遇")
		return null
	
	# 随机选择一个奇遇
	var selected_encounter_id = available_encounters[randi() % available_encounters.size()]
	var encounter_data = DatabaseManager.get_encounter(selected_encounter_id)
	
	if encounter_data == null:
		push_warning("奇遇数据不存在: %s" % selected_encounter_id)
		return null
	
	print("触发奇遇: %s (%s)" % [encounter_data["name"], get_encounter_type_name(encounter_type)])
	return {"id": selected_encounter_id, "data": encounter_data, "type": encounter_type}

func select_encounter_type(character_luck):
	"""根据福缘选择奇遇类型"""
	# 计算调整后的权重
	var adjusted_weights = {}
	
	for type in config["type_weights"]:
		var base_weight = config["type_weights"][type]
		
		# 高价值奇遇权重增加
		if type == EncounterType.WISE_MASTER or type == EncounterType.LOST_MARTIAL_SCROLL or type == EncounterType.SECRET_REALM:
			adjusted_weights[type] = base_weight * (1.0 + (character_luck / 100.0) * config["weight_redistribution_factor"])
		else:
			# 低价值奇遇权重减少
			adjusted_weights[type] = base_weight / (1.0 + (character_luck / 100.0) * config["weight_redistribution_factor"])
	
	# 权重随机选择
	var total_weight = 0
	for weight in adjusted_weights.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var accumulated_weight = 0
	
	for type in adjusted_weights:
		accumulated_weight += adjusted_weights[type]
		if random_value <= accumulated_weight:
			return type
	
	# 默认返回第一个类型
	return EncounterType.JIANGHU_RUMOR

func get_available_encounters(encounter_type, character_level, character_realm):
	"""获取可用的奇遇列表"""
	var available_ids = []
	
	# 根据类型筛选奇遇
	var type_name = ""
	match encounter_type:
		EncounterType.JIANGHU_RUMOR:
			type_name = "jianghu_rumor"
		EncounterType.HEAVENLY_TREASURE:
			type_name = "heavenly_treasure"
		EncounterType.WISE_MASTER:
			type_name = "wise_master_guidance"
		EncounterType.LOST_MARTIAL_SCROLL:
			type_name = "lost_martial_scroll"
		EncounterType.SECRET_REALM:
			type_name = "secret_realm_discovery"
	
	# 获取所有奇遇ID
	var all_encounter_ids = DatabaseManager.get_all_encounter_ids()
	
	for encounter_id in all_encounter_ids:
		var encounter_data = DatabaseManager.get_encounter(encounter_id)
		if encounter_data == null:
			continue
		
		# 检查类型匹配
		if encounter_data["id"] != type_name:
			continue
		
		# 检查是否已完成（一次性奇遇）
		if completed_encounters.has(encounter_id):
			continue
		
		# 检查等级和境界要求
		if encounter_data.has("trigger_conditions"):
			var conditions = encounter_data["trigger_conditions"]
			
			# 检查最低福缘
			if conditions.has("min_luck") and character_luck < conditions["min_luck"]:
				continue
			
			# 检查最低等级
			if conditions.has("min_level") and character_level < conditions["min_level"]:
				continue
		
		available_ids.append(encounter_id)
	
	return available_ids

func execute_encounter_reward(encounter_data, character_data):
	"""执行奇遇奖励"""
	var rewards = encounter_data["rewards"]
	
	# 处理属性点奖励
	if rewards.has("attribute_points"):
		var min_points = rewards["attribute_points"]["min"]
		var max_points = rewards["attribute_points"]["max"]
		var attribute_points = randi_range(min_points, max_points)
		character_data["attribute_points"] += attribute_points
		print("获得属性点: %d" % attribute_points)
	
	# 处理天赋点奖励
	if rewards.has("talent_points"):
		var min_points = rewards["talent_points"]["min"]
		var max_points = rewards["talent_points"]["max"]
		var talent_points = randi_range(min_points, max_points)
		character_data["talent_points"] += talent_points
		print("获得天赋点: %d" % talent_points)
	
	# 处理EXP奖励
	if rewards.has("exp_bonus"):
		var min_exp = rewards["exp_bonus"]["min"]
		var max_exp = rewards["exp_bonus"]["max"]
		var exp_bonus = randi_range(min_exp, max_exp)
		character_data["exp"] += exp_bonus
		print("获得经验值: %d" % exp_bonus)
	
	# 处理物品奖励
	if rewards.has("consumables"):
		for consumable in rewards["consumables"]:
			var item_id = consumable["item_id"]
			var chance = consumable["chance"]
			var quantity = consumable["quantity"]
			
			if randf() < chance:
				add_item_to_inventory(item_id, quantity)
				print("获得物品: %s x%d" % [item_id, quantity])
	
	# 处理稀有物品奖励
	if rewards.has("rare_items"):
		for rare_item in rewards["rare_items"]:
			add_item_to_inventory(rare_item, 1)
			print("获得稀有物品: %s" % rare_item)
	
	# 处理武学奖励
	if rewards.has("martial_arts"):
		for martial_art in rewards["martial_arts"]:
			learn_martial_art(martial_art)
			print("学会武学: %s" % martial_art)
	
	# 处理武学残页奖励
	if rewards.has("martial_art_fragments"):
		var min_fragments = rewards["martial_art_fragments"]["min"]
		var max_fragments = rewards["martial_art_fragments"]["max"]
		var fragments = randi_range(min_fragments, max_fragments)
		character_data["martial_art_fragments"] += fragments
		print("获得武学残页: %d" % fragments)
	
	# 处理银两奖励
	if rewards.has("gold"):
		var min_gold = rewards["gold"]["min"]
		var max_gold = rewards["gold"]["max"]
		var gold = randi_range(min_gold, max_gold)
		character_data["gold"] += gold
		print("获得银两: %d" % gold)

func add_item_to_inventory(item_id, quantity):
	"""添加物品到背包"""
	# 这里应该调用物品系统
	# 简化实现：暂时只打印信息
	pass

func learn_martial_art(martial_art_id):
	"""学习武学"""
	# 这里应该调用武学系统
	# 简化实现：暂时只打印信息
	pass

func mark_encounter_completed(encounter_id):
	"""标记奇遇为已完成"""
	if not completed_encounters.has(encounter_id):
		completed_encounters.append(encounter_id)
		save_encounter_state()

func increment_move_count():
	"""增加移动计数"""
	current_move_count += 1

func increment_consecutive_failures():
	"""增加连续失败计数"""
	consecutive_failures += 1
	if consecutive_failures > config["consecutive_failures_limit"]:
		consecutive_failures = config["consecutive_failures_limit"]

func get_encounter_type_name(encounter_type):
	"""获取奇遇类型名称"""
	match encounter_type:
		EncounterType.JIANGHU_RUMOR:
			return "江湖传闻"
		EncounterType.HEAVENLY_TREASURE:
			return "天材地宝"
		EncounterType.WISE_MASTER:
			return "高人指点"
		EncounterType.LOST_MARTIAL_SCROLL:
			return "失传秘籍"
		EncounterType.SECRET_REALM:
			return "秘境挑战"
		_:
			return "未知"

func save_encounter_state():
	"""保存奇遇状态"""
	# 这里应该调用存档系统
	# 简化实现：暂时只打印信息
	print("保存奇遇状态: %d个已完成奇遇, %d次连续失败" % [completed_encounters.size(), consecutive_failures])

func load_encounter_state():
	"""加载奇遇状态"""
	# 这里应该调用存档系统
	# 简化实现：暂时只打印信息
	print("加载奇遇状态")

# 调试函数
func debug_print_encounter_info():
	"""打印奇遇信息用于调试"""
	print("=== 奇遇系统信息 ===")
	print("已完成奇遇: %d" % completed_encounters.size())
	print("连续失败次数: %d" % consecutive_failures)
	print("当前移动计数: %d" % current_move_count)
	print("上次触发移动计数: %d" % last_trigger_move_count)
	print("====================")

# 测试函数
func test_encounter_probability():
	"""测试奇遇触发概率"""
	print("=== 奇遇触发概率测试 ===")
	
	var test_luck_values = [0, 25, 50, 75, 100]
	var test_contexts = [TriggerContext.MAP_MOVEMENT, TriggerContext.COMBAT_VICTORY, TriggerContext.REST_SAVE]
	
	for luck in test_luck_values:
		print("福缘=%d 的触发概率:" % luck)
		for context in test_contexts:
			var base_chance = config["base_trigger_chances"][context]
			var final_chance = base_chance * (1.0 + (luck / 100.0) * config["luck_influence_factor"])
			final_chance = min(final_chance, config["max_trigger_chance"])
			print("  %s: %.1f%%" % [get_trigger_context_name(context), final_chance * 100])
	
	print("========================")

func get_trigger_context_name(context):
	"""获取触发时机名称"""
	match context:
		TriggerContext.MAP_MOVEMENT:
			return "大地图移动"
		TriggerContext.COMBAT_VICTORY:
			return "战斗胜利后"
		TriggerContext.REST_SAVE:
			return "休息/存档"
		TriggerContext.SPECIAL_LOCATION:
			return "特定地点"
		_:
			return "未知"

# UI回调函数
func _on_test_trigger_probability_pressed():
	"""测试触发概率按钮回调"""
	test_encounter_probability()

func _on_test_encounter_selection_pressed():
	"""测试奇遇选择按钮回调"""
	# 测试不同福缘值的奇遇类型选择
	var test_luck_values = [0, 25, 50, 75, 100]
	
	print("=== 奇遇类型选择测试 ===")
	for luck in test_luck_values:
		print("福缘=%d 的奇遇类型选择:" % luck)
		for i in range(10):  # 每个福缘值测试10次
			var encounter_type = select_encounter_type(luck)
			print("  第%d次: %s" % [i+1, get_encounter_type_name(encounter_type)])
	
	print("========================")

func _on_test_reward_execution_pressed():
	"""测试奖励执行按钮回调"""
	# 获取一个奇遇进行测试
	var test_encounters = ["jianghu_rumor", "heavenly_treasure", "wise_master_guidance"]
	
	print("=== 奇遇奖励执行测试 ===")
	for encounter_id in test_encounters:
		var encounter_data = DatabaseManager.get_encounter(encounter_id)
		if encounter_data != null:
			var character_data = {
				"attribute_points": 0,
				"talent_points": 0,
				"exp": 0,
				"gold": 0,
				"martial_art_fragments": 0
			}
			
			print("测试奇遇: %s" % encounter_data["name"])
			execute_encounter_reward(encounter_data, character_data)
			print("  最终角色数据: 属性点=%d, 天赋点=%d, EXP=%d, 银两=%d, 武学残页=%d" % [
				character_data["attribute_points"],
				character_data["talent_points"],
				character_data["exp"],
				character_data["gold"],
				character_data["martial_art_fragments"]
			])
	
	print("========================")

func _on_test_guaranteed_trigger_pressed():
	"""测试保底触发按钮回调"""
	# 设置连续失败次数达到保底
	consecutive_failures = config["consecutive_failures_limit"]
	
	print("=== 保底触发测试 ===")
	print("当前连续失败次数: %d" % consecutive_failures)
	
	# 测试各种触发时机都应该强制触发
	var test_contexts = [TriggerContext.MAP_MOVEMENT, TriggerContext.COMBAT_VICTORY, TriggerContext.REST_SAVE]
	var character_luck = 0  # 低福缘确保正常情况下不会触发
	
	for context in test_contexts:
		var can_trigger = can_trigger_encounter(context, character_luck)
		print("%s: %s" % [get_trigger_context_name(context), "可以触发" if can_trigger else "无法触发"])
	
	# 测试触发奇遇
	var triggered_encounter = trigger_encounter(character_luck, 10, 1, TriggerContext.MAP_MOVEMENT)
	if triggered_encounter != null:
		print("成功触发保底奇遇: %s" % triggered_encounter["data"]["name"])
	else:
		print("保底触发失败")
	
	print("========================")</content>