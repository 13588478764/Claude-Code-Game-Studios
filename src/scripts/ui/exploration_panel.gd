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

## 时段系统: 每 5 次探索推进一个时段
var _explore_count: int = 0
enum TimeOfDay { DAY, DUSK, NIGHT }
var _current_time: TimeOfDay = TimeOfDay.DAY

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
		KEY_W: "martial_arts",
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

	if GameEvents:
		GameEvents.player_realm_changed.connect(_on_realm_breakthrough)
		GameEvents.combat_ended.connect(_on_combat_ended_for_kills)

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
		"martial_arts":
			_show_martial_arts_panel()
			return


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

	# 商人入口
	var shop_btn := Button.new()
	shop_btn.text = "行脚商人 (购买装备/丹药)"
	shop_btn.custom_minimum_size = Vector2(200, 36)
	shop_btn.pressed.connect(_show_shop_panel)
	_npc_container.add_child(shop_btn)


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
	# 1. 先检查主线事件
	if _try_trigger_story_via_npc(npc_id, npc_name):
		return

	# 2. 再检查支线任务
	if _try_trigger_side_quest(npc_id, npc_name):
		return

	# 3. 普通 NPC 对话
	var dialogue_mgr: Node = get_node_or_null("/root/DialogueManager")
	if dialogue_mgr == null:
		log_label.text = "（对话系统不可用）"
		return

	var success: bool = dialogue_mgr.start_dialogue_with_npc(npc_id)
	if not success:
		log_label.text = "（%s没有什么特别想说的）" % npc_name


## NPC 支线对话 ID 映射
## 支线任务配置: quest_id → {dialogue_id, require_kills, require_item, reward_exp_mult, reward_item}
const SIDE_QUEST_CONFIG: Dictionary = {
	"yunzhonghe_sword_path": {
		"dialogue_id": "YUN_QUEST_LINE",
		"npc_name": "云中鹤",
		"hint": "击败5个敌人后帮云中鹤寻找剑心",
		"reward_hint": "经验+古剑术残篇",
		"require_kills": 5,
		"reward_item": "ancient_sword_technique_fragment",
	},
	"tiewushuang_beggars": {
		"dialogue_id": "TIE_QUEST_LINE",
		"npc_name": "铁无双",
		"hint": "与铁无双把酒言欢",
		"reward_hint": "经验+回春丹",
		"reward_item": "health_pill",
	},
	"liuruyan_righteous": {
		"dialogue_id": "LIU_QUEST_LINE",
		"npc_name": "柳如烟",
		"hint": "获取精钢剑后助柳如烟行侠",
		"reward_hint": "经验+武学残卷",
		"require_item": "rare_sword",
		"reward_item": "ancient_martial_art_fragment",
	},
	"murongxue_past_life": {
		"dialogue_id": "MU_QUEST_LINE",
		"npc_name": "慕容雪",
		"hint": "击败8个敌人后探索前世之谜",
		"reward_hint": "经验+火焰戒指",
		"require_kills": 8,
		"reward_item": "epic_ring",
	},
	"xiaohanye_demonic": {
		"dialogue_id": "XIAO_QUEST_LINE",
		"npc_name": "萧寒夜",
		"hint": "击败6个敌人后追随魔道之路",
		"reward_hint": "经验+功法卷轴",
		"require_kills": 6,
		"reward_item": "ancient_technique_scroll",
	},
}

## 已完成的支线 quest_id 集合
var _completed_side_quests: Array[String] = []


