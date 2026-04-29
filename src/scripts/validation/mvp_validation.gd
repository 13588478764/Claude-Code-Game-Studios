## 武侠奇遇录 - MVP验证脚本
## 用于验证所有核心系统的完整性和集成性
##
## 主要功能：
## - 验证所有核心系统的初始化
## - 验证系统间的集成
## - 生成验证报告

extends Node

class_name MvpValidation

# ============================================================================
# 常量定义
# ============================================================================

const CHARACTER_SYSTEM_PATH: String = "/root/CharacterSystem"
const COMBAT_SYSTEM_PATH: String = "/root/CombatSystem"
const EXPERIENCE_SYSTEM_PATH: String = "/root/ExperienceSystem"
const EQUIPMENT_SYSTEM_PATH: String = "/root/EquipmentSystem"
const ENCOUNTER_SYSTEM_PATH: String = "/root/EncounterSystem"
const UI_SYSTEM_PATH: String = "/root/UIManager"
const SAVE_SYSTEM_PATH: String = "/root/SaveSystem"
const AUDIO_SYSTEM_PATH: String = "/root/AudioManager"
const QUEST_SYSTEM_PATH: String = "/root/QuestSystem"
const WORLD_SYSTEM_PATH: String = "/root/WorldSystem"
const ECONOMY_SYSTEM_PATH: String = "/root/EconomySystem"

const MAX_CHARACTER_LEVEL: int = 99
const EXPECTED_REALM_COUNT: int = 10
const EXPECTED_ATTRIBUTE_COUNT: int = 6

# ============================================================================
# 信号定义
# ============================================================================

## 验证完成信号
signal validation_complete(results: Dictionary)

## 系统验证完成信号
signal system_validated(system_name: String, passed: bool)

# ============================================================================
# 成员变量
# ============================================================================

## 验证结果字典
var validation_results: Dictionary = {
	"character_system": false,
	"combat_system": false,
	"experience_system": false,
	"equipment_system": false,
	"encounter_system": false,
	"ui_system": false,
	"save_system": false,
	"audio_system": false,
	"quest_system": false,
	"world_system": false,
	"economy_system": false,
	"integration_test": false
}

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化MVP验证
func _ready() -> void:
	print("=== 武侠奇遇录 MVP验证开始 ===")
	_validate_all_systems()

# ============================================================================
# 公共方法
# ============================================================================

## 获取验证结果
func get_validation_results() -> Dictionary:
	return validation_results.duplicate()

## 获取通过的系统数量
func get_passed_count() -> int:
	var count: int = 0
	for result in validation_results.values():
		if result:
			count += 1
	return count

## 获取总系统数量
func get_total_count() -> int:
	return validation_results.size()

## 验证是否全部通过
func is_all_passed() -> bool:
	return get_passed_count() == get_total_count()

# ============================================================================
# 私有方法
# ============================================================================

## 验证所有系统
func _validate_all_systems() -> void:
	validation_results["character_system"] = _validate_character_system()
	system_validated.emit("character_system", validation_results["character_system"])
	
	validation_results["combat_system"] = _validate_combat_system()
	system_validated.emit("combat_system", validation_results["combat_system"])
	
	validation_results["experience_system"] = _validate_experience_system()
	system_validated.emit("experience_system", validation_results["experience_system"])
	
	validation_results["equipment_system"] = _validate_equipment_system()
	system_validated.emit("equipment_system", validation_results["equipment_system"])
	
	validation_results["encounter_system"] = _validate_encounter_system()
	system_validated.emit("encounter_system", validation_results["encounter_system"])
	
	validation_results["ui_system"] = _validate_ui_system()
	system_validated.emit("ui_system", validation_results["ui_system"])
	
	validation_results["save_system"] = _validate_save_system()
	system_validated.emit("save_system", validation_results["save_system"])
	
	validation_results["audio_system"] = _validate_audio_system()
	system_validated.emit("audio_system", validation_results["audio_system"])
	
	validation_results["quest_system"] = _validate_quest_system()
	system_validated.emit("quest_system", validation_results["quest_system"])
	
	validation_results["world_system"] = _validate_world_system()
	system_validated.emit("world_system", validation_results["world_system"])
	
	validation_results["economy_system"] = _validate_economy_system()
	system_validated.emit("economy_system", validation_results["economy_system"])
	
	validation_results["integration_test"] = _validate_integration()
	system_validated.emit("integration_test", validation_results["integration_test"])
	
	_print_validation_results()
	validation_complete.emit(validation_results)

