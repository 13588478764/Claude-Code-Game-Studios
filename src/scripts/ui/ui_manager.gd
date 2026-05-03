## 武侠奇遇录 - UI管理器
## 负责管理所有UI界面的显示、切换和数据绑定
##
## 主要功能：
## - UI状态管理和切换
## - UI组件引用管理
## - 数据绑定和更新
## - 颜色配置管理

extends Node

class_name UiManager

# ============================================================================
# 常量定义
# ============================================================================

const CHARACTER_SYSTEM_PATH: String = "/root/CharacterSystem"
const EQUIPMENT_SYSTEM_PATH: String = "/root/EquipmentSystem"
const COMBAT_SYSTEM_PATH: String = "/root/CombatSystem"

const TIER_COLOR_COMMON: Color = Color(1.0, 1.0, 1.0)      # 白色
const TIER_COLOR_RARE: Color = Color(0.0, 0.5, 1.0)        # 蓝色
const TIER_COLOR_EPIC: Color = Color(0.6, 0.2, 0.8)        # 紫色
const TIER_COLOR_LEGENDARY: Color = Color(1.0, 0.8, 0.0)   # 金色

const STATE_COLOR_POSITIVE: Color = Color(0.0, 1.0, 0.0)   # 绿色
const STATE_COLOR_NEGATIVE: Color = Color(1.0, 1.0, 0.0)   # 黄色
const STATE_COLOR_CANNOT_EQUIP: Color = Color(1.0, 0.0, 0.0) # 红色
const STATE_COLOR_LOCKED: Color = Color(0.5, 0.5, 0.5)     # 灰色

# ============================================================================
# 信号定义
# ============================================================================

## UI状态改变信号
signal ui_state_changed(new_state: int)

## UI更新完成信号
signal ui_updated(panel_name: String)

# ============================================================================
# 成员变量
# ============================================================================

## UI界面枚举
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

## 当前UI状态
var current_state: int = UIState.MAIN_MENU

## UI组件引用
var character_panel: Node = null          # Control root for show()/hide()
var character_panel_script: Node = null   # Script node for update_display()
var equipment_panel: Node = null
var backpack_panel: Node = null
var combat_interface: Node = null
var encounter_card: Node = null

## 品阶颜色配置
var tier_colors: Dictionary = {
	"common": TIER_COLOR_COMMON,
	"rare": TIER_COLOR_RARE,
	"epic": TIER_COLOR_EPIC,
	"legendary": TIER_COLOR_LEGENDARY
}

## 状态指示颜色
var state_colors: Dictionary = {
	"can_equip_positive": STATE_COLOR_POSITIVE,
	"can_equip_negative": STATE_COLOR_NEGATIVE,
	"cannot_equip": STATE_COLOR_CANNOT_EQUIP,
	"locked": STATE_COLOR_LOCKED
}

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化UI管理器
func _ready() -> void:
	print("UI管理器初始化完成")
	_setup_ui_components()

# ============================================================================
# 公共方法
# ============================================================================

## 设置UI组件引用
func _setup_ui_components() -> void:
	print("设置UI组件引用")
	# CharacterPanelInstance is added dynamically by main_game_ui_script
	# Use deferred to find it after both scenes are ready
	call_deferred("_deferred_setup_character_panel")

## 切换到指定UI状态
func switch_to_state(new_state: int) -> void:
	if new_state == current_state:
		return
	
	_hide_current_state()
	_show_new_state(new_state)
	
	current_state = new_state
	ui_state_changed.emit(new_state)
	print("切换到UI状态: %s" % _get_state_name(new_state))

## 显示奇遇事件卡片
func show_encounter_card(encounter_data: Dictionary) -> void:
	switch_to_state(UIState.ENCOUNTER_CARD)
	if encounter_card != null:
		encounter_card.display_encounter(encounter_data)

## 应用品阶颜色到标签
func apply_tier_color(label: Label, tier: String) -> void:
	if tier_colors.has(tier):
		label.add_theme_color_override("font_color", tier_colors[tier])
	else:
		push_warning("未知的品阶: %s" % tier)

