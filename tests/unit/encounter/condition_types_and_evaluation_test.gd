# 条件类型与评估单元测试
# 验证四大类条件类型、条件评估逻辑、福缘修正系数和评估结果

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_four_condition_types_correctly_implemented())
	results.append(test_condition_evaluation_logic_correct())
	results.append(test_luck_correction_coefficient_correctly_applied())
	results.append(test_condition_evaluation_result_accurate())
	
	return results

# 测试1: 四大类条件类型正确实现
func test_four_condition_types_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "四大类条件类型正确实现"
	
	# 创建条件评估器实例
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	
	# 测试时空环境条件
	var temporal_result = evaluator.evaluate_temporal_environment_conditions(create_test_player_data())
	
	# 测试角色状态条件
	var character_result = evaluator.evaluate_character_state_conditions(create_test_player_data())
	
	# 测试进度历史条件
	var progress_result = evaluator.evaluate_progress_history_conditions(create_test_progress_data())
	
	# 测试随机概率条件
	var random_result = evaluator.evaluate_random_probability_conditions(50.0)
	
	# 验证结果
	if temporal_result and character_result and progress_result and random_result:
		result.passed = true
		result.message = "四大类条件类型评估通过"
	else:
		result.passed = false
		result.message = "四大类条件类型评估失败 - 时空环境:%s, 角色状态:%s, 进度历史:%s, 随机概率:%s" % [
			"通过" if temporal_result else "失败",
			"通过" if character_result else "失败",
			"通过" if progress_result else "失败",
			"通过" if random_result else "失败"
		]
	
	return result

# 测试2: 条件评估逻辑正确（AND/OR逻辑组合）
func test_condition_evaluation_logic_correct() -> TestResult:
	var result = TestResult.new()
	result.test_name = "条件评估逻辑正确（AND/OR逻辑组合）"
	
	# 创建条件评估器实例
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	
	# 创建测试条件组 - AND逻辑
	var and_group = evaluator.ConditionGroup.new()
	and_group.logic_op = evaluator.LogicOp.AND
	and_group.conditions = [
		create_test_condition(evaluator.ConditionType.TEMPORAL_ENVIRONMENT, true),
		create_test_condition(evaluator.ConditionType.CHARACTER_STATE, true),
		create_test_condition(evaluator.ConditionType.PROGRESS_HISTORY, true)
	]
	
	var and_result = evaluator.evaluate_condition_group(and_group, create_test_player_data(), create_test_progress_data())
	
	# 创建测试条件组 - OR逻辑
	var or_group = evaluator.ConditionGroup.new()
	or_group.logic_op = evaluator.LogicOp.OR
	or_group.conditions = [
		create_test_condition(evaluator.ConditionType.TEMPORAL_ENVIRONMENT, false),
		create_test_condition(evaluator.ConditionType.CHARACTER_STATE, true),
		create_test_condition(evaluator.ConditionType.PROGRESS_HISTORY, false)
	]
	
	var or_result = evaluator.evaluate_condition_group(or_group, create_test_player_data(), create_test_progress_data())
	
	# 验证结果
	if and_result and or_result:
		result.passed = true
		result.message = "AND逻辑:%s, OR逻辑:%s" % ["通过" if and_result else "失败", "通过" if or_result else "失败"]
	else:
		result.passed = false
		result.message = "条件评估逻辑失败 - AND逻辑:%s, OR逻辑:%s" % ["通过" if and_result else "失败", "通过" if or_result else "失败"]
	
	return result

# 测试3: 福缘修正系数正确应用
func test_luck_correction_coefficient_correctly_applied() -> TestResult:
	var result = TestResult.new()
	result.test_name = "福缘修正系数正确应用"
	
	# 创建条件评估器实例
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	
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
	if abs(prob_low_luck - expected_low) < 0.001 and \
	   abs(prob_medium_luck - expected_medium) < 0.001 and \
	   abs(prob_high_luck - expected_high) < 0.001 and \
	   abs(prob_very_high_luck - expected_very_high) < 0.001:
		result.passed = true
		result.message = "福缘修正系数计算正确: 10点=%g, 50点=%g, 90点=%g, 150点(上限)=%g" % [
			prob_low_luck, prob_medium_luck, prob_high_luck, prob_very_high_luck
		]
	else:
		result.passed = false
		result.message = "福缘修正系数计算错误: 期望 10点=%g, 50点=%g, 90点=%g, 150点(上限)=%g | 实际 10点=%g, 50点=%g, 90点=%g, 150点(上限)=%g" % [
			expected_low, expected_medium, expected_high, expected_very_high,
			prob_low_luck, prob_medium_luck, prob_high_luck, prob_very_high_luck
		]
	
	return result

# 测试4: 条件评估结果准确（true/false）
func test_condition_evaluation_result_accurate() -> TestResult:
	var result = TestResult.new()
	result.test_name = "条件评估结果准确（true/false）"
	
	# 创建条件评估器实例
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	
	# 测试玩家生命值低于20%的条件
	var test_player_data = create_test_player_data()
	test_player_data.health = 0.15  # 15%生命值
	
	var character_result = evaluator.evaluate_character_state_conditions(test_player_data)
	
	# 测试随机概率条件（使用固定随机种子）
	var random_result = evaluator.evaluate_random_probability_conditions(50.0, 0.5)  # 高概率测试
	
	# 验证结果
	if character_result:
		result.passed = true
		result.message = "条件评估结果准确: 角色状态条件=%s, 随机概率条件=%s" % [character_result, random_result]
	else:
		result.passed = false
		result.message = "条件评估结果不准确: 角色状态条件=%s, 随机概率条件=%s" % [character_result, random_result]
	
	return result

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

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行条件类型与评估测试...")
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