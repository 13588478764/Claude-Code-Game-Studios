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
var _npc_container: VBoxContainer = null

## 核心NPC列表（RelationshipManager._npc_database 降级后备）
var NPC_FALLBACK: Array = []

# ============================================================================
# 面板管理
# ============================================================================

## 快捷键到面板键名的映射
var HOTKEY_MAP: Dictionary = {}

## 面板节点引用
var _panels: Dictionary = {}

## 当前打开的面板键名（"" = 无面板打开）
var _active_panel_key: String = ""

# ============================================================================
# 生命周期
# ============================================================================

func _ready() -> void:
	layer = 100
	HOTKEY_MAP = {
		KEY_ESCAPE: "pause",
		KEY_I: "inventory",
		KEY_E: "equipment",
		KEY_M: "world_map",
		KEY_F1: "help",
		KEY_C: "character",
		KEY_J: "quest_log",
		KEY_R: "relationship",
	}
	NPC_FALLBACK = [
		{"id": "yunzhonghe", "name": "云中鹤", "sect": "青云门"},
		{"id": "liuruyan", "name": "柳如烟", "sect": "翠微宫"},
		{"id": "xuanjizhenren", "name": "玄机真人", "sect": "天机阁"},
		{"id": "xiaohanye", "name": "萧寒夜", "sect": "万魔宗"},
		{"id": "xuewuhen", "name": "血无痕", "sect": "血刹教"},
		{"id": "murongxue", "name": "慕容雪", "sect": "无门无派"},
	]
	call_deferred("_initialize")


func _initialize() -> void:
	_game_loop = get_node_or_null("/root/GameLoopManager")
	if _game_loop == null:
		push_warning("[ExplorationPanel] GameLoopManager 未找到")
		return

	print("[ExplorationPanel] 初始化成功，GameLoopManager 已找到")
	explore_button.pressed.connect(_on_explore_pressed)
	_game_loop.exploration_result.connect(_on_exploration_result)
	_game_loop.battle_log_updated.connect(_on_battle_log)
	_game_loop.game_state_changed.connect(_on_game_state_changed)

	var encounter_ui = get_node_or_null("/root/EncounterUI")
	if encounter_ui:
		encounter_ui.visibility_changed.connect(_on_encounter_ui_visibility_changed.bind(encounter_ui))

	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		dialogue_manager.dialogue_started.connect(_on_dialogue_started)
		dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)

	_init_panels()
	_build_region_buttons()
	_build_npc_buttons()
	_refresh_display()

# ============================================================================
# 面板初始化
# ============================================================================

func _init_panels() -> void:
	var root: Node = get_tree().root
	_panels["pause"] = root.get_node_or_null("PauseMenu")
	_panels["inventory"] = root.get_node_or_null("InventoryPanel")
	_panels["equipment"] = root.get_node_or_null("EquipmentPanel")
	_panels["world_map"] = root.get_node_or_null("WorldMap")
	_panels["help"] = root.get_node_or_null("HelpPanel")
	_panels["quest_log"] = root.get_node_or_null("QuestLogPanel")
	_panels["relationship"] = root.get_node_or_null("RelationshipPanel")
	_panels["character"] = root.get_node_or_null("CharacterGrowthUI")

	_connect_panel_close_signals()

	var found := _panels.values().filter(func(p): return p != null).size()
	print("[ExplorationPanel] 面板初始化: %d/%d" % [found, _panels.size()])


func _connect_panel_close_signals() -> void:
	var pause = _panels.get("pause")
	if pause and pause.has_signal("pause_menu_closed_continue"):
		pause.pause_menu_closed_continue.connect(func(): _on_panel_closed())

	var inventory = _panels.get("inventory")
	if inventory and inventory.has_signal("inventory_panel_closed"):
		inventory.inventory_panel_closed.connect(func(): _on_panel_closed())

	var equipment = _panels.get("equipment")
	if equipment and equipment.has_signal("equipment_panel_closed"):
		equipment.equipment_panel_closed.connect(func(_a, _b, _c): _on_panel_closed())

	var world_map = _panels.get("world_map")
	if world_map and world_map.has_signal("world_map_closed"):
		world_map.world_map_closed.connect(func(_a, _b): _on_panel_closed())

	var help = _panels.get("help")
	if help and help.has_signal("help_panel_closed"):
		help.help_panel_closed.connect(func(_a, _b): _on_panel_closed())

	var quest_log = _panels.get("quest_log")
	if quest_log and quest_log.has_signal("quest_log_closed"):
		quest_log.quest_log_closed.connect(func(): _on_panel_closed())

	var relationship = _panels.get("relationship")
	if relationship and relationship.has_signal("relationship_panel_closed"):
		relationship.relationship_panel_closed.connect(func(): _on_panel_closed())

	var character = _panels.get("character")
	if character and character is CanvasItem:
		character.visibility_changed.connect(func():
			if not character.visible and _active_panel_key == "character":
				_on_panel_closed()
		)


