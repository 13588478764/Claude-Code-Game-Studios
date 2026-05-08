# WeaknessSystem 单元测试
# 验证五行相克、弱点打击判定、击倒机制和总攻击触发

extends GutTest

var _system
var _mock_combat
var _mock_nodes: Array = []

class MockCombat extends Node:
	var participants: Array = []

func before_each():
	_system = WeaknessSystem.new()
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

# 初始化弱点系统（使用 MockCombat 绕过战斗系统引用）
func _init_weakness_system(participants: Array = []):
	_system.participant_weaknesses.clear()
	_system.participant_down_status.clear()
	var mock = MockCombat.new()
	_mock_combat = mock
	mock.participants = participants
	_system.combat_system = mock
	for p in participants:
		_mock_nodes.append(p)

func _create_mock_participant() -> Node:
	var p = Node.new()
	_mock_nodes.append(p)
	return p


# ============================================================================
# 测试 1：五行相克关系
# 金克木、木克土、土克水、水克火、火克金
# ============================================================================
func test_elemental_weakness_metal_beats_wood():
	assert_true(_system.check_elemental_weakness(WeaknessSystem.Element.METAL, WeaknessSystem.Element.WOOD),
		"金应该克制木")


func test_elemental_weakness_wood_beats_earth():
	assert_true(_system.check_elemental_weakness(WeaknessSystem.Element.WOOD, WeaknessSystem.Element.EARTH),
		"木应该克制土")


func test_elemental_weakness_earth_beats_water():
	assert_true(_system.check_elemental_weakness(WeaknessSystem.Element.EARTH, WeaknessSystem.Element.WATER),
		"土应该克制水")


func test_elemental_weakness_water_beats_fire():
	assert_true(_system.check_elemental_weakness(WeaknessSystem.Element.WATER, WeaknessSystem.Element.FIRE),
		"水应该克制火")


func test_elemental_weakness_fire_beats_metal():
	assert_true(_system.check_elemental_weakness(WeaknessSystem.Element.FIRE, WeaknessSystem.Element.METAL),
		"火应该克制金")


# 测试：非克制关系
func test_no_weakness_same_element():
	assert_false(_system.check_elemental_weakness(WeaknessSystem.Element.FIRE, WeaknessSystem.Element.FIRE),
		"相同属性不应该有克制关系")


func test_no_weakness_reversed():
	assert_false(_system.check_elemental_weakness(WeaknessSystem.Element.WOOD, WeaknessSystem.Element.METAL),
		"木不应该克制金（反向）")


# ============================================================================
# 测试 2：弱点打击判定
# ============================================================================
func test_weakness_hit_with_exposed_weakness():
	var attacker = _create_mock_participant()
	var target = _create_mock_participant()
	
	# 目标弱点为木，攻击属性为金（克制木）
	_system.set_participant_weakness(target, WeaknessSystem.Element.WOOD, true)
	
	var result = _system.calculate_weakness_hit(attacker, target, WeaknessSystem.Element.METAL)
	
	assert_true(result.is_weakness_hit, "攻击克制属性且弱点暴露时应该命中弱点")
	assert_true(abs(result.damage_multiplier - 1.5) < 0.01, "弱点伤害倍率应该是 1.5")
	assert_true(result.triggered_down, "命中弱点应该触发击倒")


func test_no_weakness_hit_when_not_exposed():
	var attacker = _create_mock_participant()
	var target = _create_mock_participant()
	
	# 目标弱点为木但未暴露
	_system.set_participant_weakness(target, WeaknessSystem.Element.WOOD, false)
	
	var result = _system.calculate_weakness_hit(attacker, target, WeaknessSystem.Element.METAL)
	
	assert_false(result.is_weakness_hit, "弱点未暴露时不应该命中弱点")
	assert_true(abs(result.damage_multiplier - 1.0) < 0.01, "伤害倍率应该是 1.0")
	assert_false(result.triggered_down, "弱点未暴露时不应该触发击倒")


func test_no_weakness_hit_when_not_weakness_element():
	var attacker = _create_mock_participant()
	var target = _create_mock_participant()
	
	# 目标弱点为木，攻击属性为水（不克制木）
	_system.set_participant_weakness(target, WeaknessSystem.Element.WOOD, true)
	
	var result = _system.calculate_weakness_hit(attacker, target, WeaknessSystem.Element.WATER)
	
	assert_false(result.is_weakness_hit, "非克制属性不应该命中弱点")
	assert_true(abs(result.damage_multiplier - 1.0) < 0.01, "伤害倍率应该是 1.0")


