class_name NodeDetailPanel
extends PanelContainer

## 节点详情面板
## 显示节点详细信息，动态更新内容

# 信号定义
signal unlock_button_pressed(node_id: String)

# 子节点引用
@onready var skill_name_label: Label = $VBoxContainer/SkillNameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var tier_label: Label = $VBoxContainer/TierLabel
@onready var stats_container: VBoxContainer = $VBoxContainer/StatsContainer
@onready var requirements_container: VBoxContainer = $VBoxContainer/RequirementsContainer
@onready var unlock_button: Button = $VBoxContainer/UnlockButton

# 当前显示的节点数据
var current_node_data: SkillTreeManager.SkillNode
var current_node_id: String = ""

# 品阶名称映射
const TIER_NAMES = {
	1: "黄阶武学",
	2: "玄阶武学",
	3: "地阶武学",
	4: "天阶武学"
}

func _ready() -> void:
	# 初始化UI
	_setup_ui()
	
	# 连接按钮信号
	if unlock_button:
		unlock_button.pressed.connect(_on_unlock_button_pressed)
	
	# 默认隐藏面板
	hide()

func _setup_ui() -> void:
	# 设置面板样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.95, 0.95, 0.9, 0.95)  # 宣纸背景色
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.3, 0.3, 0.3, 1.0)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.content_margin_left = 16
	style_box.content_margin_right = 16
	style_box.content_margin_top = 16
	style_box.content_margin_bottom = 16
	
	add_theme_stylebox_override("panel", style_box)
	
	# 设置最小尺寸
	custom_minimum_size = Vector2(300, 400)

# 显示节点详细信息
func show_node_details(node_data: SkillTreeManager.SkillNode, unlock_manager: SkillUnlockManager) -> void:
	current_node_data = node_data
	current_node_id = node_data.node_id
	
	# 更新招式名称
	if skill_name_label:
		skill_name_label.text = node_data.skill_name
		skill_name_label.add_theme_font_size_override("font_size", 24)
		skill_name_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	
	# 更新描述
	if description_label:
		description_label.text = node_data.description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# 更新品阶
	if tier_label:
		var tier_name = TIER_NAMES.get(node_data.tier, "未知品阶")
		tier_label.text = "品阶: " + tier_name
		
		# 根据品阶设置颜色
		var tier_color = SkillNode.TIER_COLORS.get(node_data.tier, Color.WHITE)
		tier_label.add_theme_color_override("font_color", tier_color)
	
	# 更新属性信息
	_update_stats_display(node_data)
	
	# 更新前置条件
	_update_requirements_display(node_data, unlock_manager)
	
	# 更新解锁按钮状态
	_update_unlock_button(node_data, unlock_manager)
	
	# 显示面板
	show()

# 更新属性信息显示
func _update_stats_display(node_data: SkillTreeManager.SkillNode) -> void:
	if not stats_container:
		return
	
	# 清空现有内容
	for child in stats_container.get_children():
		child.queue_free()
	
	# 添加标题
	var title = Label.new()
	title.text = "招式属性"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1.0))
	stats_container.add_child(title)
	
	# 添加伤害系数（示例数据）
	var damage_label = Label.new()
	damage_label.text = "伤害系数: 1.2x"
	stats_container.add_child(damage_label)
	
	# 添加内力消耗（示例数据）
	var energy_label = Label.new()
	energy_label.text = "消耗内力: 20"
	stats_container.add_child(energy_label)
	
	# 添加路径类型
	var path_type_label = Label.new()
	var path_type_text = ""
	match node_data.path_type:
		SkillTreeManager.PathType.MAIN_PATH:
			path_type_text = "路径类型: 线性主干"
		SkillTreeManager.PathType.BRANCH:
			path_type_text = "路径类型: 分支专精"
		SkillTreeManager.PathType.CROSS_LINK:
			path_type_text = "路径类型: 网状关联"
	path_type_label.text = path_type_text
	stats_container.add_child(path_type_label)

# 更新前置条件显示
func _update_requirements_display(node_data: SkillTreeManager.SkillNode, unlock_manager: SkillUnlockManager) -> void:
	if not requirements_container:
		return
	
	# 清空现有内容
	for child in requirements_container.get_children():
		child.queue_free()
	
	# 添加标题
	var title = Label.new()
	title.text = "解锁条件"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1.0))
	requirements_container.add_child(title)
	
	# 显示前置节点
	if node_data.prerequisites.size() > 0:
		var prereq_label = Label.new()
		prereq_label.text = "前置招式: " + ", ".join(node_data.prerequisites)
		requirements_container.add_child(prereq_label)
	
	# 显示分支条件
	if node_data.branch_condition.size() > 0:
		for attr in node_data.branch_condition.keys():
			var value = node_data.branch_condition[attr]
			var condition_label = Label.new()
			condition_label.text = "需要 %s ≥ %d" % [attr, value]
			requirements_container.add_child(condition_label)
	
	# 显示跨武学依赖
	if node_data.cross_link_source.size() > 0:
		var cross_link_label = Label.new()
		cross_link_label.text = "需要学习其他武学"
		requirements_container.add_child(cross_link_label)
	
	# 如果有解锁管理器，显示具体缺失条件
	if unlock_manager:
		var missing_conditions = _get_missing_conditions(node_data, unlock_manager)
		if missing_conditions.size() > 0:
			var missing_title = Label.new()
			missing_title.text = "\n缺失条件:"
			missing_title.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1.0))
			requirements_container.add_child(missing_title)
			
			for condition in missing_conditions:
				var condition_label = Label.new()
				condition_label.text = "• " + condition
				condition_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1.0))
				requirements_container.add_child(condition_label)

# 获取缺失条件
func _get_missing_conditions(node_data: SkillTreeManager.SkillNode, unlock_manager: SkillUnlockManager) -> Array:
	var missing = []
	
	# 这里应该调用解锁管理器的验证方法
	# 由于我们没有完整的上下文，这里使用示例逻辑
	
	# 示例：检查节点状态
	if node_data.status == SkillTreeManager.NodeStatus.LOCKED:
		if node_data.prerequisites.size() > 0:
			missing.append("需要先解锁前置招式")
		
		if node_data.branch_condition.size() > 0:
			missing.append("属性条件未满足")
	
	return missing

# 更新解锁按钮状态
func _update_unlock_button(node_data: SkillTreeManager.SkillNode, unlock_manager: SkillUnlockManager) -> void:
	if not unlock_button:
		return
	
	match node_data.status:
		SkillTreeManager.NodeStatus.LOCKED:
			unlock_button.text = "条件未满足"
			unlock_button.disabled = true
		SkillTreeManager.NodeStatus.AVAILABLE:
			unlock_button.text = "领悟"
			unlock_button.disabled = false
		SkillTreeManager.NodeStatus.UNLOCKED:
			unlock_button.text = "已领悟"
			unlock_button.disabled = true
		SkillTreeManager.NodeStatus.ACTIVE:
			unlock_button.text = "已装备"
			unlock_button.disabled = true

# 按钮点击处理
func _on_unlock_button_pressed() -> void:
	if current_node_id != "":
		unlock_button_pressed.emit(current_node_id)

# 隐藏面板
func hide_panel() -> void:
	hide()
	current_node_data = null
	current_node_id = ""