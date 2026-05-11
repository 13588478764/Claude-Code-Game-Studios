## OffscreenIndicator
## 屏幕边缘指示器
## 用于指示屏幕外的目标方向
##
## 主要功能：
## - 待补充

extends Node

class_name OffscreenIndicator

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
signal target_clicked(target_id: String)

# 属性
@export var target_id: String = ""
@export var target_position: Vector2 = Vector2.ZERO
@export var indicator_size: Vector2 = Vector2(24, 24)

# 节点引用
var indicator_sprite: TextureRect

# 内部变量
var viewport_size: Vector2
var player_position: Vector2 = Vector2.ZERO
var pulse_tween: Tween = null

# 初始化
func _ready():
	viewport_size = get_viewport_rect().size
	_initialize_indicator()
	_update_indicator_position()

# 初始化指示器
func _initialize_indicator():
	# 创建指示器精灵
	indicator_sprite = TextureRect.new()
	indicator_sprite.name = "IndicatorSprite"
	indicator_sprite.size = indicator_size
	indicator_sprite.position = Vector2(-indicator_size.x/2, -indicator_size.y/2)  # 居中
	indicator_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	indicator_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# 设置默认纹理（实际项目中应使用箭头图标）
	var default_texture = _create_default_texture()
	indicator_sprite.texture = default_texture
	
	# 设置锚点和边距
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	
	add_child(indicator_sprite)
	
	# 设置默认可见性
	visible = false
	
	# 添加点击检测
	mouse_filter = Control.MOUSE_FILTER_PASS

# 创建默认纹理（实际项目中应替换为实际的箭头图标）
func _create_default_texture() -> Texture2D:
	# 创建一个简单的箭头形状作为占位符
	# 在实际实现中，这里应该加载实际的箭头图标
	var image = Image.new()
	image.initialize_data(32, 32, false, Image.FORMAT_RGBA8)
	
	# 填充图像为透明
	image.fill(Color.TRANSPARENT)
	
	# 绘制一个简单的三角形箭头
	var arrow_color = Color.YELLOW
	for y in range(32):
		for x in range(32):
			# 创建一个简单的右向箭头形状
			if (x > y - 8 and x < y + 8 and y > 10 and y < 22):
				image.set_pixel(x, y, arrow_color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# 更新指示器位置
func _update_indicator_position():
	if not is_instance_valid(indicator_sprite):
		return
	
	# 计算相对于玩家的位置
	var relative_pos = target_position - player_position
	
	# 如果目标在屏幕内，则隐藏指示器
	var screen_rect = Rect2(player_position - viewport_size/2, viewport_size)
	if screen_rect.has_point(target_position):
		visible = false
		return
	
	# 计算屏幕边界交点
	var screen_center = player_position
	var screen_half_size = viewport_size / 2
	
	# 计算射线与屏幕边界的交点
	var intersection = _calculate_screen_intersection(screen_center, relative_pos, screen_half_size)
	
	if intersection != null:
		# 将屏幕坐标转换为控件坐标
		var screen_pos = intersection + screen_center
		var control_pos = screen_pos - (get_canvas_transform().origin + player_position)
		
		# 限制在屏幕边缘
		control_pos.x = clamp(control_pos.x, -screen_half_size.x, screen_half_size.x)
		control_pos.y = clamp(control_pos.y, -screen_half_size.y, screen_half_size.y)
		
		# 确保指示器在屏幕边缘
		if abs(control_pos.x) > screen_half_size.x - indicator_size.x/2:
			control_pos.x = sign(control_pos.x) * (screen_half_size.x - indicator_size.x/2)
		if abs(control_pos.y) > screen_half_size.y - indicator_size.y/2:
			control_pos.y = sign(control_pos.y) * (screen_half_size.y - indicator_size.y/2)
		
		position = control_pos
		visible = true
		
		# 根据方向旋转指示器
		var direction = (target_position - player_position).normalized()
		rotation = atan2(direction.y, direction.x)
		
		# 确保箭头指向目标
		rotation += PI/2  # 调整到正确的朝向
	else:
		visible = false

# 计算射线与屏幕边界的交点
func _calculate_screen_intersection(origin: Vector2, direction: Vector2, half_size: Vector2) -> Vector2:
	var t_min = 0.0
	var t_max = INF
	
	# 计算与水平边界的交点
	if abs(direction.x) > 0.001:  # 避免除零
		var t1 = (-half_size.x - origin.x) / direction.x
		var t2 = (half_size.x - origin.x) / direction.x
		
		t_min = max(t_min, min(t1, t2))
		t_max = min(t_max, max(t1, t2))
	
	# 计算与垂直边界的交点
	if abs(direction.y) > 0.001:  # 避免除零
		var t1 = (-half_size.y - origin.y) / direction.y
		var t2 = (half_size.y - origin.y) / direction.y
		
		t_min = max(t_min, min(t1, t2))
		t_max = min(t_max, max(t1, t2))
	
	if t_min <= t_max and t_max > 0:
		var t = max(t_min, 0)
		if t <= t_max:
			return direction.normalized() * t
	
	return null

# 设置玩家位置
func set_player_position(pos: Vector2):
	player_position = pos
	_update_indicator_position()

# 设置目标位置
func set_target_position(pos: Vector2):
	target_position = pos
	_update_indicator_position()

# 设置目标ID
func set_target_id(id: String):
	target_id = id

# 开始脉冲动画
func start_pulse_animation():
	if pulse_tween:
		pulse_tween.kill()
	
	pulse_tween = create_tween()
	pulse_tween.set_loops()  # 永久循环
	pulse_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# 停止脉冲动画
func stop_pulse_animation():
	if pulse_tween:
		pulse_tween.kill()
		scale = Vector2(1.0, 1.0)

# 输入处理
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("target_clicked", target_id)
		accept_event()

# 更新函数，用于持续更新指示器位置
func update_indicator(player_pos: Vector2, target_pos: Vector2):
	player_position = player_pos
	target_position = target_pos
	_update_indicator_position()

# 显示/隐藏指示器
func set_visible(visible_state: bool):
	visible = visible_state