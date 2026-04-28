# 装备管理功能单元测试
# 验证装备获取、存储、筛选、排序、拆解和绑定功能

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_equipment_get_and_store_function_works_normally())
	results.append(test_equipment_filter_and_sort_mechanism_works_correctly())
	results.append(test_equipment_disassemble_and_recycle_function_works_normally())
	results.append(test_equipment_binding_mechanism_works_normally())
	
	return results

# 测试1: 装备获取和存储功能正常
func test_equipment_get_and_store_function_works_normally() -> TestResult:
	var result = TestResult.new()
	result.test_name = "装备获取和存储功能正常"
	
	# 创建装备管理器实例
	var equipment_manager = load("res://src/scripts/equipment/equipment_manager.gd").new()
	
	# 创建测试装备
	var test_sword = equipment_manager.EquipmentData.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 添加装备到背包
	var add_result = equipment_manager.add_equipment(test_sword)
	
	# 检查装备是否成功添加
	var retrieved_equipment = equipment_manager.get_equipment_by_id("sword_001")
	
	if add_result and retrieved_equipment != null:
		result.passed = true
		result.message = "装备获取和存储功能正常"
	else:
		result.passed = false
		result.message = "装备获取和存储功能异常"
	
	return result

# 测试2: 装备筛选和排序机制正确
func test_equipment_filter_and_sort_mechanism_works_correctly() -> TestResult:
	var result = TestResult.new()
	result.test_name = "装备筛选和排序机制正确"
	
	# 创建装备管理器实例
	var equipment_manager = load("res://src/scripts/equipment/equipment_manager.gd").new()
	
	# 创建测试装备
	var test_sword = equipment_manager.EquipmentData.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	var test_armor = equipment_manager.EquipmentData.new("armor_001", "铁甲", "armor", "body")
	test_armor.tier = 2
	test_armor.base_attributes = {"defense": 30, "max_health": 50}
	
	var test_ring = equipment_manager.EquipmentData.new("ring_001", "铜戒指", "accessory", "ring_1")
	test_ring.tier = 1
	test_ring.base_attributes = {"attack": 5, "defense": 2}
	
	# 添加装备到背包
	equipment_manager.add_equipment(test_sword)
	equipment_manager.add_equipment(test_armor)
	equipment_manager.add_equipment(test_ring)
	
	# 测试筛选功能
	var tier2_items = equipment_manager.get_equipment_by_filter({"tier": 2})
	var weapon_items = equipment_manager.get_equipment_by_filter({"type": "weapon"})
	
	# 测试排序功能
	var sorted_by_tier = equipment_manager.sort_equipment({"by_tier": true})
	
	if tier2_items.size() == 2 and weapon_items.size() == 1 and sorted_by_tier.size() == 3:
		result.passed = true
		result.message = "装备筛选和排序机制正确"
	else:
		result.passed = false
		result.message = "装备筛选和排序机制异常"
	
	return result

# 测试3: 装备拆解和回收功能正常
func test_equipment_disassemble_and_recycle_function_works_normally() -> TestResult:
	var result = TestResult.new()
	result.test_name = "装备拆解和回收功能正常"
	
	# 创建装备管理器实例
	var equipment_manager = load("res://src/scripts/equipment/equipment_manager.gd").new()
	
	# 创建测试装备
	var test_sword = equipment_manager.EquipmentData.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 3  # 史诗品阶
	test_sword.enhancement_level = 5
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 添加装备到背包
	equipment_manager.add_equipment(test_sword)
	
	# 拆解装备
	var resources = equipment_manager.disassemble_equipment("sword_001")
	
	# 检查是否获得了资源且装备已从背包移除
	var equipment_count_before = equipment_manager.get_equipment_count()
	
	if resources.size() > 0 and equipment_count_before == 0:
		result.passed = true
		result.message = "装备拆解和回收功能正常"
	else:
		result.passed = false
		result.message = "装备拆解和回收功能异常"
	
	return result

# 测试4: 装备绑定机制正常
func test_equipment_binding_mechanism_works_normally() -> TestResult:
	var result = TestResult.new()
	result.test_name = "装备绑定机制正常"
	
	# 创建装备管理器实例
	var equipment_manager = load("res://src/scripts/equipment/equipment_manager.gd").new()
	
	# 创建测试装备
	var test_sword = equipment_manager.EquipmentData.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 添加装备到背包
	equipment_manager.add_equipment(test_sword)
	
	# 绑定装备
	var bind_result = equipment_manager.bind_equipment("sword_001")
	
	# 检查装备是否已绑定
	var bound_equipment = equipment_manager.get_equipment_by_id("sword_001")
	var is_bound = bound_equipment.is_bound if bound_equipment else false
	
	if bind_result and is_bound:
		result.passed = true
		result.message = "装备绑定机制正常"
	else:
		result.passed = false
		result.message = "装备绑定机制异常"
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行装备管理功能测试...")
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