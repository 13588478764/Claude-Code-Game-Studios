# 任务追踪系统集成测试
# 测试任务追踪功能与任务管理器的集成

extends Node

# 导入要测试的脚本
var QuestManager = load("res://src/scripts/quest/quest_manager.gd")
var QuestTracker = load("res://src/scripts/quest/quest_tracker.gd")

# 测试结果统计
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("运行任务追踪系统集成测试...")
	
	# 测试1: 任务追踪器初始化和连接
	test_quest_tracker_initialization_and_connection()
	
	# 测试2: 任务追踪功能
	test_quest_tracking_functionality()
	
	# 测试3: 目标进度追踪
	test_objective_progress_tracking()
	
	# 测试4: 任务状态变化追踪
	test_quest_status_change_tracking()
	
	# 测试5: 外部事件处理
	test_external_event_handling()
	
	# 测试6: UI数据集成
	test_ui_data_integration()
	
	# 测试7: 紧急任务检测
	test_urgent_quest_detection()
	
	print("任务追踪系统集成测试完成: %d/%d 通过" % [tests_passed, tests_total])

# 测试任务追踪器初始化和连接
func test_quest_tracker_initialization_and_connection():
	var manager = QuestManager.new()
	var tracker = QuestTracker.new()
	
	assert(manager != null, "任务管理器应成功创建")
	assert(tracker != null, "任务追踪器应成功创建")
	
	# 连接追踪器到管理器
	tracker.set_quest_manager(manager)
	
	# 验证连接
	assert(tracker.quest_manager == manager, "追踪器应正确连接到管理器")
	assert(tracker.get_current_tracked_quest_id() == "", "初始时不应追踪任何任务")
	
	print("✓ 任务追踪器初始化和连接测试通过")
	tests_passed += 4
	tests_total += 4

# 测试任务追踪功能
func test_quest_tracking_functionality():
	var manager = QuestManager.new()
	var tracker = QuestTracker.new()
	tracker.set_quest_manager(manager)
	
	# 注册一个任务
	manager.register_quest(
		"tracking_test_quest", 
		"追踪测试任务", 
		"用于测试追踪功能的任务", 
		manager.QuestType.MAIN
	)
	manager.add_quest_objective(
		"tracking_test_quest",
		manager.ObjectiveType.KILL_ENEMY,
		"zombie",
		3,
		"击杀3只僵尸"
	)
	
	# 设置任务为可用并接取
	manager.update_quest_status("tracking_test_quest", manager.QuestStatus.AVAILABLE)
	manager.accept_quest("tracking_test_quest")
	
	# 开始追踪任务
	var track_result = tracker.track_quest("tracking_test_quest")
	assert(track_result == true, "应能成功追踪进行中的任务")
	
	# 验证正在追踪
	assert(tracker.get_current_tracked_quest_id() == "tracking_test_quest", "应正在追踪指定任务")
	
	var tracked_info = tracker.get_current_tracked_quest_info()
	assert(tracked_info.id == "tracking_test_quest", "追踪的任务ID应匹配")
	assert(tracked_info.status == manager.QuestStatus.ACTIVE, "追踪的任务状态应为进行中")
	
	# 停止追踪
	var stop_result = tracker.stop_tracking()
	assert(stop_result == true, "应能成功停止追踪")
	assert(tracker.get_current_tracked_quest_id() == "", "停止追踪后不应追踪任何任务")
	
	# 重新开始追踪
	var track_result2 = tracker.track_quest("tracking_test_quest")
	assert(track_result2 == true, "应能再次追踪任务")
	
	print("✓ 任务追踪功能测试通过")
	tests_passed += 7
	tests_total += 7

