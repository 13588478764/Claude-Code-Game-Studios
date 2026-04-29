## 武侠奇遇录 - 简化装备系统测试脚本
## 直接运行测试逻辑，不依赖UI按钮
##
## 该脚本自动执行装备系统的完整测试流程，包括：
## - 装备物品测试
## - 槽位解锁测试
## - 装备属性计算测试

extends Node2D

# 常量定义
const EQUIPMENT_SYSTEM_PATH: String = "/root/EquipmentSystem"
const CHARACTER_SYSTEM_PATH: String = "/root/CharacterSystem"

const TEST_CHARACTER_LEVEL: int = 10
const TEST_CHARACTER_REALM: int = 1

const TEST_REALMS: Array = [0, 1, 2, 3, 4, 8]
const TEST_REALM_NAMES: Array = ["炼气", "筑基", "金丹", "元婴", "化神", "渡劫"]

const TEST_TIMEOUT_SECONDS: float = 3.0

## 初始化并运行所有测试
func _ready() -> void:
	print("=== 开始简化装备系统测试 ===")
	
	var equipment_system: Node = get_node_or_null(EQUIPMENT_SYSTEM_PATH)
	var character_system: Node = get_node_or_null(CHARACTER_SYSTEM_PATH)
	
	if not _validate_systems(equipment_system, character_system):
		_exit_test(false)
		return
	
	_initialize_test_character(character_system)
	
	# 执行所有测试
	print("\n--- 测试1: 装备物品 ---")
	_test_equip_item(equipment_system, character_system)
	
	print("\n--- 测试2: 槽位解锁 ---")
	_test_slot_unlock(equipment_system)
	
	print("\n--- 测试3: 装备属性计算 ---")
	_test_equipment_attributes(equipment_system)
	
	print("\n✅ 简化装备系统测试完成！")
	
	# 等待几秒后退出
	_exit_test(true)

## 测试装备物品功能
func _test_equip_item(equipment_system: Node, character_system: Node) -> void:
	_test_equip_common_sword(equipment_system)
	_test_equip_rare_sword(equipment_system)

## 测试装备普通铁剑
func _test_equip_common_sword(equipment_system: Node) -> void:
	var can_equip: bool = equipment_system.can_equip_item("common_sword", 1, 0)
	print("普通铁剑可装备: %s" % ("是" if can_equip else "否"))
	
	if can_equip:
		equipment_system.equip_item("common_sword", 1, 0)
		print("✅ 成功装备普通铁剑")
	else:
		print("❌ 无法装备普通铁剑")

## 测试装备精钢剑
func _test_equip_rare_sword(equipment_system: Node) -> void:
	var can_equip: bool = equipment_system.can_equip_item("rare_sword", TEST_CHARACTER_LEVEL, TEST_CHARACTER_REALM)
	print("精钢剑(10级筑基)可装备: %s" % ("是" if can_equip else "否"))
	
	if can_equip:
		equipment_system.equip_item("rare_sword", TEST_CHARACTER_LEVEL, TEST_CHARACTER_REALM)
		print("✅ 成功装备精钢剑")
	else:
		print("❌ 无法装备精钢剑")

## 测试槽位解锁功能
func _test_slot_unlock(equipment_system: Node) -> void:
	for i in range(TEST_REALMS.size()):
		var realm: int = TEST_REALMS[i]
		var realm_name: String = TEST_REALM_NAMES[i]
		print("  %s 期:" % realm_name)
		
		for slot in equipment_system.slot_unlock_realm:
			var unlocked: bool = equipment_system.is_slot_unlocked(slot, realm)
			var slot_name: String = equipment_system.get_slot_name(slot)
			var status: String = "已解锁" if unlocked else "未解锁"
			print("    %s: %s" % [slot_name, status])

## 测试装备属性计算
func _test_equipment_attributes(equipment_system: Node) -> void:
	var equipment_attrs: Dictionary = equipment_system.get_equipment_attributes()
	
	if not _validate_equipment_attributes(equipment_attrs):
		push_warning("装备属性数据结构不完整")
		return
	
	print("  当前装备属性:")
	print("    力道: %d" % equipment_attrs["base"]["strength"])
	print("    攻击力: %d" % equipment_attrs["combat"]["attack"])
	print("    火属性: %d" % equipment_attrs["elemental"]["fire"])

## 验证系统是否可用
func _validate_systems(equipment_system: Node, character_system: Node) -> bool:
	if equipment_system == null or character_system == null:
		push_error("无法访问装备系统或角色系统")
		return false
	return true

## 验证装备属性数据结构
func _validate_equipment_attributes(equipment_attrs: Dictionary) -> bool:
	if not equipment_attrs.has("base"):
		return false
	if not equipment_attrs.has("combat"):
		return false
	if not equipment_attrs.has("elemental"):
		return false
	return true

## 初始化测试角色
func _initialize_test_character(character_system: Node) -> void:
	character_system.initialize_character()
	character_system.level = TEST_CHARACTER_LEVEL
	character_system.realm_index = TEST_CHARACTER_REALM

## 退出测试
func _exit_test(success: bool) -> void:
	await get_tree().create_timer(TEST_TIMEOUT_SECONDS).timeout
	if success:
		print("\n测试进程将在 %d 秒后退出" % int(TEST_TIMEOUT_SECONDS))
	get_tree().quit()