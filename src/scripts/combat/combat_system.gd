# 武侠奇遇录 - 战斗系统
# 负责管理战斗逻辑、回合制、伤害计算和战斗效果

extends Node

# 战斗状态枚举
enum CombatState {
	ENCOUNTER,      # 遭遇阶段
	PLAYER_INPUT,   # 玩家输入阶段  
	EXECUTION,      # 执行演出阶段
	ENEMY_TURN,     # 敌方回合阶段
	END_PHASE       # 回合结束阶段
}

# 角色战斗数据类
class CombatCharacter:
	var character_id = ""
	var level = 0
	var realm = 0
	var health = 0
	var max_health = 0
	var defense = 0
	var poise = 0          # 架势值
	var max_poise = 0
	var qi = 0             # 内力
	var max_qi = 0
	var evasion = 0.0      # 闪避率
	var critical_rate = 0.0 # 暴击率
	var hit_rate = 0.0     # 命中率
	var attributes = {}    # 六维属性
	var equipped_items = [] # 装备列表
	var martial_arts = []  # 武学列表
	var status_effects = [] # 状态效果
	var is_player = false
	var is_down = false    # 是否倒地
	var is_break = false   # 是否破防
	
	func _init(char_data):
		character_id = char_data["id"]
		level = char_data["level"]
		realm = char_data["realm"]
		health = char_data["health"]
		max_health = char_data["max_health"]
		defense = char_data["defense"]
		poise = char_data["poise"]
		max_poise = char_data["max_poise"]
		qi = char_data["qi"]
		max_qi = char_data["max_qi"]
		evasion = char_data["evasion"]
		critical_rate = char_data["critical_rate"]
		hit_rate = char_data["hit_rate"]
		attributes = char_data["attributes"]
		equipped_items = char_data["equipped_items"]
		martial_arts = char_data["martial_arts"]
		status_effects = char_data["status_effects"]
		is_player = char_data["is_player"]

# 战斗管理器状态
var current_state = CombatState.ENCOUNTER
var player_characters = []    # 玩家角色列表
var enemy_characters = []     # 敌人角色列表
var turn_order = []          # 行动顺序
var current_turn_index = 0
var combo_count = 0          # 连击数
var link_gauge = 0.0         # 连携槽 (0.0-1.0)
var battle_log = []          # 战斗日志

# 战斗配置
var config = {
	"qi_regen_min": 0.05,    # 内力回复率最小值
	"qi_regen_max": 0.1,     # 内力回复率最大值
	"crit_multiplier_min": 1.5, # 暴击倍数最小值
	"crit_multiplier_max": 2.5, # 暴击倍数最大值
	"weakness_multiplier": 1.5, # 弱点克制倍数
	"break_multiplier": 1.5,    # 破防倍数
	"random_variance_min": 0.95, # 随机浮动最小值
	"random_variance_max": 1.05  # 随机浮动最大值
}

func _ready():
	print("战斗系统初始化完成")

func start_battle(player_party, enemy_group):
	"""开始战斗"""
	player_characters = []
	enemy_characters = []
	
	# 初始化玩家角色
	for player_data in player_party:
		var combat_char = CombatCharacter.new(player_data)
		player_characters.append(combat_char)
	
	# 初始化敌人角色
	for enemy_data in enemy_group:
		var combat_char = CombatCharacter.new(enemy_data)
		enemy_characters.append(combat_char)
	
	# 计算行动顺序
	calculate_turn_order()
	
	# 设置初始状态
	current_state = CombatState.PLAYER_INPUT
	current_turn_index = 0
	
	print("战斗开始！玩家角色: %d, 敌人: %d" % [player_characters.size(), enemy_characters.size()])

func calculate_turn_order():
	"""计算行动顺序"""
	turn_order = []
	
	# 添加所有角色到行动队列
	for char in player_characters:
		turn_order.append({"character": char, "initiative": calculate_initiative(char)})
	
	for char in enemy_characters:
		turn_order.append({"character": char, "initiative": calculate_initiative(char)})
	
	# 按先攻值排序（高到低）
	turn_order.sort_custom(self, "_sort_by_initiative")

