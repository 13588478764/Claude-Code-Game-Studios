## test_skill_tree_manager.gd
## 技能树可视化与交互单元测试 (skill-tree-003)
## 验证技能树管理、路径验证、分支条件、网状关联、节点状态等功能

extends GutTest

var skill_tree: SkillTreeManager

func before_each():
	skill_tree = SkillTreeManager.new()

func after_each():
	skill_tree = null

## 测试：技能树管理器初始化
func test_skill_tree_manager_init():
	assert_ne(skill_tree, null, "技能树管理器应该成功创建")

## 测试：获取默认武学图谱
func test_get_default_skill_tree():
	var huashan = skill_tree.get_skill_tree("huashan_sword")
	assert_ne(huashan, null, "应该存在华山剑法图谱")
	assert_eq(huashan.school_name, "华山剑法", "图谱名称应该正确")

## 测试：获取所有武学图谱
func test_get_all_skill_trees():
	var all_trees = skill_tree.get_all_skill_trees()
	assert_gt(all_trees.size(), 0, "应该至少有1个武学图谱")
	assert_true(all_trees.has("huashan_sword"), "应该包含华山剑法")
	assert_true(all_trees.has("taiji_quan"), "应该包含太极拳")

## 测试：获取不存在的武学图谱
func test_get_nonexistent_skill_tree():
	var result = skill_tree.get_skill_tree("nonexistent_school")
	assert_eq(result, null, "不存在的图谱应该返回null")

## 测试：主干路径节点列表
func test_get_main_path_nodes():
	var nodes = skill_tree.get_main_path_nodes("huashan_sword")
	assert_gt(nodes.size(), 0, "主干路径应该有节点")
	assert_eq(nodes[0].node_id, "ci", "第一个节点应该是刺")

## 测试：获取不存在图谱的主干节点
func test_get_main_path_nodes_nonexistent():
	var nodes = skill_tree.get_main_path_nodes("nonexistent")
	assert_eq(nodes.size(), 0, "不存在的图谱应该返回空数组")

## 测试：获取节点信息
func test_get_node_info():
	var node = skill_tree.get_node_info("huashan_sword", "ci")
	assert_ne(node, null, "节点信息应该存在")
	assert_eq(node.skill_name, "刺", "节点名称应该正确")
	assert_eq(node.tier, 1, "节点品阶应该为1")

## 测试：获取不存在的节点信息
func test_get_nonexistent_node_info():
	var node = skill_tree.get_node_info("huashan_sword", "nonexistent_node")
	assert_eq(node, null, "不存在的节点应该返回null")

## 测试：主干路径验证 - 有效
func test_validate_main_path_valid():
	var result = skill_tree.validate_main_path("huashan_sword")
	assert_true(result, "华山剑法主干路径应该有效")

## 测试：主干路径验证 - 不存在的图谱
func test_validate_main_path_nonexistent():
	var result = skill_tree.validate_main_path("nonexistent")
	assert_false(result, "不存在的图谱应该验证失败")

## 测试：太极拳主干路径验证
func test_validate_taiji_main_path():
	var result = skill_tree.validate_main_path("taiji_quan")
	assert_true(result, "太极拳主干路径应该有效")

## 测试：获取分支选项
func test_get_branch_options():
	var options = skill_tree.get_branch_options("huashan_sword", "pi")
	assert_eq(options.size(), 2, "应该有2个分支选项")

## 测试：获取不存在节点的分支选项
func test_get_branch_options_nonexistent_node():
	var options = skill_tree.get_branch_options("huashan_sword", "nonexistent")
	assert_eq(options.size(), 0, "不存在的节点应该没有分支选项")

## 测试：获取不存在图谱的分支选项
func test_get_branch_options_nonexistent_tree():
	var options = skill_tree.get_branch_options("nonexistent", "any_node")
	assert_eq(options.size(), 0, "不存在的图谱应该返回空数组")

