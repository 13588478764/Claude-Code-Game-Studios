# 装备管理功能单元测试
# 验证装备获取和存储、筛选和排序、拆解和回收、绑定机制

extends Node

# 加载装备管理器
var EquipmentManager = load("res://src/scripts/equipment/equipment_manager.gd")

var equipment_manager
var test_result = {
	"passed": 0,
	"failed": 0,
	"total": 0,
	"details": []
}

func _ready():
	print("开始装备管理功能单元测试...")
	
	# 运行所有测试
	test_equipment_acquisition_and_storage()
	test_equipment_filtering_and_sorting()
	test_equipment_disassembly_and_recycling()
	test_equipment_binding_mechanism()
	
	# 输出测试结果
	print("\n=== 装备管理功能单元测试结果 ===")
	print("通过: %d" % test_result.passed)
	print("失败: %d" % test_result.failed)
	print("总计: %d" % test_result.total)
	
	if test_result.failed == 0:
		print("✅ 所有测试通过！")
	else:
		print("❌ 有 %d 个测试失败" % test_result.failed)
	
	for detail in test_result.details:
		print(detail)

# 测试装备获取和存储功能
func test_equipment_acquisition_and_storage():
	print("\n--- 测试装备获取和存储功能 ---")
	
	equipment_manager = EquipmentManager.new()
	
	# 创建测试装备
	var test_sword = equipment_manager.EquipmentData.new(
		"sword_001", 
		"青锋剑", 
		equipment_manager.EquipmentType.WEAPON_MAIN_HAND, 
		equipment_manager.EquipmentRarity.UNCOMMON
	)
	test_sword.level_requirement = 5
	test_sword.attributes = {"attack": 25, "durability": 100}
	
	# 测试添加装备到背包
	var add_result = equipment_manager.add_equipment(test_sword)
	if add_result:
		add_test_result("装备获取和存储功能", true, "成功添加装备到背包: %s" % test_sword.name)
	else:
		add_test_result("装备获取和存储功能", false, "添加装备到背包失败: %s" % test_sword.name)
	
	# 测试背包中装备数量
	if equipment_manager.get_backpack_size() == 1:
		add_test_result("装备获取和存储功能", true, "背包中装备数量正确: 1")
	else:
		add_test_result("装备获取和存储功能", false, "背包中装备数量不正确: %d" % equipment_manager.get_backpack_size())
	
	# 测试背包未满状态
	if !equipment_manager.is_backpack_full():
		add_test_result("装备获取和存储功能", true, "背包未满状态正确")
	else:
		add_test_result("装备获取和存储功能", false, "背包未满状态错误")
	
	# 测试查找装备
	var found_equipment = equipment_manager.find_equipment_by_id("sword_001")
	if found_equipment != null and found_equipment.name == "青锋剑":
		add_test_result("装备获取和存储功能", true, "成功找到背包中的装备")
	else:
		add_test_result("装备获取和存储功能", false, "未能找到背包中的装备")

# 测试装备筛选和排序机制
func test_equipment_filtering_and_sorting():
	print("\n--- 测试装备筛选和排序机制 ---")
	
	equipment_manager = EquipmentManager.new()
	
	# 创建不同类型的测试装备
	var common_helmet = equipment_manager.EquipmentData.new(
		"helmet_001", 
		"布帽", 
		equipment_manager.EquipmentType.HELMET, 
		equipment_manager.EquipmentRarity.COMMON
	)
	common_helmet.level_requirement = 1
	
	var rare_armor = equipment_manager.EquipmentData.new(
		"armor_001", 
		"铁甲", 
		equipment_manager.EquipmentType.ARMOR, 
		equipment_manager.EquipmentRarity.RARE
	)
	rare_armor.level_requirement = 10
	rare_armor.enhancement_level = 5
	
	var legendary_weapon = equipment_manager.EquipmentData.new(
		"weapon_001", 
		"倚天剑", 
		equipment_manager.EquipmentType.WEAPON_MAIN_HAND, 
		equipment_manager.EquipmentRarity.LEGENDARY
	)
	legendary_weapon.level_requirement = 20
	legendary_weapon.enhancement_level = 10
	
	# 添加装备到背包
	equipment_manager.add_equipment(common_helmet)
	equipment_manager.add_equipment(rare_armor)
	equipment_manager.add_equipment(legendary_weapon)
	
	# 测试按品阶筛选
	var rare_and_above = equipment_manager.get_equipment_by_filter({
		"rarity": equipment_manager.EquipmentRarity.RARE
	})
	# 注意：我们的筛选函数是精确匹配，所以我们需要测试相等的情况
	var rare_items = equipment_manager.get_equipment_by_filter({
		"rarity": equipment_manager.EquipmentRarity.RARE
	})
	var legendary_items = equipment_manager.get_equipment_by_filter({
		"rarity": equipment_manager.EquipmentRarity.LEGENDARY
	})
	
	if rare_items.size() == 1 and legendary_items.size() == 1:
		add_test_result("装备筛选和排序机制", true, "按品阶筛选功能正常")
	else:
		add_test_result("装备筛选和排序机制", false, "按品阶筛选功能异常")
	
	# 测试按类型筛选
	var weapon_items = equipment_manager.get_equipment_by_filter({
		"type": equipment_manager.EquipmentType.WEAPON_MAIN_HAND
	})
	if weapon_items.size() == 1:
		add_test_result("装备筛选和排序机制", true, "按类型筛选功能正常")
	else:
		add_test_result("装备筛选和排序机制", false, "按类型筛选功能异常")
	
	# 测试按等级筛选
	var high_level_items = equipment_manager.get_equipment_by_filter({
		"min_level": 10
	})
	if high_level_items.size() == 2:  # 铁甲和倚天剑
		add_test_result("装备筛选和排序机制", true, "按等级筛选功能正常")
	else:
		add_test_result("装备筛选和排序机制", false, "按等级筛选功能异常，期望2，实际%d" % high_level_items.size())
	
	# 测试排序功能
	var sorted_equipment = equipment_manager.sort_equipment({})
	# 排序应该是传奇 > 稀有 > 普通，所以第一件应该是倚天剑
	if sorted_equipment.size() > 0 and sorted_equipment[0].name == "倚天剑":
		add_test_result("装备筛选和排序机制", true, "排序功能正常（按品阶降序）")
	else:
		add_test_result("装备筛选和排序机制", false, "排序功能异常，最高品阶装备不在第一位")
	
	# 测试统计功能
	var legendary_count = equipment_manager.get_equipment_count_by_rarity(equipment_manager.EquipmentRarity.LEGENDARY)
	if legendary_count == 1:
		add_test_result("装备筛选和排序机制", true, "品阶统计功能正常")
	else:
		add_test_result("装备筛选和排序机制", false, "品阶统计功能异常")

