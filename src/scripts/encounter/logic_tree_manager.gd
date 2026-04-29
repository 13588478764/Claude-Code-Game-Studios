# LogicTreeManager - 逻辑树与权重管理系统
#
# 负责管理奇遇的逻辑树结构、权重分配、互斥组处理和加权随机选择
# 与 ConditionEvaluator 和 TriggerMechanismManager 集成
#
# 信号:
#   - logic_tree_processed(tree_root, selected_encounter)

extends Node

class_name LogicTreeManager

# 逻辑操作符枚举
enum LogicOp {
	AND,                     # 逻辑与
	OR                       # 逻辑或
}

# 信号定义
signal logic_tree_processed(tree_root: Object, selected_encounter: String)

# ============================================================================
# 内部类定义
# ============================================================================

## 逻辑树节点类
class LogicTreeNode:
	var id: String
	var logic_op: int                    # AND 或 OR
	var condition_nodes: Array           # 条件节点数组
	var child_nodes: Array               # 子树节点数组
	var parent_node: Object              # 父节点引用
	
	func _init():
		id = ""
		logic_op = 0
		condition_nodes = []
		child_nodes = []
		parent_node = null

## 条件节点类
class ConditionNode:
	var id: String
	var type: String
	var parameters: Dictionary
	var is_met: bool
	
	func _init():
		id = ""
		type = ""
		parameters = {}
		is_met = false

## 权重数据类
class WeightData:
	var encounter_id: String
	var base_weight: float
	var weight_modifier: float
	var adjusted_weight: float
	
	func _init():
		encounter_id = ""
		base_weight = 0.0
		weight_modifier = 1.0
		adjusted_weight = 0.0

## 互斥组类
class MutexGroup:
	var group_id: String
	var encounter_ids: Array
	var triggered_encounter: String      # 已触发的奇遇ID
	var is_locked: bool
	
	func _init():
		group_id = ""
		encounter_ids = []
		triggered_encounter = ""
		is_locked = false

# ============================================================================
# 成员变量
# ============================================================================

var condition_evaluator: Node = null
var mutex_groups: Dictionary = {}      # 互斥组字典
var logic_trees: Dictionary = {}        # 逻辑树字典
var encounter_weights: Dictionary = {}  # 奇遇权重字典

# ============================================================================
# 初始化
# ============================================================================

func _ready():
	# 获取条件评估器实例
	condition_evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()

# ============================================================================
# 公共方法
# ============================================================================

## 构建逻辑树结构
## 参数:
##   - condition_data: 逻辑树数据字典
##     - id: 树的ID
##     - logic_op: 逻辑操作符 ("AND" 或 "OR")
##     - conditions: 条件数组
##     - children: 子树数组
## 返回: 逻辑树根节点
func build_logic_tree(condition_data: Dictionary) -> Object:
	var tree_root = LogicTreeNode.new()
	tree_root.id = condition_data.get("id", "root")
	
	# 设置逻辑操作符
	var logic_op_str = condition_data.get("logic_op", "AND")
	tree_root.logic_op = LogicOp.AND if logic_op_str == "AND" else LogicOp.OR
	
	# 构建条件节点
	var conditions = condition_data.get("conditions", [])
	for condition in conditions:
		var condition_node = ConditionNode.new()
		condition_node.id = condition.get("id", "")
		condition_node.type = condition.get("type", "")
		condition_node.parameters = condition.get("parameters", {})
		tree_root.condition_nodes.append(condition_node)
	
	# 递归构建子树
	var children = condition_data.get("children", [])
	for child_data in children:
		var child_node = build_logic_tree(child_data)
		child_node.parent_node = tree_root
		tree_root.child_nodes.append(child_node)
	
	# 保存逻辑树
	logic_trees[tree_root.id] = tree_root
	
	return tree_root


## 评估逻辑树
## 参数:
##   - tree_root: 逻辑树根节点
##   - player_data: 玩家数据对象
##   - progress_data: 进度数据对象
## 返回: 逻辑树评估结果
func evaluate_logic_tree(tree_root: Object, player_data: Object = null, progress_data: Object = null) -> bool:
	if tree_root == null:
		return false
	
	# 评估条件节点
	var condition_results = []
	for condition_node in tree_root.condition_nodes:
		var result = _evaluate_condition_node(condition_node, player_data, progress_data)
		condition_results.append(result)
	
	# 评估子树
	var child_results = []
	for child_node in tree_root.child_nodes:
		var result = evaluate_logic_tree(child_node, player_data, progress_data)
		child_results.append(result)
	
	# 合并所有结果
	var all_results = condition_results + child_results
	
	# 根据逻辑操作符组合结果
	if all_results.is_empty():
		return false
	
	match tree_root.logic_op:
		LogicOp.AND:
			# AND 逻辑: 所有条件都为 true 才返回 true
			for result in all_results:
				if not result:
					return false
			return true
		
		LogicOp.OR:
			# OR 逻辑: 至少一个条件为 true 就返回 true
			for result in all_results:
				if result:
					return true
			return false
	
	return false