func test_no_weakness_hit_when_no_weakness_set():
	var attacker = _create_mock_participant()
	var target = _create_mock_participant()
	
	# 目标没有设置弱点
	var result = _system.calculate_weakness_hit(attacker, target, WeaknessSystem.Element.METAL)
	
	assert_false(result.is_weakness_hit, "没有设置弱点时不应该命中弱点")
	assert_true(abs(result.damage_multiplier - 1.0) < 0.01, "伤害倍率应该是 1.0")


# ============================================================================
# 测试 3：击倒机制
# ============================================================================
func test_trigger_down_sets_status():
	var target = _create_mock_participant()
	
	_system.trigger_down(target)
	
	assert_true(_system.is_down(target), "触发击倒后应该处于击倒状态")


func test_clear_down_removes_status():
	var target = _create_mock_participant()
	
	_system.trigger_down(target)
	_system.clear_down(target)
	
	assert_false(_system.is_down(target), "清除击倒后应该不再处于击倒状态")


func test_double_down_no_duplicate():
	var target = _create_mock_participant()
	
	_system.trigger_down(target)
	_system.trigger_down(target)
	
	assert_true(_system.is_down(target), "多次触发击倒应该保持击倒状态")


# ============================================================================
# 测试 4：击倒易伤倍率
# ============================================================================
func test_down_damage_multiplier():
	var target = _create_mock_participant()
	
	_system.trigger_down(target)
	
	assert_true(abs(_system.get_down_damage_multiplier(target) - 1.5) < 0.01,
		"击倒状态的伤害倍率应该是 1.5")


func test_normal_damage_multiplier():
	var target = _create_mock_participant()
	
	assert_true(abs(_system.get_down_damage_multiplier(target) - 1.0) < 0.01,
		"非击倒状态的伤害倍率应该是 1.0")


# ============================================================================
# 测试 5：总攻击触发条件
# ============================================================================
func test_all_out_attack_when_all_enemies_down():
	var e1 = _create_mock_participant()
	var e2 = _create_mock_participant()
	_init_weakness_system([e1, e2])
	
	_system.set_participant_weakness(e1, WeaknessSystem.Element.WOOD, true)
	_system.set_participant_weakness(e2, WeaknessSystem.Element.WOOD, true)
	
	_system.trigger_down(e1)
	_system.trigger_down(e2)
	
	assert_true(_system.is_all_out_attack_available(), "所有敌人都被击倒时应该可以发动总攻击")


func test_all_out_attack_not_available_when_some_alive():
	var e1 = _create_mock_participant()
	var e2 = _create_mock_participant()
	_init_weakness_system([e1, e2])
	
	_system.set_participant_weakness(e1, WeaknessSystem.Element.WOOD, true)
	_system.set_participant_weakness(e2, WeaknessSystem.Element.WOOD, true)
	
	_system.trigger_down(e1)
	
	assert_false(_system.is_all_out_attack_available(), "还有敌人存活时不应该可以发动总攻击")


# ============================================================================
# 测试 6：暴露/隐藏弱点
# ============================================================================
func test_expose_weakness():
	var target = _create_mock_participant()
	_system.set_participant_weakness(target, WeaknessSystem.Element.WOOD, false)
	
	_system.expose_weakness(target)
	
	assert_true(_system.get_participant_weakness(target).is_exposed, "暴露弱点后弱点应该变为暴露状态")


func test_hide_weakness():
	var target = _create_mock_participant()
	_system.set_participant_weakness(target, WeaknessSystem.Element.WOOD, true)
	
	_system.hide_weakness(target)
	
	assert_false(_system.get_participant_weakness(target).is_exposed, "隐藏弱点后弱点应该变为隐藏状态")


# ============================================================================
# 测试 7：重置系统
# ============================================================================
func test_reset_clears_all_data():
	var target = _create_mock_participant()
	_system.set_participant_weakness(target, WeaknessSystem.Element.WOOD, true)
	_system.trigger_down(target)
	
	_system.reset()
	
	assert_true(_system.get_participant_weakness(target) == null, "重置后弱点信息应该被清除")
	assert_false(_system.is_down(target), "重置后击倒状态应该被清除")
