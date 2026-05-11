# EXP获取机制单元测试
# 验证战斗收益、探索与奇遇收益、任务进度收益和EXP来源追溯功能

extends Node

# 导入需要测试的脚本
var ExpAcquisitionManager = load("res://src/scripts/character/exp_acquisition_manager.gd")

# 测试结果统计
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("开始运行EXP获取机制单元测试...")
	
	# 运行战斗收益测试
	test_combat_exp_granting()
	test_combat_exp_with_perfect_victory()
	test_combat_exp_with_combo()
	
	# 运行探索收益测试
	test_exploration_exp_granting()
	test_exploration_exp_with_different_types()
	
	# 运行奇遇收益测试
	test_encounter_exp_granting()
	test_encounter_exp_with_different_types()
	
	# 运行任务进度收益测试
	test_quest_exp_granting()
	test_quest_exp_with_different_completion_types()
	
	# 运行EXP来源追溯测试
	test_exp_source_tracing()
	test_multiple_exp_sources()
	
	print("\n测试完成: %d/%d 个测试通过" % [tests_passed, tests_total])

# 测试战斗EXP授予
func test_combat_exp_granting():
	var exp_manager = ExpAcquisitionManager.new()
	
	# 测试普通敌人
	var enemy_data = {"type": "normal_enemy"}
	var battle_result = {}
	var exp_result = exp_manager.grant_combat_exp(enemy_data, battle_result)
	
	# 验证返回值
	assert(exp_result > 0, "战斗EXP授予应返回正值")
	assert(exp_result == 50, "普通敌人应授予50点EXP")
	
	# 测试Boss敌人
	var boss_data = {"type": "boss"}
	var boss_result = {}
	var boss_exp_result = exp_manager.grant_combat_exp(boss_data, boss_result)
	
	# 验证返回值
	assert(boss_exp_result == 500, "Boss敌人应授予500点EXP")
	
	print("✓ 战斗EXP授予测试通过")
	tests_passed += 2
	tests_total += 2

# 测试完美胜利战斗EXP
func test_combat_exp_with_perfect_victory():
	var exp_manager = ExpAcquisitionManager.new()
	
	# 测试完美胜利奖励
	var enemy_data = {"type": "normal_enemy"}
	var battle_result = {"perfect_victory": true}
	var exp_result = exp_manager.grant_combat_exp(enemy_data, battle_result)
	
	# 基础EXP: 50, 完美胜利奖励: +10%, 所以应该是 50 * 1.1 = 55
	var expected_exp = int(50 * 1.1)
	assert(exp_result == expected_exp, "完美胜利应获得额外10%EXP奖励")
	
	print("✓ 完美胜利战斗EXP测试通过")
	tests_passed += 1
	tests_total += 1

# 测试连击战斗EXP
func test_combat_exp_with_combo():
	var exp_manager = ExpAcquisitionManager.new()
	
	# 测试连击奖励
	var enemy_data = {"type": "normal_enemy"}
	var battle_result = {"combo_performed": true}
	var exp_result = exp_manager.grant_combat_exp(enemy_data, battle_result)
	
	# 基础EXP: 50, 连击奖励: +5%, 所以应该是 50 * 1.05 = 52.5 -> 52
	var expected_exp = int(50 * 1.05)
	assert(exp_result == expected_exp, "连击应获得额外5%EXP奖励")
	
	print("✓ 连击战斗EXP测试通过")
	tests_passed += 1
	tests_total += 1

# 测试探索EXP授予
func test_exploration_exp_granting():
	var exp_manager = ExpAcquisitionManager.new()
	
	# 测试首次探索
	var region_data = {"name": "新手村"}
	var discovery_type = "first_exploration"
	var exp_result = exp_manager.grant_exploration_exp(region_data, discovery_type)
	
	assert(exp_result == 25, "首次探索应授予25点EXP")
	
	print("✓ 探索EXP授予测试通过")
	tests_passed += 1
	tests_total += 1

# 测试不同类型探索EXP
func test_exploration_exp_with_different_types():
	var exp_manager = ExpAcquisitionManager.new()
	
	# 测试不同类型探索
	var discovery_types = ["first_exploration", "discovery_point", "treasure"]
	var expected_values = [25, 15, 30]
	
	for i in range(discovery_types.size()):
		var region_data = {"name": "区域" + str(i)}
		var exp_result = exp_manager.grant_exploration_exp(region_data, discovery_types[i])
		assert(exp_result == expected_values[i], "探索类型'%s'应授予%d点EXP" % [discovery_types[i], expected_values[i]])
	
	print("✓ 不同类型探索EXP测试通过")
	tests_passed += 3
	tests_total += 3

