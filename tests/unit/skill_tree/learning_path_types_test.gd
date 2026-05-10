extends "res://addons/gut/test.gd"

class_name LearningPathTypesTest

# 测试学习路径类型
# 覆盖线性主干、分支专精和网状关联三种路径类型

var skill_tree_manager: SkillTreeManager

func before_each():
	# 初始化技能树管理器
	skill_tree_manager = load("res://src/scripts/skill_tree/skill_tree_manager.gd").new()

func after_each():
	# 清理测试资源
	skill_tree_manager = null

# 测试线性主干路径
func test_main_path_implementation():
	# Given: 华山剑法武学图谱包含刺→撩→劈→崩的线性主干
	var huashan_tree = skill_tree_manager.get_skill_tree("huashan_sword")
	
	# When: 系统加载武学图谱数据
	assert_not_null(huashan_tree, "华山剑法图谱应存在")
	
	# Then: 正确识别线性主干路径，验证顺序依赖关系
	assert_eq(huashan_tree.main_path.size(), 4, "主干路径应包含4个节点")
	assert_eq(huashan_tree.main_path[0], "ci", "第一个节点应为刺")
	assert_eq(huashan_tree.main_path[1], "liao", "第二个节点应为撩")
	assert_eq(huashan_tree.main_path[2], "pi", "第三个节点应为劈")
	assert_eq(huashan_tree.main_path[3], "beng", "第四个节点应为崩")
	
	# 验证顺序依赖关系
	var ci_node = huashan_tree.nodes["ci"]
	var liao_node = huashan_tree.nodes["liao"]
	var pi_node = huashan_tree.nodes["pi"]
	var beng_node = huashan_tree.nodes["beng"]
	
	assert_true(ci_node.prerequisites.is_empty(), "刺节点不应有前置依赖")
	assert_true(liao_node.prerequisites.has("ci"), "撩节点应依赖刺")
	assert_true(pi_node.prerequisites.has("liao"), "劈节点应依赖撩")
	assert_true(beng_node.prerequisites.has("pi"), "崩节点应依赖劈")
	
	# 验证主干路径有效性
	var is_valid = skill_tree_manager.validate_main_path("huashan_sword")
	assert_true(is_valid, "华山剑法主干路径应有效")

# 测试分支专精路径
func test_branch_path_implementation():
	# Given: 劈字诀节点后分叉为重劈和快劈两个分支
	var huashan_tree = skill_tree_manager.get_skill_tree("huashan_sword")
	
	# When: 系统处理分支节点
	var branch_options = skill_tree_manager.get_branch_options("huashan_sword", "pi")
	
	# Then: 正确识别分支选项，记录分支条件
	assert_eq(branch_options.size(), 2, "劈节点应有2个分支选项")
	
	var zhong_pi_found = false
	var kuai_pi_found = false
	
	for branch_node in branch_options:
		if branch_node.node_id == "zhong_pi":
			zhong_pi_found = true
			assert_eq(branch_node.path_type, SkillTreeManager.PathType.BRANCH, "重劈应为分支类型")
			assert_true(branch_node.branch_condition.has("STR"), "重劈应有力道条件")
			assert_eq(branch_node.branch_condition["STR"], 10, "重劈需要力道≥10")
		elif branch_node.node_id == "kuai_pi":
			kuai_pi_found = true
			assert_eq(branch_node.path_type, SkillTreeManager.PathType.BRANCH, "快劈应为分支类型")
			assert_true(branch_node.branch_condition.has("AGI"), "快劈应有身法条件")
			assert_eq(branch_node.branch_condition["AGI"], 10, "快劈需要身法≥10")
	
	assert_true(zhong_pi_found, "应找到重劈分支")
	assert_true(kuai_pi_found, "应找到快劈分支")

