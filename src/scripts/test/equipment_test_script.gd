# 武侠奇遇录 - 装备系统测试脚本
# 专门用于装备测试场景的UI回调处理

extends Node2D

func _ready():
	print("装备系统测试脚本初始化完成")
	
	# 手动连接按钮信号（Godot 4可靠方案）
	var equip_button = get_node("TestEquipItemButton")
	if equip_button != null:
		equip_button.pressed.connect(_on_test_equip_item_pressed)
	
	var slot_button = get_node("TestSlotUnlockButton")
	if slot_button != null:
		slot_button.pressed.connect(_on_test_slot_unlock_pressed)
	
	var enhance_button = get_node("TestEnhancementButton")
	if enhance_button != null:
		enhance_button.pressed.connect(_on_test_enhancement_pressed)

func _on_test_equip_item_pressed():
	"""测试装备物品按钮回调"""
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	var character_system = get_node_or_null("/root/CharacterSystem")
	
	if equipment_system == null or character_system == null:
		print("❌ 无法访问装备系统或角色系统")
		return
	
	# 初始化角色
	character_system.initialize_character()
	character_system.level = 10
	character_system.realm_index = 1
	
	# 测试装备普通铁剑（炼气期1级可装备）
	var can_equip = equipment_system.can_equip_item("common_sword", 1, 0)
	print("普通铁剑可装备: %s" % ("是" if can_equip else "否"))
	
	if can_equip:
		equipment_system.equip_item("common_sword", 1, 0)
	
	# 测试装备精钢剑（筑基期10级可装备）
	can_equip = equipment_system.can_equip_item("rare_sword", 5, 0)
	print("精钢剑(5级)可装备: %s" % ("是" if can_equip else "否"))
	
	can_equip = equipment_system.can_equip_item("rare_sword", 10, 1)
	print("精钢剑(10级筑基)可装备: %s" % ("是" if can_equip else "否"))
	
	if can_equip:
		equipment_system.equip_item("rare_sword", 10, 1)
	
	# 打印装备信息
	equipment_system.debug_print_equipment_info()

func _on_test_slot_unlock_pressed():
	"""测试槽位解锁按钮回调"""
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	
	if equipment_system == null:
		print("❌ 无法访问装备系统")
		return
	
	# 测试不同境界的槽位解锁情况
	var test_realms = [0, 1, 2, 3, 4, 8]  # 炼气、筑基、金丹、元婴、化神、渡劫
	var realm_names = ["炼气", "筑基", "金丹", "元婴", "化神", "渡劫"]
	
	for i in range(test_realms.size()):
		var realm = test_realms[i]
		var name = realm_names[i]
		print("=== %s 期槽位解锁情况 ===" % name)
		
		for slot in equipment_system.slot_unlock_realm:
			var unlocked = equipment_system.is_slot_unlocked(slot, realm)
			print("%s: %s" % [equipment_system.get_slot_name(slot), "已解锁" if unlocked else "未解锁"])
	
	print("==================")

func _on_test_enhancement_pressed():
	"""测试装备强化按钮回调"""
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	var character_system = get_node_or_null("/root/CharacterSystem")
	
	if equipment_system == null or character_system == null:
		print("❌ 无法访问装备系统或角色系统")
		return
	
	# 初始化角色并装备物品
	character_system.initialize_character()
	character_system.level = 10
	character_system.realm_index = 1
	equipment_system.equip_item("common_sword", 10, 1)
	
	# 测试强化成功率
	print("=== 强化成功率测试 ===")
	for level in range(21):  # +0 to +20
		if level < equipment_system.enhancement_config["success_rates"].size():
			var success_rate = equipment_system.enhancement_config["success_rates"][level]
			print("+%d -> +%d: 成功率 %.0f%%" % [level, level + 1, success_rate * 100])
	
	# 测试强化失败处理
	print("=== 强化失败处理测试 ===")
	print("强化到+12失败: 不降级")
	print("强化到+18失败: 降级1-2级")
	
	# 获取装备属性
	var equipment_attrs = equipment_system.get_equipment_attributes()
	print("当前装备属性:")
	print("  力道: %d" % equipment_attrs["base"]["strength"])
	print("  攻击力: %d" % equipment_attrs["combat"]["attack"])
	print("  火属性: %d" % equipment_attrs["elemental"]["fire"])