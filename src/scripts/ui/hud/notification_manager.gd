extends Control
class_name NotificationManager
## NotificationManager - 通知系统管理器
##
## 负责管理HUD的通知显示:
## - 支持3种通知类型(信息/警告/错误)
## - 不同类型有不同的显示时长
## - 最多同时显示3条通知,超出时排队等待
## - 淡入淡出动画
##
## 架构来源: ADR-002 (HUD架构模式)
## Story: Story 007 - 菜单入口和系统功能

## 通知类型枚举
enum NotificationType {
	INFO,     ## 信息 - 蓝色 - 3秒
	WARNING,  ## 警告 - 黄色 - 5秒
	ERROR     ## 错误 - 红色 - 持续到手动关闭
}

## 通知数据结构
class NotificationData:
	var type: NotificationType
	var message: String
	var duration: float
	
	func _init(p_type: NotificationType, p_message: String) -> void:
		type = p_type
		message = p_message
		
		# 根据类型设置持续时间
		match type:
			NotificationType.INFO:
				duration = 3.0  # AC-10: 信息3秒
			NotificationType.WARNING:
				duration = 5.0  # AC-10: 警告5秒
			NotificationType.ERROR:
				duration = -1.0  # AC-10: 错误持续到手动关闭

## 通知容器
var notifications_container: VBoxContainer = null

## 当前显示的通知列表
var _active_notifications: Array[Control] = []

## 通知队列(等待显示的通知)
var _notification_queue: Array[NotificationData] = []

## 最大同时显示数量
const MAX_VISIBLE_NOTIFICATIONS: int = 3  # AC-11


func _ready() -> void:
	# 连接GameEvents信号
	_connect_game_events()

	# 初始化容器
	_ensure_container()

	print("[NotificationManager] Initialized")


## 懒加载：确保 notifications_container 已初始化。
## _ready() 和 _display_notification() 都会调用此方法，
## 防止在 _ready() 完成前就被调用 show_notification 时空引用崩溃。
func _ensure_container() -> void:
	if notifications_container != null and is_instance_valid(notifications_container):
		return
	notifications_container = get_node_or_null("NotificationsContainer")
	if notifications_container == null:
		notifications_container = VBoxContainer.new()
		notifications_container.name = "NotificationsContainer"
		# 仅当本节点已经在场景树中时才能 add_child
		if is_inside_tree():
			add_child(notifications_container)


func _connect_game_events() -> void:
	if GameEvents == null:
		push_error("[NotificationManager] GameEvents singleton not found!")
		return
	
	# 监听系统通知信号
	if GameEvents.has_signal("system_notification"):
		GameEvents.system_notification.connect(_on_system_notification)


## 显示通知
## AC-6: 通知系统正确显示消息
## AC-9: 通知系统支持3种类型
func show_notification(type: NotificationType, message: String) -> void:
	var notification_data = NotificationData.new(type, message)
	
	# AC-11: 同时最多显示3条通知,超出时排队等待
	if _active_notifications.size() >= MAX_VISIBLE_NOTIFICATIONS:
		_notification_queue.append(notification_data)
		print("[NotificationManager] Notification queued: %s" % message)
		return
	
	_display_notification(notification_data)


## 显示信息通知(蓝色,3秒)
func show_info(message: String) -> void:
	show_notification(NotificationType.INFO, message)


## 显示警告通知(黄色,5秒)
func show_warning(message: String) -> void:
	show_notification(NotificationType.WARNING, message)


## 显示错误通知(红色,持续到手动关闭)
func show_error(message: String) -> void:
	show_notification(NotificationType.ERROR, message)