func calculate_initiative(character):
	"""计算先攻值"""
	# 基于身法属性和随机因子
	var base_initiative = character.attributes["agility"]
	var random_factor = randf_range(0.9, 1.1)
	return base_initiative * random_factor

func _sort_by_initiative(a, b):
	"""排序函数：按先攻值降序"""
	return a["initiative"] > b["initiative"]

func execute_player_action(action_data):
	"""执行玩家行动"""
	if current_state != CombatState.PLAYER_INPUT:
		return
	
	var attacker = action_data["attacker"]
	var target = action_data["target"]
	var martial_art_id = action_data["martial_art_id"]
	
	# 消耗内力和架势
	var martial_art = DatabaseManager.get_martial_art(martial_art_id)
	if martial_art == null:
		push_error("武学不存在: %s" % martial_art_id)
		return
	
	# 检查资源是否足够
	if attacker.qi < martial_art["cost"]["qi"]:
		push_warning("内力不足")
		return
	if attacker.poise < martial_art["cost"]["poise"]:
		push_warning("架势不足")
		return
	
	# 消耗资源
	attacker.qi -= martial_art["cost"]["qi"]
	attacker.poise -= martial_art["cost"]["poise"]
	
	# 执行攻击
	var damage_result = calculate_damage(attacker, target, martial_art)
	
	# 应用伤害
	apply_damage(target, damage_result["final_damage"])
	
	# 处理特殊效果
	handle_special_effects(attacker, target, martial_art, damage_result)
	
	# 更新连击和连携
	update_combo_and_link(attacker, target, damage_result)
	
	# 记录战斗日志
	battle_log.append({
		"attacker": attacker.character_id,
		"target": target.character_id,
		"martial_art": martial_art_id,
		"damage": damage_result["final_damage"],
		"is_critical": damage_result["is_critical"],
		"is_weakness": damage_result["is_weakness_hit"]
	})
	
	# 切换到执行状态
	current_state = CombatState.EXECUTION
	
	# 检查战斗是否结束
	check_battle_end()

func calculate_damage(attacker, target, martial_art):
	"""计算伤害"""
	# 获取基础属性
	var attacker_attrs = attacker.attributes
	var target_attrs = target.attributes
	
	# 计算基础攻击力
	var base_attack = 0
	if martial_art["damage_type"] == "physical":
		base_attack = attacker_attrs["strength"] * 2 + martial_art["base_multiplier"] * 10
	elif martial_art["damage_type"] == "energy":
		base_attack = attacker_attrs["intelligence"] * 2 + martial_art["base_multiplier"] * 10
	
	# 计算目标防御力
	var target_defense = 0
	if martial_art["damage_type"] == "physical":
		target_defense = target_attrs["constitution"] + target_attrs["willpower"]
	elif martial_art["damage_type"] == "energy":
		target_defense = target_attrs["intelligence"] + target_attrs["willpower"]
	
	# 基础伤害 = 攻击力 - 防御力
	var base_damage = max(1, base_attack - target_defense)
	
	# 检查暴击
	var is_critical = false
	var crit_multiplier = 1.0
	if randf() < attacker.critical_rate:
		is_critical = true
		crit_multiplier = randf_range(config["crit_multiplier_min"], config["crit_multiplier_max"])
	
	# 检查弱点克制
	var is_weakness_hit = false
	var weakness_multiplier = 1.0
	if check_weakness(martial_art["element"], target):
		is_weakness_hit = true
		weakness_multiplier = config["weakness_multiplier"]
	
	# 检查破防状态
	var break_multiplier = 1.0
	if target.is_break:
		break_multiplier = config["break_multiplier"]
	
	# 连击加成
	var combo_multiplier = 1.0 + (combo_count * 0.05)  # 每段连击+5%伤害
	
	# 随机浮动
	var random_variance = randf_range(config["random_variance_min"], config["random_variance_max"])
	
	# 最终伤害
	var final_damage = base_damage * crit_multiplier * combo_multiplier * weakness_multiplier * break_multiplier * random_variance
	
	return {
		"base_damage": base_damage,
		"final_damage": int(final_damage),
		"is_critical": is_critical,
		"is_weakness_hit": is_weakness_hit,
		"crit_multiplier": crit_multiplier,
		"weakness_multiplier": weakness_multiplier,
		"break_multiplier": break_multiplier,
		"combo_multiplier": combo_multiplier,
		"random_variance": random_variance
	}