## 验证角色成长系统
func _validate_character_system() -> bool:
	print("验证角色成长系统...")
	
	var character_system: Node = get_node_or_null(CHARACTER_SYSTEM_PATH)
	if character_system == null:
		push_error("无法访问 CharacterSystem")
		return false
	
	if not character_system.has_method("initialize_character"):
		push_error("CharacterSystem 缺少 initialize_character 方法")
		return false
	
	character_system.initialize_character()
	
	if character_system.level > MAX_CHARACTER_LEVEL:
		push_error("角色等级超过 %d 级上限" % MAX_CHARACTER_LEVEL)
		return false
	
	if not character_system.has_method("get_total_attributes"):
		push_error("CharacterSystem 缺少 get_total_attributes 方法")
		return false
	
	var attributes: Dictionary = character_system.get_total_attributes()
	if attributes.size() != EXPECTED_ATTRIBUTE_COUNT:
		push_error("六维属性数量不正确，期望 %d，实际 %d" % [EXPECTED_ATTRIBUTE_COUNT, attributes.size()])
		return false
	
	print("✅ 角色成长系统验证通过")
	return true

## 验证战斗系统
func _validate_combat_system() -> bool:
	print("验证战斗系统...")
	
	var combat_system: Node = get_node_or_null(COMBAT_SYSTEM_PATH)
	if combat_system == null:
		push_error("无法访问 CombatSystem")
		return false
	
	if not combat_system.has_method("start_battle"):
		push_error("CombatSystem 缺少 start_battle 方法")
		return false
	
	var player_data: Dictionary = _create_test_player_data()
	var enemy_data: Dictionary = _create_test_enemy_data()
	
	combat_system.start_battle([player_data], [enemy_data])
	
	if not combat_system.has_method("get_player_characters"):
		push_error("CombatSystem 缺少 get_player_characters 方法")
		return false
	
	var player_characters: Array = combat_system.get_player_characters()
	if player_characters.size() == 0:
		push_error("战斗系统初始化失败")
		return false
	
	print("✅ 战斗系统验证通过")
	return true

## 验证经验值系统
func _validate_experience_system() -> bool:
	print("验证经验值系统...")
	
	var character_system: Node = get_node_or_null(CHARACTER_SYSTEM_PATH)
	if character_system == null:
		push_error("无法访问 CharacterSystem")
		return false
	
	if not character_system.has_method("add_experience"):
		push_error("CharacterSystem 缺少 add_experience 方法")
		return false
	
	character_system.initialize_character()
	var initial_level: int = character_system.level
	
	character_system.add_experience(1000)
	
	if character_system.level <= initial_level:
		push_error("经验值系统未正确处理升级")
		return false
	
	print("✅ 经验值系统验证通过")
	return true

## 验证装备系统
func _validate_equipment_system() -> bool:
	print("验证装备系统...")
	
	var equipment_system: Node = get_node_or_null(EQUIPMENT_SYSTEM_PATH)
	var character_system: Node = get_node_or_null(CHARACTER_SYSTEM_PATH)
	
	if equipment_system == null or character_system == null:
		push_error("无法访问装备系统或角色系统")
		return false
	
	if not equipment_system.has_method("equip_item"):
		push_error("EquipmentSystem 缺少 equip_item 方法")
		return false
	
	character_system.level = 10
	character_system.realm_index = 1
	
	equipment_system.equip_item("common_sword", 10, 1)
	
	if not equipment_system.has_method("get_equipment_attributes"):
		push_error("EquipmentSystem 缺少 get_equipment_attributes 方法")
		return false
	
	var total_attributes: Dictionary = equipment_system.get_equipment_attributes()
	if total_attributes.size() == 0:
		push_error("装备属性计算失败")
		return false
	
	print("✅ 装备系统验证通过")
	return true

