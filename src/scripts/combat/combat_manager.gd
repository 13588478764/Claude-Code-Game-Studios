## CombatManager
## 战斗管理器
##
## 实现战斗系统的核心机制，包括回合制战斗流程、行动队列、资源管理等功能。
## 负责战斗状态管理、单位管理、行动执行和战斗日志记录。
##
## 主要功能：
## - 战斗初始化和流程管理
## - 行动队列生成和管理
## - 行动执行和结果处理
## - 资源更新和状态管理
## - 战斗日志记录

extends Node
class_name CombatManager

# ============================================================================
# 常量定义
# ============================================================================

# ============================================================================
# 信号定义
# ============================================================================

signal battle_started
signal battle_ended
signal turn_started(unit)
signal turn_ended(unit)
signal action_executed(action_result)
REPLACE

# 战斗状态枚举
enum BattleState {
	IDLE,          # 空闲状态
	PREPARATION,   # 准备阶段
	BATTLE_TURN,   # 战斗回合中
	POST_ACTION,   # 行动后处理
	CLEANUP        # 清理阶段
}

# 战斗单位数据结构
class BattleUnit:
	var unit_node: Object  # 战斗单位节点
	var initiative: int     # 速度/先攻值，用于行动队列排序
	var current_hp: int    # 当前生命值
	var max_hp: int        # 最大生命值
	var current_internal_energy: int  # 当前内力
	var max_internal_energy: int     # 最大内力
	var stance: int        # 架势值 (0-100)
	var combo_value: int   # 连击值 (0-100)
	var link_gauge: int    # 连携槽 (0-100)
	var attributes: Dictionary  # 角色属性 (力道、身法、根骨、悟性、定力、福缘)
	
	func _init(node: Object, init_attrs: Dictionary):
		unit_node = node
		initiative = init_attrs.get("speed", 10)
		current_hp = init_attrs.get("hp", 100)
		max_hp = init_attrs.get("max_hp", 100)
		current_internal_energy = init_attrs.get("internal_energy", 50)
		max_internal_energy = init_attrs.get("max_internal_energy", 100)
		stance = init_attrs.get("stance", 100)
		combo_value = init_attrs.get("combo_value", 0)
		link_gauge = init_attrs.get("link_gauge", 0)
		attributes = init_attrs.get("attributes", {})

var battle_state: BattleState = BattleState.IDLE
var battle_units: Array[BattleUnit] = []  # 参战单位列表
var action_queue: Array[BattleUnit] = []   # 行动队列
var current_turn_unit: BattleUnit = null  # 当前行动单位
var battle_log: Array[String] = []        # 战斗日志

func _ready():
	# 初始化战斗管理器
	pass

# 开始战斗
func start_battle(units: Array) -> void:
	if battle_state != BattleState.IDLE:
		print("Warning: Battle already in progress")
		return
	
	battle_units.clear()
	action_queue.clear()
	battle_log.clear()
	
	# 添加战斗单位
	for unit in units:
		var attrs = {
			"speed": unit.get("speed", 10),
			"hp": unit.get("hp", 100),
			"max_hp": unit.get("max_hp", 100),
			"internal_energy": unit.get("internal_energy", 50),
			"max_internal_energy": unit.get("max_internal_energy", 100),
			"stance": unit.get("stance", 100),
			"combo_value": unit.get("combo_value", 0),
			"link_gauge": unit.get("link_gauge", 0),
			"attributes": unit.get("attributes", {})
		}
		var battle_unit = BattleUnit.new(unit, attrs)
		battle_units.append(battle_unit)
	
	# 生成行动队列（按身法属性排序）
	generate_action_queue()
	
	battle_state = BattleState.PREPARATION
	emit_signal("battle_started")
	
	# 进入战斗回合
	start_next_turn()

# 生成行动队列（按身法属性从高到低排序）
func generate_action_queue() -> void:
	action_queue = battle_units.duplicate(true)
	# 按先攻值降序排序
	action_queue.sort_custom(func(a, b): return a.initiative > b.initiative)

# 开始下一回合
func start_next_turn() -> void:
	if action_queue.is_empty():
		end_battle()
		return
	
	# 获取下一个行动单位
	current_turn_unit = action_queue.pop_front()
	
	battle_state = BattleState.BATTLE_TURN
	emit_signal("turn_started", current_turn_unit)
	
	# 这里会等待玩家或AI选择行动
	# 在实际实现中，这里会等待输入

# 执行行动
func execute_action(action_data: Dictionary) -> Dictionary:
	if battle_state != BattleState.BATTLE_TURN:
		return {"success": false, "message": "Not in battle turn state"}
	
	var result = {"success": true, "action": action_data}
	
	# 根据行动类型执行不同逻辑
	match action_data.type:
		"attack":
			result = execute_attack(action_data)
		"defend":
			result = execute_defend(action_data)
		"use_skill":
			result = execute_skill(action_data)
		_:
			result = {"success": false, "message": "Unknown action type"}
	
	# 更新资源
	update_resources(current_turn_unit, action_data)
	
	# 发射行动执行信号
	emit_signal("action_executed", result)
	
	# 结束当前回合
	end_current_turn()
	
	return result