# 测试装备拆解和回收功能
func test_equipment_disassembly_and_recycling():
	print("\n--- 测试装备拆解和回收功能 ---")
	
	equipment_manager = EquipmentManager.new()
	
	# 创建测试装备
	var test_armor = equipment_manager.EquipmentData.new(
		"armor_002", 
		"玄铁甲", 
		equipment_manager.EquipmentType.ARMOR, 
		equipment_manager.EquipmentRarity.RARE
	)
	test_armor.level_requirement = 15
	test_armor.enhancement_level = 7
	test_armor.gems = ["red_gem", "blue_gem"]  # 镶嵌了2颗宝石
	
	# 添加装备到背包
	equipment_manager.add_equipment(test_armor)
	
	# 测试拆解装备
	var disassemble_result = equipment_manager.disassemble_equipment("armor_002")
	
	if disassemble_result.success:
		add_test_result("装备拆解和回收功能", true, "装备拆解成功")
	else:
		add_test_result("装备拆解和回收功能", false, "装备拆解失败: %s" % disassemble_result.message)
	
	# 检查拆解后背包中是否还有该装备
	var found_equipment = equipment_manager.find_equipment_by_id("armor_002")
	if found_equipment == null:
		add_test_result("装备拆解和回收功能", true, "拆解后装备已从背包中移除")
	else:
		add_test_result("装备拆解和回收功能", false, "拆解后装备仍然在背包中")
	
	# 检查拆解获得的材料
	if disassemble_result.materials_gained.size() > 0:
		print("拆解获得材料: ", disassemble_result.materials_gained)
		add_test_result("装备拆解和回收功能", true, "拆解获得了材料")
	else:
		add_test_result("装备拆解和回收功能", false, "拆解未获得任何材料")
	
	# 测试拆解不存在的装备
	var fail_result = equipment_manager.disassemble_equipment("nonexistent")
	if not fail_result.success:
		add_test_result("装备拆解和回收功能", true, "正确处理不存在的装备拆解请求")
	else:
		add_test_result("装备拆解和回收功能", false, "未正确处理不存在的装备拆解请求")

# 测试装备绑定机制
func test_equipment_binding_mechanism():
	print("\n--- 测试装备绑定机制 ---")
	
	equipment_manager = EquipmentManager.new()
	
	# 创建测试装备
	var quest_sword = equipment_manager.EquipmentData.new(
		"quest_sword_001", 
		"任务剑", 
		equipment_manager.EquipmentType.WEAPON_MAIN_HAND, 
		equipment_manager.EquipmentRarity.COMMON
	)
	quest_sword.acquisition_source = "quest_reward"  # 任务奖励来源
	
	# 添加装备到背包
	equipment_manager.add_equipment(quest_sword)
	
	# 测试绑定装备
	var bind_result = equipment_manager.bind_equipment("quest_sword_001")
	if bind_result:
		add_test_result("装备绑定机制", true, "成功绑定装备")
	else:
		add_test_result("装备绑定机制", false, "绑定装备失败")
	
	# 检查装备是否真的被标记为绑定
	var bound_equipment = equipment_manager.find_equipment_by_id("quest_sword_001")
	if bound_equipment and bound_equipment.is_bound:
		add_test_result("装备绑定机制", true, "装备正确标记为绑定状态")
	else:
		add_test_result("装备绑定机制", false, "装备未正确标记为绑定状态")
	
	# 测试重复绑定（应该失败）
	var duplicate_bind_result = equipment_manager.bind_equipment("quest_sword_001")
	if not duplicate_bind_result:
		add_test_result("装备绑定机制", true, "正确阻止重复绑定")
	else:
		add_test_result("装备绑定机制", false, "未阻止重复绑定")
	
	# 测试绑定不存在的装备
	var nonexistent_bind_result = equipment_manager.bind_equipment("nonexistent")
	if not nonexistent_bind_result:
		add_test_result("装备绑定机制", true, "正确处理不存在的装备绑定请求")
	else:
		add_test_result("装备绑定机制", false, "未正确处理不存在的装备绑定请求")

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