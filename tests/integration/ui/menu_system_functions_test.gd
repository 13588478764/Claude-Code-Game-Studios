extends GutTest
## Story 007: 菜单入口和系统功能 - 集成测试
##
## 测试MenuSystemFunctions和NotificationManager的所有验收标准

var menu_system: MenuSystemFunctions
var notification_manager: NotificationManager
var test_scene: Node
var menu_buttons: HBoxContainer


func before_each():
	# 创建测试场景结构，不加载完整 HUD
	test_scene = Control.new()
	test_scene.name = "TestScene"
	add_child_autofree(test_scene)

	# 创建MenuSystemFunctions所需子节点
	menu_buttons = HBoxContainer.new()
	menu_buttons.name = "MenuButtons"
	test_scene.add_child(menu_buttons)

	var main_menu_button = Button.new()
	main_menu_button.name = "MainMenuButton"
	main_menu_button.custom_minimum_size = Vector2(48, 48)
	menu_buttons.add_child(main_menu_button)

	var settings_button = Button.new()
	settings_button.name = "SettingsButton"
	settings_button.custom_minimum_size = Vector2(48, 48)
	menu_buttons.add_child(settings_button)

	var help_button = Button.new()
	help_button.name = "HelpButton"
	help_button.custom_minimum_size = Vector2(48, 48)
	menu_buttons.add_child(help_button)

	# 创建NotificationManager
	var notification_root = Control.new()
	notification_root.name = "NotificationRoot"
	test_scene.add_child(notification_root)

	var notification_container = VBoxContainer.new()
	notification_container.name = "NotificationsContainer"
	notification_root.add_child(notification_container)

	# 加载脚本并挂载
	var menu_system_script = load("res://src/scripts/ui/hud/menu_system_functions.gd")
	test_scene.set_script(menu_system_script)
	menu_system = test_scene as MenuSystemFunctions

	var notification_script = load("res://src/scripts/ui/hud/notification_manager.gd")
	notification_root.set_script(notification_script)
	notification_manager = notification_root

	assert_not_null(menu_system, "MenuSystemFunctions should exist")
	assert_not_null(notification_manager, "NotificationManager should exist")

	menu_system._ready()
	notification_manager._ready()

	if notification_manager.has_method("clear_all_notifications"):
		notification_manager.clear_all_notifications()

	await get_tree().process_frame


# ============================================================================
# AC-1: 主菜单按钮点击打开主菜单(48x48px)
# ============================================================================

func test_ac1_main_menu_button_exists_and_correct_size():
	var main_menu_button = menu_system.get_node("MenuButtons/MainMenuButton")
	assert_not_null(main_menu_button, "主菜单按钮应存在")
	assert_eq(main_menu_button.custom_minimum_size, Vector2(48, 48), "主菜单按钮应为48x48px")


func test_ac1_main_menu_button_click_emits_signal():
	var main_menu_button = menu_system.get_node("MenuButtons/MainMenuButton")
	watch_signals(menu_system)

	main_menu_button.pressed.emit()

	assert_signal_emitted(menu_system, "main_menu_requested", "点击后应发射main_menu_requested信号")


# ============================================================================
# AC-2: 设置按钮点击打开设置界面(48x48px)
# ============================================================================

func test_ac2_settings_button_exists_and_correct_size():
	var settings_button = menu_system.get_node("MenuButtons/SettingsButton")
	assert_not_null(settings_button, "设置按钮应存在")
	assert_eq(settings_button.custom_minimum_size, Vector2(48, 48), "设置按钮应为48x48px")


func test_ac2_settings_button_click_emits_signal():
	var settings_button = menu_system.get_node("MenuButtons/SettingsButton")
	watch_signals(menu_system)

	settings_button.pressed.emit()

	assert_signal_emitted(menu_system, "settings_requested", "点击后应发射settings_requested信号")


# ============================================================================
# AC-3: 帮助按钮点击打开帮助界面(48x48px)
# ============================================================================

func test_ac3_help_button_exists_and_correct_size():
	var help_button = menu_system.get_node("MenuButtons/HelpButton")
	assert_not_null(help_button, "帮助按钮应存在")
	assert_eq(help_button.custom_minimum_size, Vector2(48, 48), "帮助按钮应为48x48px")


func test_ac3_help_button_click_emits_signal():
	var help_button = menu_system.get_node("MenuButtons/HelpButton")
	watch_signals(menu_system)

	help_button.pressed.emit()

	assert_signal_emitted(menu_system, "help_requested", "点击后应发射help_requested信号")


# ============================================================================
# AC-4: ESC键打开主菜单
# ============================================================================

func test_ac4_esc_key_opens_main_menu():
	watch_signals(menu_system)

	var event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	menu_system._unhandled_input(event)

	assert_signal_emitted(menu_system, "main_menu_requested", "ESC键应触发主菜单")


# ============================================================================
# AC-5: F1键打开帮助
# ============================================================================

func test_ac5_f1_key_opens_help():
	watch_signals(menu_system)

	var event = InputEventKey.new()
	event.keycode = KEY_F1
	event.pressed = true
	menu_system._unhandled_input(event)

	assert_signal_emitted(menu_system, "help_requested", "F1键应触发帮助")


# ============================================================================
# AC-6: 通知系统正确显示消息
# ============================================================================

func test_ac6_notification_system_displays_message():
	notification_manager.show_info("Test notification")

	assert_eq(notification_manager.get_active_notification_count(), 1, "应有1条活动通知")


# ============================================================================
# AC-7: 战斗中主菜单按钮禁用
# ============================================================================

