## DialogueCombatBridge
## 对话-战斗联动桥接器
##
## 负责将对话系统中的战斗选择连接到实际战斗遭遇：
## - 监听对话系统中的战斗触发效果
## - 调用CombatManager启动对应的战斗
## - 战斗结束后将结果传递回对话系统继续流程
##
## 架构：Autoload单例，通过信号实现对话与战斗的松耦合


extends Node

# ============================================================================
# 信号定义
# ============================================================================

## 对话触发了战斗
signal combat_triggered_by_dialogue(encounter_id: String, config: Dictionary, callback_node: String)

## 战斗结束返回对话
signal combat_ended_return_to_dialogue(result: Dictionary, callback_node: String)

## 战斗触发失败
signal combat_trigger_failed(encounter_id: String, error: String)

# ============================================================================
# 成员变量
# ============================================================================

var _combat_manager = null
var _dialogue_manager = null
var _character_system = null
var _is_initialized = false

# 当前战斗上下文
var _active_combat_context: Dictionary = {}

# ============================================================================
# 生命周期方法
# ============================================================================

func _ready() -> void:
	call_deferred("_initialize_bridge")

func _initialize_bridge() -> void:
	if _is_initialized:
		return

	# 获取Autoload单例引用
	_combat_manager = get_node_or_null("/root/CombatSystem")
	_dialogue_manager = get_node_or_null("/root/DialogueManager")
	_character_system = get_node_or_null("/root/CharacterSystem")

	# 验证必需系统
	if _combat_manager == null:
		push_warning("[DialogueCombatBridge] CombatManager 未找到，对话-战斗联动将不可用")
		return

	if _dialogue_manager == null:
		push_warning("[DialogueCombatBridge] DialogueManager 未找到，对话-战斗联动将不可用")
		return

	# 连接战斗信号
	_combat_manager.battle_ended.connect(_on_battle_ended)

	# 连接对话信号
	if _dialogue_manager.has_signal("combat_trigger_requested"):
		_dialogue_manager.combat_trigger_requested.connect(_on_combat_trigger_requested)

	_is_initialized = true
	print("[DialogueCombatBridge] 对话-战斗联动桥接器已初始化")

# ============================================================================
# 信号处理器 - 来自对话系统
# ============================================================================

## 处理对话系统发来的战斗触发请求
## @param encounter_id: 战斗遭遇ID
## @param config: 战斗配置字典
## @param callback_node: 回调节点ID
func _on_combat_trigger_requested(encounter_id: String, config: Dictionary, callback_node: String) -> void:
	print("[DialogueCombatBridge] 收到战斗触发请求: %s" % encounter_id)
	trigger_dialogue_combat(encounter_id, config, callback_node)

# ============================================================================
# 核心API
# ============================================================================

## 从对话系统触发战斗
## @param encounter_id: 战斗遭遇ID
## @param config: 战斗配置字典（包含敌人、难度等）
## @param callback_node: 战斗结束后返回的对话节点ID
func trigger_dialogue_combat(encounter_id: String, config: Dictionary = {}, callback_node: String = "") -> void:
	if not _is_initialized:
		combat_trigger_failed.emit(encounter_id, "Bridge not initialized")
		return

	# 保存战斗上下文
	_active_combat_context = {
		"encounter_id": encounter_id,
		"config": config,
		"callback_node": callback_node,
		"dialogue_id": _dialogue_manager.get_current_dialogue_id()
	}

	print("[DialogueCombatBridge] 触发对话战斗: %s (回调节点: %s)" % [encounter_id, callback_node])

	# 构建战斗数据
	var battle_data = _build_battle_data(encounter_id, config)

	# 结束当前对话（战斗接管）
	_dialogue_manager.end_dialogue()

	# 启动战斗
	_combat_manager.start_battle(battle_data.units)

	combat_triggered_by_dialogue.emit(encounter_id, config, callback_node)

## 获取战斗上下文
func get_active_combat_context() -> Dictionary:
	return _active_combat_context.duplicate()

# ============================================================================
# 战斗数据处理
# ============================================================================

## 构建战斗数据
## @param encounter_id: 遭遇ID
## @param config: 配置字典
## @return 战斗数据字典
func _build_battle_data(encounter_id: String, config: Dictionary) -> Dictionary:
	var units: Array = []

	# 添加玩家单位
	var player_unit = _create_player_unit()
	if player_unit != null:
		units.append(player_unit)

	# 添加敌方单位
	var enemies = config.get("enemies", [])
	for enemy_config in enemies:
		var enemy_unit = _create_enemy_unit(enemy_config)
		if enemy_unit != null:
			units.append(enemy_unit)

	# 如果没有指定敌人，使用默认敌人
	if enemies.is_empty():
		units.append(_create_default_enemy())

	return {"units": units}

