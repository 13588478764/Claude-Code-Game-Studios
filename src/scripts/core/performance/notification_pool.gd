## NotificationPool - 通知面板对象池
## 预分配10个通知面板，减少GC压力
class_name NotificationPool
extends ObjectPool

## 创建NotificationPool实例
static func create() -> NotificationPool:
	var pool = NotificationPool.new(10, _create_notification, _reset_notification)
	return pool

## 创建通知面板对象
static func _create_notification() -> Node:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 60)
	
	# 添加背景样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	style_box.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style_box)
	
	# 添加VBoxContainer用于布局
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# 添加标题Label
	var title_label = Label.new()
	title_label.text = "Notification"
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title_label)
	
	# 添加内容Label
	var content_label = Label.new()
	content_label.text = "Content"
	content_label.add_theme_font_size_override("font_size", 12)
	content_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(content_label)
	
	# 存储引擎
	panel.set_meta("title_label", title_label)
	panel.set_meta("content_label", content_label)
	panel.set_meta("notification_type", "info")  # info, warning, error, success
	panel.set_meta("duration", 3.0)
	panel.set_meta("elapsed_time", 0.0)
	
	return panel

## 重置通知面板
static func _reset_notification(panel: Node) -> void:
	if not panel:
		return
	
	# 隐藏面板
	panel.visible = false
	
	# 重置数据
	panel.set_meta("notification_type", "info")
	panel.set_meta("duration", 3.0)
	panel.set_meta("elapsed_time", 0.0)
	
	# 重置标签
	var title_label = panel.get_meta("title_label")
	if title_label:
		title_label.text = "Notification"
	
	var content_label = panel.get_meta("content_label")
	if content_label:
		content_label.text = "Content"

## 获取通知面板
func acquire_notification(title: String, content: String, notification_type: String = "info", duration: float = 3.0) -> Node:
	var panel = acquire()
	
	if panel:
		# 设置数据
		panel.set_meta("notification_type", notification_type)
		panel.set_meta("duration", duration)
		panel.set_meta("elapsed_time", 0.0)
		panel.visible = true
		
		# 设置标题和内容
		var title_label = panel.get_meta("title_label")
		if title_label:
			title_label.text = title
		
		var content_label = panel.get_meta("content_label")
		if content_label:
			content_label.text = content
		
		# 根据类型设置颜色
		_set_notification_color(panel, notification_type)
	
	return panel

## 释放通知面板
func release_notification(panel: Node) -> void:
	release(panel)

## 设置通知颜色
func _set_notification_color(panel: Node, notification_type: String) -> void:
	if not panel:
		return
	
	var style_box = StyleBoxFlat.new()
	style_box.set_corner_radius_all(5)
	
	match notification_type:
		"warning":
			style_box.bg_color = Color(0.8, 0.6, 0.2, 0.9)
		"error":
			style_box.bg_color = Color(0.8, 0.2, 0.2, 0.9)
		"success":
			style_box.bg_color = Color(0.2, 0.8, 0.2, 0.9)
		_:  # info
			style_box.bg_color = Color(0.2, 0.2, 0.8, 0.9)
	
	panel.add_theme_stylebox_override("panel", style_box)

## 获取通知类型
func get_notification_type(panel: Node) -> String:
	if not panel:
		return "info"
	return panel.get_meta("notification_type", "info")

## 更新通知时间
func update_notification_time(panel: Node, delta: float) -> void:
	if not panel:
		return
	
	var elapsed_time = panel.get_meta("elapsed_time", 0.0)
	var duration = panel.get_meta("duration", 3.0)
	
	elapsed_time += delta
	panel.set_meta("elapsed_time", elapsed_time)
	
	# 计算透明度（从1到0）
	var progress = elapsed_time / duration
	var alpha = 1.0 - progress
	
	# 更新面板透明度
	var style_box = panel.get_theme_stylebox("panel")
	if style_box:
		var color = style_box.bg_color
		color.a = alpha
		style_box.bg_color = color

## 是否通知已过期
func is_notification_expired(panel: Node) -> bool:
	if not panel:
		return true
	
	var elapsed_time = panel.get_meta("elapsed_time", 0.0)
	var duration = panel.get_meta("duration", 3.0)
	
	return elapsed_time >= duration

## 获取通知的剩余时间
func get_remaining_time(panel: Node) -> float:
	if not panel:
		return 0.0
	
	var elapsed_time = panel.get_meta("elapsed_time", 0.0)
	var duration = panel.get_meta("duration", 3.0)
	
	return max(0.0, duration - elapsed_time)