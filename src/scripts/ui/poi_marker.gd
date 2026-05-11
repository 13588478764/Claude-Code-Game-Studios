## PoiMarker
## 兴趣点标记脚本
## 用于在小地图和世界中显示兴趣点标记
##
## 主要功能：
## - 待补充

extends Node

class_name PoiMarker

# ============================================================================
# 常量定义
# ============================================================================

# ============================================================================
# 信号定义
# ============================================================================

# ============================================================================
# 成员变量
# ============================================================================

# ============================================================================
# 生命周期方法
# ============================================================================

# ============================================================================
# 公共方法
# ============================================================================

# ============================================================================
# 私有方法
# ============================================================================

# 信号定义
signal poi_clicked(poi_id: String)

# 兴趣点类型枚举（与POIManager保持一致）
enum POI_TYPE {
	RESOURCE_NODE,      # 资源采集点
	QUEST_TARGET,       # 任务目标
	SECRET_ENCOUNTER,   # 奇遇/隐藏点
	FACILITY            # 功能设施
}

# 兴趣点状态枚举（与POIManager保持一致）
enum POI_STATUS {
	UNDISCOVERED,       # 未发现
	DISCOVERED,         # 已发现
	ACTIVATED,          # 已激活
	COMPLETED          # 已完成
}

# 属性
@export var poi_id: String = ""
@export var poi_type: POI_TYPE = POI_TYPE.RESOURCE_NODE
@export var poi_status: POI_STATUS = POI_STATUS.UNDISCOVERED

# 节点引用
var icon_sprite: Sprite2D
var highlight_effect: ColorRect
var tooltip_label: Label

# 颜色定义（水墨风格）
var discovered_color_map = {
	POI_TYPE.RESOURCE_NODE: Color.GREEN,
	POI_TYPE.QUEST_TARGET: Color.YELLOW,
	POI_TYPE.SECRET_ENCOUNTER: Color.PURPLE,
	POI_TYPE.FACILITY: Color.BLUE
}

var completed_color_map = {
	POI_TYPE.RESOURCE_NODE: Color.GRAY,
	POI_TYPE.QUEST_TARGET: Color.GRAY,
	POI_TYPE.SECRET_ENCOUNTER: Color.GRAY,
	POI_TYPE.FACILITY: Color.GRAY
}

var undiscovered_color = Color.DARK_GRAY

# 初始化
func _ready():
	_initialize_components()
	_update_visual_state()
	
	# 设置图层以确保正确的渲染顺序
	z_index = 100

# 初始化组件
func _initialize_components():
	# 创建图标精灵
	icon_sprite = Sprite2D.new()
	icon_sprite.name = "Icon"
	add_child(icon_sprite)
	
	# 设置默认图标（稍后会根据类型更新）
	icon_sprite.texture = _get_icon_texture(poi_type)
	
	# 创建高亮效果
	highlight_effect = ColorRect.new()
	highlight_effect.name = "Highlight"
	highlight_effect.size = Vector2(32, 32)
	highlight_effect.position = Vector2(-16, -16)  # 居中
	highlight_effect.modulate = Color.WHITE
	highlight_effect.visible = false
	add_child(highlight_effect)
	
	# 创建工具提示标签（可选，主要用于调试）
	tooltip_label = Label.new()
	tooltip_label.name = "Tooltip"
	tooltip_label.visible = false
	tooltip_label.pivot_offset = tooltip_label.size / 2
	add_child(tooltip_label)

# 获取图标纹理
func _get_icon_texture(poi_type: POI_TYPE) -> Texture2D:
	# 在实际实现中，这里会返回相应的图标纹理
	# 为了演示目的，我们返回null，实际使用时应加载适当的纹理
	match poi_type:
		POI_TYPE.RESOURCE_NODE:
			# 应该返回资源点图标
			return null
		POI_TYPE.QUEST_TARGET:
			# 应该返回任务目标图标
			return null
		POI_TYPE.SECRET_ENCOUNTER:
			# 应该返回奇遇点图标
			return null
		POI_TYPE.FACILITY:
			# 应该返回设施图标
			return null
	return null

