# 装备穿戴系统集成测试
# 验证装备槽位管理、兼容性验证、穿戴/卸下功能和外观渲染

extends GutTest

# 导入要测试的脚本
const EquipmentWearerScript = load("res://src/scripts/equipment/equipment_wearer.gd")
const EquipmentManagerScript = load("res://src/scripts/equipment/equipment_manager.gd")

# 测试实例
var wearer
var manager

# 每个测试前执行
func before_each():
	wearer = EquipmentWearerScript.new()
	manager = EquipmentManagerScript.new()
	
	# 将 wearer 添加到场景树
	add_child_autofree(wearer)
	
	wearer._ready()
	manager._ready()

# 测试1: 装备槽位管理正常
func test_equipment_slot_management_works_normally():
	# 获取装备槽位
	var slots = wearer.get_equipment_slots()
	
	# 检查是否有正确的槽位
	var expected_slots = ["weapon_main", "weapon_offhand", "head", "body", "hands", "feet", "necklace", "ring_1", "ring_2", "belt"]
	
	assert_eq(slots.size(), 10, "应该有10个装备槽位")
	
	for expected_slot in expected_slots:
		assert_true(slots.has(expected_slot), "应该包含槽位: " + expected_slot)

# 测试2: 装备兼容性验证正确
func test_equipment_compatibility_validation_works_correctly():
	# 创建测试装备
	var test_sword = manager.EquipmentInfo.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 添加装备到管理器
	manager.add_equipment(test_sword)
	
	# 将管理器添加到场景树并加入组
	add_child_autofree(manager)
	manager.add_to_group("equipment_manager")
	
	# 验证兼容性 - 正确的槽位
	var is_compatible = wearer.validate_compatibility("sword_001", "weapon_main")
	assert_true(is_compatible, "武器应该可以装备到主手槽位")
	
	# 验证兼容性 - 错误的槽位
	var is_incompatible = wearer.validate_compatibility("sword_001", "head")
	assert_false(is_incompatible, "武器不应该可以装备到头部槽位")

# 测试3: 装备穿戴/卸下功能正常
func test_equipment_wear_and_unwear_function_works_normally():
	# 创建测试装备
	var test_sword = manager.EquipmentInfo.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 添加装备到管理器
	manager.add_equipment(test_sword)
	
	# 将管理器添加到场景树并加入组
	add_child_autofree(manager)
	manager.add_to_group("equipment_manager")
	
	# 穿戴装备
	var wear_result = wearer.equip_item("sword_001", "weapon_main")
	assert_true(wear_result, "穿戴装备应该成功")
	
	# 检查是否已穿戴
	var equipped_item = wearer.get_equipped_item("weapon_main")
	assert_not_null(equipped_item, "槽位应该有装备")
	assert_eq(equipped_item.id, "sword_001", "装备ID应该匹配")
	
	# 卸下装备
	var unwear_result = wearer.unequip_item("weapon_main")
	assert_true(unwear_result, "卸下装备应该成功")
	
	# 检查是否已卸下
	var is_unequipped = wearer.get_equipped_item("weapon_main")
	assert_null(is_unequipped, "槽位应该为空")

# 测试4: 装备外观渲染正确
func test_equipment_visual_rendering_works_correctly():
	# 创建测试装备
	var test_sword = manager.EquipmentInfo.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 添加装备到管理器
	manager.add_equipment(test_sword)
	
	# 将管理器添加到场景树并加入组
	add_child_autofree(manager)
	manager.add_to_group("equipment_manager")
	
	# 穿戴装备
	wearer.equip_item("sword_001", "weapon_main")
	
	# 渲染外观（这主要是检查不会崩溃）
	wearer.render_equipment_visuals()
	
	# 检查装备统计信息
	var stats = wearer.get_equipment_stats()
	assert_true(stats.has("total_equipped"), "应该有装备统计信息")
	assert_eq(stats.total_equipped, 1, "应该有1件装备")