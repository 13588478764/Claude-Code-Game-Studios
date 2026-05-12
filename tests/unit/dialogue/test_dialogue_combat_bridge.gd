## test_dialogue_combat_bridge.gd
## 测试对话-战斗联动桥接器功能
## 验证对话选择能够正确触发战斗，战斗结束后能够正确返回对话流程

extends GutTest

var dialogue_combat_bridge = null
var dialogue_manager = null
var combat_manager = null
var relationship_manager = null

## 前置设置
func before_each() -> void:
	# 获取Autoload系统引用
	dialogue_combat_bridge = get_node_or_null("/root/DialogueCombatBridge")
	dialogue_manager = get_node_or_null("/root/DialogueManager")
	combat_manager = get_node_or_null("/root/CombatManager")
	relationship_manager = get_node_or_null("/root/RelationshipManager")

## 测试1: DialogueCombatBridge autoload已正确加载
func test_bridge_autoload_exists() -> void:
	assert_ne(dialogue_combat_bridge, null, "DialogueCombatBridge 应该作为 autoload 存在")
	assert_true(dialogue_combat_bridge._is_initialized, "DialogueCombatBridge 应该已初始化")

## 测试2: Bridge信号连接正确
func test_bridge_signals_connected() -> void:
	assert_true(dialogue_combat_bridge.has_signal("combat_triggered_by_dialogue"),
		"应该有 combat_triggered_by_dialogue 信号")
	assert_true(dialogue_combat_bridge.has_signal("combat_ended_return_to_dialogue"),
		"应该有 combat_ended_return_to_dialogue 信号")
	assert_true(dialogue_combat_bridge.has_signal("combat_trigger_failed"),
		"应该有 combat_trigger_failed 信号")

## 测试3: DialogueManager 有 combat_trigger_requested 信号
func test_dialogue_manager_has_combat_signal() -> void:
	assert_ne(dialogue_manager, null, "DialogueManager 应该存在")
	assert_true(dialogue_manager.has_signal("combat_trigger_requested"),
		"DialogueManager 应该有 combat_trigger_requested 信号")

## 测试4: 触发战斗效果类能够正确创建
func test_trigger_combat_effect_creation() -> void:
	var effect = DialogueData.TriggerCombatEffect.new(
		"final_battle_seal",
		{"battle_type": "seal", "enemies": []},
		"BATTLE_SEAL_PATH"
	)
	
	assert_eq(effect.target, "final_battle_seal", "encounter_id 应该正确设置")
	assert_eq(effect.encounter_config.battle_type, "seal", "battle_type 应该正确设置")
	assert_eq(effect.callback_node, "BATTLE_SEAL_PATH", "callback_node 应该正确设置")

## 测试5: Bridge 构建玩家单位数据
func test_bridge_create_player_unit() -> void:
	var player_unit = dialogue_combat_bridge._create_player_unit()
	
	# 注意：用 assert_not_null 而不是 assert_ne(x, null)。
	# GUT 的 assert_ne 内部会调用 diff_tool 比较两值差异，
	# 当其中一个是 null 时会触发"Only Arrays and Dictionaries are supported"内部错误。
	assert_not_null(player_unit, "玩家单位不应为空")
	assert_true(player_unit.has("id"), "玩家单位应该有 id")
	assert_eq(player_unit.id, "player", "玩家 id 应为 'player'")
	assert_true(player_unit.has("hp"), "玩家单位应该有 hp")
	assert_true(player_unit.has("max_hp"), "玩家单位应该有 max_hp")
	assert_true(player_unit.has("is_player"), "玩家单位应该有 is_player")
	assert_eq(player_unit.is_player, true, "is_player 应为 true")

## 测试6: Bridge 构建敌人单位数据
func test_bridge_create_enemy_unit() -> void:
	var enemy_config = {
		"id": "test_enemy",
		"speed": 12,
		"hp": 100,
		"max_hp": 100,
		"internal_energy": 50,
		"max_internal_energy": 60,
		"stance": 80,
		"attributes": {"force": 15, "constitution": 10, "wisdom": 8}
	}
	
	var enemy_unit = dialogue_combat_bridge._create_enemy_unit(enemy_config)
	
	# 同上：用 assert_not_null 替代 assert_ne(x, null) 避免 GUT diff_tool 内部错误
	assert_not_null(enemy_unit, "敌人单位不应为空")
	assert_eq(enemy_unit.id, "test_enemy", "敌人 id 应该正确")
	assert_eq(enemy_unit.hp, 100, "敌人 hp 应该正确")
	assert_eq(enemy_unit.is_player, false, "is_player 应为 false")

