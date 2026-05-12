## CombatManager
## 武侠奇遇录 - 战斗管理器
##
## 实现战斗系统的核心机制，包括回合制战斗流程、行动队列、资源管理等功能。
## 负责战斗状态管理、单位管理、行动执行和战斗日志记录。
##
## 依赖关系：
## - BattleUnit: 战斗单位数据结构
## - DamageCalculator: 伤害计算
## - SkillSystem: 技能系统
##
## 主要功能：
## - 战斗初始化和流程管理（准备、回合、清理）
## - 行动队列生成和管理（按先攻值排序）
## - 行动执行和结果处理（攻击、防御、技能）
## - 资源更新和状态管理（内力、架势、连击）
## - 战斗日志记录（行动历史）

extends Node

class_name CombatManager

# ============================================================================
# 战斗配置（从 data/combat_config.json 加载）
# ============================================================================

## 战斗配置数据
var _combat_config: Dictionary = {}

## 资源回复配置
var _resource_recovery: Dictionary = {}

## 战斗行动数值配置
var _combat_action_values: Dictionary = {}

## 伤害公式配置
var _damage_formulas: Dictionary = {}

## 资源上限配置
var _resource_defaults: Dictionary = {}

# ============================================================================
# 配置访问属性（保持向后兼容）
# ============================================================================

## 内力自然回复量
var internal_energy_recovery: int:
	get: return _resource_recovery.get("internal_energy_recovery", 5)

## 架势自然回复量
var stance_recovery: int:
	get: return _resource_recovery.get("stance_recovery", 5)

## 连携槽自然回复量
var link_gauge_recovery: int:
	get: return _resource_recovery.get("link_gauge_recovery", 3)

## 连击值衰减量
var combo_value_decay: int:
	get: return _resource_recovery.get("combo_decay_non_attack", 5)

## 攻击连击值增加量
var attack_combo_increase: int:
	get: return _combat_action_values.get("attack_combo_increase", 10)

## 防御架势值增加量
var defend_stance_increase: int:
	get: return _combat_action_values.get("defend_stance_increase", 20)

## 技能连携槽增加量
var skill_link_gauge_increase: int:
	get: return _combat_action_values.get("skill_link_gauge_increase", 15)

## 基础伤害值
var base_damage: int:
	get: return _damage_formulas.get("base_damage", 10)

## 伤害随机范围
var damage_random_range: int:
	get: return _damage_formulas.get("damage_random_range", 5)

## 连击最大加成比例
var max_combo_bonus: float:
	get: return _damage_formulas.get("max_combo_bonus", 0.5)

## 最大架势值
var max_stance: int:
	get: return _resource_defaults.get("stance_max", 100)

## 最大连击值
var max_combo: int:
	get: return _resource_defaults.get("combo_max", 100)

## 最大连携槽
var max_link_gauge: int:
	get: return _resource_defaults.get("link_gauge_max", 100)

# ============================================================================
# 信号定义
# ============================================================================

## 战斗开始信号
signal battle_started()

## 战斗结束信号
signal battle_ended(result: Dictionary)

## 回合开始信号
signal turn_started(unit: BattleUnit)

## 回合结束信号
signal turn_ended(unit: BattleUnit)

## 行动执行信号
signal action_executed(action_result: Dictionary)

## 战斗状态改变信号
signal battle_state_changed(new_state: BattleState)

## 单位生命值改变信号
signal unit_hp_changed(unit: BattleUnit, old_hp: int, new_hp: int)

## 单位资源改变信号
signal unit_resource_changed(unit: BattleUnit, resource_type: String, old_value: int, new_value: int)

# ============================================================================
# 枚举定义
# ============================================================================

## 战斗状态枚举
enum BattleState {
	IDLE,          ## 空闲状态
	PREPARATION,   ## 准备阶段
	BATTLE_TURN,   ## 战斗回合中
	POST_ACTION,   ## 行动后处理
	CLEANUP        ## 清理阶段
}

