# 武侠奇遇录 - UI管理器
# 负责管理所有UI界面的显示、切换和数据绑定

extends Node

# UI界面枚举
enum UIState {
	MAIN_MENU,        # 主菜单
	CHARACTER_PANEL,  # 角色面板
	EQUIPMENT_PANEL,  # 装备界面
	BACKPACK_PANEL,   # 背包界面
	COMBAT_INTERFACE, # 战斗界面
	ENCOUNTER_CARD,   # 奇遇事件卡片
	QUEST_LOG,        # 任务日志
	SETTINGS_MENU     # 设置菜单
}

# 当前UI状态
var current_state = UIState.MAIN_MENU

# UI组件引用
var character_panel = null
var equipment_panel = null
var backpack_panel = null
var combat_interface = null
var encounter_card = null

# 品阶颜色配置
var tier_colors = {
	"common": Color(1.0, 1.0, 1.0),    # 白色
	"rare": Color(0.0, 0.5, 1.0),      # 蓝色
	"epic": Color(0.6, 0.2, 0.8),      # 紫色
	"legendary": Color(1.0, 0.8, 0.0)  # 金色
}

# 状态指示颜色
var state_colors = {
	"can_equip_positive": Color(0.0, 1.0, 0.0),  # 绿色 - 可装备且属性提升
	"can_equip_negative": Color(1.0, 1.0, 0.0),  # 黄色 - 可装备但属性下降
	"cannot_equip": Color(1.0, 0.0, 0.0),       # 红色 - 不可装备
	"locked": Color(0.5, 0.5, 0.5)              # 灰色 - 槽位未解锁
}

func _ready():
	print("UI管理器初始化完成")
	setup_ui_components()

func setup_ui_components():
	"""设置UI组件引用"""
	# 这里应该获取各个UI组件的引用
	# 简化实现：暂时只打印信息
	print("设置UI组件引用")

func switch_to_state(new_state):
	"""切换到指定UI状态"""
	if new_state == current_state:
		return
	
	# 隐藏当前界面
	hide_current_state()
	
	# 显示新界面
	show_new_state(new_state)
	
	current_state = new_state
	print("切换到UI状态: %s" % get_state_name(new_state))

func hide_current_state():
	"""隐藏当前UI状态"""
	match current_state:
		UIState.CHARACTER_PANEL:
			if character_panel != null:
				character_panel.hide()
		UIState.EQUIPMENT_PANEL:
			if equipment_panel != null:
				equipment_panel.hide()
		UIState.BACKPACK_PANEL:
			if backpack_panel != null:
				backpack_panel.hide()
		UIState.COMBAT_INTERFACE:
			if combat_interface != null:
				combat_interface.hide()
		UIState.ENCOUNTER_CARD:
			if encounter_card != null:
				encounter_card.hide()

func show_new_state(new_state):
	"""显示新的UI状态"""
	match new_state:
		UIState.CHARACTER_PANEL:
			if character_panel != null:
				character_panel.show()
				update_character_panel()
		UIState.EQUIPMENT_PANEL:
			if equipment_panel != null:
				equipment_panel.show()
				update_equipment_panel()
		UIState.BACKPACK_PANEL:
			if backpack_panel != null:
				backpack_panel.show()
				update_backpack_panel()
		UIState.COMBAT_INTERFACE:
			if combat_interface != null:
				combat_interface.show()
				update_combat_interface()
		UIState.ENCOUNTER_CARD:
			if encounter_card != null:
				encounter_card.show()

func update_character_panel():
	"""更新角色面板数据"""
	# 获取角色数据
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system == null:
		push_warning("无法访问CharacterSystem")
		return
	var character_data = character_system.get_final_attributes()
	var combat_stats = character_system.get_combat_stats()
	
	# 更新UI显示
	if character_panel != null:
		character_panel.update_display({
			"level": character_system.level,
			"realm": character_system.get_current_realm()["name"],
			"attributes": character_data,
			"combat_stats": combat_stats,
			"attribute_points": character_system.total_attribute_points - character_system.allocated_attribute_points
		})

func update_equipment_panel():
	"""更新装备界面数据"""
	# 获取装备数据
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	if equipment_system == null:
		push_warning("无法访问EquipmentSystem")
		return
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system == null:
		push_warning("无法访问CharacterSystem")
		return
	var equipped_items = equipment_system.equipped_items
	var equipment_attributes = equipment_system.get_equipment_attributes()
	
	# 更新UI显示
	if equipment_panel != null:
		equipment_panel.update_display({
			"equipped_items": equipped_items,
			"equipment_attributes": equipment_attributes,
			"slot_unlock_status": get_slot_unlock_status(character_system.realm_index)
		})

func update_backpack_panel():
	"""更新背包界面数据"""
	# 这里应该获取背包物品数据
	# 简化实现：暂时只打印信息
	if backpack_panel != null:
		backpack_panel.update_display({
			"items": get_backpack_items(),
			"filters": {"tier": "all", "type": "all"},
			"sort_mode": "name"
		})

