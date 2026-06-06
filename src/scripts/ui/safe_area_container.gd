## SafeAreaManager (Autoload)
## 自动适配 iOS 安全区 (刘海/底部横条/灵动岛)
## 作为全局单例, 提供安全区 margin 查询接口, 各面板自行调用
extends Node

## 安全区边距 (像素, 已按视口缩放)
var margin_left: float = 0.0
var margin_top: float = 0.0
var margin_right: float = 0.0
var margin_bottom: float = 0.0

signal safe_area_changed


func _ready() -> void:
	_update_safe_area()
	get_viewport().size_changed.connect(_update_safe_area)


func _update_safe_area() -> void:
	var safe_area: Rect2 = DisplayServer.get_display_safe_area()
	var screen_size: Vector2i = DisplayServer.screen_get_size()

	if safe_area.size == Vector2.ZERO or screen_size == Vector2i.ZERO:
		margin_left = 0.0
		margin_top = 0.0
		margin_right = 0.0
		margin_bottom = 0.0
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var scale_x: float = viewport_size.x / float(screen_size.x)
	var scale_y: float = viewport_size.y / float(screen_size.y)

	margin_left = safe_area.position.x * scale_x
	margin_top = safe_area.position.y * scale_y
	margin_right = (float(screen_size.x) - safe_area.end.x) * scale_x
	margin_bottom = (float(screen_size.y) - safe_area.end.y) * scale_y

	safe_area_changed.emit()


## 将安全区 margin 应用到一个 Control 节点
func apply_to_control(control: Control) -> void:
	control.offset_left = margin_left
	control.offset_top = margin_top
	control.offset_right = -margin_right
	control.offset_bottom = -margin_bottom