func _try_trigger_side_quest(npc_id: String, npc_name: String) -> bool:
	var trigger_mgr: Node = get_node_or_null("/root/QuestTriggerManager")
	var dialogue_mgr: Node = get_node_or_null("/root/DialogueManager")
	if trigger_mgr == null or dialogue_mgr == null:
		return false

	var available: Array = trigger_mgr.get_available_quests_for_npc(npc_id)
	if available.is_empty():
		return false

	# 找第一个未完成的支线
	var quest_id := ""
	for qid in available:
		if qid not in _completed_side_quests:
			quest_id = qid
			break
	if quest_id.is_empty():
		return false

	var config: Dictionary = SIDE_QUEST_CONFIG.get(quest_id, {})
	if config.is_empty():
		return false

	# 检查支线前置条件
	var block := _check_side_quest_conditions(config)
	if not block.is_empty():
		log_label.text = "[color=yellow]%s：「%s」[/color]" % [npc_name, block]
		return true

	var dialogue_id: String = config.get("dialogue_id", "")
	if dialogue_id.is_empty():
		return false

	dialogue_mgr.start_dialogue(dialogue_id)
	log_label.text = "[color=cyan]支线任务：%s[/color]" % config.get("hint", "与%s的故事" % npc_name)

	if not _dialogue_reward_pending:
		_dialogue_reward_pending = true
		dialogue_mgr.dialogue_ended.connect(_on_side_quest_ended.bind(quest_id), CONNECT_ONE_SHOT)
	return true


func _check_side_quest_conditions(config: Dictionary) -> String:
	var require_kills: int = config.get("require_kills", 0)
	if require_kills > 0 and _total_kills < require_kills:
		return "你还需要更多历练（击败敌人 %d/%d）" % [_total_kills, require_kills]

	var require_item: String = config.get("require_item", "")
	if not require_item.is_empty():
		var inv: Node = get_node_or_null("/root/InventorySystem")
		if inv == null or not inv.has_item(require_item):
			var items_data: Dictionary = _load_items_data()
			var item_name: String = items_data.get(require_item, {}).get("name", require_item)
			return "你需要获得「%s」" % item_name

	return ""


func _on_side_quest_ended(_dialogue_id: String, quest_id: String) -> void:
	_dialogue_reward_pending = false

	# 标记支线已完成 (防止重复领取)
	if quest_id not in _completed_side_quests:
		_completed_side_quests.append(quest_id)
	else:
		return

	var char_sys: Node = get_node_or_null("/root/CharacterSystem")
	var currency: Node = get_node_or_null("/root/CurrencyManager")
	var inv: Node = get_node_or_null("/root/InventorySystem")

	# 经验: 升级所需的 30%
	var exp_reward: int = 100
	if char_sys and char_sys.has_method("get_exp_required_for_level"):
		exp_reward = int(char_sys.get_exp_required_for_level(char_sys.level + 1) * 0.3)
	var silver_reward: int = 50

	if char_sys and char_sys.has_method("add_experience"):
		char_sys.add_experience(exp_reward)
	if currency and currency.has_method("add_currency"):
		currency.add_currency(0, silver_reward)

	# 道具奖励
	var config: Dictionary = SIDE_QUEST_CONFIG.get(quest_id, {})
	var reward_item: String = config.get("reward_item", "")
	var reward_text := "+%d 经验 +%d 银两" % [exp_reward, silver_reward]
	if not reward_item.is_empty() and inv and inv.has_method("add_item"):
		inv.add_item(reward_item, 1)
		var items_data: Dictionary = _load_items_data()
		var item_name: String = items_data.get(reward_item, {}).get("name", reward_item)
		reward_text += " +[%s]" % item_name

	if log_label:
		log_label.text = "[color=cyan]支线完成！%s[/color]" % reward_text
	if GameEvents and GameEvents.has_signal("system_notification"):
		GameEvents.system_notification.emit("支线完成！%s" % reward_text, "success", 4.0)


## 尝试通过 NPC 交谈触发主线事件
func _try_trigger_story_via_npc(npc_id: String, npc_name: String) -> bool:
	var act_mgr: Node = get_node_or_null("/root/ActManager")
	var dialogue_mgr: Node = get_node_or_null("/root/DialogueManager")
	var char_sys: Node = get_node_or_null("/root/CharacterSystem")
	if act_mgr == null or dialogue_mgr == null:
		return false

	var next_event: Dictionary = _get_next_story_event(act_mgr)
	if next_event.is_empty():
		return false

	# 检查所有前置条件
	var block_reason: String = _check_story_conditions(next_event, char_sys)
	if not block_reason.is_empty():
		log_label.text = "[color=red]%s：「%s」[/color]" % [npc_name, block_reason]
		return true

	# 全部条件满足 → 触发主线对话
	var event_id: String = next_event.event_id
	var dialogue_id: String = next_event.dialogue_id
	act_mgr.trigger_event(act_mgr.current_act, event_id)
	dialogue_mgr.start_dialogue(dialogue_id)

	if not _dialogue_reward_pending:
		_dialogue_reward_pending = true
		dialogue_mgr.dialogue_ended.connect(_on_main_story_dialogue_ended.bind(event_id), CONNECT_ONE_SHOT)
	return true


