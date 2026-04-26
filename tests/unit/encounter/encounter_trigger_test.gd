# 奇遇触发系统单元测试
# 验证奇遇触发时机、福缘影响概率、权重重分配和保底机制

extends Node

# 加载奇遇触发管理器
var EncounterTriggerManager = load("res://src/scripts/encounter/encounter_trigger_manager.gd")

var encounter_manager
var test_result = {
	"passed": 0,
	"failed": 0,
	"total": 0,
	"details": []
}

func _ready():
	print("开始奇遇触发系统单元测试...")
	
	# 运行所有测试
	test_encounter_trigger_timing()
	test_luck_impact_on_probability()
	test_weight_redistribution_mechanism()
	test_guarantee_mechanism()
	
	# 输出测试结果
	print("\n=== 奇遇触发系统单元测试结果 ===")
	print("通过: %d" % test_result.passed)
	print("失败: %d" % test_result.failed)
	print("总计: %d" % test_result.total)
	
	if test_result.failed == 0:
		print("✅ 所有测试通过！")
	else:
		print("❌ 有 %d 个测试失败" % test_result.failed)
	
	for detail in test_result.details:
		print(detail)

# 测试奇遇触发时机
func test_encounter_trigger_timing():
	print("\n--- 测试奇遇触发时机 ---")
	
	encounter_manager = EncounterTriggerManager.new()
	encounter_manager.set_character_luck(50)  # 设置中等福缘
	
	# 测试大地图移动触发
	var result_movement = encounter_manager.trigger_encounter_check(encounter_manager.TriggerType.MAP_MOVEMENT)
	if result_movement.has("triggered"):
		add_test_result("奇遇触发时机", true, "大地图移动触发检查正常")
	else:
		add_test_result("奇遇触发时机", false, "大地图移动触发检查失败")
	
	# 测试战斗胜利后触发
	var result_victory = encounter_manager.trigger_encounter_check(encounter_manager.TriggerType.BATTLE_VICTORY)
	if result_victory.has("triggered"):
		add_test_result("奇遇触发时机", true, "战斗胜利后触发检查正常")
	else:
		add_test_result("奇遇触发时机", false, "战斗胜利后触发检查失败")
	
	# 测试休息存档触发
	var result_rest = encounter_manager.trigger_encounter_check(encounter_manager.TriggerType.REST_SAVE)
	if result_rest.has("triggered"):
		add_test_result("奇遇触发时机", true, "休息存档触发检查正常")
	else:
		add_test_result("奇遇触发时机", false, "休息存档触发检查失败")

# 测试福缘影响概率计算
func test_luck_impact_on_probability():
	print("\n--- 测试福缘影响概率计算 ---")
	
	encounter_manager = EncounterTriggerManager.new()
	
	# 测试福缘为0时的概率计算
	encounter_manager.set_character_luck(0)
	var prob_0_luck = encounter_manager.calculate_trigger_probability(0.05, 0)  # 5%基础概率，0福缘
	var expected_prob_0 = 0.05  # 5% * (1 + 0/100) = 5%
	if abs(prob_0_luck - expected_prob_0) < 0.001:
		add_test_result("福缘影响概率计算", true, "福缘为0时概率计算正确: %.3f" % prob_0_luck)
	else:
		add_test_result("福缘影响概率计算", false, "福缘为0时概率计算错误: 期望%.3f, 实际%.3f" % [expected_prob_0, prob_0_luck])
	
	# 测试福缘为50时的概率计算
	encounter_manager.set_character_luck(50)
	var prob_50_luck = encounter_manager.calculate_trigger_probability(0.05, 50)  # 5%基础概率，50福缘
	var expected_prob_50 = 0.075  # 5% * (1 + 50/100) = 7.5%
	if abs(prob_50_luck - expected_prob_50) < 0.001:
		add_test_result("福缘影响概率计算", true, "福缘为50时概率计算正确: %.3f" % prob_50_luck)
	else:
		add_test_result("福缘影响概率计算", false, "福缘为50时概率计算错误: 期望%.3f, 实际%.3f" % [expected_prob_50, prob_50_luck])
	
	# 测试福缘为100时的概率计算
	encounter_manager.set_character_luck(100)
	var prob_100_luck = encounter_manager.calculate_trigger_probability(0.05, 100)  # 5%基础概率，100福缘
	var expected_prob_100 = 0.10  # 5% * (1 + 100/100) = 10%
	# 注意：如果计算结果超过上限，应该是上限值
	var capped_prob_100 = min(expected_prob_100, encounter_manager.TRIGGER_CHANCE_CAP)
	if abs(prob_100_luck - capped_prob_100) < 0.001:
		add_test_result("福缘影响概率计算", true, "福缘为100时概率计算正确(考虑上限): %.3f" % prob_100_luck)
	else:
		add_test_result("福缘影响概率计算", false, "福缘为100时概率计算错误: 期望%.3f, 实际%.3f" % [capped_prob_100, prob_100_luck])

