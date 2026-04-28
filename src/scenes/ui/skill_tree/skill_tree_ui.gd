class_name SkillTreeUI
extends Control

## 技能树UI主控制器
## 管理整体布局、视图控制、缩放和平移交互
## 实现水墨卷轴风格的技能树可视化界面

# 信号定义
signal node_selected(node_id: String)
signal node_unlocked(node_id: String)
signal branch_chosen(node_id: String, branch_index: int)

# 子节点引用
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var tree_viewport: Control = $ScrollContainer/TreeViewport
@onready var school_selector: VBoxContainer = $SchoolSelector
@onready var detail_panel: Control = $NodeDetailPanel
@onready var branch_dialog: Control = $BranchDialog

# 技能树管理器引用
var skill_tree_manager: SkillTreeManager
var skill_unlock_manager: SkillUnlockManager

# 当前状态
var current_school_id: String = ""
var current_zoom: float = 1.0
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var viewport_offset: Vector2 = Vector2.ZERO

# 配置参数
const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 2.0
const ZOOM_STEP: float = 0.1
const PAN_SPEED: float = 1.0

# 节点实例缓存
var node_instances: Dictionary = {}  # {node_id: SkillNode}

# 预加载场景
const SKILL_NODE_SCENE = preload("res://scenes/ui/skill_tree/SkillNode.tscn")

func _ready() -> void:
	# 初始化UI组件
	_setup_ui()
	
	# 连接信号
	_connect_signals()
	
	# 设置输入处理
	set_process_input(true)

func _setup_ui() -> void:
	# 设置水墨卷轴风格背景
	var bg_panel = Panel.new()
	bg_panel.name = "Background"
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_panel.z_index = -1
	add_child(bg_panel)
	move_child(bg_panel, 0)
	
	# 应用水墨风格主题（如果存在）
	if ResourceLoader.exists("res://assets/themes/ink_scroll_theme.tres"):
		var theme = load("res://assets/themes/ink_scroll_theme.tres")
		bg_panel.theme = theme
	
	# 初始化视口
	if tree_viewport:
		tree_viewport.custom_minimum_size = Vector2(2000, 1500)

func _connect_signals() -> void:
	# 连接详情面板信号
	if detail_panel and detail_panel.has_signal("unlock_button_pressed"):
		detail_panel.unlock_button_pressed.connect(_on_unlock_button_pressed)
	
	# 连接分支对话框信号
	if branch_dialog:
		if branch_dialog.has_signal("branch_selected"):
			branch_dialog.branch_selected.connect(_on_branch_selected)
		if branch_dialog.has_signal("dialog_closed"):
			branch_dialog.dialog_closed.connect(_on_branch_dialog_closed)

# 初始化技能树数据
func initialize(tree_manager: SkillTreeManager, unlock_manager: SkillUnlockManager) -> void:
	skill_tree_manager = tree_manager
	skill_unlock_manager = unlock_manager
	
	# 加载所有武学流派
	_load_school_list()
	
	# 默认加载第一个流派
	if skill_tree_manager.skill_trees.size() > 0:
		var first_school = skill_tree_manager.skill_trees.keys()[0]
		load_skill_tree(first_school)

# 加载武学流派列表
func _load_school_list() -> void:
	if not school_selector:
		return
	
	# 清空现有列表
	for child in school_selector.get_children():
		child.queue_free()
	
	# 添加流派按钮
	for school_id in skill_tree_manager.skill_trees.keys():
		var school_tree = skill_tree_manager.skill_trees[school_id]
		var button = Button.new()
		button.text = school_tree.school_name
		button.name = "SchoolButton_" + school_id
		button.pressed.connect(_on_school_selected.bind(school_id))
		school_selector.add_child(button)

# 加载指定武学流派的技能树
func load_skill_tree(school_id: String) -> void:
	if not skill_tree_manager.skill_trees.has(school_id):
		push_error("技能树不存在: " + school_id)
		return
	
	current_school_id = school_id
	var skill_tree = skill_tree_manager.skill_trees[school_id]
	
	# 清空现有节点
	_clear_tree_viewport()
	
	# 创建节点实例
	_create_skill_nodes(skill_tree)
	
	# 绘制连接线
	_draw_connections(skill_tree)
	
	# 居中视图
	center_view()

# 清空技能树视口
func _clear_tree_viewport() -> void:
	if not tree_viewport:
		return
	
	for child in tree_viewport.get_children():
		child.queue_free()
	
	node_instances.clear()

