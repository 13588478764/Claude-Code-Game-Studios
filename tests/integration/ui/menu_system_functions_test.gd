extends GutTest
## Story 007: 菜单入口和系统功能 - 集成测试
##
## 测试MenuSystemFunctions和NotificationManager的所有验收标准

var menu_system: MenuSystemFunctions
var notification_manager: NotificationManager
var test_scene: Node


func before_each():
	# 加载HUD场景
	var hud_scene = load("res://src/scenes/ui/hud/HUD.tscn")
	test_scene = hud_scene.instantiate()
	add_child_autofree(test_scene)
	
	# 获取MenuSystemFunctions和NotificationManager
	menu_system = test_scene.get_node("MenuSystemFunctions")
	notification_manager = test_scene.get_node("NotificationManager")
	
	assert_not_null(menu_system, "MenuSystemFunctions should exist")
	assert_not_null(notification_manager, "NotificationManager should exist")


# ============================================================================
# AC-1: 主菜单按钮点击打开主菜单(48x48px)
# ============================================================================

func test_ac1_main_menu_button_exists_and_correct_size():
	var main_menu_button = menu_system.get_node("MenuButtons/MainMenuButton")
	assert_not_null(main_menu_button, "Main menu button should exist")
	assert_eq(main_menu_button.custom_minimum_size, Vector2(48, 48), "Main menu button should be 48x48px")


func test_ac1_main_menu_button_click_emits_signal():
	var main_menu_button = menu_system.get_node("MenuButtons/MainMenuButton")
	watch_signals(menu_system)
	
	main_menu_button.pressed.emit()
	
	assert_signal_emitted(menu_system, "main_menu_requested", "Main menu requested signal should be emitted")


# ============================================================================
# AC-2: 设置按钮点击打开设置界面(48x48px)
# ============================================================================

func test_ac2_settings_button_exists_and_correct_size():
	var settings_button = menu_system.get_node("MenuButtons/SettingsButton")
	assert_not_null(settings_button, "Settings button should exist")
	assert_eq(settings_button.custom_minimum_size, Vector2(48, 48), "Settings button should be 48x48px")


func test_ac2_settings_button_click_emits_signal():
	var settings_button = menu_system.get_node("MenuButtons/SettingsButton")
	watch_signals(menu_system)
	
	settings_button.pressed.emit()
	
	assert_signal_emitted(menu_system, "settings_requested", "Settings requested signal should be emitted")


# ============================================================================
# AC-3: 帮助按钮点击打开帮助界面(48x48px)
# ============================================================================

func test_ac3_help_button_exists_and_correct_size():
	var help_button = menu_system.get_node("MenuButtons/HelpButton")
	assert_not_null(help_button, "Help button should exist")
	assert_eq(help_button.custom_minimum_size, Vector2(48, 48), "Help button should be 48x48px")


func test_ac3_help_button_click_emits_signal():
	var help_button = menu_system.get_node("MenuButtons/HelpButton")
	watch_signals(menu_system)
	
	help_button.pressed.emit()
	
	assert_signal_emitted(menu_system, "help_requested", "Help requested signal should be emitted")


# ============================================================================
# AC-4: ESC键打开主菜单
# ============================================================================

func test_ac4_esc_key_opens_main_menu():
	watch_signals(menu_system)
	
	# 模拟ESC键按下
	var event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	menu_system._input(event)
	
	assert_signal_emitted(menu_system, "main_menu_requested", "ESC key should trigger main menu")


# ============================================================================
# AC-5: F1键打开帮助
# ============================================================================

func test_ac5_f1_key_opens_help():
	watch_signals(menu_system)
	
	# 模拟F1键按下
	var event = InputEventKey.new()
	event.keycode = KEY_F1
	event.pressed = true
	menu_system._input(event)
	
	assert_signal_emitted(menu_system, "help_requested", "F1 key should trigger help")


# ============================================================================
# AC-6: 通知系统正确显示消息
# ============================================================================

func test_ac6_notification_system_displays_message():
	notification_manager.show_info("Test notification")
	
	assert_eq(notification_manager.get_active_notification_count(), 1, "Should have 1 active notification")


# ============================================================================
# AC-7: 战斗中主菜单按钮禁用,显示灰色且不可点击
# ============================================================================

func test_ac7_main_menu_button_disabled_in_combat():
	var main_menu_button = menu_system.get_node("MenuButtons/MainMenuButton")
	
	# 设置战斗状态
	menu_system.set_combat_state(true)
	
	assert_true(main_menu_button.disabled, "Main menu button should be disabled in combat")
	assert_eq(main_menu_button.modulate, Color(0.5, 0.5, 0.5, 1.0), "Main menu button should be gray in combat")


func test_ac7_main_menu_button_enabled_outside_combat():
	var main_menu_button = menu_system.get_node("MenuButtons/MainMenuButton")
	
	# 设置非战斗状态
	menu_system.set_combat_state(false)
	
	assert_false(main_menu_button.disabled, "Main menu button should be enabled outside combat")
	assert_eq(main_menu_button.modulate, Color.WHITE, "Main menu button should be white outside combat")