func check_weakness(attack_element, target):
	"""检查元素弱点"""
	if attack_element == "none":
		return false
	
	# 五行克制关系
	var weaknesses = {
		"fire": ["wood", "metal"],
		"water": ["fire"],
		"earth": ["water"],
		"metal": ["wood"],
		"wood": ["earth", "water"]
	}
	
	# 检查目标是否有对应弱点
	if weaknesses.has(attack_element):
		for weakness in weaknesses[attack_element]:
			if target.attributes.has(weakness + "_weakness") and target.attributes[weakness + "_weakness"]:
				return true
	
	return false

func apply_damage(target, damage):
	"""应用伤害"""
	target.health -= damage
	if target.health <= 0:
		target.health = 0
		# 处理死亡逻辑
		handle_character_death(target)

func handle_special_effects(attacker, target, martial_art, damage_result):
	"""处理特殊效果"""
	# 处理状态效果
	if martial_art.has("status_effects"):
		for effect in martial_art["status_effects"]:
			apply_status_effect(target, effect)
	
	# 处理治疗效果
	if martial_art.has("healing"):
		var heal_amount = martial_art["healing"]["amount"] + attacker.attributes["intelligence"] * martial_art["healing"]["scaling"]
		attacker.health = min(attacker.max_health, attacker.health + int(heal_amount))
	
	# 处理Buff效果
	if martial_art.has("buffs"):
		for buff in martial_art["buffs"]:
			apply_buff(attacker, buff)

func update_combo_and_link(attacker, target, damage_result):
	"""更新连击和连携"""
	# 连击数增加
	combo_count += 1
	
	# 连携槽增加
	link_gauge = min(1.0, link_gauge + 0.2)  # 每次攻击增加20%连携槽
	
	# 如果触发弱点打击，额外增加连携槽
	if damage_result["is_weakness_hit"]:
		link_gauge = min(1.0, link_gauge + 0.3)
	
	# 如果暴击，额外增加连携槽
	if damage_result["is_critical"]:
		link_gauge = min(1.0, link_gauge + 0.1)

func apply_status_effect(target, effect):
	"""应用状态效果"""
	target.status_effects.append({
		"type": effect["type"],
		"duration": effect["duration"],
		"damage_per_turn": effect.get("damage_per_turn", 0),
		"chance": effect.get("chance", 1.0)
	})

func apply_buff(character, buff):
	"""应用Buff效果"""
	character.status_effects.append({
		"type": buff["type"],
		"amount": buff["amount"],
		"duration": buff["duration"]
	})

func handle_character_death(character):
	"""处理角色死亡"""
	if character.is_player:
		# 玩家角色死亡
		print("玩家角色 %s 死亡！" % character.character_id)
	else:
		# 敌人死亡
		print("敌人 %s 被击败！" % character.character_id)
		# 移除敌人
		enemy_characters.erase(character)

func check_battle_end():
	"""检查战斗是否结束"""
	# 检查玩家是否全部死亡
	var all_players_dead = true
	for player in player_characters:
		if player.health > 0:
			all_players_dead = false
			break
	
	if all_players_dead:
		end_battle(false)  # 玩家失败
		return
	
	# 检查敌人是否全部被击败
	if enemy_characters.size() == 0:
		end_battle(true)   # 玩家胜利
		return

func end_battle(is_victory):
	"""结束战斗"""
	if is_victory:
		print("战斗胜利！")
		# 分发奖励
		distribute_rewards()
	else:
		print("战斗失败！")
	
	# 重置战斗状态
	reset_battle_state()

func distribute_rewards():
	"""分发战斗奖励"""
	# 这里应该调用经验值系统和物品掉落系统
	# 暂时只打印信息
	print("分发战斗奖励...")

func reset_battle_state():
	"""重置战斗状态"""
	player_characters = []
	enemy_characters = []
	turn_order = []
	current_turn_index = 0
	combo_count = 0
	link_gauge = 0.0
	battle_log = []
	current_state = CombatState.ENCOUNTER

