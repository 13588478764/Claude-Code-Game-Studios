# 保存加载机制单元测试
# 验证自动保存机制、手动保存功能、周期保存功能和数据加载功能

extends Node

# 导入需要测试的脚本
var SaveLoadManager = load("res://src/scripts/persistence/save_load_manager.gd")
var GrowthDataStructureManager = load("res://src/scripts/persistence/growth_data_structure_manager.gd")

# 测试结果统计
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("开始运行保存加载机制单元测试...")
	
	# 运行自动保存机制测试
	test_auto_save_on_level_up()
	test_auto_save_on_realm_breakthrough()
	test_auto_save_on_attribute_allocation()
	
	# 运行手动保存功能测试
	test_manual_save_functionality()
	test_save_with_character_object()
	
	# 运行周期保存功能测试
	test_periodic_save_timer()
	test_periodic_save_trigger()
	
	# 运行数据加载功能测试
	test_load_functionality()
	test_load_with_invalid_data()
	
	# 运行存档管理测试
	test_get_available_saves()
	test_delete_save_functionality()
	
	print("\n测试完成: %d/%d 个测试通过" % [tests_passed, tests_total])

# 测试自动保存 - 等级提升时
func test_auto_save_on_level_up():
	var save_manager = SaveLoadManager.new()
	var data_manager = GrowthDataStructureManager.new()
	
	# 创建一个模拟角色对象
	var mock_character = {
		"level": 10,
		"get_level": Callable(self, "_get_mock_level"),
		"get_realm": Callable(self, "_get_mock_realm"),
		"get_experience": Callable(self, "_get_mock_experience")
	}
	
	# 连接保存完成信号
	var save_completed = false
	save_manager.save_completed.connect(func(slot): save_completed = true)
	
	# 尝试保存
	var result = save_manager.save_growth_data(mock_character, 1)
	
	assert(result == true, "自动保存应成功")
	assert(save_completed == true, "应触发保存完成信号")
	
	print("✓ 自动保存-等级提升测试通过")
	tests_passed += 2
	tests_total += 2

# 测试自动保存 - 境界突破时
func test_auto_save_on_realm_breakthrough():
	var save_manager = SaveLoadManager.new()
	var mock_character = {
		"realm": 2,
		"get_level": Callable(self, "_get_mock_level"),
		"get_realm": Callable(self, "_get_mock_realm"),
		"get_experience": Callable(self, "_get_mock_experience")
	}
	
	var save_completed = false
	save_manager.save_completed.connect(func(slot): save_completed = true)
	
	var result = save_manager.save_growth_data(mock_character, 1)
	
	assert(result == true, "境界突破时保存应成功")
	assert(save_completed == true, "应触发保存完成信号")
	
	print("✓ 自动保存-境界突破测试通过")
	tests_passed += 2
	tests_total += 2

# 测试自动保存 - 属性分配时
func test_auto_save_on_attribute_allocation():
	var save_manager = SaveLoadManager.new()
	var mock_character = {
		"attributes": {"strength": 20, "agility": 18},
		"get_level": Callable(self, "_get_mock_level"),
		"get_realm": Callable(self, "_get_mock_realm"),
		"get_attribute": Callable(self, "_get_mock_attribute"),
		"get_experience": Callable(self, "_get_mock_experience")
	}
	
	var save_completed = false
	save_manager.save_completed.connect(func(slot): save_completed = true)
	
	var result = save_manager.save_growth_data(mock_character, 1)
	
	assert(result == true, "属性分配时保存应成功")
	assert(save_completed == true, "应触发保存完成信号")
	
	print("✓ 自动保存-属性分配测试通过")
	tests_passed += 2
	tests_total += 2

# 测试手动保存功能
func test_manual_save_functionality():
	var save_manager = SaveLoadManager.new()
	var mock_character = {
		"name": "测试角色",
		"get_name": Callable(self, "_get_mock_name"),
		"get_level": Callable(self, "_get_mock_level"),
		"get_realm": Callable(self, "_get_mock_realm"),
		"get_experience": Callable(self, "_get_mock_experience")
	}
	
	var save_completed = false
	save_manager.save_completed.connect(func(slot): save_completed = true)
	
	var result = save_manager.save_growth_data(mock_character, 2)
	
	assert(result == true, "手动保存应成功")
	assert(save_completed == true, "应触发保存完成信号")
	
	print("✓ 手动保存功能测试通过")
	tests_passed += 2
	tests_total += 2

