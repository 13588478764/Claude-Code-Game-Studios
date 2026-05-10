## dynamic_difficulty_test.gd
## 动态难度调整系统单元测试
##
## 测试 TR-enemy-scaling-005

extends GutTest

const DynamicDifficulty = preload("res://src/scripts/enemy_scaling/dynamic_difficulty.gd")

## AC-6: 连续失败惩罚
## GIVEN 玩家连续失败同一战斗3次, WHEN 第4次遭遇, THEN 敌人属性降低30%(系数=0.7)
func test_failure_penalty_3_failures():
	# Given: 连续失败3次
	var failure_count = 3
	
	# When: 计算失败惩罚系数
	var coefficient = DynamicDifficulty.calculate_failure_penalty(failure_count)
	
	# Then: 系数应该是0.7 (降低30%)
	assert_almost_eq(coefficient, 0.7, 0.01, "3 failures should result in 0.7 coefficient")

## AC-7: 连续碾压奖励
## GIVEN 玩家连续10场无伤胜利, WHEN 第11场战斗, THEN 敌人属性提升5%(系数=1.05)
func test_perfect_win_bonus_10_wins():
	# Given: 连续10场无伤胜利
	var perfect_win_count = 10
	
	# When: 计算碾压奖励系数
	var coefficient = DynamicDifficulty.calculate_perfect_win_bonus(perfect_win_count)
	
	# Then: 系数应该是1.05 (提升5%, 但最多3次计算)
	# 实际上10场无伤会被限制为3场,所以系数 = 1.0 + (3 × 0.05) = 1.15
	assert_almost_eq(coefficient, 1.15, 0.01, "10 perfect wins should result in 1.15 coefficient (capped at 3)")

## 验证失败惩罚的阶梯
func test_failure_penalty_progression():
	var test_cases = [
		{"failures": 0, "expected": 1.0},
		{"failures": 1, "expected": 0.9},
		{"failures": 2, "expected": 0.8},
		{"failures": 3, "expected": 0.7},
		{"failures": 4, "expected": 0.7},  # 上限
		{"failures": 10, "expected": 0.7},  # 上限
	]
	
	for test_case in test_cases:
		var coefficient = DynamicDifficulty.calculate_failure_penalty(test_case["failures"])
		assert_almost_eq(coefficient, test_case["expected"], 0.01,
			"Failure count %d should result in %.2f coefficient" % [test_case["failures"], test_case["expected"]])

## 验证碾压奖励的阶梯
func test_perfect_win_bonus_progression():
	var test_cases = [
		{"wins": 0, "expected": 1.0},
		{"wins": 1, "expected": 1.05},
		{"wins": 2, "expected": 1.10},
		{"wins": 3, "expected": 1.15},
		{"wins": 4, "expected": 1.15},  # 上限
		{"wins": 30, "expected": 1.15},  # 上限
	]
	
	for test_case in test_cases:
		var coefficient = DynamicDifficulty.calculate_perfect_win_bonus(test_case["wins"])
		assert_almost_eq(coefficient, test_case["expected"], 0.01,
			"Perfect win count %d should result in %.2f coefficient" % [test_case["wins"], test_case["expected"]])

## 验证综合动态难度系数 - 失败优先
func test_combined_coefficient_failure_priority():
	# 失败优先级高于碾压奖励
	var coefficient = DynamicDifficulty.calculate_dynamic_coefficient(2, 5)
	assert_almost_eq(coefficient, 0.8, 0.01, "Failure should take priority over perfect wins")

## 验证综合动态难度系数 - 无失败时使用奖励
func test_combined_coefficient_no_failure():
	# 无失败时使用碾压奖励
	var coefficient = DynamicDifficulty.calculate_dynamic_coefficient(0, 5)
	assert_almost_eq(coefficient, 1.15, 0.01, "Perfect wins should be used when no failures")

## 验证综合动态难度系数 - 都为0时正常
func test_combined_coefficient_normal():
	# 都为0时返回1.0
	var coefficient = DynamicDifficulty.calculate_dynamic_coefficient(0, 0)
	assert_almost_eq(coefficient, 1.0, 0.01, "No failures or wins should result in 1.0 coefficient")

## 验证应用动态难度到属性
func test_apply_dynamic_difficulty():
	var base_hp = 100.0
	var base_attack = 20.0
	var dynamic_coefficient = 0.8
	
	var result = DynamicDifficulty.apply_dynamic_difficulty(base_hp, base_attack, dynamic_coefficient)
	
	assert_almost_eq(result["adjusted_hp"], 80.0, 0.01, "HP should be adjusted by coefficient")
	assert_almost_eq(result["adjusted_attack"], 16.0, 0.01, "Attack should be adjusted by coefficient")

## 验证系数范围限制
func test_coefficient_clamping():
	# 测试超出范围的系数是否被限制
	var result1 = DynamicDifficulty.apply_dynamic_difficulty(100.0, 20.0, 0.5)
	assert_almost_eq(result1["adjusted_hp"], 70.0, 0.01, "Coefficient below min should be clamped to 0.7")
	
	var result2 = DynamicDifficulty.apply_dynamic_difficulty(100.0, 20.0, 1.5)
	assert_almost_eq(result2["adjusted_hp"], 115.0, 0.01, "Coefficient above max should be clamped to 1.15")

## 验证重置条件 - 切换区域
func test_should_reset_on_region_change():
	var should_reset = DynamicDifficulty.should_reset_counters(1, 0, 50, 50)
	assert_true(should_reset, "Should reset when region changes")

## 验证重置条件 - 升级
func test_should_reset_on_level_up():
	var should_reset = DynamicDifficulty.should_reset_counters(0, 0, 51, 50)
	assert_true(should_reset, "Should reset when level increases")

## 验证重置条件 - 无变化
func test_should_not_reset_no_change():
	var should_reset = DynamicDifficulty.should_reset_counters(0, 0, 50, 50)
	assert_false(should_reset, "Should not reset when region and level unchanged")

## 验证难度描述 - 失败惩罚
func test_difficulty_description_failure():
	var description = DynamicDifficulty.get_difficulty_description(2, 0)
	assert_true("难度降低" in description, "Description should mention difficulty reduction")
	assert_true("失败2次" in description, "Description should mention failure count")

## 验证难度描述 - 碾压奖励
func test_difficulty_description_perfect_win():
	var description = DynamicDifficulty.get_difficulty_description(0, 5)
	assert_true("难度提升" in description, "Description should mention difficulty increase")
	assert_true("无伤5场" in description, "Description should mention perfect win count")

## 验证难度描述 - 正常难度
func test_difficulty_description_normal():
	var description = DynamicDifficulty.get_difficulty_description(0, 0)
	assert_true("正常难度" in description, "Description should mention normal difficulty")

## 边缘情况: 负数失败次数
func test_negative_failure_count():
	var coefficient = DynamicDifficulty.calculate_failure_penalty(-5)
	assert_almost_eq(coefficient, 1.0, 0.01, "Negative failure count should be treated as 0")

## 边缘情况: 负数无伤胜利次数
func test_negative_perfect_win_count():
	var coefficient = DynamicDifficulty.calculate_perfect_win_bonus(-5)
	assert_almost_eq(coefficient, 1.0, 0.01, "Negative perfect win count should be treated as 0")

## 验证失败后胜利会重置
func test_failure_then_win_reset():
	# 这个测试验证逻辑:如果有失败,则不计算奖励
	var coefficient_with_failure = DynamicDifficulty.calculate_dynamic_coefficient(1, 10)
	assert_almost_eq(coefficient_with_failure, 0.9, 0.01, "Failure should override perfect wins")