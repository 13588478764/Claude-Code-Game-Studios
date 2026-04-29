# 武侠奇遇录 - 主游戏脚本
# 处理主界面按钮点击事件

extends Node2D

func _ready():
	print("主游戏脚本初始化完成")
	
	# 手动连接按钮信号（Godot 4可靠方案）
	var start_button = get_node("StartNewGameButton")
	if start_button != null:
		start_button.pressed.connect(_on_start_new_game_pressed)
	
	var load_button = get_node("LoadGameButton")
	if load_button != null:
		load_button.pressed.connect(_on_load_game_pressed)
	
	var test_button = get_node("TestAllSystemsButton")
	if test_button != null:
		test_button.pressed.connect(_on_test_all_systems_pressed)

func _on_start_new_game_pressed():
	"""开始新游戏按钮回调"""
	print("=== 开始新游戏 ===")
	
	# 初始化角色系统
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null:
		character_system.initialize_character()
		print("角色初始化完成，当前等级: %d" % character_system.level)
	
	# 初始化其他系统
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	if equipment_system != null:
		print("装备系统就绪")
	
	var encounter_system = get_node_or_null("/root/EncounterSystem")
	if encounter_system != null:
		print("奇遇系统就绪")
	
	print("新游戏已开始！")
	print("====================")

func _on_load_game_pressed():
	"""加载游戏按钮回调"""
	print("=== 加载游戏 ===")
	
	var save_system = get_node_or_null("/root/SaveSystem")
	if save_system != null:
		var loaded_data = save_system.load_from_slot(0)
		if loaded_data != null:
			print("游戏加载成功！")
		else:
			print("没有找到存档，开始新游戏")
			_on_start_new_game_pressed()
	else:
		print("存档系统不可用")
	
	print("====================")

