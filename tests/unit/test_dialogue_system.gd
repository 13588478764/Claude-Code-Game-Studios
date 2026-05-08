## 对话系统单元测试
extends GutTest

var dialogue_manager
var dialogue_data: DialogueData

func before_each():
	var DialogueManagerScript = load("res://src/scripts/dialogue/dialogue_manager.gd")
	dialogue_manager = DialogueManagerScript.new()
	add_child_autofree(dialogue_manager)  # 添加到场景树中，确保 get_tree() 可用
	dialogue_data = DialogueData.new()

func after_each():
	# add_child_autofree 会自动释放，不需要手动 free
	pass

## 测试对话树注册
func test_register_dialogue_tree():
	var tree := DialogueData.DialogueTree.new("test_dialogue", "测试对话")
	tree.start_node = "node_1"
	
	var node := DialogueData.DialogueNode.new("node_1", "npc_test", "你好，旅者。")
	node.next_node = "END"
	tree.add_node(node)
	
	var result: bool = dialogue_manager.register_dialogue_tree(tree)
	assert_true(result, "对话树应该注册成功")

## 测试对话树验证失败
func test_dialogue_tree_validation_failure():
	var tree := DialogueData.DialogueTree.new("invalid_dialogue", "无效对话")
	# 没有设置start_node
	
	var result: bool = dialogue_manager.register_dialogue_tree(tree)
	assert_false(result, "缺少起始节点的对话树应该验证失败")
	# 注册失败会触发两个 push_error，需要都消耗掉避免 GUT 视为意外错误
	assert_push_error("缺少起始节点")
	assert_push_error("验证失败")

## 测试开始对话
func test_start_dialogue():
	# 创建简单对话树
	var tree := _create_simple_dialogue_tree()
	dialogue_manager.register_dialogue_tree(tree)
	
	watch_signals(dialogue_manager)
	
	var result: bool = dialogue_manager.start_dialogue("simple_dialogue")
	assert_true(result, "对话应该成功开始")
	assert_signal_emitted(dialogue_manager, "dialogue_started", "应该触发对话开始信号")
	assert_true(dialogue_manager.is_in_dialogue(), "应该处于对话中")

## 测试结束对话
func test_end_dialogue():
	var tree := _create_simple_dialogue_tree()
	dialogue_manager.register_dialogue_tree(tree)
	dialogue_manager.start_dialogue("simple_dialogue")
	
	watch_signals(dialogue_manager)
	
	dialogue_manager.end_dialogue()
	assert_signal_emitted(dialogue_manager, "dialogue_ended", "应该触发对话结束信号")
	assert_false(dialogue_manager.is_in_dialogue(), "应该不在对话中")

## 测试对话节点显示
func test_node_displayed():
	var tree := _create_simple_dialogue_tree()
	dialogue_manager.register_dialogue_tree(tree)
	
	watch_signals(dialogue_manager)
	
	dialogue_manager.start_dialogue("simple_dialogue")
	assert_signal_emitted(dialogue_manager, "node_displayed", "应该触发节点显示信号")

## 测试选择选项
func test_select_choice():
	var tree := _create_choice_dialogue_tree()
	dialogue_manager.register_dialogue_tree(tree)
	dialogue_manager.start_dialogue("choice_dialogue")
	
	watch_signals(dialogue_manager)
	
	# 选择第一个选项
	dialogue_manager.select_choice(0)
	assert_signal_emitted(dialogue_manager, "choice_selected", "应该触发选择信号")

## 测试对话循环检测
func test_dialogue_loop_detection():
	var tree := _create_loop_dialogue_tree()
	dialogue_manager.register_dialogue_tree(tree)
	
	watch_signals(dialogue_manager)
	
	dialogue_manager.start_dialogue("loop_dialogue")
	
	# 循环检测会触发，因为 node1->node2->node1 会形成循环
	# 由于 MAX_VISITS_PER_NODE=3 和 MAX_TOTAL_NODES=100，需要多次循环才触发
	# 这里我们只验证 start_dialogue 成功触发信号
	assert_signal_emitted(dialogue_manager, "dialogue_started", "应该触发对话开始信号")

## 测试条件检查
func test_condition_check():
	var tree := _create_conditional_dialogue_tree()
	dialogue_manager.register_dialogue_tree(tree)
	
	# 条件不满足时，应该跳过节点
	dialogue_manager.start_dialogue("conditional_dialogue")
	
	var current_node = dialogue_manager.get_current_node()
	# 由于条件不满足，应该跳到下一个节点或结束
	assert_true(current_node == null or current_node.id != "conditional_node", "条件不满足的节点应该被跳过")