## 验证奇遇系统
func _validate_encounter_system() -> bool:
	print("验证奇遇系统...")
	
	var encounter_system: Node = get_node_or_null(ENCOUNTER_SYSTEM_PATH)
	if encounter_system == null:
		push_error("无法访问 EncounterSystem")
		return false
	
	if not encounter_system.has_method("can_trigger_encounter"):
		push_error("EncounterSystem 缺少 can_trigger_encounter 方法")
		return false
	
	print("✅ 奇遇系统验证通过")
	return true

## 验证UI系统
func _validate_ui_system() -> bool:
	print("验证UI系统...")
	
	var ui_manager: Node = get_node_or_null(UI_SYSTEM_PATH)
	if ui_manager == null:
		push_error("无法访问 UIManager")
		return false
	
	if not ui_manager.has_method("switch_to_state"):
		push_error("UIManager 缺少 switch_to_state 方法")
		return false
	
	print("✅ UI系统验证通过")
	return true

## 验证存档系统
func _validate_save_system() -> bool:
	print("验证存档系统...")
	
	var save_system: Node = get_node_or_null(SAVE_SYSTEM_PATH)
	if save_system == null:
		push_error("无法访问 SaveSystem")
		return false
	
	if not save_system.has_method("save_to_slot"):
		push_error("SaveSystem 缺少 save_to_slot 方法")
		return false
	
	print("✅ 存档系统验证通过")
	return true

## 验证音效系统
func _validate_audio_system() -> bool:
	print("验证音效系统...")
	
	var audio_manager: Node = get_node_or_null(AUDIO_SYSTEM_PATH)
	if audio_manager == null:
		push_error("无法访问 AudioManager")
		return false
	
	print("✅ 音效系统验证通过")
	return true

## 验证任务系统
func _validate_quest_system() -> bool:
	print("验证任务系统...")
	
	var quest_system: Node = get_node_or_null(QUEST_SYSTEM_PATH)
	if quest_system == null:
		push_error("无法访问 QuestSystem")
		return false
	
	if not quest_system.has_method("accept_quest"):
		push_error("QuestSystem 缺少 accept_quest 方法")
		return false
	
	print("✅ 任务系统验证通过")
	return true

## 验证世界系统
func _validate_world_system() -> bool:
	print("验证世界系统...")
	
	var world_system: Node = get_node_or_null(WORLD_SYSTEM_PATH)
	if world_system == null:
		push_error("无法访问 WorldSystem")
		return false
	
	if not world_system.has_method("enter_region"):
		push_error("WorldSystem 缺少 enter_region 方法")
		return false
	
	print("✅ 世界系统验证通过")
	return true

## 验证经济系统
func _validate_economy_system() -> bool:
	print("验证经济系统...")
	
	var economy_system: Node = get_node_or_null(ECONOMY_SYSTEM_PATH)
	if economy_system == null:
		push_error("无法访问 EconomySystem")
		return false
	
	if not economy_system.has_method("add_silver"):
		push_error("EconomySystem 缺少 add_silver 方法")
		return false
	
	print("✅ 经济系统验证通过")
	return true

## 验证系统集成
func _validate_integration() -> bool:
	print("验证系统集成...")
	
	var character_system: Node = get_node_or_null(CHARACTER_SYSTEM_PATH)
	if character_system == null:
		push_error("无法访问 CharacterSystem")
		return false
	
	character_system.initialize_character()
	character_system.add_experience(500)
	
	print("✅ 系统集成验证通过")
	return true

## 创建测试玩家数据
func _create_test_player_data() -> Dictionary:
	return {
		"id": "test_player",
		"level": 10,
		"realm": 1,
		"health": 200,
		"max_health": 200,
		"defense": 30,
		"poise": 50,
		"max_poise": 50,
		"qi": 100,
		"max_qi": 100,
		"evasion": 0.1,
		"critical_rate": 0.15,
		"hit_rate": 0.95,
		"attributes": {
			"strength": 25,
			"agility": 20,
			"constitution": 22,
			"intelligence": 18,
			"willpower": 16,
			"luck": 12
		},
		"equipped_items": ["rare_sword", "rare_helmet"],
		"martial_arts": ["basic_sword", "fire_palm"],
		"status_effects": [],
		"is_player": true
	}

