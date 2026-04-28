# 伤害倍率与修正单元测试
# 验证暴击、连击、弱点和状态效果修正

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_critical_multiplier_correctly_applied())
	results.append(test_combo_multiplier_correctly_applied())
	results.append(test_weakness_multiplier_correctly_applied())
	results.append(test_status_effect_correction_correct())
	
	return results

# 测试1: 暴击系数正确应用
func test_critical_multiplier_correctly_applied() -> TestResult:
	var result = TestResult.new()
	result.test_name = "暴击系数正确应用"
	
	# 创建伤害倍率管理器实例
	var multiplier_manager = load("res://src/scripts/combat/damage_multiplier_manager.gd").new()
	
	# 测试不同暴击伤害加成
	var crit_mult_50 = multiplier_manager.calculate_critical_multiplier(0.1, 0.5)  # 1.5倍
	var crit_mult_100 = multiplier_manager.calculate_critical_multiplier(0.1, 1.0)  # 2.0倍
	
	# 验证结果
	if abs(crit_mult_50 - 1.5) < 0.01 and abs(crit_mult_100 - 2.0) < 0.01:
		result.passed = true
		result.message = "暴击系数正确: 50%%加成=%g倍, 100%%加成=%g倍" % [crit_mult_50, crit_mult_100]
	else:
		result.passed = false
		result.message = "暴击系数错误: 期望1.5和2.0, 实际%g和%g" % [crit_mult_50, crit_mult_100]
	
	return result

# 测试2: 连击系数正确应用
func test_combo_multiplier_correctly_applied() -> TestResult:
	var result = TestResult.new()
	result.test_name = "连击系数正确应用"
	
	# 创建伤害倍率管理器实例
	var multiplier_manager = load("res://src/scripts/combat/damage_multiplier_manager.gd").new()
	
	# 测试不同连击数
	var combo_mult_0 = multiplier_manager.calculate_combo_multiplier(0)  # 1.0倍
	var combo_mult_3 = multiplier_manager.calculate_combo_multiplier(3)  # 1.15倍 (3*5%)
	var combo_mult_6 = multiplier_manager.calculate_combo_multiplier(6)  # 1.30倍 (上限30%)
	
	# 验证结果
	if abs(combo_mult_0 - 1.0) < 0.01 and abs(combo_mult_3 - 1.15) < 0.01 and abs(combo_mult_6 - 1.30) < 0.01:
		result.passed = true
		result.message = "连击系数正确: 0连击=%g倍, 3连击=%g倍, 6连击=%g倍" % [combo_mult_0, combo_mult_3, combo_mult_6]
	else:
		result.passed = false
		result.message = "连击系数错误: 期望1.0, 1.15, 1.30, 实际%g, %g, %g" % [combo_mult_0, combo_mult_3, combo_mult_6]
	
	return result

# 测试3: 弱点系数正确应用
func test_weakness_multiplier_correctly_applied() -> TestResult:
	var result = TestResult.new()
	result.test_name = "弱点系数正确应用"
	
	# 创建伤害倍率管理器实例
	var multiplier_manager = load("res://src/scripts/combat/damage_multiplier_manager.gd").new()
	
	# 测试弱点克制
	var weakness_mult_hit = multiplier_manager.calculate_weakness_multiplier(
		multiplier_manager.ElementType.FIRE,  # 攻击元素
		multiplier_manager.ElementType.METAL   # 目标弱点
	)
	
	# 测试无克制关系
	var weakness_mult_miss = multiplier_manager.calculate_weakness_multiplier(
		multiplier_manager.ElementType.FIRE,  # 攻击元素
		multiplier_manager.ElementType.WATER  # 目标弱点（非克制）
	)
	
	# 验证结果
	if abs(weakness_mult_hit - 1.5) < 0.01 and abs(weakness_mult_miss - 1.0) < 0.01:
		result.passed = true
		result.message = "弱点系数正确: 克制=%g倍, 无克制=%g倍" % [weakness_mult_hit, weakness_mult_miss]
	else:
		result.passed = false
		result.message = "弱点系数错误: 期望1.5和1.0, 实际%g和%g" % [weakness_mult_hit, weakness_mult_miss]
	
	return result

# 测试4: 状态效果修正正确
func test_status_effect_correction_correct() -> TestResult:
	var result = TestResult.new()
	result.test_name = "状态效果修正正确"
	
	# 创建伤害倍率管理器实例
	var multiplier_manager = load("res://src/scripts/combat/damage_multiplier_manager.gd").new()
	
	# 测试易伤状态
	var vulnerable_status = [
		{"type": multiplier_manager.StatusType.VULNERABLE, "magnitude": 0.25}  # 易伤25%
	]
	var vulnerable_mult = multiplier_manager.calculate_status_multiplier(vulnerable_status)
	
	# 测试破防状态
	var break_status = [
		{"type": multiplier_manager.StatusType.BREAK, "magnitude": 0.0}
	]
	var break_mult = multiplier_manager.calculate_status_multiplier(break_status)
	
	# 测试多种状态
	var multi_status = [
		{"type": multiplier_manager.StatusType.VULNERABLE, "magnitude": 0.20},  # 易伤20%
		{"type": multiplier_manager.StatusType.BREAK, "magnitude": 0.0}          # 破防
	]
	var multi_mult = multiplier_manager.calculate_status_multiplier(multi_status)
	
	# 验证结果
	var expected_vulnerable = 1.25  # 1 + 0.25
	var expected_break = 1.5         # 破防固定1.5倍
	var expected_multi = 1.2 * 1.5   # 易伤20% * 破防 = 1.8
	
	if abs(vulnerable_mult - expected_vulnerable) < 0.01 and abs(break_mult - expected_break) < 0.01 and abs(multi_mult - expected_multi) < 0.01:
		result.passed = true
		result.message = "状态修正正确: 易伤=%g倍, 破防=%g倍, 多种=%g倍" % [vulnerable_mult, break_mult, multi_mult]
	else:
		result.passed = false
		result.message = "状态修正错误: 期望%g, %g, %g, 实际%g, %g, %g" % [expected_vulnerable, expected_break, expected_multi, vulnerable_mult, break_mult, multi_mult]
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行伤害倍率与修正测试...")
	print("================================")
	
	for result in test_results:
		if result.passed:
			print("✅ %s: %s" % [result.test_name, result.message])
			passed_count += 1
		else:
			print("❌ %s: %s" % [result.test_name, result.message])
	
	print("================================")
	print("测试结果: %d/%d 项测试通过" % [passed_count, total_count])
	
	if passed_count == total_count:
		print("🎉 所有测试都通过了！")
	else:
		print("⚠️  有 %d 项测试失败" % [total_count - passed_count])
	
	return passed_count == total_count