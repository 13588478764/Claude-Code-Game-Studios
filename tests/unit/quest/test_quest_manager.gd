## test_quest_manager.gd
## 任务状态管理单元测试 (quest-001)
## 验证任务注册、状态流转、前置条件检查、接取/完成等功能

extends GutTest

var quest_manager: QuestManager

func before_each():
	quest_manager = QuestManager.new()
	add_child_autofree(quest_manager)

func after_each():
	quest_manager = null

## 测试：任务管理器初始化
func test_quest_manager_init():
	assert_ne(quest_manager, null, "任务管理器应该成功创建")
	assert_eq(quest_manager.player_level, 1, "玩家初始等级应该为1")

## 测试：注册任务
func test_register_quest():
	var result = quest_manager.register_quest("test_quest_001", "测试任务", "这是一个测试任务", QuestManager.QuestType.SIDE)
	assert_true(result, "任务应该注册成功")
	assert_true(quest_manager.quest_definitions.has("test_quest_001"), "任务定义应该存在")

## 测试：重复任务ID注册
func test_register_quest_duplicate():
	quest_manager.register_quest("dup_quest", "任务A", "描述A", QuestManager.QuestType.SIDE)
	var result = quest_manager.register_quest("dup_quest", "任务B", "描述B", QuestManager.QuestType.MAIN)
	assert_false(result, "重复ID应该注册失败")

## 测试：添加任务目标
func test_add_quest_objective():
	quest_manager.register_quest("obj_quest", "目标测试", "描述", QuestManager.QuestType.SIDE)
	var result = quest_manager.add_quest_objective("obj_quest", QuestManager.ObjectiveType.KILL_ENEMY, "bandit", 5, "击杀5名山贼")
	assert_true(result, "目标应该添加成功")
	
	var quest = quest_manager.quest_definitions["obj_quest"]
	assert_eq(quest.objectives.size(), 1, "应该有1个目标")
	assert_eq(quest.objectives[0].target_count, 5, "目标数量应该为5")

## 测试：添加目标到不存在的任务
func test_add_objective_to_missing_quest():
	var result = quest_manager.add_quest_objective("nonexistent", QuestManager.ObjectiveType.TALK_TO_NPC, "npc_01", 1, "对话")
	assert_false(result, "不存在的任务应该添加目标失败")

## 测试：设置任务奖励
func test_set_quest_rewards():
	quest_manager.register_quest("reward_quest", "奖励测试", "描述", QuestManager.QuestType.MAIN)
	var rewards = {"exp": 500, "silver": 100, "items": ["sword_01"]}
	var result = quest_manager.set_quest_rewards("reward_quest", rewards)
	assert_true(result, "奖励应该设置成功")
	assert_eq(quest_manager.quest_definitions["reward_quest"].rewards.exp, 500, "经验奖励应该为500")

## 测试：设置前置条件
func test_set_quest_prerequisites():
	quest_manager.register_quest("prereq_quest", "前置测试", "描述", QuestManager.QuestType.SIDE)
	var prereqs = {"min_level": 10, "required_quests": ["quest_a", "quest_b"]}
	var result = quest_manager.set_quest_prerequisites("prereq_quest", prereqs)
	assert_true(result, "前置条件应该设置成功")

## 测试：前置条件检查 - 通过
func test_check_prerequisites_pass():
	quest_manager.register_quest("prereq_quest", "前置测试", "描述", QuestManager.QuestType.SIDE)
	quest_manager.set_quest_prerequisites("prereq_quest", {"min_level": 5})
	quest_manager.set_player_level(10)
	
	var result = quest_manager.check_quest_prerequisites("prereq_quest")
	assert_true(result, "等级满足应该通过前置检查")

## 测试：前置条件检查 - 等级不足
func test_check_prerequisites_level_fail():
	quest_manager.register_quest("prereq_quest", "前置测试", "描述", QuestManager.QuestType.SIDE)
	quest_manager.set_quest_prerequisites("prereq_quest", {"min_level": 10})
	quest_manager.set_player_level(3)
	
	var result = quest_manager.check_quest_prerequisites("prereq_quest")
	assert_false(result, "等级不足应该不通过前置检查")

## 测试：前置条件检查 - 前置任务未完成
func test_check_prerequisites_quest_fail():
	quest_manager.register_quest("prereq_quest", "前置测试", "描述", QuestManager.QuestType.SIDE)
	quest_manager.set_quest_prerequisites("prereq_quest", {"required_quests": ["quest_a"]})
	
	var result = quest_manager.check_quest_prerequisites("prereq_quest")
	assert_false(result, "前置任务未完成应该不通过检查")

## 测试：前置条件检查 - 前置任务已完成
func test_check_prerequisites_quest_done():
	quest_manager.register_quest("prereq_quest", "前置测试", "描述", QuestManager.QuestType.SIDE)
	quest_manager.set_quest_prerequisites("prereq_quest", {"required_quests": ["quest_a"]})
	quest_manager.player_completed_quests.append("quest_a")
	
	var result = quest_manager.check_quest_prerequisites("prereq_quest")
	assert_true(result, "前置任务已完成应该通过检查")

## 测试：更新任务状态
func test_update_quest_status():
	quest_manager.register_quest("status_quest", "状态测试", "描述", QuestManager.QuestType.SIDE)
	var result = quest_manager.update_quest_status("status_quest", QuestManager.QuestStatus.AVAILABLE)
	assert_true(result, "状态应该更新成功")