# 调试函数
func debug_print_battle_info():
	"""打印战斗信息用于调试"""
	print("=== 战斗信息 ===")
	print("当前状态: %s" % current_state)
	print("玩家角色: %d" % player_characters.size())
	for i in range(player_characters.size()):
		var char = player_characters[i]
		print("  %s: HP=%d/%d, Qi=%d/%d, Poise=%d/%d" % [
			char.character_id, char.health, char.max_health, char.qi, char.max_qi, char.poise, char.max_poise
		])
	
	print("敌人角色: %d" % enemy_characters.size())
	for i in range(enemy_characters.size()):
		var char = enemy_characters[i]
		print("  %s: HP=%d/%d, Qi=%d/%d, Poise=%d/%d" % [
			char.character_id, char.health, char.max_health, char.qi, char.max_qi, char.poise, char.max_poise
		])
	
	print("连击数: %d" % combo_count)
	print("连携槽: %.1f%%" % (link_gauge * 100))
	print("战斗日志: %d 条" % battle_log.size())
	print("================")

# UI回调函数
func _on_start_battle_pressed():
	"""开始战斗测试"""
	# 创建测试玩家角色数据
	var player_data = {
		"id": "player_main",
		"level": 10,
		"realm": 1,
		"health": 200,
		"max_health": 200,
		"defense": 30,
		"poise": 50,
		"max_poise": 50,
		"qi": 100,
		"max_qi": 100,
		"evasion": 0.1,
		"critical_rate": 0.15,
		"hit_rate": 0.95,
		"attributes": {
			"strength": 25,
			"agility": 20,
			"constitution": 22,
			"intelligence": 18,
			"willpower": 16,
			"luck": 12
		},
		"equipped_items": ["rare_sword", "rare_helmet"],
		"martial_arts": ["basic_sword", "fire_palm"],
		"status_effects": [],
		"is_player": true
	}
	
	# 创建测试队友角色数据
	var teammate_data = {
		"id": "player_teammate",
		"level": 8,
		"realm": 0,
		"health": 150,
		"max_health": 150,
		"defense": 25,
		"poise": 40,
		"max_poise": 40,
		"qi": 80,
		"max_qi": 80,
		"evasion": 0.15,
		"critical_rate": 0.1,
		"hit_rate": 0.9,
		"attributes": {
			"strength": 20,
			"agility": 25,
			"constitution": 18,
			"intelligence": 22,
			"willpower": 14,
			"luck": 10
		},
		"equipped_items": ["common_sword", "common_helmet"],
		"martial_arts": ["basic_sword", "water_sword"],
		"status_effects": [],
		"is_player": true
	}
	
	# 创建测试敌人数据
	var enemy_data = {
		"id": "test_bandit",
		"level": 5,
		"realm": 0,
		"health": 100,
		"max_health": 100,
		"defense": 20,
		"poise": 30,
		"max_poise": 30,
		"qi": 50,
		"max_qi": 50,
		"evasion": 0.05,
		"critical_rate": 0.05,
		"hit_rate": 0.85,
		"attributes": {
			"strength": 15,
			"agility": 12,
			"constitution": 14,
			"intelligence": 8,
			"willpower": 10,
			"luck": 6,
			"wood_weakness": true
		},
		"equipped_items": ["common_sword"],
		"martial_arts": ["basic_sword"],
		"status_effects": [],
		"is_player": false
	}
	
	# 开始战斗
	start_battle([player_data, teammate_data], [enemy_data])
	
	# 打印战斗信息
	debug_print_battle_info()

func _on_execute_action_pressed():
	"""执行攻击测试"""
	if current_state != CombatState.PLAYER_INPUT:
		print("当前不是玩家输入阶段")
		return
	
	if player_characters.size() == 0 or enemy_characters.size() == 0:
		print("没有有效的战斗角色")
		return
	
	# 获取第一个玩家和第一个敌人
	var attacker = player_characters[0]
	var target = enemy_characters[0]
	
	# 使用火掌攻击（对木属性弱点）
	var action_data = {
		"attacker": attacker,
		"target": target,
		"martial_art_id": "fire_palm"
	}
	
	execute_player_action(action_data)
	
	# 打印战斗信息
	debug_print_battle_info()</content>