func _get_next_story_event(act_mgr: Node) -> Dictionary:
	for event in MAIN_STORY_EVENTS:
		if not act_mgr.is_event_completed(event.event_id):
			return event
	return {}


# ============================================================================
# 事件处理
# ============================================================================

func _on_explore_pressed() -> void:
	if _game_loop == null:
		return
	log_label.text = "探索中..."
	_game_loop.do_explore_action()
	_advance_time()


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

	# 任务提示 (始终显示在日志上方)
	var hint := get_current_story_hint()
	if hint != "" and log_label:
		var current_log: String = log_label.text
		# 去除旧的任务提示行
		if current_log.begins_with("[color"):
			var newline_pos: int = current_log.find("\n")
			if newline_pos >= 0:
				current_log = current_log.substr(newline_pos + 1)
			else:
				current_log = ""
		log_label.text = "%s\n%s" % [hint, current_log]


## 根据当前区域和时段加载背景图
func _load_region_background(region: Dictionary) -> void:
	if scene_background == null:
		return
	var bg_name: String = region.get("bg", "")
	if bg_name.is_empty():
		return

	# 尝试加载时段变体
	var suffix := ""
	match _current_time:
		TimeOfDay.DUSK: suffix = "_dusk"
		TimeOfDay.NIGHT: suffix = "_night"

	if not suffix.is_empty():
		var variant_path := "res://assets/ui/backgrounds/%s%s.png" % [bg_name, suffix]
		if ResourceLoader.exists(variant_path):
			scene_background.texture = load(variant_path) as Texture2D
			return

	var bg_path := "res://assets/ui/backgrounds/%s.png" % bg_name
	if ResourceLoader.exists(bg_path):
		scene_background.texture = load(bg_path) as Texture2D


## 推进时段 (每5次探索切换)
func _advance_time() -> void:
	_explore_count += 1
	if _explore_count % 5 == 0:
		match _current_time:
			TimeOfDay.DAY: _current_time = TimeOfDay.DUSK
			TimeOfDay.DUSK: _current_time = TimeOfDay.NIGHT
			TimeOfDay.NIGHT: _current_time = TimeOfDay.DAY
		_load_region_background(_game_loop.current_region)


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

