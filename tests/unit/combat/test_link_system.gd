# LinkSystem 单元测试
# 验证连携槽、连击系统、连携攻击和条件判定

extends GutTest

var _system
var _mock_combat
var _mock_nodes: Array = []

class MockCombat extends Node:
	var participants: Array = []

func before_each():
	_system = LinkSystem.new()
	add_child_autofree(_system)
	_mock_combat = null
	_mock_nodes.clear()

func after_each():
	if is_instance_valid(_mock_combat):
		_mock_combat.free()
	for node in _mock_nodes:
		if is_instance_valid(node):
			node.free()
	_mock_nodes.clear()

func _init_system(participants: Array = []):
	var mock = MockCombat.new()
	_mock_combat = mock
	mock.participants = participants
	for p in participants:
		_mock_nodes.append(p)
	_system.combat_system = mock
	_system.participants = participants
	_system.link_gauge = LinkSystem.LinkGauge.new(100.0)
	_system.combo_tracker = LinkSystem.ComboTracker.new(10)
	_system.available_link_attacks.clear()
	_system._setup_default_link_attacks()

func _create_mock_participant() -> Node:
	var p = Node.new()
	_mock_nodes.append(p)
	return p

# ============================================================================
# 测试 1：连携槽积累和消耗
# ============================================================================
func test_link_gauge_accumulate():
	_init_system()
	_system.accumulate_link_gauge(30)
	
	assert_eq(_system.get_link_gauge_current(), 30.0, "连携槽应该积累到 30")


func test_link_gauge_caps_at_max():
	_init_system()
	_system.accumulate_link_gauge(150)
	
	assert_true(_system.is_link_gauge_full(), "连携槽应该满了")
	assert_eq(_system.get_link_gauge_current(), 100.0, "连携槽不应该超过最大值")


func test_link_gauge_consume():
	_init_system()
	_system.accumulate_link_gauge(60)
	
	var success = _system.link_gauge.consume(40)
	
	assert_true(success, "连携槽足够时消耗应该成功")
	assert_eq(_system.get_link_gauge_current(), 20.0, "消耗后连携槽应该是 20")


func test_link_gauge_consume_insufficient():
	_init_system()
	_system.accumulate_link_gauge(30)
	
	var success = _system.link_gauge.consume(50)
	
	assert_false(success, "连携槽不足时消耗应该失败")
	assert_eq(_system.get_link_gauge_current(), 30.0, "消耗失败时连携槽应该不变")


func test_link_gauge_reset():
	_init_system()
	_system.accumulate_link_gauge(50)
	_system.reset()
	
	assert_eq(_system.get_link_gauge_current(), 0.0, "重置后连携槽应该为 0")


# ============================================================================
# 测试 2：连击系统
# ============================================================================
func test_first_hit_multiplier():
	_init_system()
	var target = _create_mock_participant()
	var multiplier = _system.record_hit(target)
	
	assert_eq(_system.get_combo_count(), 1, "第一次命中后连击数应该是 1")
	assert_true(abs(multiplier - 1.0) < 0.01, "第一次命中伤害倍率应该是 1.0")


func test_combo_damage_scaling():
	_init_system()
	var target = _create_mock_participant()
	
	_system.record_hit(target)
	_system.record_hit(target)
	_system.record_hit(target)
	_system.record_hit(target)
	_system.record_hit(target)
	
	assert_eq(_system.get_combo_count(), 5, "连击数应该是 5")
	assert_true(abs(_system.get_combo_damage_multiplier() - 1.4) < 0.01,
		"5连击伤害倍率应该是 1.4")


func test_combo_caps_at_max():
	_init_system()
	var target = _create_mock_participant()
	
	for i in range(15):
		_system.record_hit(target)
	
	assert_eq(_system.get_combo_count(), 10, "连击数应该被限制在最大值 10")


func test_combo_resets_on_target_change():
	_init_system()
	var target1 = _create_mock_participant()
	var target2 = _create_mock_participant()
	
	_system.record_hit(target1)
	_system.record_hit(target1)
	_system.record_hit(target1)
	
	_system.record_hit(target2)
	
	assert_eq(_system.get_combo_count(), 1, "切换目标后连击应该重置为 1")


