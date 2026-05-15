## 对话UI脚本
## 处理对话显示、选择按钮和玩家输入
extends Control

## 信号
signal dialogue_closed
signal player_choice_selected(choice_index: int)

## 节点引用
@onready var _speaker_name: Label = $VBoxContainer/SpeakerPanel/HBoxContainer/SpeakerName
@onready var _dialogue_text: RichTextLabel = $VBoxContainer/DialogueText
@onready var _choices_container: VBoxContainer = $VBoxContainer/ChoicesContainer
@onready var _continue_hint: Label = $VBoxContainer/BottomBar/ContinueHint
@onready var _close_button: Button = $VBoxContainer/BottomBar/CloseButton

## 选择按钮缓存
var _choice_buttons: Array[Button] = []

## 对话管理器引用
var _dialogue_manager: Node = null

## 当前可用选择
var _current_choices: Array = []

## 是否等待玩家输入
var _waiting_for_input: bool = false
var _has_choices: bool = false

func _ready() -> void:
	# 缓存选择按钮
	_choice_buttons.assign([
		$VBoxContainer/ChoicesContainer/Choice1,
		$VBoxContainer/ChoicesContainer/Choice2,
		$VBoxContainer/ChoicesContainer/Choice3,
		$VBoxContainer/ChoicesContainer/Choice4
	])
	
	# 隐藏所有选择按钮
	_hide_all_choices()
	
	# 连接按钮信号
	for i in range(_choice_buttons.size()):
		_choice_buttons[i].pressed.connect(_on_choice_pressed.bind(i))
	
	# 隐藏继续提示
	_continue_hint.visible = false

	# 连接关闭按钮
	_close_button.pressed.connect(_on_close_pressed)

	# 自动连接DialogueManager
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager != null:
		set_dialogue_manager(dialogue_manager)
		print("[DialogueBox] Connected to DialogueManager")
	else:
		push_warning("[DialogueBox] DialogueManager not found - dialogue UI will not function")

## 设置对话管理器
func set_dialogue_manager(manager: Node) -> void:
	_dialogue_manager = manager
	
	if _dialogue_manager != null:
		# 连接信号
		if not _dialogue_manager.node_displayed.is_connected(_on_node_displayed):
			_dialogue_manager.node_displayed.connect(_on_node_displayed)
		if not _dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
			_dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)

## 显示对话面板
func show_dialogue() -> void:
	visible = true
	grab_focus()

## 隐藏对话面板
func hide_dialogue() -> void:
	visible = false
	_waiting_for_input = false
	_has_choices = false

## 更新说话者名称
func _update_speaker(speaker_id: String) -> void:
	var speaker_name := _get_display_name(speaker_id)
	_speaker_name.text = speaker_name

## 更新对话文本
func _update_text(text: String) -> void:
	_dialogue_text.text = text

## 显示选择按钮
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

		# 显示道心提示（如果有）
		var dao_heart_hint: int = choice.dao_heart_hint
		if dao_heart_hint != 0:
			var hint_text := " (+)" if dao_heart_hint > 0 else " (-)"
			_choice_buttons[i].text += hint_text

## 隐藏所有选择按钮
func _hide_all_choices() -> void:
	for btn in _choice_buttons:
		btn.visible = false
	_current_choices.clear()
	_has_choices = false

## 显示继续提示
func _show_continue_hint() -> void:
	_continue_hint.visible = true
	_waiting_for_input = true

## 获取显示名称
func _get_display_name(speaker_id: String) -> String:
	match speaker_id:
		"yunzhonghe":
			return "云中鹤"
		"tiewushuang":
			return "铁无双"
		"liuruyan":
			return "柳如烟"
		"murongxue":
			return "慕容雪"
		"xiaohanye":
			return "萧寒夜"
		"player":
			return "我"
		"system":
			return ""
		_:
			return speaker_id.capitalize()

## 处理节点显示
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

## 对话结束
func _on_dialogue_ended(_dialogue_id: String) -> void:
	hide_dialogue()
	dialogue_closed.emit()

## 玩家选择按钮
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
			# ESC键关闭对话
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
