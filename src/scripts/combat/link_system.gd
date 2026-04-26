# 武侠奇遇录 - 连携系统
# 实现连携槽、连击、连携攻击和连携条件判定等功能

extends Node

# 信号定义
signal link_gauge_changed(character_id, gauge_value)
signal combo_increased(character_id, combo_count)
signal link_attack_executed(attacker_id, target_id, attack_type)
signal link_condition_met(character_id, condition_type)

# 连携系统配置
var max_link_gauge = 100  # 最大连携槽值
var max_combo_count = 10  # 最大连击数
var link_gauge_per_hit = 10  # 每次攻击增加的连携槽
var link_gauge_per_block = 15  # 每次完美格挡增加的连携槽
var link_gauge_per_weakness = 20  # 每次弱点打击增加的连携槽
var combo_damage_multiplier = 0.1  # 连击伤害加成系数

# 连携攻击类型枚举
enum LinkAttackType {
	FOLLOW_UP = 0,  # 追击
	DUAL_TECH = 1   # 合体技
}

# 战斗角色数据结构
class BattleCharacter:
	var character_id: String
	var link_gauge: int = 0
	var combo_count: int = 0
	var last_target_id: String = ""  # 上次攻击的目标
	var is_player: bool = false
	var teammates: Array[String] = []  # 队友ID列表
	
	func _init(id: String, player: bool, team_ids: Array):
		character_id = id
		is_player = player
		teammates = team_ids

# 存储战斗角色信息
var battle_characters: Dictionary = {}

func _ready():
	print("连携系统初始化完成")

# 初始化连携系统
func initialize(characters: Array):
	"""初始化连携系统，传入战斗角色列表"""
	battle_characters.clear()
	
	for char_data in characters:
		var char = BattleCharacter.new(
			char_data.id,
			char_data.is_player,
			char_data.teammates
		)
		battle_characters[char_data.id] = char
	
	print("连携系统已初始化，角色数量: %d" % battle_characters.size())

# 增加连携槽
func increase_link_gauge(character_id: String, amount: int, source: String = "normal") -> bool:
	"""增加指定角色的连携槽"""
	if not battle_characters.has(character_id):
		return false
	
	var character = battle_characters[character_id]
	var old_gauge = character.link_gauge
	
	# 增加连携槽
	character.link_gauge = min(max_link_gauge, character.link_gauge + amount)
	
	# 如果连携槽发生变化，发送信号
	if character.link_gauge != old_gauge:
		emit_signal("link_gauge_changed", character_id, character.link_gauge)
		return true
	
	return false

# 增加连击数
func increase_combo(character_id: String, target_id: String = "") -> bool:
	"""增加指定角色的连击数"""
	if not battle_characters.has(character_id):
		return false
	
	var character = battle_characters[character_id]
	
	# 如果攻击了不同目标，重置连击数
	if target_id != "" and character.last_target_id != "" and target_id != character.last_target_id:
		character.combo_count = 0
	else:
		# 连续攻击同一目标，增加连击数
		character.combo_count = min(max_combo_count, character.combo_count + 1)
	
	# 更新最后攻击目标
	if target_id != "":
		character.last_target_id = target_id
	
	# 发送连击增加信号
	emit_signal("combo_increased", character_id, character.combo_count)
	return true

# 重置连击数
func reset_combo(character_id: String) -> bool:
	"""重置指定角色的连击数"""
	if not battle_characters.has(character_id):
		return false
	
	var character = battle_characters[character_id]
	if character.combo_count > 0:
		character.combo_count = 0
		emit_signal("combo_increased", character_id, 0)
		return true
	
	return false

# 处理攻击事件
func on_attack_event(attacker_id: String, target_id: String, is_weakness_hit: bool = false) -> Dictionary:
	"""处理攻击事件，更新连携槽和连击数"""
	var result = {
		"success": false,
		"link_gauge_increased": 0,
		"combo_increased": false,
		"message": ""
	}
	
	if not battle_characters.has(attacker_id):
		result.message = "攻击者不存在"
		return result
	
	# 增加连击数
	increase_combo(attacker_id, target_id)
	result.combo_increased = true
	
	# 增加连携槽
	var gauge_increase = link_gauge_per_hit
	if is_weakness_hit:
		gauge_increase = link_gauge_per_weakness
	
	increase_link_gauge(attacker_id, gauge_increase, "attack")
	result.link_gauge_increased = gauge_increase
	result.success = true
	result.message = "攻击事件处理完成"
	
	# 同时增加队友的连携槽（共享机制）
	for teammate_id in battle_characters[attacker_id].teammates:
		if battle_characters.has(teammate_id):
			increase_link_gauge(teammate_id, int(gauge_increase * 0.5), "shared")  # 队友获得一半的连携槽
	
	return result

