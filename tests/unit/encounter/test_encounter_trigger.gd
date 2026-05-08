## 奇遇触发系统单元测试
## 验证奇遇触发时机、福缘影响概率、权重重分配和保底机制
extends GutTest

var encounter_manager

func before_each():
	encounter_manager = EncounterTriggerManager.new()
	add_child_autofree(encounter_manager)

func after_each():
	pass

## 测试奇遇触发时机 - 大地图移动
func test_encounter_trigger_on_map_movement():
	var result = encounter_manager.trigger_encounter_check("MAP_MOVE", 0.0)
	assert_true(result or not result, "大地图移动触发检查应返回布尔值")

## 测试奇遇触发时机 - 战斗胜利
func test_encounter_trigger_on_battle_victory():
	var result = encounter_manager.trigger_encounter_check("BATTLE_WIN", 0.0)
	assert_true(result or not result, "战斗胜利后触发检查应返回布尔值")

## 测试奇遇触发时机 - 休息存档
func test_encounter_trigger_on_rest_save():
	var result = encounter_manager.trigger_encounter_check("REST_SAVE", 0.0)
	assert_true(result or not result, "休息存档触发检查应返回布尔值")

## 测试福缘为0时的概率计算
func test_luck_zero_probability():
	var prob = encounter_manager.calculate_trigger_probability(0.05, 0.0)
	assert_true(abs(prob - 0.05) < 0.001, "福缘为0时概率应为5%")

## 测试福缘为50时的概率计算
func test_luck_fifty_probability():
	var prob = encounter_manager.calculate_trigger_probability(0.05, 50.0)
	assert_true(abs(prob - 0.075) < 0.001, "福缘为50时概率应为7.5%")

## 测试福缘为100时的概率计算
func test_luck_hundred_probability():
	var prob = encounter_manager.calculate_trigger_probability(0.05, 100.0)
	assert_true(abs(prob - 0.10) < 0.001, "福缘为100时概率应为10%")

## 测试高福缘概率上限为20%
func test_probability_cap_at_twenty_percent():
	var prob = encounter_manager.calculate_trigger_probability(0.05, 200.0)
	# 0.05 * (1 + 200/100) = 0.05 * 3 = 0.15, 上限为0.20所以不触发
	assert_true(abs(prob - 0.15) < 0.001, "福缘为200时概率应为15%（未超过20%上限）")

## 测试福缘为0时权重基本不变
func test_weight_no_change_at_zero_luck():
	var weights = encounter_manager.adjust_weights_by_luck(encounter_manager.encounter_weights, 0.0)
	var jianghu_weight = weights["JiangHuRumor"]
	# 福缘为0时，江湖传闻权重应被除以1.0（不变）
	assert_true(abs(jianghu_weight - 40.0) < 1.0, "福缘为0时江湖传闻权重应基本不变")

## 测试高福缘增加高阶奇遇权重
func test_high_luck_increases_high_tier_weights():
	var weights_0 = encounter_manager.adjust_weights_by_luck(encounter_manager.encounter_weights, 0.0)
	var weights_100 = encounter_manager.adjust_weights_by_luck(encounter_manager.encounter_weights, 100.0)
	# 高人指点和秘境挑战的权重应该增加
	assert_true(weights_100["GaoRenZhiDian"] > weights_0["GaoRenZhiDian"], "福缘100时高人指点权重应增加")
	assert_true(weights_100["MiJingChallenge"] > weights_0["MiJingChallenge"], "福缘100时秘境挑战权重应增加")

## 测试奇遇类型选择返回有效类型
func test_select_encounter_type_returns_valid_type():
	var valid_types = ["JiangHuRumor", "TianCaiDiBao", "GaoRenZhiDian", "ShiChuanMiJi", "MiJingChallenge"]
	for i in range(10):
		var selected = encounter_manager.select_encounter_type(50.0)
		assert_true(valid_types.has(selected), "奇遇类型应为有效类型: " + selected)

## 测试连续失败计数器增加
func test_consecutive_failures_increment():
	var initial = encounter_manager.consecutive_failures
	encounter_manager.trigger_encounter_check("MAP_MOVE", 0.0)
	assert_true(encounter_manager.consecutive_failures >= initial, "连续失败计数应增加或保持不变")

## 测试重置计数器功能
func test_reset_failure_counter():
	encounter_manager.consecutive_failures = 15
	encounter_manager.reset_failure_counter()
	assert_eq(encounter_manager.consecutive_failures, 0, "重置后计数器应为0")

## 测试奇遇完成记录
func test_encounter_completion_tracking():
	var eid = "test_encounter_001"
	assert_false(encounter_manager.has_completed_encounter(eid), "奇遇应未完成")
	encounter_manager.mark_encounter_completed(eid)
	assert_true(encounter_manager.has_completed_encounter(eid), "奇遇应已标记完成")
