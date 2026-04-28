class_name SkillNode
extends Control

## 技能节点组件
## 显示节点图标和状态，处理悬停和点击事件，播放解锁动画

# 信号定义
signal hovered()
signal clicked()
signal unlock_requested()

# 子节点引用
@onready var icon_container: Panel = $IconContainer
@onready var icon_label: Label = $IconContainer/IconLabel
@onready var status_indicator: ColorRect = $StatusIndicator
@onready var particles: GPUParticles2D = $UnlockParticles

# 节点数据
var node_data: SkillTreeManager.SkillNode
var hover_timer: Timer

# 品阶颜色映射
const TIER_COLORS = {
	1: Color(0.8, 0.7, 0.2, 1.0),  # 黄阶 - 黄色
	2: Color(0.2, 0.5, 0.9, 1.0),  # 玄阶 - 蓝色
	3: Color(0.6, 0.2, 0.8, 1.0),  # 地阶 - 紫色
	4: Color(0.9, 0.7, 0.1, 1.0)   # 天阶 - 金色
}

# 状态颜色映射
const STATUS_COLORS = {
	SkillTreeManager.NodeStatus.LOCKED: Color(0.3, 0.3, 0.3, 0.5),      # 锁定 - 灰色
	SkillTreeManager.NodeStatus.AVAILABLE: Color(0.5, 0.5, 0.5, 0.7),   # 可解锁 - 淡墨
	SkillTreeManager.NodeStatus.UNLOCKED: Color(0.1, 0.1, 0.1, 1.0),    # 已解锁 - 浓墨
	SkillTreeManager.NodeStatus.ACTIVE: Color(0.9, 0.7, 0.1, 1.0)       # 激活 - 金色
}

func _ready() -> void:
	# 设置节点大小
	custom_minimum_size = Vector2(100, 100)
	
	# 创建悬停计时器
	hover_timer = Timer.new()
	hover_timer.wait_time = 0.5
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timeout)
	add_child(hover_timer)
	
	# 连接鼠标事件
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	# 初始化粒子系统
	_setup_particles()

# 初始化节点数据
func initialize(data: SkillTreeManager.SkillNode) -> void:
	node_data = data
	_update_visual()

# 更新视觉表现
func _update_visual() -> void:
	if not node_data:
		return
	
	# 更新图标文字（使用招式名称的第一个字）
	if icon_label:
		icon_label.text = node_data.skill_name.substr(0, 1) if node_data.skill_name.length() > 0 else "?"
		icon_label.add_theme_font_size_override("font_size", 48)
	
	# 更新品阶颜色边框
	if icon_container:
		var tier_color = TIER_COLORS.get(node_data.tier, Color.WHITE)
		
		# 创建边框样式
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.95, 0.95, 0.9, 1.0)  # 宣纸背景色
		style_box.border_width_left = 3
		style_box.border_width_right = 3
		style_box.border_width_top = 3
		style_box.border_width_bottom = 3
		style_box.border_color = tier_color
		style_box.corner_radius_top_left = 8
		style_box.corner_radius_top_right = 8
		style_box.corner_radius_bottom_left = 8
		style_box.corner_radius_bottom_right = 8
		
		icon_container.add_theme_stylebox_override("panel", style_box)
	
	# 更新状态指示器
	_update_status_indicator()

# 更新状态指示器
func _update_status_indicator() -> void:
	if not status_indicator or not node_data:
		return
	
	var status_color = STATUS_COLORS.get(node_data.status, Color.WHITE)
	status_indicator.color = status_color
	
	# 根据状态调整透明度
	match node_data.status:
		SkillTreeManager.NodeStatus.LOCKED:
			modulate = Color(1.0, 1.0, 1.0, 0.5)
		SkillTreeManager.NodeStatus.AVAILABLE:
			modulate = Color(1.0, 1.0, 1.0, 0.8)
		SkillTreeManager.NodeStatus.UNLOCKED, SkillTreeManager.NodeStatus.ACTIVE:
			modulate = Color(1.0, 1.0, 1.0, 1.0)

# 设置粒子系统
func _setup_particles() -> void:
	if not particles:
		return
	
	# 配置墨水晕染粒子效果
	particles.emitting = false
	particles.amount = 50
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 0.8
	
	# 创建粒子材质
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 20.0
	particle_material.direction = Vector3(0, 0, 0)
	particle_material.spread = 180.0
	particle_material.initial_velocity_min = 50.0
	particle_material.initial_velocity_max = 100.0
	particle_material.gravity = Vector3(0, 0, 0)
	particle_material.scale_min = 2.0
	particle_material.scale_max = 5.0
	particle_material.color = Color(0.1, 0.1, 0.1, 0.8)  # 墨水颜色
	
	particles.process_material = particle_material
	
	# 设置粒子纹理（如果有的话）
	if ResourceLoader.exists("res://assets/textures/ink_particle.png"):
		particles.texture = load("res://assets/textures/ink_particle.png")

# 鼠标事件处理
func _on_mouse_entered() -> void:
	# 启动悬停计时器
	hover_timer.start()
	
	# 视觉反馈：轻微放大
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)

func _on_mouse_exited() -> void:
	# 停止悬停计时器
	hover_timer.stop()
	
	# 恢复原始大小
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

func _on_hover_timeout() -> void:
	# 悬停超过0.5秒，发送悬停信号
	hovered.emit()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 发送点击信号
			clicked.emit()
			
			# 如果节点可解锁，发送解锁请求
			if node_data and node_data.status == SkillTreeManager.NodeStatus.AVAILABLE:
				unlock_requested.emit()

# 播放解锁动画
func play_unlock_animation() -> void:
	# 播放墨水晕染粒子效果
	if particles:
		particles.emitting = true
	
	# 节点变为金色/亮色动画
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 缩放动画
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.3)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	# 颜色闪烁动画
	var original_modulate = modulate
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.0, 1.0), 0.3)
	tween.chain().tween_property(self, "modulate", original_modulate, 0.2)
	
	# 更新节点状态
	if node_data:
		node_data.status = SkillTreeManager.NodeStatus.UNLOCKED
		_update_status_indicator()

# 设置节点状态
func set_node_status(status: SkillTreeManager.NodeStatus) -> void:
	if node_data:
		node_data.status = status
		_update_status_indicator()

# 获取节点数据
func get_node_data() -> SkillTreeManager.SkillNode:
	return node_data