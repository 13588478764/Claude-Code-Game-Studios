## 主菜单控制器
## 对应 UX Spec: design/ux/main-menu.md
## 全屏布局，Z-index = 0（根场景）

extends Control

signal main_menu_loaded(has_save: bool, save_realm: String, save_region_name: String)
signal main_menu_load_failed(error_reason: String)
signal main_menu_new_game_selected
signal main_menu_continue_selected(save_slot_id: int, character_realm: String, character_region: String)
signal main_menu_settings_opened
signal main_menu_credits_opened
signal main_menu_quit_initiated
signal main_menu_quit_confirmed
signal main_menu_quit_cancelled

@onready var _logo_title: Label = $ZoneA_Logo/LogoVBox/LogoTitle
@onready var _logo_subtitle: Label = $ZoneA_Logo/LogoVBox/LogoSubtitle
@onready var _new_game_btn: Button = $ZoneB_Menu/NewGameButton
@onready var _continue_btn: Button = $ZoneB_Menu/ContinueButton
@onready var _settings_btn: Button = $ZoneB_Menu/SettingsButton
@onready var _credits_btn: Button = $ZoneB_Menu/CreditsButton
@onready var _quit_btn: Button = $ZoneB_Menu/QuitButton
@onready var _save_info_label: Label = $ZoneC_Info/SaveInfoLabel
@onready var _version_label: Label = $ZoneC_Info/VersionLabel

var _has_save: bool = false
var _save_realm: String = ""
var _save_region: String = ""
var _save_slot: int = 1
var _settings_panel: Node = null
var _credits_panel: Node = null
var _exploration_panel: Node = null
var _dialogue_box: Node = null
var _game_panels: Array = []
var _transitioning: bool = false


func _ready() -> void:
	var buttons: Array = [_new_game_btn, _continue_btn, _settings_btn, _credits_btn, _quit_btn]
	for btn in buttons:
		btn.modulate = Color(1, 1, 1, 0)

	_logo_title.modulate = Color(1, 1, 1, 0)
	_logo_subtitle.modulate = Color(1, 1, 1, 0)

	_new_game_btn.pressed.connect(_on_new_game_pressed)
	_continue_btn.pressed.connect(_on_continue_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_credits_btn.pressed.connect(_on_credits_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)

	var version: String = "v%s" % ProjectSettings.get_setting("application/config/version", "0.3.0")
	_version_label.text = version

	_play_intro_animation()

	var game_loop: Node = get_node_or_null("/root/GameLoopManager")
	if game_loop:
		game_loop.game_state_changed.connect(_on_game_state_changed)

	await get_tree().create_timer(0.5).timeout
	_check_save_status()


## 显示主菜单（从游戏内返回时调用）
func show_menu() -> void:
	_transitioning = false
	visible = true
	_check_save_status()
	_new_game_btn.grab_focus()


func _on_game_state_changed(new_state: int) -> void:
	if new_state == 0:
		show_menu()
		for panel in _game_panels:
			if is_instance_valid(panel):
				panel.queue_free()
		_game_panels.clear()
		_exploration_panel = null
		_dialogue_box = null


func _play_intro_animation() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_logo_title, "modulate", Color(1, 1, 1, 1), 0.5)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_logo_subtitle, "modulate", Color(1, 1, 1, 1), 0.5)

	var buttons: Array = [_new_game_btn, _continue_btn, _settings_btn, _credits_btn, _quit_btn]
	for i in range(buttons.size()):
		await get_tree().create_timer(0.08 * (i + 1)).timeout
		var btn: Button = buttons[i]
		btn.modulate = Color(1, 1, 1, 0)
		var start_offset: float = btn.offset_top
		btn.offset_top = start_offset + 20
		var btn_tween := create_tween()
		btn_tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.15)
		btn_tween.tween_property(btn, "offset_top", start_offset, 0.3)
		btn_tween.set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(1.2).timeout
	var info_labels: Array = [$ZoneC_Info/SaveInfoLabel, $ZoneC_Info/VersionLabel]
	for lbl in info_labels:
		if lbl != null:
			lbl.modulate = Color(1, 1, 1, 0)
			var info_tween := create_tween()
			info_tween.tween_property(lbl, "modulate", Color(1, 1, 1, 0.6), 0.2)


