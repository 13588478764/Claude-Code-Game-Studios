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

## 本场战斗中使用过的武学 ID（战后批量提升熟练度）
var _used_martial_arts: Array[String] = []

## 武学连招系统
var _combo_system: MartialArtsComboSystem = null

## 弱点系统 (依赖注入, 默认 null — 等外部 set_weakness_system() 注入后才桥接到 HUD)
## 设计动机: 当前 src/ 内无 WeaknessSystem 实例化点 (autoload/.tscn/.new() 均无),
## A2 PR (sprint-007 s7-18) 只负责把桥接通路打通, 不强行实例化以避免影响其他系统行为。
## 实际接入: 战斗启动方调 combat_manager.set_weakness_system(ws) 即生效。
var _weakness_system: WeaknessSystem = null

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
	
	# 初始化连招系统
	_combo_system = MartialArtsComboSystem.new()
	add_child(_combo_system)

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

## 连接局部信号到全局 GameEvents（P0-3 修复 + sprint-007 s7-18 HUD 接通）
## 幂等: 重复调用不会重复连接 (测试桥重连场景需要)
func _connect_global_signals() -> void:
	if _game_events == null:
		return

	# 局部信号转发到 GameEvents
	if not battle_started.is_connected(_on_battle_started_global):
		battle_started.connect(_on_battle_started_global)
	if not battle_ended.is_connected(_on_battle_ended_global):
		battle_ended.connect(_on_battle_ended_global)
	if not turn_started.is_connected(_on_turn_started_global):
		turn_started.connect(_on_turn_started_global)

	# HUD 半哑火接通: unit_hp_changed → player_hp_changed / enemy_hp_changed
	if not unit_hp_changed.is_connected(_on_unit_hp_changed_global):
		unit_hp_changed.connect(_on_unit_hp_changed_global)
	# HUD 半哑火接通: unit_resource_changed → player_qi_changed / player_poise_changed
	if not unit_resource_changed.is_connected(_on_unit_resource_changed_global):
		unit_resource_changed.connect(_on_unit_resource_changed_global)

func _on_battle_started_global() -> void:
	_game_events.combat_started.emit()

func _on_battle_ended_global(result: Dictionary) -> void:
	_game_events.combat_ended.emit(result.get("victory", false), result)

## 回合开始全局信号转发
func _on_turn_started_global(_unit: BattleUnit) -> void:
	_turn_counter += 1
	_game_events.combat_turn_changed.emit(_turn_counter)
	# 行动队列变更广播 (HUD ActionQueueDisplay 订阅)
	_emit_action_queue_updated()

## HP 变更全局广播 — 玩家/敌人按 battle_units 位置区分
func _on_unit_hp_changed_global(unit: BattleUnit, _old_hp: int, new_hp: int) -> void:
	if _is_player_unit(unit):
		_game_events.player_hp_changed.emit(new_hp, unit.max_hp)
	else:
		_game_events.enemy_hp_changed.emit(_unit_id(unit), new_hp, unit.max_hp)

## 资源变更全局广播 — 仅玩家的 Qi / Poise 上报到 HUD
## 敌人 Qi/Poise 暂无 UI 订阅, 不广播以减少开销
func _on_unit_resource_changed_global(unit: BattleUnit, resource_type: String, _old: int, new_value: int) -> void:
	if not _is_player_unit(unit):
		return
	match resource_type:
		"internal_energy":
			_game_events.player_qi_changed.emit(new_value, unit.max_internal_energy)
		"stance":
			# 架势 = Poise (GDD 术语对齐)
			_game_events.player_poise_changed.emit(new_value, max_stance)


## 注入 WeaknessSystem 并建立桥接 (sprint-007 s7-18 A2)
## 接通 enemy_weakness_revealed + enemy_status_changed 两个 P0 半哑火 HUD 信号。
## 幂等: 重复注入同一实例不会重复连接; 注入不同实例会先解绑旧实例。
## @param ws: WeaknessSystem 实例; 传 null 等同解绑当前实例。
func set_weakness_system(ws: WeaknessSystem) -> void:
	# 解绑旧实例 (避免重复广播 / 悬挂引用)
	if _weakness_system != null and _weakness_system != ws:
		if _weakness_system.weakness_hit.is_connected(_on_weakness_hit_global):
			_weakness_system.weakness_hit.disconnect(_on_weakness_hit_global)
		if _weakness_system.down_triggered.is_connected(_on_down_triggered_global):
			_weakness_system.down_triggered.disconnect(_on_down_triggered_global)
		if _weakness_system.down_cleared.is_connected(_on_down_cleared_global):
			_weakness_system.down_cleared.disconnect(_on_down_cleared_global)

	_weakness_system = ws
	if _weakness_system == null or _game_events == null:
		return

	# 幂等连接 (与 _connect_global_signals 同模式)
	if not _weakness_system.weakness_hit.is_connected(_on_weakness_hit_global):
		_weakness_system.weakness_hit.connect(_on_weakness_hit_global)
	if not _weakness_system.down_triggered.is_connected(_on_down_triggered_global):
		_weakness_system.down_triggered.connect(_on_down_triggered_global)
	if not _weakness_system.down_cleared.is_connected(_on_down_cleared_global):
		_weakness_system.down_cleared.connect(_on_down_cleared_global)