# 测试目标进度追踪
func test_objective_progress_tracking():
	var manager = QuestManager.new()
	var tracker = QuestTracker.new()
	tracker.set_quest_manager(manager)
	
	# 注册一个有多个目标的任务
	manager.register_quest(
		"progress_test_quest", 
		"进度追踪测试任务", 
		"用于测试进度追踪的任务", 
		manager.QuestType.SIDE
	)
	manager.add_quest_objective(
		"progress_test_quest",
		manager.ObjectiveType.KILL_ENEMY,
		"skeleton",
		5,
		"击杀5只骷髅"
	)
	manager.add_quest_objective(
		"progress_test_quest",
		manager.ObjectiveType.COLLECT_ITEM,
		"crystal",
		2,
		"收集2颗水晶"
	)
	
	# 接取任务
	manager.update_quest_status("progress_test_quest", manager.QuestStatus.AVAILABLE)
	manager.accept_quest("progress_test_quest")
	
	# 开始追踪
	tracker.track_quest("progress_test_quest")
	
	# 连接信号以捕获进度更新
	var signal_received = false
	var received_quest_id = ""
	var received_obj_index = -1
	var received_current = -1
	var received_target = -1
	
	tracker.connect("objective_progress_updated", func(quest_id, obj_index, current, target):
		signal_received = true
		received_quest_id = quest_id
		received_obj_index = obj_index
		received_current = current
		received_target = target
	)
	
	# 更新目标进度
	manager.update_objective_progress("progress_test_quest", 0, 2)  # 击杀2只骷髅
	
	# 验证信号被触发
	assert(signal_received == true, "应触发目标进度更新信号")
	assert(received_quest_id == "progress_test_quest", "信号中的任务ID应匹配")
	assert(received_obj_index == 0, "信号中的目标索引应匹配")
	assert(received_current == 2, "信号中的当前值应为2")
	assert(received_target == 5, "信号中的目标值应为5")
	
	# 验证追踪数据中的进度
	var tracking_data = tracker.get_quest_tracking_data("progress_test_quest")
	assert(tracking_data.objectives[0].current_count == 2, "追踪数据中的进度应更新")
	assert(tracking_data.objectives[0].progress_ratio == 0.4, "进度比率应为0.4")
	
	# 完成第一个目标
	manager.update_objective_progress("progress_test_quest", 0, 3)  # 再击杀3只骷髅
	
	var updated_tracking_data = tracker.get_quest_tracking_data("progress_test_quest")
	assert(updated_tracking_data.objectives[0].is_complete == true, "第一个目标应已完成")
	
	print("✓ 目标进度追踪测试通过")
	tests_passed += 10
	tests_total += 10

# 测试任务状态变化追踪
func test_quest_status_change_tracking():
	var manager = QuestManager.new()
	var tracker = QuestTracker.new()
	tracker.set_quest_manager(manager)
	
	# 注册一个任务
	manager.register_quest(
		"status_test_quest", 
		"状态变化测试任务", 
		"用于测试状态变化追踪的任务", 
		manager.QuestType.BOUNTY
	)
	manager.add_quest_objective(
		"status_test_quest",
		manager.ObjectiveType.KILL_ENEMY,
		"bandit",
		1,
		"击杀1个强盗"
	)
	
	# 连接状态变化信号
	var status_change_received = false
	var old_status = ""
	var new_status = ""
	
	manager.connect("quest_status_changed", func(quest_id, old, new):
		if quest_id == "status_test_quest":
			status_change_received = true
			old_status = old
			new_status = new
	)
	
	# 接取任务
	manager.update_quest_status("status_test_quest", manager.QuestStatus.AVAILABLE)
	manager.accept_quest("status_test_quest")
	
	# 开始追踪
	tracker.track_quest("status_test_quest")
	
	# 验证状态变化
	var initial_info = tracker.get_current_tracked_quest_info()
	assert(initial_info.status == manager.QuestStatus.ACTIVE, "任务状态应为进行中")
	
	# 完成目标
	manager.update_objective_progress("status_test_quest", 0)
	
	# 验证任务状态变为已完成
	var completed_info = tracker.get_current_tracked_quest_info()
	assert(completed_info.status == manager.QuestStatus.COMPLETED, "任务状态应为已完成")
	
	# 完成任务
	manager.complete_quest("status_test_quest")
	
	var finished_info = tracker.get_current_tracked_quest_info()
	assert(finished_info.status == manager.QuestStatus.FINISHED, "任务状态应为已结束")
	
	# 验证追踪器是否停止追踪已完成的任务
	assert(tracker.get_current_tracked_quest_id() == "", "完成任务后应停止追踪")
	
	print("✓ 任务状态变化追踪测试通过")
	tests_passed += 6
	tests_total += 6