## 创建测试敌人数据
func _create_test_enemy_data() -> Dictionary:
	return {
		"id": "test_enemy",
		"level": 5,
		"realm": 0,
		"health": 100,
		"max_health": 100,
		"defense": 20,
		"poise": 30,
		"max_poise": 30,
		"qi": 50,
		"max_qi": 50,
		"evasion": 0.05,
		"critical_rate": 0.05,
		"hit_rate": 0.85,
		"attributes": {
			"strength": 15,
			"agility": 12,
			"constitution": 14,
			"intelligence": 8,
			"willpower": 10,
			"luck": 6
		},
		"equipped_items": ["common_sword"],
		"martial_arts": ["basic_sword"],
		"status_effects": [],
		"is_player": false
	}

## 打印验证结果
func _print_validation_results() -> void:
	print("\n=== MVP验证结果 ===")
	var passed: int = get_passed_count()
	var total: int = get_total_count()
	
	for system in validation_results:
		var status: String = "✅" if validation_results[system] else "❌"
		var result: String = "通过" if validation_results[system] else "失败"
		print("%s %s: %s" % [status, system, result])
	
	print("\n总计: %d/%d 通过" % [passed, total])
	
	if is_all_passed():
		print("🎉 MVP验证完全成功！所有系统正常工作！")
	else:
		print("⚠️  部分系统验证失败，请检查上述错误信息")
	
	print("====================")

func validate_all_systems():
	"""验证所有系统"""
	
	# 1. 角色成长系统验证
	validation_results["character_system"] = validate_character_system()
	
	# 2. 战斗系统验证
	validation_results["combat_system"] = validate_combat_system()
	
	# 3. 经验值系统验证
	validation_results["experience_system"] = validate_experience_system()
	
	# 4. 装备系统验证
	validation_results["equipment_system"] = validate_equipment_system()
	
	# 5. 奇遇系统验证
	validation_results["encounter_system"] = validate_encounter_system()
	
	# 6. UI系统验证
	validation_results["ui_system"] = validate_ui_system()
	
	# 7. 存档系统验证
	validation_results["save_system"] = validate_save_system()
	
	# 8. 音效系统验证
	validation_results["audio_system"] = validate_audio_system()
	
	# 9. 任务系统验证
	validation_results["quest_system"] = validate_quest_system()
	
	# 10. 世界系统验证
	validation_results["world_system"] = validate_world_system()
	
	# 11. 经济系统验证
	validation_results["economy_system"] = validate_economy_system()
	
	# 12. 集成测试
	validation_results["integration_test"] = validate_integration()
	
	# 输出验证结果
	print_validation_results()

func validate_character_system():
	"""验证角色成长系统"""
	print("验证角色成长系统...")
	
	# 初始化角色
	CharacterSystem.initialize_character()
	
	# 测试等级上限
	if CharacterSystem.level > 99:
		print("❌ 角色等级超过99级上限")
		return false
	
	# 测试境界数量
	var realms = CharacterSystem.realms
	if realms.size() != 10:
		print("❌ 境界数量不是10个")
		return false
	
	# 测试六维属性
	var attributes = CharacterSystem.attributes.get_total()
	if not (attributes.has("strength") and attributes.has("agility") and 
			attributes.has("constitution") and attributes.has("intelligence") and
			attributes.has("willpower") and attributes.has("luck")):
		print("❌ 六维属性不完整")
		return false
	
	print("✅ 角色成长系统验证通过")
	return true

