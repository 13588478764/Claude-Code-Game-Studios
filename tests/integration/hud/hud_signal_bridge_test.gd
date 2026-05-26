extends GutTest
## HUD 信号桥接集成测试 (sprint-007 s7-18 P0)
##
## 验证 polish-fixlist #1 的 8 个 P0 半哑火信号已成功从源头桥接到 GameEvents:
## - player_hp_changed / player_qi_changed / player_poise_changed (combat_manager 资源变更桥接)
## - player_level_up / player_exp_changed (character_system 升级桥接)
## - enemy_hp_changed (combat_manager unit_hp_changed 桥接 - 敌人路径)
## - enemy_selected (combat_manager execute_attack 玩家锁定时发射)
## - combat_action_queue_updated (combat_manager generate_action_queue 后发射)
##
## 后续单独 PR 处理 (A2): enemy_weakness_revealed / enemy_status_changed
## (需扩 WeaknessSystem 信号签名 + 节点→id 约定, 见 signal-audit.md)

const CombatManagerScript := preload("res://src/scripts/combat/combat_manager.gd")
const FakeGameEventsScript := preload("res://tests/integration/hud/fake_game_events.gd")

var combat_manager: Node
var game_events: Node
var _signal_log: Array = []

# ============================================================================
# 测试生命周期
# ============================================================================

func before_each() -> void:
	_signal_log.clear()

	# 准备隔离的 GameEvents 替身, 挂到 /root 让 combat_manager 自动找到
	# (combat_manager._initialize_dependencies() 通过 has_node("/root/GameEvents") 注入)
	# 不能直接修改真实 autoload, 测试隔离原则。
	game_events = _make_fake_game_events()
	game_events.name = "GameEventsTest"
	add_child(game_events)

	combat_manager = CombatManagerScript.new()
	combat_manager.name = "CombatManagerTest"
	add_child(combat_manager)
	# combat_manager 自身的 _ready 会尝试连 /root/GameEvents,
	# 测试里直接手动注入桥接路径以避免污染真实 autoload
	combat_manager._game_events = game_events
	combat_manager._connect_global_signals()

	await get_tree().process_frame

func after_each() -> void:
	if is_instance_valid(combat_manager):
		combat_manager.queue_free()
	if is_instance_valid(game_events):
		game_events.queue_free()
	_signal_log.clear()

# ============================================================================
# 桥接测试: combat_manager.unit_hp_changed → GameEvents.player/enemy_hp_changed
# ============================================================================

func test_combat_unit_hp_changed_bridges_to_player_hp_changed_when_unit_is_player() -> void:
	# Arrange — 1v1 战斗, 玩家在前 (positional convention)
	var units := _make_units_player_vs_enemy()
	combat_manager.start_battle(units)
	game_events.player_hp_changed.connect(_log_player_hp)
	var player_unit = combat_manager.battle_units[0]

	# Act
	combat_manager.unit_hp_changed.emit(player_unit, 100, 75)

	# Assert
	assert_eq(_signal_log.size(), 1, "GameEvents.player_hp_changed 应被发射 1 次")
	assert_eq(_signal_log[0], [75, player_unit.max_hp], "current/max 应正确转发")

func test_combat_unit_hp_changed_bridges_to_enemy_hp_changed_when_unit_is_enemy() -> void:
	# Arrange
	var units := _make_units_player_vs_enemy()
	combat_manager.start_battle(units)
	game_events.enemy_hp_changed.connect(_log_enemy_hp)
	var enemy_unit = combat_manager.battle_units[1]

	# Act
	combat_manager.unit_hp_changed.emit(enemy_unit, 100, 30)

	# Assert
	assert_eq(_signal_log.size(), 1, "GameEvents.enemy_hp_changed 应被发射 1 次")
	assert_eq(_signal_log[0][0], "enemy_001", "enemy_id 应来自 unit_node.id")
	assert_eq(_signal_log[0][1], 30, "current_hp 应为 30")
	assert_eq(_signal_log[0][2], enemy_unit.max_hp, "max_hp 应正确转发")

# ============================================================================
# 桥接测试: unit_resource_changed → player_qi_changed / player_poise_changed
# ============================================================================