## 主线事件序列 (三幕28事件, 覆盖 Lv1-90)
## 条件: required_level / require_kills / require_item / require_realm (可选, 无则纯对话)
## reward: 固定标注在 hint 中给玩家看, 实际发放在 _grant_story_reward
## dialogue_id 必须与 data/dialogues/*.json 中的 "id" 字段一致
const MAIN_STORY_EVENTS: Array[Dictionary] = [
	# === Act 1: 青云镇危机 (Lv1-15, 炼气→筑基) ===
	{"event_id": "act1_event1_opening", "dialogue_id": "ACT1_OPENING_001",
		"hint": "与村中长老交谈", "reward_hint": "经验+银两",
		"required_level": 1},
	{"event_id": "act1_event2_cultivation", "dialogue_id": "ACT2_CULTIVATION_001",
		"hint": "击败3个敌人后回来汇报", "reward_hint": "经验+古剑术残篇",
		"required_level": 2, "require_kills": 3},
	{"event_id": "act1_event3_crisis", "dialogue_id": "ACT3_CRISIS_001",
		"hint": "获取一把铁剑再来调查异变", "reward_hint": "经验+银两",
		"required_level": 5, "require_item": "common_sword"},
	{"event_id": "act1_event4_boss", "dialogue_id": "ACT4_BOSS_001",
		"hint": "击败10个敌人后面对危机", "reward_hint": "经验+精钢剑",
		"required_level": 8, "require_kills": 10},
	{"event_id": "act1_event5_ruins", "dialogue_id": "ACT5_RUINS_001",
		"hint": "突破筑基期后探索古遗迹", "reward_hint": "经验+银两",
		"required_level": 12, "require_realm": 1},
	{"event_id": "act1_event6_resolution", "dialogue_id": "ACT6_RESOLUTION_001",
		"hint": "击败20个敌人后解决危机", "reward_hint": "经验+铁盔",
		"required_level": 15, "require_kills": 20},
	# === Act 2: 九州风云 (Lv16-50, 筑基→化神) ===
	{"event_id": "act2_event1_return", "dialogue_id": "ACT2_EVENT1_RETURN",
		"hint": "与旧友重逢", "reward_hint": "经验+银两",
		"required_level": 16},
	{"event_id": "act2_event2_sect_gathering", "dialogue_id": "ACT2_EVENT2_SECT_GATHERING",
		"hint": "击败30个敌人后参加宗门大会", "reward_hint": "经验+银两",
		"required_level": 20, "require_kills": 30},
	{"event_id": "act2_event3_first_trial", "dialogue_id": "ACT2_EVENT3_FIRST_TRIAL",
		"hint": "获取精钢剑后挑战试炼", "reward_hint": "经验+青冥剑",
		"required_level": 23, "require_item": "rare_sword"},
	{"event_id": "act2_event4_demonic_invasion", "dialogue_id": "ACT2_EVENT4_DEMONIC_INVASION",
		"hint": "突破金丹期抵御魔道入侵", "reward_hint": "经验+银两",
		"required_level": 27, "require_realm": 2},
	{"event_id": "act2_event5_secret_realm", "dialogue_id": "ACT2_EVENT5_SECRET_REALM",
		"hint": "击败50个敌人后探索秘境", "reward_hint": "经验+功法卷轴",
		"required_level": 30, "require_kills": 50},
	{"event_id": "act2_event6_dao_heart_choice", "dialogue_id": "ACT2_EVENT6_DAO_HEART_CHOICE",
		"hint": "在正邪之间做出抉择", "reward_hint": "经验+银两",
		"required_level": 33},
	{"event_id": "act2_event7_murongxue_memory", "dialogue_id": "ACT2_EVENT7_MURONGXUE_MEMORY",
		"hint": "突破元婴期找回记忆", "reward_hint": "经验+银两",
		"required_level": 36, "require_realm": 3},
	{"event_id": "act2_event8_battlefield", "dialogue_id": "ACT2_EVENT8_BATTLEFIELD",
		"hint": "击败80个敌人前往九州战场", "reward_hint": "经验+龙鳞盔",
		"required_level": 40, "require_kills": 80},
	{"event_id": "act2_event9_yunzhonghe_sacrifice", "dialogue_id": "ACT2_EVENT9_SACRIFICE",
		"hint": "获取青冥剑后救援云中鹤", "reward_hint": "经验+银两",
		"required_level": 44, "require_item": "epic_sword"},
	{"event_id": "act2_event10_foundation_breakthrough", "dialogue_id": "ACT2_EVENT10_BREAKTHROUGH",
		"hint": "突破化神期", "reward_hint": "经验+火焰戒指",
		"required_level": 47, "require_realm": 4},
	{"event_id": "act2_event11_act2_finale", "dialogue_id": "ACT2_EVENT11_FINALE",
		"hint": "击败100个敌人完成第二幕", "reward_hint": "经验+银两",
		"required_level": 50, "require_kills": 100},
	# === Act 3: 九州之门 (Lv51-90, 返虚→渡劫) ===
	{"event_id": "act3_event1_new_journey", "dialogue_id": "ACT3_EVENT1_JOURNEY",
		"hint": "突破返虚期踏上新征途", "reward_hint": "经验+银两",
		"required_level": 51, "require_realm": 5},
	{"event_id": "act3_event2_faction_trial", "dialogue_id": "ACT3_EVENT2_TRIAL",
		"hint": "击败120个敌人通过试炼", "reward_hint": "经验+银两",
		"required_level": 55, "require_kills": 120},
	{"event_id": "act3_event3_seal_tremor", "dialogue_id": "ACT3_EVENT3_SEAL",
		"hint": "感应到封印异动", "reward_hint": "经验+银两",
		"required_level": 58},
	{"event_id": "act3_event4_murongxue_appears", "dialogue_id": "ACT3_EVENT4_MURONGXUE",
		"hint": "突破合道期与慕容雪重逢", "reward_hint": "经验+银两",
		"required_level": 62, "require_realm": 6},
	{"event_id": "act3_event5_ancient_battlefield", "dialogue_id": "ACT3_EVENT5_BATTLEFIELD",
		"hint": "获取轩辕剑后闯上古战场", "reward_hint": "经验+完整上古功法",
		"required_level": 66, "require_item": "legendary_sword"},
	{"event_id": "act3_event6_xiaohanye_truth", "dialogue_id": "ACT3_EVENT6_XIAOHANYE",
		"hint": "击败150个敌人揭开真相", "reward_hint": "经验+银两",
		"required_level": 70, "require_kills": 150},
	{"event_id": "act3_event7_sword_bone_awakening", "dialogue_id": "ACT3_EVENT7_SWORD_BONE",
		"hint": "突破大乘期觉醒剑骨", "reward_hint": "经验+银两",
		"required_level": 75, "require_realm": 7},
	{"event_id": "act3_event8_gate_opens", "dialogue_id": "ACT3_EVENT8_GATE",
		"hint": "击败200个敌人开启九州之门", "reward_hint": "经验+五行轮回戒",
		"required_level": 80, "require_kills": 200},
	{"event_id": "act3_event9_final_eve", "dialogue_id": "ACT3_EVENT9_FINAL_EVE",
		"hint": "突破渡劫期准备最终决战", "reward_hint": "经验+银两",
		"required_level": 85, "require_realm": 8},
	{"event_id": "act3_event10_final_battle", "dialogue_id": "ACT3_EVENT10_FINAL_BATTLE",
		"hint": "击败250个敌人后最终决战", "reward_hint": "经验+银两",
		"required_level": 88, "require_kills": 250},
	{"event_id": "act3_event11_ending", "dialogue_id": "ACT3_EVENT11_ENDING",
		"hint": "完成修真之旅", "reward_hint": "通关奖励",
		"required_level": 90},
]

