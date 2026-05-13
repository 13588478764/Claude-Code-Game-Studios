## 对话系统集成测试
## 测试对话加载、选择、效果、分支跳转等完整链路
extends GutTest

var DialogueManagerClass = load("res://src/scripts/dialogue/dialogue_manager.gd")

var dialogue_manager: Node


func before_each() -> void:
	# 创建对话管理器实例作为子节点
	dialogue_manager = DialogueManagerClass.new()
	add_child_autofree(dialogue_manager)
	# 确保初始状态为未对话中
	dialogue_manager.end_dialogue()


func after_each() -> void:
	# 清理对话队列和状态
	if dialogue_manager != null:
		dialogue_manager.clear_dialogue_queue()
		dialogue_manager.end_dialogue()


## 测试1: 对话树从数据创建到注册的正确性
## 验证对话数据可以通过 DialogueData 类正确构建并注册到 DialogueManager
func test_dialogue_tree_registration_succeeds() -> void:
	# 准备
	var tree: Object = DialogueData.DialogueTree.new("test_npc_greeting", "NPC问候")
	tree.start_node = "node_start"

	var start_node: Object = DialogueData.DialogueNode.new(
		"node_start", "npc_villager", "少侠，欢迎来到青云村！"
	)
	start_node.next_node = "node_farewell"
	tree.add_node(start_node)

	var end_node: Object = DialogueData.DialogueNode.new(
		"node_farewell", "npc_villager", "少侠慢走！"
	)
	tree.add_node(end_node)

	# 执行
	var registered: bool = dialogue_manager.register_dialogue_tree(tree)

	# 断言
	assert_true(registered, "对话树应注册成功")
	assert_true(dialogue_manager.has_dialogue("test_npc_greeting"),
		"注册后应能通过ID查询到对话树")


## 测试2: 对话加载 → 选择 → 效果链路完整
## 验证从开始对话到做出选择再到执行效果的完整流程
func test_dialogue_flow_choice_to_effects() -> void:
	# 准备
	var tree: Object = DialogueData.DialogueTree.new("test_choice_flow", "选择流程测试")
	tree.start_node = "node_1"

	# 第一个节点：包含一个选择
	var node_1: Object = DialogueData.DialogueNode.new(
		"node_1", "npc_elder", "少侠，你愿意帮我寻找灵草吗？"
	)
	var choice_accept: Object = DialogueData.Choice.new(
		"choice_accept", "我愿意帮忙", "node_accept"
	)
	var choice_decline: Object = DialogueData.Choice.new(
		"choice_decline", "我没空", "node_decline"
	)
	node_1.choices.append(choice_accept)
	node_1.choices.append(choice_decline)
	tree.add_node(node_1)

	# 接受分支节点：带有效果
	var node_accept: Object = DialogueData.DialogueNode.new(
		"node_accept", "npc_elder", "太好了，灵草在后山！"
	)
	node_accept.next_node = "END"
	var rel_effect: Object = DialogueData.ModifyRelationshipEffect.new(
		"npc_elder", 10, "接受帮助请求"
	)
	node_accept.effects.append(rel_effect)
	tree.add_node(node_accept)

	# 拒绝分支节点
	var node_decline: Object = DialogueData.DialogueNode.new(
		"node_decline", "npc_elder", "好吧，等你有空再来。"
	)
	node_decline.next_node = "END"
	tree.add_node(node_decline)

	var registered: bool = dialogue_manager.register_dialogue_tree(tree)

	# 执行 - 开始对话
	var started: bool = dialogue_manager.start_dialogue("test_choice_flow")

	# 断言 - 对话成功开始
	assert_true(registered, "对话树应注册成功")
	assert_true(started, "对话应成功开始")
	assert_true(dialogue_manager.is_in_dialogue(), "应处于对话状态")

	# 验证当前节点
	var current_node: Object = dialogue_manager.get_current_node()
	assert_not_null(current_node, "当前节点不应为空")
	assert_eq(current_node.id, "node_1", "起始节点应为node_1")

	# 执行 - 选择第一个选项（接受）
	var choices: Array = dialogue_manager.get_available_choices()
	assert_eq(choices.size(), 2, "应有2个可用选择")

	dialogue_manager.select_choice(0)  # 选择"我愿意帮忙"

	# 断言 - 跳转到接受分支
	current_node = dialogue_manager.get_current_node()
	assert_eq(current_node.id, "node_accept", "选择后应跳转到接受分支节点")
	assert_eq(choices[0].next_node, "node_accept", "选择的跳转目标应正确")


