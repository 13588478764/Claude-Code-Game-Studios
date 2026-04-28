extends Node

# 逻辑树与权重管理器
# 实现嵌套逻辑树结构、权重分配机制、互斥组处理和权重重分配算法

# 逻辑操作枚举（与ConditionEvaluator保持一致）
enum LogicOp {
	AND,  # 与操作
	OR,   # 或操作
	XOR   # 异或操作
	NOT   # 非操作
}

# 条件节点结构
class ConditionNode:
	var id: String
	var type: String  # 条件类型
	var parameters: Dictionary
	var is_negated: bool = false  # 是否取反

# 逻辑树节点结构
class LogicTreeNode:
	var id: String
	var logic_op: LogicOp  # 逻辑操作
	var condition_nodes: Array[ConditionNode] = []  # 条件节点
	var child_nodes: Array[LogicTreeNode] = []  # 子节点
	var is_leaf: bool = false  # 是否为叶子节点

# 权重数据结构
class WeightData:
	var base_weight: int = 1
	var weight_modifier: float = 1.0
	var adjusted_weight: float = 1.0
	var encounter_id: String

# 互斥组数据结构
class MutexGroup:
	var group_id: String
	var encounter_ids: Array[String]
	var active_encounter: String = ""  # 当前激活的奇遇ID

# 信号定义
signal logic_tree_processed(result_data)

# 存储数据
var logic_trees: Dictionary = {}
var mutex_groups: Dictionary = {}
var weights: Dictionary = {}

# 构建逻辑树结构
func build_logic_tree(condition_data: Dictionary) -> LogicTreeNode:
	var root_node = LogicTreeNode.new()
	root_node.id = condition_data.get("id", "root")
	root_node.logic_op = get_logic_op_from_string(condition_data.get("logic_op", "AND"))
	
	# 处理条件节点
	if condition_data.has("conditions"):
		for condition in condition_data.conditions:
			var condition_node = ConditionNode.new()
			condition_node.id = condition.get("id", "")
			condition_node.type = condition.get("type", "")
			condition_node.parameters = condition.get("parameters", {})
			condition_node.is_negated = condition.get("is_negated", false)
			root_node.condition_nodes.append(condition_node)
	
	# 处理子节点（嵌套逻辑）
	if condition_data.has("children"):
		for child_data in condition_data.children:
			var child_node = build_logic_tree(child_data)
			root_node.child_nodes.append(child_node)
	
	# 如果没有子节点和条件节点，则为叶子节点
	root_node.is_leaf = (root_node.condition_nodes.is_empty() and root_node.child_nodes.is_empty())
	
	return root_node

# 从字符串获取逻辑操作
func get_logic_op_from_string(op_string: String) -> LogicOp:
	match op_string.to_upper():
		"AND": return LogicOp.AND
		"OR": return LogicOp.OR
		"XOR": return LogicOp.XOR
		"NOT": return LogicOp.NOT
		_: return LogicOp.AND

# 评估逻辑树
func evaluate_logic_tree(tree_root: LogicTreeNode, player_data, progress_data) -> bool:
	# 评估条件节点
	var condition_results: Array[bool] = []
	for condition_node in tree_root.condition_nodes:
		var result = evaluate_condition_node(condition_node, player_data, progress_data)
		if condition_node.is_negated:
			result = not result
		condition_results.append(result)
	
	# 评估子节点
	var child_results: Array[bool] = []
	for child_node in tree_root.child_nodes:
		var result = evaluate_logic_tree(child_node, player_data, progress_data)
		child_results.append(result)
	
	# 合并所有结果
	var all_results = condition_results + child_results
	
	# 根据逻辑操作符处理结果
	match tree_root.logic_op:
		LogicOp.AND:
			for result in all_results:
				if not result:
					return false
			return true
		LogicOp.OR:
			for result in all_results:
				if result:
					return true
			return false
		LogicOp.XOR:
			var true_count = 0
			for result in all_results:
				if result:
					true_count += 1
			return true_count % 2 == 1
		LogicOp.NOT:
			# NOT操作通常只对单个条件有效
			if all_results.size() > 0:
				return not all_results[0]
			else:
				return true
		_:
			return false

