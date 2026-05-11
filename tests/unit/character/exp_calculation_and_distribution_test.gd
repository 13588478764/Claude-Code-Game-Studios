# EXP计算与分配单元测试
# 验证基础经验值公式、等级缩放修正、队伍EXP分配和分段指数升级曲线

extends Node

# 导入需要测试的脚本
var ExpCalculationManager = load("res://src/scripts/character/exp_calculation_manager.gd")

# 测试结果统计
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("开始运行EXP计算与分配单元测试...")
	
	# 运行基础经验值公式测试
	test_base_exp_calculation()
	test_base_exp_with_different_scaling_factors()
	
	# 运行等级缩放修正公式测试
	test_level_scaling_positive_bonus()
	test_level_scaling_negative_penalty()
	test_level_scaling_extreme_difference()
	
	# 运行悟性修正测试
	test_wisdom_bonus_calculation()
	
	# 运行全局倍率测试
	test_global_multiplier()
	
	# 运行队伍EXP分配公式测试
	test_party_exp_distribution_active_only()
	test_party_exp_distribution_with_backup()
	test_party_exp_distribution_multiple_members()
	
	# 运行分段指数升级曲线测试
	test_level_curve_early_stage()
	test_level_curve_mid_stage()
	test_level_curve_late_stage()
	test_level_curve_progression()
	
	# 运行完整EXP计算流程测试
	test_full_exp_calculation()
	
	print("\n测试完成: %d/%d 个测试通过" % [tests_passed, tests_total])