## 测试：分支条件验证 - 通过（力道满足）
func test_validate_branch_condition_str_pass():
	var zhong_pi = skill_tree.get_node_info("huashan_sword", "zhong_pi")
	var player_attrs = {"STR": 15, "AGI": 5}
	
	var result = skill_tree.validate_branch_condition(zhong_pi, player_attrs)
	assert_true(result, "力道15应该满足条件(需要10)")

## 测试：分支条件验证 - 不通过（力道不足）
func test_validate_branch_condition_str_fail():
	var zhong_pi = skill_tree.get_node_info("huashan_sword", "zhong_pi")
	var player_attrs = {"STR": 5, "AGI": 15}
	
	var result = skill_tree.validate_branch_condition(zhong_pi, player_attrs)
	assert_false(result, "力道5应该不满足条件(需要10)")

## 测试：分支条件验证 - 无条件限制
func test_validate_branch_condition_no_condition():
	var ci = skill_tree.get_node_info("huashan_sword", "ci")
	var player_attrs = {"STR": 0}
	
	var result = skill_tree.validate_branch_condition(ci, player_attrs)
	assert_true(result, "无条件限制的节点应该始终通过")

## 测试：分支条件验证 - 空属性
func test_validate_branch_condition_empty_attrs():
	var zhong_pi = skill_tree.get_node_info("huashan_sword", "zhong_pi")
	var player_attrs = {}
	
	var result = skill_tree.validate_branch_condition(zhong_pi, player_attrs)
	assert_false(result, "空属性应该不满足条件")

## 测试：身法分支条件验证 - 通过
func test_validate_branch_condition_agi_pass():
	var kuai_pi = skill_tree.get_node_info("huashan_sword", "kuai_pi")
	var player_attrs = {"AGI": 12, "STR": 3}
	
	var result = skill_tree.validate_branch_condition(kuai_pi, player_attrs)
	assert_true(result, "身法12应该满足条件(需要10)")

## 测试：网状关联依赖获取
func test_get_cross_link_dependencies():
	var deps = skill_tree.get_cross_link_dependencies("qinna_shou", "fan_guan_jie")
	assert_true(deps.has("taiji_quan"), "应该依赖太极拳")
	assert_eq(deps["taiji_quan"], "jie_li", "应该依赖借力节点")

## 测试：网状关联依赖 - 不存在的图谱
func test_get_cross_link_dependencies_nonexistent_tree():
	var deps = skill_tree.get_cross_link_dependencies("nonexistent", "any_node")
	assert_true(deps.is_empty(), "不存在的图谱应该返回空字典")

## 测试：网状关联依赖 - 不存在的节点
func test_get_cross_link_dependencies_nonexistent_node():
	var deps = skill_tree.get_cross_link_dependencies("huashan_sword", "nonexistent")
	assert_true(deps.is_empty(), "不存在的节点应该返回空字典")

## 测试：网状关联验证 - 通过
func test_validate_cross_link_pass():
	var unlocked = {
		"taiji_quan": ["jie_li"]
	}
	
	var result = skill_tree.validate_cross_link("qinna_shou", "fan_guan_jie", unlocked)
	assert_true(result, "已解锁借力应该验证通过")

## 测试：网状关联验证 - 未通过（依赖未解锁）
func test_validate_cross_link_fail():
	var unlocked = {
		"taiji_quan": []
	}
	
	var result = skill_tree.validate_cross_link("qinna_shou", "fan_guan_jie", unlocked)
	assert_false(result, "未解锁借力应该验证失败")

## 测试：网状关联验证 - 无依赖
func test_validate_cross_link_no_dependency():
	var unlocked = {}
	
	var result = skill_tree.validate_cross_link("huashan_sword", "ci", unlocked)
	assert_true(result, "无依赖的节点应该验证通过")

## 测试：路径完整性 - 有效
func test_check_path_integrity_valid():
	var result = skill_tree.check_path_integrity("huashan_sword")
	assert_true(result, "华山剑法路径应该完整")

## 测试：路径完整性 - 不存在的图谱
func test_check_path_integrity_nonexistent():
	var result = skill_tree.check_path_integrity("nonexistent")
	assert_false(result, "不存在的图谱应该验证失败")

