## 主菜单控制器
## 对应 UX Spec: design/ux/main-menu.md
## 全屏布局，Z-index = 0（根场景）

extends Control

## 主菜单加载完成时发出
signal main_menu_loaded(has_save: bool, save_realm: String, save_region_name: String)
## 存档加载失败时发出
signal main_menu_load_failed(error_reason: String)
## 开始新游戏
signal main_menu_new_game_selected
## 继续游戏
signal main_menu_continue_selected(save_slot_id: int, character_realm: String, character_region: String)
## 设置打开
signal main_menu_settings_opened
## 制作人员打开
signal main_menu_credits_opened
## 退出游戏
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

## 是否有存档
var _has_save: bool = false
## 存档信息
var _save_realm: String = ""
var _save_region: String = ""


func _ready() -> void:
	# 初始隐藏所有按钮（用于入场动画）
	var buttons = [_new_game_btn, _continue_btn, _settings_btn, _credits_btn, _quit_btn]
	for btn in buttons:
		btn.modulate = Color(1, 1, 1, 0)

	_logo_title.modulate = Color(1, 1, 1, 0)
	_logo_subtitle.modulate = Color(1, 1, 1, 0)

	# 连接按钮信号
	_new_game_btn.pressed.connect(_on_new_game_pressed)
	_continue_btn.pressed.connect(_on_continue_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_credits_btn.pressed.connect(_on_credits_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)

	# 版本号
	var version = "v%s" % ProjectSettings.get_setting("application/config/version", "1.0.0")
	_version_label.text = version

	# 入场动画
	_play_intro_animation()

	# 检测存档
	await get_tree().create_timer(0.5).timeout
	_check_save_status()


## 播放入场动画
func _play_intro_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(true)

	# 背景已在ColorRect中，不需要额外淡入
	# Logo 落下 (0.3s - 0.8s)
	tween.tween_property(_logo_title, "modulate", Color(1, 1, 1, 1), 0.5)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_logo_subtitle, "modulate", Color(1, 1, 1, 1), 0.5)

	# 按钮依次滑入 (0.8s - 1.2s)
	var buttons = [_new_game_btn, _continue_btn, _settings_btn, _credits_btn, _quit_btn]
	for i in range(buttons.size()):
		await get_tree().create_timer(0.08 * (i + 1)).timeout
		var btn = buttons[i]
		btn.modulate = Color(1, 1, 1, 0)
		var start_offset = btn.offset_top
		btn.offset_top = start_offset + 20
		var btn_tween = create_tween()
		btn_tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.15)
		btn_tween.tween_property(btn, "offset_top", start_offset, 0.3)
		btn_tween.set_ease(Tween.EASE_OUT)

	# 底部信息 (1.2s - 1.4s)
	await get_tree().create_timer(1.2).timeout
	var info_labels = [$ZoneC_Info/SaveInfoLabel, $ZoneC_Info/VersionLabel]
	for lbl in info_labels:
		if lbl != null:
			lbl.modulate = Color(1, 1, 1, 0)
			var info_tween = create_tween()
			info_tween.tween_property(lbl, "modulate", Color(1, 1, 1, 0.6), 0.2)


## 检测存档状态
func _check_save_status() -> void:
	_has_save = false  # TODO: 调用 SaveSystem.has_save()
	_save_realm = ""
	_save_region = ""

	if _has_save:
		_continue_btn.disabled = false
		_continue_btn.focus_mode = Control.FOCUS_ALL
		_save_info_label.text = "上次：%s · %s" % [_save_realm, _save_region]
		_save_info_label.visible = true
		# 默认焦点在"继续修炼"
		_continue_btn.grab_focus()
	else:
		_continue_btn.disabled = true
		_continue_btn.focus_mode = Control.FOCUS_NONE
		_save_info_label.text = "无修炼记录"
		_save_info_label.visible = true
		# 默认焦点在"开始新修炼"
		_new_game_btn.grab_focus()

	main_menu_loaded.emit(_has_save, _save_realm, _save_region)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP, KEY_DOWN:
				# 在按钮间导航（循环）
				var buttons = _get_focusable_buttons()
				var current_focus = get_viewport().gui_get_focus_owner()
				var idx = buttons.find(current_focus)
				if idx == -1:
					idx = 0
				if event.keycode == KEY_DOWN:
					idx = (idx + 1) % buttons.size()
				else:
					idx = (idx - 1 + buttons.size()) % buttons.size()
				buttons[idx].grab_focus()
				get_viewport().set_input_as_handled()
			KEY_ENTER:
				var focus = get_viewport().gui_get_focus_owner()
				if focus is Button and focus.disabled == false:
					focus.pressed.emit()
				get_viewport().set_input_as_handled()


## 获取可聚焦的按钮列表
func _get_focusable_buttons() -> Array[Button]:
	var result: Array[Button] = []
	var buttons = [_new_game_btn, _continue_btn, _settings_btn, _credits_btn, _quit_btn]
	for btn in buttons:
		if btn.focus_mode != Control.FOCUS_NONE:
			result.append(btn)
	return result


func _on_new_game_pressed() -> void:
	main_menu_new_game_selected.emit()
	# TODO: 加载开场引导场景


func _on_continue_pressed() -> void:
	if not _has_save:
		return
	main_menu_continue_selected.emit(1, _save_realm, _save_region)
	# TODO: 加载存档


func _on_settings_pressed() -> void:
	main_menu_settings_opened.emit()
	# TODO: 打开设置面板


func _on_credits_pressed() -> void:
	main_menu_credits_opened.emit()
	# TODO: 打开制作人员滚动字幕


func _on_quit_pressed() -> void:
	main_menu_quit_initiated.emit()
	_show_quit_confirm()


## 显示退出确认对话框
func _show_quit_confirm() -> void:
	# TODO: 使用全局对话框系统
	# 临时直接退出
	main_menu_quit_confirmed.emit()
	get_tree().quit()
