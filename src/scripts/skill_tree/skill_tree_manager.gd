class_name SkillTreeManager
extends Node

## 技能树管理器
## 实现线性主干、分支专精和网状关联三种学习路径类型

# 路径类型枚举
enum PathType {
	MAIN_PATH,      # 线性主干路径
	BRANCH,         # 分支专精路径
	CROSS_LINK      # 网状关联路径
}

# 节点状态枚举
enum NodeStatus {
	LOCKED,         # 锁定状态
	AVAILABLE,      # 可解锁状态
	UNLOCKED,       # 已解锁状态
	ACTIVE          # 激活状态（已装备）
}

# 武学图谱数据结构
var skill_trees: Dictionary = {}  # 存储所有武学流派的图谱 {school_id: SkillTree}

# 武学图谱类
class SkillTree:
	var school_id: String           # 武学流派ID
	var school_name: String         # 武学流派名称
	var nodes: Dictionary = {}      # 节点字典 {node_id: SkillNode}
	var main_path: Array = []       # 线性主干路径节点ID列表
	var branches: Dictionary = {}   # 分支路径 {parent_node_id: [branch_nodes]}
	var cross_links: Array = []     # 网状关联 [{from_school, from_node, to_school, to_node}]
	
	func _init(id: String, name: String):
		school_id = id
		school_name = name

# 武学节点类
class SkillNode:
	var node_id: String             # 节点ID
	var skill_name: String          # 招式名称
	var description: String         # 招式描述
	var path_type: PathType         # 路径类型
	var tier: int                   # 品阶（1=黄阶, 2=玄阶, 3=地阶, 4=天阶）
	var prerequisites: Array = []   # 前置节点ID列表
	var branch_condition: Dictionary = {}  # 分支条件 {attribute: value}
	var cross_link_source: Dictionary = {} # 跨武学依赖 {school_id: node_id}
	var status: NodeStatus = NodeStatus.LOCKED
	
	func _init(id: String, name: String, desc: String, type: PathType, tier_level: int = 1):
		node_id = id
		skill_name = name
		description = desc
		path_type = type
		tier = tier_level

func _init():
	# 初始化默认武学图谱
	_initialize_default_skill_trees()

# 初始化默认武学图谱
func _initialize_default_skill_trees():
	# 创建华山剑法图谱
	var huashan = SkillTree.new("huashan_sword", "华山剑法")
	
	# 线性主干路径：刺→撩→劈→崩
	var ci = SkillNode.new("ci", "刺", "基础刺击，快速精准", PathType.MAIN_PATH, 1)
	var liao = SkillNode.new("liao", "撩", "向上撩击，破防效果", PathType.MAIN_PATH, 1)
	liao.prerequisites = ["ci"]
	var pi = SkillNode.new("pi", "劈", "向下劈砍，高伤害", PathType.MAIN_PATH, 2)
	pi.prerequisites = ["liao"]
	var beng = SkillNode.new("beng", "崩", "崩字诀，破甲攻击", PathType.MAIN_PATH, 2)
	beng.prerequisites = ["pi"]
	
	# 分支专精路径：劈之后分叉为重劈和快劈
	var zhong_pi = SkillNode.new("zhong_pi", "重劈", "重型劈砍，高伤害破防", PathType.BRANCH, 2)
	zhong_pi.prerequisites = ["pi"]
	zhong_pi.branch_condition = {"STR": 10}  # 需要力道≥10
	
	var kuai_pi = SkillNode.new("kuai_pi", "快劈", "快速劈砍，高连击加身法", PathType.BRANCH, 2)
	kuai_pi.prerequisites = ["pi"]
	kuai_pi.branch_condition = {"AGI": 10}  # 需要身法≥10
	
	# 添加节点到图谱
	huashan.nodes["ci"] = ci
	huashan.nodes["liao"] = liao
	huashan.nodes["pi"] = pi
	huashan.nodes["beng"] = beng
	huashan.nodes["zhong_pi"] = zhong_pi
	huashan.nodes["kuai_pi"] = kuai_pi
	
	# 设置线性主干路径
	huashan.main_path = ["ci", "liao", "pi", "beng"]
	
	# 设置分支路径
	huashan.branches["pi"] = ["zhong_pi", "kuai_pi"]
	
	# 添加到武学图谱字典
	skill_trees["huashan_sword"] = huashan
	
	# 创建太极拳图谱
	var taiji = SkillTree.new("taiji_quan", "太极拳")
	
	var jie_li = SkillNode.new("jie_li", "借力", "借力打力，以柔克刚", PathType.MAIN_PATH, 2)
	taiji.nodes["jie_li"] = jie_li
	taiji.main_path = ["jie_li"]
	
	skill_trees["taiji_quan"] = taiji
	
	# 创建擒拿手图谱
	var qinna = SkillTree.new("qinna_shou", "擒拿手")
	
	var fan_guan_jie = SkillNode.new("fan_guan_jie", "反关节技", "反关节擒拿技巧", PathType.CROSS_LINK, 2)
	fan_guan_jie.cross_link_source = {"taiji_quan": "jie_li"}  # 需要太极拳的借力
	qinna.nodes["fan_guan_jie"] = fan_guan_jie
	
	# 设置网状关联
	qinna.cross_links.append({
		"from_school": "taiji_quan",
		"from_node": "jie_li",
		"to_school": "qinna_shou",
		"to_node": "fan_guan_jie"
	})
	
	skill_trees["qinna_shou"] = qinna