# 执行攻击行动
func execute_attack(attack_data: Dictionary) -> Dictionary:
	var attacker = current_turn_unit
	var target_idx = attack_data.target_index
	if target_idx >= battle_units.size():
		return {"success": false, "message": "Invalid target index"}
	
	var target = battle_units[target_idx]
	
	# 计算伤害（简化版）
	var damage = calculate_damage(attacker, target, attack_data)
	
	# 应用伤害
	target.current_hp -= damage
	if target.current_hp < 0:
		target.current_hp = 0
	
	# 更新连击值
	attacker.combo_value = min(100, attacker.combo_value + 10)
	
	# 记录战斗日志
	battle_log.append("%s 对 %s 造成了 %d 点伤害" % [str(attacker.unit_node), str(target.unit_node), damage])
	
	return {
		"success": true,
		"type": "attack",
		"damage_dealt": damage,
		"target_hp_left": target.current_hp
	}

# 执行防御行动
func execute_defend(defend_data: Dictionary) -> Dictionary:
	var defender = current_turn_unit
	
	# 增加架势值
	defender.stance = min(100, defender.stance + 20)
	
	# 记录战斗日志
	battle_log.append("%s 进入防御状态，架势值增加" % str(defender.unit_node))
	
	return {
		"success": true,
		"type": "defend",
		"stance_increased": 20
	}

# 执行技能行动
func execute_skill(skill_data: Dictionary) -> Dictionary:
	var user = current_turn_unit
	var skill_cost = skill_data.get("cost", 10)
	
	# 检查内力是否足够
	if user.current_internal_energy < skill_cost:
		return {"success": false, "message": "内力不足"}
	
	# 消耗内力
	user.current_internal_energy -= skill_cost
	
	# 根据技能类型执行不同效果
	var effect_result = apply_skill_effect(user, skill_data)
	
	# 更新连携槽
	user.link_gauge = min(100, user.link_gauge + 15)
	
	# 记录战斗日志
	battle_log.append("%s 使用了技能 %s" % [str(user.unit_node), skill_data.get("name", "未知技能")])
	
	return {
		"success": true,
		"type": "skill",
		"skill_name": skill_data.get("name", "未知技能"),
		"effect": effect_result
	}

# 计算伤害
func calculate_damage(attacker: BattleUnit, target: BattleUnit, attack_data: Dictionary) -> int:
	# 基础伤害计算（简化版）
	var base_damage = 10 + randi_range(0, 5)
	
	# 考虑攻击方属性
	var attack_attr = attacker.attributes.get("force", 10)
	base_damage += int(base_damage * attack_attr / 50.0)
	
	# 考虑防御方架势
	var defense_reduction = int((100 - target.stance) / 10.0)
	base_damage = max(1, base_damage - defense_reduction)
	
	# 考虑连击值加成
	var combo_bonus = 1.0 + (attacker.combo_value / 100.0 * 0.5)  # 最多50%加成
	base_damage = int(base_damage * combo_bonus)
	
	return base_damage

# 应用技能效果
func apply_skill_effect(user: BattleUnit, skill_data: Dictionary) -> Dictionary:
	# 这里会根据技能数据应用具体效果
	# 简化实现，返回基本效果
	return {"type": "skill_effect", "value": skill_data.get("power", 1)}

# 更新资源
func update_resources(unit: BattleUnit, action_data: Dictionary) -> void:
	# 更新内力（每回合自然回复）
	unit.current_internal_energy = min(
		unit.max_internal_energy,
		unit.current_internal_energy + 5
	)
	
	# 更新架势（每回合少量回复）
	unit.stance = min(100, unit.stance + 5)
	
	# 更新连击值（非攻击行动会逐渐减少）
	if action_data.type != "attack":
		unit.combo_value = max(0, unit.combo_value - 5)
	
	# 更新连携槽（每回合少量回复）
	unit.link_gauge = min(100, unit.link_gauge + 3)

# 结束当前回合
func end_current_turn() -> void:
	if current_turn_unit:
		emit_signal("turn_ended", current_turn_unit)
	
	# 如果战斗单位全部行动完毕，重新生成行动队列
	if action_queue.is_empty():
		generate_action_queue()
	
	# 开始下一回合
	start_next_turn()

# 结束战斗
func end_battle() -> void:
	battle_state = BattleState.CLEANUP
	
	# 检查战斗结果
	var alive_units = []
	for unit in battle_units:
		if unit.current_hp > 0:
			alive_units.append(unit)
	
	var result = {
		"winner": alive_units,
		"battle_log": battle_log.duplicate()
	}
	
	emit_signal("battle_ended", result)
	
	# 重置状态
	battle_state = BattleState.IDLE
	battle_units.clear()
	action_queue.clear()
	current_turn_unit = null

# 检查战斗是否结束
func is_battle_over() -> bool:
	var player_units_alive = 0
	var enemy_units_alive = 0
	
	for unit in battle_units:
		if unit.current_hp > 0:
			# 这里简化处理，假设前一半是玩家单位，后一半是敌人
			if battle_units.find(unit) < ceil(battle_units.size() / 2.0):
				player_units_alive += 1
			else:
				enemy_units_alive += 1
	
	return player_units_alive == 0 or enemy_units_alive == 0

# 获取当前战斗状态
func get_battle_status() -> Dictionary:
	return {
		"state": battle_state,
		"current_turn_unit": current_turn_unit,
		"battle_units": battle_units,
		"action_queue": action_queue,
		"log": battle_log
	}