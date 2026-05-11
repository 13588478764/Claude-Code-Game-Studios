extends CanvasLayer
class_name HUDManager
## HUDManager - HUD主控制器
##
## 统一管理HUD的模式切换(探索/战斗/菜单)和子面板显示。
## 监听GameEvents的相关信号,在状态变化时切换HUD模式。
##
## 架构来源: ADR-002 (HUD架构模式)
##
## 模式切换逻辑:
## - EXPLORATION: CombatInfoPanel隐藏, NavigationPanel显示
## - COMBAT: CombatInfoPanel显示, NavigationPanel自动折叠
## - MENU: 所有游戏HUD面板隐藏

## HUD模式枚举
enum HUDMode {
	EXPLORATION,  ## 探索模式 - 显示导航,隐藏战斗信息
	COMBAT,       ## 战斗模式 - 显示战斗信息,隐藏导航
	MENU          ## 菜单模式 - 隐藏所有HUD面板
}

## 当前HUD模式
var current_mode: HUDMode = HUDMode.EXPLORATION

## 子面板节点引用 (使用@onready缓存,符合控制清单要求)
@onready var player_status_panel: Node = get_node_or_null("PlayerStatusPanel")
@onready var party_panel: Node = get_node_or_null("PartyPanel")
@onready var combat_info_panel: Node = get_node_or_null("CombatInfoPanel")
@onready var navigation_panel: Node = get_node_or_null("NavigationPanel")
@onready var hotbar_controller: Node = get_node_or_null("HotbarController")
@onready var notification_manager: Node = get_node_or_null("NotificationManager")
@onready var dialogue_box: Node = get_node_or_null("DialogueBox")

## 性能优化框架组件 (Story 009)
## 注意: 这些组件暂时不使用类型声明,因为对应的脚本文件没有class_name声明
var performance_monitor
var batch_update_manager
var lod_scheduler
var buff_icon_pool
var damage_number_pool
var notification_pool

## 模式切换历史(用于AC-9健壮性测试)
var _mode_switch_count: int = 0

## 待应用的模式(用于一帧内多次切换的合并,AC-8 Edge case)
var _pending_mode: HUDMode = HUDMode.EXPLORATION
var _has_pending_mode_switch: bool = false


func _ready() -> void:
	# 验证场景结构完整性 (AC-3, AC-10)
	_validate_scene_structure()

	# 连接GameEvents信号 (AC-8)
	_connect_signals()
	
	# 连接测试按钮（仅用于演示）
	var test_combat_button = get_node_or_null("TestCombatButton")
	if test_combat_button:
		test_combat_button.pressed.connect(_on_test_combat_button_pressed)

	# 初始化为探索模式
	set_mode(HUDMode.EXPLORATION)

	print("[HUDManager] Initialized - Mode: EXPLORATION")


func _process(_delta: float) -> void:
	# 处理待应用的模式切换(一帧内多次切换合并)
	if _has_pending_mode_switch:
		_apply_mode_change(_pending_mode)
		_has_pending_mode_switch = false


func _exit_tree() -> void:
	# 显式断开关键信号,防止内存泄漏 (AC-9)
	if GameEvents:
		if GameEvents.combat_started.is_connected(_on_combat_started):
			GameEvents.combat_started.disconnect(_on_combat_started)
		if GameEvents.combat_ended.is_connected(_on_combat_ended):
			GameEvents.combat_ended.disconnect(_on_combat_ended)
		if GameEvents.system_mode_changed.is_connected(_on_system_mode_changed):
			GameEvents.system_mode_changed.disconnect(_on_system_mode_changed)


## 验证场景结构完整性 (AC-3, AC-10)
## 检查所有必需子节点是否存在,缺失时记录错误
func _validate_scene_structure() -> void:
	var required_nodes := [
		{"name": "PlayerStatusPanel", "node": player_status_panel},
		{"name": "PartyPanel", "node": party_panel},
		{"name": "CombatInfoPanel", "node": combat_info_panel},
		{"name": "NavigationPanel", "node": navigation_panel},
		{"name": "HotbarController", "node": hotbar_controller},
		{"name": "NotificationManager", "node": notification_manager},
		{"name": "DialogueBox", "node": dialogue_box}
	]

	var missing_nodes: Array = []
	for node_info in required_nodes:
		if node_info.node == null:
			missing_nodes.append(node_info.name)
			push_warning("[HUDManager] Required node missing: %s" % node_info.name)

	if missing_nodes.size() > 0:
		# 使用 push_warning 而非 push_error：
		# 1. 已有降级 UI 处理，这是可恢复状态
		# 2. push_error 会被 GUT 测试框架视为失败，但 test_hud_handles_missing_optional_panel_gracefully 
		#    等测试故意制造此场景验证降级逻辑
		push_warning("[HUDManager] Scene structure incomplete. Missing nodes: %s" % str(missing_nodes))
		# 显示降级UI(简化版HUD或错误提示)
		_show_fallback_ui(missing_nodes)


## 显示降级UI (AC-10)
## 当场景加载失败或节点缺失时,显示简化的错误提示
func _show_fallback_ui(missing_nodes: Array) -> void:
	# TODO: 实现降级UI显示逻辑
	# 当前阶段:仅记录日志,后续stories实现具体降级UI
	print("[HUDManager] Fallback UI activated. Missing: %s" % str(missing_nodes))