# 评估条件节点
func evaluate_condition_node(condition_node: ConditionNode, player_data, progress_data) -> bool:
	# 这里需要引用ConditionEvaluator来评估条件
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	
	# 根据条件类型调用评估器的相应方法
	match condition_node.type:
		"TEMPORAL_ENVIRONMENT":
			return evaluator.evaluate_temporal_environment_conditions(player_data)
		"CHARACTER_STATE":
			return evaluator.evaluate_character_state_conditions(player_data)
		"PROGRESS_HISTORY":
			return evaluator.evaluate_progress_history_conditions(progress_data)
		"RANDOM_PROBABILITY":
			var base_prob = condition_node.parameters.get("base_probability", 0.05)
			return evaluator.evaluate_random_probability_conditions(player_data.luck, base_prob)
		_:
			print("未知的条件类型: %s" % condition_node.type)
			return false

# 计算调整后权重
func calculate_adjusted_weights(encounters: Array) -> Array[WeightData]:
	var weight_data_list: Array[WeightData] = []
	
	for encounter in encounters:
		var weight_data = WeightData.new()
		weight_data.encounter_id = encounter.get("id", "")
		weight_data.base_weight = encounter.get("base_weight", 1)
		weight_data.weight_modifier = encounter.get("weight_modifier", 1.0)
		weight_data.adjusted_weight = float(weight_data.base_weight) * weight_data.weight_modifier
		
		weight_data_list.append(weight_data)
	
	return weight_data_list

# 处理互斥组
func handle_mutex_groups(mutex_data: Array) -> void:
	for group_data in mutex_data:
		var mutex_group = MutexGroup.new()
		mutex_group.group_id = group_data.get("group_id", "")
		mutex_group.encounter_ids = group_data.get("encounter_ids", [])
		mutex_group.active_encounter = ""
		
		mutex_groups[mutex_group.group_id] = mutex_group
	
	print("处理了 %d 个互斥组" % mutex_groups.size())

# 检查互斥组冲突
func check_mutex_conflicts(encounter_id: String, mutex_group_id: String = "") -> bool:
	if mutex_group_id == "":
		return false
	
	if not mutex_groups.has(mutex_group_id):
		return false
	
	var mutex_group = mutex_groups[mutex_group_id]
	if mutex_group.active_encounter != "" and mutex_group.active_encounter != encounter_id:
		# 同组中已有其他奇遇被激活
		return true
	
	return false

# 更新互斥组状态
func update_mutex_group_status(encounter_id: String, mutex_group_id: String = "") -> void:
	if mutex_group_id == "":
		return
	
	if not mutex_groups.has(mutex_group_id):
		return
	
	var mutex_group = mutex_groups[mutex_group_id]
	mutex_group.active_encounter = encounter_id

# 加权随机选择
func weighted_random_selection(weighted_encounters: Array[WeightData]) -> String:
	if weighted_encounters.is_empty():
		return ""
	
	# 计算总权重
	var total_weight: float = 0.0
	for weight_data in weighted_encounters:
		total_weight += weight_data.adjusted_weight
	
	if total_weight <= 0:
		return ""
	
	# 生成随机值
	var random_value = randf() * total_weight
	
	# 选择奇遇
	var current_weight: float = 0.0
	for weight_data in weighted_encounters:
		current_weight += weight_data.adjusted_weight
		if random_value <= current_weight:
			return weight_data.encounter_id
	
	# 如果没有找到（理论上不应该发生），返回最后一个
	return weighted_encounters[-1].encounter_id