# 获取武学图谱
func get_skill_tree(school_id: String) -> SkillTree:
	return skill_trees.get(school_id, null)

# 获取所有武学图谱
func get_all_skill_trees() -> Dictionary:
	return skill_trees

# 添加武学图谱
func add_skill_tree(skill_tree: SkillTree) -> void:
	skill_trees[skill_tree.school_id] = skill_tree

# 验证线性主干路径的顺序依赖
func validate_main_path(school_id: String) -> bool:
	var tree = get_skill_tree(school_id)
	if not tree:
		return false
	
	# 检查主干路径是否为空
	if tree.main_path.is_empty():
		return true  # 空路径视为有效
	
	# 检查每个节点的前置依赖是否正确
	for i in range(tree.main_path.size()):
		var node_id = tree.main_path[i]
		var node = tree.nodes.get(node_id)
		
		if not node:
			return false  # 节点不存在
		
		# 第一个节点不应有前置依赖
		if i == 0:
			if not node.prerequisites.is_empty():
				return false
		else:
			# 后续节点应依赖前一个节点
			var prev_node_id = tree.main_path[i - 1]
			if not node.prerequisites.has(prev_node_id):
				return false
	
	# 检查是否存在循环依赖
	if _has_circular_dependency(tree):
		return false
	
	return true

# 检查循环依赖
func _has_circular_dependency(tree: SkillTree) -> bool:
	var visited = {}
	var rec_stack = {}
	
	for node_id in tree.nodes.keys():
		if not visited.get(node_id, false):
			if _is_cyclic_util(tree, node_id, visited, rec_stack):
				return true
	
	return false

# 循环依赖检测辅助函数（深度优先搜索）
func _is_cyclic_util(tree: SkillTree, node_id: String, visited: Dictionary, rec_stack: Dictionary) -> bool:
	visited[node_id] = true
	rec_stack[node_id] = true
	
	var node = tree.nodes.get(node_id)
	if node:
		for prereq in node.prerequisites:
			if not visited.get(prereq, false):
				if _is_cyclic_util(tree, prereq, visited, rec_stack):
					return true
			elif rec_stack.get(prereq, false):
				return true
	
	rec_stack[node_id] = false
	return false

# 获取分支选项
func get_branch_options(school_id: String, parent_node_id: String) -> Array:
	var tree = get_skill_tree(school_id)
	if not tree:
		return []
	
	var branch_node_ids = tree.branches.get(parent_node_id, [])
	var branch_nodes = []
	
	for node_id in branch_node_ids:
		var node = tree.nodes.get(node_id)
		if node:
			branch_nodes.append(node)
	
	return branch_nodes

# 验证分支条件
func validate_branch_condition(node: SkillNode, player_attributes: Dictionary) -> bool:
	if node.branch_condition.is_empty():
		return true  # 无条件限制
	
	for attr in node.branch_condition.keys():
		var required_value = node.branch_condition[attr]
		var player_value = player_attributes.get(attr, 0)
		
		if player_value < required_value:
			return false
	
	return true

