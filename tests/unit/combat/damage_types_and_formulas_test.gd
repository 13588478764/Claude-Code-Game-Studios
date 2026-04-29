# 伤害类型与公式 - 单元测试
#
# 测试 DamageCalculator 的所有功能:
# - AC-1: 三种伤害类型正确实现
# - AC-2: 基础伤害计算公式正确
# - AC-3: 攻防属性正确应用
# - AC-4: 最小伤害限制正常

extends GutTest

# 导入实现文件
const DamageCalculator = preload("res://src/scripts/combat/damage_calculator.gd")

var damage_calculator: DamageCalculator
var attacker: Node
var defender: Node

# ============================================================================
# 测试设置和清理
# ============================================================================

func before_each():
	damage_calculator = DamageCalculator.new()
	add_child(damage_calculator)
	
	attacker = Node.new()
	defender = Node.new()
	add_child(attacker)
	add_child(defender)


func after_each():
	if damage_calculator:
		damage_calculator.queue_free()
	if attacker:
		attacker.queue_free()
	if defender:
		defender.queue_free()


# ============================================================================
# AC-1: 三种伤害类型正确实现
# ============================================================================

func test_physical_damage_type_uses_str_and_weapon_attack():
	attacker.set_meta("strength", 100)
	attacker.set_meta("weapon_attack", 50)
	defender.set_meta("constitution", 30)
	defender.set_meta("armor", 20)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 100, "外功伤害应该正确计算")


func test_energy_damage_type_uses_wis_and_qi_power():
	attacker.set_meta("wisdom", 80)
	attacker.set_meta("qi_power", 40)
	defender.set_meta("wisdom", 50)
	defender.set_meta("qi_resistance", 15)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.ENERGY
	)
	
	assert_eq(damage, 55, "内功伤害应该正确计算")


func test_true_damage_ignores_defense():
	attacker.set_meta("strength", 100)
	defender.set_meta("constitution", 200)
	defender.set_meta("armor", 100)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.TRUE_DAMAGE
	)
	
	assert_eq(damage, 100, "真实伤害应该无视防御")


# ============================================================================
# AC-2: 基础伤害计算公式正确
# ============================================================================

func test_base_damage_formula_150_minus_80_equals_70():
	attacker.set_meta("strength", 150)
	attacker.set_meta("weapon_attack", 0)
	defender.set_meta("constitution", 80)
	defender.set_meta("armor", 0)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 70, "基础伤害公式应该正确")


func test_high_attack_power():
	attacker.set_meta("strength", 1000)
	attacker.set_meta("weapon_attack", 0)
	defender.set_meta("constitution", 100)
	defender.set_meta("armor", 0)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 900, "高攻击力应该正确计算")


func test_high_defense_power():
	attacker.set_meta("strength", 100)
	attacker.set_meta("weapon_attack", 0)
	defender.set_meta("constitution", 500)
	defender.set_meta("armor", 0)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 1, "高防御力应该被限制为最小伤害1")


func test_equal_attack_and_defense():
	attacker.set_meta("strength", 100)
	attacker.set_meta("weapon_attack", 0)
	defender.set_meta("constitution", 100)
	defender.set_meta("armor", 0)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 1, "攻防相等时伤害应该被限制为1")


# ============================================================================
# AC-3: 攻防属性正确应用
# ============================================================================

func test_physical_damage_uses_str_vs_con():
	attacker.set_meta("strength", 100)
	attacker.set_meta("weapon_attack", 0)
	defender.set_meta("constitution", 50)
	defender.set_meta("armor", 0)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 50, "外功伤害应该使用力道vs根骨")


func test_energy_damage_uses_wis_vs_wis():
	attacker.set_meta("wisdom", 80)
	attacker.set_meta("qi_power", 0)
	defender.set_meta("wisdom", 40)
	defender.set_meta("qi_resistance", 0)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.ENERGY
	)
	
	assert_eq(damage, 40, "内功伤害应该使用悟性vs悟性")


func test_equipment_defense_bonus():
	attacker.set_meta("strength", 100)
	attacker.set_meta("weapon_attack", 0)
	defender.set_meta("constitution", 50)
	defender.set_meta("armor", 30)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 20, "装备防御加成应该正确应用")


# ============================================================================
# AC-4: 最小伤害限制正常
# ============================================================================

func test_minimum_damage_limit_negative_damage():
	attacker.set_meta("strength", 10)
	attacker.set_meta("weapon_attack", 0)
	defender.set_meta("constitution", 50)
	defender.set_meta("armor", 0)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 1, "负数伤害应该被限制为1")


func test_minimum_damage_limit_zero_damage():
	attacker.set_meta("strength", 50)
	attacker.set_meta("weapon_attack", 0)
	defender.set_meta("constitution", 50)
	defender.set_meta("armor", 0)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 1, "0伤害应该被限制为1")


func test_minimum_damage_limit_very_low_damage():
	attacker.set_meta("strength", 0)
	attacker.set_meta("weapon_attack", 0)
	defender.set_meta("constitution", 200)
	defender.set_meta("armor", 0)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 1, "极低伤害应该被限制为1")


func test_minimum_damage_does_not_affect_positive_damage():
	attacker.set_meta("strength", 100)
	attacker.set_meta("weapon_attack", 0)
	defender.set_meta("constitution", 50)
	defender.set_meta("armor", 0)
	
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 50, "正数伤害不应该被最小伤害限制影响")


# ============================================================================
# 边界情况测试
# ============================================================================

func test_missing_attributes_default_to_zero():
	var damage = damage_calculator.calculate_base_damage(
		attacker, 
		defender, 
		DamageCalculator.DamageType.PHYSICAL
	)
	
	assert_eq(damage, 1, "缺失属性应该默认为0")


func test_apply_damage_type_rules_physical():
	var result = damage_calculator.apply_damage_type_rules(
		DamageCalculator.DamageType.PHYSICAL,
		100
	)
	assert_eq(result, 100, "外功伤害规则应该返回原值")


func test_apply_damage_type_rules_energy():
	var result = damage_calculator.apply_damage_type_rules(
		DamageCalculator.DamageType.ENERGY,
		100
	)
	assert_eq(result, 100, "内功伤害规则应该返回原值")


func test_apply_damage_type_rules_true_damage():
	var result = damage_calculator.apply_damage_type_rules(
		DamageCalculator.DamageType.TRUE_DAMAGE,
		100
	)
	assert_eq(result, 100, "真实伤害规则应该返回原值")


func test_enforce_minimum_damage_positive():
	var result = damage_calculator.enforce_minimum_damage(50)
	assert_eq(result, 50, "正数伤害应该保持不变")


func test_enforce_minimum_damage_zero():
	var result = damage_calculator.enforce_minimum_damage(0)
	assert_eq(result, 1, "0伤害应该被限制为1")


func test_enforce_minimum_damage_negative():
	var result = damage_calculator.enforce_minimum_damage(-50)
	assert_eq(result, 1, "负数伤害应该被限制为1")