## 计算调整后权重
## 参数:
##   - encounters: 奇遇数组
##     - id: 奇遇ID
##     - base_weight: 基础权重
##     - weight_modifier: 权重修正系数
## 返回: 权重数据数组
func calculate_adjusted_weights(encounters: Array) -> Array:
	var weighted_results = []
	
	for encounter in encounters:
		var weight_data = WeightData.new()
		weight_data.encounter_id = encounter.get("id", "")
		weight_data.base_weight = encounter.get("base_weight", 1.0)
		weight_data.weight_modifier = encounter.get("weight_modifier", 1.0)
		
		# 计算调整后权重 = 基础权重 × 修正系数
		weight_data.adjusted_weight = weight_data.base_weight * weight_data.weight_modifier
		
		weighted_results.append(weight_data)
		
		# 保存权重数据
		encounter_weights[weight_data.encounter_id] = weight_data
	
	return weighted_results


## 处理互斥组
## 参数:
##   - mutex_data: 互斥组数据数组
##     - group_id: 组ID
##     - encounter_ids: 组内奇遇ID数组
## 返回: 无
func handle_mutex_groups(mutex_data: Array) -> void:
	for group_data in mutex_data:
		var mutex_group = MutexGroup.new()
		mutex_group.group_id = group_data.get("group_id", "")
		mutex_group.encounter_ids = group_data.get("encounter_ids", [])
		mutex_group.is_locked = false
		
		mutex_groups[mutex_group.group_id] = mutex_group


## 检查互斥冲突
## 参数:
##   - encounter_id: 奇遇ID
##   - group_id: 互斥组ID
## 返回: 是否存在冲突
func check_mutex_conflicts(encounter_id: String, group_id: String) -> bool:
	if not mutex_groups.has(group_id):
		return false
	
	var mutex_group = mutex_groups[group_id]
	
	# 如果组已锁定，检查是否是同组的其他奇遇
	if mutex_group.is_locked:
		# 如果是同组的其他奇遇，则存在冲突
		if encounter_id in mutex_group.encounter_ids and encounter_id != mutex_group.triggered_encounter:
			return true
	
	return false


## 更新互斥组状态
## 参数:
##   - encounter_id: 奇遇ID
##   - group_id: 互斥组ID
## 返回: 无
func update_mutex_group_status(encounter_id: String, group_id: String) -> void:
	if not mutex_groups.has(group_id):
		return
	
	var mutex_group = mutex_groups[group_id]
	
	# 检查奇遇是否属于该组
	if encounter_id in mutex_group.encounter_ids:
		mutex_group.triggered_encounter = encounter_id
		mutex_group.is_locked = true


## 执行加权随机选择
## 参数:
##   - weighted_encounters: 权重数据数组
## 返回: 选中的奇遇ID
func weighted_random_selection(weighted_encounters: Array) -> String:
	if weighted_encounters.is_empty():
		return ""
	
	# 计算总权重
	var total_weight = 0.0
	for weight_data in weighted_encounters:
		total_weight += weight_data.adjusted_weight
	
	if total_weight <= 0.0:
		return ""
	
	# 生成随机数
	var random_value = randf() * total_weight
	
	# 根据权重进行选择
	var accumulated_weight = 0.0
	for weight_data in weighted_encounters:
		accumulated_weight += weight_data.adjusted_weight
		if random_value <= accumulated_weight:
			return weight_data.encounter_id
	
	# 如果没有选中任何奇遇，返回最后一个
	if weighted_encounters.size() > 0:
		return weighted_encounters[-1].encounter_id
	
	return ""


## 处理逻辑树并选择奇遇
## 参数:
##   - tree_root: 逻辑树根节点
##   - encounters: 奇遇数组
##   - player_data: 玩家数据对象
##   - progress_data: 进度数据对象
## 返回: 选中的奇遇ID
func process_logic_tree_and_select_encounter(tree_root: Object, encounters: Array, player_data: Object = null, progress_data: Object = null) -> String:
	# 评估逻辑树
	var tree_result = evaluate_logic_tree(tree_root, player_data, progress_data)
	
	if not tree_result:
		return ""
	
	# 计算权重
	var weighted_results = calculate_adjusted_weights(encounters)
	
	# 执行加权随机选择
	var selected_encounter = weighted_random_selection(weighted_results)
	
	# 发送信号
	logic_tree_processed.emit(tree_root, selected_encounter)
	
	return selected_encounter