func test_combat_internal_energy_change_bridges_to_player_qi_changed() -> void:
	# Arrange
	var units := _make_units_player_vs_enemy()
	combat_manager.start_battle(units)
	game_events.player_qi_changed.connect(_log_player_qi)
	var player_unit = combat_manager.battle_units[0]

	# Act
	combat_manager.unit_resource_changed.emit(player_unit, "internal_energy", 50, 35)

	# Assert
	assert_eq(_signal_log.size(), 1, "player_qi_changed 应被发射 1 次")
	assert_eq(_signal_log[0], [35, player_unit.max_internal_energy], "current/max 应正确")

func test_combat_stance_change_bridges_to_player_poise_changed() -> void:
	# Arrange
	var units := _make_units_player_vs_enemy()
	combat_manager.start_battle(units)
	game_events.player_poise_changed.connect(_log_player_poise)
	var player_unit = combat_manager.battle_units[0]

	# Act
	combat_manager.unit_resource_changed.emit(player_unit, "stance", 100, 60)

	# Assert
	assert_eq(_signal_log.size(), 1, "player_poise_changed 应被发射 1 次")
	assert_eq(_signal_log[0], [60, combat_manager.max_stance], "current/max 应正确")

func test_combat_enemy_internal_energy_change_does_not_bridge_to_player_qi() -> void:
	# 敌人 Qi 变更不应污染玩家 HUD
	var units := _make_units_player_vs_enemy()
	combat_manager.start_battle(units)
	game_events.player_qi_changed.connect(_log_player_qi)
	var enemy_unit = combat_manager.battle_units[1]

	combat_manager.unit_resource_changed.emit(enemy_unit, "internal_energy", 50, 35)

	assert_eq(_signal_log.size(), 0, "敌人 Qi 变更不应触发 player_qi_changed")

# ============================================================================
# 桥接测试: generate_action_queue → combat_action_queue_updated
# ============================================================================

func test_generate_action_queue_emits_combat_action_queue_updated() -> void:
	# Arrange
	var units := _make_units_player_vs_enemy()
	game_events.combat_action_queue_updated.connect(_log_action_queue)
	combat_manager._initialize_battle_units(units)

	# Act
	combat_manager.generate_action_queue()

	# Assert
	assert_eq(_signal_log.size(), 1, "队列变更应广播 1 次")
	var queue: Array = _signal_log[0]
	assert_eq(queue.size(), 2, "队列应有 2 个单位")
	# 字段约定 (ActionQueueDisplay 期待格式)
	assert_true(queue[0].has("unit_id"), "队列项应有 unit_id")
	assert_true(queue[0].has("unit_name"), "队列项应有 unit_name")
	assert_true(queue[0].has("is_player"), "队列项应有 is_player")
	assert_true(queue[0].has("icon_path"), "队列项应有 icon_path")

# ============================================================================
# 桥接测试: execute_attack (玩家锁定敌人) → enemy_selected
# ============================================================================

func test_player_attacks_enemy_emits_enemy_selected_snapshot() -> void:
	# Arrange
	var units := _make_units_player_vs_enemy()
	combat_manager.start_battle(units)
	game_events.enemy_selected.connect(_log_enemy_selected)
	# 强制 current_turn_unit 为玩家 (start_battle 已 pop_front, 此处覆盖确保)
	combat_manager.current_turn_unit = combat_manager.battle_units[0]

	# Act
	combat_manager.execute_attack({"target_index": 1, "weapon_attack": 10})

	# Assert
	assert_gte(_signal_log.size(), 1, "enemy_selected 至少应发射 1 次")
	var snapshot: Dictionary = _signal_log[0]
	assert_eq(snapshot.get("id", ""), "enemy_001", "快照 id 来自 unit_node.id")
	assert_eq(snapshot.get("name", ""), "测试敌人", "快照 name 应为敌人名")
	assert_true(snapshot.has("current_hp"), "快照应有 current_hp")
	assert_true(snapshot.has("max_hp"), "快照应有 max_hp")
	assert_true(snapshot.has("weaknesses"), "快照应有 weaknesses")

