## ExplorationPanel
## 简易探索面板
##
## MVP 探索界面：显示区域选择、角色状态、探索按钮。
## 通过 GameLoopManager 驱动游戏循环。

extends CanvasLayer

# ============================================================================
# 节点引用
# ============================================================================

@onready var region_name_label: Label = $PanelContainer/VBox/HeaderBox/RegionNameLabel
@onready var region_level_label: Label = $PanelContainer/VBox/HeaderBox/RegionLevelLabel
@onready var player_level_label: Label = $PanelContainer/VBox/StatusBox/PlayerLevelLabel
@onready var player_exp_label: Label = $PanelContainer/VBox/StatusBox/PlayerExpLabel
@onready var player_realm_label: Label = $PanelContainer/VBox/StatusBox/PlayerRealmLabel
@onready var player_silver_label: Label = $PanelContainer/VBox/StatusBox/PlayerSilverLabel
@onready var explore_button: Button = $PanelContainer/VBox/ActionBox/ExploreButton
@onready var region_list: VBoxContainer = $PanelContainer/VBox/RegionBox/RegionList
@onready var log_label: Label = $PanelContainer/VBox/LogBox/LogLabel

var _game_loop: Node = null

# ============================================================================
# 生命周期
# ============================================================================

func _ready() -> void:
	layer = 100
	call_deferred("_initialize")


func _initialize() -> void:
	_game_loop = get_node_or_null("/root/GameLoopManager")
	if _game_loop == null:
		push_warning("[ExplorationPanel] GameLoopManager 未找到")
		return

	explore_button.pressed.connect(_on_explore_pressed)
	_game_loop.exploration_result.connect(_on_exploration_result)
	_game_loop.battle_log_updated.connect(_on_battle_log)
	_game_loop.game_state_changed.connect(_on_game_state_changed)

	var encounter_ui = get_node_or_null("/root/MainGameUI/HUDLayer/EncounterUI")
	if encounter_ui:
		encounter_ui.visibility_changed.connect(_on_encounter_ui_visibility_changed.bind(encounter_ui))

	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		dialogue_manager.dialogue_started.connect(_on_dialogue_started)
		dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)

	_build_region_buttons()
	_refresh_display()

# ============================================================================
# UI 构建
# ============================================================================

func _build_region_buttons() -> void:
	if _game_loop == null:
		return

	for child in region_list.get_children():
		child.queue_free()

	for i in range(_game_loop.REGIONS.size()):
		var region: Dictionary = _game_loop.REGIONS[i]
		var btn := Button.new()
		btn.text = "%s (Lv.%d)" % [region.name, region.level]
		btn.custom_minimum_size = Vector2(200, 36)
		var idx := i
		btn.pressed.connect(func(): _on_region_selected(idx))
		region_list.add_child(btn)

# ============================================================================
# 事件处理
# ============================================================================

func _on_explore_pressed() -> void:
	if _game_loop == null:
		return
	log_label.text = "探索中..."
	_game_loop.do_explore_action()


func _on_region_selected(index: int) -> void:
	if _game_loop == null:
		return
	_game_loop.select_region(index)
	_refresh_display()


func _on_exploration_result(result_text: String) -> void:
	log_label.text = result_text
	_refresh_display()


func _on_battle_log(message: String) -> void:
	log_label.text = message


func _on_dialogue_started(_dialogue_id: String) -> void:
	hide()


func _on_dialogue_ended(_dialogue_id: String) -> void:
	if _game_loop and _game_loop.current_state == 1:  # EXPLORING
		show()
		_refresh_display()


func _on_encounter_ui_visibility_changed(encounter_ui: Control) -> void:
	if encounter_ui.visible:
		hide()
	elif _game_loop and _game_loop.current_state == 1:  # EXPLORING
		show()
		_refresh_display()


func _on_game_state_changed(new_state: int) -> void:
	# 0=MENU, 1=EXPLORING, 2=IN_COMBAT, 3=COMBAT_RESULT
	match new_state:
		1:  # EXPLORING
			show()
			_refresh_display()
		_:
			hide()

# ============================================================================
# 刷新显示
# ============================================================================

func _refresh_display() -> void:
	if _game_loop == null:
		return

	var region: Dictionary = _game_loop.current_region
	region_name_label.text = region.get("name", "未知区域")
	region_level_label.text = "推荐等级: %d" % region.get("level", 1)

	var summary: Dictionary = _game_loop.get_player_summary()
	player_level_label.text = "等级: %d" % summary.get("level", 1)
	player_exp_label.text = "经验: %d / %d" % [summary.get("exp", 0), summary.get("exp_next", 100)]
	player_realm_label.text = "境界: %s" % summary.get("realm", "炼气")
	player_silver_label.text = "银两: %d" % summary.get("silver", 0)
