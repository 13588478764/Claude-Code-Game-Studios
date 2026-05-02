extends Control
class_name MenuSystemFunctions
## MenuSystemFunctions - 菜单系统功能控制器
##
## 负责处理HUD的菜单入口和系统功能:
## - ESC键打开主菜单
## - F1键打开帮助
## - 菜单按钮(主菜单/设置/帮助)的点击处理
## - 战斗模式下禁用主菜单按钮
##
## 架构来源: ADR-002 (HUD架构模式)
## Story: Story 007 - 菜单入口和系统功能

## 信号定义
signal main_menu_requested
signal settings_requested
signal help_requested

## 菜单按钮节点引用
@onready var main_menu_button: Button = get_node_or_null("MenuButtons/MainMenuButton")
@onready var settings_button: Button = get_node_or_null("MenuButtons/SettingsButton")
@onready var help_button: Button = get_node_or_null("MenuButtons/HelpButton")

## 当前是否在战斗中
var _is_in_combat: bool = false

## 输入优先级标记(用于AC-8: HUD快捷键优先级最低)
var _input_priority: int = 100  # 数值越大优先级越低

## 菜单打开前的模式(用于返回)
var _previous_mode: String = "exploration"

## 当前是否在菜单模式
var _is_in_menu_mode: bool = false


func _ready() -> void:
	# 设置焦点模式以接收输入事件
	set_process_input(true)
	
	# 验证节点存在
	_validate_nodes()
	
	# 连接按钮信号
	_connect_button_signals()
	
	# 连接GameEvents信号
	_connect_game_events()
	
	# 设置初始状态
	_update_button_states()
	
	print("[MenuSystemFunctions] Initialized - Input processing enabled")


func _unhandled_input(event: InputEvent) -> void:
	# 使用_unhandled_input确保在其他节点未处理输入时才响应
	# AC-8: 快捷键优先级最低
	
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				print("[MenuSystemFunctions] ESC key pressed - menu mode: %s" % _is_in_menu_mode)
				# 如果已经在菜单模式,ESC键返回游戏
				if _is_in_menu_mode:
					_handle_return_to_game()
				else:
					# AC-4: ESC键打开主菜单
					_handle_main_menu_request()
				get_viewport().set_input_as_handled()
			
			KEY_F1:
				print("[MenuSystemFunctions] F1 key pressed")
				# AC-5: F1键打开帮助
				_handle_help_request()
				get_viewport().set_input_as_handled()


## 验证必需节点是否存在
func _validate_nodes() -> void:
	if main_menu_button == null:
		push_warning("[MenuSystemFunctions] MainMenuButton not found")
	if settings_button == null:
		push_warning("[MenuSystemFunctions] SettingsButton not found")
	if help_button == null:
		push_warning("[MenuSystemFunctions] HelpButton not found")


## 连接按钮信号
func _connect_button_signals() -> void:
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_button_pressed)
	if help_button:
		help_button.pressed.connect(_on_help_button_pressed)


## 连接GameEvents信号
func _connect_game_events() -> void:
	if GameEvents == null:
		push_error("[MenuSystemFunctions] GameEvents singleton not found!")
		return
	
	# 监听战斗状态变化
	GameEvents.combat_started.connect(_on_combat_started)
	GameEvents.combat_ended.connect(_on_combat_ended)
	
	# 监听系统模式变化
	GameEvents.system_mode_changed.connect(_on_system_mode_changed)


## 处理主菜单请求
func _handle_main_menu_request() -> void:
	# AC-7: 战斗中主菜单按钮禁用
	if _is_in_combat:
		print("[MenuSystemFunctions] Main menu disabled during combat")
		# 发送警告通知
		GameEvents.system_notification.emit("warning", "战斗中无法打开主菜单")
		return
	
	print("[MenuSystemFunctions] Main menu requested")
	main_menu_requested.emit()
	
	# 发送信息通知
	GameEvents.system_notification.emit("info", "主菜单已打开")
	
	# 切换到菜单模式
	GameEvents.system_mode_changed.emit("menu")


