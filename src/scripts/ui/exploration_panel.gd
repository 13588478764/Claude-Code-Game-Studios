## ExplorationPanel
## 简易探索面板
##
## MVP 探索界面：显示区域选择、角色状态、探索按钮。
## 通过 GameLoopManager 驱动游戏循环。

extends CanvasLayer

# ============================================================================
# 节点引用
# ============================================================================

@onready var scene_background: TextureRect = $Root/SceneBackground
@onready var region_name_label: Label = $Root/TopBar/TopHBox/RegionNameLabel
@onready var player_level_label: Label = $Root/TopBar/TopHBox/PlayerLevelLabel
@onready var player_exp_label: Label = $Root/TopBar/TopHBox/PlayerExpLabel
@onready var player_realm_label: Label = $Root/TopBar/TopHBox/PlayerRealmLabel
@onready var player_silver_label: Label = $Root/TopBar/TopHBox/PlayerSilverLabel
@onready var explore_button: Button = $Root/ActionPanel/ActionVBox/ExploreButton
@onready var region_list: VBoxContainer = $Root/ActionPanel/ActionVBox/RegionList
@onready var log_label: RichTextLabel = $Root/LogPanel/LogVBox/LogLabel
@onready var _npc_container: VBoxContainer = $Root/NPCPanel/NPCScroll/NPCVBox/NPCList

var _game_loop: Node = null

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
	_check_first_time_tutorial()

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

	var player_level: int = 1
	var char_sys: Node = get_node_or_null("/root/CharacterSystem")
	if char_sys:
		player_level = char_sys.level

	for i in range(_game_loop.REGIONS.size()):
		var region: Dictionary = _game_loop.REGIONS[i]
		var btn := Button.new()
		var region_level: int = region.get("level", 1)
		var locked: bool = player_level < region_level
		if locked:
			btn.text = "%s (Lv.%d 🔒)" % [region.name, region_level]
			btn.disabled = true
			btn.tooltip_text = "需要等级 %d 解锁" % region_level
		else:
			btn.text = "%s (Lv.%d)" % [region.name, region_level]
		btn.custom_minimum_size = Vector2(200, 36)
		var idx := i
		btn.pressed.connect(func(): _on_region_selected(idx))
		region_list.add_child(btn)

# ============================================================================
# NPC 交谈 (s6-04)
# ============================================================================

func _build_npc_buttons() -> void:
	if _npc_container == null:
		return

	for child in _npc_container.get_children():
		child.queue_free()

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
		_npc_container.add_child(_make_npc_row(npc.id, npc.name, npc.sect))


## 构建单个 NPC 行：小头像 + 交谈按钮
func _make_npc_row(npc_id: String, npc_name: String, sect: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(40, 40)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_path := "res://assets/ui/portraits/portrait_%s.png" % npc_id
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path) as Texture2D
	row.add_child(portrait)

	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sect_text: String = " (%s)" % sect if sect != "" else ""
	btn.text = "%s%s" % [npc_name, sect_text]
	btn.pressed.connect(_on_npc_talk_pressed.bind(npc_id, npc_name))
	row.add_child(btn)

	return row


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
	match new_state:
		1:  # EXPLORING
			visible = true
			_refresh_display()
			_try_advance_main_story()
		_:
			visible = false

# ============================================================================
# 刷新显示
# ============================================================================

func _refresh_display() -> void:
	if _game_loop == null:
		return

	var region: Dictionary = _game_loop.current_region
	region_name_label.text = "%s · Lv.%d" % [region.get("name", "未知区域"), region.get("level", 1)]
	_load_region_background(region)
	_build_region_buttons()

	var summary: Dictionary = _game_loop.get_player_summary()
	player_level_label.text = "等级: %d" % summary.get("level", 1)
	player_exp_label.text = "经验: %d/%d" % [summary.get("exp", 0), summary.get("exp_next", 100)]
	player_realm_label.text = "境界: %s" % summary.get("realm", "炼气")
	player_silver_label.text = "银两: %d" % summary.get("silver", 0)

	# 任务提示
	var hint := get_current_story_hint()
	if hint != "" and log_label:
		var current_text: String = log_label.text
		if not current_text.begins_with("[color"):
			log_label.text = "[color=gold]当前目标: %s[/color]\n%s" % [hint, current_text]


