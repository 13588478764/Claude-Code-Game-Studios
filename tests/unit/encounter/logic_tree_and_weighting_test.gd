# 逻辑树与权重单元测试
# 验证嵌套逻辑树、权重分配、互斥组处理和权重重分配算法

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_logic_tree_structure_correctly_implemented())
	results.append(test_weight_allocation_mechanism_normal())
	results.append(test_mutex_group_handling_correct())
	results.append(test_weight_redistribution_algorithm_accurate())
	
	return results

# 测试1: 逻辑树结构正确实现
func test_logic_tree_structure_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "逻辑树结构正确实现"
	
	# 创建逻辑树管理器实例
	var logic_manager = load("res://src/scripts/encounter/logic_tree_manager.gd").new()
	
	# 创建测试逻辑树数据
	var test_tree_data = {
		"id": "test_tree_1",
		"logic_op": "AND",
		"conditions": [
			{
				"id": "cond_1",
				"type": "CHARACTER_STATE",
				"parameters": {"luck": ">20"}
			},
			{
				"id": "cond_2",
				"type": "TEMPORAL_ENVIRONMENT",
				"parameters": {"time_of_day": "night"}
			}
		],
		"children": [
			{
				"id": "child_tree_1",
				"logic_op": "OR",
				"conditions": [
					{
						"id": "cond_3",
						"type": "PROGRESS_HISTORY",
						"parameters": {"quest_completed": true}
					},
					{
						"id": "cond_4",
						"type": "CHARACTER_STATE",
						"parameters": {"health": "<0.5"}
					}
				]
			}
		]
	}
	
	# 构建逻辑树
	var tree_root = logic_manager.build_logic_tree(test_tree_data)
	
	# 验证树结构
	var has_correct_root_op = tree_root.logic_op == logic_manager.LogicOp.AND
	var has_correct_child_op = tree_root.child_nodes.size() > 0 and tree_root.child_nodes[0].logic_op == logic_manager.LogicOp.OR
	var has_correct_condition_count = tree_root.condition_nodes.size() == 2
	
	if has_correct_root_op and has_correct_child_op and has_correct_condition_count:
		result.passed = true
		result.message = "逻辑树结构正确：根节点为AND操作，包含1个OR操作的子节点，2个条件节点"
	else:
		result.passed = false
		result.message = "逻辑树结构错误：根操作=%s, 子节点数=%d, 条件节点数=%d" % [
			"AND" if has_correct_root_op else "其他",
			tree_root.child_nodes.size(),
			tree_root.condition_nodes.size()
		]
	
	return result

# 测试2: 权重分配机制正常
func test_weight_allocation_mechanism_normal() -> TestResult:
	var result = TestResult.new()
	result.test_name = "权重分配机制正常"
	
	# 创建逻辑树管理器实例
	var logic_manager = load("res://src/scripts/encounter/logic_tree_manager.gd").new()
	
	# 创建测试奇遇数据
	var test_encounters = [
		{"id": "encounter_1", "base_weight": 10, "weight_modifier": 1.5},
		{"id": "encounter_2", "base_weight": 5, "weight_modifier": 2.0},
		{"id": "encounter_3", "base_weight": 15, "weight_modifier": 1.0}
	]
	
	# 计算调整后权重
	var weighted_results = logic_manager.calculate_adjusted_weights(test_encounters)
	
	# 验证权重计算
	var expected_weights = [15.0, 10.0, 15.0]  # 10*1.5, 5*2.0, 15*1.0
	var actual_weights = []
	for weight_data in weighted_results:
		actual_weights.append(weight_data.adjusted_weight)
	
	var all_correct = true
	for i in range(min(expected_weights.size(), actual_weights.size())):
		if abs(expected_weights[i] - actual_weights[i]) > 0.01:
			all_correct = false
			break
	
	if all_correct and weighted_results.size() == 3:
		result.passed = true
		result.message = "权重分配正确：encounter_1(10*1.5=%g), encounter_2(5*2.0=%g), encounter_3(15*1.0=%g)" % [
			expected_weights[0], expected_weights[1], expected_weights[2]
		]
	else:
		result.passed = false
		result.message = "权重分配错误：期望=%s, 实际=%s" % [str(expected_weights), str(actual_weights)]
	
	return result