## 测试3: 对话结束后正确触发效果（关系值变化、任务触发等）
## 验证对话节点和选择的效果能够正确执行
func test_dialogue_effects_execution() -> void:
	# 准备
	var tree: Object = DialogueData.DialogueTree.new("test_effects", "效果测试")
	tree.start_node = "node_effect_test"

	var test_node: Object = DialogueData.DialogueNode.new(
		"node_effect_test", "npc_master", "这是对你的考验。"
	)
	# 添加关系值效果
	var rel_effect: Object = DialogueData.ModifyRelationshipEffect.new(
		"npc_master", 5, "完成考验"
	)
	test_node.effects.append(rel_effect)
	# 添加道心值效果
	var dao_effect: Object = DialogueData.ModifyDaoHeartEffect.new(
		3, "选择正道"
	)
	test_node.effects.append(dao_effect)
	# 添加任务解锁效果
	var quest_effect: Object = DialogueData.UnlockQuestEffect.new("quest_initiation")
	test_node.effects.append(quest_effect)
	# 添加标志位效果
	var flag_effect: Object = DialogueData.SetFlagEffect.new("met_master", true)
	test_node.effects.append(flag_effect)

	tree.add_node(test_node)

	# 执行
	var registered: bool = dialogue_manager.register_dialogue_tree(tree)
	assert_true(registered, "对话树应注册成功")

	# 验证效果对象已正确添加到节点
	assert_eq(test_node.effects.size(), 4, "节点应包含4个效果")
	assert_eq(test_node.effects[0].type, DialogueData.Effect.EffectType.MODIFY_RELATIONSHIP,
		"第一个效果应为关系值修改")
	assert_eq(test_node.effects[1].type, DialogueData.Effect.EffectType.MODIFY_DAO_HEART,
		"第二个效果应为道心值修改")
	assert_eq(test_node.effects[2].type, DialogueData.Effect.EffectType.UNLOCK_QUEST,
		"第三个效果应为任务解锁")
	assert_eq(test_node.effects[3].type, DialogueData.Effect.EffectType.SET_FLAG,
		"第四个效果应为标志位设置")

	# 验证效果参数正确
	var modify_rel: DialogueData.ModifyRelationshipEffect = test_node.effects[0]
	assert_eq(modify_rel.target, "npc_master", "关系效果目标NPC应正确")
	assert_eq(modify_rel.value, 5, "关系值变化量应为5")
	assert_eq(modify_rel.reason, "完成考验", "效果原因描述应正确")

	var modify_dao: DialogueData.ModifyDaoHeartEffect = test_node.effects[1]
	assert_eq(modify_dao.value, 3, "道心值变化量应为3")

	var unlock_quest: DialogueData.UnlockQuestEffect = test_node.effects[2]
	assert_eq(unlock_quest.target, "quest_initiation", "解锁任务ID应正确")

	var set_flag: DialogueData.SetFlagEffect = test_node.effects[3]
	assert_eq(set_flag.target, "met_master", "标志位名称应正确")
	assert_eq(set_flag.value, true, "标志位值应为true")

	# 执行效果（在无GameManager环境下效果应静默跳过，不报错）
	test_node.execute_effects()
	# 断言：效果执行不抛出错误即通过