## 根据当前区域加载背景图
func _load_region_background(region: Dictionary) -> void:
	if scene_background == null:
		return
	var bg_name: String = region.get("bg", "")
	if bg_name.is_empty():
		return
	var bg_path := "res://assets/ui/backgrounds/%s.png" % bg_name
	if ResourceLoader.exists(bg_path):
		scene_background.texture = load(bg_path) as Texture2D


# ============================================================================
# 新手引导
# ============================================================================

const TUTORIAL_SAVE_KEY := "tutorial_completed"

var _tutorial_steps: Array[String] = [
	"欢迎来到修真界！\n\n你是一名初入修真之路的年轻修士，目标是通过探索、战斗和奇遇不断提升境界。",
	"左侧面板列出了附近的修士。\n点击他们的名字可以交谈，获取情报或触发剧情。",
	"右侧面板可以选择前往不同区域。\n不同区域有不同等级的敌人和独特的奇遇。",
	"点击「探索此区域」按钮开始冒险。\n每次探索可能遭遇战斗、触发仙缘奇遇或获得经验。",
	"快捷键提示:\n  I=背包  E=装备  C=角色  M=地图  J=任务  ESC=暂停\n\n祝你修真之路顺利！",
]
var _tutorial_step: int = 0
var _tutorial_overlay: Control = null


func _check_first_time_tutorial() -> void:
	if _has_completed_tutorial():
		return
	await get_tree().create_timer(0.5).timeout
	_show_tutorial_step()


func _has_completed_tutorial() -> bool:
	var save_path := "user://tutorial_state.save"
	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file:
			var content := file.get_as_text()
			file.close()
			return content.strip_edges() == "done"
	return false


func _mark_tutorial_completed() -> void:
	var file := FileAccess.open("user://tutorial_state.save", FileAccess.WRITE)
	if file:
		file.store_string("done")
		file.close()


func _show_tutorial_step() -> void:
	if _tutorial_step >= _tutorial_steps.size():
		_close_tutorial()
		return

	if _tutorial_overlay == null:
		_tutorial_overlay = Control.new()
		_tutorial_overlay.name = "TutorialOverlay"
		_tutorial_overlay.anchors_preset = Control.PRESET_FULL_RECT
		_tutorial_overlay.z_index = 500
		var root: Control = $Root
		root.add_child(_tutorial_overlay)

		var bg := ColorRect.new()
		bg.anchors_preset = Control.PRESET_FULL_RECT
		bg.color = Color(0, 0, 0, 0.6)
		bg.name = "BG"
		_tutorial_overlay.add_child(bg)

		var panel := PanelContainer.new()
		panel.name = "Panel"
		panel.anchors_preset = Control.PRESET_CENTER
		panel.offset_left = -300
		panel.offset_top = -120
		panel.offset_right = 300
		panel.offset_bottom = 120
		_tutorial_overlay.add_child(panel)

		var vbox := VBoxContainer.new()
		vbox.name = "VBox"
		vbox.add_theme_constant_override("separation", 16)
		panel.add_child(vbox)

		var label := Label.new()
		label.name = "StepLabel"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 20)
		vbox.add_child(label)

		var btn := Button.new()
		btn.name = "NextBtn"
		btn.custom_minimum_size = Vector2(120, 40)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(_on_tutorial_next)
		vbox.add_child(btn)

	var label: Label = _tutorial_overlay.get_node("Panel/VBox/StepLabel")
	var btn: Button = _tutorial_overlay.get_node("Panel/VBox/NextBtn")
	label.text = _tutorial_steps[_tutorial_step]

	if _tutorial_step < _tutorial_steps.size() - 1:
		btn.text = "下一步 (%d/%d)" % [_tutorial_step + 1, _tutorial_steps.size()]
	else:
		btn.text = "开始修炼！"


