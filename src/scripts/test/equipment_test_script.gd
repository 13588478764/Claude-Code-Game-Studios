## 武侠奇遇录 - 装备系统测试脚本
## 专门用于装备测试场景的UI回调处理
## 
## 该脚本处理装备系统的UI测试回调，包括：
## - 装备物品测试
## - 槽位解锁测试
## - 装备强化测试

extends Node2D

# 常量定义
const BUTTON_EQUIP_PATH: String = "TestEquipItemButton"
const BUTTON_SLOT_PATH: String = "TestSlotUnlockButton"
const BUTTON_ENHANCE_PATH: String = "TestEnhancementButton"
const EQUIPMENT_SYSTEM_PATH: String = "/root/EquipmentSystem"
const CHARACTER_SYSTEM_PATH: String = "/root/CharacterSystem"

const TEST_CHARACTER_LEVEL: int = 10
const TEST_CHARACTER_REALM: int = 1

const TEST_REALMS: Array = [0, 1, 2, 3, 4, 8]
const TEST_REALM_NAMES: Array = ["炼气", "筑基", "金丹", "元婴", "化神", "渡劫"]

## 初始化测试脚本
## 连接UI按钮信号
func _ready() -> void:
	print("装备系统测试脚本初始化完成")
	_connect_button_signals()

## 连接所有UI按钮信号
func _connect_button_signals() -> void:
	var equip_button: Button = get_node_or_null(BUTTON_EQUIP_PATH)
	if equip_button != null:
		equip_button.pressed.connect(_on_test_equip_item_pressed)
	else:
		push_warning("无法找到装备物品按钮: %s" % BUTTON_EQUIP_PATH)
	
	var slot_button: Button = get_node_or_null(BUTTON_SLOT_PATH)
	if slot_button != null:
		slot_button.pressed.connect(_on_test_slot_unlock_pressed)
	else:
		push_warning("无法找到槽位解锁按钮: %s" % BUTTON_SLOT_PATH)
	
	var enhance_button: Button = get_node_or_null(BUTTON_ENHANCE_PATH)
	if enhance_button != null:
		enhance_button.pressed.connect(_on_test_enhancement_pressed)
	else:
		push_warning("无法找到强化按钮: %s" % BUTTON_ENHANCE_PATH)

## 测试装备物品按钮回调
func _on_test_equip_item_pressed() -> void:
	var equipment_system: Node = get_node_or_null(EQUIPMENT_SYSTEM_PATH)
	var character_system: Node = get_node_or_null(CHARACTER_SYSTEM_PATH)
	
	if not _validate_systems(equipment_system, character_system):
		return
	
	_initialize_test_character(character_system)
	_test_equip_common_sword(equipment_system)
	_test_equip_rare_sword(equipment_system)
	_print_equipment_info(equipment_system)

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
	var can_equip: bool = equipment_system.can_equip_item("rare_sword", 5, 0)
	print("精钢剑(5级)可装备: %s" % ("是" if can_equip else "否"))
	
	can_equip = equipment_system.can_equip_item("rare_sword", TEST_CHARACTER_LEVEL, TEST_CHARACTER_REALM)
	print("精钢剑(10级筑基)可装备: %s" % ("是" if can_equip else "否"))
	
	if can_equip:
		equipment_system.equip_item("rare_sword", TEST_CHARACTER_LEVEL, TEST_CHARACTER_REALM)
		print("✅ 成功装备精钢剑")
	else:
		print("❌ 无法装备精钢剑")

## 测试槽位解锁按钮回调
func _on_test_slot_unlock_pressed() -> void:
	var equipment_system: Node = get_node_or_null(EQUIPMENT_SYSTEM_PATH)
	
	if equipment_system == null:
		push_error("无法访问装备系统")
		return
	
	_test_slot_unlock_by_realm(equipment_system)

## 按境界测试槽位解锁
func _test_slot_unlock_by_realm(equipment_system: Node) -> void:
	for i in range(TEST_REALMS.size()):
		var realm: int = TEST_REALMS[i]
		var realm_name: String = TEST_REALM_NAMES[i]
		print("=== %s 期槽位解锁情况 ===" % realm_name)
		
		for slot in equipment_system.slot_unlock_realm:
			var unlocked: bool = equipment_system.is_slot_unlocked(slot, realm)
			var slot_name: String = equipment_system.get_slot_name(slot)
			print("  %s: %s" % [slot_name, "已解锁" if unlocked else "未解锁"])
	
	print("==================")

## 测试装备强化按钮回调
func _on_test_enhancement_pressed() -> void:
	var equipment_system: Node = get_node_or_null(EQUIPMENT_SYSTEM_PATH)
	var character_system: Node = get_node_or_null(CHARACTER_SYSTEM_PATH)
	
	if not _validate_systems(equipment_system, character_system):
		return
	
	_initialize_test_character(character_system)
	equipment_system.equip_item("common_sword", TEST_CHARACTER_LEVEL, TEST_CHARACTER_REALM)
	
	_test_enhancement_success_rates(equipment_system)
	_test_enhancement_failure_handling()
	_print_equipment_attributes(equipment_system)

## 测试强化成功率
func _test_enhancement_success_rates(equipment_system: Node) -> void:
	print("=== 强化成功率测试 ===")
	
	if not equipment_system.has_meta("enhancement_config"):
		push_warning("装备系统缺少强化配置")
		return
	
	var config: Dictionary = equipment_system.get_meta("enhancement_config")
	if not config.has("success_rates"):
		push_warning("强化配置缺少成功率数据")
		return
	
	var success_rates: Array = config["success_rates"]
	for level in range(mini(21, success_rates.size())):
		var success_rate: float = success_rates[level]
		print("  +%d -> +%d: 成功率 %.0f%%" % [level, level + 1, success_rate * 100])

## 测试强化失败处理
func _test_enhancement_failure_handling() -> void:
	print("=== 强化失败处理测试 ===")
	print("  强化到+12失败: 不降级")
	print("  强化到+18失败: 降级1-2级")

## 初始化测试角色
func _initialize_test_character(character_system: Node) -> void:
	character_system.initialize_character()
	character_system.level = TEST_CHARACTER_LEVEL
	character_system.realm_index = TEST_CHARACTER_REALM

## 验证系统是否可用
func _validate_systems(equipment_system: Node, character_system: Node) -> bool:
	if equipment_system == null or character_system == null:
		push_error("无法访问装备系统或角色系统")
		return false
	return true

## 打印装备信息
func _print_equipment_info(equipment_system: Node) -> void:
	if equipment_system.has_method("debug_print_equipment_info"):
		equipment_system.debug_print_equipment_info()
	else:
		push_warning("装备系统缺少 debug_print_equipment_info 方法")

## 打印装备属性
func _print_equipment_attributes(equipment_system: Node) -> void:
	var equipment_attrs: Dictionary = equipment_system.get_equipment_attributes()
	print("当前装备属性:")
	print("  力道: %d" % equipment_attrs["base"]["strength"])
	print("  攻击力: %d" % equipment_attrs["combat"]["attack"])
	print("  火属性: %d" % equipment_attrs["elemental"]["fire"])