# 测试权重重分配机制
func test_weight_redistribution_mechanism():
	print("\n--- 测试权重重分配机制 ---")
	
	encounter_manager = EncounterTriggerManager.new()
	
	# 测试福缘为0时的权重
	encounter_manager.set_character_luck(0)
	var weights_0_luck = encounter_manager.adjust_weights_by_luck(encounter_manager.base_weights, 0)
	var base_jianghu_weight = encounter_manager.base_weights[encounter_manager.EncounterType.JIANGHU_RUMOR]
	var result_jianghu_0 = weights_0_luck[encounter_manager.EncounterType.JIANGHU_RUMOR]
	if abs(result_jianghu_0 - base_jianghu_weight) < 0.1:
		add_test_result("权重重分配机制", true, "福缘为0时江湖传闻权重基本不变: %.1f" % result_jianghu_0)
	else:
		add_test_result("权重重分配机制", false, "福缘为0时江湖传闻权重应基本不变: 期望%.1f, 实际%.1f" % [float(base_jianghu_weight), result_jianghu_0])
	
	# 测试福缘为100时的权重变化
	encounter_manager.set_character_luck(100)
	var weights_100_luck = encounter_manager.adjust_weights_by_luck(encounter_manager.base_weights, 100)
	var base_mijing_weight = encounter_manager.base_weights[encounter_manager.EncounterType.MIJING_CHALLENGE]
	var result_mijing_100 = weights_100_luck[encounter_manager.EncounterType.MIJING_CHALLENGE]
	# 高阶权重应该增加: 原权重 * (1 + 100*0.5/50) = 原权重 * (1 + 1) = 原权重 * 2
	var expected_mijing_100 = base_mijing_weight * (1.0 + (100.0 * encounter_manager.WEIGHT_ADJUSTMENT_FACTOR / 50.0))
	if result_mijing_100 >= base_mijing_weight:
		add_test_result("权重重分配机制", true, "福缘为100时秘境挑战权重增加: %.1f" % result_mijing_100)
	else:
		add_test_result("权重重分配机制", false, "福缘为100时秘境挑战权重应增加: 期望>%d, 实际%.1f" % [base_mijing_weight, result_mijing_100])

# 测试保底机制
func test_guarantee_mechanism():
	print("\n--- 测试保底机制 ---")
	
	encounter_manager = EncounterTriggerManager.new()
	encounter_manager.set_character_luck(0)  # 设置最低福缘，降低自然触发概率
	
	# 通过反射设置连续失败次数接近阈值
	encounter_manager.consecutive_failures = encounter_manager.GUARANTEE_THRESHOLD - 1
	
	# 下一次触发应该激活保底机制
	var result = encounter_manager.trigger_encounter_check(encounter_manager.TriggerType.MAP_MOVEMENT)
	
	if result.triggered and "保底机制激活" in result.message:
		add_test_result("保底机制", true, "保底机制正常工作，连续%d次后强制触发" % encounter_manager.GUARANTEE_THRESHOLD)
		# 检查计数器是否重置
		if encounter_manager.get_consecutive_failures() == 0:
			add_test_result("保底机制", true, "保底触发后计数器正确重置")
		else:
			add_test_result("保底机制", false, "保底触发后计数器未重置")
	else:
		add_test_result("保底机制", false, "保底机制未正常工作")
	
	# 重置计数器以进行后续测试
	encounter_manager.reset_failure_counter()

# 辅助函数：添加测试结果
func add_test_result(test_name: String, passed: bool, message: String):
	test_result.total += 1
	if passed:
		test_result.passed += 1
		print("✅ %s: %s" % [test_name, message])
	else:
		test_result.failed += 1
		print("❌ %s: %s" % [test_name, message])
	
	test_result.details.append("%s: %s" % [test_name, "通过" if passed else "失败 - " + message])