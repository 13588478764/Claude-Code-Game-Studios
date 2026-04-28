# 任务状态管理单元测试
# 测试任务状态机和状态转换功能

extends Node

# 导入要测试的脚本
var QuestManager = load("res://src/scripts/quest/quest_manager.gd")

# 测试结果统计
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("运行任务状态管理测试...")
	
	# 测试1: 任务管理器初始化
	test_quest_manager_initialization()
	
	# 测试2: 任务注册和定义
	test_quest_registration()
	
	# 测试3: 任务状态机
	test_quest_state_machine()
	
	# 测试4: 任务状态转换
	test_quest_state_transitions()
	
	# 测试5: 任务目标管理
	test_quest_objective_management()
	
	# 测试6: 前置条件检查
	test_prerequisite_checking()
	
	# 测试7: 任务数据保存和加载
	test_quest_data_save_and_load()
	
	print("任务状态管理测试完成: %d/%d 通过" % [tests_passed, tests_total])

# 测试任务管理器初始化
func test_quest_manager_initialization():
	var manager = QuestManager.new()
	
	assert(manager != null, "任务管理器应成功创建")
	assert(manager.quest_definitions.size() == 0, "初始时任务定义字典应为空")
	assert(manager.active_quests.size() == 0, "初始时进行中任务字典应为空")
	assert(manager.player_level == 1, "默认玩家等级应为1")
	
	print("✓ 任务管理器初始化测试通过")
	tests_passed += 4
	tests_total += 4

# 测试任务注册和定义
func test_quest_registration():
	var manager = QuestManager.new()
	
	# 测试注册正常任务
	var result1 = manager.register_quest(
		"test_main_quest", 
		"测试主线任务", 
		"这是一个测试用的主线任务", 
		manager.QuestType.MAIN,
		"npc_tester"
	)
	assert(result1 == true, "应能成功注册任务")
	
	# 测试重复注册同一ID
	var result2 = manager.register_quest(
		"test_main_quest", 
		"重复注册任务", 
		"重复注册测试", 
		manager.QuestType.SIDE
	)
	assert(result2 == false, "不应能重复注册相同ID的任务")
	
	# 测试获取任务信息
	var quest_info = manager.get_quest_info("test_main_quest")
	assert(quest_info.size() > 0, "应能获取已注册任务的信息")
	assert(quest_info.title == "测试主线任务", "任务标题应匹配")
	assert(quest_info.type == manager.QuestType.MAIN, "任务类型应匹配")
	assert(quest_info.status == manager.QuestStatus.LOCKED, "新注册任务状态应为锁定")
	
	print("✓ 任务注册和定义测试通过")
	tests_passed += 6
	tests_total += 6

# 测试任务状态机
func test_quest_state_machine():
	var manager = QuestManager.new()
	
	# 注册一个任务
	manager.register_quest(
		"state_test_quest", 
		"状态机测试任务", 
		"用于测试状态机的任务", 
		manager.QuestType.SIDE
	)
	
	# 检查初始状态
	var initial_info = manager.get_quest_info("state_test_quest")
	assert(initial_info.status == manager.QuestStatus.LOCKED, "任务初始状态应为锁定")
	
	# 手动设置为可用状态
	manager.update_quest_status("state_test_quest", manager.QuestStatus.AVAILABLE)
	var available_info = manager.get_quest_info("state_test_quest")
	assert(available_info.status == manager.QuestStatus.AVAILABLE, "任务状态应能更新为可用")
	
	# 设置为进行中状态
	manager.update_quest_status("state_test_quest", manager.QuestStatus.ACTIVE)
	var active_info = manager.get_quest_info("state_test_quest")
	assert(active_info.status == manager.QuestStatus.ACTIVE, "任务状态应能更新为进行中")
	
	# 设置为已完成状态
	manager.update_quest_status("state_test_quest", manager.QuestStatus.COMPLETED)
	var completed_info = manager.get_quest_info("state_test_quest")
	assert(completed_info.status == manager.QuestStatus.COMPLETED, "任务状态应能更新为已完成")
	
	# 设置为已结束状态
	manager.update_quest_status("state_test_quest", manager.QuestStatus.FINISHED)
	var finished_info = manager.get_quest_info("state_test_quest")
	assert(finished_info.status == manager.QuestStatus.FINISHED, "任务状态应能更新为已结束")
	
	print("✓ 任务状态机测试通过")
	tests_passed += 6
	tests_total += 6