func test_manual_combo_reset():
	_init_system()
	var target = _create_mock_participant()
	
	_system.record_hit(target)
	_system.record_hit(target)
	_system.reset_combo()
	
	assert_eq(_system.get_combo_count(), 0, "手动重置后连击数应该是 0")
	assert_true(abs(_system.get_combo_damage_multiplier() - 1.0) < 0.01,
		"手动重置后伤害倍率应该是 1.0")


# ============================================================================
# 测试 3：每次命中积累连携槽
# ============================================================================
func test_hit_accumulates_link_gauge():
	_init_system()
	var target = _create_mock_participant()
	
	_system.record_hit(target)
	
	assert_eq(_system.get_link_gauge_current(), 10.0, "每次命中应该积累 10 点连携槽")


func test_multiple_hits_accumulate_gauge():
	_init_system()
	var target = _create_mock_participant()
	
	for i in range(5):
		_system.record_hit(target)
	
	assert_eq(_system.get_link_gauge_current(), 50.0, "5次命中应该积累 50 点连携槽")


# ============================================================================
# 测试 4：连携攻击执行
# ============================================================================
func test_execute_follow_up_attack():
	var p = _create_mock_participant()
	_init_system([p])
	var target = _create_mock_participant()
	
	for i in range(5):
		_system.record_hit(target)
	
	var result = _system.execute_link_attack("追击")
	
	assert_true(result, "追击攻击应该成功执行")
	assert_eq(_system.get_link_gauge_current(), 0.0, "追击后连携槽应该被消耗")
	assert_eq(_system.get_combo_count(), 0, "追击后连击应该被重置")


func test_execute_follow_up_insufficient_gauge():
	_init_system()
	var target = _create_mock_participant()
	
	_system.record_hit(target)
	_system.record_hit(target)
	_system.record_hit(target)
	
	var result = _system.execute_link_attack("追击")
	
	assert_false(result, "连携槽不足时追击应该失败")


func test_execute_dual_tech_attack():
	var p1 = _create_mock_participant()
	var p2 = _create_mock_participant()
	var p3 = _create_mock_participant()
	_init_system([p1, p2, p3])
	var target = _create_mock_participant()
	
	for i in range(10):
		_system.record_hit(target)
	
	var result = _system.execute_link_attack("合体技")
	
	assert_true(result, "合体技应该成功执行")
	assert_true(abs(_system.get_link_gauge_current() - 0.0) < 0.01, "合体技后连携槽应该被消耗")


func test_execute_dual_tech_insufficient_teammates():
	var p = _create_mock_participant()
	_init_system([p])
	var target = _create_mock_participant()
	for i in range(10):
		_system.record_hit(target)
	
	var result = _system.execute_link_attack("合体技")
	
	assert_false(result, "队友不足时合体技应该失败")


func test_execute_nonexistent_attack():
	_init_system()
	
	var result = _system.execute_link_attack("不存在的攻击")
	
	assert_false(result, "执行不存在的攻击应该失败")


# ============================================================================
# 测试 5：连携条件检查
# ============================================================================
func test_get_available_link_attacks_initial():
	var p = _create_mock_participant()
	_init_system([p])
	
	var available = _system.get_available_link_attacks()
	
	assert_eq(available.size(), 0, "初始状态没有可用的连携攻击")


func test_get_available_link_attacks_with_sufficient_gauge():
	var p = _create_mock_participant()
	_init_system([p])
	var target = _create_mock_participant()
	
	for i in range(5):
		_system.record_hit(target)
	
	var available = _system.get_available_link_attacks()
	
	assert_eq(available.size(), 1, "积累5次命中后应该有1个可用攻击（追击）")


func test_get_available_link_attacks_dual_tech():
	var p1 = _create_mock_participant()
	var p2 = _create_mock_participant()
	var p3 = _create_mock_participant()
	_init_system([p1, p2, p3])
	var target = _create_mock_participant()
	
	for i in range(10):
		_system.record_hit(target)
	
	var available = _system.get_available_link_attacks()
	
	assert_eq(available.size(), 2, "积累10次命中后应该有2个可用攻击（追击和合体技）")
