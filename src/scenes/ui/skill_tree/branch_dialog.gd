class_name BranchDialog
extends Window

## 分支选择对话框
## 显示分支选项，处理用户选择

# 信号定义
signal branch_selected(node_id: String, branch_index: int)
signal dialog_closed()

# 子节点引用
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var branches_container: VBoxContainer = $VBoxContainer/BranchesContainer
@onready var confirm_button: Button = $VBoxContainer/ButtonContainer/ConfirmButton
@onready var cancel_button: Button = $VBoxContainer/ButtonContainer/CancelButton

# 当前数据
var current_node_id: String = ""
var branch_options: Array = []
var selected_branch_index: int = -1

func _ready() -> void:
	# 设置窗口属性
	title = "分支选择"
	size = Vector2i(500, 600)
	popup_window = true
	transient = true
	exclusive = true
	
	# 连接按钮信号
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	
	# 连接窗口关闭信号
	close_requested.connect(_on_close_requested)
	
	# 默认隐藏
	hide()

# 显示分支选择
func show_branches(node_id: String, branches: Array) -> void:
	current_node_id = node_id
	branch_options = branches
	selected_branch_index = -1
	
	# 更新标题
	if title_label:
		title_label.text = "选择武学分支"
		title_label.add_theme_font_size_override("font_size", 24)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 更新描述
	if description_label:
		description_label.text = "请选择一个分支路线。注意：一旦选择将无法更改！"
		description_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1.0))
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 创建分支选项
	_create_branch_options()
	
	# 禁用确认按钮（直到选择分支）
	if confirm_button:
		confirm_button.disabled = true
	
	# 居中显示窗口
	popup_centered()

# 创建分支选项
func _create_branch_options() -> void:
	if not branches_container:
		return
	
	# 清空现有选项
	for child in branches_container.get_children():
		child.queue_free()
	
	# 为每个分支创建选项卡
	for i in range(branch_options.size()):
		var branch_data = branch_options[i]
		var option_panel = _create_branch_option_panel(i, branch_data)
		branches_container.add_child(option_panel)

# 创建单个分支选项面板
func _create_branch_option_panel(index: int, branch_data: SkillTreeManager.SkillNode) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "BranchOption_" + str(index)
	
	# 设置面板样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.95, 0.95, 0.9, 1.0)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.5, 0.5, 0.5, 1.0)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.content_margin_left = 12
	style_box.content_margin_right = 12
	style_box.content_margin_top = 12
	style_box.content_margin_bottom = 12
	
	panel.add_theme_stylebox_override("panel", style_box)
	panel.custom_minimum_size = Vector2(0, 150)
	
	# 创建内容容器
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# 添加选择按钮
	var select_button = Button.new()
	select_button.text = "选择此分支"
	select_button.pressed.connect(_on_branch_option_selected.bind(index))
	vbox.add_child(select_button)
	
	# 添加招式名称
	var name_label = Label.new()
	name_label.text = branch_data.skill_name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	vbox.add_child(name_label)
	
	# 添加描述
	var desc_label = Label.new()
	desc_label.text = branch_data.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# 添加属性要求
	if branch_data.branch_condition.size() > 0:
		var req_label = Label.new()
		var req_text = "属性要求: "
		var requirements = []
		for attr in branch_data.branch_condition.keys():
			var value = branch_data.branch_condition[attr]
			requirements.append("%s ≥ %d" % [attr, value])
		req_label.text = req_text + ", ".join(requirements)
		req_label.add_theme_color_override("font_color", Color(0.2, 0.4, 0.8, 1.0))
		vbox.add_child(req_label)
	
	# 添加效果差异说明
	var effect_label = Label.new()
	effect_label.text = _get_branch_effect_description(branch_data)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1.0))
	vbox.add_child(effect_label)
	
	# 添加不可逆提示
	var warning_label = Label.new()
	warning_label.text = "⚠️ 选择后无法更改"
	warning_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1.0))
	warning_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(warning_label)
	
	return panel

# 获取分支效果描述
func _get_branch_effect_description(branch_data: SkillTreeManager.SkillNode) -> String:
	# 根据分支条件生成效果描述
	if branch_data.branch_condition.has("STR"):
		return "效果: 高伤害、破防能力强，适合刚猛路线"
	elif branch_data.branch_condition.has("AGI"):
		return "效果: 连击速度快、身法加成，适合灵动路线"
	elif branch_data.branch_condition.has("INT"):
		return "效果: 内力消耗低、技能冷却短，适合智慧路线"
	else:
		return "效果: 平衡型发展，各方面均衡提升"

# 分支选项被选择
func _on_branch_option_selected(index: int) -> void:
	selected_branch_index = index
	
	# 更新所有选项的视觉状态
	_update_option_selection_visual()
	
	# 启用确认按钮
	if confirm_button:
		confirm_button.disabled = false

# 更新选项选择的视觉状态
func _update_option_selection_visual() -> void:
	if not branches_container:
		return
	
	for i in range(branches_container.get_child_count()):
		var panel = branches_container.get_child(i) as PanelContainer
		if not panel:
			continue
		
		var style_box = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if not style_box:
			continue
		
		# 选中的选项高亮显示
		if i == selected_branch_index:
			style_box.border_color = Color(0.9, 0.7, 0.1, 1.0)  # 金色边框
			style_box.border_width_left = 4
			style_box.border_width_right = 4
			style_box.border_width_top = 4
			style_box.border_width_bottom = 4
		else:
			style_box.border_color = Color(0.5, 0.5, 0.5, 1.0)  # 灰色边框
			style_box.border_width_left = 2
			style_box.border_width_right = 2
			style_box.border_width_top = 2
			style_box.border_width_bottom = 2

# 确认按钮点击
func _on_confirm_pressed() -> void:
	if selected_branch_index >= 0 and selected_branch_index < branch_options.size():
		branch_selected.emit(current_node_id, selected_branch_index)
		hide()

# 取消按钮点击
func _on_cancel_pressed() -> void:
	hide()

# 窗口关闭请求
func _on_close_requested() -> void:
	dialog_closed.emit()
	hide()