# 测试外部事件处理
func test_external_event_handling():
	var manager = QuestManager.new()
	var tracker = QuestTracker.new()
	tracker.set_quest_manager(manager)
	
	# 注册一个任务
	manager.register_quest(
		"event_test_quest", 
		"事件处理测试任务", 
		"用于测试外部事件处理的任务", 
		manager.QuestType.SIDE
	)
	manager.add_quest_objective(
		"event_test_quest",
		manager.ObjectiveType.KILL_ENEMY,
		"orc",
		3,
		"击杀3只兽人"
	)
	manager.add_quest_objective(
		"event_test_quest",
		manager.ObjectiveType.COLLECT_ITEM,
		"ore",
		5,
		"收集5块矿石"
	)
	
	# 接取任务
	manager.update_quest_status("event_test_quest", manager.QuestStatus.AVAILABLE)
	manager.accept_quest("event_test_quest")
	
	# 开始追踪
	tracker.track_quest("event_test_quest")
	
	# 处理击杀敌人事件
	var kill_event_data = {"enemy_type": "orc"}
	tracker.handle_external_event("enemy_killed", kill_event_data)
	
	var after_kill_info = tracker.get_current_tracked_quest_info()
	assert(after_kill_info.objectives[0].current_count == 1, "击杀事件应更新目标进度")
	
	# 处理收集物品事件
	var collect_event_data = {"item_id": "ore"}
	tracker.handle_external_event("item_collected", collect_event_data)
	
	var after_collect_info = tracker.get_current_tracked_quest_info()
	assert(after_collect_info.objectives[1].current_count == 1, "收集事件应更新目标进度")
	
	# 多次处理事件
	for i in range(2):
		tracker.handle_external_event("enemy_killed", kill_event_data)
	
	var after_multiple_kills = tracker.get_current_tracked_quest_info()
	assert(after_multiple_kills.objectives[0].current_count == 3, "多次击杀应正确累计进度")
	assert(after_multiple_kills.objectives[0].is_complete == true, "完成击杀目标后应标记为完成")
	
	# 验证任务是否自动变为已完成
	var quest_info = manager.get_quest_info("event_test_quest")
	assert(quest_info.status == manager.QuestStatus.COMPLETED, "完成所有目标后任务应变为已完成")
	
	print("✓ 外部事件处理测试通过")
	tests_passed += 7
	tests_total += 7

# 测试UI数据集成
func test_ui_data_integration():
	var manager = QuestManager.new()
	var tracker = QuestTracker.new()
	tracker.set_quest_manager(manager)
	
	# 注册多个任务
	manager.register_quest(
		"ui_test_quest_1", 
		"UI测试任务1", 
		"第一个UI测试任务", 
		manager.QuestType.MAIN
	)
	manager.add_quest_objective(
		"ui_test_quest_1",
		manager.ObjectiveType.KILL_ENEMY,
		"spider",
		4,
		"击杀4只蜘蛛"
	)
	
	manager.register_quest(
		"ui_test_quest_2", 
		"UI测试任务2", 
		"第二个UI测试任务", 
		manager.QuestType.SIDE
	)
	manager.add_quest_objective(
		"ui_test_quest_2",
		manager.ObjectiveType.TALK_TO_NPC,
		"villager",
		1,
		"与村民对话"
	)
	
	# 接取任务
	manager.update_quest_status("ui_test_quest_1", manager.QuestStatus.AVAILABLE)
	manager.update_quest_status("ui_test_quest_2", manager.QuestStatus.AVAILABLE)
	manager.accept_quest("ui_test_quest_1")
	manager.accept_quest("ui_test_quest_2")
	
	# 开始追踪一个任务
	tracker.track_quest("ui_test_quest_1")
	
	# 获取UI数据
	var ui_data = tracker.get_tracking_ui_data()
	
	assert(ui_data.has_tracked_quest == true, "UI数据应表明有被追踪的任务")
	assert(ui_data.tracked_quest.id == "ui_test_quest_1", "UI数据中的追踪任务应匹配")
	assert(ui_data.active_quests.size() == 2, "UI数据中的活跃任务数量应为2")
	
	# 验证活跃任务列表
	var active_quest_ids = []
	for quest in ui_data.active_quests:
		active_quest_ids.append(quest.id)
	assert(active_quest_ids.has("ui_test_quest_1"), "活跃任务列表应包含任务1")
	assert(active_quest_ids.has("ui_test_quest_2"), "活跃任务列表应包含任务2")
	
	# 获取特定任务的追踪数据
	var quest1_data = tracker.get_quest_tracking_data("ui_test_quest_1")
	assert(quest1_data.quest_id == "ui_test_quest_1", "任务追踪数据ID应匹配")
	assert(quest1_data.is_tracked == true, "任务1应被追踪")
	
	var quest2_data = tracker.get_quest_tracking_data("ui_test_quest_2")
	assert(quest2_data.is_tracked == false, "任务2不应被追踪")
	
	# 验证目标信息
	assert(quest1_data.objectives.size() == 1, "任务1应有1个目标")
	assert(quest1_data.objectives[0].description == "击杀4只蜘蛛", "目标描述应匹配")
	
	print("✓ UI数据集成测试通过")
	tests_passed += 10
	tests_total += 10