# ============================================================================
# 内部类定义
# ============================================================================

## 战斗单位数据结构
class BattleUnit:
	## 战斗单位节点（可以是 Object 节点引用，也可以是 Dictionary 数据）
	## 注意：不能限定为 Object 类型——Dictionary 是 Godot 4 的 Variant 内置类型，
	## 并不继承自 Object，赋值时会触发类型不匹配错误。
	var unit_node
	
	## 速度/先攻值，用于行动队列排序
	var initiative: int
	
	## 当前生命值
	var current_hp: int
	
	## 最大生命值
	var max_hp: int
	
	## 当前内力
	var current_internal_energy: int
	
	## 最大内力
	var max_internal_energy: int
	
	## 架势值 (0-100)
	var stance: int
	
	## 连击值 (0-100)
	var combo_value: int
	
	## 连携槽 (0-100)
	var link_gauge: int
	
	## 角色属性 (力道、身法、根骨、悟性、定力、福缘)
	var attributes: Dictionary
	
	## 构造函数
	## @param node_or_data: 战斗单位节点或数据字典
	## @param init_attrs: 初始属性字典
	func _init(node_or_data, init_attrs: Dictionary) -> void:
		if node_or_data is Object:
			unit_node = node_or_data
		elif node_or_data is Dictionary:
			unit_node = node_or_data
			# 如果传入的是数据字典，从中提取属性
			initiative = initiative if init_attrs.has("speed") else node_or_data.get("speed", 10)
			current_hp = node_or_data.get("hp", 100)
			max_hp = node_or_data.get("max_hp", 100)
			current_internal_energy = node_or_data.get("internal_energy", 50)
			max_internal_energy = node_or_data.get("max_internal_energy", 100)
			stance = node_or_data.get("stance", 100)
			combo_value = node_or_data.get("combo_value", 0)
			link_gauge = node_or_data.get("link_gauge", 0)
			attributes = node_or_data.get("attributes", {})
			return
		initiative = init_attrs.get("speed", 10)
		current_hp = init_attrs.get("hp", 100)
		max_hp = init_attrs.get("max_hp", 100)
		current_internal_energy = init_attrs.get("internal_energy", 50)
		max_internal_energy = init_attrs.get("max_internal_energy", 100)
		stance = init_attrs.get("stance", 100)
		combo_value = init_attrs.get("combo_value", 0)
		link_gauge = init_attrs.get("link_gauge", 0)
		attributes = init_attrs.get("attributes", {})

# ============================================================================
# 成员变量
# ============================================================================

## 当前战斗状态
var battle_state: BattleState = BattleState.IDLE

## 参战单位列表
var battle_units: Array[BattleUnit] = []

## 行动队列
var action_queue: Array[BattleUnit] = []

## 当前行动单位
var current_turn_unit: BattleUnit = null

## 战斗日志
var battle_log: Array[String] = []

## 伤害计算器（依赖注入）
var _damage_calculator: DamageCalculator = null

## GameEvents 全局信号总线（依赖注入）
var _game_events: Node = null

## 回合计数器（用于 GameEvents 信号）
var _turn_counter: int = 0

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化战斗管理器
func _ready() -> void:
	_initialize_combat_manager()

## 初始化战斗管理器
func _initialize_combat_manager() -> void:
	_load_combat_config()
	_initialize_dependencies()
	print("CombatManager: 战斗管理器已初始化")

## 初始化依赖注入
func _initialize_dependencies() -> void:
	# 获取伤害计算器
	if has_node("/root/DamageCalculator"):
		_damage_calculator = get_node("/root/DamageCalculator") as DamageCalculator
	else:
		_damage_calculator = DamageCalculator.new()
		add_child(_damage_calculator)
		print("CombatManager: 创建了本地 DamageCalculator 实例")
	
	# 获取 GameEvents 全局信号总线
	if has_node("/root/GameEvents"):
		_game_events = get_node("/root/GameEvents")
	
	# 连接战斗信号到 GameEvents（如果可用）
	_connect_global_signals()