# ============================================================================
# 私有方法
# ============================================================================

## 评估条件节点
## 参数:
##   - condition_node: 条件节点
##   - player_data: 玩家数据对象
##   - progress_data: 进度数据对象
## 返回: 条件评估结果
func _evaluate_condition_node(condition_node: Object, player_data: Object = null, progress_data: Object = null) -> bool:
	if condition_evaluator == null:
		condition_evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	
	# 如果条件节点有 is_met 参数，直接使用它
	if condition_node.parameters.has("is_met"):
		return condition_node.parameters["is_met"]
	
	# 根据条件类型进行评估
	match condition_node.type:
		"TEMPORAL_ENVIRONMENT":
			var player_dict = _player_data_to_dict(player_data)
			return condition_evaluator.evaluate_temporal_environment_conditions(player_dict)
		
		"CHARACTER_STATE":
			var player_dict = _player_data_to_dict(player_data)
			return condition_evaluator.evaluate_character_state_conditions(player_dict)
		
		"PROGRESS_HISTORY":
			var progress_dict = _progress_data_to_dict(progress_data)
			return condition_evaluator.evaluate_progress_history_conditions(progress_dict)
		
		"RANDOM_PROBABILITY":
			var luck = 50.0
			if player_data and player_data is Object:
				if "luck" in player_data:
					luck = player_data.luck
			var base_prob = condition_node.parameters.get("base_probability", 0.05)
			return condition_evaluator.evaluate_random_probability_conditions(luck, base_prob)
		
		_:
			return false


## 将 PlayerData 对象转换为字典
## 参数:
##   - player_data: PlayerData 对象
## 返回: 转换后的字典
func _player_data_to_dict(player_data: Object) -> Dictionary:
	var result = {}
	
	if player_data == null:
		# 返回默认值
		result["position"] = Vector2.ZERO
		result["time"] = 0.0
		result["weather"] = ""
		result["luck"] = 50.0
		result["wisdom"] = 60.0
		result["health"] = 0.8
		result["max_health"] = 1.0
		result["qi"] = 0.7
		result["attributes"] = {}
		result["inventory"] = []
		result["skills"] = []
		result["realm"] = ""
		result["location"] = "default_location"
		result["time_of_day"] = "day"
		result["status_effects"] = []
	else:
		# 尝试访问对象的属性
		result["position"] = player_data.position if "position" in player_data else Vector2.ZERO
		result["time"] = player_data.time if "time" in player_data else 0.0
		result["weather"] = player_data.weather if "weather" in player_data else ""
		result["luck"] = player_data.luck if "luck" in player_data else 50.0
		result["wisdom"] = player_data.wisdom if "wisdom" in player_data else 60.0
		result["health"] = player_data.health if "health" in player_data else 0.8
		result["max_health"] = 1.0
		result["qi"] = player_data.qi if "qi" in player_data else 0.7
		result["attributes"] = player_data.attributes if "attributes" in player_data else {}
		result["inventory"] = player_data.inventory if "inventory" in player_data else []
		result["skills"] = player_data.skills if "skills" in player_data else []
		result["realm"] = player_data.realm if "realm" in player_data else ""
		result["location"] = "default_location"
		result["time_of_day"] = "day"
		result["status_effects"] = []
	
	return result


## 将 ProgressData 对象转换为字典
## 参数:
##   - progress_data: ProgressData 对象
## 返回: 转换后的字典
func _progress_data_to_dict(progress_data: Object) -> Dictionary:
	var result = {}
	
	if progress_data == null:
		# 返回默认值
		result["quest_status"] = {}
		result["explored_areas"] = []
		result["encounter_history"] = []
		result["behavior_history"] = {}
		result["encounters_completed"] = []
		result["level"] = 1
	else:
		# 尝试访问对象的属性
		result["quest_status"] = progress_data.quest_status if "quest_status" in progress_data else {}
		result["explored_areas"] = progress_data.explored_areas if "explored_areas" in progress_data else []
		result["encounter_history"] = progress_data.encounter_history if "encounter_history" in progress_data else []
		result["behavior_history"] = progress_data.behavior_history if "behavior_history" in progress_data else {}
		result["encounters_completed"] = progress_data.encounter_history if "encounter_history" in progress_data else []
		result["level"] = 1
	
	return result