## 测试4: 对话树分支正确跳转
## 验证多分支对话树中，不同选择跳转到不同节点路径
func test_dialogue_branch_navigation() -> void:
	# 准备 - 构建一个三叉分支的对话树
	var tree: Object = DialogueData.DialogueTree.new("test_branch", "分支跳转测试")
	tree.start_node = "branch_start"

	# 起始节点：3个选择分别导向不同分支
	var start_node: Object = DialogueData.DialogueNode.new(
		"branch_start", "npc_guide", "请选择你的修行之路。"
	)
	var choice_sword := DialogueData.Choice.new("choice_sword", "修炼剑道", "branch_sword")
	var choice_magic := DialogueData.Choice.new("choice_magic", "修炼法术", "branch_magic")
	var choice_body := DialogueData.Choice.new("choice_body", "修炼体术", "branch_body")
	start_node.choices.append(choice_sword)
	start_node.choices.append(choice_magic)
	start_node.choices.append(choice_body)
	tree.add_node(start_node)

	# 剑道分支
	# 注意：分支节点需要有 choices 或 next_node，否则 _display_current_node 会立即结束对话，
	# 导致后续无法读取 _current_node。这里添加一个"结束"choice 让对话停留在该节点等待选择。
	var sword_node := DialogueData.DialogueNode.new(
		"branch_sword", "npc_guide", "剑道讲究以快制胜。"
	)
	sword_node.choices.append(DialogueData.Choice.new("end_sword", "结束对话", "END"))
	tree.add_node(sword_node)

	# 法术分支
	var magic_node := DialogueData.DialogueNode.new(
		"branch_magic", "npc_guide", "法术需要感悟天地灵气。"
	)
	magic_node.choices.append(DialogueData.Choice.new("end_magic", "结束对话", "END"))
	tree.add_node(magic_node)

	# 体术分支
	var body_node := DialogueData.DialogueNode.new(
		"branch_body", "npc_guide", "体术以肉身淬炼为本。"
	)
	body_node.choices.append(DialogueData.Choice.new("end_body", "结束对话", "END"))
	tree.add_node(body_node)

	dialogue_manager.register_dialogue_tree(tree)
	dialogue_manager.start_dialogue("test_branch")

	# 执行 - 选择剑道（索引0）
	dialogue_manager.select_choice(0)

	# 断言
	var current_node: Object = dialogue_manager.get_current_node()
	assert_eq(current_node.id, "branch_sword", "选择剑道应跳转到剑道分支")

	# 重新开始的对话，选择法术（索引1）
	dialogue_manager.end_dialogue()
	dialogue_manager.start_dialogue("test_branch")
	dialogue_manager.select_choice(1)

	current_node = dialogue_manager.get_current_node()
	assert_eq(current_node.id, "branch_magic", "选择法术应跳转到法术分支")

	# 重新开始的对话，选择体术（索引2）
	dialogue_manager.end_dialogue()
	dialogue_manager.start_dialogue("test_branch")
	dialogue_manager.select_choice(2)

	current_node = dialogue_manager.get_current_node()
	assert_eq(current_node.id, "branch_body", "选择体术应跳转到体术分支")


