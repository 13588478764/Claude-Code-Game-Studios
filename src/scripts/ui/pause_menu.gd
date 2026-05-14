## 暂停菜单控制器
## 对应 UX Spec: design/ux/pause-menu.md
## Z-index = 260 (在HUD之上、奇遇面板之下)

extends CanvasLayer

## 当暂停菜单打开时发出
signal pause_menu_opened(game_context: String, current_area: String, game_time: String)
## 当暂停菜单关闭（继续游戏）时发出
signal pause_menu_closed_continue
## 当保存进度时发出
signal pause_menu_save_initiated
## 当保存成功时发出
signal pause_menu_save_succeeded(save_slot_id: int, save_timestamp: String)
## 当保存失败时发出
signal pause_menu_save_failed(error_reason: String)
## 当读取存档时发出
signal pause_menu_load_initiated(save_slot_id: int)
## 当读取成功时发出
signal pause_menu_load_succeeded(save_slot_id: int)
## 当设置打开时发出
signal pause_menu_settings_opened
## 当设置关闭时发出
signal pause_menu_settings_closed(changes_applied: bool)
## 当返回主菜单时发出
signal pause_menu_return_to_main(saved_before_exit: bool)
## 当退出游戏时发出
signal pause_menu_quit_initiated
## 当退出确认时发出
signal pause_menu_quit_confirmed(saved_before_exit: bool)
## 当退出取消时发出
signal pause_menu_quit_cancelled

## 场景引用
@onready var _panel: PanelContainer = $PanelContainer
@onready var _continue_btn: Button = $PanelContainer/VBoxContainer/ContinueButton
@onready var _save_btn: Button = $PanelContainer/VBoxContainer/SaveButton
@onready var _load_btn: Button = $PanelContainer/VBoxContainer/LoadButton
@onready var _settings_btn: Button = $PanelContainer/VBoxContainer/SettingsButton
@onready var _return_btn: Button = $PanelContainer/VBoxContainer/ReturnButton
@onready var _quit_btn: Button = $PanelContainer/VBoxContainer/QuitButton
@onready var _location_hint: Label = $PanelContainer/VBoxContainer/LocationHint

## 当前游戏区域名
var _current_area: String = "青云山"
## 游戏内时间
var _game_time: String = "未时三刻"
## 是否有存档
var _has_save: bool = false
## 子面板是否打开（存档列表/设置/对话框）
var _subpanel_open: bool = false
## 设置面板实例
var _settings_panel: Node = null
## 存档槽位面板实例
var _save_slot_panel: Node = null


func _ready() -> void:
	# 暂停时仍需响应输入
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 初始隐藏
	visible = false
	_panel.modulate = Color(1, 1, 1, 0)

	# 连接按钮信号
	_continue_btn.pressed.connect(_on_continue_pressed)
	_save_btn.pressed.connect(_on_save_pressed)
	_load_btn.pressed.connect(_on_load_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_return_btn.pressed.connect(_on_return_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)

	_update_location_hint()
	_update_save_availability()


## 打开暂停菜单
func open_menu(area_name: String = "", game_time_str: String = "") -> void:
	if area_name != "":
		_current_area = area_name
	if game_time_str != "":
		_game_time = game_time_str

	visible = true
	_update_location_hint()
	_update_save_availability()

	# 暂停游戏逻辑
	get_tree().paused = true

	# 淡入动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.2)

	# 默认焦点在"继续修炼"
	_continue_btn.grab_focus()

	pause_menu_opened.emit("gameplay", _current_area, _game_time)


## 关闭暂停菜单（继续游戏）
func close_menu() -> void:
	_subpanel_open = false

	# 淡出动画
	var tween = create_tween()
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 0), 0.15)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func() -> void:
		visible = false
		get_tree().paused = false
	)

	pause_menu_closed_continue.emit()


## 更新存档状态提示
func update_save_status(has_save: bool) -> void:
	_has_save = has_save
	_update_save_availability()


## 更新区域和时间提示
func _update_location_hint() -> void:
	_location_hint.text = "当前：%s · %s" % [_current_area, _game_time]
	_location_hint.visible = _current_area != ""


## 根据是否有存档更新按钮状态
func _update_save_availability() -> void:
	var save_sys = get_node_or_null("/root/SaveSystem")
	if save_sys:
		_has_save = false
		for i in range(1, save_sys.MAX_SLOTS + 1):
			if save_sys.has_save(i):
				_has_save = true
				break

	if not _has_save:
		_load_btn.disabled = true
		_load_btn.focus_mode = Control.FOCUS_NONE
	else:
		_load_btn.disabled = false
		_load_btn.focus_mode = Control.FOCUS_ALL


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				if _subpanel_open:
					# 子面板打开时关闭子面板
					_on_subpanel_closed()
				else:
					close_menu()
				get_viewport().set_input_as_handled()


## 继续游戏
func _on_continue_pressed() -> void:
	close_menu()


## 保存进度 — 打开槽位选择面板
func _on_save_pressed() -> void:
	_subpanel_open = true
	_ensure_save_slot_panel()
	_save_slot_panel.open_save()


## 读取存档 — 打开槽位选择面板
func _on_load_pressed() -> void:
	if not _has_save:
		return
	_subpanel_open = true
	_ensure_save_slot_panel()
	_save_slot_panel.open_load()


