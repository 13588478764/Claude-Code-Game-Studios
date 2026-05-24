## NPC对话触发接入集成测试 (s6-04)
## 验证 DialogueManager.start_dialogue_with_npc() 对NPC可调用
extends GutTest

const DialogueManagerScript = preload("res://src/scripts/dialogue/dialogue_manager.gd")

var _dialogue_mgr: Node = null


func before_each() -> void:
	_dialogue_mgr = DialogueManagerScript.new()
	_dialogue_mgr.name = "DialogueManager"
	add_child_autofree(_dialogue_mgr)


## 无对话文件的NPC调用不崩溃，返回false
func test_npc_without_dialogue_returns_false() -> void:
	var result: bool = _dialogue_mgr.start_dialogue_with_npc("nonexistent_npc_xyz")
	assert_false(result)


## has_dialogue 对不存在的ID返回false
func test_has_dialogue_returns_false_for_missing() -> void:
	assert_false(_dialogue_mgr.has_dialogue("does_not_exist"))


## 注册对话树后 has_dialogue 返回 true
func test_has_dialogue_returns_true_after_register() -> void:
	var tree := DialogueData.DialogueTree.new("test_npc_talk", "测试对话")
	tree.start_node = "start"
	tree.metadata = {"npc_id": "test_npc"}
	var node := DialogueData.DialogueNode.new("start", "测试NPC", "你好！")
	tree.add_node(node)

	_dialogue_mgr.register_dialogue_tree(tree)
	assert_true(_dialogue_mgr.has_dialogue("test_npc_talk"))


## start_dialogue_with_npc 通过 metadata.npc_id 匹配
func test_start_dialogue_with_npc_matches_metadata() -> void:
	var tree := DialogueData.DialogueTree.new("yunzhonghe_daily", "云中鹤日常")
	tree.start_node = "start"
	tree.metadata = {"npc_id": "yunzhonghe"}
	var node := DialogueData.DialogueNode.new("start", "云中鹤", "少侠有礼了。")
	tree.add_node(node)

	_dialogue_mgr.register_dialogue_tree(tree)

	var success: bool = _dialogue_mgr.start_dialogue_with_npc("yunzhonghe")
	assert_true(success)
	assert_true(_dialogue_mgr.is_in_dialogue())


## 对话开始信号正确触发
func test_dialogue_started_signal_emitted() -> void:
	var signal_fired: Array = [false]
	var callback := func(_id: String): signal_fired[0] = true
	_dialogue_mgr.dialogue_started.connect(callback)

	var tree := DialogueData.DialogueTree.new("signal_test", "信号测试")
	tree.start_node = "start"
	tree.metadata = {"npc_id": "test_signal_npc"}
	var node := DialogueData.DialogueNode.new("start", "NPC", "测试文本")
	tree.add_node(node)
	_dialogue_mgr.register_dialogue_tree(tree)

	_dialogue_mgr.start_dialogue_with_npc("test_signal_npc")
	assert_true(signal_fired[0])


## 对话中不能开始新对话
func test_cannot_start_dialogue_while_in_dialogue() -> void:
	var tree := DialogueData.DialogueTree.new("block_test", "阻塞测试")
	tree.start_node = "start"
	tree.metadata = {"npc_id": "blocking_npc"}
	var node := DialogueData.DialogueNode.new("start", "NPC", "对话中...")
	node.choices.append(DialogueData.Choice.new("c1", "选项1", "start"))
	tree.add_node(node)
	_dialogue_mgr.register_dialogue_tree(tree)

	_dialogue_mgr.start_dialogue("block_test")
	assert_true(_dialogue_mgr.is_in_dialogue())

	var success: bool = _dialogue_mgr.start_dialogue_with_npc("blocking_npc")
	assert_false(success)


## 对话结束后可再次触发
func test_can_restart_after_end() -> void:
	var tree := DialogueData.DialogueTree.new("restart_test", "重启测试")
	tree.start_node = "start"
	tree.metadata = {"npc_id": "restart_npc"}
	var node := DialogueData.DialogueNode.new("start", "NPC", "你好")
	tree.add_node(node)
	_dialogue_mgr.register_dialogue_tree(tree)

	_dialogue_mgr.start_dialogue("restart_test")
	_dialogue_mgr.end_dialogue()
	assert_false(_dialogue_mgr.is_in_dialogue())

	var success: bool = _dialogue_mgr.start_dialogue_with_npc("restart_npc")
	assert_true(success)


## load_dialogue_from_dict 注册对话
func test_load_dialogue_from_dict() -> void:
	var dict := {
		"id": "dict_test",
		"title": "字典测试",
		"start_node": "start",
		"metadata": {"npc_id": "dict_npc"},
		"nodes": [
			{"id": "start", "speaker": "NPC", "text": "从字典加载", "next_node": "END"}
		]
	}
	var success: bool = _dialogue_mgr.load_dialogue_from_dict(dict)
	assert_true(success)
	assert_true(_dialogue_mgr.has_dialogue("dict_test"))