# 测试任务状态转换
func test_quest_state_transitions():
	var manager = QuestManager.new()
	
	# 注册一个任务并添加目标
	manager.register_quest(
		"transition_test_quest", 
		"状态转换测试任务", 
		"用于测试状态转换的任务", 
		manager.QuestType.MAIN
	)
	manager.add_quest_objective(
		"transition_test_quest",
		manager.ObjectiveType.KILL_ENEMY,
		"wolf",
		5,
		"击杀5只狼"
	)
	
	# 设置任务为可用状态
	manager.update_quest_status("transition_test_quest", manager.QuestStatus.AVAILABLE)
	
	# 接取任务
	var accept_result = manager.accept_quest("transition_test_quest")
	assert(accept_result == true, "应能成功接取可用任务")
	
	var active_info = manager.get_quest_info("transition_test_quest")
	assert(active_info.status == manager.QuestStatus.ACTIVE, "接取后任务状态应为进行中")
	
	# 更新目标进度直到完成
	for i in range(5):
		manager.update_objective_progress("transition_test_quest", 0)
	
	# 检查任务是否自动变为已完成
	var after_progress_info = manager.get_quest_info("transition_test_quest")
	assert(after_progress_info.status == manager.QuestStatus.COMPLETED, "完成所有目标后任务状态应为已完成")
	
	# 完成任务
	var complete_result = manager.complete_quest("transition_test_quest")
	assert(complete_result == true, "应能成功完成已完成的任务")
	
	var finished_info = manager.get_quest_info("transition_test_quest")
	assert(finished_info.status == manager.QuestStatus.FINISHED, "完成任务后状态应为已结束")
	
	print("✓ 任务状态转换测试通过")
	tests_passed += 5
	tests_total += 5

# 测试任务目标管理
func test_quest_objective_management():
	var manager = QuestManager.new()
	
	# 注册一个有多重目标的任务
	manager.register_quest(
		"objective_test_quest", 
		"目标管理测试任务", 
		"用于测试目标管理的任务", 
		manager.QuestType.SIDE
	)
	
	# 添加多个目标
	var obj1_result = manager.add_quest_objective(
		"objective_test_quest",
		manager.ObjectiveType.KILL_ENEMY,
		"goblin",
		3,
		"击杀3只哥布林"
	)
	var obj2_result = manager.add_quest_objective(
		"objective_test_quest",
		manager.ObjectiveType.COLLECT_ITEM,
		"herb",
		5,
		"收集5株草药"
	)
	var obj3_result = manager.add_quest_objective(
		"objective_test_quest",
		manager.ObjectiveType.TALK_TO_NPC,
		"merchant",
		1,
		"与商人对话"
	)
	
	assert(obj1_result == true, "应能成功添加第一个目标")
	assert(obj2_result == true, "应能成功添加第二个目标")
	assert(obj3_result == true, "应能成功添加第三个目标")
	
	# 检查目标数量
	var quest_info = manager.get_quest_info("objective_test_quest")
	assert(quest_info.objectives.size() == 3, "任务应有3个目标")
	
	# 更新第一个目标进度
	manager.update_objective_progress("objective_test_quest", 0, 2)  # 击杀2只哥布林，还需1只
	
	var updated_info = manager.get_quest_info("objective_test_quest")
	assert(updated_info.objectives[0].current_count == 2, "第一个目标当前计数应为2")
	assert(updated_info.objectives[0].is_complete == false, "第一个目标应未完成")
	
	# 完成第一个目标
	manager.update_objective_progress("objective_test_quest", 0)  # 再击杀1只
	
	var after_completion_info = manager.get_quest_info("objective_test_quest")
	assert(after_completion_info.objectives[0].is_complete == true, "第一个目标应已完成")
	
	print("✓ 任务目标管理测试通过")
	tests_passed += 8
	tests_total += 8