## 设置
func _on_settings_pressed() -> void:
	pause_menu_settings_opened.emit()
	_subpanel_open = true
	_load_settings_panel()
	if _settings_panel != null:
		_settings_panel.open_settings()
		if not _settings_panel.settings_closed.is_connected(_on_settings_closed):
			_settings_panel.settings_closed.connect(_on_settings_closed)

func _on_settings_closed() -> void:
	pause_menu_settings_closed.emit(true)
	_subpanel_open = false


## 返回主菜单
func _on_return_pressed() -> void:
	_show_confirm_dialog(
		"确认返回主菜单？",
		"当前进度将自动保存",
		["保存并返回", "不保存直接返回", "取消"],
		func(result: int) -> void:
			if result == 0:
				_do_save()
				await get_tree().create_timer(0.5).timeout
				_return_to_main_menu(true)
			elif result == 1:
				_return_to_main_menu(false)
	)


## 执行返回主菜单
func _return_to_main_menu(saved: bool) -> void:
	get_tree().paused = false
	visible = false

	# 通知 GameLoopManager 返回菜单状态
	var game_loop: Node = get_node_or_null("/root/GameLoopManager")
	if game_loop and game_loop.has_method("return_to_menu"):
		game_loop.return_to_menu()

	# 显示主菜单
	var main_menu: Control = get_node_or_null("/root/MainGameUI/MainMenu")
	if main_menu and main_menu.has_method("show_menu"):
		main_menu.show_menu()
	elif main_menu:
		main_menu.visible = true

	pause_menu_return_to_main.emit(saved)


## 退出游戏
func _on_quit_pressed() -> void:
	_show_confirm_dialog(
		"确认退出修炼？",
		"当前进度将自动保存",
		["保存并退出", "取消"],
		func(result: int) -> void:
			if result == 0:
				# 保存并退出
				_do_save()
				await get_tree().create_timer(0.5).timeout
				pause_menu_quit_confirmed.emit(true)
				get_tree().quit()
			# result == 1: 取消
			if result == 1:
				pause_menu_quit_cancelled.emit()
	)


## 执行保存操作
func _do_save(slot: int = 1) -> void:
	pause_menu_save_initiated.emit()
	var save_sys = get_node_or_null("/root/SaveSystem")
	if save_sys:
		if save_sys.save_to_slot(slot):
			pause_menu_save_succeeded.emit(slot, Time.get_datetime_string_from_system())
			_has_save = true
			_update_save_availability()
			_show_save_success_notification()
		else:
			pause_menu_save_failed.emit("保存失败")
	else:
		pause_menu_save_failed.emit("存档系统不可用")


## 执行读取操作
func _do_load(slot: int = 1) -> void:
	pause_menu_load_initiated.emit(slot)
	var save_sys = get_node_or_null("/root/SaveSystem")
	if save_sys and save_sys.load_from_slot(slot):
		pause_menu_load_succeeded.emit(slot)
		close_menu()
	else:
		push_warning("[PauseMenu] 读取存档失败")


## 初始化存档槽位面板
func _ensure_save_slot_panel() -> void:
	if _save_slot_panel != null:
		return
	var scene = load("res://src/scenes/ui/save_slot_panel.tscn")
	if scene == null:
		push_warning("[PauseMenu] 无法加载存档槽位面板")
		return
	_save_slot_panel = scene.instantiate()
	add_child(_save_slot_panel)
	_save_slot_panel.slot_selected.connect(_on_slot_selected)
	_save_slot_panel.slot_panel_cancelled.connect(_on_subpanel_closed)


## 槽位选择回调
func _on_slot_selected(slot: int) -> void:
	_subpanel_open = false
	if _save_slot_panel._mode == _save_slot_panel.Mode.SAVE:
		_do_save(slot)
	else:
		_do_load(slot)


## 子面板关闭处理
func _on_subpanel_closed() -> void:
	_subpanel_open = false


## 显示保存成功通知
func _show_save_success_notification() -> void:
	_location_hint.text = "✓ 修炼进度已保存"
	_location_hint.visible = true
	await get_tree().create_timer(1.5).timeout
	_update_location_hint()


## 显示确认对话框
## @param title: 对话框标题
## @param description: 描述文字
## @param button_labels: 按钮文字数组
## @param callback: 选择结果回调（按钮索引）
func _show_confirm_dialog(
	title: String,
	description: String,
	button_labels: PackedStringArray,
	callback: Callable
) -> void:
	# TODO: 使用全局对话框系统显示确认对话框
	# 遵循 interaction-patterns.md 确认对话框模式
	# Z-index=400（奇遇内对话框）
	# 默认焦点在第一个按钮（确认按钮）
	print("[PauseMenu] Confirm dialog: %s" % title)
	print("[PauseMenu] Buttons: %s" % button_labels)
	# 模拟回调（默认选择第一个按钮，即确认）
	callback.call(0)


## 加载设置面板实例
func _load_settings_panel() -> void:
	if _settings_panel != null:
		return
	var scene = load("res://src/scenes/ui/settings_panel.tscn")
	if scene != null:
		_settings_panel = scene.instantiate()
		add_child(_settings_panel)
	else:
		push_warning("无法加载设置面板场景")