func _on_tutorial_next() -> void:
	_tutorial_step += 1
	_show_tutorial_step()


func _close_tutorial() -> void:
	if _tutorial_overlay:
		_tutorial_overlay.queue_free()
		_tutorial_overlay = null
	_mark_tutorial_completed()
	_try_advance_main_story()


# ============================================================================
# 主线推进
# ============================================================================

## 主线事件序列 (三幕28事件, 覆盖 Lv1-90, 需满足 required_level 才能推进)
const MAIN_STORY_EVENTS: Array[Dictionary] = [
	# === Act 1: 青云镇危机 (Lv1-15, 炼气→筑基) ===
	{"event_id": "act1_event1_opening", "dialogue_id": "act1_event1_opening", "hint": "与村中长老交谈了解情况", "required_level": 1},
	{"event_id": "act1_event2_cultivation", "dialogue_id": "act1_event2_cultivation", "hint": "开始修炼之路", "required_level": 3},
	{"event_id": "act1_event3_crisis", "dialogue_id": "act1_event3_crisis", "hint": "调查青云镇异变", "required_level": 5},
	{"event_id": "act1_event4_boss", "dialogue_id": "act1_event4_boss", "hint": "面对青云镇危机", "required_level": 8},
	{"event_id": "act1_event5_ruins", "dialogue_id": "act1_event5_ruins", "hint": "探索古遗迹", "required_level": 12},
	{"event_id": "act1_event6_resolution", "dialogue_id": "act1_event6_resolution", "hint": "解决青云镇危机", "required_level": 15},
	# === Act 2: 九州风云 (Lv16-50, 筑基→化神) ===
	{"event_id": "act2_event1_return", "dialogue_id": "act2_event1_return", "hint": "重返修真界", "required_level": 16},
	{"event_id": "act2_event2_sect_gathering", "dialogue_id": "act2_event2_sect_gathering", "hint": "参加宗门大会", "required_level": 20},
	{"event_id": "act2_event3_first_trial", "dialogue_id": "act2_event3_first_trial", "hint": "完成第一次试炼", "required_level": 23},
	{"event_id": "act2_event4_demonic_invasion", "dialogue_id": "act2_event4_demonic_invasion", "hint": "抵御魔道入侵", "required_level": 27},
	{"event_id": "act2_event5_secret_realm", "dialogue_id": "act2_event5_secret_realm", "hint": "探索秘境", "required_level": 30},
	{"event_id": "act2_event6_dao_heart_choice", "dialogue_id": "act2_event6_dao_heart_choice", "hint": "道心抉择", "required_level": 33},
	{"event_id": "act2_event7_murongxue_memory", "dialogue_id": "act2_event7_murongxue_memory", "hint": "慕容雪的记忆", "required_level": 36},
	{"event_id": "act2_event8_battlefield", "dialogue_id": "act2_event8_battlefield", "hint": "九州战场", "required_level": 40},
	{"event_id": "act2_event9_yunzhonghe_sacrifice", "dialogue_id": "act2_event9_yunzhonghe_sacrifice", "hint": "云中鹤的牺牲", "required_level": 44},
	{"event_id": "act2_event10_foundation_breakthrough", "dialogue_id": "act2_event10_foundation_breakthrough", "hint": "突破化神期", "required_level": 47},
	{"event_id": "act2_event11_act2_finale", "dialogue_id": "act2_event11_act2_finale", "hint": "第二幕终章", "required_level": 50},
	# === Act 3: 九州之门 (Lv51-90, 返虚→渡劫) ===
	{"event_id": "act3_event1_new_journey", "dialogue_id": "act3_event1_new_journey", "hint": "踏上新征途", "required_level": 51},
	{"event_id": "act3_event2_faction_trial", "dialogue_id": "act3_event2_faction_trial", "hint": "阵营试炼", "required_level": 55},
	{"event_id": "act3_event3_seal_tremor", "dialogue_id": "act3_event3_seal_tremor", "hint": "封印震动", "required_level": 58},
	{"event_id": "act3_event4_murongxue_appears", "dialogue_id": "act3_event4_murongxue_appears", "hint": "慕容雪现身", "required_level": 62},
	{"event_id": "act3_event5_ancient_battlefield", "dialogue_id": "act3_event5_ancient_battlefield", "hint": "上古战场", "required_level": 66},
	{"event_id": "act3_event6_xiaohanye_truth", "dialogue_id": "act3_event6_xiaohanye_truth", "hint": "萧寒夜的真相", "required_level": 70},
	{"event_id": "act3_event7_sword_bone_awakening", "dialogue_id": "act3_event7_sword_bone_awakening", "hint": "剑骨觉醒", "required_level": 75},
	{"event_id": "act3_event8_gate_opens", "dialogue_id": "act3_event8_gate_opens", "hint": "九州之门开启", "required_level": 80},
	{"event_id": "act3_event9_final_eve", "dialogue_id": "act3_event9_final_eve", "hint": "最终决战前夜", "required_level": 85},
	{"event_id": "act3_event10_final_battle", "dialogue_id": "act3_event10_final_battle", "hint": "最终决战", "required_level": 88},
	{"event_id": "act3_event11_ending", "dialogue_id": "act3_event11_ending", "hint": "结局", "required_level": 90},
]

