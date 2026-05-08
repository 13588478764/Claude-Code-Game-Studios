## 奇遇记录管理系统单元测试
## 验证奇遇完成状态记录、连续失败计数器、历史记录管理和存档功能
extends GutTest

var record_manager

func before_each():
	record_manager = EncounterRecordManager.new()
	add_child_autofree(record_manager)

func after_each():
	# 清理测试存档文件
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("encounter_records.json"):
		dir.remove("encounter_records.json")

## 测试标记奇遇完成后记录存在
func test_mark_encounter_completed_adds_to_list():
	record_manager.mark_encounter_completed("JiangHuRumor_1234567890")
	assert_true(record_manager.completed_encounters.has("JiangHuRumor_1234567890"), "奇遇应添加到已完成列表")

## 测试检查奇遇完成状态正确
func test_is_encounter_completed_returns_correct():
	record_manager.mark_encounter_completed("test_encounter_001")
	assert_true(record_manager.is_encounter_completed("test_encounter_001"), "已标记的奇遇应返回完成")
	assert_false(record_manager.is_encounter_completed("unknown_encounter"), "未标记的奇遇应返回未完成")

## 测试重复标记同一奇遇不重复添加
func test_duplicate_mark_does_not_duplicate_entry():
	record_manager.mark_encounter_completed("test_encounter_001")
	record_manager.mark_encounter_completed("test_encounter_001")
	var count = 0
	for eid in record_manager.completed_encounters:
		if eid == "test_encounter_001":
			count += 1
	assert_eq(count, 1, "同一奇遇不应重复添加")

## 测试连续失败计数器更新
func test_failure_counter_updates_on_failure():
	record_manager.consecutive_failures = 0
	record_manager.update_failure_counter(false)
	assert_eq(record_manager.consecutive_failures, 1, "失败后计数器应增加1")

## 测试成功重置失败计数器
func test_success_resets_failure_counter():
	record_manager.consecutive_failures = 5
	record_manager.update_failure_counter(true)
	assert_eq(record_manager.consecutive_failures, 0, "成功后计数器应重置为0")

## 测试连续多次失败达到保底
func test_consecutive_failures_reach_guarantee():
	for i in range(19):
		record_manager.update_failure_counter(false)
	assert_true(record_manager.consecutive_failures >= 19, "连续失败应接近保底阈值")

## 测试历史记录包含正确数据
func test_history_entry_contains_correct_data():
	record_manager.mark_encounter_completed("JiangHuRumor_1234567890")
	var history = record_manager.get_encounter_history()
	assert_true(history.size() > 0, "历史记录应至少有一条")
	var entry = history[0]
	assert_true(entry.has("id"), "历史记录应有id字段")
	assert_true(entry.has("timestamp"), "历史记录应有timestamp字段")
	assert_true(entry.has("type"), "历史记录应有type字段")
	assert_eq(entry.type, "JiangHuRumor", "奇遇类型应正确提取")

## 测试按类型查询历史记录
func test_get_encounters_by_type():
	record_manager.mark_encounter_completed("JiangHuRumor_111")
	record_manager.mark_encounter_completed("TianCaiDiBao_222")
	record_manager.mark_encounter_completed("JiangHuRumor_333")
	var jianghu_entries = record_manager.get_encounters_by_type("JiangHuRumor")
	assert_eq(jianghu_entries.size(), 2, "江湖传闻类型记录应为2条")

## 测试从ID提取奇遇类型
func test_extract_type_from_id():
	assert_eq(record_manager.extract_encounter_type_from_id("JiangHuRumor_1234567890"), "JiangHuRumor", "类型提取应正确")
	assert_eq(record_manager.extract_encounter_type_from_id("TianCaiDiBao_0"), "TianCaiDiBao", "类型提取应正确")

## 测试保存和加载记录
func test_save_and_load_records():
	record_manager.mark_encounter_completed("test_encounter_001")
	record_manager.consecutive_failures = 5
	var save_result = record_manager.save_records()
	assert_true(save_result, "保存应成功")
	# 重置数据
	record_manager.reset_all_records()
	# 重新加载
	var load_result = record_manager.load_records()
	assert_true(load_result, "加载应成功")
	assert_true(record_manager.is_encounter_completed("test_encounter_001"), "加载后奇遇应标记为完成")
	assert_eq(record_manager.consecutive_failures, 5, "加载后失败计数器应恢复")

## 测试加载不存在的文件返回false
func test_load_nonexistent_file_returns_false():
	var result = record_manager.load_records()
	assert_false(result, "文件不存在时应返回false")

## 测试重置所有记录
func test_reset_all_records():
	record_manager.mark_encounter_completed("test_001")
	record_manager.update_failure_counter(false)
	record_manager.reset_all_records()
	assert_eq(record_manager.completed_encounters.size(), 0, "重置后已完成列表应为空")
	assert_eq(record_manager.encounter_history.size(), 0, "重置后历史记录应为空")
	assert_eq(record_manager.consecutive_failures, 0, "重置后失败计数器应为0")

## 测试获取状态信息
func test_get_status_info():
	record_manager.mark_encounter_completed("test_001")
	var status = record_manager.get_status_info()
	assert_true(status.has("completed_count"), "状态信息应有completed_count")
	assert_true(status.has("consecutive_failures"), "状态信息应有consecutive_failures")
	assert_true(status.has("history_count"), "状态信息应有history_count")

## 测试统计信息计算正确
func test_statistics_calculation():
	record_manager.mark_encounter_completed("JiangHuRumor_001")
	record_manager.mark_encounter_completed("JiangHuRumor_002")
	record_manager.mark_encounter_completed("TianCaiDiBao_003")
	var stats = record_manager.get_statistics()
	assert_eq(stats.total_completed, 3, "总完成数应等于completed_encounters数量")
	assert_eq(stats.total_history, 3, "总历史记录数应为3")
	assert_true(stats.type_distribution.has("JiangHuRumor"), "统计应包含江湖传闻类型")
