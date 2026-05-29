## 对话UI脚本 — 视觉小说模式
## 全屏背景 + 左右立绘 + 底部对话框
extends Control

## 信号
signal dialogue_closed
signal player_choice_selected(choice_index: int)

## 节点引用
@onready var _dialogue_bg: TextureRect = $DialogueBG
@onready var _left_portrait: TextureRect = $LeftPortrait
@onready var _right_portrait: TextureRect = $RightPortrait
@onready var _speaker_name: Label = $DialoguePanel/VBoxContainer/SpeakerPanel/SpeakerName
@onready var _dialogue_text: RichTextLabel = $DialoguePanel/VBoxContainer/DialogueText
@onready var _choices_container: VBoxContainer = $DialoguePanel/VBoxContainer/ChoicesContainer
@onready var _continue_hint: Label = $DialoguePanel/VBoxContainer/BottomBar/ContinueHint
@onready var _close_button: Button = $DialoguePanel/VBoxContainer/BottomBar/CloseButton

## 选择按钮缓存
var _choice_buttons: Array[Button] = []

## 对话管理器引用
var _dialogue_manager: Node = null

## 当前可用选择
var _current_choices: Array = []

## 是否等待玩家输入
var _waiting_for_input: bool = false
var _has_choices: bool = false

## 当前对话的双方 ID
var _current_npc_id: String = ""


func _ready() -> void:
	_choice_buttons.assign([
		$DialoguePanel/VBoxContainer/ChoicesContainer/Choice1,
		$DialoguePanel/VBoxContainer/ChoicesContainer/Choice2,
		$DialoguePanel/VBoxContainer/ChoicesContainer/Choice3,
		$DialoguePanel/VBoxContainer/ChoicesContainer/Choice4
	])

	_hide_all_choices()

	for i in range(_choice_buttons.size()):
		_choice_buttons[i].pressed.connect(_on_choice_pressed.bind(i))

	_continue_hint.visible = false
	_close_button.pressed.connect(_on_close_pressed)

	var dialogue_manager: Node = get_node_or_null("/root/DialogueManager")
	if dialogue_manager != null:
		set_dialogue_manager(dialogue_manager)


func set_dialogue_manager(manager: Node) -> void:
	_dialogue_manager = manager
	if _dialogue_manager != null:
		if not _dialogue_manager.node_displayed.is_connected(_on_node_displayed):
			_dialogue_manager.node_displayed.connect(_on_node_displayed)
		if not _dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
			_dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)


func show_dialogue() -> void:
	visible = true
	_load_dialogue_bg()
	grab_focus()


func hide_dialogue() -> void:
	visible = false
	_waiting_for_input = false
	_has_choices = false
	_left_portrait.visible = false
	_right_portrait.visible = false


func _update_speaker(speaker_id: String) -> void:
	_speaker_name.text = _get_display_name(speaker_id)
	_update_portraits(speaker_id)


func _update_portraits(speaker_id: String) -> void:
	if speaker_id == "system" or speaker_id == "narrator" or speaker_id.is_empty():
		_left_portrait.modulate = Color(0.4, 0.4, 0.4, 1)
		_right_portrait.modulate = Color(0.4, 0.4, 0.4, 1)
		return

	# 玩家立绘始终在左侧
	_load_portrait(_left_portrait, "protagonist_male")
	_left_portrait.visible = true

	if speaker_id == "player":
		_left_portrait.modulate = Color.WHITE
		_right_portrait.modulate = Color(0.4, 0.4, 0.4, 1)
	else:
		# NPC 在右侧
		_current_npc_id = speaker_id
		_load_portrait(_right_portrait, speaker_id)
		_right_portrait.visible = true
		_left_portrait.modulate = Color(0.4, 0.4, 0.4, 1)
		_right_portrait.modulate = Color.WHITE


func _load_portrait(target: TextureRect, char_id: String) -> void:
	var path := "res://assets/ui/portraits/portrait_%s.png" % char_id
	if ResourceLoader.exists(path):
		target.texture = load(path) as Texture2D
		target.visible = true
	else:
		target.visible = false


func _load_dialogue_bg() -> void:
	var game_loop: Node = get_node_or_null("/root/GameLoopManager")
	if game_loop == null:
		return
	var region_id: String = game_loop.current_region.get("id", "")
	var bg_path := "res://assets/ui/backgrounds/bg_%s.png" % region_id
	if ResourceLoader.exists(bg_path):
		_dialogue_bg.texture = load(bg_path) as Texture2D
	else:
		# 回退到通用背景
		var fallback := "res://assets/ui/backgrounds/bg_qingyun_sect.png"
		if ResourceLoader.exists(fallback):
			_dialogue_bg.texture = load(fallback) as Texture2D


func _update_text(text: String) -> void:
	_dialogue_text.text = text


func _show_choices(choices: Array) -> void:
	_hide_all_choices()
	_has_choices = true
	_current_choices = choices
	_continue_hint.visible = false

	var count := mini(choices.size(), _choice_buttons.size())
	for i in range(count):
		var choice = choices[i]
		_choice_buttons[i].text = choice.text if choice.text != "" else "选择"
		_choice_buttons[i].visible = true
		var dao_heart_hint: int = choice.dao_heart_hint
		if dao_heart_hint != 0:
			var hint_text := " (+)" if dao_heart_hint > 0 else " (-)"
			_choice_buttons[i].text += hint_text


func _hide_all_choices() -> void:
	for btn in _choice_buttons:
		btn.visible = false
	_current_choices.clear()
	_has_choices = false


func _show_continue_hint() -> void:
	_continue_hint.visible = true
	_waiting_for_input = true


func _get_display_name(speaker_id: String) -> String:
	match speaker_id:
		"yunzhonghe": return "云中鹤"
		"tiewushuang": return "铁无双"
		"liuruyan": return "柳如烟"
		"murongxue": return "慕容雪"
		"xiaohanye": return "萧寒夜"
		"xuanjizhenren": return "玄机真人"
		"xuewuhen": return "血无痕"
		"player": return "我"
		"system", "narrator": return ""
		_: return speaker_id.capitalize()


func _on_node_displayed(node: DialogueData.DialogueNode) -> void:
	if not visible:
		show_dialogue()
	_update_speaker(node.speaker)
	_update_text(node.text)

	var choices = node.get_available_choices()
	if not choices.is_empty():
		_show_choices(choices)
		_waiting_for_input = true
	else:
		_hide_all_choices()
		_show_continue_hint()
		_waiting_for_input = true


func _on_dialogue_ended(_dialogue_id: String) -> void:
	hide_dialogue()
	dialogue_closed.emit()


func _on_choice_pressed(index: int) -> void:
	if index >= 0 and index < _current_choices.size():
		player_choice_selected.emit(index)
		if _dialogue_manager != null:
			_dialogue_manager.select_choice(index)
		_hide_all_choices()
		_waiting_for_input = false


func _on_close_pressed() -> void:
	if _dialogue_manager != null:
		_dialogue_manager.end_dialogue()


func _advance() -> void:
	_waiting_for_input = false
	_continue_hint.visible = false
	if _dialogue_manager != null:
		_dialogue_manager.advance_dialogue()


func _gui_input(event: InputEvent) -> void:
	if not visible or _has_choices:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _waiting_for_input:
			_advance()
			accept_event()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if _dialogue_manager != null:
				_dialogue_manager.end_dialogue()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if _has_choices:
				return
			if _waiting_for_input:
				_advance()
				get_viewport().set_input_as_handled()
