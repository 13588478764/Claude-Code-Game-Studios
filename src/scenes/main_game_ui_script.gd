# 武侠奇遇录 - 主游戏UI脚本
# 负责管理主游戏界面和基本游戏功能

extends Node2D

func _ready():
	print("主游戏UI脚本初始化完成")
	# 初始化角色系统
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null:
		character_system.initialize_character()
	
	# 动态加载并添加角色面板
	load_and_add_character_panel()
	
	# 手动连接按钮信号
	var start_button = get_node("StartNewGameButton")
	if start_button != null:
		print("  - 开始新游戏按钮已连接")
		if not start_button.pressed.is_connected(_on_start_new_game_pressed):
			start_button.pressed.connect(_on_start_new_game_pressed)
	else:
		push_warning("StartNewGameButton 节点未找到")
	
	var load_button = get_node("LoadGameButton")
	if load_button != null:
		if not load_button.pressed.is_connected(_on_load_game_pressed):
			load_button.pressed.connect(_on_load_game_pressed)
	
	var test_button = get_node("TestAllSystemsButton")
	if test_button != null:
		if not test_button.pressed.is_connected(_on_test_all_systems_pressed):
			test_button.pressed.connect(_on_test_all_systems_pressed)

func load_and_add_character_panel():
	"""动态加载角色面板场景。
	
	预加载面板节点以便后续 UIManager.switch_to_state(CHARACTER_PANEL) 可以立即 show()，
	但启动时必须显式 hide()，否则主菜单上会盖着角色信息面板。
	（character_panel.tscn 根节点是 Control，默认 visible=true。）
	"""
	var scene = load("res://src/scenes/ui/character_panel.tscn")
	if scene != null:
		var panel_instance = scene.instantiate()
		panel_instance.name = "CharacterPanelInstance"
		add_child(panel_instance)
		# 关键：启动时隐藏，由 show_character_panel() 在玩家点击"开始新游戏"时显示
		panel_instance.visible = false
	else:
		push_error("无法加载角色面板场景")

func _on_start_new_game_pressed():
	"""开始新游戏按钮回调"""
	print("=== 开始新游戏 ===")

	# 隐藏主菜单元素
	_hide_node("GameTitleLabel")
	_hide_node("WelcomeLabel")
	_hide_node("StartNewGameButton")
	_hide_node("LoadGameButton")
	_hide_node("MainMenuPanel")

	# 显示 HUDLayer
	var hud_layer = get_node_or_null("HUDLayer")
	if hud_layer:
		hud_layer.visible = true

	# 初始化所有系统
	initialize_game_systems()

	# 通知 GameLoopManager 进入探索状态
	var game_loop = get_node_or_null("/root/GameLoopManager")
	if game_loop:
		game_loop.enter_exploration()
	else:
		push_warning("[主游戏UI] GameLoopManager 未找到，回退到角色面板")
		show_character_panel()

	print("新游戏已开始！")
	print("====================")

func _hide_node(node_name: String) -> void:
	var node = get_node_or_null(node_name)
	if node:
		node.visible = false

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
	var mvp_validator = preload("res://src/scripts/test_mvp_validation.gd").new()
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
	
	# 初始化幕次管理器
	var act_manager = get_node_or_null("/root/ActManager")
	if act_manager != null:
		print("[ActManager] 当前幕次: %s" % act_manager.get_current_act_title())
	
	# 触发开场对话
	call_deferred("_trigger_opening_dialogue")

func _trigger_opening_dialogue():
	"""触发开场对话（Act 1 事件一）"""
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager == null:
		push_warning("[主游戏UI] DialogueManager未找到")
		return
	
	# 连接对话结束信号
	if not dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
	
	# 检查对话是否存在
	if dialogue_manager.has_dialogue("ACT1_OPENING_001"):
		print("[主游戏UI] 触发开场对话...")
		dialogue_manager.start_dialogue("ACT1_OPENING_001")
		
		# 注册NPC个人线触发条件
		var quest_trigger = get_node_or_null("/root/QuestTriggerManager")
		if quest_trigger != null:
			quest_trigger.register_all_npc_questlines()
		
		# 初始化Act 1状态
		var act_manager = get_node_or_null("/root/ActManager")
		if act_manager != null:
			act_manager.trigger_event("act_1", "act1_event1_opening")
	else:
		push_warning("[主游戏UI] 开场对话不存在: ACT1_OPENING_001")

func _on_dialogue_ended(dialogue_id: String) -> void:
	"""对话结束回调，处理幕次过渡"""
	print("[主游戏UI] 对话结束: %s" % dialogue_id)
	
	var act_manager = get_node_or_null("/root/ActManager")
	if act_manager == null:
		return
	
	# Act 1 事件完成标记
	if dialogue_id == "ACT6_RESOLUTION_001":
		act_manager.complete_event("act1_event6_resolution")
		act_manager.complete_event("act1_event5_ruins")
		act_manager.complete_event("act1_event4_boss")
		act_manager.complete_event("act1_event3_crisis")
		act_manager.complete_event("act1_event2_cultivation")
		act_manager.complete_event("act1_event1_opening")
		
		# 自动过渡到 Act 2
		print("[主游戏UI] 触发 Act 1 → Act 2 过渡...")
		act_manager.transition_act1_to_act2()
		
		# 加载 Act 2 开场对话
		var dialogue_manager = get_node_or_null("/root/DialogueManager")
		if dialogue_manager != null and dialogue_manager.has_dialogue("ACT2_EVENT1_RETURN"):
			print("[主游戏UI] 触发 Act 2 开场对话...")
			await get_tree().create_timer(1.0).timeout
			dialogue_manager.start_dialogue("ACT2_EVENT1_RETURN")
			act_manager.trigger_event("act_2", "act2_event1_return")

func show_character_panel():
	"""显示角色面板"""
	# UIManager 是 main_game_ui.tscn 的子节点，不是 Autoload
	var ui_manager = get_node_or_null("UIManager")
	if ui_manager == null:
		push_warning("UIManager not found as child node")
		return
	
	# switch_to_state 会自动调用 _update_character_panel() 更新数据
	ui_manager.switch_to_state(ui_manager.UIState.CHARACTER_PANEL)
