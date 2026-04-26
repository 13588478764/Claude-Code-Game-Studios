# 武侠奇遇录 - 经验值系统
# 负责管理经验值获取、升级计算和境界突破逻辑

extends Node

# 经验值来源类型
enum ExpSource {
	COMBAT,        # 战斗收益
	EXPLORATION,   # 探索与奇遇
	QUEST          # 任务进度
}

# 经验值配置
var config = {
	"base_exp_values": {  # 敌人基础EXP值
		"bandit": 50,
		"wolf": 40,
		"cultist": 80,
		"elite_guard": 120,
		"ice_spirit": 150,
		"stone_golem": 200,
		"thunder_beast": 280,
		"shadow_assassin": 250,
		"ancient_tree_spirit": 350,
		"golden_dragon": 500
	},
	"scaling_factor": 1.2,           # 等级差异缩放因子
	"level_bonus_max": 1.5,         # 高等级敌人最大加成
	"level_penalty_min": 0.2,       # 低等级敌人最小惩罚
	"max_level_diff": 10,           # 最大等级差（超过不给EXP）
	"wisdom_bonus_per_10": 0.01,    # 每10点悟性+1%EXP
	"party_share_enabled": true,     # 队伍共享EXP
	"reserve_member_bonus": 0.5,     # 后备队员获得50%EXP
	"global_multiplier": 1.0,        # 全局倍率（双倍经验活动等）
	"perfect_victory_bonus": 0.2,    # 完美胜利额外奖励
	"combo_bonus": 0.1              # 连携/连招奖励
}

# 升级曲线配置
var level_curve = {
	"early_levels": {"start": 1, "end": 10, "exponent": 1.0},      # 初期：线性增长
	"mid_levels": {"start": 11, "end": 30, "exponent": 1.5},      # 中期：温和指数
	"late_levels": {"start": 31, "end": 99, "exponent": 2.5}      # 后期：陡峭指数
}

# 境界配置
var realms = [
	{"name": "炼气", "start_level": 1, "end_level": 10},
	{"name": "筑基", "start_level": 11, "end_level": 20},
	{"name": "金丹", "start_level": 21, "end_level": 30},
	{"name": "元婴", "start_level": 31, "end_level": 40},
	{"name": "化神", "start_level": 41, "end_level": 50},
	{"name": "返虚", "start_level": 51, "end_level": 60},
	{"name": "合道", "start_level": 61, "end_level": 70},
	{"name": "大乘", "start_level": 71, "end_level": 80},
	{"name": "渡劫", "start_level": 81, "end_level": 90},
	{"name": "真仙", "start_level": 91, "end_level": 99}
]

func _ready():
	print("经验值系统初始化完成")

func calculate_combat_exp(player_character, enemy_data, battle_result):
	"""计算战斗获得的经验值"""
	var base_exp = 0
	
	# 获取敌人基础EXP值
	if config["base_exp_values"].has(enemy_data["id"]):
		base_exp = config["base_exp_values"][enemy_data["id"]]
	else:
		# 如果没有预定义值，基于敌人等级计算
		base_exp = enemy_data["level"] * 10
	
	# 等级缩放修正
	var level_diff = enemy_data["level"] - player_character.level
	var level_bonus = 1.0
	
	if level_diff > 0:
		# 挑战高等级敌人获得加成
		level_bonus = min(config["level_bonus_max"], 1.0 + (level_diff * 0.1))
	elif level_diff < 0:
		# 低等级敌人获得惩罚
		if abs(level_diff) > config["max_level_diff"]:
			return 0  # 超过最大等级差，不获得EXP
		level_bonus = max(config["level_penalty_min"], 1.0 + (level_diff * 0.08))
	
	# 悟性属性修正
	var wisdom_bonus = 1.0 + (player_character.attributes["intelligence"] / 10.0) * config["wisdom_bonus_per_10"]
	
	# 战斗结果修正
	var result_bonus = 1.0
	if battle_result.get("perfect_victory", false):
		result_bonus += config["perfect_victory_bonus"]
	if battle_result.get("combo_used", false):
		result_bonus += config["combo_bonus"]
	
	# 全局倍率
	var global_multiplier = config["global_multiplier"]
	
	# 最终EXP计算
	var final_exp = base_exp * level_bonus * wisdom_bonus * result_bonus * global_multiplier
	
	return int(final_exp)

func calculate_exploration_exp(exp_type, location_data):
	"""计算探索获得的经验值"""
	var base_exp = 0
	
	match exp_type:
		"first_discovery":  # 首次探索区域
			base_exp = 100
		"encounter_completion":  # 完成奇遇
			base_exp = 200
		"collection":  # 收集图鉴
			base_exp = 50
	
	# 位置难度修正
	if location_data.has("difficulty"):
		base_exp *= (1.0 + location_data["difficulty"] * 0.5)
	
	return int(base_exp * config["global_multiplier"])

func calculate_quest_exp(quest_data):
	"""计算任务获得的经验值"""
	var base_exp = 0
	
	match quest_data["type"]:
		"main":  # 主线任务
			base_exp = quest_data["level"] * 50
		"side":  # 支线任务
			base_exp = quest_data["level"] * 25
		"daily":  # 日常任务
			base_exp = quest_data["level"] * 10
	
	return int(base_exp * config["global_multiplier"])

func get_exp_required_for_level(target_level):
	"""获取升级到目标等级所需的经验值"""
	if target_level <= 1:
		return 0
	if target_level > 99:
		target_level = 99
	
	# 确定当前阶段的指数系数
	var exponent = 1.0
	if target_level >= level_curve["late_levels"]["start"]:
		exponent = level_curve["late_levels"]["exponent"]
	elif target_level >= level_curve["mid_levels"]["start"]:
		exponent = level_curve["mid_levels"]["exponent"]
	else:
		exponent = level_curve["early_levels"]["exponent"]
	
	# 基础值根据阶段调整
	var base_value = 100
	if target_level >= level_curve["late_levels"]["start"]:
		base_value = 200
	elif target_level >= level_curve["mid_levels"]["start"]:
		base_value = 150
	
	# 计算所需EXP
	var exp_required = base_value * pow(target_level, exponent)
	return int(exp_required)

