## 对话系统集成测试
## 测试DialogueManager、DialogueBox和JSON加载的完整流程
extends GutTest

var dialogue_manager = null
var dialogue_loader = null

func before_each() -> void:
	# 获取AutoLoad单例
	dialogue_manager = get_node_or_null("/root/DialogueManager")
	dialogue_loader = get_node_or_null("/root/DialogueLoader")
	
	assert_not_null(dialogue_manager, "DialogueManager should exist")
	assert_not_null(dialogue_loader, "DialogueLoader should exist")

func test_dialogue_manager_is_autoload() -> void:
	## 测试：DialogueManager已注册为AutoLoad
	assert_not_null(dialogue_manager, "DialogueManager should be autoloaded")
	assert_true(dialogue_manager is Node, "DialogueManager should be a Node")

func test_dialogue_loader_is_autoload() -> void:
	## 测试：DialogueLoader已注册为AutoLoad
	assert_not_null(dialogue_loader, "DialogueLoader should be autoloaded")

func test_dialogue_files_exist() -> void:
	## 测试：对话JSON文件存在
	var expected_files := [
		"res://data/dialogues/intro_yunzhonghe.json",
		"res://data/dialogues/act1_event1_opening.json",
		"res://data/dialogues/act1_event2_cultivation.json",
		"res://data/dialogues/act1_event3_crisis.json",
		"res://data/dialogues/act1_event4_boss.json",
		"res://data/dialogues/act1_event5_ruins.json",
		"res://data/dialogues/act1_event6_resolution.json",
		"res://data/dialogues/act2_event1_return.json",
		"res://data/dialogues/act2_event2_sect_gathering.json",
		"res://data/dialogues/act2_event3_first_trial.json",
		"res://data/dialogues/act2_event4_demonic_invasion.json",
		"res://data/dialogues/act2_event5_secret_realm.json",
		"res://data/dialogues/act2_event6_dao_heart_choice.json",
		"res://data/dialogues/act2_event7_murongxue_memory.json",
		"res://data/dialogues/act2_event8_battlefield.json",
		"res://data/dialogues/act2_event9_yunzhonghe_sacrifice.json",
		"res://data/dialogues/act2_event10_foundation_breakthrough.json",
		"res://data/dialogues/act2_event11_act2_finale.json",
		"res://data/dialogues/side_quests/yunzhonghe_sword_heart_path.json",
		"res://data/dialogues/side_quests/tiewushuang_brotherhood.json",
		"res://data/dialogues/side_quests/liuruyan_righteous_path.json",
		"res://data/dialogues/side_quests/murongxue_past_life.json",
		"res://data/dialogues/side_quests/xiaohanye_demonic_path.json"
	]
	
	for file_path in expected_files:
		assert_true(FileAccess.file_exists(file_path), "Dialogue file should exist: %s" % file_path)

func test_load_dialogue_from_json() -> void:
	## 测试：从JSON加载对话树
	var test_file := "res://data/dialogues/intro_yunzhonghe.json"
	
	if not FileAccess.file_exists(test_file):
		push_warning("测试文件不存在，跳过测试")
		return
	
	var result: bool = dialogue_manager.load_dialogue_from_json(test_file)
	assert_true(result, "load_dialogue_from_json should return true for valid file")

func test_start_dialogue() -> void:
	## 测试：开始对话
	var test_file := "res://data/dialogues/intro_yunzhonghe.json"
	
	if not FileAccess.file_exists(test_file):
		push_warning("测试文件不存在，跳过测试")
		return
	
	# 先加载对话
	dialogue_manager.load_dialogue_from_json(test_file)
	
	# 开始对话
	var dialogue_id := "yunzhonghe_first_meeting"
	var result: bool = dialogue_manager.start_dialogue(dialogue_id)
	assert_true(result, "start_dialogue should return true for valid dialogue_id")
	assert_true(dialogue_manager.is_in_dialogue(), "is_in_dialogue should return true after starting")

func test_end_dialogue() -> void:
	## 测试：结束对话
	var test_file := "res://data/dialogues/intro_yunzhonghe.json"
	
	if not FileAccess.file_exists(test_file):
		push_warning("测试文件不存在，跳过测试")
		return
	
	dialogue_manager.load_dialogue_from_json(test_file)
	dialogue_manager.start_dialogue("yunzhonghe_first_meeting")
	
	# 结束对话
	dialogue_manager.end_dialogue()
	assert_false(dialogue_manager.is_in_dialogue(), "is_in_dialogue should return false after ending")