# 更新视觉状态
func _update_visual_state():
	if not icon_sprite:
		return
	
	# 根据状态和类型设置颜色
	var color = _get_poi_color()
	icon_sprite.modulate = color
	highlight_effect.color = color
	highlight_effect.color.a = 0.3  # 半透明
	
	# 根据状态设置可见性
	match poi_status:
		POI_STATUS.UNDISCOVERED:
			icon_sprite.visible = false
			highlight_effect.visible = false
		POI_STATUS.DISCOVERED, POI_STATUS.ACTIVATED:
			icon_sprite.visible = true
			highlight_effect.visible = false
		POI_STATUS.COMPLETED:
			icon_sprite.visible = true
			highlight_effect.visible = false
	
	# 如果是激活状态，启用高亮效果
	if poi_status == POI_STATUS.ACTIVATED:
		highlight_effect.visible = true
		_start_highlight_animation()

# 获取兴趣点颜色
func _get_poi_color() -> Color:
	if poi_status == POI_STATUS.UNDISCOVERED:
		return undiscovered_color
	elif poi_status == POI_STATUS.COMPLETED:
		return completed_color_map[poi_type]
	else:  # DISCOVERED 或 ACTIVATED
		return discovered_color_map[poi_type]

# 开始高亮动画
func _start_highlight_animation():
	if not highlight_effect:
		return
	
	# 创建一个简单的脉冲动画
	var tween = create_tween()
	tween.set_loops()  # 循环播放
	tween.tween_method(
		func(value):
			highlight_effect.scale = Vector2(1.0 + value * 0.2, 1.0 + value * 0.2)
			highlight_effect.modulate.a = 0.3 + value * 0.2
		, 0.0, 1.0, 1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# 更新兴趣点状态
func update_status(new_status: POI_STATUS):
	var old_status = poi_status
	poi_status = new_status
	
	# 如果状态改变了，更新视觉效果
	if old_status != new_status:
		_update_visual_state()

# 更新兴趣点类型
func update_type(new_type: POI_TYPE):
	poi_type = new_type
	icon_sprite.texture = _get_icon_texture(new_type)
	_update_visual_state()

# 设置为任务相关（更高优先级的显示）
func set_quest_related(is_quest_related: bool):
	if is_quest_related:
		# 任务相关的POI会有更明显的标记
		z_index = 200
		if icon_sprite:
			icon_sprite.scale = Vector2(1.2, 1.2)
	else:
		z_index = 100
		if icon_sprite:
			icon_sprite.scale = Vector2(1.0, 1.0)

# 鼠标进入事件
func _on_mouse_entered():
	if poi_status != POI_STATUS.UNDISCOVERED:
		highlight_effect.visible = true
		tooltip_label.visible = true

# 鼠标退出事件
func _on_mouse_exited():
	if poi_status != POI_STATUS.UNDISCOVERED:
		if poi_status != POI_STATUS.ACTIVATED:  # 激活状态保持高亮
			highlight_effect.visible = false
		tooltip_label.visible = false

# 鼠标按下事件
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if poi_status != POI_STATUS.UNDISCOVERED:
			emit_signal("poi_clicked", poi_id)

# 设置交互
func _input(event):
	if event is InputEventMouseMotion:
		# 检测鼠标是否悬停在POI上
		var mouse_pos = get_global_mouse_position()
		var distance = global_position.distance_to(mouse_pos)
		if distance < 20:  # 20像素的交互半径
			_on_mouse_entered()
		else:
			_on_mouse_exited()

# 获取POI信息
func get_poi_info() -> Dictionary:
	return {
		"id": poi_id,
		"type": poi_type,
		"status": poi_status,
		"position": global_position
	}

# 设置位置
func set_position(position: Vector2):
	global_position = position