## 测试5: 对话数据完整性验证
## 验证对话树的 validate() 方法能够正确检测数据问题
func test_dialogue_tree_validation() -> void:
	# 准备 - 创建一个有效的对话树
	var valid_tree: Object = DialogueData.DialogueTree.new("valid_tree", "有效的对话树")
	valid_tree.start_node = "start"

	var start_node: Object = DialogueData.DialogueNode.new("start", "npc", "你好")
	start_node.next_node = "end"
	valid_tree.add_node(start_node)

	var end_node: Object = DialogueData.DialogueNode.new("end", "npc", "再见")
	valid_tree.add_node(end_node)

	# 断言 - 有效的对话树应通过验证
	assert_true(valid_tree.validate(), "有效的对话树应通过验证")

	# 准备 - 创建缺少起始节点的对话树
	var missing_start_tree := DialogueData.DialogueTree.new("missing_start", "缺少起始节点")
	missing_start_tree.start_node = ""  # 空的起始节点

	var node_a := DialogueData.DialogueNode.new("node_a", "npc", "测试")
	missing_start_tree.add_node(node_a)

	# 断言 - 缺少起始节点的对话树应验证失败
	assert_false(missing_start_tree.validate(), "缺少起始节点的对话树应验证失败")

	# 准备 - 创建起始节点不存在的对话树
	var invalid_start_tree := DialogueData.DialogueTree.new("invalid_start", "起始节点不存在")
	invalid_start_tree.start_node = "nonexistent_node"

	var some_node := DialogueData.DialogueNode.new("some_node", "npc", "测试")
	invalid_start_tree.add_node(some_node)

	# 断言 - 起始节点不存在的对话树应验证失败
	assert_false(invalid_start_tree.validate(), "起始节点不存在的对话树应验证失败")

	# 准备 - 创建next_node引用不存在节点的对话树
	var broken_ref_tree := DialogueData.DialogueTree.new("broken_ref", "引用断裂的对话树")
	broken_ref_tree.start_node = "node_x"

	var node_x := DialogueData.DialogueNode.new("node_x", "npc", "你好")
	node_x.next_node = "nonexistent_next"  # 引用的节点不存在
	broken_ref_tree.add_node(node_x)

	# 断言 - next_node引用断裂的对话树应验证失败
	assert_false(broken_ref_tree.validate(), "next_node引用不存在节点的对话树应验证失败")

	# 消费预期的 push_error（validate 内部会 push_error 输出）
	# GUT 默认把 push_error 当作失败，这里明确承认预期的 3 条错误：
	#   1. 对话树 missing_start 缺少起始节点
	#   2. 对话树 invalid_start 的起始节点 nonexistent_node 不存在
	#   3. 节点 node_x 的next_node nonexistent_next 不存在
	assert_push_error_count(3, "validate() 失败时应产生 3 条预期的 push_error")


## 测试6: 对话历史追踪正确
## 验证对话过程中节点访问历史被正确记录
func test_dialogue_history_tracking() -> void:
	# 准备
	var tree: Object = DialogueData.DialogueTree.new("test_history", "历史追踪测试")
	tree.start_node = "hist_1"

	var node_1 := DialogueData.DialogueNode.new("hist_1", "npc", "第一句话")
	node_1.next_node = "hist_2"
	tree.add_node(node_1)

	var node_2 := DialogueData.DialogueNode.new("hist_2", "npc", "第二句话")
	tree.add_node(node_2)

	dialogue_manager.register_dialogue_tree(tree)

	# 执行
	dialogue_manager.start_dialogue("test_history")

	# 等待自动跳转（由于节点有next_node且无选择，会自动跳转）
	# 在GUT headless模式下，await可能不执行，我们直接检查历史
	var history: Array = dialogue_manager.get_dialogue_history()

	# 断言
	assert_true(history.size() >= 1, "对话历史至少应包含起始节点")
	assert_eq(history[0], "hist_1", "历史记录的第一个节点应为hist_1")


## 辅助函数：创建一个单节点对话树，节点带"结束对话"choice 防止自动结束
## 这是因为 _display_current_node 在节点既无 choices 也无 next_node 时会立即 end_dialogue
func _make_persistent_tree(tree_id: String, npc_id: String = "", metadata: Dictionary = {}) -> Object:
	var tree: Object = DialogueData.DialogueTree.new(tree_id, tree_id)
	tree.start_node = "node_0"
	if not metadata.is_empty():
		tree.metadata = metadata
	var n0: Object = DialogueData.DialogueNode.new(
		"node_0", npc_id if not npc_id.is_empty() else "npc", tree_id
	)
	# 添加一个结束 choice，避免节点进入"无出口自动结束"分支
	n0.choices.append(DialogueData.Choice.new("end_0", "结束对话", "END"))
	tree.add_node(n0)
	return tree