## 弱点命中全局广播 — 仅在 result.is_weakness_hit == true 时上报
## 语义: enemy_weakness_revealed 表示"敌人某项弱点首次被验证", 普通攻击不上报。
## HUD enemy_info_panel._on_enemy_weakness_revealed 会去重写入 discovered_weaknesses。
func _on_weakness_hit_global(_attacker, target, result) -> void:
	if not result.is_weakness_hit:
		return
	var element_str: String = WeaknessSystem.element_name(result.element)
	if element_str.is_empty():
		return
	_game_events.enemy_weakness_revealed.emit(_node_to_enemy_id(target), element_str)


## 击倒状态全局广播 — 进入 down 状态
## 字符串约定与 enemy_info_panel._update_status_display() 对齐: "down" → down_indicator.visible = true
func _on_down_triggered_global(participant) -> void:
	_game_events.enemy_status_changed.emit(_node_to_enemy_id(participant), "down")


## 击倒状态全局广播 — 离开 down 状态
## 用空字符串 "" 表示"无特殊状态" (UI down_indicator/break_indicator 均关闭)。
## TODO(beta): break 状态接入后, 改为 "break" / "" 二态切换。
func _on_down_cleared_global(participant) -> void:
	_game_events.enemy_status_changed.emit(_node_to_enemy_id(participant), "")

## 行动队列变更广播 — 把 BattleUnit 数组转成 HUD 期待的字典格式
func _emit_action_queue_updated() -> void:
	if _game_events == null:
		return
	var queue_data: Array = []
	# 当前行动单位 + 剩余队列共同构成"完整行动顺序"
	if current_turn_unit != null:
		queue_data.append(_unit_to_queue_entry(current_turn_unit))
	for unit in action_queue:
		queue_data.append(_unit_to_queue_entry(unit))
	_game_events.combat_action_queue_updated.emit(queue_data)

## 把 BattleUnit 转成 HUD ActionQueueDisplay 期待的字典
## 约定字段: {unit_id, unit_name, is_player, icon_path}
func _unit_to_queue_entry(unit: BattleUnit) -> Dictionary:
	return {
		"unit_id": _unit_id(unit),
		"unit_name": _unit_name(unit),
		"is_player": _is_player_unit(unit),
		"icon_path": "",
	}

## 判定是否玩家单位 — 沿用 is_battle_over() 的位置约定 (前半为玩家)
## 临时方案: BattleUnit 未来加 is_player 字段后此函数可简化为 unit.is_player
func _is_player_unit(unit: BattleUnit) -> bool:
	var idx: int = battle_units.find(unit)
	if idx < 0:
		return false
	return idx < ceil(float(battle_units.size()) / 2.0)

## 从 unit_node 提取稳定 ID — 字典走 "id" / "name", 节点走 name
func _unit_id(unit: BattleUnit) -> String:
	if unit.unit_node is Dictionary:
		return str(unit.unit_node.get("id", unit.unit_node.get("name", "")))
	if unit.unit_node is Node:
		return unit.unit_node.name
	return str(unit.unit_node)

## 把 WeaknessSystem 的 participant (Node/Object) 反查回 enemy_id 字符串
## 策略: 1) 先在 battle_units 找 unit_node 匹配项 (生产路径)
##       2) 退回 Node.name (单元测试常用)
##       3) 最终 fallback str() 防崩
func _node_to_enemy_id(participant) -> String:
	for unit in battle_units:
		if unit.unit_node == participant:
			return _unit_id(unit)
	if participant is Node:
		return participant.name
	return str(participant)