func update_combat_interface():
	"""更新战斗界面数据"""
	# 获取战斗数据
	var combat_system = get_node_or_null("/root/CombatSystem")
	if combat_system == null:
		push_warning("无法访问CombatSystem")
		return
	var player_characters = combat_system.player_characters
	var enemy_characters = combat_system.enemy_characters
	var turn_order = combat_system.turn_order
	
	# 更新UI显示
	if combat_interface != null:
		combat_interface.update_display({
			"players": player_characters,
			"enemies": enemy_characters,
			"turn_order": turn_order,
			"combo_count": combat_system.combo_count,
			"link_gauge": combat_system.link_gauge
		})

func get_slot_unlock_status(character_realm):
	"""获取槽位解锁状态"""
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	if equipment_system == null:
		push_warning("无法访问EquipmentSystem")
		return {}
	var slot_status = {}
	for slot in equipment_system.slot_unlock_realm:
		slot_status[slot] = character_realm >= equipment_system.slot_unlock_realm[slot]
	return slot_status

func get_backpack_items():
	"""获取背包物品列表"""
	# 这里应该从物品系统获取背包数据
	# 简化实现：返回空列表
	return []

func show_encounter_card(encounter_data):
	"""显示奇遇事件卡片"""
	switch_to_state(UIState.ENCOUNTER_CARD)
	if encounter_card != null:
		encounter_card.display_encounter(encounter_data)

func apply_tier_color(label, tier):
	"""应用品阶颜色到标签"""
	if tier_colors.has(tier):
		label.add_theme_color_override("font_color", tier_colors[tier])

func apply_state_color(control, state):
	"""应用状态颜色到控件"""
	if state_colors.has(state):
		control.add_theme_color_override("font_color", state_colors[state])

func get_state_name(state):
	"""获取UI状态名称"""
	match state:
		UIState.MAIN_MENU:
			return "主菜单"
		UIState.CHARACTER_PANEL:
			return "角色面板"
		UIState.EQUIPMENT_PANEL:
			return "装备界面"
		UIState.BACKPACK_PANEL:
			return "背包界面"
		UIState.COMBAT_INTERFACE:
			return "战斗界面"
		UIState.ENCOUNTER_CARD:
			return "奇遇事件卡片"
		UIState.QUEST_LOG:
			return "任务日志"
		UIState.SETTINGS_MENU:
			return "设置菜单"
		_:
			return "未知"

# 调试函数
func debug_print_ui_info():
	"""打印UI信息用于调试"""
	print("=== UI管理器信息 ===")
	print("当前状态: % s" % get_state_name(current_state))
	print("品阶颜色配置:")
	for tier in tier_colors:
		print("  %s: %s" % [tier, str(tier_colors[tier])])
	print("状态颜色配置:")
	for state in state_colors:
		print("  %s: %s" % [state, str(state_colors[state])])
	print("====================")

# UI回调函数
func _on_test_character_panel_pressed():
	"""测试角色面板按钮回调"""
	print("=== 角色面板测试 ===")
	
	# 初始化角色数据进行测试
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null:
		character_system.initialize_character()
		character_system.add_experience(1000)  # 升级到10级左右
		character_system.debug_print_character_info()
	
	# 更新角色面板
	update_character_panel()
	
	print("====================")

func _on_test_equipment_panel_pressed():
	"""测试装备界面按钮回调"""
	print("=== 装备界面测试 ===")
	
	# 装备一些测试物品
	var character_system = get_node_or_null("/root/CharacterSystem")
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	
	if character_system != null:
		character_system.level = 10
		character_system.realm_index = 1
	
	if equipment_system != null:
		equipment_system.equip_item("common_sword", 10, 1)
		equipment_system.equip_item("rare_helmet", 10, 1)
		equipment_system.equip_item("epic_ring", 10, 1)
		equipment_system.debug_print_equipment_info()
	
	# 更新装备界面
	update_equipment_panel()
	
	print("====================")

func _on_test_combat_interface_pressed():
	"""测试战斗界面按钮回调"""
	print("=== 战斗界面测试 ===")
	
	# 创建测试战斗数据
	var player_data = {
		"id": "player_main",
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
		"id": "test_bandit",
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
	var combat_system = get_node_or_null("/root/CombatSystem")
	if combat_system != null:
		combat_system.start_battle([player_data], [enemy_data])
		combat_system.debug_print_battle_info()
	
	# 更新战斗界面
	update_combat_interface()
	
	print("====================")

func _on_test_ui_colors_pressed():
	"""测试品阶颜色按钮回调"""
	print("=== 品阶颜色测试 ===")
	
	# 测试所有品阶颜色
	for tier in tier_colors:
		print("品阶 %s 颜色: %s" % [tier, str(tier_colors[tier])])
	
	# 测试所有状态颜色
	for state in state_colors:
		print("状态 %s 颜色: %s" % [state, str(state_colors[state])])
	
	print("====================")