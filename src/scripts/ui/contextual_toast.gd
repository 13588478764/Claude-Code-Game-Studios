## 情境提示Toast
## 对应 UX Spec: design/ux/help-tutorial.md §6 情境提示
## Z-index = 190（在帮助面板180之上、Tooltip 200之下）

extends CanvasLayer

## 提示点击"了解更多"时发出
signal learn_more_clicked(toast_id: String, related_chapter_id: String)
## 提示点击"稍后查看"时发出
signal later_clicked(toast_id: String)
## 提示被消除时发出
signal dismissed(toast_id: String, action: String)

const SUPPRESS_CONFIG: String = "user://toast_suppressions.json"
const AUTO_DISMISS_TIME: float = 10.0

@onready var _panel: PanelContainer = $ToastPanel
@onready var _title_label: Label = $ToastPanel/ToastVBox/TitleLabel
@onready var _body_label: Label = $ToastPanel/ToastVBox/BodyLabel
@onready var _learn_more_btn: Button = $ToastPanel/ToastVBox/ButtonHBox/LearnMoreButton
@onready var _later_btn: Button = $ToastPanel/ToastVBox/ButtonHBox/LaterButton
@onready var _dismiss_btn: Button = $ToastPanel/ToastVBox/ButtonHBox/DismissButton

var _toast_id: String = ""
var _related_chapter_id: String = ""
var _auto_dismiss_timer: float = 0.0
var _reduce_motion: bool = false


func _ready() -> void:
	visible = false
	_panel.modulate = Color(1, 1, 1, 0)

	_learn_more_btn.pressed.connect(_on_learn_more)
	_later_btn.pressed.connect(_on_later)
	_dismiss_btn.pressed.connect(_on_dismiss)

	_reduce_motion = _load_reduce_motion_setting()


## 显示提示
func show_toast(toast_id: String, title: String, body: String, related_chapter_id: String = "") -> void:
	# 检查是否已被抑制
	if _is_suppressed(toast_id):
		return

	_toast_id = toast_id
	_related_chapter_id = related_chapter_id
	_auto_dismiss_timer = AUTO_DISMISS_TIME

	_title_label.text = title
	_body_label.text = body

	visible = true

	if _reduce_motion:
		_panel.modulate = Color(1, 1, 1, 1)
	else:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.3)


## 隐藏提示
func hide_toast() -> void:
	visible = false
	_panel.modulate = Color(1, 1, 1, 0)


## _process 用于自动消失计时
func _process(delta: float) -> void:
	if visible and _auto_dismiss_timer > 0:
		_auto_dismiss_timer -= delta
		if _auto_dismiss_timer <= 0:
			_auto_dismiss()


## 了解更多
func _on_learn_more() -> void:
	learn_more_clicked.emit(_toast_id, _related_chapter_id)
	_hide_with_animation()
	dismissed.emit(_toast_id, "learn_more")


## 稍后查看
func _on_later() -> void:
	later_clicked.emit(_toast_id)
	_hide_with_animation()
	dismissed.emit(_toast_id, "later")


## 消除
func _on_dismiss() -> void:
	_set_suppressed(_toast_id)
	_hide_with_animation()
	dismissed.emit(_toast_id, "dismiss")


## 自动消失
func _auto_dismiss() -> void:
	_hide_with_animation()
	dismissed.emit(_toast_id, "auto_dismiss")


## 带动画隐藏
func _hide_with_animation() -> void:
	if _reduce_motion:
		hide_toast()
	else:
		var tween = create_tween()
		tween.tween_property(_panel, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_callback(hide_toast)


## 检查是否已被抑制
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
