extends CanvasLayer

# 战斗菜单交互管理器
# 处理武学指令菜单、目标选择、键盘和鼠标交互

# 信号定义
signal menu_interaction_completed(action_data)

# UI元素引用
@onready var martial_arts_menu = $CombatMenu/MartialArtsMenu
@onready var target_selection_cursor = $CombatMenu/TargetSelectionCursor
@onready var skill_tooltip = $CombatMenu/SkillTooltip

# 状态变量
var is_target_selection_active = false
var is_menu_visible = false
var current_selected_skill = null
var current_target_index = 0
var available_targets = []

# 初始化
func _ready():
	# 初始化菜单状态
	hide_martial_arts_menu()
	hide_target_selection()
	hide_skill_tooltip()
	
	# 连接信号
	martial_arts_menu.connect("skill_selected", _on_skill_selected)
	martial_arts_menu.connect("menu_closed", _on_menu_closed)

# 显示武学指令菜单
func show_martial_arts_menu(skill_data):
	# 更新技能数据
	martial_arts_menu.update_skills(skill_data)
	
	# 显示菜单
	martial_arts_menu.show()
	is_menu_visible = true
	
	# 重置选择
	current_selected_skill = null

# 隐藏武学指令菜单
func hide_martial_arts_menu():
	martial_arts_menu.hide()
	is_menu_visible = false

# 处理目标选择
func handle_target_selection(target_data):
	# 存储可用目标
	available_targets = target_data
	current_target_index = 0
	
	# 激活目标选择模式
	is_target_selection_active = true
	
	# 显示目标选择光标
	show_target_selection()

# 显示目标选择光标
func show_target_selection():
	if available_targets.size() > 0:
		# 高亮当前目标
		highlight_target(available_targets[current_target_index])

# 隐藏目标选择
func hide_target_selection():
	# 移除所有目标高亮
	for target in available_targets:
		remove_target_highlight(target)

# 高亮目标
func highlight_target(target):
	# 在目标上显示高亮效果
	if target.has_method("highlight"):
		target.highlight()

# 移除目标高亮
func remove_target_highlight(target):
	# 移除目标的高亮效果
	if target.has_method("remove_highlight"):
		target.remove_highlight()

# 切换目标
func switch_target(direction):
	if available_targets.size() == 0:
		return
	
	# 移除当前目标高亮
	remove_target_highlight(available_targets[current_target_index])
	
	# 更新目标索引
	if direction > 0:
		current_target_index = (current_target_index + 1) % available_targets.size()
	else:
		current_target_index = (current_target_index - 1 + available_targets.size()) % available_targets.size()
	
	# 高亮新目标
	highlight_target(available_targets[current_target_index])

# 确认目标选择
func confirm_target_selection():
	if available_targets.size() > 0:
		var selected_target = available_targets[current_target_index]
		
		# 构建行动数据
		var action_data = {
			"skill": current_selected_skill,
			"target": selected_target,
			"action_type": "skill_use"
		}
		
		# 发送行动完成信号
		emit_signal("menu_interaction_completed", action_data)
		
		# 重置状态
		is_target_selection_active = false
		hide_target_selection()
		
		return true
	
	return false

# 处理输入事件
func process_input(event):
	if event is InputEventKey and event.pressed:
		if is_target_selection_active:
			# 处理目标选择模式下的键盘输入
			if event.key_label == KEY_W || event.key_label == KEY_UP:
				switch_target(-1)
			elif event.key_label == KEY_S || event.key_label == KEY_DOWN:
				switch_target(1)
			elif event.key_label == KEY_A || event.key_label == KEY_LEFT:
				switch_target(-1)
			elif event.key_label == KEY_D || event.key_label == KEY_RIGHT:
				switch_target(1)
			elif event.key_label == KEY_ENTER:
				confirm_target_selection()
			elif event.key_label == KEY_ESCAPE:
				cancel_target_selection()
		elif is_menu_visible:
			# 处理菜单模式下的键盘输入
			if event.key_label == KEY_ESCAPE:
				hide_martial_arts_menu()
				emit_signal("menu_interaction_completed", {"action_type": "cancel"})

# 取消目标选择
func cancel_target_selection():
	is_target_selection_active = false
	hide_target_selection()
	
	# 重新显示菜单
	show_martial_arts_menu([])

# 显示技能工具提示
func show_skill_tooltip(skill_data, position):
	skill_tooltip.text = format_skill_tooltip(skill_data)
	skill_tooltip.position = position
	skill_tooltip.show()

# 隐藏技能工具提示
func hide_skill_tooltip():
	skill_tooltip.hide()

# 格式化技能工具提示
func format_skill_tooltip(skill_data):
	var tooltip_text = skill_data.name + "\n"
	tooltip_text += "消耗: " + str(skill_data.cost) + " " + skill_data.cost_type + "\n"
	tooltip_text += "冷却: " + str(skill_data.cooldown) + " 回合\n"
	tooltip_text += "描述: " + skill_data.description
	
	return tooltip_text

# 处理技能选择
func _on_skill_selected(skill):
	current_selected_skill = skill
	
	# 如果技能需要目标，则激活目标选择
	if skill.requires_target:
		handle_target_selection(skill.potential_targets)
	else:
		# 如果技能不需要目标，直接完成
		var action_data = {
			"skill": skill,
			"action_type": "skill_use",
			"target": null
		}
		emit_signal("menu_interaction_completed", action_data)

# 处理菜单关闭
func _on_menu_closed():
	hide_martial_arts_menu()
	emit_signal("menu_interaction_completed", {"action_type": "cancel"})

# 处理鼠标悬停
func _on_skill_mouse_hovered(skill, mouse_position):
	show_skill_tooltip(skill, mouse_position)

# 处理鼠标离开
func _on_skill_mouse_exited():
	hide_skill_tooltip()

# 处理鼠标点击
func _on_skill_mouse_clicked(skill):
	_on_skill_selected(skill)