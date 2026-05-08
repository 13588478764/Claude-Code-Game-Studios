## 数据持久化与管理单元测试
## 验证历史记录序列化、存档加载、内存管理和存储空间管理
extends GutTest

var persistence_manager

func before_each():
	persistence_manager = HistoryPersistenceManager.new()
	add_child_autofree(persistence_manager)

func after_each():
	# 清理测试存档文件
	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists("encounter_history.json"):
			dir.remove("encounter_history.json")
		if dir.file_exists("test_encounter_history.json"):
			dir.remove("test_encounter_history.json")

## 测试历史记录正确序列化到存档文件
func test_history_records_correctly_serialize_to_save_file():
	for i in range(3):
		var player_state = {"level": i+1, "health": 100.0 - (i*10)}
		var rewards = ["item_%d" % i, "exp_%d" % (i*100)]
		var metadata = {"test": true, "iteration": i}
		persistence_manager.add_history_record("encounter_%d" % i, player_state, "success", rewards, metadata)
	
	var serialized_data = persistence_manager.serialize_to_save()
	assert_false(serialized_data.is_empty(), "序列化数据不应为空")
	
	var json = JSON.new()
	var parse_result = json.parse(serialized_data)
	assert_eq(parse_result, OK, "JSON解析应成功")
	
	var data = json.data
	assert_true(data.has("records"), "序列化数据应有records字段")
	assert_eq(data.records.size(), 3, "应包含3条历史记录")
	assert_eq(data.records[0].encounter_id, "encounter_0", "第一条记录的encounter_id应正确")

## 测试存档加载时历史记录正确恢复
func test_archive_loading_restores_history_correctly():
	var test_save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"record_count": 2,
		"records": [
			{
				"id": "record_1",
				"encounter_id": "test_encounter_1",
				"timestamp": Time.get_unix_time_from_system(),
				"player_state": {"level": 5, "health": 80.0},
				"outcome": "success",
				"rewards": ["item_1", "exp_100"],
				"metadata": {"location": "test_area"}
			},
			{
				"id": "record_2",
				"encounter_id": "test_encounter_2",
				"timestamp": Time.get_unix_time_from_system(),
				"player_state": {"level": 10, "health": 90.0},
				"outcome": "partial_success",
				"rewards": ["item_2", "skill_point"],
				"metadata": {"location": "test_area_2"}
			}
		]
	}
	
	var json_string = JSON.stringify(test_save_data)
	var loaded_records = persistence_manager.deserialize_from_save(json_string)
	
	assert_eq(loaded_records.size(), 2, "应加载2条历史记录")
	assert_eq(loaded_records[0].encounter_id, "test_encounter_1", "第一条记录的encounter_id应正确")
	assert_eq(loaded_records[1].encounter_id, "test_encounter_2", "第二条记录的encounter_id应正确")
	assert_eq(loaded_records[0].player_state.level, 5, "玩家等级应正确")

## 测试内存管理限制记录数量
func test_memory_management_limits_records():
	persistence_manager.set_max_active_records(3)
	
	for i in range(5):
		var player_state = {"level": i+1, "health": 100.0}
		var rewards = ["item_%d" % i]
		var metadata = {"test": true}
		persistence_manager.add_history_record("encounter_%d" % i, player_state, "success", rewards, metadata)
	
	assert_true(persistence_manager.get_record_count() <= 3, "记录数量不应超过限制")

## 测试存储空间管理返回正确大小估算
func test_storage_space_management_returns_size_estimate():
	for i in range(3):
		var player_state = {"level": i+1, "health": 100.0}
		var rewards = ["item_%d" % i]
		var metadata = {"test": true}
		persistence_manager.add_history_record("encounter_%d" % i, player_state, "success", rewards, metadata)
	
	var current_size = persistence_manager.get_current_save_size_estimate()
	assert_true(current_size > 0, "存档大小估算应大于0")
	assert_true(current_size < persistence_manager.MAX_SAVE_SIZE, "存档大小应在限制范围内")

## 测试保存和加载文件功能
func test_save_and_load_from_file():
	for i in range(2):
		var player_state = {"level": i+1, "health": 100.0}
		var rewards = ["item_%d" % i]
		var metadata = {"test": true}
		persistence_manager.add_history_record("test_enc_%d" % i, player_state, "success", rewards, metadata)
	
	var save_result = persistence_manager.save_to_file("user://test_encounter_history.json")
	assert_true(save_result, "保存到文件应成功")
	
	var loaded_count_before = persistence_manager.get_record_count()
	persistence_manager.clear_all_records()
	assert_eq(persistence_manager.get_record_count(), 0, "清除后记录数应为0")
	
	var load_result = persistence_manager.load_from_file("user://test_encounter_history.json")
	assert_true(load_result, "从文件加载应成功")
	assert_eq(persistence_manager.get_record_count(), loaded_count_before, "加载后记录数应恢复")

## 测试文件不存在时加载返回false
func test_load_nonexistent_file_returns_false():
	var result = persistence_manager.load_from_file("user://nonexistent_file.json")
	assert_false(result, "文件不存在时应返回false")

## 测试无效JSON解析返回空数组
func test_invalid_json_returns_empty_array():
	var records = persistence_manager.deserialize_from_save("invalid json")
	assert_true(records.is_empty(), "无效JSON应返回空数组")

## 测试清除所有记录
func test_clear_all_records():
	for i in range(3):
		var player_state = {"level": i+1, "health": 100.0}
		persistence_manager.add_history_record("enc_%d" % i, player_state, "success", ["item"], {})
	
	persistence_manager.clear_all_records()
	assert_eq(persistence_manager.get_record_count(), 0, "清除后记录数应为0")
	assert_eq(persistence_manager.record_id_counter, 0, "清除后计数器应重置")