## 测试：添加新的武学图谱
func test_add_skill_tree():
	var new_tree = SkillTreeManager.SkillTree.new("new_school", "新武学")
	new_tree.main_path = ["basic_move"]
	var basic = SkillTreeManager.SkillTreeNode.new("basic_move", "基础招式", "基础招式", SkillTreeManager.PathType.MAIN_PATH, 1)
	new_tree.nodes["basic_move"] = basic
	
	skill_tree.add_skill_tree(new_tree)
	
	var retrieved = skill_tree.get_skill_tree("new_school")
	assert_ne(retrieved, null, "新添加的图谱应该可以获取")
	assert_eq(retrieved.school_name, "新武学", "图谱名称应该正确")

## 测试：节点状态枚举值
func test_node_status_enum():
	assert_eq(SkillTreeManager.NodeStatus.LOCKED, 0, "LOCKED状态应该为0")
	assert_eq(SkillTreeManager.NodeStatus.AVAILABLE, 1, "AVAILABLE状态应该为1")
	assert_eq(SkillTreeManager.NodeStatus.UNLOCKED, 2, "UNLOCKED状态应该为2")
	assert_eq(SkillTreeManager.NodeStatus.ACTIVE, 3, "ACTIVE状态应该为3")

## 测试：路径类型枚举值
func test_path_type_enum():
	assert_eq(SkillTreeManager.PathType.MAIN_PATH, 0, "MAIN_PATH应该为0")
	assert_eq(SkillTreeManager.PathType.BRANCH, 1, "BRANCH应该为1")
	assert_eq(SkillTreeManager.PathType.CROSS_LINK, 2, "CROSS_LINK应该为2")

## 测试：节点数据结构
func test_skill_tree_node_structure():
	var node = SkillTreeManager.SkillTreeNode.new("test", "测试招式", "描述", SkillTreeManager.PathType.MAIN_PATH, 2)
	assert_eq(node.node_id, "test", "节点ID应该正确")
	assert_eq(node.status, SkillTreeManager.NodeStatus.LOCKED, "初始状态应该为LOCKED")
	assert_eq(node.prerequisites.size(), 0, "初始前置依赖应该为空")

## 测试：图谱数据结构
func test_skill_tree_structure():
	var tree = SkillTreeManager.SkillTree.new("test_school", "测试武学")
	assert_eq(tree.school_id, "test_school", "图谱ID应该正确")
	assert_true(tree.main_path.is_empty(), "初始主干路径应该为空")
	assert_true(tree.branches.is_empty(), "初始分支应该为空")

## 测试：擒拿手图谱网状关联
func test_qinna_cross_link_structure():
	var qinna = skill_tree.get_skill_tree("qinna_shou")
	assert_ne(qinna, null, "擒拿手图谱应该存在")
	assert_gt(qinna.cross_links.size(), 0, "应该有网状关联")
	assert_eq(qinna.cross_links[0].from_school, "taiji_quan", "应该来自太极拳")
	assert_eq(qinna.cross_links[0].to_school, "qinna_shou", "应该指向擒拿手")

## 测试：华山剑法节点前置依赖
func test_huashan_prerequisites():
	var liao = skill_tree.get_node_info("huashan_sword", "liao")
	assert_true(liao.prerequisites.has("ci"), "撩应该依赖刺")
	
	var pi = skill_tree.get_node_info("huashan_sword", "pi")
	assert_true(pi.prerequisites.has("liao"), "劈应该依赖撩")

## 测试：循环依赖检测 - 无循环
func test_no_circular_dependency():
	var result = skill_tree.validate_main_path("huashan_sword")
	assert_true(result, "华山剑法不应该有循环依赖")

## 测试：获取太极拳节点信息
func test_get_taiji_node_info():
	var jie_li = skill_tree.get_node_info("taiji_quan", "jie_li")
	assert_ne(jie_li, null, "借力节点应该存在")
	assert_eq(jie_li.skill_name, "借力", "节点名称应该正确")
	assert_eq(jie_li.path_type, SkillTreeManager.PathType.MAIN_PATH, "路径类型应该是主线")
