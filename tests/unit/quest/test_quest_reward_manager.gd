## test_quest_reward_manager.gd
## 任务奖励分配单元测试 (quest-003)
## 验证奖励计算、分发、临时储物箱、特殊物品奖励等功能

extends GutTest

var quest_manager: QuestManager
var reward_manager: QuestRewardManager

func before_each():
	quest_manager = QuestManager.new()
	add_child_autofree(quest_manager)
	
	reward_manager = QuestRewardManager.new()
	add_child_autofree(reward_manager)
	reward_manager.set_quest_manager(quest_manager)

func after_each():
	reward_manager = null
	quest_manager = null

## 测试：奖励管理器初始化
func test_reward_manager_init():
	assert_ne(reward_manager, null, "奖励管理器应该成功创建")
	assert_ne(reward_manager.quest_manager, null, "任务管理器引用应该已设置")

## 测试：分发奖励 - 主线任务
func test_distribute_rewards_main_quest():
	quest_manager.register_quest("main_quest", "主线任务", "描述", QuestManager.QuestType.MAIN)
	quest_manager.set_quest_rewards("main_quest", {"exp": 500, "silver": 200})
	quest_manager.set_player_level(5)
	
	var result = reward_manager.distribute_rewards("main_quest")
	assert_true(result, "奖励应该分发成功")

## 测试：分发奖励 - 无奖励任务
func test_distribute_rewards_no_rewards():
	quest_manager.register_quest("no_reward_quest", "无奖励任务", "描述", QuestManager.QuestType.SIDE)
	
	var result = reward_manager.distribute_rewards("no_reward_quest")
	assert_true(result, "无奖励也应该返回成功")

## 测试：分发奖励 - 不存在的任务
func test_distribute_rewards_quest_not_found():
	var result = reward_manager.distribute_rewards("nonexistent")
	assert_false(result, "不存在的任务奖励分发应该失败")

## 测试：分发奖励 - 无管理器
func test_distribute_rewards_no_manager():
	reward_manager.quest_manager = null
	var result = reward_manager.distribute_rewards("any_quest")
	assert_false(result, "无任务管理器时奖励分发应该失败")

## 测试：计算奖励 - 主线任务自动计算
func test_calculate_rewards_main():
	var quest_info = {
		"type": QuestManager.QuestType.MAIN,
		"rewards": {}
	}
	quest_manager.set_player_level(3)
	
	var calculated = reward_manager._calculate_rewards(quest_info)
	
	assert_eq(calculated.exp, 300, "主线经验应该为 等级*100 = 300")
	assert_eq(calculated.silver, 150, "主线银两应该为 等级*50 = 150")

## 测试：计算奖励 - 支线任务自动计算
func test_calculate_rewards_side():
	var quest_info = {
		"type": QuestManager.QuestType.SIDE,
		"rewards": {}
	}
	quest_manager.set_player_level(4)
	
	var calculated = reward_manager._calculate_rewards(quest_info)
	
	assert_eq(calculated.exp, 200, "支线经验应该为 等级*50 = 200")
	assert_eq(calculated.silver, 80, "支线银两应该为 等级*20 = 80")

## 测试：计算奖励 - 使用手动设定的奖励
func test_calculate_rewards_manual():
	var quest_info = {
		"type": QuestManager.QuestType.MAIN,
		"rewards": {"exp": 9999, "silver": 8888}
	}
	
	var calculated = reward_manager._calculate_rewards(quest_info)
	
	assert_eq(calculated.exp, 9999, "应该使用手动设定的经验")
	assert_eq(calculated.silver, 8888, "应该使用手动设定的银两")

## 测试：计算奖励 - 物品奖励
func test_calculate_rewards_with_items():
	var quest_info = {
		"type": QuestManager.QuestType.SIDE,
		"rewards": {"items": ["sword_01", "herb_01"]}
	}
	
	var calculated = reward_manager._calculate_rewards(quest_info)
	
	assert_eq(calculated.items.size(), 2, "应该有2个物品奖励")

## 测试：奖励公式参数 - 主线
func test_get_reward_parameters_main():
	var params = reward_manager.get_reward_parameters(0, 5)
	assert_eq(params.exp, 500, "主线经验参数应该为500")
	assert_eq(params.silver, 250, "主线银两参数应该为250")

## 测试：奖励公式参数 - 支线
func test_get_reward_parameters_side():
	var params = reward_manager.get_reward_parameters(1, 10)
	assert_eq(params.exp, 500, "支线经验参数应该为500")
	assert_eq(params.silver, 200, "支线银两参数应该为200")