func distribute_exp_to_party(exp_amount, party_members, active_members):
	"""分配EXP给队伍成员"""
	var exp_distribution = []
	
	if not config["party_share_enabled"]:
		# 不共享EXP，只给活跃成员
		for member in active_members:
			exp_distribution.append({"character": member, "exp": exp_amount})
		return exp_distribution
	
	# 计算总份额
	var total_shares = active_members.size() + (party_members.size() - active_members.size()) * config["reserve_member_bonus"]
	var exp_per_share = exp_amount / total_shares
	
	# 分配EXP
	for member in party_members:
		var is_active = active_members.has(member)
		var shares = is_active ? 1.0 : config["reserve_member_bonus"]
		var member_exp = int(exp_per_share * shares)
		
		exp_distribution.append({"character": member, "exp": member_exp})
	
	return exp_distribution

func check_level_up(current_exp, current_level):
	"""检查是否可以升级"""
	var exp_needed = get_exp_required_for_level(current_level + 1)
	return current_exp >= exp_needed

func check_realm_breakthrough(current_level):
	"""检查是否达到境界突破条件"""
	for i in range(realms.size()):
		var realm = realms[i]
		if current_level == realm["end_level"]:
			return {"can_breakthrough": true, "realm_index": i, "realm_name": realm["name"]}
	
	return {"can_breakthrough": false, "realm_index": -1, "realm_name": ""}

func get_current_realm_by_level(level):
	"""根据等级获取当前境界"""
	for realm in realms:
		if level >= realm["start_level"] and level <= realm["end_level"]:
			return realm
	return realms[realms.size() - 1]  # 返回最高境界

func apply_exp_bonus(bonus_type, multiplier):
	"""应用EXP加成（如双倍经验活动）"""
	match bonus_type:
		"global":
			config["global_multiplier"] = multiplier
		"combat":
			# 可以添加特定类型的加成
			pass
		"exploration":
			pass
		"quest":
			pass

func reset_exp_bonuses():
	"""重置所有EXP加成"""
	config["global_multiplier"] = 1.0

# 调试函数
func debug_print_exp_info(character_level, current_exp):
	"""打印EXP信息用于调试"""
	var exp_needed = get_exp_required_for_level(character_level + 1)
	var current_realm = get_current_realm_by_level(character_level)
	var breakthrough_info = check_realm_breakthrough(character_level)
	
	print("=== EXP信息 ===")
	print("当前等级: %d" % character_level)
	print("当前EXP: %d" % current_exp)
	print("升级所需EXP: %d" % exp_needed)
	print("当前境界: %s (%d-%d)" % [current_realm["name"], current_realm["start_level"], current_realm["end_level"]])
	print("可突破: %s" % ("是" if breakthrough_info["can_breakthrough"] else "否"))
	if breakthrough_info["can_breakthrough"]:
		print("突破境界: %s" % breakthrough_info["realm_name"])
	print("================")

# 测试函数
func test_exp_calculation():
	"""测试EXP计算"""
	print("=== EXP计算测试 ===")
	
	# 测试升级所需EXP
	for level in [1, 5, 10, 15, 20, 30, 50, 80, 99]:
		var exp_needed = get_exp_required_for_level(level)
		print("升到%d级需要: %d EXP" % [level, exp_needed])
	
	# 测试战斗EXP计算
	var test_character = {
		"level": 10,
		"attributes": {"intelligence": 20}
	}
	var test_enemy = {"id": "bandit", "level": 12}
	var battle_result = {"perfect_victory": true, "combo_used": true}
	
	var combat_exp = calculate_combat_exp(test_character, test_enemy, battle_result)
	print("战斗EXP测试: %d" % combat_exp)
	
	# 测试境界突破
	for level in [10, 20, 30, 99]:
		var breakthrough = check_realm_breakthrough(level)
		print("等级%d突破检查: %s" % [level, "可突破" if breakthrough["can_breakthrough"] else "不可突破"])
	
	print("==================")

# UI回调函数
func _on_test_exp_calculation_pressed():
	"""测试EXP计算按钮回调"""
	test_exp_calculation()

func _on_test_level_up_pressed():
	"""测试升级逻辑按钮回调"""
	# 测试不同等级的升级需求
	var test_levels = [1, 5, 10, 15, 20, 30, 50, 80, 99]
	for level in test_levels:
		var exp_needed = get_exp_required_for_level(level + 1)
		var can_level_up = check_level_up(exp_needed - 1, level)
		var can_level_up_exact = check_level_up(exp_needed, level)
		
		print("等级%d: 需要%d EXP, %d EXP时可升级: %s, %d EXP时可升级: %s" % [
			level, exp_needed, exp_needed - 1, "是" if can_level_up else "否",
			exp_needed, "是" if can_level_up_exact else "否"
		])

func _on_test_realm_breakthrough_pressed():
	"""测试境界突破按钮回调"""
	# 测试关键等级的境界突破
	var test_levels = [9, 10, 11, 19, 20, 21, 29, 30, 31, 98, 99]
	for level in test_levels:
		var breakthrough_info = check_realm_breakthrough(level)
		var current_realm = get_current_realm_by_level(level)
		
		print("等级%d: 当前境界=%s, 可突破=%s" % [
			level, current_realm["name"], "是" if breakthrough_info["can_breakthrough"] else "否"
		])</content>