# 测试前置条件检查
func test_prerequisite_checking():
	var manager = QuestManager.new()
	
	# 注册一个有前置条件的任务
	manager.register_quest(
		"prereq_test_quest", 
		"前置条件测试任务", 
		"用于测试前置条件的任务", 
		manager.QuestType.MAIN
	)
	
	# 设置前置条件：等级5，需要完成另一个任务
	var prereq_dict = {
		"min_level": 5,
		"required_quests": ["previous_quest"]
	}
	var prereq_result = manager.set_quest_prerequisites("prereq_test_quest", prereq_dict)
	assert(prereq_result == true, "应能成功设置前置条件")
	
	# 检查前置条件（等级不够）
	var prereq_check1 = manager.check_quest_prerequisites("prereq_test_quest")
	assert(prereq_check1 == false, "等级不够时前置条件检查应失败")
	
	# 提高等级但没有完成前置任务
	manager.set_player_level(10)
	var prereq_check2 = manager.check_quest_prerequisites("prereq_test_quest")
	assert(prereq_check2 == false, "未完成前置任务时前置条件检查应失败")
	
	# 添加前置任务到已完成列表
	manager.player_completed_quests.append("previous_quest")
	var prereq_check3 = manager.check_quest_prerequisites("prereq_test_quest")
	assert(prereq_check3 == true, "满足所有前置条件时检查应成功")
	
	# 测试更新任务状态为可用
	manager.update_quest_status("prereq_test_quest", manager.QuestStatus.AVAILABLE)
	var available_info = manager.get_quest_info("prereq_test_quest")
	assert(available_info.status == manager.QuestStatus.AVAILABLE, "满足前置条件后任务状态应能设为可用")
	
	print("✓ 前置条件检查测试通过")
	tests_passed += 6
	tests_total += 6

# 测试任务数据保存和加载
func test_quest_data_save_and_load():
	var manager = QuestManager.new()
	
	# 注册任务并设置状态
	manager.register_quest(
		"save_test_quest", 
		"保存测试任务", 
		"用于测试保存和加载的任务", 
		manager.QuestType.BOUNTY
	)
	manager.add_quest_objective(
		"save_test_quest",
		manager.ObjectiveType.KILL_ENEMY,
		"bandit",
		10,
		"击杀10个强盗"
	)
	manager.set_player_level(15)
	manager.player_completed_quests = ["old_quest_1", "old_quest_2"]
	manager.player_inventory = ["sword", "potion"]
	
	# 接取并激活任务
	manager.update_quest_status("save_test_quest", manager.QuestStatus.AVAILABLE)
	manager.accept_quest("save_test_quest")
	
	# 更新目标进度
	for i in range(7):
		manager.update_objective_progress("save_test_quest", 0)
	
	# 保存数据
	var saved_data = manager.save_quest_data()
	assert(saved_data.size() > 0, "保存的数据不应为空")
	assert(saved_data.player_level == 15, "保存的等级应为15")
	assert(saved_data.player_completed_quests.size() == 2, "保存的已完成任务数量应为2")
	assert(saved_data.active_quests.has("save_test_quest"), "保存的数据应包含进行中的任务")
	
	var saved_quest_data = saved_data.active_quests["save_test_quest"]
	assert(saved_quest_data.status == manager.QuestStatus.ACTIVE, "保存的任务状态应为进行中")
	assert(saved_quest_data.objectives[0].current_count == 7, "保存的目标进度应为7")
	
	# 创建新管理器并加载数据
	var new_manager = QuestManager.new()
	new_manager.register_quest(
		"save_test_quest", 
		"保存测试任务", 
		"用于测试保存和加载的任务", 
		manager.QuestType.BOUNTY
	)
	new_manager.add_quest_objective(
		"save_test_quest",
		new_manager.ObjectiveType.KILL_ENEMY,
		"bandit",
		10,
		"击杀10个强盗"
	)
	
	new_manager.load_quest_data(saved_data)
	
	# 验证加载的数据
	assert(new_manager.player_level == 15, "加载后等级应为15")
	assert(new_manager.player_completed_quests.size() == 2, "加载后已完成任务数量应为2")
	assert(new_manager.player_inventory.size() == 2, "加载后背包物品数量应为2")
	
	var loaded_quest_info = new_manager.get_quest_info("save_test_quest")
	assert(loaded_quest_info.status == new_manager.QuestStatus.ACTIVE, "加载后任务状态应为进行中")
	assert(loaded_quest_info.objectives[0].current_count == 7, "加载后目标进度应为7")
	
	print("✓ 任务数据保存和加载测试通过")
	tests_passed += 11
	tests_total += 11

# 断言函数
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("断言失败: " + message)
	
	tests_total += 1