# 测试网状关联路径
func test_cross_link_path_implementation():
	# Given: 太极拳的"借力"节点关联到擒拿手的"反关节技"节点
	var qinna_tree = skill_tree_manager.get_skill_tree("qinna_shou")
	
	# When: 系统处理跨武学关联
	var fan_guan_jie_node = qinna_tree.nodes["fan_guan_jie"]
	
	# Then: 正确建立网状关联，验证跨武学依赖
	assert_not_null(fan_guan_jie_node, "反关节技节点应存在")
	assert_eq(fan_guan_jie_node.path_type, SkillTreeManager.PathType.CROSS_LINK, "反关节技应为网状关联类型")
	assert_false(fan_guan_jie_node.cross_link_source.is_empty(), "反关节技应有跨武学依赖")
	assert_true(fan_guan_jie_node.cross_link_source.has("taiji_quan"), "反关节技应依赖太极拳")
	assert_eq(fan_guan_jie_node.cross_link_source["taiji_quan"], "jie_li", "反关节技应依赖太极拳的借力节点")
	
	# 验证网状关联条件
	var unlocked_skills = {"taiji_quan": ["jie_li"]}
	var is_valid = skill_tree_manager.validate_cross_link("qinna_shou", "fan_guan_jie", unlocked_skills)
	assert_true(is_valid, "当太极拳借力已解锁时，反关节技应可解锁")
	
	# 测试未解锁依赖的情况
	var empty_unlocked = {}
	var is_invalid = skill_tree_manager.validate_cross_link("qinna_shou", "fan_guan_jie", empty_unlocked)
	assert_false(is_invalid, "当太极拳借力未解锁时，反关节技不应可解锁")

# 测试模块化武学图谱
func test_modular_skill_tree_structure():
	# Given: 多个武学流派的独立图谱配置文件
	var all_trees = skill_tree_manager.get_all_skill_trees()
	
	# When: 系统加载所有武学图谱
	# Then: 正确解析每个武学流派的图谱结构，支持独立管理
	assert_true(all_trees.has("huashan_sword"), "应包含华山剑法图谱")
	assert_true(all_trees.has("taiji_quan"), "应包含太极拳图谱")
	assert_true(all_trees.has("qinna_shou"), "应包含擒拿手图谱")
	
	# 验证每个图谱的独立性
	var huashan = all_trees["huashan_sword"]
	var taiji = all_trees["taiji_quan"]
	var qinna = all_trees["qinna_shou"]
	
	assert_eq(huashan.school_id, "huashan_sword", "华山剑法ID应正确")
	assert_eq(taiji.school_id, "taiji_quan", "太极拳ID应正确")
	assert_eq(qinna.school_id, "qinna_shou", "擒拿手ID应正确")
	
	assert_false(huashan.nodes.is_empty(), "华山剑法应有节点")
	assert_false(taiji.nodes.is_empty(), "太极拳应有节点")
	assert_false(qinna.nodes.is_empty(), "擒拿手应有节点")

# 边缘情况测试：循环依赖检测
func test_edge_case_circular_dependency():
	# Given: 创建一个包含循环依赖的图谱
	var test_tree = SkillTreeManager.SkillTree.new("test_circular", "测试循环依赖")
	
	var node_a = SkillTreeManager.SkillTreeNode.new("a", "节点A", "测试节点A", SkillTreeManager.PathType.MAIN_PATH)
	var node_b = SkillTreeManager.SkillTreeNode.new("b", "节点B", "测试节点B", SkillTreeManager.PathType.MAIN_PATH)
	var node_c = SkillTreeManager.SkillTreeNode.new("c", "节点C", "测试节点C", SkillTreeManager.PathType.MAIN_PATH)
	
	# 创建循环依赖：A → B → C → A
	node_b.prerequisites = ["a"]
	node_c.prerequisites = ["b"]
	node_a.prerequisites = ["c"]  # 循环依赖
	
	test_tree.nodes["a"] = node_a
	test_tree.nodes["b"] = node_b
	test_tree.nodes["c"] = node_c
	test_tree.main_path = ["a", "b", "c"]
	
	skill_tree_manager.add_skill_tree(test_tree)
	
	# When: 验证主干路径
	var is_valid = skill_tree_manager.validate_main_path("test_circular")
	
	# Then: 应检测到循环依赖
	assert_false(is_valid, "应检测到循环依赖并返回false")

# 边缘情况测试：断裂路径检测
func test_edge_case_broken_path():
	# Given: 创建一个包含断裂路径的图谱
	var test_tree = SkillTreeManager.SkillTree.new("test_broken", "测试断裂路径")
	
	var node_a = SkillTreeManager.SkillTreeNode.new("a", "节点A", "测试节点A", SkillTreeManager.PathType.MAIN_PATH)
	var node_b = SkillTreeManager.SkillTreeNode.new("b", "节点B", "测试节点B", SkillTreeManager.PathType.MAIN_PATH)
	
	# 节点B依赖不存在的节点C
	node_b.prerequisites = ["c"]
	
	test_tree.nodes["a"] = node_a
	test_tree.nodes["b"] = node_b
	test_tree.main_path = ["a", "b"]
	
	skill_tree_manager.add_skill_tree(test_tree)
	
	# When: 检查路径完整性
	var is_intact = skill_tree_manager.check_path_integrity("test_broken")
	
	# Then: 应检测到断裂路径
	assert_false(is_intact, "应检测到断裂路径并返回false")