func test_dialogue_signals() -> void:
	## 测试：对话信号发射
	## 
	## GDScript Lambda 闭包陷阱：
	## Lambda 按值捕获外部变量，给 lambda 内部捕获的 bool 变量重新赋值
	## 不会影响外部 var 的值。必须用 Array/Dictionary 等引用类型传递状态。
	## 之前 `var dialogue_started_received := false` + lambda 赋值 = true
	## 在外部读取依然是 false，导致 assert 失败。
	var received := {"started": false, "ended": false}
	
	dialogue_manager.dialogue_started.connect(
		func(_id): received["started"] = true
	)
	dialogue_manager.dialogue_ended.connect(
		func(_id): received["ended"] = true
	)
	
	var test_file := "res://data/dialogues/intro_yunzhonghe.json"
	
	if not FileAccess.file_exists(test_file):
		push_warning("测试文件不存在，跳过测试")
		return
	
	dialogue_manager.load_dialogue_from_json(test_file)
	dialogue_manager.start_dialogue("yunzhonghe_first_meeting")
	
	assert_true(received["started"], "dialogue_started signal should be emitted")
	
	dialogue_manager.end_dialogue()
	
	# 等待信号传播
	await get_tree().process_frame
	
	assert_true(received["ended"], "dialogue_ended signal should be emitted")

func test_loaded_dialogues_count() -> void:
	## 测试：DialogueLoader加载了足够的对话文件
	var loaded_count: int = dialogue_loader.get_loaded_dialogues().size()
	assert_true(loaded_count >= 23, "Should load at least 23 dialogue files, got %d" % loaded_count)

func test_act2_dialogues_exist() -> void:
	## 测试：Act 2 主线对话文件全部存在
	var act2_files := [
		"res://data/dialogues/act2_event1_return.json",
		"res://data/dialogues/act2_event2_sect_gathering.json",
		"res://data/dialogues/act2_event3_first_trial.json",
		"res://data/dialogues/act2_event4_demonic_invasion.json",
		"res://data/dialogues/act2_event5_secret_realm.json",
		"res://data/dialogues/act2_event6_dao_heart_choice.json",
		"res://data/dialogues/act2_event7_murongxue_memory.json",
		"res://data/dialogues/act2_event8_battlefield.json",
		"res://data/dialogues/act2_event9_yunzhonghe_sacrifice.json",
		"res://data/dialogues/act2_event10_foundation_breakthrough.json",
		"res://data/dialogues/act2_event11_act2_finale.json"
	]
	
	for file_path in act2_files:
		assert_true(FileAccess.file_exists(file_path), "Act 2 对话文件应该存在: %s" % file_path)

func test_act2_dialogues_registered() -> void:
	## 测试：Act 2 对话树已注册到 DialogueManager
	var act2_ids := [
		"ACT2_EVENT1_RETURN",
		"ACT2_EVENT2_SECT_GATHERING",
		"ACT2_EVENT3_FIRST_TRIAL",
		"ACT2_EVENT4_DEMONIC_INVASION",
		"ACT2_EVENT5_SECRET_REALM",
		"ACT2_EVENT6_DAO_HEART_CHOICE",
		"ACT2_EVENT7_MURONGXUE_MEMORY",
		"ACT2_EVENT8_BATTLEFIELD",
		"ACT2_EVENT9_SACRIFICE",
		"ACT2_EVENT10_BREAKTHROUGH",
		"ACT2_EVENT11_FINALE"
	]
	
	for dialogue_id in act2_ids:
		assert_true(dialogue_manager.has_dialogue(dialogue_id), "Act 2 对话树应已注册: %s" % dialogue_id)

func test_act_manager_exists() -> void:
	## 测试：ActManager 已注册为 AutoLoad
	var act_manager = get_node_or_null("/root/ActManager")
	assert_not_null(act_manager, "ActManager should be autoloaded")
	assert_true(act_manager is Node, "ActManager should be a Node")

func test_act_manager_initial_state() -> void:
	## 测试：ActManager 初始状态正确
	var act_manager = get_node_or_null("/root/ActManager")
	assert_not_null(act_manager, "ActManager should exist")
	
	assert_eq(act_manager.get_current_act(), "act_1", "初始幕次应为 Act 1")
	assert_false(act_manager.is_act_completed("act_1"), "Act 1 初始不应为已完成")
	assert_true(act_manager.is_act_unlocked("act_1"), "Act 1 初始应为已解锁")