## 加载战斗配置文件
func _load_combat_config() -> void:
	var config_path := "res://data/combat_config.json"
	if not FileAccess.file_exists(config_path):
		push_warning("CombatManager: 战斗配置文件不存在: %s，使用默认值" % config_path)
		return
	
	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_error("CombatManager: 无法打开战斗配置文件: %s" % config_path)
		return
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_text)
	
	if parse_result != OK:
		push_error("CombatManager: 战斗配置文件 JSON 解析失败: %s" % config_path)
		return
	
	_combat_config = json.data
	_resource_recovery = _combat_config.get("resource_recovery", {})
	_combat_action_values = _combat_config.get("combat_action_values", {})
	_damage_formulas = _combat_config.get("damage_formulas", {})
	_resource_defaults = _combat_config.get("resource_defaults", {})
	
	print("CombatManager: 战斗配置已从 %s 加载" % config_path)

## 连接局部信号到全局 GameEvents（P0-3 修复）
func _connect_global_signals() -> void:
	if _game_events == null:
		return
	
	# 局部信号转发到 GameEvents
	battle_started.connect(func(): _game_events.combat_started.emit())
	battle_ended.connect(func(result): _game_events.combat_ended.emit(result.get("victory", false), result))
	turn_started.connect(_on_turn_started_global)

## 回合开始全局信号转发
func _on_turn_started_global(_unit: BattleUnit) -> void:
	_turn_counter += 1
	_game_events.combat_turn_changed.emit(_turn_counter)

# ============================================================================
# 战斗流程管理
# ============================================================================

## 开始战斗
## @param units: 参战单位数组
func start_battle(units: Array) -> void:
	if battle_state != BattleState.IDLE:
		push_warning("CombatManager: 战斗已在进行中")
		return
	
	_reset_battle_state()
	_initialize_battle_units(units)
	generate_action_queue()
	
	battle_state = BattleState.PREPARATION
	battle_state_changed.emit(battle_state)
	battle_started.emit()
	
	# 进入战斗回合
	start_next_turn()

## 重置战斗状态
func _reset_battle_state() -> void:
	battle_units.clear()
	action_queue.clear()
	battle_log.clear()
	_turn_counter = 0

## 初始化战斗单位
## @param units: 参战单位数组
func _initialize_battle_units(units: Array) -> void:
	for unit in units:
		var attrs: Dictionary = {
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
		var battle_unit: BattleUnit = BattleUnit.new(unit, attrs)
		battle_units.append(battle_unit)

## 生成行动队列（按先攻值从高到低排序）
func generate_action_queue() -> void:
	action_queue = battle_units.duplicate()
	# 按先攻值降序排序
	action_queue.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool: return a.initiative > b.initiative)

## 开始下一回合
func start_next_turn() -> void:
	# 检查战斗是否结束
	if is_battle_over():
		end_battle()
		return
	
	if action_queue.is_empty():
		generate_action_queue()
	
	# 获取下一个行动单位
	current_turn_unit = action_queue.pop_front()
	
	battle_state = BattleState.BATTLE_TURN
	battle_state_changed.emit(battle_state)
	turn_started.emit(current_turn_unit)
	
	# 这里会等待玩家或AI选择行动
	# 在实际实现中，这里会等待输入

## 结束当前回合
func end_current_turn() -> void:
	if current_turn_unit:
		turn_ended.emit(current_turn_unit)
	
	# 开始下一回合
	start_next_turn()

## 结束战斗
func end_battle() -> void:
	battle_state = BattleState.CLEANUP
	battle_state_changed.emit(battle_state)
	
	# 检查战斗结果
	var result: Dictionary = _calculate_battle_result()
	
	battle_ended.emit(result)
	
	# 重置状态
	battle_state = BattleState.IDLE
	battle_state_changed.emit(battle_state)
	_reset_battle_state()