# ============================================================================
# 快捷键处理
# ============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	if _game_loop == null or _game_loop.current_state != 1:
		return

	var dialogue_box = get_node_or_null("/root/DialogueBox")
	if dialogue_box and dialogue_box.visible:
		return
	var encounter_ui_node = get_node_or_null("/root/EncounterUI")
	if encounter_ui_node and encounter_ui_node.visible:
		return

	var key = event.keycode
	if not HOTKEY_MAP.has(key):
		return

	var panel_key: String = HOTKEY_MAP[key]
	_toggle_panel(panel_key)
	get_viewport().set_input_as_handled()


func _toggle_panel(panel_key: String) -> void:
	if _active_panel_key == panel_key:
		_close_active_panel()
		return

	if _active_panel_key != "":
		_close_active_panel()

	_open_panel(panel_key)


func _open_panel(panel_key: String) -> void:
	var panel = _panels.get(panel_key)
	if panel == null:
		return

	_active_panel_key = panel_key
	visible = false

	match panel_key:
		"pause":
			panel.open_menu()
		"inventory":
			panel.open_panel()
		"equipment":
			panel.open_panel()
		"world_map":
			panel.open_map()
		"help":
			panel.open_panel()
		"quest_log":
			panel.open_panel()
		"relationship":
			panel.open_panel()
		"character":
			panel.visible = true


func _close_active_panel() -> void:
	if _active_panel_key == "":
		return

	var key := _active_panel_key
	var panel = _panels.get(key)
	_active_panel_key = ""

	if panel == null:
		visible = true
		_refresh_display()
		return

	match key:
		"pause":
			panel.close_menu()
		"inventory":
			panel.close_panel()
		"equipment":
			panel.close_panel()
		"world_map":
			panel.close_map()
		"help":
			panel.close_panel()
		"quest_log":
			panel.close_panel()
		"relationship":
			panel.close_panel()
		"character":
			panel.visible = false

	visible = true
	_refresh_display()


func _on_panel_closed() -> void:
	_active_panel_key = ""
	if _game_loop and _game_loop.current_state == 1:
		visible = true
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
# NPC 交谈 (s6-04)
# ============================================================================

func _build_npc_buttons() -> void:
	var panel_container: PanelContainer = $PanelContainer
	var vbox: VBoxContainer = $PanelContainer/VBox
	if vbox == null:
		return

	# 创建NPC区域容器
	var separator := HSeparator.new()
	vbox.add_child(separator)

	var npc_label := Label.new()
	npc_label.text = "附近的修士"
	npc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(npc_label)

	_npc_container = VBoxContainer.new()
	_npc_container.name = "NPCList"
	vbox.add_child(_npc_container)

	# 从 RelationshipManager 获取 NPC 数据
	var npc_list: Array = []
	var relationship_mgr: Node = get_node_or_null("/root/RelationshipManager")
	if relationship_mgr and relationship_mgr._npc_database.size() > 0:
		for npc_id in relationship_mgr._npc_database:
			var npc_data: Dictionary = relationship_mgr._npc_database[npc_id]
			npc_list.append({
				"id": npc_data.get("id", npc_id),
				"name": npc_data.get("name", npc_id),
				"sect": npc_data.get("sect", ""),
			})
	else:
		npc_list.assign(NPC_FALLBACK)

	for npc in npc_list:
		var btn := Button.new()
		var sect_text: String = " (%s)" % npc.sect if npc.sect != "" else ""
		btn.text = "与 %s 交谈%s" % [npc.name, sect_text]
		btn.custom_minimum_size = Vector2(200, 32)
		var npc_id: String = npc.id
		var npc_name: String = npc.name
		btn.pressed.connect(_on_npc_talk_pressed.bind(npc_id, npc_name))
		_npc_container.add_child(btn)


func _on_npc_talk_pressed(npc_id: String, npc_name: String) -> void:
	var dialogue_mgr: Node = get_node_or_null("/root/DialogueManager")
	if dialogue_mgr == null:
		log_label.text = "（对话系统不可用）"
		return

	var success: bool = dialogue_mgr.start_dialogue_with_npc(npc_id)
	if not success:
		log_label.text = "（%s没有什么特别想说的）" % npc_name


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
	visible = false


func _on_dialogue_ended(_dialogue_id: String) -> void:
	if _game_loop and _game_loop.current_state == 1:  # EXPLORING
		visible = true
		_refresh_display()


func _on_encounter_ui_visibility_changed(encounter_ui: Control) -> void:
	if encounter_ui.visible:
		visible = false
	elif _game_loop and _game_loop.current_state == 1:  # EXPLORING
		visible = true
		_refresh_display()


func _on_game_state_changed(new_state: int) -> void:
	# 0=MENU, 1=EXPLORING, 2=IN_COMBAT, 3=COMBAT_RESULT
	print("[ExplorationPanel] 收到状态变化: %d, 当前visible=%s" % [new_state, str(visible)])
	match new_state:
		1:  # EXPLORING
			visible = true
			print("[ExplorationPanel] 设置 visible=true, 实际=%s, layer=%d" % [str(visible), layer])
			_refresh_display()
		_:
			visible = false

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