func test_ac7_esc_key_blocked_in_combat():
	menu_system.set_combat_state(true)
	watch_signals(menu_system)
	
	# 模拟ESC键按下
	var event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	menu_system._input(event)
	
	assert_signal_not_emitted(menu_system, "main_menu_requested", "ESC key should not trigger main menu in combat")


# ============================================================================
# AC-9: 通知系统支持3种类型:信息(蓝色)、警告(黄色)、错误(红色)
# ============================================================================

func test_ac9_notification_types_info():
	notification_manager.show_info("Info message")
	assert_eq(notification_manager.get_active_notification_count(), 1, "Should have 1 info notification")


func test_ac9_notification_types_warning():
	notification_manager.show_warning("Warning message")
	assert_eq(notification_manager.get_active_notification_count(), 1, "Should have 1 warning notification")


func test_ac9_notification_types_error():
	notification_manager.show_error("Error message")
	assert_eq(notification_manager.get_active_notification_count(), 1, "Should have 1 error notification")


# ============================================================================
# AC-10: 通知显示时长:信息3秒,警告5秒,错误持续到手动关闭
# ============================================================================

func test_ac10_info_notification_duration():
	notification_manager.show_info("Info message")
	
	# 等待3.5秒
	await get_tree().create_timer(3.5).timeout
	
	assert_eq(notification_manager.get_active_notification_count(), 0, "Info notification should auto-close after 3 seconds")


func test_ac10_warning_notification_duration():
	notification_manager.show_warning("Warning message")
	
	# 等待5.5秒
	await get_tree().create_timer(5.5).timeout
	
	assert_eq(notification_manager.get_active_notification_count(), 0, "Warning notification should auto-close after 5 seconds")


func test_ac10_error_notification_persists():
	notification_manager.show_error("Error message")
	
	# 等待10秒
	await get_tree().create_timer(10.0).timeout
	
	assert_eq(notification_manager.get_active_notification_count(), 1, "Error notification should not auto-close")


# ============================================================================
# AC-11: 同时最多显示3条通知,超出时排队等待
# ============================================================================

func test_ac11_max_3_notifications_displayed():
	# 添加5条通知
	for i in range(5):
		notification_manager.show_info("Notification %d" % i)
	
	assert_eq(notification_manager.get_active_notification_count(), 3, "Should display max 3 notifications")
	assert_eq(notification_manager.get_queued_notification_count(), 2, "Should queue 2 notifications")


func test_ac11_queued_notifications_display_after_close():
	# 添加4条通知
	for i in range(4):
		notification_manager.show_info("Notification %d" % i)
	
	assert_eq(notification_manager.get_active_notification_count(), 3, "Should display 3 notifications")
	assert_eq(notification_manager.get_queued_notification_count(), 1, "Should queue 1 notification")
	
	# 等待第一条通知关闭(3秒)
	await get_tree().create_timer(3.5).timeout
	
	# 队列中的通知应该显示
	assert_eq(notification_manager.get_active_notification_count(), 3, "Queued notification should be displayed")
	assert_eq(notification_manager.get_queued_notification_count(), 0, "Queue should be empty")


# ============================================================================
# AC-12: 按钮点击有0.1秒的按下动画和音效反馈
# ============================================================================

func test_ac12_button_press_animation():
	var main_menu_button = menu_system.get_node("MenuButtons/MainMenuButton")
	
	# 点击按钮
	main_menu_button.pressed.emit()
	
	# 等待动画完成(0.1秒)
	await get_tree().create_timer(0.15).timeout
	
	# 按钮应该恢复到原始大小
	assert_eq(main_menu_button.scale, Vector2.ONE, "Button should return to original scale after animation")


# ============================================================================
# 性能测试
# ============================================================================

func test_performance_button_click_response_time():
	var main_menu_button = menu_system.get_node("MenuButtons/MainMenuButton")
	
	var start_time = Time.get_ticks_usec()
	main_menu_button.pressed.emit()
	var end_time = Time.get_ticks_usec()
	
	var response_time_ms = (end_time - start_time) / 1000.0
	assert_lt(response_time_ms, 16.67, "Button click response time should be < 16.67ms (60FPS)")


func test_performance_notification_display():
	var start_time = Time.get_ticks_usec()
	notification_manager.show_info("Performance test")
	var end_time = Time.get_ticks_usec()
	
	var display_time_ms = (end_time - start_time) / 1000.0
	assert_lt(display_time_ms, 1.0, "Notification display time should be < 1ms")


func test_performance_notification_queue_management():
	var start_time = Time.get_ticks_usec()
	
	# 添加10条通知
	for i in range(10):
		notification_manager.show_info("Notification %d" % i)
	
	var end_time = Time.get_ticks_usec()
	
	var queue_time_ms = (end_time - start_time) / 1000.0
	assert_lt(queue_time_ms, 2.0, "Notification queue management should be < 2ms")