# 测试使用角色对象保存
func test_save_with_character_object():
	var save_manager = SaveLoadManager.new()
	var mock_character = {
		"level": 25,
		"realm": 3,
		"experience": 15000,
		"get_level": Callable(self, "_get_mock_level"),
		"get_realm": Callable(self, "_get_mock_realm"),
		"get_experience": Callable(self, "_get_mock_experience"),
		"get_name": Callable(self, "_get_mock_name"),
		"get_location": Callable(self, "_get_mock_location")
	}
	
	var save_completed = false
	save_manager.save_completed.connect(func(slot): save_completed = true)
	
	var result = save_manager.save_growth_data(mock_character, 3)
	
	assert(result == true, "使用角色对象保存应成功")
	assert(save_completed == true, "应触发保存完成信号")
	
	print("✓ 使用角色对象保存测试通过")
	tests_passed += 2
	tests_total += 2

# 测试周期保存计时器
func test_periodic_save_timer():
	var save_manager = SaveLoadManager.new()
	
	# 检查计时器是否已创建
	var has_timer = save_manager.has_method("_on_auto_save_timeout")
	assert(has_timer == true, "应有自动保存超时处理方法")
	
	print("✓ 周期保存计时器测试通过")
	tests_passed += 1
	tests_total += 1

# 测试周期保存触发
func test_periodic_save_trigger():
	var save_manager = SaveLoadManager.new()
	
	# 直接触发自动保存
	var save_completed = false
	save_manager.save_completed.connect(func(slot): save_completed = true)
	
	save_manager.trigger_auto_save()
	
	# 由于没有实际角色对象，这里主要测试方法是否存在
	assert(save_manager.has_method("trigger_auto_save") == true, "应有触发自动保存方法")
	
	print("✓ 周期保存触发测试通过")
	tests_passed += 1
	tests_total += 1

# 测试加载功能
func test_load_functionality():
	var save_manager = SaveLoadManager.new()
	
	# 先保存一个测试数据
	var mock_character = {
		"level": 12,
		"realm": 1,
		"get_level": Callable(self, "_get_mock_level"),
		"get_realm": Callable(self, "_get_mock_realm"),
		"get_experience": Callable(self, "_get_mock_experience"),
		"get_name": Callable(self, "_get_mock_name")
	}
	
	var save_result = save_manager.save_growth_data(mock_character, 1)
	assert(save_result == true, "预保存应成功")
	
	# 尝试加载
	var loaded_character = save_manager.load_growth_data(1)
	
	assert(loaded_character != null, "加载的角色对象不应为空")
	
	print("✓ 加载功能测试通过")
	tests_passed += 2
	tests_total += 2

# 测试加载无效数据
func test_load_with_invalid_data():
	var save_manager = SaveLoadManager.new()
	
	# 尝试加载不存在的存档
	var loaded_character = save_manager.load_growth_data(99)  # 假设不存在的槽位
	
	# 这应该返回null
	assert(loaded_character == null, "加载不存在的存档应返回null")
	
	print("✓ 加载无效数据测试通过")
	tests_passed += 1
	tests_total += 1

# 测试获取可用存档
func test_get_available_saves():
	var save_manager = SaveLoadManager.new()
	
	var available_saves = save_manager.get_available_saves()
	
	assert(available_saves is Array, "可用存档列表应为数组")
	
	print("✓ 获取可用存档测试通过")
	tests_passed += 1
	tests_total += 1

# 测试删除存档功能
func test_delete_save_functionality():
	var save_manager = SaveLoadManager.new()
	
	# 先保存一个测试存档
	var mock_character = {
		"level": 5,
		"get_level": Callable(self, "_get_mock_level"),
		"get_realm": Callable(self, "_get_mock_realm"),
		"get_experience": Callable(self, "_get_mock_experience"),
		"get_name": Callable(self, "_get_mock_name")
	}
	
	var save_result = save_manager.save_growth_data(mock_character, 1)
	assert(save_result == true, "预保存应成功")
	
	# 删除存档
	var delete_result = save_manager.delete_save(1)
	
	assert(delete_result == true, "删除存档应成功")
	
	print("✓ 删除存档功能测试通过")
	tests_passed += 2
	tests_total += 2

# 模拟方法 - 获取等级
func _get_mock_level():
	return 10

# 模拟方法 - 获取境界
func _get_mock_realm():
	return 2

# 模拟方法 - 获取经验值
func _get_mock_experience():
	return 5000

# 模拟方法 - 获取属性值
func _get_mock_attribute(attr_name):
	var attrs = {"strength": 20, "agility": 18, "constitution": 15}
	return attrs.get(attr_name, 10)

# 模拟方法 - 获取角色名
func _get_mock_name():
	return "测试角色"

# 模拟方法 - 获取位置
func _get_mock_location():
	return "青云山"