# 边缘情况测试：多分支冲突
func test_edge_case_multiple_branch_conflict():
	# Given: 玩家同时满足多个分支条件
	var player_attributes = {"STR": 15, "AGI": 15}
	
	var branch_options = skill_tree_manager.get_branch_options("huashan_sword", "pi")
	
	# When: 验证每个分支条件
	var valid_branches = []
	for branch_node in branch_options:
		if skill_tree_manager.validate_branch_condition(branch_node, player_attributes):
			valid_branches.append(branch_node.node_id)
	
	# Then: 应允许玩家选择任意一个分支
	assert_eq(valid_branches.size(), 2, "玩家应能选择两个分支中的任意一个")
	assert_true(valid_branches.has("zhong_pi"), "重劈应可选")
	assert_true(valid_branches.has("kuai_pi"), "快劈应可选")

# 边缘情况测试：无效分支条件
func test_edge_case_invalid_branch_condition():
	# Given: 玩家不满足任何分支条件
	var player_attributes = {"STR": 5, "AGI": 5}
	
	var branch_options = skill_tree_manager.get_branch_options("huashan_sword", "pi")
	
	# When: 验证每个分支条件
	var valid_branches = []
	for branch_node in branch_options:
		if skill_tree_manager.validate_branch_condition(branch_node, player_attributes):
			valid_branches.append(branch_node.node_id)
	
	# Then: 不应有可选分支
	assert_eq(valid_branches.size(), 0, "玩家不应能选择任何分支")

# 边缘情况测试：孤立节点检测
func test_edge_case_isolated_node():
	# Given: 创建一个包含孤立节点的图谱
	var test_tree = SkillTreeManager.SkillTree.new("test_isolated", "测试孤立节点")
	
	var node_a = SkillTreeManager.SkillTreeNode.new("a", "节点A", "测试节点A", SkillTreeManager.PathType.MAIN_PATH)
	var node_b = SkillTreeManager.SkillTreeNode.new("b", "节点B", "测试节点B", SkillTreeManager.PathType.MAIN_PATH)
	var node_isolated = SkillTreeManager.SkillTreeNode.new("isolated", "孤立节点", "测试孤立节点", SkillTreeManager.PathType.MAIN_PATH)
	
	node_b.prerequisites = ["a"]
	# node_isolated 没有前置依赖，也不在主干路径中
	
	test_tree.nodes["a"] = node_a
	test_tree.nodes["b"] = node_b
	test_tree.nodes["isolated"] = node_isolated
	test_tree.main_path = ["a", "b"]
	
	skill_tree_manager.add_skill_tree(test_tree)
	
	# When: 检查路径完整性
	var is_intact = skill_tree_manager.check_path_integrity("test_isolated")
	
	# Then: 路径应完整（孤立节点不影响主干路径）
	assert_true(is_intact, "孤立节点不应影响主干路径的完整性")

# 测试获取主干路径节点列表
func test_get_main_path_nodes():
	# Given: 华山剑法图谱
	# When: 获取主干路径节点列表
	var main_path_nodes = skill_tree_manager.get_main_path_nodes("huashan_sword")
	
	# Then: 应返回正确的节点列表
	assert_eq(main_path_nodes.size(), 4, "应返回4个主干路径节点")
	assert_eq(main_path_nodes[0].node_id, "ci", "第一个节点应为刺")
	assert_eq(main_path_nodes[1].node_id, "liao", "第二个节点应为撩")
	assert_eq(main_path_nodes[2].node_id, "pi", "第三个节点应为劈")
	assert_eq(main_path_nodes[3].node_id, "beng", "第四个节点应为崩")

# 测试获取节点信息
func test_get_node_info():
	# Given: 华山剑法图谱
	# When: 获取特定节点信息
	var ci_node = skill_tree_manager.get_node_info("huashan_sword", "ci")
	
	# Then: 应返回正确的节点信息
	assert_not_null(ci_node, "应返回刺节点")
	assert_eq(ci_node.skill_name, "刺", "节点名称应为刺")
	assert_eq(ci_node.path_type, SkillTreeManager.PathType.MAIN_PATH, "应为主干路径类型")
	assert_eq(ci_node.tier, 1, "品阶应为1（黄阶）")