## test_quest_tracker.gd
## 任务追踪系统单元测试 (quest-002)
## 验证任务追踪、事件处理、进度更新、紧急任务检测等功能

extends GutTest

var quest_manager: QuestManager
var quest_tracker: QuestTracker

func before_each():
	quest_manager = QuestManager.new()
	add_child_autofree(quest_manager)
	
	quest_tracker = QuestTracker.new()
	add_child_autofree(quest_tracker)
	
	# 连接追踪器到管理器
	quest_tracker.set_quest_manager(quest_manager)

func after_each():
	quest_tracker = null
	quest_manager = null

## 测试：追踪器初始化
func test_tracker_init():
	assert_ne(quest_tracker, null, "追踪器应该成功创建")
	assert_ne(quest_tracker.quest_manager, null, "任务管理器引用应该已设置")

## 测试：设置任务管理器
func test_set_quest_manager():
	var new_manager = QuestManager.new()
	add_child_autofree(new_manager)
	
	quest_tracker.set_quest_manager(new_manager)
	assert_eq(quest_tracker.quest_manager, new_manager, "任务管理器引用应该更新")

## 测试：追踪任务 - 成功
func test_track_quest_success():
	quest_manager.register_quest("track_quest", "追踪任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("track_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("track_quest")
	
	var result = quest_tracker.track_quest("track_quest")
	assert_true(result, "追踪应该成功")
	assert_eq(quest_tracker.get_current_tracked_quest_id(), "track_quest", "当前追踪ID应该正确")

## 测试：追踪任务 - 不存在的任务
func test_track_quest_not_found():
	var result = quest_tracker.track_quest("nonexistent")
	assert_false(result, "不存在的任务应该追踪失败")

## 测试：追踪任务 - 未接取的任务
func test_track_quest_not_active():
	quest_manager.register_quest("locked_quest", "锁定任务", "描述", QuestManager.QuestType.SIDE)
	
	var result = quest_tracker.track_quest("locked_quest")
	assert_false(result, "未接取的任务应该追踪失败")

## 测试：停止追踪
func test_stop_tracking():
	quest_manager.register_quest("stop_quest", "停止追踪", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("stop_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("stop_quest")
	quest_tracker.track_quest("stop_quest")
	
	var result = quest_tracker.stop_tracking()
	assert_true(result, "停止追踪应该成功")
	assert_eq(quest_tracker.get_current_tracked_quest_id(), "", "追踪ID应该为空")

## 测试：停止追踪 - 无追踪任务
func test_stop_tracking_no_quest():
	var result = quest_tracker.stop_tracking()
	assert_false(result, "无追踪任务时停止应该失败")

## 测试：获取当前追踪任务信息
func test_get_tracked_quest_info():
	quest_manager.register_quest("info_quest", "信息任务", "描述", QuestManager.QuestType.MAIN)
	quest_manager.update_quest_status("info_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("info_quest")
	quest_tracker.track_quest("info_quest")
	
	var info = quest_tracker.get_current_tracked_quest_info()
	assert_ne(info.size(), 0, "追踪任务信息不应该为空")
	assert_eq(info.id, "info_quest", "任务ID应该正确")

## 测试：获取追踪信息 - 无追踪任务
func test_get_tracked_quest_info_empty():
	var info = quest_tracker.get_current_tracked_quest_info()
	assert_eq(info.size(), 0, "无追踪任务时信息应该为空")

## 测试：获取所有进行中任务信息
func test_get_active_quests_info():
	quest_manager.register_quest("q1", "任务1", "描述1", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("q1", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("q1")
	
	quest_manager.register_quest("q2", "任务2", "描述2", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("q2", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("q2")
	
	var active_info = quest_tracker.get_active_quests_info()
	assert_eq(active_info.size(), 2, "应该有2个进行中任务")

## 测试：追踪UI数据
func test_get_tracking_ui_data():
	quest_manager.register_quest("ui_quest", "UI测试任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("ui_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("ui_quest")
	
	var ui_data = quest_tracker.get_tracking_ui_data()
	assert_true(ui_data.has("tracked_quest"), "UI数据应该包含tracked_quest")
	assert_true(ui_data.has("active_quests"), "UI数据应该包含active_quests")
	assert_true(ui_data.has("has_tracked_quest"), "UI数据应该包含has_tracked_quest")

## 测试：任务状态变更回调 - ACTIVE
func test_on_quest_status_changed_active():
	quest_manager.register_quest("active_cb", "回调任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("active_cb", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("active_cb")
	
	assert_eq(quest_tracker.current_tracked_quest, "active_cb", "ACTIVE状态变更应该自动追踪")

## 测试：任务状态变更回调 - COMPLETED
func test_on_quest_status_changed_completed():
	quest_manager.register_quest("complete_cb", "完成回调", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("complete_cb", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("complete_cb")
	quest_manager.update_quest_status("complete_cb", QuestManager.QuestStatus.COMPLETED)
	
	assert_eq(quest_tracker.current_tracked_quest, "", "COMPLETED状态变更应该停止追踪")

## 测试：紧急任务检测
func test_get_urgent_quests():
	quest_manager.register_quest("urgent_quest", "紧急任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("urgent_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("urgent_quest")
	
	# 添加目标并完成90%
	quest_manager.add_quest_objective("urgent_quest", QuestManager.ObjectiveType.KILL_ENEMY, "enemy_01", 10, "击杀10个敌人")
	quest_manager.update_objective_progress("urgent_quest", 0, 9)
	
	var urgent = quest_tracker.get_urgent_quests()
	assert_true(urgent.has("urgent_quest"), "应该检测到紧急任务")

## 测试：非紧急任务
func test_non_urgent_quests():
	quest_manager.register_quest("normal_quest", "普通任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("normal_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("normal_quest")
	
	quest_manager.add_quest_objective("normal_quest", QuestManager.ObjectiveType.KILL_ENEMY, "enemy_01", 10, "击杀10个敌人")
	quest_manager.update_objective_progress("normal_quest", 0, 3)
	
	var urgent = quest_tracker.get_urgent_quests()
	assert_false(urgent.has("normal_quest"), "30%进度不应该视为紧急任务")

## 测试：获取任务追踪数据
func test_get_quest_tracking_data():
	quest_manager.register_quest("track_data_quest", "追踪数据", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("track_data_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("track_data_quest")
	quest_manager.add_quest_objective("track_data_quest", QuestManager.ObjectiveType.COLLECT_ITEM, "herb", 5, "收集5株草药")
	quest_tracker.track_quest("track_data_quest")
	
	var data = quest_tracker.get_quest_tracking_data("track_data_quest")
	assert_ne(data.size(), 0, "追踪数据不应该为空")
	assert_eq(data.quest_id, "track_data_quest", "任务ID应该正确")
	assert_true(data.is_tracked, "任务应该处于被追踪状态")
	assert_eq(data.objectives.size(), 1, "应该有1个目标")

## 测试：处理敌人击杀事件
func test_handle_enemy_killed_event():
	quest_manager.register_quest("kill_quest", "击杀任务", "描述", QuestManager.QuestType.BOUNTY)
	quest_manager.update_quest_status("kill_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("kill_quest")
	quest_manager.add_quest_objective("kill_quest", QuestManager.ObjectiveType.KILL_ENEMY, "bandit", 3, "击杀3个山贼")
	
	watch_signals(quest_manager)
	
	quest_tracker.handle_external_event("enemy_killed", {"enemy_type": "bandit"})
	quest_tracker.handle_external_event("enemy_killed", {"enemy_type": "bandit"})
	
	var info = quest_manager.get_quest_info("kill_quest")
	assert_eq(info.objectives[0].current_count, 2, "击杀进度应该更新为2")

## 测试：处理物品收集事件
func test_handle_item_collected_event():
	quest_manager.register_quest("collect_quest", "收集任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("collect_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("collect_quest")
	quest_manager.add_quest_objective("collect_quest", QuestManager.ObjectiveType.COLLECT_ITEM, "herb", 5, "收集5株草药")
	
	quest_tracker.handle_external_event("item_collected", {"item_id": "herb"})
	quest_tracker.handle_external_event("item_collected", {"item_id": "herb"})
	quest_tracker.handle_external_event("item_collected", {"item_id": "herb"})
	
	var info = quest_manager.get_quest_info("collect_quest")
	assert_eq(info.objectives[0].current_count, 3, "收集进度应该更新为3")

## 测试：处理NPC对话事件
func test_handle_npc_talked_to_event():
	quest_manager.register_quest("talk_quest", "对话任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("talk_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("talk_quest")
	quest_manager.add_quest_objective("talk_quest", QuestManager.ObjectiveType.TALK_TO_NPC, "elder_zhang", 1, "与张长老对话")
	
	quest_tracker.handle_external_event("npc_talked_to", {"npc_id": "elder_zhang"})
	
	var info = quest_manager.get_quest_info("talk_quest")
	assert_eq(info.objectives[0].current_count, 1, "对话进度应该更新为1")
	assert_eq(info.objectives[0].is_complete, true, "目标应该已完成")

## 测试：处理到达位置事件
func test_handle_location_reached_event():
	quest_manager.register_quest("location_quest", "位置任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("location_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("location_quest")
	quest_manager.add_quest_objective("location_quest", QuestManager.ObjectiveType.GO_TO_LOCATION, "ancient_cave", 1, "到达古洞窟")
	
	watch_signals(quest_tracker)
	
	quest_tracker.handle_external_event("location_reached", {"location_id": "ancient_cave", "world_position": Vector2(100, 200)})
	
	assert_signal_emitted(quest_tracker, "quest_target_location_updated", "位置更新信号应该触发")

## 测试：事件处理缺少管理器
func test_handle_event_no_manager():
	quest_tracker.quest_manager = null
	quest_tracker.handle_external_event("enemy_killed", {"enemy_type": "bandit"})
	# 不应崩溃，静默返回

## 测试：事件处理缺少必要数据
func test_handle_event_missing_data():
	quest_manager.register_quest("test_event", "测试事件", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("test_event", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("test_event")
	
	# 事件数据缺少enemy_type
	quest_tracker.handle_external_event("enemy_killed", {})
	# 不应崩溃，静默返回

## 测试：追踪数据 - 目标完成度比例
func test_quest_tracking_data_progress_ratio():
	quest_manager.register_quest("ratio_quest", "比例任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("ratio_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("ratio_quest")
	quest_manager.add_quest_objective("ratio_quest", QuestManager.ObjectiveType.COLLECT_ITEM, "stone", 10, "收集10块石头")
	quest_manager.update_objective_progress("ratio_quest", 0, 7)
	
	var data = quest_tracker.get_quest_tracking_data("ratio_quest")
	assert_eq(data.objectives[0].progress_ratio, 0.7, "进度比例应该为0.7")
	assert_eq(data.objectives[0].current_count, 7, "当前计数应该为7")
