# 数据持久化与管理单元测试
# 验证历史记录序列化、存档加载、内存管理和存储空间管理

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_history_records_correctly_serialize_to_save_file())
	results.append(test_archive_loading_restores_history_correctly())
	results.append(test_memory_management_normal())
	results.append(test_storage_space_management_normal())
	
	return results

# 测试1: 历史记录正确序列化到存档文件
func test_history_records_correctly_serialize_to_save_file() -> TestResult:
	var result = TestResult.new()
	result.test_name = "历史记录正确序列化到存档文件"
	
	# 创建历史记录持久化管理器实例
	var persistence_manager = load("res://src/scripts/encounter/history_persistence_manager.gd").new()
	
	# 添加一些测试记录
	for i in range(3):
		var player_state = {"level": i+1, "health": 100.0 - (i*10), "position": Vector2(i*10, i*10)}
		var rewards = ["item_%d" % i, "exp_%d" % (i*100)]
		var metadata = {"test": true, "iteration": i, "timestamp": Time.get_unix_time_from_system()}
		
		persistence_manager.add_history_record("encounter_%d" % i, player_state, "success", rewards, metadata)
	
	# 序列化到存档
	var serialized_data = persistence_manager.serialize_to_save()
	
	# 验证序列化数据不为空
	if serialized_data != "" and serialized_data.length() > 0:
		# 尝试解析JSON以验证格式正确
		var json = JSON.new()
		var parse_result = json.parse(serialized_data)
		
		if parse_result == OK:
			var data = json.data
			if data.has("records") and data.records.size() == 3:
				result.passed = true
				result.message = "成功序列化了 %d 条历史记录，JSON格式正确" % data.records.size()
			else:
				result.passed = false
				result.message = "序列化数据格式错误：期望3条记录，实际 %d 条" % data.records.size()
		else:
			result.passed = false
			result.message = "序列化数据不是有效的JSON格式"
	else:
		result.passed = false
		result.message = "序列化数据为空"
	
	return result

# 测试2: 存档加载时历史记录正确恢复
func test_archive_loading_restores_history_correctly() -> TestResult:
	var result = TestResult.new()
	result.test_name = "存档加载时历史记录正确恢复"
	
	# 创建历史记录持久化管理器实例
	var persistence_manager = load("res://src/scripts/encounter/history_persistence_manager.gd").new()
	
	# 创建测试存档数据
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
	
	# 从存档反序列化
	var loaded_records = persistence_manager.deserialize_from_save(json_string)
	
	# 验证加载的记录数量和内容
	if loaded_records.size() == 2:
		var first_record = loaded_records[0]
		var second_record = loaded_records[1]
		
		if first_record.encounter_id == "test_encounter_1" and second_record.encounter_id == "test_encounter_2":
			result.passed = true
			result.message = "成功从存档加载了 %d 条历史记录，内容正确" % loaded_records.size()
		else:
			result.passed = false
			result.message = "加载的记录内容不正确"
	else:
		result.passed = false
		result.message = "加载的记录数量不正确：期望2条，实际 %d 条" % loaded_records.size()
	
	return result

# 测试3: 内存管理正常
func test_memory_management_normal() -> TestResult:
	var result = TestResult.new()
	result.test_name = "内存管理正常"
	
	# 创建历史记录持久化管理器实例
	var persistence_manager = load("res://src/scripts/encounter/history_persistence_manager.gd").new()
	
	# 设置较小的活跃记录限制以进行测试
	persistence_manager.set_max_active_records(3)
	
	# 添加超过限制的记录
	for i in range(5):
		var player_state = {"level": i+1, "health": 100.0}
		var rewards = ["item_%d" % i]
		var metadata = {"test": true, "iteration": i}
		
		persistence_manager.add_history_record("encounter_%d" % i, player_state, "success", rewards, metadata)
	
	# 检查内存管理是否生效
	var current_count = persistence_manager.get_record_count()
	
	if current_count == 3:
		# 检查是否保留了最新的3条记录
		var all_records = persistence_manager.get_all_records()
		var record_ids = []
		for record in all_records:
			record_ids.append(record.encounter_id)
		
		# 应该保留的是 encounter_2, encounter_3, encounter_4 (最新的3条)
		var expected_ids = ["encounter_2", "encounter_3", "encounter_4"]
		var has_correct_records = true
		for expected_id in expected_ids:
			if not record_ids.has(expected_id):
				has_correct_records = false
				break
		
		if has_correct_records:
			result.passed = true
			result.message = "内存管理正常：限制为3条，当前记录数为 %d，保留了最新的记录" % current_count
		else:
			result.passed = false
			result.message = "内存管理异常：未保留最新的记录"
	else:
		result.passed = false
		result.message = "内存管理异常：期望3条记录，实际 %d 条" % current_count
	
	return result

# 测试4: 存储空间管理正常
func test_storage_space_management_normal() -> TestResult:
	var result = TestResult.new()
	result.test_name = "存储空间管理正常"
	
	# 创建历史记录持久化管理器实例
	var persistence_manager = load("res://src/scripts/encounter/history_persistence_manager.gd").new()
	
	# 添加一些记录
	for i in range(3):
		var player_state = {"level": i+1, "health": 100.0 - (i*10), "detailed_info": "This is a very long string to increase the save file size for testing purposes. " + "x" * 100}
		var rewards = ["item_%d_with_very_long_name_to_increase_save_size" % i, "exp_%d" % (i*100)]
		var metadata = {"test": true, "iteration": i, "detailed_metadata": "y" * 200}
		
		persistence_manager.add_history_record("encounter_%d_with_very_long_name_for_testing_purposes" % i, player_state, "success", rewards, metadata)
	
	# 获取当前存档大小估算
	var current_size = persistence_manager.get_current_save_size_estimate()
	var max_size = persistence_manager.MAX_SAVE_SIZE
	
	# 验证大小估算功能正常工作
	if current_size > 0:
		result.passed = true
		result.message = "存储空间管理正常：当前存档大小估算为 %d 字节，限制为 %d 字节" % [current_size, max_size]
	else:
		result.passed = false
		result.message = "存储空间管理异常：无法估算存档大小"
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行数据持久化与管理测试...")
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