# 测试奇遇EXP授予
func test_encounter_exp_granting():
	var exp_manager = ExpAcquisitionManager.new()
	
	# 测试故事类奇遇
	var encounter_data = {"type": "story_encounter"}
	var completion_result = {}
	var exp_result = exp_manager.grant_encounter_exp(encounter_data, completion_result)
	
	assert(exp_result == 40, "故事类奇遇应授予40点EXP")
	
	print("✓ 奇遇EXP授予测试通过")
	tests_passed += 1
	tests_total += 1

# 测试不同类型奇遇EXP
func test_encounter_exp_with_different_types():
	var exp_manager = ExpAcquisitionManager.new()
	
	# 测试不同类型奇遇
	var encounter_types = ["story_encounter", "puzzle_encounter", "combat_encounter", "collection_encounter"]
	var expected_values = [40, 50, 60, 35]
	
	for i in range(encounter_types.size()):
		var encounter_data = {"type": encounter_types[i]}
		var completion_result = {}
		var exp_result = exp_manager.grant_encounter_exp(encounter_data, completion_result)
		assert(exp_result == expected_values[i], "奇遇类型'%s'应授予%d点EXP" % [encounter_types[i], expected_values[i]])
	
	print("✓ 不同类型奇遇EXP测试通过")
	tests_passed += 4
	tests_total += 4

# 测试任务EXP授予
func test_quest_exp_granting():
	var exp_manager = ExpAcquisitionManager.new()
	
	# 测试主线任务
	var quest_data = {"type": "main_quest"}
	var completion_type = "normal"
	var exp_result = exp_manager.grant_quest_exp(quest_data, completion_type)
	
	assert(exp_result == 100, "主线任务应授予100点EXP")
	
	print("✓ 任务EXP授予测试通过")
	tests_passed += 1
	tests_total += 1

# 测试不同类型任务完成EXP
func test_quest_exp_with_different_completion_types():
	var exp_manager = ExpAcquisitionManager.new()
	
	# 测试不同类型完成
	var quest_data = {"type": "main_quest"}
	var completion_types = ["normal", "quick", "perfect"]
	var expected_values = [100, int(100 * 1.1), int(100 * 1.2)]  # 100, 110, 120
	
	for i in range(completion_types.size()):
		var exp_result = exp_manager.grant_quest_exp(quest_data, completion_types[i])
		assert(exp_result == expected_values[i], "任务完成类型'%s'应授予%d点EXP" % [completion_types[i], expected_values[i]])
	
	print("✓ 不同类型任务完成EXP测试通过")
	tests_passed += 3
	tests_total += 3

# 测试EXP来源追溯
func test_exp_source_tracing():
	var exp_manager = ExpAcquisitionManager.new()
	
	# 连接信号以验证来源
	# 使用Dictionary包装状态，绕过GDScript lambda按值捕获的限制
	var verification_state := {
		"source_verified": false,
		"amount_verified": false,
	}
	
	var on_exp_granted := func(amount, source_type, _source_details):
		if source_type == exp_manager.EXP_SOURCE_COMBAT:
			verification_state["source_verified"] = true
		if amount > 0:
			verification_state["amount_verified"] = true
	
	exp_manager.exp_granted.connect(on_exp_granted)
	
	# 触发一次战斗EXP
	var enemy_data = {"type": "normal_enemy"}
	var battle_result = {}
	exp_manager.grant_combat_exp(enemy_data, battle_result)
	
	assert(verification_state["source_verified"], "EXP来源应正确追溯")
	assert(verification_state["amount_verified"], "EXP数量应正确记录")
	
	print("✓ EXP来源追溯测试通过")
	tests_passed += 2
	tests_total += 2

# 测试多个EXP来源
func test_multiple_exp_sources():
	var exp_manager = ExpAcquisitionManager.new()
	
	# 创建多个EXP来源
	var exp_sources = [
		{"type": exp_manager.EXP_SOURCE_COMBAT, "data": {"type": "normal_enemy"}, "result": {}},
		{"type": exp_manager.EXP_SOURCE_QUEST, "data": {"type": "main_quest"}, "result": "normal"},
		{"type": exp_manager.EXP_SOURCE_EXPLORATION, "data": {"name": "新手村"}, "result": "first_exploration"}
	]
	
	var result = exp_manager.grant_multiple_exp(exp_sources)
	
	# 验证总EXP
	var expected_total = 50 + 100 + 25  # 普通敌人 + 主线任务 + 首次探索
	assert(result.total_exp == expected_total, "多个EXP来源的总和应正确计算")
	
	# 验证各来源分解
	assert(result.breakdown.has(exp_manager.EXP_SOURCE_COMBAT), "分解应包含战斗来源")
	assert(result.breakdown.has(exp_manager.EXP_SOURCE_QUEST), "分解应包含任务来源")
	assert(result.breakdown.has(exp_manager.EXP_SOURCE_EXPLORATION), "分解应包含探索来源")
	
	print("✓ 多个EXP来源测试通过")
	tests_passed += 4
	tests_total += 4
