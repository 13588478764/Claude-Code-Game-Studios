# 武侠奇遇录 - 主游戏UI脚本
# 负责管理主游戏界面和基本UI功能，包括快捷键绑定

extends Node2D

## UI场景引用
var _world_map_panel: Node = null
var _help_panel: Node = null
var _inventory_panel: Node = null
var _equipment_panel: Node = null
var _pause_menu_manager: Node = null

func _ready():
	print("主游戏UI脚本初始化完成")
	# 初始化角色系统
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null:
		character_system.initialize_character()

	# 动态加载并添加角色面板
	load_and_add_character_panel()

	# 动态加载Sprint 2 UI场景
	call_deferred("_load_ui_scenes")

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

## 延迟加载UI场景（确保AutoLoad就绪）
func _load_ui_scenes() -> void:
	_load_world_map()
	_load_help_panel()
	_load_inventory_panel()
	_load_equipment_panel()
	_load_pause_menu_manager()

## 加载大地图场景
func _load_world_map() -> void:
	var scene = load("res://src/scenes/ui/world_map.tscn")
	if scene != null:
		_world_map_panel = scene.instantiate()
		add_child(_world_map_panel)
		print("  - 大地图场景已加载")
	else:
		push_warning("无法加载大地图场景")

## 加载帮助面板
func _load_help_panel() -> void:
	var scene = load("res://src/scenes/ui/help_panel.tscn")
	if scene != null:
		_help_panel = scene.instantiate()
		add_child(_help_panel)
		print("  - 帮助面板已加载")
	else:
		push_warning("无法加载帮助面板")

## 加载背包面板
func _load_inventory_panel() -> void:
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	if scene != null:
		_inventory_panel = scene.instantiate()
		add_child(_inventory_panel)
		print("  - 背包面板已加载")
	else:
		push_warning("无法加载背包面板")

## 加载装备面板
func _load_equipment_panel() -> void:
	var scene = load("res://src/scenes/ui/equipment_panel.tscn")
	if scene != null:
		_equipment_panel = scene.instantiate()
		add_child(_equipment_panel)
		print("  - 装备面板已加载")
	else:
		push_warning("无法加载装备面板")

## 加载暂停菜单管理器
func _load_pause_menu_manager() -> void:
	# PauseMenuManager是AutoLoad，不需要手动加载实例
	_pause_menu_manager = get_node_or_null("/root/PauseMenuManager")
	if _pause_menu_manager != null:
		print("  - 暂停菜单管理器已连接")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_M:
				# 打开/关闭大地图
				if _world_map_panel != null:
					if _is_panel_open(_world_map_panel):
						_world_map_panel.close_map()
					else:
						_world_map_panel.open_map("keyboard")
					get_viewport().set_input_as_handled()
			KEY_F1:
				# 打开/关闭帮助面板
				if _help_panel != null:
					if _is_panel_open(_help_panel):
						_help_panel.close_panel()
					else:
						_help_panel.open_panel("f1_key")
					get_viewport().set_input_as_handled()
			KEY_I:
				# 打开/关闭背包面板
				if _inventory_panel != null:
					if _is_panel_open(_inventory_panel):
						_inventory_panel.close_panel()
					else:
						_inventory_panel.open_panel("keyboard")
					get_viewport().set_input_as_handled()
			KEY_E:
				# 打开/关闭装备面板
				if _equipment_panel != null:
					if _is_panel_open(_equipment_panel):
						_equipment_panel.close_panel()
					else:
						_equipment_panel.open_panel("keyboard")
					get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				# 暂停/继续游戏
				if _pause_menu_manager != null:
					if _pause_menu_manager._is_paused:
						_pause_menu_manager.close_pause_menu()
					else:
						_pause_menu_manager.open_pause_menu()
					get_viewport().set_input_as_handled()

## 检查面板是否打开
func _is_panel_open(panel: Node) -> bool:
	return panel.visible and panel.has_method("_is_open") and panel.get("_is_open")

func load_and_add_character_panel():
	"""动态加载角色面板场景"""
	var scene = load("res://src/scenes/ui/character_panel.tscn")
	if scene != null:
		var panel_instance = scene.instantiate()
		panel_instance.name = "CharacterPanelInstance"
		add_child(panel_instance)
	else:
		push_error("无法加载角色面板场景")

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