var _story_triggered_this_session: bool = false
var _dialogue_reward_pending: bool = false
var _total_kills: int = 0


## 主线不再自动触发，改为玩家主动与 NPC 交谈时检查
func _try_advance_main_story() -> void:
	pass


func _on_main_story_dialogue_ended(_dialogue_id: String, event_id: String) -> void:
	_dialogue_reward_pending = false
	var act_mgr: Node = get_node_or_null("/root/ActManager")
	if act_mgr:
		act_mgr.complete_event(event_id)
	_story_triggered_this_session = false
	_grant_story_reward(event_id)


## 主线关键事件的装备/武学奖励
const STORY_ITEM_REWARDS: Dictionary = {
	"act1_event2_cultivation": "ancient_sword_technique_fragment",
	"act1_event4_boss": "rare_sword",
	"act1_event6_resolution": "rare_helmet",
	"act2_event3_first_trial": "epic_sword",
	"act2_event5_secret_realm": "ancient_technique_scroll",
	"act2_event8_battlefield": "epic_helmet",
	"act2_event11_act2_finale": "epic_ring",
	"act3_event5_ancient_battlefield": "legendary_sword",
	"act3_event7_sword_bone_awakening": "ancient_technique_complete",
	"act3_event10_final_battle": "legendary_ring",
}