## 构造敌人选中快照 — HUD EnemyInfoPanel 字段对齐 (id/name/level/hp/weaknesses/status/is_boss)
## 未来 BattleUnit 加 metadata 字段后可直接 unit.unit_node.duplicate()
func _build_enemy_snapshot(unit: BattleUnit) -> Dictionary:
	var node_data: Dictionary = {}
	if unit.unit_node is Dictionary:
		node_data = unit.unit_node
	return {
		"id": _unit_id(unit),
		"name": _unit_name(unit),
		"level": node_data.get("level", 1),
		"current_hp": unit.current_hp,
		"max_hp": unit.max_hp,
		"weaknesses": node_data.get("weaknesses", []),
		"discovered_weaknesses": node_data.get("discovered_weaknesses", []),
		"status": node_data.get("status", ""),
		"is_boss": node_data.get("is_boss", false),
	}

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
	_used_martial_arts.clear()
	if _combo_system:
		_combo_system.reset_combo_state()

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
	# 队列重排后通知 HUD ActionQueueDisplay 刷新
	_emit_action_queue_updated()

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
func end_battle(fled: bool = false) -> void:
	battle_state = BattleState.CLEANUP
	battle_state_changed.emit(battle_state)

	var result: Dictionary = _calculate_battle_result()
	if fled:
		result["victory"] = false
		result["fled"] = true
		_log_battle_action("逃跑成功，撤离战斗")

	battle_ended.emit(result)
	
	# 重置状态
	battle_state = BattleState.IDLE
	battle_state_changed.emit(battle_state)
	_reset_battle_state()