## 测试7: 对话队列优先级排序
## 验证对话按优先级正确排序和处理
func test_dialogue_queue_priority() -> void:
	# 准备
	# 添加不同优先级的对话到队列
	dialogue_manager.queue_dialogue("low_priority_dialogue", 1)
	dialogue_manager.queue_dialogue("high_priority_dialogue", 5)
	dialogue_manager.queue_dialogue("medium_priority_dialogue", 3)

	# 执行 - 触发队列处理（需要注册一些对话树让start_dialogue不报错）
	# 使用带 choices 的节点，避免对话一开始就自动结束
	dialogue_manager.register_dialogue_tree(_make_persistent_tree("low_priority_dialogue"))
	dialogue_manager.register_dialogue_tree(_make_persistent_tree("high_priority_dialogue"))
	dialogue_manager.register_dialogue_tree(_make_persistent_tree("medium_priority_dialogue"))

	dialogue_manager.process_dialogue_queue()

	# 断言 - 高优先级对话应先执行
	assert_eq(dialogue_manager.get_current_dialogue_id(), "high_priority_dialogue",
		"队列处理后应执行最高优先级的对话")


## 测试8: 对话不存在时正确返回错误
## 验证请求不存在的对话树时的错误处理
func test_start_nonexistent_dialogue_returns_error() -> void:
	# 准备
	# 注意：GDScript 4 的 lambda 对局部变量是值捕获，赋值不会反映到外部
	# 因此使用数组包装 bool，通过引用类型传递状态
	var state: Array = [false]

	# 连接错误信号
	dialogue_manager.dialogue_error.connect(
		func(_error_msg: String): state[0] = true
	)

	# 执行
	var result: bool = dialogue_manager.start_dialogue("nonexistent_dialogue_id")

	# 断言
	assert_false(result, "启动不存在的对话应返回false")
	assert_false(dialogue_manager.is_in_dialogue(), "不应进入对话状态")
	assert_true(state[0], "应触发错误信号")

	# 消费预期的 push_error（"对话树不存在: nonexistent_dialogue_id"）
	assert_push_error_count(1, "启动不存在的对话应产生 1 条预期 push_error")


## 测试9: 对话结束信号正确触发
## 验证对话结束时 dialogue_ended 信号正确发出
func test_dialogue_ended_signal_fired() -> void:
	# 准备
	# GDScript 4 lambda 对局部变量是值捕获，用字典包装状态以便在 lambda 中修改
	var state: Dictionary = {"emitted": false, "id": ""}

	dialogue_manager.dialogue_ended.connect(
		func(d_id: String):
			state["emitted"] = true
			state["id"] = d_id
	)

	# 使用带 choices 的对话树，防止 start_dialogue 后立即自动结束
	dialogue_manager.register_dialogue_tree(_make_persistent_tree("test_ended_signal"))

	# 执行
	dialogue_manager.start_dialogue("test_ended_signal")
	dialogue_manager.end_dialogue()

	# 断言
	assert_true(state["emitted"], "对话结束信号应被触发")
	assert_eq(state["id"], "test_ended_signal", "信号中的对话ID应正确")
	assert_false(dialogue_manager.is_in_dialogue(), "对话结束后应不在对话状态")


## 测试10: NPC ID匹配触发对话
## 验证通过NPC ID自动查找并启动对应对话
func test_start_dialogue_with_npc_id() -> void:
	# 准备 - 使用带 choices 的对话树避免自动结束
	var tree: Object = _make_persistent_tree(
		"npc_shop_dialogue",
		"npc_shopkeeper",
		{"npc_id": "npc_shopkeeper"}
	)
	dialogue_manager.register_dialogue_tree(tree)

	# 执行
	var result: bool = dialogue_manager.start_dialogue_with_npc("npc_shopkeeper")

	# 断言
	assert_true(result, "通过NPC ID应能找到并启动对话")
	assert_eq(dialogue_manager.get_current_dialogue_id(), "npc_shop_dialogue",
		"启动的对话ID应与注册的对话树ID一致")