func test_enemy_attacks_player_does_not_emit_enemy_selected() -> void:
	# 敌人 AI 攻击玩家时, 不应错误触发 enemy_selected (避免 HUD 显示自己被选中)
	var units := _make_units_player_vs_enemy()
	combat_manager.start_battle(units)
	game_events.enemy_selected.connect(_log_enemy_selected)
	combat_manager.current_turn_unit = combat_manager.battle_units[1]  # enemy turn

	combat_manager.execute_attack({"target_index": 0, "weapon_attack": 10})

	# 不应触发 (只有玩家锁定敌人才触发)
	# 注意: start_battle 自身可能因 turn_started 触发 action_queue, 但与 enemy_selected 无关
	assert_eq(_signal_log.size(), 0, "敌方回合攻击玩家不应触发 enemy_selected")

# ============================================================================
# 桥接测试: character_system.add_experience → player_exp_changed
# ============================================================================

func test_character_system_add_experience_emits_player_exp_changed() -> void:
	# 该测试依赖真实 GameEvents autoload (character_system 使用全局 GameEvents 引用),
	# 跳过条件: 真实 autoload 不可用
	if not is_instance_valid(GameEvents):
		pending("真实 GameEvents autoload 不可用, 跳过 character_system 桥接测试")
		return

	var character_system_script = load("res://src/scripts/character/character_system.gd")
	var cs = character_system_script.new()
	cs.name = "CharacterSystemTest"
	add_child(cs)
	await get_tree().process_frame

	var received: Array = []
	var cb = func(current: int, to_next: int) -> void:
		received.append([current, to_next])
	GameEvents.player_exp_changed.connect(cb)

	cs.add_experience(50)

	assert_gte(received.size(), 1, "player_exp_changed 应至少发射 1 次")
	assert_eq(received[0][0], 50, "current 应为累计经验 50")

	GameEvents.player_exp_changed.disconnect(cb)
	cs.queue_free()

func test_character_system_level_up_emits_player_level_up_with_old_level() -> void:
	if not is_instance_valid(GameEvents):
		pending("真实 GameEvents autoload 不可用, 跳过 character_system 桥接测试")
		return

	var character_system_script = load("res://src/scripts/character/character_system.gd")
	var cs = character_system_script.new()
	cs.name = "CharacterSystemLevelUp"
	add_child(cs)
	await get_tree().process_frame

	var old_level_before: int = cs.level
	var received: Array = []
	var cb = func(new_lvl: int, old_lvl: int) -> void:
		received.append([new_lvl, old_lvl])
	GameEvents.player_level_up.connect(cb)

	cs.level_up()

	assert_eq(received.size(), 1, "level_up 应触发 1 次 player_level_up")
	assert_eq(received[0][1], old_level_before, "old_level 参数应与升级前等级一致")
	assert_eq(received[0][0], old_level_before + 1, "new_level 参数应为旧等级+1")

	GameEvents.player_level_up.disconnect(cb)
	cs.queue_free()

# ============================================================================
# 测试辅助
# ============================================================================

## 构造 GameEvents 替身 — declared signals (combat_manager 用点访问要求 Signal 属性)
func _make_fake_game_events() -> Node:
	return FakeGameEventsScript.new()

## 构造 1 玩家 + 1 敌人战斗单位 (positional convention: 前半玩家, 后半敌人)
func _make_units_player_vs_enemy() -> Array:
	return [
		{
			"id": "player_001",
			"name": "测试玩家",
			"speed": 20,
			"hp": 100,
			"max_hp": 100,
			"internal_energy": 50,
			"max_internal_energy": 80,
			"stance": 100,
			"attributes": {"force": 20, "constitution": 10},
		},
		{
			"id": "enemy_001",
			"name": "测试敌人",
			"speed": 10,
			"hp": 80,
			"max_hp": 80,
			"internal_energy": 30,
			"max_internal_energy": 60,
			"stance": 100,
			"weaknesses": ["fire"],
			"attributes": {"force": 15, "constitution": 8},
		},
	]

# Callback recorders (避免 lambda 字段访问限制)
func _log_player_hp(current: int, max_value: int) -> void:
	_signal_log.append([current, max_value])

func _log_player_qi(current: int, max_value: int) -> void:
	_signal_log.append([current, max_value])

func _log_player_poise(current: int, max_value: int) -> void:
	_signal_log.append([current, max_value])

func _log_enemy_hp(enemy_id: String, current: int, max_value: int) -> void:
	_signal_log.append([enemy_id, current, max_value])

func _log_action_queue(queue: Array) -> void:
	_signal_log.append(queue)

func _log_enemy_selected(enemy: Dictionary) -> void:
	_signal_log.append(enemy)