# 创建技能节点实例
func _create_skill_nodes(skill_tree: SkillTreeManager.SkillTree) -> void:
	if not tree_viewport:
		return
	
	# 计算节点布局位置
	var layout = _calculate_node_layout(skill_tree)
	
	# 创建节点实例
	for node_id in skill_tree.nodes.keys():
		var skill_node_data = skill_tree.nodes[node_id]
		var node_instance = SKILL_NODE_SCENE.instantiate()
		
		# 设置节点数据
		node_instance.initialize(skill_node_data)
		
		# 设置节点位置
		if layout.has(node_id):
			node_instance.position = layout[node_id]
		
		# 连接节点信号
		node_instance.hovered.connect(_on_node_hovered.bind(node_id))
		node_instance.clicked.connect(_on_node_clicked.bind(node_id))
		node_instance.unlock_requested.connect(_on_unlock_requested.bind(node_id))
		
		# 添加到视口
		tree_viewport.add_child(node_instance)
		node_instances[node_id] = node_instance

# 计算节点布局位置
func _calculate_node_layout(skill_tree: SkillTreeManager.SkillTree) -> Dictionary:
	var layout: Dictionary = {}
	var node_spacing_x: float = 200.0
	var node_spacing_y: float = 150.0
	var start_x: float = 100.0
	var start_y: float = 100.0
	
	# 布局线性主干路径（垂直流：从上到下）
	var y_offset = start_y
	for i in range(skill_tree.main_path.size()):
		var node_id = skill_tree.main_path[i]
		layout[node_id] = Vector2(start_x + 400, y_offset)
		y_offset += node_spacing_y
	
	# 布局分支节点（左右分支）
	for parent_id in skill_tree.branches.keys():
		if not layout.has(parent_id):
			continue
		
		var parent_pos = layout[parent_id]
		var branches = skill_tree.branches[parent_id]
		
		# 左侧分支（刚猛/外功路线）
		var left_offset = parent_pos.x - node_spacing_x
		# 右侧分支（灵动/内功路线）
		var right_offset = parent_pos.x + node_spacing_x
		
		for i in range(branches.size()):
			var branch_node_id = branches[i]
			var branch_node = skill_tree.nodes[branch_node_id]
			
			# 根据分支条件判断左右位置
			var x_pos = parent_pos.x
			if branch_node.branch_condition.has("STR"):
				x_pos = left_offset  # 力量分支在左侧
			elif branch_node.branch_condition.has("AGI"):
				x_pos = right_offset  # 敏捷分支在右侧
			else:
				# 默认交替排列
				x_pos = left_offset if i % 2 == 0 else right_offset
			
			layout[branch_node_id] = Vector2(x_pos, parent_pos.y + node_spacing_y * 0.5)
	
	return layout

# 绘制节点连接线
func _draw_connections(skill_tree: SkillTreeManager.SkillTree) -> void:
	if not tree_viewport:
		return
	
	# 创建连接线容器
	var connections_layer = Control.new()
	connections_layer.name = "ConnectionsLayer"
	connections_layer.z_index = -1
	connections_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	connections_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	tree_viewport.add_child(connections_layer)
	tree_viewport.move_child(connections_layer, 0)
	
	# 绘制主干路径连接线
	for i in range(skill_tree.main_path.size() - 1):
		var from_id = skill_tree.main_path[i]
		var to_id = skill_tree.main_path[i + 1]
		_draw_connection_line(connections_layer, from_id, to_id, true)
	
	# 绘制分支连接线
	for parent_id in skill_tree.branches.keys():
		var branches = skill_tree.branches[parent_id]
		for branch_id in branches:
			_draw_connection_line(connections_layer, parent_id, branch_id, false)

# 绘制单条连接线
func _draw_connection_line(parent: Control, from_id: String, to_id: String, is_unlocked: bool) -> void:
	if not node_instances.has(from_id) or not node_instances.has(to_id):
		return
	
	var from_node = node_instances[from_id]
	var to_node = node_instances[to_id]
	
	var line = Line2D.new()
	line.add_point(from_node.position + Vector2(50, 50))  # 节点中心偏移
	line.add_point(to_node.position + Vector2(50, 50))
	
	# 水墨笔触风格
	line.width = 3.0
	line.default_color = Color(0.2, 0.2, 0.2, 0.8) if is_unlocked else Color(0.5, 0.5, 0.5, 0.3)
	line.antialiased = true
	
	parent.add_child(line)

# 输入处理
func _input(event: InputEvent) -> void:
	# 鼠标滚轮缩放
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_out()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_start_pos = event.position
			else:
				is_dragging = false
	
	# 鼠标拖拽平移
	if event is InputEventMouseMotion and is_dragging:
		var delta = event.position - drag_start_pos
		drag_start_pos = event.position
		_pan_view(delta)
	
	# 快捷键支持
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				_pan_view(Vector2(0, 50))
			KEY_A:
				_pan_view(Vector2(50, 0))
			KEY_S:
				_pan_view(Vector2(0, -50))
			KEY_D:
				_pan_view(Vector2(-50, 0))
			KEY_SPACE:
				center_view()

