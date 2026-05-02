extends PanelContainer
class_name ActionQueueUnit

## 行动队列单位UI组件
##
## 显示单个单位的头像和边框。
## 支持动态设置单位数据和边框颜色。

# ============================================================================
# 节点引用 - 使用@onready缓存
# ============================================================================

## 单位头像纹理矩形
@onready var unit_icon: TextureRect = $VBoxContainer/UnitIcon

## 单位名称标签
@onready var unit_name_label: Label = $VBoxContainer/UnitNameLabel

# ============================================================================
# 状态变量
# ============================================================================

## 当前单位数据
var _unit_data: Dictionary = {}

## 边框颜色
var _border_color: Color = Color.WHITE

## 节点是否已准备好
var _is_ready: bool = false

# ============================================================================
# 初始化
# ============================================================================

func _ready() -> void:
	_is_ready = true
	# 初始化UI样式
	_initialize_style()
	# 如果有待处理的数据，现在应用它们
	if not _unit_data.is_empty():
		_update_display()
	if _border_color != Color.WHITE:
		_apply_border_color()

## 初始化UI样式
func _initialize_style() -> void:
	# 设置面板样式
	if has_theme_stylebox("panel"):
		var panel_style = get_theme_stylebox("panel").duplicate()
		panel_style.border_color = _border_color
		add_theme_stylebox_override("panel", panel_style)

# ============================================================================
# 公共接口
# ============================================================================

## 设置单位数据
## @param unit_data: 单位数据字典 {unit_id, unit_name, is_player, icon_path}
func set_unit_data(unit_data: Dictionary) -> void:
	_unit_data = unit_data.duplicate()
	if _is_ready:
		_update_display()

## 设置边框颜色
## @param color: 边框颜色
func set_border_color(color: Color) -> void:
	_border_color = color
	if _is_ready:
		_apply_border_color()

# ============================================================================
# 更新逻辑
# ============================================================================

## 更新显示
func _update_display() -> void:
	# 更新单位名称
	if _unit_data.has("unit_name"):
		unit_name_label.text = _unit_data["unit_name"]
	
	# 加载单位头像
	if _unit_data.has("icon_path"):
		_load_unit_icon(_unit_data["icon_path"])

## 加载单位头像
## @param icon_path: 头像资源路径
func _load_unit_icon(icon_path: String) -> void:
	if icon_path.is_empty():
		_use_placeholder_icon()
		return
	
	# 尝试加载头像
	if ResourceLoader.exists(icon_path):
		var texture := load(icon_path) as Texture2D
		if texture:
			unit_icon.texture = texture
		else:
			push_warning("[ActionQueueUnit] Failed to load icon: %s" % icon_path)
			_use_placeholder_icon()
	else:
		push_warning("[ActionQueueUnit] Icon not found: %s" % icon_path)
		_use_placeholder_icon()

## 使用占位符图标
func _use_placeholder_icon() -> void:
	# 创建一个简单的占位符纹理(灰色方块)
	var placeholder = Image.create(64, 64, false, Image.FORMAT_RGB8)
	placeholder.fill(Color.GRAY)
	var texture = ImageTexture.create_from_image(placeholder)
	unit_icon.texture = texture

## 应用边框颜色
func _apply_border_color() -> void:
	# 获取或创建面板样式
	var panel_style: StyleBox
	if has_theme_stylebox("panel"):
		panel_style = get_theme_stylebox("panel").duplicate()
	else:
		panel_style = StyleBoxFlat.new()
	
	# 设置边框颜色
	if panel_style is StyleBoxFlat:
		panel_style.border_color = _border_color
		# Godot 4.x API: 分别设置每个边框
		panel_style.border_width_left = 3
		panel_style.border_width_right = 3
		panel_style.border_width_top = 3
		panel_style.border_width_bottom = 3
	
	add_theme_stylebox_override("panel", panel_style)

# ============================================================================
# 测试辅助函数
# ============================================================================

## 获取单位数据(用于测试)
func get_unit_data() -> Dictionary:
	return _unit_data.duplicate()

## 获取边框颜色(用于测试)
func get_border_color() -> Color:
	return _border_color

## 获取单位名称(用于测试)
func get_unit_name() -> String:
	return unit_name_label.text