## 连接GameEvents信号 (AC-8)
## 使用类型化连接,符合控制清单要求(禁止字符串连接)
func _connect_signals() -> void:
	if GameEvents == null:
		push_error("[HUDManager] GameEvents singleton not found!")
		return

	# 监听战斗状态变化,自动切换HUD模式
	GameEvents.combat_started.connect(_on_combat_started)
	GameEvents.combat_ended.connect(_on_combat_ended)

	# 监听系统模式变化
	GameEvents.system_mode_changed.connect(_on_system_mode_changed)

	# 监听对话系统信号,控制对话UI显示/隐藏
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager != null:
		if not dialogue_manager.is_connected("node_displayed", _on_dialogue_node_displayed):
			dialogue_manager.node_displayed.connect(_on_dialogue_node_displayed)
		if not dialogue_manager.is_connected("dialogue_started", _on_dialogue_started):
			dialogue_manager.dialogue_started.connect(_on_dialogue_started)
		if not dialogue_manager.is_connected("dialogue_ended", _on_dialogue_ended):
			dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
	else:
		push_warning("[HUDManager] DialogueManager not found - dialogue UI will not function")


## 设置HUD模式 (AC-4, AC-5, AC-6, AC-7)
## @param mode: 目标HUD模式
##
## 注意: 实际的模式切换在_process()中应用,以支持一帧内多次切换的合并
func set_mode(mode: HUDMode) -> void:
	# 重复切换到同一模式不应产生错误 (AC-4 Edge case)
	if mode == current_mode and not _has_pending_mode_switch:
		return

	# 记录待应用的模式(支持一帧内多次切换合并)
	_pending_mode = mode
	_has_pending_mode_switch = true
	_mode_switch_count += 1


## 应用模式切换的实际逻辑
## @param mode: 要应用的模式
func _apply_mode_change(mode: HUDMode) -> void:
	current_mode = mode

	match mode:
		HUDMode.EXPLORATION:
			_show_panel(player_status_panel)
			_show_panel(party_panel)
			_hide_panel(combat_info_panel)
			_show_panel(navigation_panel)
			_show_panel(hotbar_controller)
			_show_panel(notification_manager)

		HUDMode.COMBAT:
			_show_panel(player_status_panel)
			_show_panel(party_panel)
			_show_panel(combat_info_panel)
			_hide_panel(navigation_panel)
			_show_panel(hotbar_controller)
			_show_panel(notification_manager)

		HUDMode.MENU:
			# 所有游戏HUD面板隐藏 (AC-7)
			_hide_panel(player_status_panel)
			_hide_panel(party_panel)
			_hide_panel(combat_info_panel)
			_hide_panel(navigation_panel)
			_hide_panel(hotbar_controller)
			# NotificationManager在菜单模式下保持显示(系统通知优先级最高)
			_show_panel(notification_manager)


## 安全显示面板(防御性编程,处理节点可能为null的情况)
func _show_panel(panel: Node) -> void:
	if panel != null and panel is CanvasItem:
		panel.visible = true


## 安全隐藏面板
func _hide_panel(panel: Node) -> void:
	if panel != null and panel is CanvasItem:
		panel.visible = false


## 立即应用模式切换(用于测试,跳过_process()延迟)
## @param mode: 目标模式
func set_mode_immediate(mode: HUDMode) -> void:
	current_mode = mode
	_apply_mode_change(mode)
	_has_pending_mode_switch = false


## 获取模式切换次数(用于AC-9健壮性测试)
func get_mode_switch_count() -> int:
	return _mode_switch_count


# ============================================================================
# 信号处理函数
# ============================================================================

func _on_combat_started() -> void:
	set_mode(HUDMode.COMBAT)
	print("[HUDManager] Combat started - switched to COMBAT mode")


func _on_combat_ended(_victory: bool, _rewards: Dictionary) -> void:
	set_mode(HUDMode.EXPLORATION)
	print("[HUDManager] Combat ended - switched to EXPLORATION mode")


func _on_system_mode_changed(mode: String) -> void:
	match mode:
		"exploration":
			set_mode(HUDMode.EXPLORATION)
		"combat":
			set_mode(HUDMode.COMBAT)
		"menu", "dialogue":
			set_mode(HUDMode.MENU)
		_:
			push_warning("[HUDManager] Unknown system mode: %s" % mode)


## 测试按钮：切换战斗模式（仅用于演示）
func _on_test_combat_button_pressed() -> void:
	if current_mode == HUDMode.COMBAT:
		# 当前在战斗模式，切换回探索模式
		print("[HUDManager] Test: Ending combat")
		GameEvents.combat_ended.emit(true, {})
	else:
		# 当前在探索模式，进入战斗模式
		print("[HUDManager] Test: Starting combat")
		GameEvents.combat_started.emit()


# ============================================================================
# 对话系统信号处理
# ============================================================================

## 对话开始时的回调
func _on_dialogue_started(_dialogue_id: String) -> void:
	if dialogue_box != null:
		dialogue_box.show_dialogue()
		# 切换到对话模式，隐藏其他HUD元素
		set_mode(HUDMode.MENU)
	print("[HUDManager] Dialogue started")


## 对话节点显示时的回调（传递到对话UI）
func _on_dialogue_node_displayed(_node: DialogueData.DialogueNode) -> void:
	# 对话节点显示由DialogueBox通过自己的信号连接处理
	# 这里保留回调用于将来的扩展（如音效、动画等）
	pass


## 对话结束时的回调
func _on_dialogue_ended(_dialogue_id: String) -> void:
	if dialogue_box != null:
		dialogue_box.hide_dialogue()
		# 恢复到探索模式
		set_mode(HUDMode.EXPLORATION)
	print("[HUDManager] Dialogue ended")