## 主线完成奖励 (经验 + 银两 + 可能的装备/武学)
func _grant_story_reward(event_id: String) -> void:
	var char_sys: Node = get_node_or_null("/root/CharacterSystem")
	var currency: Node = get_node_or_null("/root/CurrencyManager")
	var inv: Node = get_node_or_null("/root/InventorySystem")

	var event_level: int = 1
	for event in MAIN_STORY_EVENTS:
		if event.event_id == event_id:
			event_level = event.get("required_level", 1)
			break

	# 主线奖励 = 该等级升一级所需经验的 50% (不会一次跳级)
	var char_sys_ref: Node = get_node_or_null("/root/CharacterSystem")
	var exp_to_next: int = 100
	if char_sys_ref and char_sys_ref.has_method("get_exp_required_for_level"):
		exp_to_next = char_sys_ref.get_exp_required_for_level(event_level + 1)
	var exp_reward: int = int(exp_to_next * 0.5)
	var silver_reward: int = event_level * 20

	if char_sys and char_sys.has_method("add_experience"):
		char_sys.add_experience(exp_reward)
	if currency and currency.has_method("add_currency"):
		currency.add_currency(0, silver_reward)

	var reward_text := "+%d 经验 +%d 银两" % [exp_reward, silver_reward]

	# 装备/物品奖励
	var item_id: String = STORY_ITEM_REWARDS.get(event_id, "")
	if not item_id.is_empty() and inv and inv.has_method("add_item"):
		inv.add_item(item_id, 1)
		var items_data: Dictionary = _load_items_data()
		var item_name: String = items_data.get(item_id, {}).get("name", item_id)
		reward_text += " +[%s]" % item_name

	if log_label:
		log_label.text = "[color=gold]主线完成！%s[/color]" % reward_text
	if GameEvents and GameEvents.has_signal("system_notification"):
		GameEvents.system_notification.emit("主线完成！%s" % reward_text, "success", 4.0)


## 检查主线事件前置条件, 返回空字符串表示全部满足, 否则返回阻塞原因
func _check_story_conditions(event: Dictionary, char_sys: Node) -> String:
	var player_level: int = 1
	if char_sys:
		player_level = char_sys.level

	var required_level: int = event.get("required_level", 1)
	if player_level < required_level:
		return "你实力尚浅，需要达到等级 %d（当前 %d）" % [required_level, player_level]

	var require_kills: int = event.get("require_kills", 0)
	if require_kills > 0 and _total_kills < require_kills:
		return "你还需要历练，击败更多敌人（%d/%d）" % [_total_kills, require_kills]

	var require_item: String = event.get("require_item", "")
	if not require_item.is_empty():
		var inv: Node = get_node_or_null("/root/InventorySystem")
		if inv == null or not inv.has_item(require_item):
			var items_data: Dictionary = _load_items_data()
			var item_name: String = items_data.get(require_item, {}).get("name", require_item)
			return "你需要获得「%s」" % item_name

	var require_realm: int = event.get("require_realm", 0)
	if require_realm > 0 and char_sys:
		if char_sys.realm_index < require_realm:
			var realm_name: String = char_sys.REALMS[require_realm]["name"] if require_realm < char_sys.REALMS.size() else "更高境界"
			return "你需要突破到「%s」期" % realm_name

	return ""


## 获取当前主线任务提示 (BBCode 格式)
func get_current_story_hint() -> String:
	var act_mgr: Node = get_node_or_null("/root/ActManager")
	var char_sys: Node = get_node_or_null("/root/CharacterSystem")
	if act_mgr == null:
		return ""

	for event in MAIN_STORY_EVENTS:
		if not act_mgr.is_event_completed(event.event_id):
			var reward: String = event.get("reward_hint", "经验")
			var block: String = _check_story_conditions(event, char_sys)
			if not block.is_empty():
				return "[color=gray]%s — %s 🔒 | 奖励: %s[/color]" % [event.hint, block, reward]
			return "[color=gold]%s ← 与附近修士交谈 | 奖励: %s[/color]" % [event.hint, reward]
	return "[color=green]主线完成，自由探索修真界[/color]"


## 战斗结束计数
func _on_combat_ended_for_kills(victory: bool, _result: Dictionary) -> void:
	if victory:
		_total_kills += 1


# ============================================================================
# 境界突破插图
# ============================================================================

const REALM_BREAKTHROUGH_IMAGES: Dictionary = {
	"筑基": "breakthrough_zhuji",
	"金丹": "breakthrough_jindan",
	"元婴": "breakthrough_yuanying",
	"化神": "breakthrough_huashen",
	"返虚": "breakthrough_fanxu",
	"合道": "breakthrough_hedao",
	"大乘": "breakthrough_dasheng",
	"渡劫": "breakthrough_dujie",
	"真仙": "breakthrough_zhenxian",
}


