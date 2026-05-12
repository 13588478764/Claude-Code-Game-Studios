## edge_cases_test.gd
## 边缘情况处理单元测试
##
## 测试 TR-enemy-scaling-006

extends GutTest

const EdgeCaseHandler = preload("res://src/scripts/enemy_scaling/edge_cases.gd")

## AC-8: 等级过高保护
func test_level_too_high_protection():
	# Given: 玩家Lv60, 区域推荐20-40
	var player_level = 60
	var region_min = 20
	var region_max = 40
	var original_multiplier = 1.3
	
	# When: 检查等级差距
	var result = EdgeCaseHandler.check_level_difference(
		player_level, region_min, region_max, original_multiplier
	)
	
	# Then: 区域倍率降至0.5x, 警告类型为TOO_EASY
	assert_almost_eq(result["adjusted_multiplier"], 0.5, 0.01)
	assert_eq(result["warning_type"], EdgeCaseHandler.WarningType.TOO_EASY)

## AC-9: 等级过低保护
func test_level_too_low_protection():
	# Given: 玩家Lv10, 区域推荐60-80
	var player_level = 10
	var region_min = 60
	var region_max = 80
	var original_multiplier = 2.0
	
	# When: 检查等级差距
	var result = EdgeCaseHandler.check_level_difference(
		player_level, region_min, region_max, original_multiplier
	)
	
	# Then: 警告类型为TOO_HARD
	assert_eq(result["warning_type"], EdgeCaseHandler.WarningType.TOO_HARD)

## AC-10: 战斗中升级
func test_level_up_during_battle():
	# Given: 战斗中从Lv49升到Lv50
	var is_battle_active = true
	var level_before = 49
	var level_after = 50
	
	# When: 检查是否应该更新敌人属性
	var should_update = EdgeCaseHandler.should_update_enemy_stats_on_level_up(
		is_battle_active, level_before, level_after
	)
	
	# Then: 不应该更新敌人属性
	assert_false(should_update)

## AC-10: 战斗外升级
func test_level_up_outside_battle():
	# Given: 战斗外升级
	var is_battle_active = false
	var level_before = 49
	var level_after = 50
	
	# When: 检查是否应该更新敌人属性
	var should_update = EdgeCaseHandler.should_update_enemy_stats_on_level_up(
		is_battle_active, level_before, level_after
	)
	
	# Then: 应该更新敌人属性
	assert_true(should_update)

## AC-13: 基础HP异常处理
func test_invalid_base_hp():
	# Given: 敌人基础HP=0
	var base_hp = 0.0
	
	# When: 验证基础HP
	var result = EdgeCaseHandler.validate_base_hp(base_hp)
	
	# Then: 使用默认值100, 标记为错误
	assert_eq(result["validated_hp"], 100)
	assert_true(result["has_error"])

## AC-13: 基础攻击异常处理
func test_invalid_base_attack():
	# Given: 敌人基础攻击=-5
	var base_attack = -5.0
	
	# When: 验证基础攻击
	var result = EdgeCaseHandler.validate_base_attack(base_attack)
	
	# Then: 使用默认值20, 标记为错误
	assert_eq(result["validated_attack"], 20)
	assert_true(result["has_error"])

## AC-14: 区域倍率异常处理
func test_invalid_region_multiplier():
	# Given: 区域难度数据缺失(倍率=0)
	var region_multiplier = 0.0
	
	# When: 验证区域倍率
	var result = EdgeCaseHandler.validate_region_multiplier(region_multiplier)
	
	# Then: 使用默认值1.0, 标记为错误
	assert_almost_eq(result["validated_multiplier"], 1.0, 0.01)
	assert_true(result["has_error"])

## 验证警告信息
func test_warning_messages():
	var too_easy_msg = EdgeCaseHandler.get_warning_message(EdgeCaseHandler.WarningType.TOO_EASY)
	assert_true("过于简单" in too_easy_msg)
	
	var too_hard_msg = EdgeCaseHandler.get_warning_message(EdgeCaseHandler.WarningType.TOO_HARD)
	assert_true("过于困难" in too_hard_msg)
	
	var data_error_msg = EdgeCaseHandler.get_warning_message(EdgeCaseHandler.WarningType.DATA_ERROR)
	assert_true("数据异常" in data_error_msg)