## 计算战斗结果
## @return 战斗结果字典
func _calculate_battle_result() -> Dictionary:
	var alive_units: Array = []
	for unit in battle_units:
		if unit.current_hp > 0:
			alive_units.append(unit)
	
	return {
		"winner": alive_units,
		"battle_log": battle_log.duplicate()
	}

# ============================================================================
# 行动执行
# ============================================================================

## 执行行动
## @param action_data: 行动数据字典
## @return 行动结果字典
func execute_action(action_data: Dictionary) -> Dictionary:
	if battle_state != BattleState.BATTLE_TURN:
		push_error("CombatManager: 不在战斗回合状态")
		return {"success": false, "message": "Not in battle turn state"}
	
	var result: Dictionary = _process_action(action_data)
	
	# 更新资源
	update_resources(current_turn_unit, action_data)
	
	# 发射行动执行信号
	action_executed.emit(result)
	
	# 结束当前回合
	end_current_turn()
	
	return result

## 处理行动
## @param action_data: 行动数据字典
## @return 行动结果字典
func _process_action(action_data: Dictionary) -> Dictionary:
	# 根据行动类型执行不同逻辑
	match action_data.get("type", ""):
		"attack":
			return execute_attack(action_data)
		"defend":
			return execute_defend(action_data)
		"use_skill":
			return execute_skill(action_data)
		_:
			push_error("CombatManager: 未知的行动类型: %s" % action_data.get("type", ""))
			return {"success": false, "message": "Unknown action type"}

## 执行攻击行动
## @param attack_data: 攻击数据字典
## @return 攻击结果字典
func execute_attack(attack_data: Dictionary) -> Dictionary:
	var attacker: BattleUnit = current_turn_unit
	var target_idx: int = attack_data.get("target_index", -1)
	
	# 验证目标索引
	if target_idx < 0 or target_idx >= battle_units.size():
		push_error("CombatManager: 无效的目标索引: %d" % target_idx)
		return {"success": false, "message": "Invalid target index"}
	
	var target: BattleUnit = battle_units[target_idx]
	
	# 计算伤害
	var damage: int = calculate_damage(attacker, target, attack_data)
	
	# 应用伤害
	var old_hp: int = target.current_hp
	target.current_hp = max(0, target.current_hp - damage)
	unit_hp_changed.emit(target, old_hp, target.current_hp)
	
	# 更新连击值
	var old_combo: int = attacker.combo_value
	attacker.combo_value = min(max_combo, attacker.combo_value + attack_combo_increase)
	unit_resource_changed.emit(attacker, "combo", old_combo, attacker.combo_value)
	
	# 记录战斗日志
	_log_battle_action("%s 对 %s 造成了 %d 点伤害" % [str(attacker.unit_node), str(target.unit_node), damage])
	
	return {
		"success": true,
		"type": "attack",
		"damage_dealt": damage,
		"target_hp_left": target.current_hp
	}

## 执行防御行动
## @param defend_data: 防御数据字典
## @return 防御结果字典
func execute_defend(defend_data: Dictionary) -> Dictionary:
	var defender: BattleUnit = current_turn_unit
	
	# 增加架势值
	var old_stance: int = defender.stance
	defender.stance = min(max_stance, defender.stance + defend_stance_increase)
	unit_resource_changed.emit(defender, "stance", old_stance, defender.stance)
	
	# 记录战斗日志
	_log_battle_action("%s 进入防御状态，架势值增加" % str(defender.unit_node))
	
	return {
		"success": true,
		"type": "defend",
		"stance_increased": defend_stance_increase
	}