func _on_test_all_systems_pressed():
	"""测试所有系统按钮回调"""
	print("=== 开始MVP完整验证 ===")
	
	# 运行完整的MVP验证
	var validation_results = {
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
	print_validation_results(validation_results)

func validate_character_system():
	"""验证角色成长系统"""
	print("验证角色成长系统...")
	
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system == null:
		print("❌ 角色系统未找到")
		return false
	
	# 初始化角色
	character_system.initialize_character()
	
	# 测试等级上限
	if character_system.level > 99:
		print("❌ 角色等级超过99级上限")
		return false
	
	# 测试境界数量
	var realms = character_system.REALMS
	if realms.size() != 10:
		print("❌ 境界数量不是10个")
		return false
	
	# 测试六维属性
	var attributes = character_system.attributes.get_total()
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
	
	var combat_system = get_node_or_null("/root/CombatSystem")
	if combat_system == null:
		print("❌ 战斗系统未找到")
		return false
	
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
	combat_system.start_battle([player_data], [enemy_data])
	
	# 检查战斗状态
	if combat_system.player_characters.size() == 0 or combat_system.enemy_characters.size() == 0:
		print("❌ 战斗系统初始化失败")
		return false
	
	print("✅ 战斗系统验证通过")
	return true

func validate_experience_system():
	"""验证经验值系统"""
	print("验证经验值系统...")
	
	var character_system = get_node_or_null("/root/CharacterSystem")
	var experience_system = get_node_or_null("/root/ExperienceSystem")
	
	if character_system == null or experience_system == null:
		print("❌ 经验值系统未找到")
		return false
	
	character_system.initialize_character()
	var initial_exp = character_system.experience
	var initial_level = character_system.level
	
	# 添加经验值
	character_system.add_experience(1000)
	
	# 检查是否升级
	if character_system.level <= initial_level:
		print("❌ 经验值系统未正确处理升级")
		return false
	
	# 检查EXP曲线
	var exp_for_level_10 = experience_system.get_exp_required_for_level(10)
	if exp_for_level_10 <= 0:
		print("❌ EXP曲线计算错误")
		return false
	
	print("✅ 经验值系统验证通过")
	return true

func validate_equipment_system():
	"""验证装备系统"""
	print("验证装备系统...")
	
	var character_system = get_node_or_null("/root/CharacterSystem")
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	
	if character_system == null or equipment_system == null:
		print("❌ 装备系统未找到")
		return false
	
	character_system.level = 10
	character_system.realm_index = 1
	
	# 装备测试物品
	equipment_system.equip_item("common_sword", 10, 1)
	equipment_system.equip_item("rare_helmet", 10, 1)
	
	# 检查装备槽位
	if equipment_system.equipped_items[equipment_system.EquipmentSlot.WEAPON_MAIN] != "common_sword":
		print("❌ 装备系统未正确装备物品")
		return false
	
	# 检查装备属性计算
	var total_attributes = equipment_system.get_equipment_attributes()
	if total_attributes.size() == 0:
		print("❌ 装备属性计算失败")
		return false
	
	print("✅ 装备系统验证通过")
	return true

func validate_encounter_system():
	"""验证奇遇系统"""
	print("验证奇遇系统...")
	
	var character_system = get_node_or_null("/root/CharacterSystem")
	var encounter_system = get_node_or_null("/root/EncounterSystem")
	
	if character_system == null or encounter_system == null:
		print("❌ 奇遇系统未找到")
		return false
	
	character_system.level = 10
	character_system.attributes.luck = 50
	
	# 测试触发概率
	var can_trigger = encounter_system.can_trigger_encounter(
		encounter_system.TriggerContext.MAP_MOVEMENT, 
		50
	)
	
	# 测试保底机制
	encounter_system.consecutive_failures = 20
	var guaranteed_trigger = encounter_system.can_trigger_encounter(
		encounter_system.TriggerContext.MAP_MOVEMENT, 
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
	
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager == null:
		print("❌ UI系统未找到")
		return false
	
	# 测试UI管理器初始化
	ui_manager.debug_print_ui_info()
	
	print("✅ UI系统验证通过")
	return true

func validate_save_system():
	"""验证存档系统"""
	print("验证存档系统...")
	
	var character_system = get_node_or_null("/root/CharacterSystem")
	var save_system = get_node_or_null("/root/SaveSystem")
	
	if character_system == null or save_system == null:
		print("❌ 存档系统未找到")
		return false
	
	character_system.initialize_character()
	character_system.add_experience(1000)
	
	# 测试存档
	var save_success = save_system.save_to_slot(0)
	if not save_success:
		print("❌ 存档系统保存失败")
		return false
	
	# 测试加载
	var loaded_data = save_system.load_from_slot(0)
	if loaded_data == null:
		print("❌ 存档系统加载失败")
		return false
	
	print("✅ 存档系统验证通过")
	return true

func validate_audio_system():
	"""验证音效系统"""
	print("验证音效系统...")
	
	var audio_system = get_node_or_null("/root/AudioSystem")
	if audio_system == null:
		print("❌ 音效系统未找到")
		return false
	
	audio_system.debug_print_audio_info()
	
	print("✅ 音效系统验证通过")
	return true

func validate_quest_system():
	"""验证任务系统"""
	print("验证任务系统...")
	
	var character_system = get_node_or_null("/root/CharacterSystem")
	var quest_system = get_node_or_null("/root/QuestSystem")
	
	if character_system == null or quest_system == null:
		print("❌ 任务系统未找到")
		return false
	
	character_system.level = 10
	
	# 创建测试任务
	var test_quest = quest_system.QuestData.new()
	test_quest.id = "test_quest"
	test_quest.name = "测试任务"
	test_quest.type = quest_system.QuestType.MAIN
	test_quest.state = quest_system.QuestState.AVAILABLE
	test_quest.required_level = 5
	
	quest_system.available_quests.append(test_quest.id)
	
	# 测试接取任务
	var accept_success = quest_system.accept_quest(test_quest.id)
	if not accept_success:
		print("❌ 任务系统接取任务失败")
		return false
	
	print("✅ 任务系统验证通过")
	return true

func validate_world_system():
	"""验证世界系统"""
	print("验证世界系统...")
	
	var world_system = get_node_or_null("/root/WorldSystem")
	if world_system == null:
		print("❌ 世界系统未找到")
		return false
	
	# 测试区域进入
	world_system.enter_region("bandit_fortress")
	
	if world_system.current_region != "bandit_fortress":
		print("❌ 世界系统区域切换失败")
		return false
	
	print("✅ 世界系统验证通过")
	return true

func validate_economy_system():
	"""验证经济系统"""
	print("验证经济系统...")
	
	var economy_system = get_node_or_null("/root/EconomySystem")
	if economy_system == null:
		print("❌ 经济系统未找到")
		return false
	
	# 测试银两添加
	economy_system.add_silver(1000)
	if economy_system.silver != 1000:
		print("❌ 经济系统银两添加失败")
		return false
	
	# 测试强化费用计算
	var cost = economy_system.calculate_reinforcement_cost(5)
	if cost <= 0:
		print("❌ 经济系统强化费用计算失败")
		return false
	
	print("✅ 经济系统验证通过")
	return true

func validate_integration():
	"""验证系统集成"""
	print("验证系统集成...")
	
	var character_system = get_node_or_null("/root/CharacterSystem")
	var economy_system = get_node_or_null("/root/EconomySystem")
	var encounter_system = get_node_or_null("/root/EncounterSystem")
	var combat_system = get_node_or_null("/root/CombatSystem")
	
	if character_system == null or economy_system == null or encounter_system == null or combat_system == null:
		print("❌ 集成测试所需系统缺失")
		return false
	
	# 完整游戏循环测试
	character_system.initialize_character()
	character_system.add_experience(500)  # 升级到5级左右
	
	# 装备武器
	economy_system.add_silver(1000)
	economy_system.buy_item("regular", "reinforcement_stone_common", 1)
	
	# 触发奇遇
	encounter_system.consecutive_failures = 20
	var encounter = encounter_system.trigger_encounter(50, 5, 1, encounter_system.TriggerContext.MAP_MOVEMENT)
	if encounter == null:
		print("❌ 系统集成测试失败 - 奇遇触发失败")
		return false
	
	# 战斗测试
	var player_data = {
		"id": "integration_test_player",
		"level": character_system.level,
		"realm": character_system.realm_index,
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
		"attributes": character_system.attributes.get_total(),
		"equipped_items": ["common_sword"],
		"martial_arts": ["basic_sword"],
		"status_effects": [],
		"is_player": true
	}
	
	combat_system.start_battle([player_data], [])
	if combat_system.player_characters.size() == 0:
		print("❌ 系统集成测试失败 - 战斗系统集成失败")
		return false
	
	print("✅ 系统集成验证通过")
	return true

func print_validation_results(validation_results):
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
