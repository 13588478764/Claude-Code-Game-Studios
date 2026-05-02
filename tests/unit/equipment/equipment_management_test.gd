# 装备管理功能单元测试
# 验证装备获取、存储、筛选、排序、拆解和绑定功能

extends GutTest

# 导入要测试的脚本
const EquipmentManagerScript = preload("res://src/scripts/equipment/equipment_manager.gd")

# 测试管理器实例
var equipment_manager

# 每个测试前执行
func before_each():
	equipment_manager = EquipmentManagerScript.new()
	equipment_manager._ready()  # 手动调用初始化

# 测试1: 装备获取和存储功能正常
func test_equipment_get_and_store_function_works_normally():
	# 创建测试装备
	var test_sword = equipment_manager.EquipmentInfo.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 添加装备到背包
	var add_result = equipment_manager.add_equipment(test_sword)
	
	# 检查装备是否成功添加
	var retrieved_equipment = equipment_manager.get_equipment_by_id("sword_001")
	
	assert_true(add_result, "装备应该成功添加")
	assert_not_null(retrieved_equipment, "应该能够获取添加的装备")
	assert_eq(retrieved_equipment.id, "sword_001", "装备ID应该正确")
	assert_eq(retrieved_equipment.name, "青钢剑", "装备名称应该正确")

# 测试2: 装备筛选和排序机制正确
func test_equipment_filter_and_sort_mechanism_works_correctly():
	# 创建测试装备
	var test_sword = equipment_manager.EquipmentInfo.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	var test_armor = equipment_manager.EquipmentInfo.new("armor_001", "铁甲", "armor", "body")
	test_armor.tier = 2
	test_armor.base_attributes = {"defense": 30, "max_health": 50}
	
	var test_ring = equipment_manager.EquipmentInfo.new("ring_001", "铜戒指", "accessory", "ring_1")
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
	
	assert_eq(tier2_items.size(), 2, "应该有2个品阶2的装备")
	assert_eq(weapon_items.size(), 1, "应该有1个武器类型的装备")
	assert_eq(sorted_by_tier.size(), 3, "排序后应该有3个装备")

# 测试3: 装备拆解和回收功能正常
func test_equipment_disassemble_and_recycle_function_works_normally():
	# 创建测试装备
	var test_sword = equipment_manager.EquipmentInfo.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 3  # 史诗品阶
	test_sword.enhancement_level = 5
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 添加装备到背包
	equipment_manager.add_equipment(test_sword)
	
	# 拆解装备
	var resources = equipment_manager.disassemble_equipment("sword_001")
	
	# 检查是否获得了资源且装备已从背包移除
	var equipment_count_after = equipment_manager.get_equipment_count()
	
	assert_true(resources.size() > 0, "应该获得拆解资源")
	assert_eq(equipment_count_after, 0, "装备应该已从背包移除")
	assert_true(resources.has("refinement_stone"), "应该包含精炼石")
	assert_true(resources.has("silver"), "应该包含银两")

# 测试4: 装备绑定机制正常
func test_equipment_binding_mechanism_works_normally():
	# 创建测试装备
	var test_sword = equipment_manager.EquipmentInfo.new("sword_001", "青钢剑", "weapon", "weapon_main")
	test_sword.tier = 2
	test_sword.base_attributes = {"attack": 50, "attack_speed": 1.2}
	
	# 添加装备到背包
	equipment_manager.add_equipment(test_sword)
	
	# 绑定装备
	var bind_result = equipment_manager.bind_equipment("sword_001")
	
	# 检查装备是否已绑定
	var bound_equipment = equipment_manager.get_equipment_by_id("sword_001")
	
	assert_true(bind_result, "绑定操作应该成功")
	assert_not_null(bound_equipment, "应该能够获取装备")
	assert_true(bound_equipment.is_bound, "装备应该已绑定")