## 检测存档状态
func _check_save_status() -> void:
	_has_save = false
	_save_slot = 1
	_save_realm = ""
	_save_region = ""

	var save_sys: Node = get_node_or_null("/root/SaveSystem")
	if save_sys:
		for slot in range(1, save_sys.MAX_SLOTS + 1):
			if save_sys.has_save(slot):
				_has_save = true
				_save_slot = slot
				var info: Dictionary = save_sys.get_save_info(slot)
				_save_realm = info.get("realm", "")
				_save_region = info.get("region", "")
				break

	if _has_save:
		_continue_btn.disabled = false
		_continue_btn.focus_mode = Control.FOCUS_ALL
		var info_text: String = "上次：%s" % _save_realm if _save_realm != "" else "有存档记录"
		_save_info_label.text = info_text
		_save_info_label.visible = true
		_continue_btn.grab_focus()
	else:
		_continue_btn.disabled = true
		_continue_btn.focus_mode = Control.FOCUS_NONE
		_save_info_label.text = "无修炼记录"
		_save_info_label.visible = true
		_new_game_btn.grab_focus()

	main_menu_loaded.emit(_has_save, _save_realm, _save_region)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP, KEY_DOWN:
				var buttons: Array[Button] = _get_focusable_buttons()
				var current_focus: Control = get_viewport().gui_get_focus_owner()
				var idx: int = buttons.find(current_focus)
				if idx == -1:
					idx = 0
				if event.keycode == KEY_DOWN:
					idx = (idx + 1) % buttons.size()
				else:
					idx = (idx - 1 + buttons.size()) % buttons.size()
				buttons[idx].grab_focus()
				get_viewport().set_input_as_handled()
			KEY_ENTER:
				var focus: Control = get_viewport().gui_get_focus_owner()
				if focus is Button and focus.disabled == false:
					focus.pressed.emit()
				get_viewport().set_input_as_handled()


func _get_focusable_buttons() -> Array[Button]:
	var result: Array[Button] = []
	var buttons: Array = [_new_game_btn, _continue_btn, _settings_btn, _credits_btn, _quit_btn]
	for btn in buttons:
		if btn.focus_mode != Control.FOCUS_NONE:
			result.append(btn)
	return result


## ============================================================================
## 新游戏流程 (s6-02)
## ============================================================================

func _on_new_game_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	main_menu_new_game_selected.emit()
	_start_new_game()


func _start_new_game() -> void:
	# 重置角色系统
	var character: Node = get_node_or_null("/root/CharacterSystem")
	if character:
		character.level = 1
		character.experience = 0
		character.realm_index = 0
		character.realm_bonus = 1.0
		character.total_attribute_points = 0
		character.allocated_attribute_points = 0
		character.total_talent_points = 0
		character.allocated_talent_points = 0
		if character.attributes:
			character.attributes.strength = 10
			character.attributes.agility = 10
			character.attributes.constitution = 10
			character.attributes.intelligence = 10
			character.attributes.willpower = 10
			character.attributes.luck = 10

	# 重置关系系统
	var relationship: Node = get_node_or_null("/root/RelationshipManager")
	if relationship and relationship.has_method("reset_all"):
		relationship.reset_all()

	# 重置武学系统
	var martial: Node = get_node_or_null("/root/MartialArtsSystem")
	if martial:
		martial.player_martial_arts.clear()
		martial.player_fragments.clear()
		for i in range(martial.equipped_martial_arts.size()):
			martial.equipped_martial_arts[i] = null

	# 注册NPC个人线
	var quest_trigger: Node = get_node_or_null("/root/QuestTriggerManager")
	if quest_trigger and quest_trigger.has_method("register_all_npc_questlines"):
		quest_trigger.register_all_npc_questlines()

	# 隐藏主菜单
	visible = false

	# 尝试播放开场对话
	var dialogue: Node = get_node_or_null("/root/DialogueManager")
	if dialogue and dialogue.has_dialogue("intro_yunzhonghe"):
		dialogue.dialogue_ended.connect(_on_intro_dialogue_ended, CONNECT_ONE_SHOT)
		dialogue.start_dialogue("intro_yunzhonghe")
	else:
		_enter_exploration()


func _on_intro_dialogue_ended(_dialogue_id: String) -> void:
	_enter_exploration()


func _enter_exploration(is_new_game: bool = true) -> void:
	if is_new_game:
		_initialize_game_systems()
	_load_game_panels()
	var game_loop: Node = get_node_or_null("/root/GameLoopManager")
	if game_loop:
		game_loop.enter_exploration()
	_transitioning = false


func _initialize_game_systems() -> void:
	var character: Node = get_node_or_null("/root/CharacterSystem")
	if character and character.has_method("initialize_character"):
		character.initialize_character()
		character.add_experience(100)

	var currency_mgr: Node = get_node_or_null("/root/CurrencyManager")
	if currency_mgr:
		currency_mgr.add_currency(currency_mgr.CurrencyType.SILVER, 100)

	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv:
		inv.add_item("common_sword", 1)
		inv.add_item("common_helmet", 1)
		inv.add_item("health_pill", 3)
		inv.add_item("spirit_stone_small", 5)
		inv.equip_item("common_sword", "weapon_main")
		inv.equip_item("common_helmet", "head")

	var martial_arts: Node = get_node_or_null("/root/MartialArtsSystem")
	if martial_arts:
		for ma_id in ["sword_basic_01", "fist_basic_01", "palm_basic_01"]:
			var ma_data: Variant = martial_arts.get_martial_art_data(ma_id)
			if ma_data:
				martial_arts.player_martial_arts[ma_id] = ma_data.duplicate(true)
		martial_arts.equip_martial_art("sword_basic_01", 0)
		martial_arts.equip_martial_art("fist_basic_01", 1)
		martial_arts.equip_martial_art("palm_basic_01", 2)


