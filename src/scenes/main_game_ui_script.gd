# 武侠奇遇录 - 主游戏UI脚本
# 负责管理主游戏界面和基本游戏功能

extends Node2D

func _ready():
	print("主游戏UI脚本初始化完成")

	# 连接主菜单信号
	var main_menu = get_node_or_null("MainMenu")
	if main_menu:
		main_menu.main_menu_new_game_selected.connect(_on_new_game_selected)

func _on_new_game_selected():
	# 显示 HUDLayer
	var hud_layer = get_node_or_null("HUDLayer")
	if hud_layer:
		hud_layer.visible = true

	# 初始化所有系统
	initialize_game_systems()

	# 连接暂停菜单返回主菜单信号
	var pause_menu = get_node_or_null("HUDLayer/PauseMenu")
	if pause_menu and pause_menu.has_signal("pause_menu_return_to_main"):
		if not pause_menu.pause_menu_return_to_main.is_connected(_on_return_to_main_menu):
			pause_menu.pause_menu_return_to_main.connect(_on_return_to_main_menu)

func initialize_game_systems():
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null:
		character_system.initialize_character()
		character_system.add_experience(100)

	# 初始化货币
	var currency_mgr = get_node_or_null("/root/CurrencyManager")
	if currency_mgr:
		currency_mgr.add_currency(currency_mgr.CurrencyType.SILVER, 100)
		print("经济系统就绪")

	# 初始化背包物品和装备
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		inv.add_item("common_sword", 1)
		inv.add_item("common_helmet", 1)
		inv.add_item("health_pill", 3)
		inv.add_item("spirit_stone_small", 5)
		inv.equip_item("common_sword", "weapon_main")
		inv.equip_item("common_helmet", "head")
		print("背包系统就绪: %d 种物品, %d 战力" % [inv.get_item_slot_count(), inv.get_equipment_power_score()])

	# 初始化武学系统
	var martial_arts = get_node_or_null("/root/MartialArtsSystem")
	if martial_arts:
		for ma_id in ["sword_basic_01", "fist_basic_01", "palm_basic_01"]:
			var ma_data = martial_arts.get_martial_art_data(ma_id)
			if ma_data:
				martial_arts.player_martial_arts[ma_id] = ma_data.duplicate(true)
		martial_arts.equip_martial_art("sword_basic_01", 0)
		martial_arts.equip_martial_art("fist_basic_01", 1)
		martial_arts.equip_martial_art("palm_basic_01", 2)
		print("武学系统就绪: %d 种武学已装备" % martial_arts.equipped_martial_arts.filter(func(x): return x != null).size())

	# 初始化幕次管理器
	var act_manager = get_node_or_null("/root/ActManager")
	if act_manager != null:
		print("[ActManager] 当前幕次: %s" % act_manager.get_current_act_title())

func _on_return_to_main_menu(_saved_before_exit: bool) -> void:
	get_tree().paused = false

	# 关闭暂停菜单
	var pause_menu = get_node_or_null("HUDLayer/PauseMenu")
	if pause_menu:
		pause_menu.visible = false

	# 隐藏 HUDLayer
	var hud_layer = get_node_or_null("HUDLayer")
	if hud_layer:
		hud_layer.visible = false

	# 显示主菜单
	var main_menu = get_node_or_null("MainMenu")
	if main_menu:
		main_menu.show_menu()

	# 重置 GameLoopManager
	var game_loop = get_node_or_null("/root/GameLoopManager")
	if game_loop:
		game_loop.return_to_menu()

	print("[主游戏UI] 已返回主菜单")
