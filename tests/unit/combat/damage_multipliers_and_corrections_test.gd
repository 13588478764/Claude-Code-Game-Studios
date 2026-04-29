# 伤害倍率与修正 - 单元测试
#
# 测试 DamageMultiplierManager 的所有功能:
# - AC-1: 暴击系数正确应用
# - AC-2: 连击系数正确应用
# - AC-3: 弱点系数正确应用
# - AC-4: 状态效果修正正确

extends GutTest

# 导入实现文件
const DamageMultiplierManager = preload("res://src/scripts/combat/damage_multiplier_manager.gd")

var multiplier_manager: DamageMultiplierManager

# ============================================================================
# 测试设置和清理
# ============================================================================

func before_each():
	multiplier_manager = DamageMultiplierManager.new()
	add_child(multiplier_manager)


func after_each():
	if multiplier_manager:
		multiplier_manager.queue_free()


# ============================================================================
# AC-1: 暴击系数正确应用
# ============================================================================

func test_critical_multiplier_no_critical():
	var result = multiplier_manager.calculate_critical_multiplier(0.0, 100.0)
	assert_eq(result, 1.0, "暴击率为0时应该返回1.0")


func test_critical_multiplier_min_value():
	# 设置暴击率为100%确保触发暴击，暴击伤害为0
	var result = multiplier_manager.calculate_critical_multiplier(100.0, 0.0)
	assert_eq(result, 1.5, "暴击伤害为0时应该返回最小值1.5")


func test_critical_multiplier_max_value():
	# 设置暴击率为100%确保触发暴击，暴击伤害为100%
	var result = multiplier_manager.calculate_critical_multiplier(100.0, 100.0)
	assert_eq(result, 2.0, "暴击伤害为100%时应该返回最大值2.0")


func test_critical_multiplier_mid_value():
	# 设置暴击率为100%确保触发暴击，暴击伤害为50%
	var result = multiplier_manager.calculate_critical_multiplier(100.0, 50.0)
	assert_eq(result, 1.75, "暴击伤害为50%时应该返回1.75")


func test_critical_multiplier_clamped():
	# 测试参数超出范围时的处理
	var result = multiplier_manager.calculate_critical_multiplier(150.0, 150.0)
	assert_eq(result, 2.0, "参数超出范围时应该被限制")


# ============================================================================
# AC-2: 连击系数正确应用
# ============================================================================

func test_combo_multiplier_zero():
	var result = multiplier_manager.calculate_combo_multiplier(0)
	assert_eq(result, 1.0, "连击数为0时应该返回1.0")


func test_combo_multiplier_one():
	var result = multiplier_manager.calculate_combo_multiplier(1)
	assert_eq(result, 1.05, "连击数为1时应该返回1.05")


func test_combo_multiplier_three():
	var result = multiplier_manager.calculate_combo_multiplier(3)
	assert_eq(result, 1.15, "连击数为3时应该返回1.15")


func test_combo_multiplier_six():
	var result = multiplier_manager.calculate_combo_multiplier(6)
	assert_eq(result, 1.30, "连击数为6时应该返回最大值1.30")


func test_combo_multiplier_max_clamped():
	var result = multiplier_manager.calculate_combo_multiplier(10)
	assert_eq(result, 1.30, "连击数超过上限时应该被限制为1.30")


func test_combo_multiplier_negative():
	var result = multiplier_manager.calculate_combo_multiplier(-5)
	assert_eq(result, 1.0, "负数连击数应该被处理为0")


# ============================================================================
# AC-3: 弱点系数正确应用
# ============================================================================

func test_weakness_multiplier_no_weakness():
	var result = multiplier_manager.calculate_weakness_multiplier("金", "")
	assert_eq(result, 1.0, "没有弱点时应该返回1.0")


func test_weakness_multiplier_no_element():
	var result = multiplier_manager.calculate_weakness_multiplier("", "木")
	assert_eq(result, 1.0, "没有攻击属性时应该返回1.0")


func test_weakness_multiplier_no_advantage():
	var result = multiplier_manager.calculate_weakness_multiplier("金", "火")
	assert_eq(result, 1.0, "没有克制关系时应该返回1.0")


func test_weakness_multiplier_jin_克_mu():
	var result = multiplier_manager.calculate_weakness_multiplier("金", "木")
	assert_eq(result, 1.5, "金克木应该返回1.5")


func test_weakness_multiplier_mu_克_tu():
	var result = multiplier_manager.calculate_weakness_multiplier("木", "土")
	assert_eq(result, 1.5, "木克土应该返回1.5")