## 执行技能行动
## @param skill_data: 技能数据字典
## @return 技能结果字典
func execute_skill(skill_data: Dictionary) -> Dictionary:
	var user: BattleUnit = current_turn_unit
	var skill_cost: int = skill_data.get("cost", 10)
	
	# 检查内力是否足够
	if user.current_internal_energy < skill_cost:
		push_warning("CombatManager: 内力不足，无法使用技能")
		return {"success": false, "message": "内力不足"}
	
	# 消耗内力
	var old_energy: int = user.current_internal_energy
	user.current_internal_energy -= skill_cost
	unit_resource_changed.emit(user, "internal_energy", old_energy, user.current_internal_energy)
	
	# 根据技能类型执行不同效果
	var effect_result: Dictionary = apply_skill_effect(user, skill_data)
	
	# 更新连携槽
	var old_link: int = user.link_gauge
	user.link_gauge = min(max_link_gauge, user.link_gauge + skill_link_gauge_increase)
	unit_resource_changed.emit(user, "link_gauge", old_link, user.link_gauge)
	
	# 记录战斗日志
	_log_battle_action("%s 使用了技能 %s" % [str(user.unit_node), skill_data.get("name", "未知技能")])
	
	return {
		"success": true,
		"type": "skill",
		"skill_name": skill_data.get("name", "未知技能"),
		"effect": effect_result
	}

# ============================================================================
# 伤害计算
# ============================================================================

## 计算伤害（委托给 DamageCalculator）
## @param attacker: 攻击方战斗单位
## @param target: 目标战斗单位
## @param attack_data: 攻击数据字典
## @return 最终伤害值
func calculate_damage(attacker: BattleUnit, target: BattleUnit, attack_data: Dictionary) -> int:
	# 确定伤害类型（默认物理伤害，可通过 attack_data 指定）
	var damage_type: int = attack_data.get("damage_type", DamageCalculator.DamageType.PHYSICAL)
	
	# 委托给 DamageCalculator 计算基础伤害
	var base_dmg: int = 1
	if _damage_calculator != null:
		# 需要创建临时的 Node 包装器来适配 BattleUnit
		var attacker_node := _create_damage_node(attacker, attack_data)
		var target_node := _create_damage_node(target, {})
		base_dmg = _damage_calculator.calculate_base_damage(attacker_node, target_node, damage_type)
		attacker_node.queue_free()
		target_node.queue_free()
	else:
		# 回退：使用本地简化计算
		base_dmg = _calculate_damage_fallback(attacker, target, attack_data)
	
	# 应用连击值加成（战斗系统特有逻辑）
	var combo_bonus: float = 1.0 + (float(attacker.combo_value) / float(max_combo) * max_combo_bonus)
	base_dmg = int(base_dmg * combo_bonus)
	
	return base_dmg

## 创建伤害计算适配节点
## @param unit: 战斗单位
## @param attack_data: 攻击数据
## @return 临时 Node，用于 DamageCalculator 计算
func _create_damage_node(unit: BattleUnit, attack_data: Dictionary) -> Node:
	var node := Node.new()
	
	# 设置元数据（DamageCalculator 通过 has_meta/get_meta 读取）
	node.set_meta("strength", unit.attributes.get("force", 10))
	node.set_meta("constitution", unit.attributes.get("constitution", 10))
	node.set_meta("wisdom", unit.attributes.get("wisdom", 10))
	node.set_meta("weapon_attack", attack_data.get("weapon_attack", 0))
	node.set_meta("armor", max_stance - unit.stance)  # 架势越低， armor 越高
	node.set_meta("qi_power", unit.current_internal_energy / 10)
	node.set_meta("qi_resistance", unit.stance / 10)
	
	return node

