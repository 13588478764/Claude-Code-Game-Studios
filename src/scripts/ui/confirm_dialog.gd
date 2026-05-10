## 确认对话框组件
## 对应 UX Spec: design/ux/interaction-patterns.md §3. 确认对话框
## Z-index = 400（在所有面板之上）

extends CanvasLayer

## 确认时发出
signal confirmed
## 取消时发出
signal cancelled

const SUPPRESS_CONFIG: String = "user://dialog_suppressions.json"

@onready var _panel: PanelContainer = $DialogPanel
@onready var _title_label: Label = $DialogPanel/DialogVBox/TitleLabel
@onready var _desc_label: Label = $DialogPanel/DialogVBox/DescLabel
@onready var _suppress_check: CheckBox = $DialogPanel/DialogVBox/SuppressCheck
@onready var _confirm_btn: Button = $DialogPanel/DialogVBox/ButtonHBox/ConfirmButton
@onready var _cancel_btn: Button = $DialogPanel/DialogVBox/ButtonHBox/CancelButton

var _suppress_key: String = ""
var _reduce_motion: bool = false


func _ready() -> void:
	visible = false
	_panel.modulate = Color(1, 1, 1, 0)

	_confirm_btn.pressed.connect(_on_confirm)
	_cancel_btn.pressed.connect(_on_cancel)

	_reduce_motion = _load_reduce_motion_setting()


## 显示确认对话框
func show_confirm(
	title: String,
	description: String,
	suppress_key: String = "",
	default_confirm: bool = true
) -> void:
	_title_label.text = title
	_desc_label.text = description
	_suppress_key = suppress_key

	if suppress_key.is_empty():
		_suppress_check.visible = false
	else:
		_suppress_check.visible = true
		_suppress_check.button_pressed = _is_suppressed(suppress_key)

	visible = true

	if _reduce_motion:
		_panel.modulate = Color(1, 1, 1, 1)
	else:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.2)

	if default_confirm:
		_confirm_btn.grab_focus()
	else:
		_cancel_btn.grab_focus()


## 隐藏对话框
func hide_dialog() -> void:
	visible = false
	_panel.modulate = Color(1, 1, 1, 0)


## 确认
func _on_confirm() -> void:
	if _suppress_check.visible and _suppress_check.button_pressed and not _suppress_key.is_empty():
		_set_suppressed(_suppress_key)

	confirmed.emit()
	hide_dialog()


## 取消
func _on_cancel() -> void:
	cancelled.emit()
	hide_dialog()


## 检查是否已抑制
func _is_suppressed(key: String) -> bool:
	if not FileAccess.file_exists(SUPPRESS_CONFIG):
		return false

	var file = FileAccess.open(SUPPRESS_CONFIG, FileAccess.READ)
	if file == null:
		return false

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	if json == null:
		return false

	return json.get(key, false)


## 设置抑制状态
func _set_suppressed(key: String) -> void:
	var json: Dictionary = {}

	if FileAccess.file_exists(SUPPRESS_CONFIG):
		var file = FileAccess.open(SUPPRESS_CONFIG, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed != null:
				json = parsed

	json[key] = true

	var file = FileAccess.open(SUPPRESS_CONFIG, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(json, "\t"))
		file.close()


## 清除抑制状态
func clear_suppression(key: String) -> void:
	if not FileAccess.file_exists(SUPPRESS_CONFIG):
		return

	var file = FileAccess.open(SUPPRESS_CONFIG, FileAccess.READ)
	if file == null:
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	if json == null:
		return

	json.erase(key)

	file = FileAccess.open(SUPPRESS_CONFIG, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(json, "\t"))
		file.close()


## 输入处理
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_on_confirm()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_on_cancel()
				get_viewport().set_input_as_handled()


## 读取减少运动设置
func _load_reduce_motion_setting() -> bool:
	var settings_path = "user://settings.json"
	if not FileAccess.file_exists(settings_path):
		return false
	var file = FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		return false
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if json == null:
		return false
	return json.get("reduce_motion", false)