# 处理多个满足条件的奇遇
func process_multiple_encounters(encounters: Array, player_data, progress_data) -> Dictionary:
	var valid_encounters: Array = []
	
	# 过滤出满足条件的奇遇
	for encounter in encounters:
		var tree_data = encounter.get("logic_tree", {})
		if not tree_data.is_empty():
			var tree_root = build_logic_tree(tree_data)
			var is_met = evaluate_logic_tree(tree_root, player_data, progress_data)
			
			if is_met:
				# 检查互斥组冲突
				var mutex_group_id = encounter.get("mutex_group", "")
				if not check_mutex_conflicts(encounter.get("id", ""), mutex_group_id):
					valid_encounters.append(encounter)
	
	# 计算权重
	var weighted_encounters = calculate_adjusted_weights(valid_encounters)
	
	# 执行加权随机选择
	var selected_encounter_id = weighted_random_selection(weighted_encounters)
	
	# 更新互斥组状态
	if selected_encounter_id != "":
		for encounter in valid_encounters:
			if encounter.get("id", "") == selected_encounter_id:
				var mutex_group_id = encounter.get("mutex_group", "")
				update_mutex_group_status(selected_encounter_id, mutex_group_id)
				break
	
	# 返回结果
	var result = {
		"selected_encounter": selected_encounter_id,
		"valid_encounters": valid_encounters,
		"weighted_encounters": weighted_encounters,
		"total_valid": valid_encounters.size()
	}
	
	emit_signal("logic_tree_processed", result)
	
	return result

# 测试函数
func test_logic_tree_and_weighting():
	print("开始测试逻辑树与权重...")
	
	# 测试逻辑树构建和评估
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
	
	var tree_root = build_logic_tree(test_tree_data)
	print("逻辑树构建完成，根节点ID: %s" % tree_root.id)
	
	# 创建测试数据
	var evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	var player_data = evaluator.PlayerData.new()
	player_data.luck = 50.0
	player_data.time = 22.5  # 晚上10:30
	player_data.weather = "rain"
	player_data.health = 0.3  # 30%
	player_data.qi = 0.7
	player_data.position = Vector2(100, 100)
	player_data.attributes = {"luck": 50, "wisdom": 60, "health": 80}
	player_data.inventory = ["mysterious_jade"]
	player_data.skills = ["taijiquan"]
	player_data.realm = "ZhuJi"
	
	var progress_data = evaluator.ProgressData.new()
	progress_data.quest_status = {"main_chapter": 3, "side_quest_completed": true}
	progress_data.explored_areas = ["Qingyun_Mountain", "Black_Wind_Fortress"]
	progress_data.encounter_history = ["encounter_001", "encounter_002"]
	progress_data.behavior_history = {"bandits_killed": 55, "npc_helped": 12}
	
	# 评估逻辑树
	var result = evaluate_logic_tree(tree_root, player_data, progress_data)
	print("逻辑树评估结果: %s" % result)
	
	# 测试权重计算
	var test_encounters = [
		{"id": "encounter_1", "base_weight": 10, "weight_modifier": 1.5},
		{"id": "encounter_2", "base_weight": 5, "weight_modifier": 2.0},
		{"id": "encounter_3", "base_weight": 15, "weight_modifier": 1.0}
	]
	
	var weighted_results = calculate_adjusted_weights(test_encounters)
	print("权重计算结果:")
	for weight_data in weighted_results:
		print("  奇遇ID: %s, 基础权重: %d, 修正系数: %.2f, 调整后权重: %.2f" % [
			weight_data.encounter_id, 
			weight_data.base_weight, 
			weight_data.weight_modifier, 
			weight_data.adjusted_weight
		])
	
	# 测试加权随机选择
	var selected = weighted_random_selection(weighted_results)
	print("加权随机选择结果: %s" % selected)
	
	# 测试互斥组处理
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
	
	handle_mutex_groups(test_mutex_data)
	print("互斥组处理完成")
	
	# 测试互斥组冲突检查
	var has_conflict = check_mutex_conflicts("encounter_2", "group_1")
	print("互斥组冲突检查结果: %s" % has_conflict)
	
	print("逻辑树与权重测试完成")