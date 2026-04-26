# 武侠奇遇录 - 主游戏UI脚本
# 负责管理主游戏界面和基本游戏功能

extends Node2D

func _ready():
	print("主游戏UI脚本初始化完成")
	# 初始化角色系统
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null:
		character_system.initialize_character()
	
	# 手动连接按钮信号
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
	
	# 初始化所有系统
	initialize_game_systems()
	
	# 显示角色面板进行测试
	show_character_panel()
	
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
			show_character_panel()
		else:
			print("没有找到存档，开始新游戏")
			_on_start_new_game_pressed()
	else:
		print("存档系统不可用")
	
	print("====================")

func _on_test_all_systems_pressed():
	"""测试所有系统按钮回调"""
	print("=== 开始MVP完整验证 ===")
	
	# 直接调用现有的MVP验证脚本
	var mvp_validator = preload("res://scripts/test_mvp_validation.gd").new()
	add_child(mvp_validator)
	
	print("MVP验证已启动，请查看控制台输出...")
	print("====================")

func initialize_game_systems():
	"""初始化所有游戏系统"""
	var character_system = get_node_or_null("/root/CharacterSystem")
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	var encounter_system = get_node_or_null("/root/EncounterSystem")
	var economy_system = get_node_or_null("/root/EconomySystem")
	
	if character_system != null:
		character_system.initialize_character()
		character_system.add_experience(100)  # 给一点初始经验
	
	if equipment_system != null:
		print("装备系统就绪")
	
	if encounter_system != null:
		print("奇遇系统就绪")
	
	if economy_system != null:
		economy_system.add_silver(100)  # 给一点初始银两
		print("经济系统就绪")

func show_character_panel():
	"""显示角色面板"""
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager != null:
		ui_manager.switch_to_state(ui_manager.UIState.CHARACTER_PANEL)
	
	# 更新角色数据（通过UIManager）
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null:
		var character_data = {
			"level": character_system.level,
			"realm": character_system.get_current_realm()["name"],
			"attributes": character_system.attributes.get_total(),
			"attribute_points": character_system.total_attribute_points - character_system.allocated_attribute_points
		}
		
		# UIManager会自动调用角色面板的update_display函数
		ui_manager.update_character_panel()