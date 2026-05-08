# DamageCalculator 单元测试
# 验证三种伤害类型计算、防御减伤、最小伤害等核心公式

extends GutTest

var _calculator

var _orphan_nodes: Array = []

func before_each():
	_calculator = DamageCalculator.new()
	add_child_autofree(_calculator)
	_orphan_nodes.clear()

func after_each():
	for node in _orphan_nodes:
		if is_instance_valid(node):
			node.free()
	_orphan_nodes.clear()

func _create_test_node() -> Node:
	var n = Node.new()
	_orphan_nodes.append(n)
	return n


# ============================================================================
# 测试 1：物理伤害计算 - 减法公式
# 公式: 伤害 = (力道 + 武器攻击力) - (根骨 + 护甲)
# ============================================================================
func test_physical_damage_subtraction_formula():
	var attacker = _create_test_node()
	attacker.set_meta("strength", 50)
	attacker.set_meta("weapon_attack", 20)
	
	var defender = _create_test_node()
	defender.set_meta("constitution", 30)
	defender.set_meta("armor", 10)
	
	var damage = _calculator.calculate_base_damage(
		attacker, defender, DamageCalculator.DamageType.PHYSICAL
	)
	
	# 攻击: 50 + 20 = 70, 防御: 30 + 10 = 40, 伤害: 70 - 40 = 30
	assert_eq(damage, 30, "物理伤害应该是 70 - 40 = 30")


# 测试：攻击低于防御时仍造成最小伤害
func test_physical_damage_below_defense_minimum():
	var attacker = _create_test_node()
	attacker.set_meta("strength", 10)
	attacker.set_meta("weapon_attack", 5)
	
	var defender = _create_test_node()
	defender.set_meta("constitution", 50)
	defender.set_meta("armor", 30)
	
	var damage = _calculator.calculate_base_damage(
		attacker, defender, DamageCalculator.DamageType.PHYSICAL
	)
	
	# 攻击: 15, 防御: 80, 差值: -65, 最小伤害: 1
	assert_eq(damage, 1, "伤害低于防御时应该造成最小伤害 1")


# 测试：无属性时造成最小伤害
func test_physical_damage_no_attributes():
	var attacker = _create_test_node()
	var defender = _create_test_node()
	
	var damage = _calculator.calculate_base_damage(
		attacker, defender, DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 1, "无属性时应该造成最小伤害 1")


# ============================================================================
# 测试 2：内功伤害计算
# 公式: 伤害 = (悟性 + 内力强度) - (悟性 + 内力抗性)
# ============================================================================
func test_energy_damage_subtraction_formula():
	var attacker = _create_test_node()
	attacker.set_meta("wisdom", 60)
	attacker.set_meta("qi_power", 30)
	
	var defender = _create_test_node()
	defender.set_meta("wisdom", 25)
	defender.set_meta("qi_resistance", 15)
	
	var damage = _calculator.calculate_base_damage(
		attacker, defender, DamageCalculator.DamageType.ENERGY
	)
	
	# 攻击: 60 + 30 = 90, 防御: 25 + 15 = 40, 伤害: 90 - 40 = 50
	assert_eq(damage, 50, "内功伤害应该是 90 - 40 = 50")


# 测试：内功伤害最小值
func test_energy_damage_minimum():
	var attacker = _create_test_node()
	attacker.set_meta("wisdom", 5)
	
	var defender = _create_test_node()
	defender.set_meta("wisdom", 50)
	defender.set_meta("qi_resistance", 30)
	
	var damage = _calculator.calculate_base_damage(
		attacker, defender, DamageCalculator.DamageType.ENERGY
	)
	
	assert_eq(damage, 1, "内功伤害应该至少为 1")


# ============================================================================
# 测试 3：真实伤害计算 - 无视防御
# ============================================================================
func test_true_damage_ignores_defense():
	var attacker = _create_test_node()
	attacker.set_meta("strength", 40)
	
	var defender = _create_test_node()
	defender.set_meta("constitution", 100)
	defender.set_meta("armor", 100)
	
	var damage = _calculator.calculate_base_damage(
		attacker, defender, DamageCalculator.DamageType.TRUE_DAMAGE
	)
	
	# 真实伤害无视防御，直接使用攻击者的 strength
	assert_eq(damage, 40, "真实伤害应该无视防御，直接使用攻击力")


# 测试：真实伤害最小值
func test_true_damage_minimum():
	var attacker = _create_test_node()
	# 没有 strength 属性
	
	var defender = _create_test_node()
	
	var damage = _calculator.calculate_base_damage(
		attacker, defender, DamageCalculator.DamageType.TRUE_DAMAGE
	)
	
	assert_eq(damage, 1, "真实伤害应该至少为 1")


# ============================================================================
# 测试 4：enforce_minimum_damage 边界值
# ============================================================================
func test_enforce_minimum_damage_zero():
	var result = _calculator.enforce_minimum_damage(0)
	assert_eq(result, 1, "0 应该被限制为最小伤害 1")


func test_enforce_minimum_damage_negative():
	var result = _calculator.enforce_minimum_damage(-100)
	assert_eq(result, 1, "负数应该被限制为最小伤害 1")


func test_enforce_minimum_damage_positive():
	var result = _calculator.enforce_minimum_damage(50)
	assert_eq(result, 50, "正数应该保持不变")


# ============================================================================
# 测试 5：apply_damage_type_rules 边界处理
# ============================================================================
func test_apply_damage_type_rules_physical():
	var result = _calculator.apply_damage_type_rules(
		DamageCalculator.DamageType.PHYSICAL, 100
	)
	assert_eq(result, 100, "物理伤害应该保持不变")


func test_apply_damage_type_rules_energy():
	var result = _calculator.apply_damage_type_rules(
		DamageCalculator.DamageType.ENERGY, 100
	)
	assert_eq(result, 100, "内功伤害应该保持不变")


func test_apply_damage_type_rules_true():
	var result = _calculator.apply_damage_type_rules(
		DamageCalculator.DamageType.TRUE_DAMAGE, 100
	)
	assert_eq(result, 100, "真实伤害应该保持不变")
