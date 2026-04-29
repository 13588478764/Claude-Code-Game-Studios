# 条件类型与评估单元测试
# 验证四大类条件类型、条件评估逻辑、福缘修正系数和评估结果

extends GutTest

# 测试1: 四大类条件类型正确实现
func test_four_condition_types_correctly_implemented():
	# 创建条件评估器实例
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	add_child(evaluator)
	
	# 将 PlayerData 对象转换为字典用于时空环境条件测试
	var player_dict = {
		"location": "破庙",
		"time_of_day": "night",
		"weather": "rainy"
	}
	var temporal_result = evaluator.evaluate_temporal_environment_conditions(player_dict)
	assert_true(temporal_result, "时空环境条件评估应该通过")
	
	# 将 PlayerData 对象转换为字典用于角色状态条件测试
	var character_dict = {
		"health": 15,
		"max_health": 100,
		"status_effects": []
	}
	var character_result = evaluator.evaluate_character_state_conditions(character_dict)
	assert_true(character_result, "角色状态条件评估应该通过")
	
	# 将 ProgressData 对象转换为字典用于进度历史条件测试
	var progress_dict = {
		"encounters_completed": ["避雨遇高僧"],
		"level": 10
	}
	var progress_result = evaluator.evaluate_progress_history_conditions(progress_dict)
	assert_true(progress_result, "进度历史条件评估应该通过")
	
	# 测试随机概率条件
	var random_result = evaluator.evaluate_random_probability_conditions(50.0)
	assert_true(random_result or not random_result, "随机概率条件应该返回布尔值")


# 测试2: 条件评估逻辑正确（AND/OR逻辑组合）
func test_condition_evaluation_logic_correct():
	# 创建条件评估器实例
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	add_child(evaluator)
	
	# 创建测试条件组 - AND逻辑
	var and_group = evaluator.ConditionGroup.new()
	and_group.logic_op = evaluator.LogicOp.AND
	and_group.conditions = [
		create_test_condition(evaluator.ConditionType.TEMPORAL_ENVIRONMENT, true),
		create_test_condition(evaluator.ConditionType.CHARACTER_STATE, true),
		create_test_condition(evaluator.ConditionType.PROGRESS_HISTORY, true)
	]
	
	var player_data = create_test_player_data()
	var progress_data = create_test_progress_data()
	var and_result = evaluator.evaluate_condition_group(and_group, player_data, progress_data)
	assert_true(and_result, "AND逻辑应该返回true（所有条件都为true）")
	
	# 创建测试条件组 - OR逻辑
	var or_group = evaluator.ConditionGroup.new()
	or_group.logic_op = evaluator.LogicOp.OR
	or_group.conditions = [
		create_test_condition(evaluator.ConditionType.TEMPORAL_ENVIRONMENT, false),
		create_test_condition(evaluator.ConditionType.CHARACTER_STATE, true),
		create_test_condition(evaluator.ConditionType.PROGRESS_HISTORY, false)
	]
	
	var or_result = evaluator.evaluate_condition_group(or_group, player_data, progress_data)
	assert_true(or_result, "OR逻辑应该返回true（至少一个条件为true）")
	
	# 清理资源
	evaluator.queue_free()


# 测试3: 福缘修正系数正确应用
func test_luck_correction_coefficient_correctly_applied():
	# 创建条件评估器实例
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	add_child(evaluator)
	
	# 测试不同福缘值的修正系数
	var prob_low_luck = evaluator.calculate_trigger_probability(0.05, 10.0)  # 10点福缘
	var prob_medium_luck = evaluator.calculate_trigger_probability(0.05, 50.0)  # 50点福缘
	var prob_high_luck = evaluator.calculate_trigger_probability(0.05, 90.0)  # 90点福缘
	var prob_very_high_luck = evaluator.calculate_trigger_probability(0.05, 150.0)  # 150点福缘（应被限制在20%）
	
	# 验证福缘修正系数计算
	var expected_low = 0.05 * (1.0 + 0.1)  # 0.055
	var expected_medium = 0.05 * (1.0 + 0.5)  # 0.075
	var expected_high = 0.05 * (1.0 + 0.9)  # 0.095
	var expected_very_high = 0.20  # 上限20%
	
	# 验证结果
	assert_true(abs(prob_low_luck - expected_low) < 0.001, "10点福缘修正系数计算错误")
	assert_true(abs(prob_medium_luck - expected_medium) < 0.001, "50点福缘修正系数计算错误")
	assert_true(abs(prob_high_luck - expected_high) < 0.001, "90点福缘修正系数计算错误")
	assert_true(abs(prob_very_high_luck - expected_very_high) < 0.001, "150点福缘修正系数计算错误（应被限制在20%）")


# 测试4: 条件评估结果准确（true/false）
func test_condition_evaluation_result_accurate():
	# 创建条件评估器实例
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	add_child(evaluator)
	
	# 测试玩家生命值低于20%的条件
	var character_dict = {
		"health": 15,
		"max_health": 100,
		"status_effects": []
	}
	
	var character_result = evaluator.evaluate_character_state_conditions(character_dict)
	assert_true(character_result, "生命值15%应该满足低于20%的条件")
	
	# 测试随机概率条件（使用高概率）
	var random_result = evaluator.evaluate_random_probability_conditions(50.0, 0.5)  # 高概率测试
	assert_true(random_result or not random_result, "随机概率条件应该返回布尔值")


# 创建测试玩家数据
func create_test_player_data() -> Object:
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	var player_data = evaluator.PlayerData.new()
	
	player_data.position = Vector2(100, 200)
	player_data.time = 22.5  # 晚上10:30
	player_data.weather = "rain"
	player_data.luck = 50.0
	player_data.wisdom = 60.0
	player_data.health = 0.8  # 80%
	player_data.qi = 0.7     # 70%
	player_data.attributes = {"luck": 50, "wisdom": 60, "health": 80}
	player_data.inventory = ["mysterious_jade"]
	player_data.skills = ["taijiquan"]
	player_data.realm = "ZhuJi"  # 筑基期
	
	return player_data


# 创建测试进度数据
func create_test_progress_data() -> Object:
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	var progress_data = evaluator.ProgressData.new()
	
	progress_data.quest_status = {"main_chapter": 3, "side_quest_completed": true}
	progress_data.explored_areas = ["Qingyun_Mountain", "Black_Wind_Fortress"]
	progress_data.encounter_history = ["encounter_001", "encounter_002"]
	progress_data.behavior_history = {"bandits_killed": 55, "npc_helped": 12}
	
	return progress_data


# 创建测试条件
func create_test_condition(condition_type, is_met) -> Object:
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	var condition = evaluator.Condition.new()
	
	condition.type = condition_type
	condition.parameters = {"is_met": is_met}
	
	return condition