## 计算战斗结果
## @return 战斗结果字典
func _calculate_battle_result() -> Dictionary:
	var alive_units: Array = []
	var player_alive := false
	var half := ceili(battle_units.size() / 2.0)
	for i in range(battle_units.size()):
		if battle_units[i].current_hp > 0:
			alive_units.append(battle_units[i])
			if i < half:
				player_alive = true

	return {
		"victory": player_alive,
		"winner": alive_units,
		"battle_log": battle_log.duplicate(),
		"used_martial_arts": _used_martial_arts.duplicate(),
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

	# 玩家锁定敌人时广播 enemy_selected — HUD EnemyInfoPanel 据此切换显示
	# 仅当 attacker 是玩家且 target 是敌人时触发, 避免敌人 AI 攻击玩家时误广播
	if _game_events != null and _is_player_unit(attacker) and not _is_player_unit(target):
		_game_events.enemy_selected.emit(_build_enemy_snapshot(target))
	
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
	_log_battle_action("%s 对 %s 造成了 %d 点伤害 (剩余HP: %d/%d)" % [_unit_name(attacker), _unit_name(target), damage, target.current_hp, target.max_hp])
	
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
	var reduction_pct: int = int(float(defender.stance) / float(max_stance) * 30)
	_log_battle_action("%s 进入防御状态，架势值 %d/%d (减伤 %d%%)" % [_unit_name(defender), defender.stance, max_stance, reduction_pct])
	
	return {
		"success": true,
		"type": "defend",
		"stance_increased": defend_stance_increase,
		"stance_reduction_pct": reduction_pct
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
	
	# 连招系统处理
	var combo_result: Dictionary = {}
	var damage_multiplier: float = 1.0
	if _combo_system:
		var tags: Array = skill_data.get("tags", [])
		var target_idx: int = skill_data.get("target_index", -1)
		var target_status: Array = []
		if target_idx >= 0 and target_idx < battle_units.size():
			target_status = battle_units[target_idx].attributes.get("status_effects", [])
		combo_result = _combo_system.process_skill_usage(skill_data, target_status)
		damage_multiplier = combo_result.get("damage_multiplier", 1.0)

		# 内力回流
		var refund: int = int(combo_result.get("internal_energy_refund", 0.0))
		if refund > 0:
			var pre_energy: int = user.current_internal_energy
			user.current_internal_energy = min(user.max_internal_energy, user.current_internal_energy + refund)
			if user.current_internal_energy != pre_energy:
				unit_resource_changed.emit(user, "internal_energy", pre_energy, user.current_internal_energy)

	# 根据技能类型执行不同效果（含连招伤害加成）
	var effect_result: Dictionary = apply_skill_effect(user, skill_data, damage_multiplier)

	# 更新连携槽（连招系统增量 + 基础增量取较大值）
	var link_change: int = combo_result.get("link_gauge_change", 0)
	var total_link_increase: int = max(skill_link_gauge_increase, link_change)
	var old_link: int = user.link_gauge
	user.link_gauge = min(max_link_gauge, user.link_gauge + total_link_increase)
	unit_resource_changed.emit(user, "link_gauge", old_link, user.link_gauge)

	# 记录使用的武学 ID（用于战后熟练度提升）
	var ma_id: String = skill_data.get("martial_art_id", "")
	if not ma_id.is_empty() and not _used_martial_arts.has(ma_id):
		_used_martial_arts.append(ma_id)

	# 记录战斗日志
	_log_battle_action("%s 使用了技能 %s" % [_unit_name(user), skill_data.get("name", "未知技能")])
	if combo_result.get("synergy_triggered", false):
		_log_battle_action("协同效果 [%s] 触发！伤害 x%.1f" % [combo_result.get("synergy_name", ""), damage_multiplier])

	var result: Dictionary = {
		"success": true,
		"type": "skill",
		"skill_name": skill_data.get("name", "未知技能"),
		"damage_dealt": effect_result.get("damage", 0),
		"target_hp_left": effect_result.get("target_hp_left", 0),
		"effect": effect_result,
	}
	if combo_result.get("synergy_triggered", false):
		result["synergy_name"] = combo_result.get("synergy_name", "")
		result["damage_multiplier"] = damage_multiplier
	return result

# ============================================================================
# 伤害计算
# ============================================================================

## 计算伤害（委托给 DamageCalculator）
## @param attacker: 攻击方战斗单位
## @param target: 目标战斗单位
## @param attack_data: 攻击数据字典
## @return 最终伤害值
func calculate_damage(attacker: BattleUnit, target: BattleUnit, attack_data: Dictionary) -> int:
	# 使用本地简化计算（避免 DamageCalculator 的 Node-meta 适配开销）
	var base_dmg: int = _calculate_damage_fallback(attacker, target, attack_data)
	
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
	var attack_attr: int = attacker.attributes.get("force", 10)
	var defend_attr: int = target.attributes.get("constitution", 0)
	var raw_dmg: int = max(1, attack_attr - defend_attr / 3) + randi_range(0, damage_random_range)

	# 架势减伤：架势值 0~100 对应 0%~30% 减伤
	var stance_reduction: float = float(target.stance) / float(max_stance) * 0.3
	var base_dmg: int = max(1, int(raw_dmg * (1.0 - stance_reduction)))

	return base_dmg

## 设置伤害计算器（依赖注入）
## @param calc: 伤害计算器实例
func set_damage_calculator(calc: DamageCalculator) -> void:
	_damage_calculator = calc

## 应用技能效果（支持 MartialArtsSystem 熟练度加成）
## @param user: 使用者战斗单位
## @param skill_data: 技能数据字典
## @return 技能效果字典
func apply_skill_effect(user: BattleUnit, skill_data: Dictionary, damage_multiplier: float = 1.0) -> Dictionary:
	var target_idx: int = skill_data.get("target_index", -1)
	if target_idx < 0 or target_idx >= battle_units.size():
		return {"type": "skill_effect", "damage": 0}

	var target: BattleUnit = battle_units[target_idx]
	var power: int = skill_data.get("power", 1)
	var attack_attr: int = user.attributes.get("force", 10)
	var defend_attr: int = target.attributes.get("constitution", 0)

	# 基础伤害 = 武学威力 + 力道属性 - 目标防御/3
	var damage: float = float(max(1, power + attack_attr - defend_attr / 3))

	# 从 MartialArtsSystem 读取熟练度加成（每级 +2%）
	var ma_id: String = skill_data.get("martial_art_id", "")
	var martial_sys: Node = get_node_or_null("/root/MartialArtsSystem")
	if martial_sys and not ma_id.is_empty():
		var ma_data = martial_sys.get_player_martial_art(ma_id)
		if ma_data:
			var prof_bonus: float = 1.0 + ma_data.proficiency_level * 0.02
			damage *= prof_bonus

	# 连招协同伤害倍率
	damage *= damage_multiplier

	var final_damage: int = max(1, int(damage))

	var old_hp: int = target.current_hp
	target.current_hp = max(0, target.current_hp - final_damage)
	unit_hp_changed.emit(target, old_hp, target.current_hp)

	_log_battle_action("%s 的技能对 %s 造成了 %d 点伤害 (剩余HP: %d/%d)" % [_unit_name(user), _unit_name(target), final_damage, target.current_hp, target.max_hp])

	return {"type": "skill_effect", "damage": final_damage, "target_hp_left": target.current_hp}

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

## 获取单位显示名称
func _unit_name(unit: BattleUnit) -> String:
	if unit.unit_node is Dictionary:
		return unit.unit_node.get("name", "未知")
	return str(unit.unit_node)


## 记录战斗日志
## @param message: 日志消息
func _log_battle_action(message: String) -> void:
	battle_log.append(message)
	print("CombatManager: %s" % message)
