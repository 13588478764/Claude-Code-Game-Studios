# 奇遇记录管理系统单元测试
# 验证奇遇完成状态记录、连续失败计数器、历史记录管理和存档功能

extends Node

# 加载奇遇记录管理器
var EncounterRecordManager = load("res://src/scripts/encounter/encounter_record_manager.gd")

var encounter_record_manager
var test_result = {
	"passed": 0,
	"failed": 0,
	"total": 0,
	"details": []
}

func _ready():
	print("开始奇遇记录管理系统单元测试...")
	
	# 运行所有测试
	test_encounter_completion_status_recording()
	test_consecutive_failure_counter_management()
	test_encounter_history_recording()
	test_save_load_functionality()
	
	# 输出测试结果
	print("\n=== 奇遇记录管理系统单元测试结果 ===")
	print("通过: %d" % test_result.passed)
	print("失败: %d" % test_result.failed)
	print("总计: %d" % test_result.total)
	
	if test_result.failed == 0:
		print("✅ 所有测试通过！")
	else:
		print("❌ 有 %d 个测试失败" % test_result.failed)
	
	for detail in test_result.details:
		print(detail)

# 测试奇遇完成状态记录
func test_encounter_completion_status_recording():
	print("\n--- 测试奇遇完成状态记录 ---")
	
	encounter_record_manager = EncounterRecordManager.new()
	
	# 测试标记奇遇为已完成
	var test_id = "JHR_123456_789"
	var result = encounter_record_manager.mark_encounter_completed(test_id)
	if result:
		add_test_result("奇遇完成状态记录", true, "成功标记奇遇为已完成: %s" % test_id)
	else:
		add_test_result("奇遇完成状态记录", false, "标记奇遇为已完成失败: %s" % test_id)
	
	# 测试检查奇遇是否已完成
	var is_completed = encounter_record_manager.is_encounter_completed(test_id)
	if is_completed:
		add_test_result("奇遇完成状态记录", true, "正确检测到奇遇已完成: %s" % test_id)
	else:
		add_test_result("奇遇完成状态记录", false, "未能正确检测到奇遇已完成: %s" % test_id)
	
	# 测试重复标记（应该失败）
	var duplicate_result = encounter_record_manager.mark_encounter_completed(test_id)
	if !duplicate_result:
		add_test_result("奇遇完成状态记录", true, "正确阻止重复标记奇遇: %s" % test_id)
	else:
		add_test_result("奇遇完成状态记录", false, "未能阻止重复标记奇遇: %s" % test_id)

# 测试连续失败计数器管理
func test_consecutive_failure_counter_management():
	print("\n--- 测试连续失败计数器管理 ---")
	
	encounter_record_manager = EncounterRecordManager.new()
	
	# 测试初始计数器值
	if encounter_record_manager.get_consecutive_failures() == 0:
		add_test_result("连续失败计数器管理", true, "初始失败计数器为0")
	else:
		add_test_result("连续失败计数器管理", false, "初始失败计数器不为0")
	
	# 测试失败计数器递增
	encounter_record_manager.update_failure_counter(false)  # 模拟失败
	if encounter_record_manager.get_consecutive_failures() == 1:
		add_test_result("连续失败计数器管理", true, "失败后计数器递增到1")
	else:
		add_test_result("连续失败计数器管理", false, "失败后计数器未正确递增")
	
	# 测试成功后计数器重置
	encounter_record_manager.update_failure_counter(true)  # 模拟成功
	if encounter_record_manager.get_consecutive_failures() == 0:
		add_test_result("连续失败计数器管理", true, "成功后计数器重置为0")
	else:
		add_test_result("连续失败计数器管理", false, "成功后计数器未正确重置")
	
	# 测试多次失败
	encounter_record_manager.update_failure_counter(false)
	encounter_record_manager.update_failure_counter(false)
	encounter_record_manager.update_failure_counter(false)
	if encounter_record_manager.get_consecutive_failures() == 3:
		add_test_result("连续失败计数器管理", true, "多次失败后计数器正确累加到3")
	else:
		add_test_result("连续失败计数器管理", false, "多次失败后计数器未正确累加")

