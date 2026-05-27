# 伤害倍率与修正 - 单元测试
#
# 测试 DamageMultiplierManager 的所有功能:
# - AC-1: 暴击系数正确应用
# - AC-2: 连击系数正确应用
# - AC-3: 弱点系数正确应用
# - AC-4: 状态效果修正正确

extends GutTest

# 导入实现文件
var DamageMultiplierManager

var multiplier_manager: DamageMultiplierManager

# ============================================================================
# 测试设置和清理
# ============================================================================

func before_all():
	DamageMultiplierManager = load("res://src/scripts/combat/damage_multiplier_manager.gd")

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
	assert_eq(result, 1.50, "易伤应该返回1.50 (GDD: 易伤=1.5)")


func test_status_multiplier_pojie_ignored():
	var result = multiplier_manager.calculate_status_multiplier(["破防"])
	assert_eq(result, 1.0, "破防在 status_multiplier 中不生效 (由 break_multiplier 单独处理)")


func test_status_multiplier_xuoruo():
	var result = multiplier_manager.calculate_status_multiplier(["虚弱"])
	assert_eq(result, 0.80, "虚弱应该返回0.80 (GDD: 虚弱=0.8)")


func test_status_multiplier_yishuang_and_xuoruo():
	var result = multiplier_manager.calculate_status_multiplier(["易伤", "虚弱"])
	assert_eq(result, 1.30, "易伤+虚弱应该返回1.30 (0.50 - 0.20 = 0.30)")


func test_status_multiplier_max_clamped():
	var result = multiplier_manager.calculate_status_multiplier(["易伤", "易伤", "易伤"])
	assert_eq(result, 2.0, "多个易伤叠加上限为 2.0 (GDD 范围 0.5-2.0)")


# ============================================================================
# AC-5: 破防系数正确应用
# ============================================================================

func test_break_multiplier_not_broken():
	var result = multiplier_manager.calculate_break_multiplier(false)
	assert_eq(result, 1.0, "未破防时应该返回1.0")


func test_break_multiplier_broken():
	var result = multiplier_manager.calculate_break_multiplier(true)
	assert_eq(result, 1.5, "破防时应该返回1.5 (GDD)")


# ============================================================================
# AC-6: 随机浮动范围正确
# ============================================================================

func test_random_variance_in_range():
	for i in range(100):
		var result = multiplier_manager.calculate_random_variance()
		assert_true(result >= 0.95 and result <= 1.05,
			"随机浮动应该在 0.95-1.05 范围内, 实际: %f" % result)


# ============================================================================
# 综合测试 (apply_all_multipliers 含随机浮动, 用范围断言)
# ============================================================================

func test_apply_all_multipliers_base():
	# 无任何乘数时, 结果仅受 random_variance (0.95-1.05) 影响
	var result = multiplier_manager.apply_all_multipliers(
		100, 0.0, 0.0, 0, "", "", [], false
	)
	assert_true(result >= 95 and result <= 105,
		"无修正时基础伤害 100 应在 95-105 范围 (随机浮动), 实际: %d" % result)


func test_apply_all_multipliers_with_combo():
	# combo_count=3 → 1.15, 随机 0.95-1.05 → 期望 109-121
	var result = multiplier_manager.apply_all_multipliers(
		100, 0.0, 0.0, 3, "", "", [], false
	)
	assert_true(result >= 109 and result <= 121,
		"连击3段 × 随机浮动 应在 109-121, 实际: %d" % result)


func test_apply_all_multipliers_with_weakness():
	# weakness → 1.5, 随机 0.95-1.05 → 期望 142-158
	var result = multiplier_manager.apply_all_multipliers(
		100, 0.0, 0.0, 0, "金", "木", [], false
	)
	assert_true(result >= 142 and result <= 158,
		"弱点克制 × 随机浮动 应在 142-158, 实际: %d" % result)


func test_apply_all_multipliers_with_break():
	# break → 1.5, 随机 0.95-1.05 → 期望 142-158
	var result = multiplier_manager.apply_all_multipliers(
		100, 0.0, 0.0, 0, "", "", [], true
	)
	assert_true(result >= 142 and result <= 158,
		"破防 × 随机浮动 应在 142-158, 实际: %d" % result)


func test_apply_all_multipliers_with_status():
	# 易伤 → 1.50, 随机 0.95-1.05 → 期望 142-158
	var result = multiplier_manager.apply_all_multipliers(
		100, 0.0, 0.0, 0, "", "", ["易伤"], false
	)
	assert_true(result >= 142 and result <= 158,
		"易伤 × 随机浮动 应在 142-158, 实际: %d" % result)


func test_apply_all_multipliers_combined():
	# 100 × crit(1.5) × combo(1.15) × weakness(1.5) × break(1.5) × 易伤(1.5) × random(0.95-1.05)
	# = 100 × 1.5 × 1.15 × 1.5 × 1.5 × 1.5 = 581.0625
	# × 0.95 = 552, × 1.05 = 610
	var result = multiplier_manager.apply_all_multipliers(
		100, 100.0, 0.0, 3, "金", "木", ["易伤"], true
	)
	assert_true(result >= 552 and result <= 610,
		"全乘数组合应在 552-610, 实际: %d" % result)