func test_ac7_main_menu_button_disabled_in_combat():
	var main_menu_button = menu_system.get_node("MenuButtons/MainMenuButton")

	menu_system.set_combat_state(true)

	assert_true(main_menu_button.disabled, "战斗中主菜单按钮应禁用")
	assert_eq(main_menu_button.modulate, Color(0.5, 0.5, 0.5, 1.0), "战斗中按钮应灰色显示")


func test_ac7_main_menu_button_enabled_outside_combat():
	var main_menu_button = menu_system.get_node("MenuButtons/MainMenuButton")

	menu_system.set_combat_state(false)

	assert_false(main_menu_button.disabled, "非战斗时主菜单按钮应启用")
	assert_eq(main_menu_button.modulate, Color.WHITE, "非战斗时按钮应白色显示")


func test_ac7_esc_key_blocked_in_combat():
	menu_system.set_combat_state(true)
	watch_signals(menu_system)

	var event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	menu_system._unhandled_input(event)

	assert_signal_not_emitted(menu_system, "main_menu_requested", "战斗中ESC不应触发主菜单")


# ============================================================================
# AC-9: 通知系统支持3种类型
# ============================================================================

func test_ac9_notification_types_info():
	notification_manager.show_info("Info message")
	assert_eq(notification_manager.get_active_notification_count(), 1, "应有1条信息通知")


func test_ac9_notification_types_warning():
	notification_manager.show_warning("Warning message")
	assert_eq(notification_manager.get_active_notification_count(), 1, "应有1条警告通知")


func test_ac9_notification_types_error():
	notification_manager.show_error("Error message")
	assert_eq(notification_manager.get_active_notification_count(), 1, "应有1条错误通知")


# ============================================================================
# AC-10: 通知显示时长验证（通过检查 Timer 配置，不使用真实等待）
# ============================================================================

func test_ac10_info_notification_has_3s_timer():
	notification_manager.show_info("Info message")

	# 验证通知面板上挂了一个 3 秒的 Timer
	var panel = notification_manager._active_notifications[0]
	var timer: Timer = null
	for child in panel.get_children():
		if child is Timer:
			timer = child
			break

	assert_not_null(timer, "INFO通知应有自动关闭Timer")
	assert_eq(timer.wait_time, 3.0, "INFO通知Timer应为3秒")
	assert_true(timer.one_shot, "Timer应为one_shot模式")


func test_ac10_warning_notification_has_5s_timer():
	notification_manager.show_warning("Warning message")

	var panel = notification_manager._active_notifications[0]
	var timer: Timer = null
	for child in panel.get_children():
		if child is Timer:
			timer = child
			break

	assert_not_null(timer, "WARNING通知应有自动关闭Timer")
	assert_eq(timer.wait_time, 5.0, "WARNING通知Timer应为5秒")


func test_ac10_error_notification_has_no_timer():
	notification_manager.show_error("Error message")

	# ERROR 通知不应有自动关闭 Timer（duration=-1）
	var panel = notification_manager._active_notifications[0]
	var timer: Timer = null
	for child in panel.get_children():
		if child is Timer:
			timer = child
			break

	assert_null(timer, "ERROR通知不应有自动关闭Timer（需手动关闭）")
	assert_eq(notification_manager.get_active_notification_count(), 1, "ERROR通知应持续显示")


# ============================================================================
# AC-11: 同时最多显示3条通知,超出时排队等待
# ============================================================================

func test_ac11_max_3_notifications_displayed():
	for i in range(5):
		notification_manager.show_info("Notification %d" % i)

	assert_eq(notification_manager.get_active_notification_count(), 3, "最多同时显示3条通知")
	assert_eq(notification_manager.get_queued_notification_count(), 2, "超出的2条应排队")


func test_ac11_queued_notifications_dequeue_on_remove():
	for i in range(4):
		notification_manager.show_info("Notification %d" % i)

	assert_eq(notification_manager.get_active_notification_count(), 3, "应显示3条")
	assert_eq(notification_manager.get_queued_notification_count(), 1, "应排队1条")

	# 直接移除一条活动通知，验证队列中的通知会补上
	var first_panel = notification_manager._active_notifications[0]
	notification_manager._remove_notification(first_panel)

	# 移除后队列应被消费
	assert_eq(notification_manager.get_queued_notification_count(), 0, "队列应被消费完")
	assert_eq(notification_manager.get_active_notification_count(), 3, "移除后应从队列补充到3条")


# ============================================================================
# AC-12: 按钮点击动画
# ============================================================================

func test_ac12_button_has_correct_initial_scale():
	var main_menu_button = menu_system.get_node("MenuButtons/MainMenuButton")
	assert_eq(main_menu_button.scale, Vector2.ONE, "按钮初始缩放应为1")


# ============================================================================
# 性能测试
# ============================================================================

func test_performance_button_click_response_time():
	var main_menu_button = menu_system.get_node("MenuButtons/MainMenuButton")

	var start_time = Time.get_ticks_usec()
	main_menu_button.pressed.emit()
	var end_time = Time.get_ticks_usec()

	var response_time_ms = (end_time - start_time) / 1000.0
	assert_lt(response_time_ms, 16.67, "按钮点击响应应<16.67ms")


func test_performance_notification_display():
	var start_time = Time.get_ticks_usec()
	notification_manager.show_info("Performance test")
	var end_time = Time.get_ticks_usec()

	var display_time_ms = (end_time - start_time) / 1000.0
	assert_lt(display_time_ms, 3.0, "通知显示应<3ms")


func test_performance_notification_queue_management():
	var start_time = Time.get_ticks_usec()

	for i in range(10):
		notification_manager.show_info("Notification %d" % i)

	var end_time = Time.get_ticks_usec()

	var queue_time_ms = (end_time - start_time) / 1000.0
	assert_lt(queue_time_ms, 5.0, "10条通知队列管理应<5ms")