## 测试：接取任务
func test_accept_quest():
	quest_manager.register_quest("accept_quest", "接取测试", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("accept_quest", QuestManager.QuestStatus.AVAILABLE)
	
	var result = quest_manager.accept_quest("accept_quest")
	assert_true(result, "任务应该接取成功")
	assert_true(quest_manager.active_quests.has("accept_quest"), "任务应该在进行中列表中")

## 测试：接取不可用的任务
func test_accept_unavailable_quest():
	quest_manager.register_quest("locked_quest", "锁定任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.set_quest_prerequisites("locked_quest", {"min_level": 99})
	
	var result = quest_manager.accept_quest("locked_quest")
	assert_false(result, "不可用的任务应该接取失败")

## 测试：获取任务信息
func test_get_quest_info():
	quest_manager.register_quest("info_quest", "信息测试", "描述", QuestManager.QuestType.MAIN, "npc_test")
	quest_manager.set_quest_rewards("info_quest", {"exp": 200})
	
	var info = quest_manager.get_quest_info("info_quest")
	assert_ne(info.size(), 0, "任务信息不应该为空")
	assert_eq(info.id, "info_quest", "任务ID应该正确")
	assert_eq(info.title, "信息测试", "任务标题应该正确")
	assert_eq(info.type, QuestManager.QuestType.MAIN, "任务类型应该正确")
	assert_eq(info.npc_id, "npc_test", "NPC ID应该正确")

## 测试：获取不存在任务的信息
func test_get_quest_info_not_found():
	var info = quest_manager.get_quest_info("nonexistent")
	assert_eq(info.size(), 0, "不存在的任务信息应该为空字典")

## 测试：按状态获取任务列表
func test_get_quests_by_status():
	quest_manager.register_quest("avail_quest", "可接取任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("avail_quest", QuestManager.QuestStatus.AVAILABLE)
	
	quest_manager.register_quest("locked_avail", "锁定可接取", "描述", QuestManager.QuestType.SIDE)
	
	var available = quest_manager.get_quests_by_status(QuestManager.QuestStatus.AVAILABLE)
	assert_true(available.has("avail_quest"), "应该包含可接取任务")

## 测试：获取进行中的任务列表
func test_get_active_quests():
	quest_manager.register_quest("active_quest", "进行中任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.update_quest_status("active_quest", QuestManager.QuestStatus.AVAILABLE)
	quest_manager.accept_quest("active_quest")
	
	var active = quest_manager.get_active_quests()
	assert_true(active.has("active_quest"), "应该包含进行中任务")

## 测试：保存任务数据
func test_save_quest_data():
	quest_manager.set_player_level(5)
	quest_manager.player_completed_quests = ["quest_done"]
	quest_manager.player_inventory = ["item_01"]
	
	var save_data = quest_manager.save_quest_data()
	assert_true(save_data.has("player_level"), "保存数据应该包含玩家等级")
	assert_eq(save_data.player_level, 5, "玩家等级应该为5")
	assert_true(save_data.has("active_quests"), "保存数据应该包含进行中任务")

## 测试：加载任务数据
func test_load_quest_data():
	var load_data = {
		"player_level": 10,
		"player_completed_quests": ["quest_a", "quest_b"],
		"player_inventory": ["item_01", "item_02"],
		"active_quests": {}
	}
	
	quest_manager.load_quest_data(load_data)
	assert_eq(quest_manager.player_level, 10, "玩家等级应该加载为10")
	assert_eq(quest_manager.player_completed_quests.size(), 2, "已完成任务应该有2个")

## 测试：奖励系数 - 主线
func test_reward_coefficient_main():
	var coeff = quest_manager.get_reward_coefficient(QuestManager.QuestType.MAIN)
	assert_eq(coeff.exp_factor, 100, "主线任务经验系数应该为100")
	assert_eq(coeff.silver_factor, 50, "主线任务银两系数应该为50")

## 测试：奖励系数 - 支线
func test_reward_coefficient_side():
	var coeff = quest_manager.get_reward_coefficient(QuestManager.QuestType.SIDE)
	assert_eq(coeff.exp_factor, 50, "支线任务经验系数应该为50")

## 测试：目标数据结构
func test_objective_structure():
	var obj = QuestManager.Objective.new(QuestManager.ObjectiveType.COLLECT_ITEM, "herb_01", 10, "收集10株草药")
	assert_eq(obj.type, QuestManager.ObjectiveType.COLLECT_ITEM, "目标类型应该正确")
	assert_eq(obj.target_count, 10, "目标数量应该为10")
	assert_eq(obj.current_count, 0, "初始计数应该为0")

## 测试：任务数据结构
func test_quest_structure():
	var quest = QuestManager.Quest.new("test_q", "测试任务", "描述", QuestManager.QuestType.SIDE, "npc_01")
	assert_eq(quest.id, "test_q", "任务ID应该正确")
	assert_eq(quest.status, QuestManager.QuestStatus.LOCKED, "初始状态应该为锁定")
	assert_eq(quest.npc_id, "npc_01", "NPC ID应该正确")

## 测试：物品背包操作
func test_inventory_operations():
	quest_manager.add_item_to_inventory("sword_01")
	assert_true(quest_manager.has_item("sword_01"), "应该有物品sword_01")
	
	quest_manager.remove_item_from_inventory("sword_01")
	assert_false(quest_manager.has_item("sword_01"), "移除后不应该有物品sword_01")

## 测试：刷新锁定任务状态
func test_refresh_locked_quests():
	quest_manager.register_quest("refresh_quest", "刷新测试", "描述", QuestManager.QuestType.SIDE)
	quest_manager.set_quest_prerequisites("refresh_quest", {"min_level": 3})
	quest_manager.update_quest_status("refresh_quest", QuestManager.QuestStatus.LOCKED)
	
	quest_manager.set_player_level(5)
	quest_manager._refresh_locked_quests()
	
	var quest = quest_manager.quest_definitions["refresh_quest"]
	assert_eq(quest.status, QuestManager.QuestStatus.AVAILABLE, "等级提升后任务应该变为可接取")