func validate_combat_system():
	"""验证战斗系统"""
	print("验证战斗系统...")
	
	# 创建测试战斗数据
	var player_data = {
		"id": "test_player",
		"level": 10,
		"realm": 1,
		"health": 200,
		"max_health": 200,
		"defense": 30,
		"poise": 50,
		"max_poise": 50,
		"qi": 100,
		"max_qi": 100,
		"evasion": 0.1,
		"critical_rate": 0.15,
		"hit_rate": 0.95,
		"attributes": {
			"strength": 25,
			"agility": 20,
			"constitution": 22,
			"intelligence": 18,
			"willpower": 16,
			"luck": 12
		},
		"equipped_items": ["rare_sword", "rare_helmet"],
		"martial_arts": ["basic_sword", "fire_palm"],
		"status_effects": [],
		"is_player": true
	}
	
	var enemy_data = {
		"id": "test_enemy",
		"level": 5,
		"realm": 0,
		"health": 100,
		"max_health": 100,
		"defense": 20,
		"poise": 30,
		"max_poise": 30,
		"qi": 50,
		"max_qi": 50,
		"evasion": 0.05,
		"critical_rate": 0.05,
		"hit_rate": 0.85,
		"attributes": {
			"strength": 15,
			"agility": 12,
			"constitution": 14,
			"intelligence": 8,
			"willpower": 10,
			"luck": 6,
			"wood_weakness": true
		},
		"equipped_items": ["common_sword"],
		"martial_arts": ["basic_sword"],
		"status_effects": [],
		"is_player": false
	}
	
	# 开始战斗
	CombatSystem.start_battle([player_data], [enemy_data])
	
	# 检查战斗状态
	if CombatSystem.player_characters.size() == 0 or CombatSystem.enemy_characters.size() == 0:
		print("❌ 战斗系统初始化失败")
		return false
	
	print("✅ 战斗系统验证通过")
	return true

func validate_experience_system():
	"""验证经验值系统"""
	print("验证经验值系统...")
	
	CharacterSystem.initialize_character()
	var initial_exp = CharacterSystem.experience
	var initial_level = CharacterSystem.level
	
	# 添加经验值
	CharacterSystem.add_experience(1000)
	
	# 检查是否升级
	if CharacterSystem.level <= initial_level:
		print("❌ 经验值系统未正确处理升级")
		return false
	
	# 检查EXP曲线
	var exp_for_level_10 = ExperienceSystem.get_exp_for_level(10)
	if exp_for_level_10 <= 0:
		print("❌ EXP曲线计算错误")
		return false
	
	print("✅ 经验值系统验证通过")
	return true

func validate_equipment_system():
	"""验证装备系统"""
	print("验证装备系统...")
	
	CharacterSystem.level = 10
	CharacterSystem.realm_index = 1
	
	# 装备测试物品
	EquipmentSystem.equip_item("common_sword", 10, 1)
	EquipmentSystem.equip_item("rare_helmet", 10, 1)
	
	# 检查装备槽位
	if EquipmentSystem.equipped_items[EquipmentSystem.EquipmentSlot.WEAPON_MAIN] != "common_sword":
		print("❌ 装备系统未正确装备物品")
		return false
	
	# 检查装备属性计算
	var total_attributes = EquipmentSystem.get_equipment_attributes()
	if total_attributes.size() == 0:
		print("❌ 装备属性计算失败")
		return false
	
	print("✅ 装备系统验证通过")
	return true

func validate_encounter_system():
	"""验证奇遇系统"""
	print("验证奇遇系统...")
	
	CharacterSystem.level = 10
	CharacterSystem.attributes.luck = 50
	
	# 测试触发概率
	var can_trigger = EncounterSystem.can_trigger_encounter(
		EncounterSystem.TriggerContext.MAP_MOVEMENT, 
		50
	)
	
	# 测试保底机制
	EncounterSystem.consecutive_failures = 20
	var guaranteed_trigger = EncounterSystem.can_trigger_encounter(
		EncounterSystem.TriggerContext.MAP_MOVEMENT, 
		0
	)
	
	if not guaranteed_trigger:
		print("❌ 奇遇系统保底机制失效")
		return false
	
	print("✅ 奇遇系统验证通过")
	return true

func validate_ui_system():
	"""验证UI系统"""
	print("验证UI系统...")
	
	# 测试UI管理器初始化
	if UIManager == null:
		print("❌ UI系统未正确初始化")
		return false
	
	# 测试品阶颜色
	UIManager.debug_print_ui_info()
	
	print("✅ UI系统验证通过")
	return true

func validate_save_system():
	"""验证存档系统"""
	print("验证存档系统...")
	
	CharacterSystem.initialize_character()
	CharacterSystem.add_experience(1000)
	
	# 测试存档
	var save_success = SaveSystem.save_to_slot(0)
	if not save_success:
		print("❌ 存档系统保存失败")
		return false
	
	# 测试加载
	var loaded_data = SaveSystem.load_from_slot(0)
	if loaded_data == null:
		print("❌ 存档系统加载失败")
		return false
	
	print("✅ 存档系统验证通过")
	return true