## 测试：奖励公式参数 - 悬赏
func test_get_reward_parameters_bounty():
	var params = reward_manager.get_reward_parameters(2, 8)
	assert_eq(params.exp, 80, "悬赏经验参数应该为80")
	assert_eq(params.silver, 40, "悬赏银两参数应该为40")

## 测试：奖励公式参数 - 奇遇（随机）
func test_get_reward_parameters_encounter():
	var params = reward_manager.get_reward_parameters(3, 5)
	assert_eq(params.exp, 100, "奇遇经验参数应该为 等级*20 = 100")
	assert_true(params.silver >= 0 and params.silver <= 500, "奇遇银两应该为0-500随机值")

## 测试：临时储物箱状态 - 空
func test_temporary_storage_empty():
	var status = reward_manager.get_temporary_storage_status()
	assert_true(status.is_empty, "临时储物箱初始应该为空")

## 测试：从临时储物箱获取 - 不存在的任务
func test_retrieve_nonexistent_quest():
	var content = reward_manager.retrieve_from_temporary_storage("no_quest")
	assert_eq(content.size(), 0, "不存在的任务储物箱应该返回空")

## 测试：从临时储物箱获取 - 全部
func test_retrieve_all_storage():
	reward_manager.temporary_storage["q1"] = {"items": ["item_01"], "silver": 0, "exp": 0}
	reward_manager.temporary_storage["q2"] = {"items": ["item_02"], "silver": 0, "exp": 0}
	
	var all = reward_manager.retrieve_from_temporary_storage()
	assert_eq(all.size(), 2, "应该返回所有储物箱内容")
	assert_true(reward_manager.temporary_storage.is_empty(), "储物箱应该被清空")

## 测试：保存和加载奖励数据
func test_save_and_load_reward_data():
	reward_manager.temporary_storage["test_quest"] = {"items": ["item_01"], "silver": 100, "exp": 50}
	
	var save_data = reward_manager.save_reward_data()
	assert_true(save_data.has("temporary_storage"), "保存数据应该包含临时储物箱")
	
	# 清空并加载
	reward_manager.temporary_storage.clear()
	reward_manager.load_reward_data(save_data)
	
	assert_true(reward_manager.temporary_storage.has("test_quest"), "加载后应该恢复临时储物箱数据")

## 测试：分发奖励触发信号
func test_distribute_rewards_emits_signals():
	quest_manager.register_quest("signal_quest", "信号任务", "描述", QuestManager.QuestType.MAIN)
	quest_manager.set_quest_rewards("signal_quest", {"exp": 100, "silver": 50})
	
	watch_signals(reward_manager)
	
	var result = reward_manager.distribute_rewards("signal_quest")
	
	assert_true(result, "奖励分发应该成功")
	assert_signal_emitted(reward_manager, "reward_given", "应该触发reward_given信号")

## 测试：分发物品奖励到背包
func test_give_item_rewards():
	quest_manager.register_quest("item_quest", "物品任务", "描述", QuestManager.QuestType.SIDE)
	quest_manager.set_quest_rewards("item_quest", {"items": ["sword_01"]})
	
	watch_signals(reward_manager)
	
	var result = reward_manager.distribute_rewards("item_quest")
	
	assert_true(result, "物品奖励分发应该成功")
	assert_signal_emitted(reward_manager, "reward_given", "应该触发reward_given信号")
	assert_true(quest_manager.player_inventory.has("sword_01"), "物品应该添加到背包")

## 测试：特殊物品奖励
func test_give_special_item_rewards():
	var result = reward_manager._give_special_item_rewards(["talent_point", "breakthrough_pill", "attribute_point", "custom_item"], "test_quest")
	assert_true(result, "特殊物品奖励应该返回成功")

## 测试：临时储物箱状态统计
func test_temporary_storage_item_count():
	reward_manager.temporary_storage["q1"] = {"items": ["a", "b"], "silver": 0, "exp": 0}
	reward_manager.temporary_storage["q2"] = {"items": ["c"], "silver": 0, "exp": 0}
	
	var status = reward_manager.get_temporary_storage_status()
	assert_eq(status.total_items, 3, "总物品数应该为3")
	assert_eq(status.quests_stored.size(), 2, "存储的任务数应该为2")
	assert_false(status.is_empty, "储物箱应该不为空")