func test_weakness_multiplier_tu_克_shui():
	var result = multiplier_manager.calculate_weakness_multiplier("土", "水")
	assert_eq(result, 1.5, "土克水应该返回1.5")


func test_weakness_multiplier_shui_克_huo():
	var result = multiplier_manager.calculate_weakness_multiplier("水", "火")
	assert_eq(result, 1.5, "水克火应该返回1.5")


func test_weakness_multiplier_huo_克_jin():
	var result = multiplier_manager.calculate_weakness_multiplier("火", "金")
	assert_eq(result, 1.5, "火克金应该返回1.5")


# ============================================================================
# AC-4: 状态效果修正正确
# ============================================================================

func test_status_multiplier_empty():
	var result = multiplier_manager.calculate_status_multiplier([])
	assert_eq(result, 1.0, "没有状态效果时应该返回1.0")


func test_status_multiplier_yishuang():
	var result = multiplier_manager.calculate_status_multiplier(["易伤"])
	assert_eq(result, 1.20, "易伤应该返回1.20")


func test_status_multiplier_pojie():
	var result = multiplier_manager.calculate_status_multiplier(["破防"])
	assert_eq(result, 1.15, "破防应该返回1.15")


func test_status_multiplier_xuoruo():
	var result = multiplier_manager.calculate_status_multiplier(["虚弱"])
	assert_eq(result, 1.10, "虚弱应该返回1.10")


func test_status_multiplier_multiple():
	var result = multiplier_manager.calculate_status_multiplier(["易伤", "破防"])
	assert_eq(result, 1.35, "易伤+破防应该返回1.35")


func test_status_multiplier_max_clamped():
	var result = multiplier_manager.calculate_status_multiplier(["易伤", "破防", "虚弱", "虚弱"])
	assert_eq(result, 1.50, "多个状态效果应该被限制为最大值1.50")


# ============================================================================
# 综合测试
# ============================================================================

func test_apply_all_multipliers_base():
	var result = multiplier_manager.apply_all_multipliers(
		100,      # base_damage
		0.0,      # critical_chance
		0.0,      # critical_damage
		0,        # combo_count
		"",       # attack_element
		"",       # target_weakness
		[]        # status_effects
	)
	assert_eq(result, 100, "无任何修正时应该返回基础伤害")


func test_apply_all_multipliers_with_combo():
	var result = multiplier_manager.apply_all_multipliers(
		100,      # base_damage
		0.0,      # critical_chance
		0.0,      # critical_damage
		3,        # combo_count (1.15倍)
		"",       # attack_element
		"",       # target_weakness
		[]        # status_effects
	)
	assert_eq(result, 115, "连击3段应该返回115")


func test_apply_all_multipliers_with_weakness():
	var result = multiplier_manager.apply_all_multipliers(
		100,      # base_damage
		0.0,      # critical_chance
		0.0,      # critical_damage
		0,        # combo_count
		"金",     # attack_element
		"木",     # target_weakness (1.5倍)
		[]        # status_effects
	)
	assert_eq(result, 150, "弱点克制应该返回150")


func test_apply_all_multipliers_with_status():
	var result = multiplier_manager.apply_all_multipliers(
		100,      # base_damage
		0.0,      # critical_chance
		0.0,      # critical_damage
		0,        # combo_count
		"",       # attack_element
		"",       # target_weakness
		["易伤"]  # status_effects (1.20倍)
	)
	assert_eq(result, 120, "易伤状态应该返回120")


func test_apply_all_multipliers_combined():
	var result = multiplier_manager.apply_all_multipliers(
		100,      # base_damage
		100.0,    # critical_chance (1.5倍)
		0.0,      # critical_damage
		3,        # combo_count (1.15倍)
		"金",     # attack_element
		"木",     # target_weakness (1.5倍)
		["易伤"]  # status_effects (1.20倍)
	)
	# 100 * 1.5 * 1.15 * 1.5 * 1.20 = 311.25 -> 311
	assert_eq(result, 311, "所有修正组合应该正确计算")


func test_apply_all_multipliers_rounding():
	var result = multiplier_manager.apply_all_multipliers(
		100,      # base_damage
		100.0,    # critical_chance (1.5倍)
		50.0,     # critical_damage (1.75倍)
		1,        # combo_count (1.05倍)
		"",       # attack_element
		"",       # target_weakness
		[]        # status_effects
	)
	# 100 * 1.75 * 1.05 = 183.75 -> 184
	assert_eq(result, 184, "伤害应该正确四舍五入")