# 测试紧急任务检测
func test_urgent_quest_detection():
	var manager = QuestManager.new()
	var tracker = QuestTracker.new()
	tracker.set_quest_manager(manager)
	
	# 注册多个任务
	manager.register_quest(
		"urgent_test_quest_1", 
		"紧急测试任务1", 
		"接近完成的任务", 
		manager.QuestType.MAIN
	)
	manager.add_quest_objective(
		"urgent_test_quest_1",
		manager.ObjectiveType.KILL_ENEMY,
		"beast",
		10,
		"击杀10只野兽"
	)
	
	manager.register_quest(
		"urgent_test_quest_2", 
		"紧急测试任务2", 
		"刚开始的任务", 
		manager.QuestType.SIDE
	)
	manager.add_quest_objective(
		"urgent_test_quest_2",
		manager.ObjectiveType.COLLECT_ITEM,
		"flower",
		5,
		"收集5朵花"
	)
	
	# 接取任务
	manager.update_quest_status("urgent_test_quest_1", manager.QuestStatus.AVAILABLE)
	manager.update_quest_status("urgent_test_quest_2", manager.QuestStatus.AVAILABLE)
	manager.accept_quest("urgent_test_quest_1")
	manager.accept_quest("urgent_test_quest_2")
	
	# 更新第一个任务的进度，使其接近完成
	for i in range(9):  # 9/10，接近完成
		manager.update_objective_progress("urgent_test_quest_1", 0)
	
	// 更新第二个任务的进度，使其刚完成一部分
	manager.update_objective_progress("urgent_test_quest_2", 0)  # 1/5
	
	# 获取紧急任务
	var urgent_quests = tracker.get_urgent_quests()
	assert(urgent_quests.size() == 1, "应有一个紧急任务")
	assert(urgent_quests[0] == "urgent_test_quest_1", "紧急任务应是接近完成的那个")
	
	// 完成第一个任务
	for i in range(1):  # 再击杀1只，完成任务
		manager.update_objective_progress("urgent_test_quest_1", 0)
	
	// 此时第一个任务已完成，不应再是紧急任务
	var urgent_quests_after_completion = tracker.get_urgent_quests()
	assert(urgent_quests_after_completion.size() == 0, "完成任务后不应有紧急任务")
	
	// 更新第二个任务使其接近完成
	for i in range(3):  # 总共4/5，接近完成
		manager.update_objective_progress("urgent_test_quest_2", 0)
	
	var urgent_quests_later = tracker.get_urgent_quests()
	assert(urgent_quests_later.size() == 1, "任务2现在应是紧急任务")
	assert(urgent_quests_later[0] == "urgent_test_quest_2", "紧急任务应是任务2")
	
	print("✓ 紧急任务检测测试通过")
	tests_passed += 8
	tests_total += 8

# 断言函数
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("断言失败: " + message)
	
	tests_total += 1