## 内部方法: 显示通知面板
func _display_notification(data: NotificationData) -> void:
	# 防御性懒加载：调用方可能在 _ready() 完成之前就调用 show_notification
	# （特别是在测试 / autoload 早期初始化的场景中），此时容器还是 null
	_ensure_container()
	if notifications_container == null:
		push_warning("[NotificationManager] notifications_container 仍为 null，跳过 _display_notification")
		return
	
	# 创建通知面板
	var notification_panel = _create_notification_panel(data)
	
	# 添加到容器
	notifications_container.add_child(notification_panel)
	_active_notifications.append(notification_panel)
	
	# 淡入动画
	_play_fade_in_animation(notification_panel)
	
	# 设置自动关闭定时器(如果不是错误类型)
	if data.duration > 0:
		_setup_auto_close_timer(notification_panel, data.duration)
	
	print("[NotificationManager] Notification displayed: %s (type: %d)" % [data.message, data.type])


## 创建通知面板
func _create_notification_panel(data: NotificationData) -> Control:
	# 创建面板容器
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 60)
	
	# 设置背景颜色(根据类型)
	var style_box = StyleBoxFlat.new()
	match data.type:
		NotificationType.INFO:
			style_box.bg_color = Color(0.2, 0.4, 0.8, 0.9)  # 蓝色
		NotificationType.WARNING:
			style_box.bg_color = Color(0.8, 0.6, 0.2, 0.9)  # 黄色
		NotificationType.ERROR:
			style_box.bg_color = Color(0.8, 0.2, 0.2, 0.9)  # 红色
	
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style_box)
	
	# 创建水平容器
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	# 创建消息标签
	var label = Label.new()
	label.text = data.message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	# 如果是错误类型,添加关闭按钮
	if data.type == NotificationType.ERROR:
		var close_button = Button.new()
		close_button.text = "X"
		close_button.custom_minimum_size = Vector2(30, 30)
		close_button.pressed.connect(func(): _close_notification(panel))
		hbox.add_child(close_button)
	
	# 存储通知数据
	panel.set_meta("notification_data", data)
	
	return panel


## 播放淡入动画
func _play_fade_in_animation(panel: Control) -> void:
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)


## 播放淡出动画并关闭
func _play_fade_out_animation(panel: Control) -> void:
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): _remove_notification(panel))


## 设置自动关闭定时器
func _setup_auto_close_timer(panel: Control, duration: float) -> void:
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): _close_notification(panel))
	panel.add_child(timer)
	timer.start()


## 关闭通知
func _close_notification(panel: Control) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	
	_play_fade_out_animation(panel)


## 移除通知
func _remove_notification(panel: Control) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	
	# 从活动列表中移除
	_active_notifications.erase(panel)
	
	# 删除节点
	panel.queue_free()
	
	# 处理队列中的下一个通知
	_process_notification_queue()


## 处理通知队列
func _process_notification_queue() -> void:
	if _notification_queue.is_empty():
		return
	
	if _active_notifications.size() < MAX_VISIBLE_NOTIFICATIONS:
		var next_notification = _notification_queue.pop_front()
		_display_notification(next_notification)


## 清除所有通知
func clear_all_notifications() -> void:
	for panel in _active_notifications:
		if is_instance_valid(panel):
			panel.queue_free()
	
	_active_notifications.clear()
	_notification_queue.clear()


# ============================================================================
# 信号处理函数
# ============================================================================

func _on_system_notification(type: String, message: String) -> void:
	# 将字符串类型转换为枚举
	var notification_type: NotificationType
	match type.to_lower():
		"info", "information":
			notification_type = NotificationType.INFO
		"warning", "warn":
			notification_type = NotificationType.WARNING
		"error", "err":
			notification_type = NotificationType.ERROR
		_:
			notification_type = NotificationType.INFO
	
	show_notification(notification_type, message)


# ============================================================================
# 公共API
# ============================================================================

## 获取当前活动通知数量
func get_active_notification_count() -> int:
	return _active_notifications.size()


## 获取队列中的通知数量
func get_queued_notification_count() -> int:
	return _notification_queue.size()


## 获取总通知数量
func get_total_notification_count() -> int:
	return _active_notifications.size() + _notification_queue.size()