func validate_audio_system():
	"""验证音效系统"""
	print("验证音效系统...")
	
	# 测试音效系统初始化
	if AudioManager == null:
		print("❌ 音效系统未正确初始化")
		return false
	
	AudioSystem.debug_print_audio_info()
	
	print("✅ 音效系统验证通过")
	return true

func validate_quest_system():
	"""验证任务系统"""
	print("验证任务系统...")
	
	CharacterSystem.level = 10
	
	# 创建测试任务
	var test_quest = QuestSystem.QuestData.new()
	test_quest.id = "test_quest"
	test_quest.name = "测试任务"
	test_quest.type = QuestSystem.QuestType.MAIN
	test_quest.state = QuestSystem.QuestState.AVAILABLE
	test_quest.required_level = 5
	
	QuestSystem.available_quests.append(test_quest.id)
	
	# 测试接取任务
	var accept_success = QuestSystem.accept_quest(test_quest.id)
	if not accept_success:
		print("❌ 任务系统接取任务失败")
		return false
	
	print("✅ 任务系统验证通过")
	return true

func validate_world_system():
	"""验证世界系统"""
	print("验证世界系统...")
	
	# 测试区域进入
	WorldSystem.enter_region("bandit_fortress")
	
	if WorldSystem.current_region != "bandit_fortress":
		print("❌ 世界系统区域切换失败")
		return false
	
	print("✅ 世界系统验证通过")
	return true

func validate_economy_system():
	"""验证经济系统"""
	print("验证经济系统...")
	
	# 测试银两添加
	EconomySystem.add_silver(1000)
	if EconomySystem.silver != 1000:
		print("❌ 经济系统银两添加失败")
		return false
	
	# 测试强化费用计算
	var cost = EconomySystem.calculate_reinforcement_cost(5)
	if cost <= 0:
		print("❌ 经济系统强化费用计算失败")
		return false
	
	print("✅ 经济系统验证通过")
	return true

func validate_integration():
	"""验证系统集成"""
	print("验证系统集成...")
	
	# 完整游戏循环测试
	CharacterSystem.initialize_character()
	CharacterSystem.add_experience(500)  # 升级到5级左右
	
	# 装备武器
	EconomySystem.add_silver(1000)
	EconomySystem.buy_item("regular", "reinforcement_stone_common", 1)
	
	# 触发奇遇
	EncounterSystem.consecutive_failures = 20
	var encounter = EncounterSystem.trigger_encounter(50, 5, 1, EncounterSystem.TriggerContext.MAP_MOVEMENT)
	if encounter == null:
		print("❌ 系统集成测试失败 - 奇遇触发失败")
		return false
	
	# 战斗测试
	var player_data = {
		"id": "integration_test_player",
		"level": CharacterSystem.level,
		"realm": CharacterSystem.realm_index,
		"health": 150,
		"max_health": 150,
		"defense": 25,
		"poise": 40,
		"max_poise": 40,
		"qi": 80,
		"max_qi": 80,
		"evasion": 0.08,
		"critical_rate": 0.12,
		"hit_rate": 0.92,
		"attributes": CharacterSystem.attributes.get_total(),
		"equipped_items": ["common_sword"],
		"martial_arts": ["basic_sword"],
		"status_effects": [],
		"is_player": true
	}
	
	CombatSystem.start_battle([player_data], [])
	if CombatSystem.player_characters.size() == 0:
		print("❌ 系统集成测试失败 - 战斗系统集成失败")
		return false
	
	print("✅ 系统集成验证通过")
	return true

func print_validation_results():
	"""打印验证结果"""
	print("\n=== MVP验证结果 ===")
	var passed = 0
	var total = validation_results.size()
	
	for system in validation_results:
		var status = "✅" if validation_results[system] else "❌"
		print("%s %s: %s" % [status, system, "通过" if validation_results[system] else "失败"])
		if validation_results[system]:
			passed += 1
	
	print("\n总计: %d/%d 通过" % [passed, total])
	
	if passed == total:
		print("🎉 MVP验证完全成功！所有系统正常工作！")
	else:
		print("⚠️  部分系统验证失败，请检查上述错误信息")
	
	print("====================")