# 缩放功能
func _zoom_in() -> void:
	current_zoom = min(current_zoom + ZOOM_STEP, MAX_ZOOM)
	_apply_zoom()

func _zoom_out() -> void:
	current_zoom = max(current_zoom - ZOOM_STEP, MIN_ZOOM)
	_apply_zoom()

func _apply_zoom() -> void:
	if tree_viewport:
		tree_viewport.scale = Vector2(current_zoom, current_zoom)

# 平移功能
func _pan_view(delta: Vector2) -> void:
	if scroll_container:
		scroll_container.scroll_horizontal -= int(delta.x * PAN_SPEED)
		scroll_container.scroll_vertical -= int(delta.y * PAN_SPEED)

# 居中视图
func center_view() -> void:
	if not scroll_container or not tree_viewport:
		return
	
	var viewport_size = scroll_container.size
	var content_size = tree_viewport.size * current_zoom
	
	scroll_container.scroll_horizontal = int((content_size.x - viewport_size.x) / 2)
	scroll_container.scroll_vertical = int((content_size.y - viewport_size.y) / 2)

# 信号处理函数
func _on_school_selected(school_id: String) -> void:
	load_skill_tree(school_id)

func _on_node_hovered(node_id: String) -> void:
	if not skill_tree_manager.skill_trees.has(current_school_id):
		return
	
	var skill_tree = skill_tree_manager.skill_trees[current_school_id]
	if not skill_tree.nodes.has(node_id):
		return
	
	var node_data = skill_tree.nodes[node_id]
	
	# 显示详情面板
	if detail_panel:
		detail_panel.show_node_details(node_data, skill_unlock_manager)
	
	# 播放悬停音效（占位符）
	_play_hover_sound()

func _on_node_clicked(node_id: String) -> void:
	node_selected.emit(node_id)

func _on_unlock_requested(node_id: String) -> void:
	if not skill_tree_manager.skill_trees.has(current_school_id):
		return
	
	var skill_tree = skill_tree_manager.skill_trees[current_school_id]
	if not skill_tree.nodes.has(node_id):
		return
	
	var node_data = skill_tree.nodes[node_id]
	
	# 检查是否有分支选择
	if skill_tree.branches.has(node_id):
		var branches = skill_tree.branches[node_id]
		if branches.size() > 1:
			# 显示分支选择对话框
			_show_branch_dialog(node_id, branches)
			return
	
	# 直接解锁
	_unlock_node(node_id)

func _on_unlock_button_pressed(node_id: String) -> void:
	_on_unlock_requested(node_id)

func _on_branch_selected(node_id: String, branch_index: int) -> void:
	branch_chosen.emit(node_id, branch_index)
	_unlock_node(node_id)

func _on_branch_dialog_closed() -> void:
	# 对话框关闭处理
	pass

# 显示分支选择对话框
func _show_branch_dialog(node_id: String, branches: Array) -> void:
	if not branch_dialog:
		return
	
	var skill_tree = skill_tree_manager.skill_trees[current_school_id]
	var branch_options = []
	
	for branch_id in branches:
		if skill_tree.nodes.has(branch_id):
			branch_options.append(skill_tree.nodes[branch_id])
	
	branch_dialog.show_branches(node_id, branch_options)

# 解锁节点
func _unlock_node(node_id: String) -> void:
	if not skill_unlock_manager:
		return
	
	# 验证解锁条件
	var result = skill_unlock_manager.verify_unlock_conditions(current_school_id, node_id)
	
	if result.success:
		# 播放解锁动画
		if node_instances.has(node_id):
			node_instances[node_id].play_unlock_animation()
		
		# 更新节点状态
		var skill_tree = skill_tree_manager.skill_trees[current_school_id]
		if skill_tree.nodes.has(node_id):
			skill_tree.nodes[node_id].status = SkillTreeManager.NodeStatus.UNLOCKED
		
		# 播放解锁音效（占位符）
		_play_unlock_sound()
		
		# 显示"领悟成功"提示
		_show_unlock_notification()
		
		# 发送解锁信号
		node_unlocked.emit(node_id)
	else:
		# 显示缺失条件提示
		_show_missing_conditions(result.missing_conditions)

# 音效占位符
func _play_hover_sound() -> void:
	# TODO: 播放纸张翻动音效
	pass

func _play_unlock_sound() -> void:
	# TODO: 播放传统乐器音效（古琴、笛子）
	pass

# UI提示
func _show_unlock_notification() -> void:
	# TODO: 显示"领悟成功"提示
	print("领悟成功!")

func _show_missing_conditions(conditions: Array) -> void:
	# TODO: 显示缺失条件提示
	print("缺失条件: ", conditions)