func _on_realm_breakthrough(new_realm: String, _old_realm: String) -> void:
	var image_name: String = REALM_BREAKTHROUGH_IMAGES.get(new_realm, "")
	if image_name.is_empty():
		return

	var img_path := "res://assets/ui/breakthrough_scenes/%s.png" % image_name
	if not ResourceLoader.exists(img_path):
		return

	_show_breakthrough_splash(img_path, new_realm)


func _show_breakthrough_splash(img_path: String, realm_name: String) -> void:
	var overlay := Control.new()
	overlay.name = "BreakthroughSplash"
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.z_index = 600

	var bg := ColorRect.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.color = Color(0, 0, 0, 0.8)
	overlay.add_child(bg)

	var img := TextureRect.new()
	img.anchors_preset = Control.PRESET_CENTER
	img.offset_left = -256
	img.offset_top = -256
	img.offset_right = 256
	img.offset_bottom = 256
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.texture = load(img_path) as Texture2D
	overlay.add_child(img)

	var label := Label.new()
	label.text = "境界突破！踏入 %s 期" % realm_name
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_CENTER_BOTTOM
	label.offset_top = 260
	label.offset_left = -200
	label.offset_right = 200
	overlay.add_child(label)

	var root: Control = $Root
	root.add_child(overlay)

	# 动画: 淡入 → 停留3秒 → 淡出
	overlay.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.5)
	tween.tween_interval(3.0)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.5)
	tween.tween_callback(overlay.queue_free)


# ============================================================================
# 武学装备管理 (W键)
# ============================================================================

func _show_martial_arts_panel() -> void:
	var ma_sys: Node = get_node_or_null("/root/MartialArtsSystem")
	if ma_sys == null:
		return

	_active_panel_key = "martial_arts"
	visible = false

	var overlay := Control.new()
	overlay.name = "MartialArtsPanel"
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.z_index = 400
	get_tree().root.add_child(overlay)

	var bg := ColorRect.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.color = Color(0, 0, 0, 0.7)
	overlay.add_child(bg)

	var panel := PanelContainer.new()
	panel.anchors_preset = Control.PRESET_CENTER
	panel.offset_left = -350
	panel.offset_top = -250
	panel.offset_right = 350
	panel.offset_bottom = 250
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "武学管理 (4个装备槽位)"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# 显示 4 个装备槽
	for i in range(4):
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		vbox.add_child(hbox)

		var slot_label := Label.new()
		var equipped: Variant = ma_sys.equipped_martial_arts[i] if i < ma_sys.equipped_martial_arts.size() else null
		if equipped != null:
			slot_label.text = "槽位%d: %s [%s]" % [i + 1, equipped.name, equipped.grade]
		else:
			slot_label.text = "槽位%d: (空)" % (i + 1)
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(slot_label)

		# 装备按钮 — 从已学武学中选择
		var equip_btn := Button.new()
		equip_btn.text = "更换"
		equip_btn.custom_minimum_size = Vector2(80, 32)
		equip_btn.pressed.connect(_on_ma_slot_change.bind(i, overlay))
		hbox.add_child(equip_btn)

	vbox.add_child(HSeparator.new())

	# 已学武学列表
	var learned_label := Label.new()
	learned_label.text = "已学会的武学 (%d个):" % ma_sys.player_martial_arts.size()
	vbox.add_child(learned_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 100)
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	scroll.add_child(list)

	for ma_id in ma_sys.player_martial_arts:
		var ma: Variant = ma_sys.player_martial_arts[ma_id]
		var item_label := Label.new()
		item_label.text = "  %s [%s] - 威力:%d 内力:%d" % [ma.name, ma.grade, int(ma.base_damage), int(ma.cost_mana)]
		list.add_child(item_label)

	# 关闭按钮
	var close_btn := Button.new()
	close_btn.text = "关闭 (W)"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func():
		overlay.queue_free()
		_on_panel_closed()
	)
	vbox.add_child(close_btn)

	overlay.visible = true


# ============================================================================
# 商店系统
# ============================================================================

