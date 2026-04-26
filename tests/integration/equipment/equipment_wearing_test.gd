# 装备穿戴系统集成测试
# 验证装备槽位管理、兼容性验证、穿戴/卸下功能、外观渲染

extends Node

# 加载装备穿戴管理器
var EquipmentWearer = load("res://src/scripts/equipment/equipment_wearer.gd")
var EquipmentManager = load("res://src/scripts/equipment/equipment_manager.gd")

var equipment_wearer
var equipment_manager
var test_result = {
	"passed": 0,
	"failed": 0,
	"total": 0,
	"details": []
}

func _ready():
	print("开始装备穿戴系统集成测试...")
	
	# 运行所有测试
	test_equipment_slot_management()
	test_equipment_compatibility_validation()
	test_equipment_wearing_unequipping()
	test_visual_rendering_integration()
	
	# 输出测试结果
	print("\n=== 装备穿戴系统集成测试结果 ===")
	print("通过: %d" % test_result.passed)
	print("失败: %d" % test_result.failed)
	print("总计: %d" % test_result.total)
	
	if test_result.failed == 0:
		print("✅ 所有测试通过！")
	else:
		print("❌ 有 %d 个测试失败" % test_result.failed)
	
	for detail in test_result.details:
		print(detail)

# 测试装备槽位管理
func test_equipment_slot_management():
	print("\n--- 测试装备槽位管理 ---")
	
	# 初始化系统
	equipment_manager = EquipmentManager.new()
	equipment_wearer = EquipmentWearer.new()
	equipment_wearer.set_dependencies(equipment_manager, null, null, null)
	
	# 创建测试装备
	var test_sword = equipment_manager.EquipmentData.new(
		"sword_001", 
		"青铜剑", 
		equipment_manager.EquipmentType.WEAPON_MAIN_HAND, 
		equipment_manager.EquipmentRarity.UNCOMMON
	)
	test_sword.level_requirement = 1
	
	var test_helmet = equipment_manager.EquipmentData.new(
		"helmet_001", 
		"铁头盔", 
		equipment_manager.EquipmentType.HELMET, 
		equipment_manager.EquipmentRarity.COMMON
	)
	test_helmet.level_requirement = 1
	
	# 添加装备到背包
	equipment_manager.add_equipment(test_sword)
	equipment_manager.add_equipment(test_helmet)
	
	# 测试装备到正确的槽位
	var sword_equip_result = equipment_wearer.equip_item("sword_001", equipment_wearer.EquipmentSlot.MAIN_HAND)
	if sword_equip_result.success:
		add_test_result("装备槽位管理", true, "成功将武器装备到主手槽位")
	else:
		add_test_result("装备槽位管理", false, "将武器装备到主手槽位失败: %s" % sword_equip_result.message)
	
	# 测试头盔装备到正确的槽位
	var helmet_equip_result = equipment_wearer.equip_item("helmet_001", equipment_wearer.EquipmentSlot.HEAD)
	if helmet_equip_result.success:
		add_test_result("装备槽位管理", true, "成功将头盔装备到头部槽位")
	else:
		add_test_result("装备槽位管理", false, "将头盔装备到头部槽位失败: %s" % helmet_equip_result.message)
	
	# 测试尝试将武器装备到头部槽位（应该失败）
	var wrong_slot_result = equipment_wearer.equip_item("sword_001", equipment_wearer.EquipmentSlot.HEAD)
	if not wrong_slot_result.success:
		add_test_result("装备槽位管理", true, "正确阻止将武器装备到错误槽位")
	else:
		add_test_result("装备槽位管理", false, "未能阻止将武器装备到错误槽位")
	
	# 检查槽位信息
	var slot_info = equipment_wearer.get_equipment_slot_info()
	if slot_info[equipment_wearer.EquipmentSlot.MAIN_HAND].occupied and slot_info[equipment_wearer.EquipmentSlot.HEAD].occupied:
		add_test_result("装备槽位管理", true, "槽位信息正确反映了已装备的物品")
	else:
		add_test_result("装备槽位管理", false, "槽位信息未正确反映已装备的物品")

# 测试装备兼容性验证
func test_equipment_compatibility_validation():
	print("\n--- 测试装备兼容性验证 ---")
	
	# 重新初始化系统
	equipment_manager = EquipmentManager.new()
	equipment_wearer = EquipmentWearer.new()
	equipment_wearer.set_dependencies(equipment_manager, null, null, null)
	
	# 创建测试装备
	var high_level_sword = equipment_manager.EquipmentData.new(
		"high_lvl_sword", 
		"高级剑", 
		equipment_manager.EquipmentType.WEAPON_MAIN_HAND, 
		equipment_manager.EquipmentRarity.RARE
	)
	high_level_sword.level_requirement = 50  # 高等级要求
	
	# 添加装备到背包
	equipment_manager.add_equipment(high_level_sword)
	
	# 创建一个模拟的角色模型，等级为5
	var mock_char_model = MockCharacterModel.new()
	mock_char_model.level = 5
	equipment_wearer.character_model = mock_char_model
	
	# 测试等级不足的兼容性验证
	var compatibility_result = equipment_wearer.validate_compatibility("high_lvl_sword", equipment_wearer.EquipmentSlot.MAIN_HAND)
	if not compatibility_result.compatible and "等级不足" in compatibility_result.reason:
		add_test_result("装备兼容性验证", true, "正确验证等级要求")
	else:
		add_test_result("装备兼容性验证", false, "未能正确验证等级要求")
	
	# 测试正常的兼容性验证
	var normal_sword = equipment_manager.EquipmentData.new(
		"normal_sword", 
		"普通剑", 
		equipment_manager.EquipmentType.WEAPON_MAIN_HAND, 
		equipment_manager.EquipmentRarity.COMMON
	)
	normal_sword.level_requirement = 1
	
	equipment_manager.add_equipment(normal_sword)
	var normal_compat_result = equipment_wearer.validate_compatibility("normal_sword", equipment_wearer.EquipmentSlot.MAIN_HAND)
	if normal_compat_result.compatible:
		add_test_result("装备兼容性验证", true, "正常装备兼容性验证通过")
	else:
		add_test_result("装备兼容性验证", false, "正常装备兼容性验证失败: %s" % normal_compat_result.reason)

