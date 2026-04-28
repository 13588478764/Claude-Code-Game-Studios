extends Node

# 敌人AI行为管理器
# 实现五种核心战术意识行为：基础攻击、弱点利用、状态管理、生存本能、连携配合

# 常量定义
const BEHAVIOR_TYPES = {
	"BASIC_ATTACK": "基础攻击",
	"WEAKNESS_EXPLOITATION": "弱点利用", 
	"STATUS_MANAGEMENT": "状态管理",
	"SURVIVAL_INSTINCT": "生存本能",
	"COORDINATION": "连携配合"
}

# 变量定义
var combat_system = null
var status_effect_system = null
var martial_arts_system = null

# 初始化
func _ready():
	print("敌人AI行为管理器已初始化")

# 评估基础攻击行为
func evaluate_basic_attack(enemy_data, targets):
	var scores = {}
	
	for target in targets:
		var score = 0
		# 计算伤害期望值
		var expected_damage = calculate_expected_damage(enemy_data, target)
		score += expected_damage * 10  # 伤害权重
		
		# 考虑目标威胁度
		var threat_level = calculate_threat_level(target, enemy_data)
		score += threat_level * 5  # 威胁权重
		
		scores[target.id] = score
	
	return scores

# 评估弱点利用行为
func evaluate_weakness_exploitation(enemy_data, targets):
	var scores = {}
	
	for target in targets:
		var score = 0
		
		# 破防优先：若玩家处于Break状态，AI优先使用高伤害技能
		if is_target_broken(target):
			score += 100  # 破防奖励
		
		# 属性克制：AI倾向于使用克制玩家当前抗性最低属性的武学
		var weakness_score = calculate_weakness_score(enemy_data, target)
		score += weakness_score * 50  # 弱点权重
		
		scores[target.id] = score
	
	return scores

# 评估状态管理行为
func evaluate_status_management(enemy_data, targets):
	var scores = {}
	
	for target in targets:
		var score = 0
		
		# 施加Debuff：若玩家血量健康，AI优先施加负面状态
		if target.hp_ratio > 0.7:
			if has_debuff_skill(enemy_data):
				score += 30  # 施加Debuff奖励
		
		# 解除Buff：若玩家拥有强力增益状态，AI优先使用驱散技能
		if has_strong_buff(target):
			if has_dispel_skill(enemy_data):
				score += 80  # 解除Buff奖励
		
		# 控制链：若队友已施加控制效果，AI跟进高伤技能
		if has_control_chain_opportunity(enemy_data, target):
			score += 20  # 控制链奖励
		
		scores[target.id] = score
	
	return scores

# 评估生存本能行为
func evaluate_survival_instinct(enemy_data, targets):
	var scores = {}
	
	# 检查自身状态
	var self_hp_ratio = enemy_data.hp / enemy_data.max_hp
	
	for target in targets:
		var score = 0
		
		# 撤退/防御：当自身HP < 30%且无治疗手段时，选择防御
		if self_hp_ratio < 0.3:
			if not has_healing_skill(enemy_data):
				score += 40  # 防御奖励
			else:
				score += 10  # 有治疗手段但优先度较低
		
		# 集火威胁：优先攻击对其造成最高伤害的玩家角色
		var threat_to_self = calculate_threat_to_enemy(target, enemy_data)
		score += threat_to_self * 10  # 威胁权重
		
		scores[target.id] = score
	
	return scores

# 评估连携配合行为
func evaluate_coordination(enemy_data, allies):
	var scores = {}
	
	# 检查是否有连携机会
	for ally in allies:
		if ally.id == enemy_data.id:
			continue  # 跳过自己
		
		# 组合技触发：若队友已施加某种状态，AI优先使用能触发连携的技能
		if has_combo_opportunity(ally, enemy_data):
			var combo_score = calculate_combo_score(ally, enemy_data)
			scores[ally.id] = combo_score * 20  # 连携权重
		
		# 保护盟友：若盟友处于危急状态，AI可能选择保护技能
		if is_ally_in_danger(ally):
			var protect_score = calculate_protection_score(ally, enemy_data)
			scores[ally.id] = protect_score * 15  # 保护权重
	end
	
	return scores

# 计算预期伤害
func calculate_expected_damage(attacker, target):
	# 简化的伤害计算
	var base_damage = attacker.attack_power
	var target_defense = target.defense
	var damage = max(1, base_damage - target_defense)
	return damage