## 处理设置请求
func _handle_settings_request() -> void:
	print("[MenuSystemFunctions] Settings requested")
	settings_requested.emit()
	
	# 发送信息通知
	GameEvents.system_notification.emit("info", "设置界面已打开")
	
	# 切换到菜单模式
	GameEvents.system_mode_changed.emit("menu")


## 处理帮助请求
func _handle_help_request() -> void:
	print("[MenuSystemFunctions] Help requested")
	help_requested.emit()
	
	# 发送信息通知
	GameEvents.system_notification.emit("info", "帮助界面已打开")
	
	# 切换到菜单模式
	GameEvents.system_mode_changed.emit("menu")


## 处理返回游戏请求
func _handle_return_to_game() -> void:
	print("[MenuSystemFunctions] Returning to game - previous mode: %s" % _previous_mode)
	
	# 恢复到之前的模式
	GameEvents.system_mode_changed.emit(_previous_mode)


## 更新按钮状态(根据战斗状态)
func _update_button_states() -> void:
	if main_menu_button == null:
		return
	
	# AC-7: 战斗中主菜单按钮禁用,显示灰色且不可点击
	main_menu_button.disabled = _is_in_combat
	
	# 设置按钮颜色
	if _is_in_combat:
		main_menu_button.modulate = Color(0.5, 0.5, 0.5, 1.0)  # 灰色
	else:
		main_menu_button.modulate = Color.WHITE


## 播放按钮按下动画
## AC-12: 按钮点击有0.1秒的按下动画
func _play_button_press_animation(button: Button) -> void:
	if button == null:
		return
	
	# 创建Tween动画
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 缩放到0.9倍
	tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.05)
	# 然后恢复到1.0倍
	tween.chain().tween_property(button, "scale", Vector2.ONE, 0.05)
	
	# 播放音效(由音频系统负责)
	# 注意: AudioSystem是自动加载的单例,如果不存在则跳过
	var audio_system = get_node_or_null("/root/AudioSystem")
	if audio_system and audio_system.has_method("play_ui_sound"):
		audio_system.play_ui_sound("button_click")


# ============================================================================
# 信号处理函数
# ============================================================================

func _on_main_menu_button_pressed() -> void:
	# AC-1: 主菜单按钮点击打开主菜单
	_play_button_press_animation(main_menu_button)
	_handle_main_menu_request()


func _on_settings_button_pressed() -> void:
	# AC-2: 设置按钮点击打开设置界面
	_play_button_press_animation(settings_button)
	_handle_settings_request()


func _on_help_button_pressed() -> void:
	# AC-3: 帮助按钮点击打开帮助界面
	_play_button_press_animation(help_button)
	_handle_help_request()


func _on_combat_started() -> void:
	_is_in_combat = true
	_update_button_states()
	print("[MenuSystemFunctions] Combat started - main menu button disabled")


func _on_combat_ended(_victory: bool, _rewards: Dictionary) -> void:
	_is_in_combat = false
	_update_button_states()
	print("[MenuSystemFunctions] Combat ended - main menu button enabled")


func _on_system_mode_changed(mode: String) -> void:
	# 跟踪菜单状态
	if mode == "menu":
		# 保存进入菜单前的模式
		if not _is_in_menu_mode:
			_previous_mode = "combat" if _is_in_combat else "exploration"
		_is_in_menu_mode = true
		print("[MenuSystemFunctions] Entered menu mode (previous: %s)" % _previous_mode)
	else:
		_is_in_menu_mode = false
		print("[MenuSystemFunctions] Exited menu mode (current: %s)" % mode)


# ============================================================================
# 公共API
# ============================================================================

## 获取当前是否在战斗中
func is_in_combat() -> bool:
	return _is_in_combat


## 手动设置战斗状态(用于测试)
func set_combat_state(in_combat: bool) -> void:
	_is_in_combat = in_combat
	_update_button_states()