## 综合验证所有敌人数据
func test_validate_all_enemy_data():
	# Given: 所有数据都无效
	var base_hp = 0.0
	var base_attack = -5.0
	var region_multiplier = 0.0
	
	# When: 综合验证
	var result = EdgeCaseHandler.validate_all_enemy_data(
		base_hp, base_attack, region_multiplier
	)
	
	# Then: 所有值都使用默认值, 标记为错误
	assert_eq(result["validated_hp"], 100)
	assert_eq(result["validated_attack"], 20)
	assert_almost_eq(result["validated_multiplier"], 1.0, 0.01)
	assert_true(result["has_error"])
	assert_eq(result["warning_type"], EdgeCaseHandler.WarningType.DATA_ERROR)

## 获取推荐等级范围
func test_get_region_recommended_level_range():
	var beginner_range = EdgeCaseHandler.get_region_recommended_level_range(0)
	assert_eq(beginner_range["min_level"], 1)
	assert_eq(beginner_range["max_level"], 20)
	
	var final_range = EdgeCaseHandler.get_region_recommended_level_range(4)
	assert_eq(final_range["min_level"], 60)
	assert_eq(final_range["max_level"], 99)

## 边界情况: 等级差距恰好在阈值
func test_level_difference_at_threshold():
	# 玩家等级恰好超过阈值20级
	var player_level = 61  # 40 + 20 + 1
	var region_min = 20
	var region_max = 40
	var original_multiplier = 1.3
	
	var result = EdgeCaseHandler.check_level_difference(
		player_level, region_min, region_max, original_multiplier
	)
	
	# 应该触发TOO_EASY
	assert_eq(result["warning_type"], EdgeCaseHandler.WarningType.TOO_EASY)

## 边界情况: 等级差距未达到阈值
func test_level_difference_below_threshold():
	# 玩家等级在阈值内
	# 修正：原测试用 player_level=60, region_max=40，差额 = 20，
	# 与 test_level_too_high_protection（同样差额 20，期望触发 TOO_EASY）矛盾。
	# 阈值边界采用 >= 触发（差额 = 阈值 → 触发保护），所以"在阈值内"
	# 应该是差额 < 阈值，即 player_level < 60。改为 59（差 = 19）。
	var player_level = 59  # 差额 = 59 - 40 = 19，严格小于阈值 20
	var region_min = 20
	var region_max = 40
	var original_multiplier = 1.3
	
	var result = EdgeCaseHandler.check_level_difference(
		player_level, region_min, region_max, original_multiplier
	)
	
	# 不应该触发警告
	assert_eq(result["warning_type"], EdgeCaseHandler.WarningType.NONE)
	assert_almost_eq(result["adjusted_multiplier"], original_multiplier, 0.01)

## 有效数据验证
func test_validate_valid_data():
	var base_hp = 100.0
	var base_attack = 20.0
	var region_multiplier = 1.3
	
	var result = EdgeCaseHandler.validate_all_enemy_data(
		base_hp, base_attack, region_multiplier
	)
	
	assert_eq(result["validated_hp"], 100.0)
	assert_eq(result["validated_attack"], 20.0)
	assert_almost_eq(result["validated_multiplier"], 1.3, 0.01)
	assert_false(result["has_error"])
	assert_eq(result["warning_type"], EdgeCaseHandler.WarningType.NONE)

## 部分数据异常
func test_validate_partial_invalid_data():
	var base_hp = 100.0
	var base_attack = -5.0  # 无效
	var region_multiplier = 1.3
	
	var result = EdgeCaseHandler.validate_all_enemy_data(
		base_hp, base_attack, region_multiplier
	)
	
	assert_eq(result["validated_hp"], 100.0)
	assert_eq(result["validated_attack"], 20)  # 使用默认值
	assert_almost_eq(result["validated_multiplier"], 1.3, 0.01)
	assert_true(result["has_error"])
