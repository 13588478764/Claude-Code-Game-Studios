## level_coefficient_test.gd
## 三段式等级缩放曲线单元测试
##
## 测试 TR-enemy-scaling-001 的所有验收标准

extends GutTest

const LevelCoefficient = preload("res://scripts/enemy_scaling/level_coefficient.gd")

## AC-1: 等级1敌人数值验证
## GIVEN 玩家等级为1, WHEN 遭遇新手区普通敌人, THEN 敌人HP应在100-200范围内,攻击力应在15-30范围内
func test_level_1_enemy_stats_in_valid_range():
	# Given: 玩家等级=1, 敌人基础HP=100, 基础攻击=20, 新手区倍率=0.8, 普通敌人
	var player_level = 1
	var base_hp = 100
	var base_attack = 20
	var region_multiplier = 0.8  # 新手区
	var enemy_type_hp_multiplier = 1.0  # 普通敌人
	var enemy_type_attack_multiplier = 1.0  # 普通敌人
	
	# When: 调用 calculate_level_coefficient(1)
	var level_coefficient = LevelCoefficient.calculate_level_coefficient(player_level)
	
	# Then: 等级系数=1.0
	assert_almost_eq(level_coefficient, 1.0, 0.01, "Level 1 coefficient should be 1.0")
	
	# 计算最终属性 (简化版,只考虑等级系数和区域倍率)
	var final_hp = base_hp * level_coefficient * region_multiplier * enemy_type_hp_multiplier
	var final_attack = base_attack * level_coefficient * region_multiplier * enemy_type_attack_multiplier
	
	# Then: 最终HP在100-200范围, 最终攻击在15-30范围
	assert_true(final_hp >= 100 and final_hp <= 200, 
		"Final HP should be in range 100-200, got %f" % final_hp)
	assert_true(final_attack >= 15 and final_attack <= 30, 
		"Final attack should be in range 15-30, got %f" % final_attack)

## AC-1 边缘情况: 等级0(无效)
func test_level_0_clamped_to_1():
	# Given: 无效等级0
	var invalid_level = 0
	
	# When: 调用 calculate_level_coefficient(0)
	var coefficient = LevelCoefficient.calculate_level_coefficient(invalid_level)
	
	# Then: 应该被限制为等级1的系数
	assert_almost_eq(coefficient, 1.0, 0.01, "Level 0 should be clamped to level 1 coefficient")

## AC-1 边缘情况: 等级100(超出范围)
func test_level_100_clamped_to_99():
	# Given: 超出范围的等级100
	var invalid_level = 100
	
	# When: 调用 calculate_level_coefficient(100)
	var coefficient = LevelCoefficient.calculate_level_coefficient(invalid_level)
	
	# Then: 应该被限制为等级99的系数
	var expected_lv99 = 13.5 * pow(99.0 / 67.0, 2.0)
	assert_almost_eq(coefficient, expected_lv99, 0.01, "Level 100 should be clamped to level 99 coefficient")

## AC-4: Lv 33-34衔接点验证
## GIVEN 玩家在Lv 33和Lv 34之间升级, WHEN 计算等级系数, THEN 两个等级的系数应相等(5.8)
func test_level_33_34_junction_point():
	# Given: 玩家等级=33和34
	var level_33 = 33
	var level_34 = 34
	
	# When: 分别调用 calculate_level_coefficient(33) 和 calculate_level_coefficient(34)
	var coefficient_33 = LevelCoefficient.calculate_level_coefficient(level_33)
	var coefficient_34 = LevelCoefficient.calculate_level_coefficient(level_34)
	
	# Then: 两个返回值都应等于5.8(允许±0.01误差)
	assert_almost_eq(coefficient_33, 5.8, 0.01, "Level 33 coefficient should be 5.8")
	assert_almost_eq(coefficient_34, 5.8, 0.01, "Level 34 coefficient should be 5.8")
	
	# 验证曲线平滑衔接
	assert_almost_eq(coefficient_33, coefficient_34, 0.01, 
		"Level 33 and 34 coefficients should be equal for smooth transition")