func _load_game_panels() -> void:
	if _exploration_panel != null:
		_exploration_panel.visible = true
		return

	var panels_to_load: Array[Dictionary] = [
		{"path": "res://src/scenes/ui/exploration_panel.tscn", "visible": true},
		{"path": "res://src/scenes/ui/dialogue_box.tscn", "visible": false},
		{"path": "res://src/scenes/ui/pause_menu.tscn", "visible": false},
		{"path": "res://src/scenes/ui/inventory_panel.tscn", "visible": false},
		{"path": "res://src/scenes/ui/equipment_panel.tscn", "visible": false},
		{"path": "res://src/scenes/ui/world_map.tscn", "visible": false},
		{"path": "res://src/scenes/ui/help_panel.tscn", "visible": false},
		{"path": "res://src/scenes/ui/quest_log_panel.tscn", "visible": false},
		{"path": "res://src/scenes/ui/relationship_panel.tscn", "visible": false},
		{"path": "res://src/scenes/ui/encounter_ui.tscn", "visible": false},
		{"path": "res://src/scenes/ui/combat_action_panel.tscn", "visible": false},
		{"path": "res://src/scenes/ui/battle_result_panel.tscn", "visible": false},
	]

	for panel_info in panels_to_load:
		var scene: PackedScene = load(panel_info.path)
		if scene != null:
			var instance: Node = scene.instantiate()
			if instance is CanvasItem or instance is CanvasLayer:
				instance.visible = panel_info.visible
			get_tree().root.add_child(instance)
			_game_panels.append(instance)
			if panel_info.path.ends_with("exploration_panel.tscn"):
				_exploration_panel = instance
			elif panel_info.path.ends_with("dialogue_box.tscn"):
				_dialogue_box = instance
		else:
			push_warning("无法加载面板: %s" % panel_info.path)


## ============================================================================
## 加载游戏流程 (s6-03)
## ============================================================================

func _on_continue_pressed() -> void:
	if not _has_save or _transitioning:
		return
	_transitioning = true

	var save_sys: Node = get_node_or_null("/root/SaveSystem")
	if save_sys == null:
		_transitioning = false
		main_menu_load_failed.emit("存档系统不可用")
		return

	if not save_sys.load_completed.is_connected(_on_load_completed):
		save_sys.load_completed.connect(_on_load_completed, CONNECT_ONE_SHOT)
	if not save_sys.load_failed.is_connected(_on_load_failed):
		save_sys.load_failed.connect(_on_load_failed, CONNECT_ONE_SHOT)

	var success: bool = save_sys.load_from_slot(_save_slot)
	if not success:
		_transitioning = false
		_save_info_label.text = "加载失败"
		main_menu_load_failed.emit("读取存档失败")
		if save_sys.load_completed.is_connected(_on_load_completed):
			save_sys.load_completed.disconnect(_on_load_completed)
		if save_sys.load_failed.is_connected(_on_load_failed):
			save_sys.load_failed.disconnect(_on_load_failed)

	main_menu_continue_selected.emit(_save_slot, _save_realm, _save_region)


func _on_load_completed(_slot: int) -> void:
	visible = false
	_enter_exploration(false)


func _on_load_failed(_slot: int, error: String) -> void:
	_transitioning = false
	_save_info_label.text = "加载失败: %s" % error
	main_menu_load_failed.emit(error)


## ============================================================================
## 设置 / 制作人员 / 退出
## ============================================================================

func _on_settings_pressed() -> void:
	main_menu_settings_opened.emit()
	_load_settings_panel()
	if _settings_panel != null:
		_settings_panel.open_settings()


func _on_credits_pressed() -> void:
	main_menu_credits_opened.emit()
	_load_credits_panel()
	if _credits_panel and _credits_panel.has_method("open_panel"):
		_credits_panel.open_panel()


func _on_quit_pressed() -> void:
	main_menu_quit_initiated.emit()
	main_menu_quit_confirmed.emit()
	get_tree().quit()


func _load_settings_panel() -> void:
	if _settings_panel != null:
		return
	var scene: PackedScene = load("res://src/scenes/ui/settings_panel.tscn")
	if scene != null:
		_settings_panel = scene.instantiate()
		get_tree().root.add_child(_settings_panel)
	else:
		push_warning("无法加载设置面板场景")


func _load_credits_panel() -> void:
	if _credits_panel != null:
		return
	var scene: PackedScene = load("res://src/scenes/ui/credits_panel.tscn")
	if scene != null:
		_credits_panel = scene.instantiate()
		get_tree().root.add_child(_credits_panel)
	else:
		push_warning("无法加载制作人员面板场景")