# 计算目标威胁等级
func calculate_threat_level(target, enemy_data):
	# 威胁等级基于目标的攻击力和当前血量
	var threat = target.attack_power * (1.0 - target.hp_ratio)  # 血量越低威胁越高
	return threat

# 检查目标是否破防
func is_target_broken(target):
	# 检查目标是否有破防状态
	return target.has_status("broken") if target.has("has_status") else false

# 计算弱点分数
func calculate_weakness_score(enemy_data, target):
	# 计算敌人的攻击属性与目标的抗性匹配度
	var weakness_count = 0
	if enemy_data.attack_attribute == "fire" and target.fire_resistance < 0:
		weakness_count += 1
	if enemy_data.attack_attribute == "ice" and target.ice_resistance < 0:
		weakness_count += 1
	if enemy_data.attack_attribute == "lightning" and target.lightning_resistance < 0:
		weakness_count += 1
	
	return weakness_count

# 检查是否有Debuff技能
func has_debuff_skill(enemy_data):
	# 检查敌人是否有Debuff技能
	return enemy_data.has_debuff_skill if enemy_data.has("has_debuff_skill") else false

# 检查目标是否有强增益
func has_strong_buff(target):
	# 检查目标是否有强增益状态
	return target.has_strong_buff if target.has("has_strong_buff") else false

# 检查是否有驱散技能
func has_dispel_skill(enemy_data):
	# 检查敌人是否有驱散技能
	return enemy_data.has_dispel_skill if enemy_data.has("has_dispel_skill") else false

# 检查是否有控制链机会
func has_control_chain_opportunity(enemy_data, target):
	# 检查是否有控制链机会
	return false  # 简化实现

# 检查是否有治疗技能
func has_healing_skill(enemy_data):
	# 检查敌人是否有治疗技能
	return enemy_data.has_healing_skill if enemy_data.has("has_healing_skill") else false

# 计算对敌人的威胁
func calculate_threat_to_enemy(target, enemy_data):
	# 计算目标对当前敌人的威胁
	var threat = target.attack_power * target.accuracy
	return threat

# 检查是否有连携机会
func has_combo_opportunity(ally, enemy_data):
	# 检查是否有连携机会
	return false  # 简化实现

# 计算连携分数
func calculate_combo_score(ally, enemy_data):
	# 计算连携分数
	return 0  # 简化实现

# 检查盟友是否处于危险
func is_ally_in_danger(ally):
	# 检查盟友是否处于危险状态
	return ally.hp_ratio < 0.3 if ally.has("hp_ratio") else false

# 计算保护分数
func calculate_protection_score(ally, enemy_data):
	# 计算保护分数
	return 0  # 简化实现

# 测试函数
func test_behavior_evaluation():
	print("开始测试AI行为评估...")
	
	# 创建测试数据
	var test_enemy = {
		"id": "test_enemy_1",
		"hp": 50,
		"max_hp": 100,
		"attack_power": 20,
		"attack_attribute": "fire",
		"has_debuff_skill": true,
		"has_dispel_skill": true,
		"has_healing_skill": false,
		"hp_ratio": 0.5
	}
	
	var test_targets = [
		{
			"id": "player_1",
			"hp": 30,
			"max_hp": 100,
			"hp_ratio": 0.3,
			"attack_power": 25,
			"defense": 10,
			"fire_resistance": -0.2,
			"has_strong_buff": false,
			"has_status": func(status): return status == "broken" if status == "broken" else false
		},
		{
			"id": "player_2", 
			"hp": 80,
			"max_hp": 100,
			"hp_ratio": 0.8,
			"attack_power": 15,
			"defense": 8,
			"fire_resistance": 0.1,
			"has_strong_buff": true,
			"has_status": func(status): return false
		}
	]
	
	var test_allies = [
		{
			"id": "ally_1",
			"hp": 40,
			"max_hp": 100,
			"hp_ratio": 0.4
		}
	]
	
	# 测试各种行为评估
	var basic_scores = evaluate_basic_attack(test_enemy, test_targets)
	var weakness_scores = evaluate_weakness_exploitation(test_enemy, test_targets)
	var status_scores = evaluate_status_management(test_enemy, test_targets)
	var survival_scores = evaluate_survival_instinct(test_enemy, test_targets)
	var coordination_scores = evaluate_coordination(test_enemy, test_allies)
	
	print("基础攻击评分: ", basic_scores)
	print("弱点利用评分: ", weakness_scores)
	print("状态管理评分: ", status_scores)
	print("生存本能评分: ", survival_scores)
	print("连携配合评分: ", coordination_scores)
	
	print("AI行为评估测试完成")