# 获取网状关联依赖
func get_cross_link_dependencies(school_id: String, node_id: String) -> Dictionary:
	var tree = get_skill_tree(school_id)
	if not tree:
		return {}
	
	var node = tree.nodes.get(node_id)
	if not node:
		return {}
	
	return node.cross_link_source

# 验证网状关联条件
func validate_cross_link(school_id: String, node_id: String, unlocked_skills: Dictionary) -> bool:
	var dependencies = get_cross_link_dependencies(school_id, node_id)
	
	if dependencies.is_empty():
		return true  # 无跨武学依赖
	
	# 检查所有依赖的武学节点是否已解锁
	for dep_school in dependencies.keys():
		var dep_node = dependencies[dep_school]
		var dep_tree = get_skill_tree(dep_school)
		
		if not dep_tree:
			return false
		
		# 检查玩家是否已解锁该依赖节点
		var player_school_skills = unlocked_skills.get(dep_school, [])
		if not player_school_skills.has(dep_node):
			return false
	
	return true

# 检查路径完整性（是否存在断裂路径）
func check_path_integrity(school_id: String) -> bool:
	var tree = get_skill_tree(school_id)
	if not tree:
		return false
	
	# 检查所有节点的前置依赖是否存在
	for node_id in tree.nodes.keys():
		var node = tree.nodes[node_id]
		
		for prereq in node.prerequisites:
			if not tree.nodes.has(prereq):
				return false  # 前置节点不存在，路径断裂
	
	return true

# 从JSON加载武学图谱
func load_skill_tree_from_json(json_path: String) -> bool:
	if not FileAccess.file_exists(json_path):
		return false
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		return false
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	# 解析武学图谱数据
	var school_id = data.get("school_id", "")
	var school_name = data.get("school_name", "")
	
	if school_id.is_empty():
		return false
	
	var tree = SkillTree.new(school_id, school_name)
	
	# 解析节点
	var nodes_data = data.get("nodes", [])
	for node_data in nodes_data:
		var node = _parse_skill_node(node_data)
		if node:
			tree.nodes[node.node_id] = node
	
	# 解析主干路径
	tree.main_path = data.get("main_path", [])
	
	# 解析分支路径
	var branches_data = data.get("branches", {})
	for parent_id in branches_data.keys():
		tree.branches[parent_id] = branches_data[parent_id]
	
	# 解析网状关联
	tree.cross_links = data.get("cross_links", [])
	
	# 添加到武学图谱字典
	skill_trees[school_id] = tree
	
	return true

# 解析技能节点数据
func _parse_skill_node(node_data: Dictionary) -> SkillNode:
	var node_id = node_data.get("node_id", "")
	var skill_name = node_data.get("skill_name", "")
	var description = node_data.get("description", "")
	var path_type_str = node_data.get("path_type", "MAIN_PATH")
	var tier = node_data.get("tier", 1)
	
	if node_id.is_empty():
		return null
	
	# 转换路径类型字符串为枚举
	var path_type = PathType.MAIN_PATH
	match path_type_str:
		"MAIN_PATH":
			path_type = PathType.MAIN_PATH
		"BRANCH":
			path_type = PathType.BRANCH
		"CROSS_LINK":
			path_type = PathType.CROSS_LINK
	
	var node = SkillNode.new(node_id, skill_name, description, path_type, tier)
	
	# 解析前置依赖
	node.prerequisites = node_data.get("prerequisites", [])
	
	# 解析分支条件
	node.branch_condition = node_data.get("branch_condition", {})
	
	# 解析跨武学依赖
	node.cross_link_source = node_data.get("cross_link_source", {})
	
	return node

# 获取节点信息
func get_node_info(school_id: String, node_id: String) -> SkillNode:
	var tree = get_skill_tree(school_id)
	if not tree:
		return null
	
	return tree.nodes.get(node_id, null)

# 获取主干路径节点列表
func get_main_path_nodes(school_id: String) -> Array:
	var tree = get_skill_tree(school_id)
	if not tree:
		return []
	
	var nodes = []
	for node_id in tree.main_path:
		var node = tree.nodes.get(node_id)
		if node:
			nodes.append(node)
	
	return nodes