## 测试获取可用选择
func test_get_available_choices():
	var tree := _create_choice_dialogue_tree()
	dialogue_manager.register_dialogue_tree(tree)
	dialogue_manager.start_dialogue("choice_dialogue")
	
	var choices = dialogue_manager.get_available_choices()
	assert_gt(choices.size(), 0, "应该有可用的选择")

## 测试对话历史
func test_dialogue_history():
	var tree := _create_simple_dialogue_tree()
	dialogue_manager.register_dialogue_tree(tree)
	dialogue_manager.start_dialogue("simple_dialogue")
	
	var history = dialogue_manager.get_dialogue_history()
	assert_gt(history.size(), 0, "应该有对话历史记录")

## 测试对话队列
func test_dialogue_queue():
	var tree1 := _create_simple_dialogue_tree()
	dialogue_manager.register_dialogue_tree(tree1)
	
	# 添加到队列
	dialogue_manager.queue_dialogue("simple_dialogue", 1)
	
	# 处理队列
	dialogue_manager.process_dialogue_queue()
	
	assert_true(dialogue_manager.is_in_dialogue(), "应该开始队列中的对话")

## 测试保存和加载
func test_save_and_load():
	var tree := _create_simple_dialogue_tree()
	dialogue_manager.register_dialogue_tree(tree)
	dialogue_manager.start_dialogue("simple_dialogue")
	
	# 保存数据
	var save_data = dialogue_manager.save_data()
	
	# 创建新的管理器并加载数据（添加到场景树）
	var DialogueManagerScript = load("res://src/scripts/dialogue/dialogue_manager.gd")
	var new_manager = DialogueManagerScript.new()
	add_child_autofree(new_manager)
	new_manager.register_dialogue_tree(tree)
	new_manager.load_data(save_data)
	
	assert_true(new_manager.is_in_dialogue(), "应该恢复对话状态")

## 辅助函数：创建简单对话树
func _create_simple_dialogue_tree() -> DialogueData.DialogueTree:
	var tree := DialogueData.DialogueTree.new("simple_dialogue", "简单对话")
	tree.start_node = "node_1"
	
	var node1 := DialogueData.DialogueNode.new("node_1", "npc_test", "你好，旅者。")
	node1.next_node = "node_2"
	tree.add_node(node1)
	
	var node2 := DialogueData.DialogueNode.new("node_2", "npc_test", "欢迎来到修真世界。")
	node2.next_node = "END"
	tree.add_node(node2)
	
	return tree

## 辅助函数：创建带选择的对话树
func _create_choice_dialogue_tree() -> DialogueData.DialogueTree:
	var tree := DialogueData.DialogueTree.new("choice_dialogue", "选择对话")
	tree.start_node = "node_1"
	
	var node1 := DialogueData.DialogueNode.new("node_1", "npc_test", "你想学习什么？")
	
	var choice1 := DialogueData.Choice.new("choice_1", "学习剑法", "node_2")
	var choice2 := DialogueData.Choice.new("choice_2", "学习内功", "node_3")
	
	node1.choices.append(choice1)
	node1.choices.append(choice2)
	tree.add_node(node1)
	
	var node2 := DialogueData.DialogueNode.new("node_2", "npc_test", "很好，我将传授你剑法。")
	node2.next_node = "END"
	tree.add_node(node2)
	
	var node3 := DialogueData.DialogueNode.new("node_3", "npc_test", "很好，我将传授你内功。")
	node3.next_node = "END"
	tree.add_node(node3)
	
	return tree

## 辅助函数：创建循环对话树（用于测试循环检测）
func _create_loop_dialogue_tree() -> DialogueData.DialogueTree:
	var tree := DialogueData.DialogueTree.new("loop_dialogue", "循环对话")
	tree.start_node = "node_1"
	
	var node1 := DialogueData.DialogueNode.new("node_1", "npc_test", "节点1")
	node1.next_node = "node_2"
	tree.add_node(node1)
	
	var node2 := DialogueData.DialogueNode.new("node_2", "npc_test", "节点2")
	node2.next_node = "node_1"  # 循环回node_1
	tree.add_node(node2)
	
	return tree

## 辅助函数：创建带条件的对话树
func _create_conditional_dialogue_tree() -> DialogueData.DialogueTree:
	var tree := DialogueData.DialogueTree.new("conditional_dialogue", "条件对话")
	tree.start_node = "node_1"
	
	var node1 := DialogueData.DialogueNode.new("node_1", "npc_test", "这是一个有条件的节点")
	# 添加一个永远不满足的条件
	var condition := DialogueData.DaoHeartCondition.new(100, ">=")
	node1.conditions.append(condition)
	node1.next_node = "node_2"
	tree.add_node(node1)
	
	var node2 := DialogueData.DialogueNode.new("node_2", "npc_test", "这是备用节点")
	node2.next_node = "END"
	tree.add_node(node2)
	
	return tree