const SHOP_ITEMS_BY_TIER: Dictionary = {
	"common": ["health_pill", "common_sword", "body_cloth_robe", "feet_straw_sandals", "hands_cloth_gloves", "neck_hemp_necklace"],
	"rare": ["health_pill", "qi_gathering_pill", "rare_sword", "body_iron_armor", "feet_cloud_boots", "offhand_iron_shield", "hands_iron_gauntlets", "neck_jade_pendant"],
	"epic": ["health_pill", "breakthrough_pill", "epic_sword", "body_cloud_robe", "feet_lingbo_boots", "offhand_xuanwu_shield", "hands_dragon_gloves", "neck_spirit_necklace"],
}


func _get_shop_tier() -> String:
	var region_level: int = _game_loop.current_region.get("level", 1) if _game_loop else 1
	if region_level >= 30:
		return "epic"
	elif region_level >= 10:
		return "rare"
	return "common"


func _show_shop_panel() -> void:
	_active_panel_key = "shop"
	visible = false

	var overlay := Control.new()
	overlay.name = "ShopPanel"
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.z_index = 400
	get_tree().root.add_child(overlay)

	var bg := ColorRect.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.color = Color(0, 0, 0, 0.7)
	overlay.add_child(bg)

	var panel := PanelContainer.new()
	panel.anchors_preset = Control.PRESET_CENTER
	panel.offset_left = -300
	panel.offset_top = -250
	panel.offset_right = 300
	panel.offset_bottom = 250
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var currency: Node = get_node_or_null("/root/CurrencyManager")
	var current_silver: int = 0
	if currency and currency.has_method("get_currency_amount"):
		current_silver = currency.get_currency_amount(0)

	var title := Label.new()
	title.text = "行脚商人 | 银两: %d" % current_silver
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	var tier: String = _get_shop_tier()
	var shop_items: Array = SHOP_ITEMS_BY_TIER.get(tier, [])
	var items_data: Dictionary = _load_items_data()

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	for item_id in shop_items:
		var item: Dictionary = items_data.get(item_id, {})
		if item.is_empty():
			continue
		var price: int = item.get("value_gold", 10) * 2  # 商店售价 = 基础价 × 2
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		list.add_child(hbox)

		var name_label := Label.new()
		name_label.text = "%s (%d 银两)" % [item.get("name", item_id), price]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		var buy_btn := Button.new()
		buy_btn.text = "购买"
		buy_btn.custom_minimum_size = Vector2(80, 32)
		buy_btn.disabled = current_silver < price
		if current_silver < price:
			buy_btn.tooltip_text = "银两不足"
		buy_btn.pressed.connect(_on_shop_buy.bind(item_id, price, overlay))
		hbox.add_child(buy_btn)

	var close_btn := Button.new()
	close_btn.text = "离开商店"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func():
		overlay.queue_free()
		_on_panel_closed()
	)
	vbox.add_child(close_btn)


func _on_shop_buy(item_id: String, price: int, overlay: Control) -> void:
	var currency: Node = get_node_or_null("/root/CurrencyManager")
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if currency == null or inv == null:
		return

	if currency.get_currency_amount(0) < price:
		return

	currency.spend_currency(0, price)
	inv.add_item(item_id, 1)

	if GameEvents and GameEvents.has_signal("system_notification"):
		GameEvents.system_notification.emit("购买成功！", "success", 2.0)

	# 刷新商店面板
	overlay.queue_free()
	_show_shop_panel()


func _load_items_data() -> Dictionary:
	var path := "res://src/data/items.json"
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return {}
	file.close()
	return json.data if json.data is Dictionary else {}


func _on_ma_slot_change(slot_index: int, overlay: Control) -> void:
	var ma_sys: Node = get_node_or_null("/root/MartialArtsSystem")
	if ma_sys == null:
		return

	# 简单轮换: 从 player_martial_arts 中选下一个未装备的
	var equipped_ids: Array = []
	for ma in ma_sys.equipped_martial_arts:
		if ma != null:
			equipped_ids.append(ma.id)

	for ma_id in ma_sys.player_martial_arts:
		if ma_id not in equipped_ids:
			ma_sys.equip_martial_art(ma_id, slot_index)
			# 刷新面板
			overlay.queue_free()
			_show_martial_arts_panel()
			return
