extends GutTest

# 测试1: 奇遇基础标识正确记录
func test_encounter_basic_identifiers_correctly_recorded():
	var history_logger = load("res://src/scripts/encounter/history_logger.gd").new()
	add_child(history_logger)
	
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
		}
	}
	
	var record_id = history_logger.log_encounter(test_encounter_data)
	var record = history_logger.get_record_by_id(record_id)
	
	assert_not_null(record, "记录应该存在")
	assert_eq(record.encounter_id, "test_encounter_001", "奇遇ID应该正确")
	assert_eq(record.title, "测试奇遇", "奇遇标题应该正确")
	assert_eq(record.encounter_type, "random", "奇遇类型应该正确")


# 测试2: 时空上下文正确记录
func test_temporal_spatial_context_correctly_recorded():
	var history_logger = load("res://src/scripts/encounter/history_logger.gd").new()
	add_child(history_logger)
	
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
		}
	}
	
	var record_id = history_logger.log_encounter(test_encounter_data)
	var record = history_logger.get_record_by_id(record_id)
	
	assert_not_null(record, "记录应该存在")
	assert_greater_than(record.timestamp, 0, "时间戳应该大于0")
	assert_eq(record.position, Vector2(500, 300), "位置应该正确")
	assert_eq(record.weather, "rainy", "天气应该正确")


# 测试3: 结果与奖励摘要正确记录
func test_result_and_reward_summary_correctly_recorded():
	var history_logger = load("res://src/scripts/encounter/history_logger.gd").new()
	add_child(history_logger)
	
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
		}
	}
	
	var record_id = history_logger.log_encounter(test_encounter_data)
	var record = history_logger.get_record_by_id(record_id)
	
	assert_not_null(record, "记录应该存在")
	assert_eq(record.outcome, "failure", "结果应该正确")
	assert_eq(record.rewards.size(), 3, "奖励数量应该正确")


# 测试4: 玩家状态快照正确记录
func test_player_state_snapshot_correctly_recorded():
	var history_logger = load("res://src/scripts/encounter/history_logger.gd").new()
	add_child(history_logger)
	
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
		}
	}
	
	var record_id = history_logger.log_encounter(test_encounter_data)
	var record = history_logger.get_record_by_id(record_id)
	
	assert_not_null(record, "记录应该存在")
	assert_eq(record.player_level, 20, "玩家等级应该正确")
	assert_eq(record.player_realm, "HuaShen", "玩家境界应该正确")
	assert_eq(record.player_attributes.get("luck", 0), 85, "玩家福缘应该正确")