# 处理格挡事件
func on_block_event(defender_id: String, is_perfect_block: bool = false) -> Dictionary:
	"""处理格挡事件，如果是完美格挡则增加连携槽"""
	var result = {
		"success": false,
		"link_gauge_increased": 0,
		"message": ""
	}
	
	if not is_perfect_block:
		result.message = "非完美格挡，不增加连携槽"
		return result
	
	if not battle_characters.has(defender_id):
		result.message = "防御者不存在"
		return result
	
	# 增加连携槽
	var gauge_increase = link_gauge_per_block
	increase_link_gauge(defender_id, gauge_increase, "block")
	result.link_gauge_increased = gauge_increase
	result.success = true
	result.message = "完美格挡，连携槽增加"
	
	# 同时增加队友的连携槽
	for teammate_id in battle_characters[defender_id].teammates:
		if battle_characters.has(teammate_id):
			increase_link_gauge(teammate_id, int(gauge_increase * 0.5), "shared")
	
	return result

# 检查连携条件
func check_link_condition(character_id: String, attack_type: LinkAttackType) -> Dictionary:
	"""检查连携条件是否满足"""
	var result = {
		"can_execute": false,
		"required_gauge": 0,
		"current_gauge": 0,
		"message": ""
	}
	
	if not battle_characters.has(character_id):
		result.message = "角色不存在"
		return result
	
	var character = battle_characters[character_id]
	result.current_gauge = character.link_gauge
	
	# 不同连携攻击类型需要不同的连携槽
	match attack_type:
		LinkAttackType.FOLLOW_UP:
			result.required_gauge = 20  # 追击需要20点连携槽
		LinkAttackType.DUAL_TECH:
			result.required_gauge = 50  # 合体技需要50点连携槽
		_:
			result.message = "未知的连携攻击类型"
			return result
	
	# 检查是否有足够的连携槽
	if character.link_gauge >= result.required_gauge:
		result.can_execute = true
		result.message = "连携条件满足"
	else:
		result.message = "连携槽不足"
	
	# 检查是否有队友可用（对于合体技）
	if attack_type == LinkAttackType.DUAL_TECH and character.teammates.size() == 0:
		result.can_execute = false
		result.message = "没有可用队友发动合体技"
	
	return result

# 执行连携攻击
func execute_link_attack(attacker_id: String, target_id: String, attack_type: LinkAttackType) -> Dictionary:
	"""执行连携攻击"""
	var result = {
		"success": false,
		"damage_multiplier": 1.0,
		"gauge_consumed": 0,
		"message": ""
	}
	
	# 检查连携条件
	var condition_check = check_link_condition(attacker_id, attack_type)
	if not condition_check.can_execute:
		result.message = "连携条件不满足: " + condition_check.message
		return result
	
	if not battle_characters.has(attacker_id) or not battle_characters.has(target_id):
		result.message = "攻击者或目标不存在"
		return result
	
	var attacker = battle_characters[attacker_id]
	
	# 消耗连携槽
	var gauge_to_consume = condition_check.required_gauge
	attacker.link_gauge = max(0, attacker.link_gauge - gauge_to_consume)
	emit_signal("link_gauge_changed", attacker_id, attacker.link_gauge)
	result.gauge_consumed = gauge_to_consume
	
	# 根据连携攻击类型计算伤害倍率
	match attack_type:
		LinkAttackType.FOLLOW_UP:
			result.damage_multiplier = 1.3  # 追击造成1.3倍伤害
			result.message = "追击发动成功"
		LinkAttackType.DUAL_TECH:
			# 寻找可用队友参与合体技
			var available_teammate = find_available_teammate(attacker_id)
			if available_teammate != "":
				result.damage_multiplier = 2.0  # 合体技造成2.0倍伤害
				result.message = "合体技发动成功，队友%s参与" % available_teammate
			else:
				result.damage_multiplier = 1.5  # 没有队友时降低伤害
				result.message = "合体技发动但没有队友参与"
	
	result.success = true
	
	# 发送连携攻击执行信号
	emit_signal("link_attack_executed", attacker_id, target_id, attack_type)
	
	return result

# 查找可用队友
func find_available_teammate(character_id: String) -> String:
	"""查找可用的队友"""
	if not battle_characters.has(character_id):
		return ""
	
	var character = battle_characters[character_id]
	
	for teammate_id in character.teammates:
		if battle_characters.has(teammate_id):
			var teammate = battle_characters[teammate_id]
			# 检查队友是否存活（HP > 0）
			if teammate.get("current_hp", 1) > 0:
				return teammate_id
	
	return ""

# 获取角色连携信息
func get_character_link_info(character_id: String) -> Dictionary:
	"""获取角色的连携相关信息"""
	if not battle_characters.has(character_id):
		return {}
	
	var character = battle_characters[character_id]
	return {
		"link_gauge": character.link_gauge,
		"combo_count": character.combo_count,
		"max_link_gauge": max_link_gauge,
		"max_combo_count": max_combo_count,
		"teammates": character.teammates
	}

# 重置战斗状态
func reset_battle_state():
	"""重置战斗状态，清空所有连携槽和连击数"""
	for id in battle_characters.keys():
		var character = battle_characters[id]
		character.link_gauge = 0
		character.combo_count = 0
		emit_signal("link_gauge_changed", id, 0)
		emit_signal("combo_increased", id, 0)

# 计算连击伤害加成
func calculate_combo_damage_bonus(character_id: String) -> float:
	"""计算连击伤害加成"""
	if not battle_characters.has(character_id):
		return 1.0
	
	var character = battle_characters[character_id]
	return 1.0 + (character.combo_count * combo_damage_multiplier)