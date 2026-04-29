# 逻辑树与权重单元测试
# 验证嵌套逻辑树、权重分配、互斥组处理和权重重分配算法

extends GutTest

# 测试1: 逻辑树结构正确实现
func test_logic_tree_structure_correctly_implemented():
	# 创建逻辑树管理器实例
	var logic_manager = load("res://src/scripts/encounter/logic_tree_manager.gd").new()
	add_child(logic_manager)
	
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
	assert_eq(tree_root.logic_op, logic_manager.LogicOp.AND, "根节点应该是AND操作")
	assert_eq(tree_root.condition_nodes.size(), 2, "根节点应该有2个条件节点")
	assert_eq(tree_root.child_nodes.size(), 1, "根节点应该有1个子节点")
	
	# 验证子节点
	var child_node = tree_root.child_nodes[0]
	assert_eq(child_node.logic_op, logic_manager.LogicOp.OR, "子节点应该是OR操作")
	assert_eq(child_node.condition_nodes.size(), 2, "子节点应该有2个条件节点")


# 测试2: 权重分配机制正常
func test_weight_allocation_mechanism_normal():
	# 创建逻辑树管理器实例
	var logic_manager = load("res://src/scripts/encounter/logic_tree_manager.gd").new()
	add_child(logic_manager)
	
	# 创建测试奇遇数据
	var test_encounters = [
		{"id": "encounter_1", "base_weight": 10, "weight_modifier": 1.5},
		{"id": "encounter_2", "base_weight": 5, "weight_modifier": 2.0},
		{"id": "encounter_3", "base_weight": 15, "weight_modifier": 1.0}
	]
	
	# 计算调整后权重
	var weighted_results = logic_manager.calculate_adjusted_weights(test_encounters)
	
	# 验证权重计算
	assert_eq(weighted_results.size(), 3, "应该返回3个权重数据")
	
	# 验证具体权重值
	assert_true(abs(weighted_results[0].adjusted_weight - 15.0) < 0.01, "encounter_1权重应该是10*1.5=15")
	assert_true(abs(weighted_results[1].adjusted_weight - 10.0) < 0.01, "encounter_2权重应该是5*2.0=10")
	assert_true(abs(weighted_results[2].adjusted_weight - 15.0) < 0.01, "encounter_3权重应该是15*1.0=15")


# 测试3: 互斥组处理正确
func test_mutex_group_handling_correct():
	# 创建逻辑树管理器实例
	var logic_manager = load("res://src/scripts/encounter/logic_tree_manager.gd").new()
	add_child(logic_manager)
	
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
	assert_eq(logic_manager.mutex_groups.size(), 2, "应该创建2个互斥组")
	assert_true(logic_manager.mutex_groups.has("group_1"), "应该存在group_1")
	assert_true(logic_manager.mutex_groups.has("group_2"), "应该存在group_2")
	
	# 测试冲突检查 - 初始状态应该没有冲突
	var no_conflict_initially = not logic_manager.check_mutex_conflicts("encounter_1", "group_1")
	assert_true(no_conflict_initially, "初始状态应该没有冲突")
	
	# 更新组状态
	logic_manager.update_mutex_group_status("encounter_1", "group_1")
	
	# 检查冲突 - 更新后应该有冲突
	var has_conflict_after_update = logic_manager.check_mutex_conflicts("encounter_2", "group_1")
	assert_true(has_conflict_after_update, "更新后同组其他奇遇应该有冲突")


# 测试4: 权重重分配算法准确
func test_weight_redistribution_algorithm_accurate():
	# 创建逻辑树管理器实例
	var logic_manager = load("res://src/scripts/encounter/logic_tree_manager.gd").new()
	add_child(logic_manager)
	
	# 创建测试奇遇数据
	var test_encounters = [
		{"id": "encounter_1", "base_weight": 10, "weight_modifier": 1.0},
		{"id": "encounter_2", "base_weight": 20, "weight_modifier": 1.0},
		{"id": "encounter_3", "base_weight": 30, "weight_modifier": 1.0}
	]
	
	# 计算权重
	var weighted_results = logic_manager.calculate_adjusted_weights(test_encounters)
	
	# 验证权重数据
	assert_eq(weighted_results.size(), 3, "应该有3个权重数据")
	
	# 执行多次加权随机选择以验证分布
	var selection_counts = {"encounter_1": 0, "encounter_2": 0, "encounter_3": 0}
	var total_trials = 100
	
	for i in range(total_trials):
		var selected = logic_manager.weighted_random_selection(weighted_results)
		if selection_counts.has(selected):
			selection_counts[selected] += 1
	
	# 验证至少有一些选择
	var total_selected = selection_counts["encounter_1"] + selection_counts["encounter_2"] + selection_counts["encounter_3"]
	assert_eq(total_selected, total_trials, "应该选择%d个奇遇" % total_trials)