## 创建玩家单位数据
## @return 玩家单位数据字典
func _create_player_unit() -> Dictionary:
	if _character_system == null:
		# 使用默认玩家数据
		return {
			"id": "player",
			"speed": 10,
			"hp": 100,
			"max_hp": 100,
			"internal_energy": 50,
			"max_internal_energy": 100,
			"stance": 100,
			"combo_value": 0,
			"link_gauge": 0,
			"attributes": {"force": 10, "constitution": 10, "wisdom": 10},
			"is_player": true
		}

	# 从CharacterSystem获取真实数据
	var attributes = {}
	if _character_system.has_node("attributes") or _character_system.attributes != null:
		attributes = _character_system.attributes.get_total()

	return {
		"id": "player",
		"speed": 10 + (attributes.get("agility", 0) / 2),
		"hp": 100 + (attributes.get("constitution", 0) * 5),
		"max_hp": 100 + (attributes.get("constitution", 0) * 5),
		"internal_energy": 50 + (attributes.get("wisdom", 0) * 3),
		"max_internal_energy": 100 + (attributes.get("wisdom", 0) * 3),
		"stance": 100,
		"combo_value": 0,
		"link_gauge": 0,
		"attributes": attributes,
		"is_player": true
	}

## 创建敌方单位数据
## @param config: 敌人配置
## @return 敌人单位数据字典
func _create_enemy_unit(config: Dictionary) -> Dictionary:
	return {
		"id": config.get("id", "enemy"),
		"speed": config.get("speed", 8),
		"hp": config.get("hp", 80),
		"max_hp": config.get("max_hp", 80),
		"internal_energy": config.get("internal_energy", 30),
		"max_internal_energy": config.get("max_internal_energy", 50),
		"stance": config.get("stance", 100),
		"combo_value": 0,
		"link_gauge": 0,
		"attributes": config.get("attributes", {"force": 8, "constitution": 8, "wisdom": 8}),
		"is_player": false
	}

## 创建默认敌人
## @return 默认敌人单位数据字典
func _create_default_enemy() -> Dictionary:
	return {
		"id": "default_enemy",
		"speed": 8,
		"hp": 80,
		"max_hp": 80,
		"internal_energy": 30,
		"max_internal_energy": 50,
		"stance": 100,
		"combo_value": 0,
		"link_gauge": 0,
		"attributes": {"force": 8, "constitution": 8, "wisdom": 8},
		"is_player": false
	}

# ============================================================================
# 信号处理器
# ============================================================================

## 战斗结束处理
## @param result: 战斗结果字典
func _on_battle_ended(result: Dictionary) -> void:
	print("[DialogueCombatBridge] 战斗结束，处理结果...")

	var context = _active_combat_context.duplicate()
	var callback_node = context.get("callback_node", "")
	var encounter_id = context.get("encounter_id", "")

	# 确定战斗结果
	var victory = false
	if result.has("winner"):
		var winners = result.get("winner", [])
		for winner in winners:
			var is_player = false
			if winner.unit_node is Dictionary:
				is_player = winner.unit_node.get("is_player", false)
			if is_player or (winner.unit_node != null and str(winner.unit_node).contains("player")):
				victory = true
				break

	# 构建返回数据
	var return_data = {
		"victory": victory,
		"encounter_id": encounter_id,
		"result": result,
		"callback_node": callback_node
	}

	# 清空战斗上下文
	_active_combat_context.clear()

	# 通知战斗结束，返回对话
	combat_ended_return_to_dialogue.emit(return_data, callback_node)

	# 如果指定了回调节点，返回对话
	if not callback_node.is_empty() and _dialogue_manager != null:
		# 重新打开对话并跳转到回调节点
		_dialogue_manager.start_dialogue(context.get("dialogue_id", ""))

	# 如果战斗失败，触发失败处理
	if not victory:
		_on_combat_defeat(return_data)
	else:
		_on_combat_victory(return_data)

## 战斗胜利处理
## @param return_data: 返回数据
func _on_combat_victory(return_data: Dictionary) -> void:
	print("[DialogueCombatBridge] 战斗胜利，发放奖励...")
	# 这里可以连接奇遇奖励系统
	# 如果有奇遇系统，触发战斗胜利后的奇遇检查
	var game_events = get_node_or_null("/root/GameEvents")
	if game_events != null:
		game_events.combat_ended.emit(true, return_data.get("result", {}))

## 战斗失败的处理
## @param return_data: 返回数据
func _on_combat_defeat(return_data: Dictionary) -> void:
	print("[DialogueCombatBridge] 战斗失败...")
	# 这里可以处理战斗失败逻辑（如读档、惩罚等）
	var game_events = get_node_or_null("/root/GameEvents")
	if game_events != null:
		game_events.combat_ended.emit(false, return_data.get("result", {}))

# ============================================================================
# 公共API
# ============================================================================

## 获取桥接器状态
func get_bridge_status() -> Dictionary:
	return {
		"initialized": _is_initialized,
		"combat_manager_active": _combat_manager != null,
		"dialogue_manager_active": _dialogue_manager != null,
		"character_system_active": _character_system != null,
		"active_context": _active_combat_context
	}
