# 武侠奇遇录 - 简化装备系统测试脚本
# 直接运行测试逻辑，不依赖UI按钮

extends Node2D

func _ready():
	print("=== 开始简化装备系统测试 ===")
	
	# 获取系统引用
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	var character_system = get_node_or_null("/root/CharacterSystem")
	
	if equipment_system == null or character_system == null:
		print("❌ 无法访问装备系统或角色系统")
		return
	
	# 初始化角色
	character_system.initialize_character()
	character_system.level = 10
	character_system.realm_index = 1
	
	# 测试1: 装备物品
	print("\n--- 测试1: 装备物品 ---")
	test_equip_item(equipment_system, character_system)
	
	# 测试2: 槽位解锁
	print("\n--- 测试2: 槽位解锁 ---")
	test_slot_unlock(equipment_system)
	
	# 测试3: 装备属性计算
	print("\n--- 测试3: 装备属性计算 ---")
	test_equipment_attributes(equipment_system)
	
	print("\n✅ 简化装备系统测试完成！")
	
	# 等待几秒后退出
	await get_tree().create_timer(3.0).timeout
	get_tree().quit()

func test_equip_item(equipment_system, character_system):
	"""测试装备物品功能"""
	# 测试装备普通铁剑
	var can_equip = equipment_system.can_equip_item("common_sword", 1, 0)
	print("普通铁剑可装备: %s" % ("是" if can_equip else "否"))
	
	if can_equip:
		equipment_system.equip_item("common_sword", 1, 0)
		print("✅ 成功装备普通铁剑")
	else:
		print("❌ 无法装备普通铁剑")
	
	# 测试装备精钢剑
	can_equip = equipment_system.can_equip_item("rare_sword", 10, 1)
	print("精钢剑(10级筑基)可装备: %s" % ("是" if can_equip else "否"))
	
	if can_equip:
		equipment_system.equip_item("rare_sword", 10, 1)
		print("✅ 成功装备精钢剑")
	else:
		print("❌ 无法装备精钢剑")

func test_slot_unlock(equipment_system):
	"""测试槽位解锁功能"""
	# 测试不同境界的槽位解锁情况
	var test_realms = [0, 1, 2, 3, 4, 8]  # 炼气、筑基、金丹、元婴、化神、渡劫
	var realm_names = ["炼气", "筑基", "金丹", "元婴", "化神", "渡劫"]
	
	for i in range(test_realms.size()):
		var realm = test_realms[i]
		var name = realm_names[i]
		print("  %s 期:" % name)
		
		for slot in equipment_system.slot_unlock_realm:
			var unlocked = equipment_system.is_slot_unlocked(slot, realm)
			print("    %s: %s" % [equipment_system.get_slot_name(slot), "已解锁" if unlocked else "未解锁"])

func test_equipment_attributes(equipment_system):
	"""测试装备属性计算"""
	var equipment_attrs = equipment_system.get_equipment_attributes()
	print("  当前装备属性:")
	print("    力道: %d" % equipment_attrs["base"]["strength"])
	print("    攻击力: %d" % equipment_attrs["combat"]["attack"])
	print("    火属性: %d" % equipment_attrs["elemental"]["fire"])