var _story_triggered_this_session: bool = false


func _try_advance_main_story() -> void:
	if _story_triggered_this_session:
		return
	if _tutorial_overlay != null:
		return

	var act_mgr: Node = get_node_or_null("/root/ActManager")
	var dialogue_mgr: Node = get_node_or_null("/root/DialogueManager")
	var char_sys: Node = get_node_or_null("/root/CharacterSystem")
	if act_mgr == null or dialogue_mgr == null:
		return

	var player_level: int = 1
	if char_sys:
		player_level = char_sys.level

	for event in MAIN_STORY_EVENTS:
		var event_id: String = event.event_id
		if act_mgr.is_event_completed(event_id):
			continue

		# 等级不够 → 不触发，任务提示会显示需要的等级
		var required: int = event.get("required_level", 1)
		if player_level < required:
			return

		_story_triggered_this_session = true
		var dialogue_id: String = event.dialogue_id
		act_mgr.trigger_event(act_mgr.current_act, event_id)

		await get_tree().process_frame
		dialogue_mgr.start_dialogue(dialogue_id)

		if not dialogue_mgr.dialogue_ended.is_connected(_on_main_story_dialogue_ended):
			dialogue_mgr.dialogue_ended.connect(_on_main_story_dialogue_ended.bind(event_id), CONNECT_ONE_SHOT)
		return

	_story_triggered_this_session = true


func _on_main_story_dialogue_ended(_dialogue_id: String, event_id: String) -> void:
	var act_mgr: Node = get_node_or_null("/root/ActManager")
	if act_mgr:
		act_mgr.complete_event(event_id)
	_story_triggered_this_session = false


## 获取当前主线任务提示
func get_current_story_hint() -> String:
	var act_mgr: Node = get_node_or_null("/root/ActManager")
	var char_sys: Node = get_node_or_null("/root/CharacterSystem")
	if act_mgr == null:
		return ""
	var player_level: int = 1
	if char_sys:
		player_level = char_sys.level

	for event in MAIN_STORY_EVENTS:
		if not act_mgr.is_event_completed(event.event_id):
			var required: int = event.get("required_level", 1)
			if player_level < required:
				return "%s (需要等级 %d, 当前 %d)" % [event.hint, required, player_level]
			return event.hint
	return "主线完成，自由探索"