# 测试3: 互斥组处理正确
func test_mutex_group_handling_correct() -> TestResult:
	var result = TestResult.new()
	result.test_name = "互斥组处理正确"
	
	# 创建逻辑树管理器实例
	var logic_manager = load("res://src/scripts/encounter/logic_tree_manager.gd").new()
	
	# 创建测试互斥组数据
	var test_mutex_data = [
		{
			"group_id": "group_1",
			"encounter_ids": ["encounter_1", "encounter_2"]
		},
		{
			"group_id": "group_2", 
			"encounter_ids": ["encounter_3", "encounter_4", "encounter_5"]
		}
	]
	
	# 处理互斥组
	logic_manager.handle_mutex_groups(test_mutex_data)
	
	# 验证互斥组是否正确创建
	var has_correct_groups = logic_manager.mutex_groups.size() == 2
	var has_group_1 = logic_manager.mutex_groups.has("group_1")
	var has_group_2 = logic_manager.mutex_groups.has("group_2")
	
	if has_correct_groups and has_group_1 and has_group_2:
		# 测试冲突检查
		var no_conflict_initially = not logic_manager.check_mutex_conflicts("encounter_1", "group_1")
		
		# 更新组状态
		logic_manager.update_mutex_group_status("encounter_1", "group_1")
		
		# 检查冲突
		var has_conflict_after_update = logic_manager.check_mutex_conflicts("encounter_2", "group_1")
		
		if no_conflict_initially and has_conflict_after_update:
			result.passed = true
			result.message = "互斥组处理正确：成功创建2个组，冲突检测正常"
		else:
			result.passed = false
			result.message = "互斥组冲突检测异常：初始无冲突=%s, 更新后冲突检测=%s" % [
				no_conflict_initially, has_conflict_after_update
			]
	else:
		result.passed = false
		result.message = "互斥组创建失败：期望2个组，实际=%d个" % logic_manager.mutex_groups.size()
	
	return result

# 测试4: 权重重分配算法准确
func test_weight_redistribution_algorithm_accurate() -> TestResult:
	var result = TestResult.new()
	result.test_name = "权重重分配算法准确"
	
	# 创建逻辑树管理器实例
	var logic_manager = load("res://src/scripts/encounter/logic_tree_manager.gd").new()
	
	# 创建测试权重数据
	var test_weight_data = []
	
	# 创建测试奇遇数据
	var test_encounters = [
		{"id": "encounter_1", "base_weight": 10, "weight_modifier": 1.0},
		{"id": "encounter_2", "base_weight": 20, "weight_modifier": 1.0},
		{"id": "encounter_3", "base_weight": 30, "weight_modifier": 1.0}
	]
	
	# 计算权重
	var weighted_results = logic_manager.calculate_adjusted_weights(test_encounters)
	
	# 执行多次加权随机选择以验证分布
	var selection_counts = {"encounter_1": 0, "encounter_2": 0, "encounter_3": 0}
	var total_trials = 1000
	
	for i in range(total_trials):
		var selected = logic_manager.weighted_random_selection(weighted_results)
		if selection_counts.has(selected):
			selection_counts[selected] += 1
	
	# 验证选择分布是否大致符合权重比例
	# encounter_1: 10, encounter_2: 20, encounter_3: 30 -> 总计60
	# 期望比例: 1/6, 2/6, 3/6
	var expected_1 = total_trials * (10.0 / 60.0)  # ~167
	var expected_2 = total_trials * (20.0 / 60.0)  # ~333
	var expected_3 = total_trials * (30.0 / 60.0)  # ~500
	
	var tolerance = total_trials * 0.15  # 15% 容差
	
	var within_tolerance = (
		abs(selection_counts["encounter_1"] - expected_1) <= tolerance and
		abs(selection_counts["encounter_2"] - expected_2) <= tolerance and
		abs(selection_counts["encounter_3"] - expected_3) <= tolerance
	)
	
	if within_tolerance:
		result.passed = true
		result.message = "权重重分配算法准确：在%d次试验中，选择分布符合权重比例" % total_trials
	else:
		result.passed = false
		result.message = "权重重分配算法不准确：期望[%g, %g, %g]，实际[%d, %d, %d]" % [
			expected_1, expected_2, expected_3,
			selection_counts["encounter_1"], 
			selection_counts["encounter_2"], 
			selection_counts["encounter_3"]
		]
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行逻辑树与权重测试...")
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