## 测试7: Bridge 构建战斗数据 - 包含敌人
func test_bridge_build_battle_data_with_enemies() -> void:
	var config = {
		"enemies": [
			{"id": "enemy_1", "hp": 80, "max_hp": 80, "speed": 10},
			{"id": "enemy_2", "hp": 60, "max_hp": 60, "speed": 8}
		]
	}
	
	var battle_data = dialogue_combat_bridge._build_battle_data("test_encounter", config)
	
	assert_true(battle_data.has("units"), "战斗数据应该有 units")
	assert_gte(battle_data.units.size(), 3, "战斗单位数应该 >= 3 (1玩家 + 2敌人)")

## 测试8: Bridge 构建战斗数据 - 无敌人时使用默认敌人
func test_bridge_build_battle_data_default_enemy() -> void:
	var battle_data = dialogue_combat_bridge._build_battle_data("test_encounter", {})
	
	assert_gte(battle_data.units.size(), 2, "战斗单位数应该 >= 2 (1玩家 + 1默认敌人)")
	
	var has_player = false
	var has_enemy = false
	for unit in battle_data.units:
		if unit.get("is_player", false):
			has_player = true
		else:
			has_enemy = true
	
	assert_true(has_player, "应该有玩家单位")
	assert_true(has_enemy, "应该有敌人单位")

## 测试9: 桥接器状态查询
func test_bridge_status() -> void:
	var status = dialogue_combat_bridge.get_bridge_status()
	
	assert_true(status.initialized, "桥接器应该已初始化")
	assert_true(status.combat_manager_active, "CombatManager 应该活跃")
	assert_true(status.dialogue_manager_active, "DialogueManager 应该活跃")

## 测试10: 战斗上下文管理
func test_combat_context_management() -> void:
	# 初始状态上下文应为空
	var initial_context = dialogue_combat_bridge.get_active_combat_context()
	assert_eq(initial_context.size(), 0, "初始战斗上下文应该为空")

## 测试11: 触发战斗效果执行时发送信号
func test_trigger_combat_effect_emits_signal() -> void:
	var effect = DialogueData.TriggerCombatEffect.new(
		"test_encounter",
		{},
		"callback_node"
	)
	
	# 监控信号发射 —— 使用 Dictionary 包装可变状态
	# 关键：GDScript lambda 按值捕获，给 lambda 内部的 `var` 重新赋值不会影响外部变量。
	# 必须 mutate 引用类型（Dictionary/Array）的字段才能让外部读到更新。
	var observation := {
		"signal_received": false,
		"encounter_id": null,
		"config": null,
		"callback": null,
	}
	
	dialogue_manager.combat_trigger_requested.connect(
		func(enc_id, cfg, cb_node):
			observation["signal_received"] = true
			observation["encounter_id"] = enc_id
			observation["config"] = cfg
			observation["callback"] = cb_node
	)
	
	effect.execute()
	
	assert_true(observation["signal_received"], "combat_trigger_requested 信号应该被发射")
	assert_eq(observation["encounter_id"], "test_encounter", "encounter_id 应该匹配")
	assert_eq(observation["callback"], "callback_node", "callback_node 应该匹配")

## 测试12: JSON解析战斗触发效果
func test_json_trigger_combat_parsing() -> void:
	# 验证 dialogue_manager 能正确解析 trigger_combat 效果类型
	# 这里检查 dialogue_manager.gd 中的解析代码是否存在
	var has_trigger_combat_parsing = false
	
	# 检查 _parse_effect 方法中是否有 trigger_combat 分支
	# 通过尝试创建一个包含 trigger_combat 效果的对话节点来验证
	var effect = dialogue_manager._parse_effect({
		"type": "trigger_combat",
		"target": "test_battle",
		"config": {"battle_type": "test"},
		"callback_node": "test_callback"
	})
	
	assert_ne(effect, null, "效果解析不应返回 null")
	assert_true(effect is DialogueData.TriggerCombatEffect,
		"解析的效果应该是 TriggerCombatEffect 类型")

## 测试13: 战斗结束返回对话流程
func test_battle_end_return_to_dialogue() -> void:
	# 这是一个集成测试场景
	# 验证战斗结束后 bridge 能够正确设置回调数据
	
	# 模拟设置战斗上下文
	dialogue_combat_bridge._active_combat_context = {
		"encounter_id": "test_encounter",
		"config": {},
		"callback_node": "test_callback",
		"dialogue_id": "test_dialogue"
	}
	
	var context = dialogue_combat_bridge.get_active_combat_context()
	assert_eq(context.callback_node, "test_callback", "回调节点应该正确保存")
	assert_eq(context.encounter_id, "test_encounter", "encounter_id 应该正确保存")
