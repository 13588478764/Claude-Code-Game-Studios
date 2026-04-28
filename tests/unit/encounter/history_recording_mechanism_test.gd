# 历史记录机制单元测试
# 验证奇遇基础标识、时空上下文、结果奖励和玩家状态快照的记录

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_encounter_basic_identifiers_correctly_recorded())
	results.append(test_temporal_spatial_context_correctly_recorded())
	results.append(test_result_and_reward_summary_correctly_recorded())
	results.append(test_player_state_snapshot_correctly_recorded())
	
	return results

# 测试1: 奇遇基础标识正确记录
func test_encounter_basic_identifiers_correctly_recorded() -> TestResult:
	var result = TestResult.new()
	result.test_name = "奇遇基础标识正确记录"
	
	# 创建历史记录器实例
	var history_logger = load("res://src/scripts/encounter/history_logger.gd").new()
	
	# 创建测试数据
	var test_encounter_data = {
		"id": "test_encounter_001",
		"title": "测试奇遇",
		"type": "random",
		"outcome": "success",
		"rewards": ["item1", "exp100"],
		"position": Vector2(100, 200),
		"weather": "sunny",
		"player_data": {
			"level": 5,
			"realm": "ZhuJi",
			"attributes": {"luck": 80, "wisdom": 75}
		},
		"metadata": {"test": true}
	}
	
	# 记录奇遇
	var record_id = history_logger.log_encounter(test_encounter_data)
	
	# 获取记录并验证
	var record = history_logger.get_record_by_id(record_id)
	
	if record and record.encounter_id == "test_encounter_001" and record.title == "测试奇遇" and record.encounter_type == "random":
		result.passed = true
		result.message = "奇遇基础标识记录正确: ID=%s, 标题=%s, 类型=%s" % [record.encounter_id, record.title, record.encounter_type]
	else:
		result.passed = false
		result.message = "奇遇基础标识记录错误: ID=%s, 标题=%s, 类型=%s" % [record.encounter_id if record else "null", record.title if record else "null", record.encounter_type if record else "null"]
	
	return result

# 测试2: 时空上下文正确记录
func test_temporal_spatial_context_correctly_recorded() -> TestResult:
	var result = TestResult.new()
	result.test_name = "时空上下文正确记录"
	
	# 创建历史记录器实例
	var history_logger = load("res://src/scripts/encounter/history_logger.gd").new()
	
	# 创建测试数据
	var test_encounter_data = {
		"id": "test_encounter_002",
		"title": "时空测试奇遇",
		"type": "location",
		"outcome": "partial_success",
		"rewards": ["item2"],
		"position": Vector2(500, 300),
		"weather": "rainy",
		"player_data": {
			"level": 10,
			"realm": "JinDan",
			"attributes": {"luck": 90, "wisdom": 85}
		},
		"metadata": {"test": true}
	}
	
	# 记录奇遇
	var record_id = history_logger.log_encounter(test_encounter_data)
	
	# 获取记录并验证
	var record = history_logger.get_record_by_id(record_id)
	
	if record and record.timestamp > 0 and record.position == Vector2(500, 300) and record.weather == "rainy":
		result.passed = true
		result.message = "时空上下文记录正确: 时间戳=%g, 位置=%s, 天气=%s" % [record.timestamp, str(record.position), record.weather]
	else:
		result.passed = false
		result.message = "时空上下文记录错误: 时间戳=%g, 位置=%s, 天气=%s" % [record.timestamp if record else 0, str(record.position) if record else "null", record.weather if record else "null"]
	
	return result

# 测试3: 结果与奖励摘要正确记录
func test_result_and_reward_summary_correctly_recorded() -> TestResult:
	var result = TestResult.new()
	result.test_name = "结果与奖励摘要正确记录"
	
	# 创建历史记录器实例
	var history_logger = load("res://src/scripts/encounter/history_logger.gd").new()
	
	# 创建测试数据
	var test_encounter_data = {
		"id": "test_encounter_003",
		"title": "奖励测试奇遇",
		"type": "event",
		"outcome": "failure",
		"rewards": ["special_item", "rare_treasure", "exp500"],
		"position": Vector2(250, 150),
		"weather": "snowy",
		"player_data": {
			"level": 15,
			"realm": "YuanYing",
			"attributes": {"luck": 70, "wisdom": 95}
		},
		"metadata": {"test": true}
	}
	
	# 记录奇遇
	var record_id = history_logger.log_encounter(test_encounter_data)
	
	# 获取记录并验证
	var record = history_logger.get_record_by_id(record_id)
	
	if record and record.outcome == "failure" and record.rewards.size() == 3:
		result.passed = true
		result.message = "结果与奖励摘要记录正确: 结果=%s, 奖励数量=%d" % [record.outcome, record.rewards.size()]
	else:
		result.passed = false
		result.message = "结果与奖励摘要记录错误: 结果=%s, 奖励数量=%d" % [record.outcome if record else "null", record.rewards.size() if record else 0]
	
	return result

# 测试4: 玩家状态快照正确记录
func test_player_state_snapshot_correctly_recorded() -> TestResult:
	var result = TestResult.new()
	result.test_name = "玩家状态快照正确记录"
	
	# 创建历史记录器实例
	var history_logger = load("res://src/scripts/encounter/history_logger.gd").new()
	
	# 创建测试数据
	var test_encounter_data = {
		"id": "test_encounter_004",
		"title": "状态快照测试奇遇",
		"type": "random",
		"outcome": "success",
		"rewards": ["item4", "exp200"],
		"position": Vector2(400, 200),
		"weather": "cloudy",
		"player_data": {
			"level": 20,
			"realm": "HuaShen",
			"attributes": {"luck": 85, "wisdom": 90, "strength": 75, "agility": 80}
		},
		"metadata": {"test": true}
	}
	
	# 记录奇遇
	var record_id = history_logger.log_encounter(test_encounter_data)
	
	# 获取记录并验证
	var record = history_logger.get_record_by_id(record_id)
	
	if record and record.player_level == 20 and record.player_realm == "HuaShen" and record.player_attributes.get("luck", 0) == 85:
		result.passed = true
		result.message = "玩家状态快照记录正确: 等级=%d, 境界=%s, 福缘=%d" % [record.player_level, record.player_realm, record.player_attributes.get("luck", 0)]
	else:
		result.passed = false
		result.message = "玩家状态快照记录错误: 等级=%d, 境界=%s, 福缘=%d" % [record.player_level if record else 0, record.player_realm if record else "null", record.player_attributes.get("luck", 0) if record else 0]
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行历史记录机制测试...")
	print("================================")
	
	for result in test_results:
		if result.passed:
			print("✅ %s: %s" % [result.test_name, result.message])
			passed_count += 1
		else:
			print("❌ %s: %s" % [result.test_name, result.message])
	
	print("================================")
	print("测试结果: %d/%d 项测试通过" % [passed_count, total_count])
	
	if passed_count == total_count:
		print("🎉 所有测试都通过了！")
	else:
		print("⚠️  有 %d 项测试失败" % [total_count - passed_count])
	
	return passed_count == total_count