## AC-4 边缘情况: Lv 32验证
func test_level_32_near_junction():
	# Given: 等级32(衔接点附近)
	var level = 32
	
	# When: 调用 calculate_level_coefficient(32)
	var coefficient = LevelCoefficient.calculate_level_coefficient(level)
	
	# Then: 应该使用线性公式
	var expected = 1.0 + (32 - 1) * 0.15
	assert_almost_eq(coefficient, expected, 0.01, "Level 32 should use linear formula")

## AC-4 边缘情况: Lv 35验证
func test_level_35_near_junction():
	# Given: 等级35(衔接点附近)
	var level = 35
	
	# When: 调用 calculate_level_coefficient(35)
	var coefficient = LevelCoefficient.calculate_level_coefficient(level)
	
	# Then: 应该使用温和指数公式
	var expected = 5.8 * pow(35.0 / 34.0, 1.5)
	assert_almost_eq(coefficient, expected, 0.01, "Level 35 should use mild exponential formula")

## AC-5: Lv 66-67衔接点验证
## GIVEN 玩家在Lv 66和Lv 67之间升级, WHEN 计算等级系数, THEN 两个等级的系数应相等(13.5)
func test_level_66_67_junction_point():
	# Given: 玩家等级=66和67
	var level_66 = 66
	var level_67 = 67
	
	# When: 分别调用 calculate_level_coefficient(66) 和 calculate_level_coefficient(67)
	var coefficient_66 = LevelCoefficient.calculate_level_coefficient(level_66)
	var coefficient_67 = LevelCoefficient.calculate_level_coefficient(level_67)
	
	# Then: 两个返回值都应等于13.5(允许±0.01误差)
	assert_almost_eq(coefficient_66, 13.5, 0.01, "Level 66 coefficient should be 13.5")
	assert_almost_eq(coefficient_67, 13.5, 0.01, "Level 67 coefficient should be 13.5")
	
	# 验证曲线平滑衔接
	assert_almost_eq(coefficient_66, coefficient_67, 0.01, 
		"Level 66 and 67 coefficients should be equal for smooth transition")

## AC-5 边缘情况: Lv 65验证
func test_level_65_near_junction():
	# Given: 等级65(衔接点附近)
	var level = 65
	
	# When: 调用 calculate_level_coefficient(65)
	var coefficient = LevelCoefficient.calculate_level_coefficient(level)
	
	# Then: 应该使用温和指数公式
	var expected = 5.8 * pow(65.0 / 34.0, 1.5)
	assert_almost_eq(coefficient, expected, 0.01, "Level 65 should use mild exponential formula")

## AC-5 边缘情况: Lv 68验证
func test_level_68_near_junction():
	# Given: 等级68(衔接点附近)
	var level = 68
	
	# When: 调用 calculate_level_coefficient(68)
	var coefficient = LevelCoefficient.calculate_level_coefficient(level)
	
	# Then: 应该使用陡峭指数公式
	var expected = 13.5 * pow(68.0 / 67.0, 2.0)
	assert_almost_eq(coefficient, expected, 0.01, "Level 68 should use steep exponential formula")

## 额外测试: 验证关键节点值
func test_key_node_values():
	# 验证GDD中定义的关键节点值
	assert_almost_eq(LevelCoefficient.calculate_level_coefficient(1), 1.0, 0.01, "Lv 1 = 1.0")
	assert_almost_eq(LevelCoefficient.calculate_level_coefficient(33), 5.8, 0.01, "Lv 33 = 5.8")
	assert_almost_eq(LevelCoefficient.calculate_level_coefficient(34), 5.8, 0.01, "Lv 34 = 5.8")
	assert_almost_eq(LevelCoefficient.calculate_level_coefficient(66), 13.5, 0.01, "Lv 66 = 13.5")
	assert_almost_eq(LevelCoefficient.calculate_level_coefficient(67), 13.5, 0.01, "Lv 67 = 13.5")
	assert_almost_eq(LevelCoefficient.calculate_level_coefficient(99), 29.8, 0.1, "Lv 99 ≈ 29.8")

## 额外测试: 验证曲线单调递增
func test_curve_is_monotonically_increasing():
	# 验证曲线在整个范围内单调递增
	var prev_coefficient = 0.0
	for level in range(1, 100):
		var coefficient = LevelCoefficient.calculate_level_coefficient(level)
		assert_true(coefficient >= prev_coefficient, 
			"Coefficient should be monotonically increasing at level %d" % level)
		prev_coefficient = coefficient