## 回退伤害计算（当 DamageCalculator 不可用时）
## @param attacker: 攻击方战斗单位
## @param target: 目标战斗单位
## @param attack_data: 攻击数据字典
## @return 基础伤害值
func _calculate_damage_fallback(attacker: BattleUnit, target: BattleUnit, attack_data: Dictionary) -> int:
	var base_dmg: int = base_damage + randi_range(0, damage_random_range)
	
	var attack_attr: int = attacker.attributes.get("force", 10)
	var force_div: float = _damage_formulas.get("force_divisor", 50.0)
	base_dmg += int(base_dmg * attack_attr / force_div)
	
	var stance_def_div: float = _damage_formulas.get("stance_defense_divisor", 10.0)
	var defense_reduction: int = int((max_stance - target.stance) / stance_def_div)
	base_dmg = max(1, base_dmg - defense_reduction)
	
	return base_dmg

## 设置伤害计算器（依赖注入）
## @param calc: 伤害计算器实例
func set_damage_calculator(calc: DamageCalculator) -> void:
	_damage_calculator = calc

## 应用技能效果
## @param user: 使用者战斗单位
## @param skill_data: 技能数据字典
## @return 技能效果字典
func apply_skill_effect(user: BattleUnit, skill_data: Dictionary) -> Dictionary:
	# 这里会根据技能数据应用具体效果
	# 简化实现，返回基本效果
	return {"type": "skill_effect", "value": skill_data.get("power", 1)}

# ============================================================================
# 资源管理
# ============================================================================

## 更新资源
## @param unit: 战斗单位
## @param action_data: 行动数据字典
func update_resources(unit: BattleUnit, action_data: Dictionary) -> void:
	# 更新内力（每回合自然回复）
	var old_energy: int = unit.current_internal_energy
	unit.current_internal_energy = min(
		unit.max_internal_energy,
		unit.current_internal_energy + internal_energy_recovery
	)
	if old_energy != unit.current_internal_energy:
		unit_resource_changed.emit(unit, "internal_energy", old_energy, unit.current_internal_energy)
	
	# 更新架势（每回合少量回复）
	var old_stance: int = unit.stance
	unit.stance = min(max_stance, unit.stance + stance_recovery)
	if old_stance != unit.stance:
		unit_resource_changed.emit(unit, "stance", old_stance, unit.stance)
	
	# 更新连击值（非攻击行动会逐渐减少）
	if action_data.get("type", "") != "attack":
		var old_combo: int = unit.combo_value
		unit.combo_value = max(0, unit.combo_value - combo_value_decay)
		if old_combo != unit.combo_value:
			unit_resource_changed.emit(unit, "combo", old_combo, unit.combo_value)
	
	# 更新连携槽（每回合少量回复）
	var old_link: int = unit.link_gauge
	unit.link_gauge = min(max_link_gauge, unit.link_gauge + link_gauge_recovery)
	if old_link != unit.link_gauge:
		unit_resource_changed.emit(unit, "link_gauge", old_link, unit.link_gauge)

# ============================================================================
# 战斗状态查询
# ============================================================================

## 检查战斗是否结束
## @return 战斗是否结束
func is_battle_over() -> bool:
	var player_units_alive: int = 0
	var enemy_units_alive: int = 0
	
	for unit in battle_units:
		if unit.current_hp > 0:
			# 这里简化处理，假设前一半是玩家单位，后一半是敌人
			if battle_units.find(unit) < ceil(float(battle_units.size()) / 2.0):
				player_units_alive += 1
			else:
				enemy_units_alive += 1
	
	return player_units_alive == 0 or enemy_units_alive == 0

## 获取当前战斗状态
## @return 战斗状态字典
func get_battle_status() -> Dictionary:
	return {
		"state": battle_state,
		"current_turn_unit": current_turn_unit,
		"battle_units": battle_units,
		"action_queue": action_queue,
		"log": battle_log.duplicate()
	}

# ============================================================================
# 辅助方法
# ============================================================================

## 记录战斗日志
## @param message: 日志消息
func _log_battle_action(message: String) -> void:
	battle_log.append(message)
	print("CombatManager: %s" % message)