## 应用状态颜色到控件
func apply_state_color(control: Control, state: String) -> void:
	if state_colors.has(state):
		control.add_theme_color_override("font_color", state_colors[state])
	else:
		push_warning("未知的状态: %s" % state)

## 获取UI状态名称
func get_state_name(state: int) -> String:
	return _get_state_name(state)

## 打印UI信息用于调试
func debug_print_ui_info() -> void:
	print("=== UI管理器信息 ===")
	print("当前状态: %s" % _get_state_name(current_state))
	print("品阶颜色配置:")
	for tier in tier_colors:
		print("  %s: %s" % [tier, str(tier_colors[tier])])
	print("状态颜色配置:")
	for state in state_colors:
		print("  %s: %s" % [state, str(state_colors[state])])
	print("====================")

# ============================================================================
# 私有方法
# ============================================================================

## 延迟查找角色面板（确保场景实例化完成）
func _deferred_setup_character_panel() -> void:
	var main_ui = get_parent()
	var panel_wrapper = main_ui.get_node_or_null("CharacterPanelInstance")
	if panel_wrapper == null:
		push_warning("CharacterPanelInstance 节点未找到")
		return
	
	# CharacterPanelInstance is a Control (root of the instanced scene)
	# We store a reference to it for show()/hide()
	character_panel = panel_wrapper
	
	# Also get the script child node for update_display()
	for child in panel_wrapper.get_children():
		if child.name == "CharacterPanelScript":
			character_panel_script = child
			break
	
	print("  - 角色面板已绑定: ", character_panel.name)

## 隐藏当前UI状态
func _hide_current_state() -> void:
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

## 显示新的UI状态
func _show_new_state(new_state: int) -> void:
	match new_state:
		UIState.CHARACTER_PANEL:
			if character_panel != null:
				character_panel.show()
				_update_character_panel()
		UIState.EQUIPMENT_PANEL:
			if equipment_panel != null:
				equipment_panel.show()
				_update_equipment_panel()
		UIState.BACKPACK_PANEL:
			if backpack_panel != null:
				backpack_panel.show()
				_update_backpack_panel()
		UIState.COMBAT_INTERFACE:
			if combat_interface != null:
				combat_interface.show()
				_update_combat_interface()
		UIState.ENCOUNTER_CARD:
			if encounter_card != null:
				encounter_card.show()

## 更新角色面板数据
func _update_character_panel() -> void:
	var character_system: Node = get_node_or_null(CHARACTER_SYSTEM_PATH)
	if character_system == null:
		push_error("无法访问CharacterSystem")
		return
	
	if character_panel == null or character_panel_script == null:
		push_warning("角色面板未初始化")
		return
	
	var character_data = character_system.get_final_attributes()
	var combat_stats = character_system.get_combat_stats()
	
	character_panel_script.update_display({
		"level": character_system.level,
		"realm": character_system.get_current_realm()["name"],
		"attributes": character_data,
		"combat_stats": combat_stats,
		"attribute_points": character_system.total_attribute_points - character_system.allocated_attribute_points
	})
	
	ui_updated.emit("character_panel")

## 更新装备界面数据
func _update_equipment_panel() -> void:
	var equipment_system: Node = get_node_or_null(EQUIPMENT_SYSTEM_PATH)
	var character_system: Node = get_node_or_null(CHARACTER_SYSTEM_PATH)
	
	if equipment_system == null or character_system == null:
		push_error("无法访问装备系统或角色系统")
		return
	
	if equipment_panel == null:
		push_warning("装备面板未初始化")
		return
	
	var equipped_items: Dictionary = equipment_system.equipped_items
	var equipment_attributes: Dictionary = equipment_system.get_equipment_attributes()
	
	equipment_panel.update_display({
		"equipped_items": equipped_items,
		"equipment_attributes": equipment_attributes,
		"slot_unlock_status": _get_slot_unlock_status(character_system.realm_index)
	})
	
	ui_updated.emit("equipment_panel")