# 测试装备穿戴/卸下功能
func test_equipment_wearing_unequipping():
	print("\n--- 测试装备穿戴/卸下功能 ---")
	
	# 重新初始化系统
	equipment_manager = EquipmentManager.new()
	equipment_wearer = EquipmentWearer.new()
	equipment_wearer.set_dependencies(equipment_manager, null, null, null)
	
	# 创建测试装备
	var armor = equipment_manager.EquipmentData.new(
		"test_armor", 
		"测试护甲", 
		equipment_manager.EquipmentType.ARMOR, 
		equipment_manager.EquipmentRarity.UNCOMMON
	)
	armor.level_requirement = 1
	
	# 添加装备到背包
	equipment_manager.add_equipment(armor)
	
	# 测试穿戴装备
	var equip_result = equipment_wearer.equip_item("test_armor", equipment_wearer.EquipmentSlot.BODY)
	if equip_result.success:
		add_test_result("装备穿戴/卸下功能", true, "成功穿戴装备")
	else:
		add_test_result("装备穿戴/卸下功能", false, "穿戴装备失败: %s" % equip_result.message)
	
	# 检查装备是否真的被穿戴了
	var equipped_item = equipment_wearer.get_equipped_item_in_slot(equipment_wearer.EquipmentSlot.BODY)
	if equipped_item and equipped_item.name == "测试护甲":
		add_test_result("装备穿戴/卸下功能", true, "装备确实被穿戴到了正确的槽位")
	else:
		add_test_result("装备穿戴/卸下功能", false, "装备未正确穿戴到槽位")
	
	# 测试卸下装备
	var unequip_result = equipment_wearer.unequip_item(equipment_wearer.EquipmentSlot.BODY)
	if unequip_result.success:
		add_test_result("装备穿戴/卸下功能", true, "成功卸下装备")
	else:
		add_test_result("装备穿戴/卸下功能", false, "卸下装备失败: %s" % unequip_result.message)
	
	# 检查背包中是否重新出现了装备
	var found_in_backpack = equipment_manager.find_equipment_by_id("test_armor")
	if found_in_backpack:
		add_test_result("装备穿戴/卸下功能", true, "卸下的装备正确回到了背包")
	else:
		add_test_result("装备穿戴/卸下功能", false, "卸下的装备未回到背包")

# 测试外观渲染集成
func test_visual_rendering_integration():
	print("\n--- 测试外观渲染集成 ---")
	
	# 重新初始化系统
	equipment_manager = EquipmentManager.new()
	equipment_wearer = EquipmentWearer.new()
	
	# 创建模拟的角色模型
	var mock_char_model = MockCharacterModel.new()
	equipment_wearer.set_dependencies(equipment_manager, mock_char_model, null, null)
	
	# 创建带模型路径的测试装备
	var weapon_with_model = equipment_manager.EquipmentData.new(
		"weapon_with_model", 
		"带模型武器", 
		equipment_manager.EquipmentType.WEAPON_MAIN_HAND, 
		equipment_manager.EquipmentRarity.LEGENDARY
	)
	weapon_with_model.level_requirement = 1
	# 在实际实现中，这将包含模型和纹理路径
	
	# 添加装备到背包
	equipment_manager.add_equipment(weapon_with_model)
	
	# 穿戴装备
	var equip_result = equipment_wearer.equip_item("weapon_with_model", equipment_wearer.EquipmentSlot.MAIN_HAND)
	if equip_result.success:
		add_test_result("外观渲染集成", true, "成功穿戴带模型的装备")
	else:
		add_test_result("外观渲染集成", false, "穿戴带模型的装备失败: %s" % equip_result.message)
	
	# 检查角色模型是否收到更新外观的调用
	# 这里我们检查模拟模型的标志是否被设置
	if mock_char_model.weapon_model_updated:
		add_test_result("外观渲染集成", true, "角色模型外观正确更新")
	else:
		add_test_result("外观渲染集成", false, "角色模型外观未更新")
	
	# 测试卸下装备后外观重置
	var unequip_result = equipment_wearer.unequip_item(equipment_wearer.EquipmentSlot.MAIN_HAND)
	if unequip_result.success:
		# 检查是否调用了重置模型的方法
		if mock_char_model.weapon_model_reset:
			add_test_result("外观渲染集成", true, "卸下装备后外观正确重置")
		else:
			add_test_result("外观渲染集成", false, "卸下装备后外观未重置")
	else:
		add_test_result("外观渲染集成", false, "卸下装备失败: %s" % unequip_result.message)

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

# 模拟角色模型类
class MockCharacterModel:
	var level: int = 1
	var weapon_model_updated: bool = false
	var weapon_model_reset: bool = false
	
	func get_level():
		return level
	
	func update_weapon_model(model_path, texture_path):
		weapon_model_updated = true
	
	func reset_weapon_model():
		weapon_model_reset = true
	
	func update_head_model(model_path, texture_path):
		pass
	
	func reset_head_model():
		pass
	
	func update_body_model(model_path, texture_path):
		pass
	
	func reset_body_model():
		pass
	
	func update_hand_model(model_path, texture_path):
		pass
	
	func reset_hand_model():
		pass
	
	func update_feet_model(model_path, texture_path):
		pass
	
	func reset_feet_model():
		pass