# 测试基础经验值计算
func test_base_exp_calculation():
	var exp_manager = ExpCalculationManager.new()
	
	# 测试基础公式: Base_EXP = Enemy_Base_Value × (Enemy_Level / Player_Level)^Scaling_Factor
	# 敌人基础值50，等级10，玩家等级5，缩放因子1.2
	var base_exp = exp_manager.calculate_base_exp(50, 10, 5, 1.2)
	var expected = 50 * pow(10.0/5.0, 1.2)
	var expected_int = int(expected)
	
	assert(abs(base_exp - expected_int) <= 1, "基础经验值计算应符合公式: Base_EXP = Enemy_Base_Value × (Enemy_Level / Player_Level)^Scaling_Factor")
	
	print("✓ 基础经验值计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试不同缩放因子的基础经验值
func test_base_exp_with_different_scaling_factors():
	var exp_manager = ExpCalculationManager.new()
	
	# 测试不同缩放因子
	var factors = [1.0, 1.5, 2.0]
	var results = []
	
	for factor in factors:
		var base_exp = exp_manager.calculate_base_exp(50, 10, 5, factor)
		results.append(base_exp)
	
	# 验证随着缩放因子增加，结果也应增加
	assert(results[0] <= results[1] and results[1] <= results[2], "缩放因子越大，基础经验值应越高")
	
	print("✓ 不同缩放因子基础经验值测试通过")
	tests_passed += 1
	tests_total += 1

# 测试等级缩放正向奖励
func test_level_scaling_positive_bonus():
	var exp_manager = ExpCalculationManager.new()
	
	# 测试玩家等级5，敌人等级10（高等级敌人）
	var base_exp = 100.0
	var scaled_exp = exp_manager.apply_level_scaling(base_exp, 10, 5)
	
	# 预期：等级差5，每级5%加成，总共25%加成，但最高50%
	var expected_scaled = base_exp * 1.25
	assert(scaled_exp >= base_exp, "高等级敌人应获得EXP奖励")
	
	print("✓ 等级缩放正向奖励测试通过")
	tests_passed += 1
	tests_total += 1

# 测试等级缩放负向惩罚
func test_level_scaling_negative_penalty():
	var exp_manager = ExpCalculationManager.new()
	
	# 测试玩家等级10，敌人等级5（低等级敌人）
	var base_exp = 100.0
	var scaled_exp = exp_manager.apply_level_scaling(base_exp, 5, 10)
	
	# 预期：等级差5，每级10%惩罚，总共50%惩罚，但最低-80%
	var expected_scaled = base_exp * 0.5
	assert(scaled_exp < base_exp, "低等级敌人应受到EXP惩罚")
	
	print("✓ 等级缩放负向惩罚测试通过")
	tests_passed += 1
	tests_total += 1

# 测试等级差过大的情况
func test_level_scaling_extreme_difference():
	var exp_manager = ExpCalculationManager.new()
	
	# 测试玩家等级1，敌人等级15（等级差过大，>10级）
	var base_exp = 100.0
	var scaled_exp = exp_manager.apply_level_scaling(base_exp, 15, 1)
	
	# 预期：等级差超过10，EXP应为0
	assert(scaled_exp == 0.0, "等级差过大时EXP应为0")
	
	print("✓ 等级差过大测试通过")
	tests_passed += 1
	tests_total += 1

# 测试悟性修正计算
func test_wisdom_bonus_calculation():
	var exp_manager = ExpCalculationManager.new()
	
	# 测试悟性为50时的修正
	var base_exp = 100.0
	var wisdom = 50
	var modified_exp = exp_manager.apply_wisdom_bonus(base_exp, wisdom)
	
	# 每10点悟性+1%，50点悟性+5%
	var expected = base_exp * 1.05
	assert(abs(modified_exp - expected) < 0.1, "悟性修正应为每10点+1%")
	
	print("✓ 悟性修正计算测试通过")
	tests_passed += 1
	tests_total += 1

# 测试全局倍率
func test_global_multiplier():
	var exp_manager = ExpCalculationManager.new()
	
	# 测试双倍经验
	var base_exp = 100.0
	var multiplier = 2.0
	var modified_exp = exp_manager.apply_global_multiplier(base_exp, multiplier)
	
	var expected = base_exp * multiplier
	assert(modified_exp == expected, "全局倍率应正确应用")
	
	print("✓ 全局倍率测试通过")
	tests_passed += 1
	tests_total += 1

# 测试仅参战成员的EXP分配
func test_party_exp_distribution_active_only():
	var exp_manager = ExpCalculationManager.new()
	
	# 创建只有参战成员的队伍
	var party = [
		{"id": "player1", "is_active": true},
		{"id": "player2", "is_active": true}
	]
	
	var distribution = exp_manager.distribute_party_exp(100.0, party)
	
	# 两个参战成员平分100EXP，每人应得50EXP
	assert(distribution.size() == 2, "分配结果应包含所有队伍成员")
	assert(distribution["player1"] == 50.0 and distribution["player2"] == 50.0, "参战成员应平分EXP")
	
	print("✓ 仅参战成员EXP分配测试通过")
	tests_passed += 2
	tests_total += 2

# 测试包含后备成员的EXP分配
func test_party_exp_distribution_with_backup():
	var exp_manager = ExpCalculationManager.new()
	
	# 创建包含参战和后备成员的队伍
	var party = [
		{"id": "player1", "is_active": true},
		{"id": "player2", "is_active": true},
		{"id": "backup1", "is_active": false}
	]
	
	var distribution = exp_manager.distribute_party_exp(100.0, party)
	
	# 两个参战成员平分100EXP（每人50），后备成员获得50%份额（25）
	assert(distribution.size() == 3, "分配结果应包含所有队伍成员")
	assert(distribution["player1"] == 50.0 and distribution["player2"] == 50.0, "参战成员应平分EXP")
	assert(distribution["backup1"] == 25.0, "后备成员应获得参战成员50%的EXP")
	
	print("✓ 包含后备成员EXP分配测试通过")
	tests_passed += 3
	tests_total += 3

# 测试多个成员的EXP分配
func test_party_exp_distribution_multiple_members():
	var exp_manager = ExpCalculationManager.new()
	
	# 创建多个参战和后备成员的队伍
	var party = [
		{"id": "player1", "is_active": true},
		{"id": "player2", "is_active": true},
		{"id": "player3", "is_active": true},
		{"id": "backup1", "is_active": false},
		{"id": "backup2", "is_active": false}
	]
	
	var total_exp = 150.0
	var distribution = exp_manager.distribute_party_exp(total_exp, party)
	
	# 三个参战成员平分150EXP（每人50），两个后备成员各获得25EXP（参战的50%）
	assert(distribution.size() == 5, "分配结果应包含所有队伍成员")
	assert(distribution["player1"] == 50.0 and distribution["player2"] == 50.0 and distribution["player3"] == 50.0, "参战成员应平分EXP")
	assert(distribution["backup1"] == 25.0 and distribution["backup2"] == 25.0, "后备成员应获得参战成员50%的EXP")
	
	print("✓ 多个成员EXP分配测试通过")
	tests_passed += 5
	tests_total += 5

# 测试初期等级曲线
func test_level_curve_early_stage():
	var exp_manager = ExpCalculationManager.new()
	
	# 测试1-10级（初期线性）
	var exp_for_level_5 = exp_manager.calculate_level_curve(5, 100, exp_manager.EXP_CURVE_EARLY)
	var expected = int(100 * pow(5, 1.0))  # 100 * 5 = 500
	
	assert(exp_for_level_5 == expected, "初期等级曲线应为线性增长")
	
	print("✓ 初期等级曲线测试通过")
	tests_passed += 1
	tests_total += 1

# 测试中期等级曲线
func test_level_curve_mid_stage():
	var exp_manager = ExpCalculationManager.new()
	
	# 测试15级（中期温和指数）
	var exp_for_level_15 = exp_manager.calculate_level_curve(15, 150, exp_manager.EXP_CURVE_MID)
	var expected = int(150 * pow(15, 1.5))
	
	assert(exp_for_level_15 == expected, "中期等级曲线应为温和指数增长")
	
	print("✓ 中期等级曲线测试通过")
	tests_passed += 1
	tests_total += 1

# 测试后期等级曲线
func test_level_curve_late_stage():
	var exp_manager = ExpCalculationManager.new()
	
	# 测试35级（后期陡峭指数）
	var exp_for_level_35 = exp_manager.calculate_level_curve(35, 200, exp_manager.EXP_CURVE_LATE)
	var expected = int(200 * pow(35, 2.5))
	
	assert(exp_for_level_35 == expected, "后期等级曲线应为陡峭指数增长")
	
	print("✓ 后期等级曲线测试通过")
	tests_passed += 1
	tests_total += 1

# 测试等级曲线的阶段性
func test_level_curve_progression():
	var exp_manager = ExpCalculationManager.new()
	
	# 测试不同阶段的等级曲线系数
	var early_coeff = exp_manager.get_exponent_coefficient_for_level(5)   # 应为EXP_CURVE_EARLY
	var mid_coeff = exp_manager.get_exponent_coefficient_for_level(15)    # 应为EXP_CURVE_MID
	var late_coeff = exp_manager.get_exponent_coefficient_for_level(35)  # 应为EXP_CURVE_LATE
	
	assert(early_coeff == exp_manager.EXP_CURVE_EARLY, "1-10级应使用初期系数")
	assert(mid_coeff == exp_manager.EXP_CURVE_MID, "11-30级应使用中期系数")
	assert(late_coeff == exp_manager.EXP_CURVE_LATE, "31级以上应使用后期系数")
	
	print("✓ 等级曲线阶段性测试通过")
	tests_passed += 3
	tests_total += 3

# 测试完整EXP计算流程
func test_full_exp_calculation():
	var exp_manager = ExpCalculationManager.new()
	
	# 创建测试数据
	var enemy_data = {
		"base_value": 100,
		"level": 10,
		"scaling_factor": 1.5
	}
	var player_level = 8
	var wisdom_attribute = 60
	var party_members = [
		{"id": "player1", "is_active": true},
		{"id": "player2", "is_active": false}
	]
	var global_multiplier = 1.5  # 1.5倍经验
	
	# 执行完整计算
	var result = exp_manager.calculate_full_exp(enemy_data, player_level, wisdom_attribute, party_members, global_multiplier)
	
	# 验证结果包含所有必要字段
	assert(result.has("base_exp"), "结果应包含基础EXP")
	assert(result.has("level_scaled_exp"), "结果应包含等级缩放EXP")
	assert(result.has("wisdom_scaled_exp"), "结果应包含悟性缩放EXP")
	assert(result.has("final_exp"), "结果应包含最终EXP")
	assert(result.has("party_distribution"), "结果应包含队伍分配")
	
	# 验证最终EXP大于0
	assert(result.final_exp > 0, "最终EXP应大于0")
	
	# 验证队伍分配包含所有成员
	assert(result.party_distribution.size() == 2, "队伍分配应包含所有成员")
	
	print("✓ 完整EXP计算流程测试通过")
	tests_passed += 6
	tests_total += 6