## 更新背包界面数据
func _update_backpack_panel() -> void:
	if backpack_panel == null:
		push_warning("背包面板未初始化")
		return
	
	backpack_panel.update_display({
		"items": _get_backpack_items(),
		"filters": {"tier": "all", "type": "all"},
		"sort_mode": "name"
	})
	
	ui_updated.emit("backpack_panel")

## 更新战斗界面数据
func _update_combat_interface() -> void:
	var combat_system: Node = get_node_or_null(COMBAT_SYSTEM_PATH)
	if combat_system == null:
		push_error("无法访问CombatSystem")
		return
	
	if combat_interface == null:
		push_warning("战斗界面未初始化")
		return
	
	var player_characters: Array = combat_system.player_characters
	var enemy_characters: Array = combat_system.enemy_characters
	var turn_order: Array = combat_system.turn_order
	
	combat_interface.update_display({
		"players": player_characters,
		"enemies": enemy_characters,
		"turn_order": turn_order,
		"combo_count": combat_system.combo_count,
		"link_gauge": combat_system.link_gauge
	})
	
	ui_updated.emit("combat_interface")

## 获取槽位解锁状态
func _get_slot_unlock_status(character_realm: int) -> Dictionary:
	var equipment_system: Node = get_node_or_null(EQUIPMENT_SYSTEM_PATH)
	if equipment_system == null:
		push_error("无法访问EquipmentSystem")
		return {}
	
	var slot_status: Dictionary = {}
	for slot in equipment_system.slot_unlock_realm:
		slot_status[slot] = character_realm >= equipment_system.slot_unlock_realm[slot]
	return slot_status

## 获取背包物品列表
func _get_backpack_items() -> Array:
	return []

## 获取UI状态名称
func _get_state_name(state: int) -> String:
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

# ============================================================================
# UI回调函数
# ============================================================================

## 测试角色面板按钮回调
func _on_test_character_panel_pressed() -> void:
	print("=== 角色面板测试 ===")
	
	var character_system: Node = get_node_or_null(CHARACTER_SYSTEM_PATH)
	if character_system != null:
		character_system.initialize_character()
		character_system.add_experience(1000)
		character_system.debug_print_character_info()
	
	_update_character_panel()
	print("====================")

## 测试装备界面按钮回调
func _on_test_equipment_panel_pressed() -> void:
	print("=== 装备界面测试 ===")
	
	var character_system: Node = get_node_or_null(CHARACTER_SYSTEM_PATH)
	var equipment_system: Node = get_node_or_null(EQUIPMENT_SYSTEM_PATH)
	
	if character_system != null:
		character_system.level = 10
		character_system.realm_index = 1
	
	if equipment_system != null:
		equipment_system.equip_item("common_sword", 10, 1)
		equipment_system.equip_item("rare_helmet", 10, 1)
		equipment_system.equip_item("epic_ring", 10, 1)
		equipment_system.debug_print_equipment_info()
	
	_update_equipment_panel()
	print("====================")

## 测试战斗界面按钮回调
func _on_test_combat_interface_pressed() -> void:
	print("=== 战斗界面测试 ===")
	
	var player_data: Dictionary = {
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
	
	var enemy_data: Dictionary = {
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
	
	var combat_system: Node = get_node_or_null(COMBAT_SYSTEM_PATH)
	if combat_system != null:
		combat_system.start_battle([player_data], [enemy_data])
		combat_system.debug_print_battle_info()
	
	_update_combat_interface()
	print("====================")

## 测试品阶颜色按钮回调
func _on_test_ui_colors_pressed() -> void:
	print("=== 品阶颜色测试 ===")
	
	for tier in tier_colors:
		print("品阶 %s 颜色: %s" % [tier, str(tier_colors[tier])])
	
	for state in state_colors:
		print("状态 %s 颜色: %s" % [state, str(state_colors[state])])
	
	print("====================")