# 测试奇遇历史记录
func test_encounter_history_recording():
	print("\n--- 测试奇遇历史记录 ---")
	
	encounter_record_manager = EncounterRecordManager.new()
	
	# 添加几个历史记录
	var test_rewards = [{"type": "silver", "amount": 100}, {"type": "material", "amount": 5}]
	encounter_record_manager.add_encounter_to_history("JHR_111111_001", encounter_record_manager.EncounterType.JIANGHU_RUMOR, test_rewards, 50)
	encounter_record_manager.add_encounter_to_history("TCD_222222_002", encounter_record_manager.EncounterType.TIANCAI_DIBAO, test_rewards, 60)
	encounter_record_manager.add_encounter_to_history("GRZ_333333_003", encounter_record_manager.EncounterType.GAOREN_ZHIDIAN, test_rewards, 70)
	
	# 检查历史记录数量
	var history = encounter_record_manager.get_encounter_history()
	if history.size() == 3:
		add_test_result("奇遇历史记录", true, "正确添加了3个历史记录")
	else:
		add_test_result("奇遇历史记录", false, "历史记录数量不正确，期望3，实际%d" % history.size())
	
	# 检查特定类型的历史记录
	var jianghu_history = encounter_record_manager.get_encounters_by_type(encounter_record_manager.EncounterType.JIANGHU_RUMOR)
	if jianghu_history.size() == 1 and jianghu_history[0].encounter_type == encounter_record_manager.EncounterType.JIANGHU_RUMOR:
		add_test_result("奇遇历史记录", true, "正确检索到江湖传闻类型的记录")
	else:
		add_test_result("奇遇历史记录", false, "未能正确检索到江湖传闻类型的记录")
	
	# 检查完成的奇遇数量
	var completed_count = encounter_record_manager.get_completed_encounter_count()
	# 注意：这里我们之前标记了一个奇遇为完成，所以应该有1个完成的
	if completed_count == 0:  # 实际上我们还没有标记任何在这个新实例中
		add_test_result("奇遇历史记录", true, "完成的奇遇数量正确（当前为0）")
	else:
		add_test_result("奇遇历史记录", false, "完成的奇遇数量不正确，期望0，实际%d" % completed_count)

# 测试存档/读档功能
func test_save_load_functionality():
	print("\n--- 测试存档/读档功能 ---")
	
	encounter_record_manager = EncounterRecordManager.new()
	
	# 设置一些测试数据
	encounter_record_manager.mark_encounter_completed("JHR_TEST_001")
	encounter_record_manager.update_failure_counter(false)  // 增加失败计数
	encounter_record_manager.update_failure_counter(false)  // 再增加失败计数
	var test_rewards = [{"type": "silver", "amount": 200}]
	encounter_record_manager.add_encounter_to_history("GRZ_TEST_002", encounter_record_manager.EncounterType.GAOREN_ZHIDIAN, test_rewards, 80)
	
	# 保存数据
	var saved_data = encounter_record_manager.save_records()
	
	# 创建新的管理器实例并加载数据
	var new_encounter_manager = EncounterRecordManager.new()
	new_encounter_manager.load_records(saved_data)
	
	# 验证加载的数据
	var is_loaded_completed = new_encounter_manager.is_encounter_completed("JHR_TEST_001")
	if is_loaded_completed:
		add_test_result("存档/读档功能", true, "成功加载已完成的奇遇记录")
	else:
		add_test_result("存档/读档功能", false, "未能加载已完成的奇遇记录")
	
	if new_encounter_manager.get_consecutive_failures() == 2:
		add_test_result("存档/读档功能", true, "成功加载连续失败计数器（值为2）")
	else:
		add_test_result("存档/读档功能", false, "未能正确加载连续失败计数器")
	
	var loaded_history = new_encounter_manager.get_encounter_history()
	if loaded_history.size() == 1:
		add_test_result("存档/读档功能", true, "成功加载历史记录（数量为1）")
	else:
		add_test_result("存档/读档功能", false, "未能正确加载历史记录")
	
	# 测试JSON导出/导入功能
	var json_export = encounter_record_manager.export_records_to_json()
	var import_success = new_encounter_manager.import_records_from_json(json_export)
	if import_success:
		add_test_result("存档/读档功能", true, "JSON导出/导入功能正常")
	else:
		add_test_result("存档/读档功能", false, "JSON导出/导入功能异常")

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