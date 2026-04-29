## CombatMenuManager
## CombatMenuManager系统
##
## 主要功能：
## - 待补充

extends Node

class_name CombatMenuManager

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

## 战斗菜单管理器 - 管理战斗菜单交互
## 处理武学指令菜单、目标选择和用户输入

class_name CombatMenuManager

# 信号定义
signal menu_interaction_completed(action_data: Dictionary)
signal menu_opened
signal menu_closed
signal target_selected(target_id: String)

# 菜单状态枚举
enum MenuState {
	CLOSED,
	MARTIAL_ARTS_MENU,
	TARGET_SELECTION,
	SKILL_PREVIEW
}

# 当前菜单状态
var current_state: MenuState = MenuState.CLOSED

# UI元素引用
@onready var martial_arts_container = $CombatMenu/MartialArtsContainer
@onready var target_selector = $CombatMenu/TargetSelector
@onready var skill_preview = $CombatMenu/SkillPreview

# 菜单数据
var available_skills: Array[Dictionary] = []
var available_targets: Array[String] = []
var current_selected_skill: Dictionary = {}
var current_selected_target: String = ""
var current_selected_index: int = 0

# 输入处理
var input_enabled: bool = true
var input_delay: float = 0.0
var input_delay_threshold: float = 0.1  # 100ms延迟限制

# 悬停预览
var hover_timer: float = 0.0
var hover_threshold: float = 0.5  # 0.5秒悬停显示预览

func _ready() -> void:
	# 初始化菜单
	close_menu()
	
	# 连接信号
	get_tree().root.gui_focus_changed.connect(_on_gui_focus_changed)

func _process(delta: float) -> void:
	# 处理输入延迟
	if input_delay > 0:
		input_delay -= delta
	
	# 处理悬停预览
	if current_state == MenuState.MARTIAL_ARTS_MENU:
		hover_timer += delta
		if hover_timer >= hover_threshold:
			_show_skill_preview()
			hover_timer = 0.0

func _input(event: InputEvent) -> void:
	if not input_enabled or input_delay > 0:
		return
	
	match current_state:
		MenuState.MARTIAL_ARTS_MENU:
			_handle_martial_arts_input(event)
		MenuState.TARGET_SELECTION:
			_handle_target_selection_input(event)

## 显示武学指令菜单
func show_martial_arts_menu(skill_data: Array[Dictionary]) -> void:
	available_skills = skill_data
	current_state = MenuState.MARTIAL_ARTS_MENU
	current_selected_index = 0
	
	# 清除现有菜单项
	for child in martial_arts_container.get_children():
		child.queue_free()
	
	# 创建菜单项
	for i in range(available_skills.size()):
		var skill = available_skills[i]
		var menu_item = _create_skill_menu_item(skill, i)
		martial_arts_container.add_child(menu_item)
	
	# 显示菜单
	martial_arts_container.visible = true
	menu_opened.emit()

## 处理目标选择
func handle_target_selection(target_data: Array[String]) -> void:
	available_targets = target_data
	current_state = MenuState.TARGET_SELECTION
	current_selected_index = 0
	
	# 清除现有目标
	for child in target_selector.get_children():
		child.queue_free()
	
	# 创建目标项
	for i in range(available_targets.size()):
		var target_id = available_targets[i]
		var target_item = _create_target_item(target_id, i)
		target_selector.add_child(target_item)
	
	# 显示目标选择器
	target_selector.visible = true
	_highlight_current_target()

## 处理用户输入
func process_input(input_event: InputEvent) -> void:
	if not input_enabled:
		return
	
	_input(input_event)

## 关闭菜单
func close_menu() -> void:
	current_state = MenuState.CLOSED
	martial_arts_container.visible = false
	target_selector.visible = false
	skill_preview.visible = false
	menu_closed.emit()

## 内部方法：处理武学菜单输入
func _handle_martial_arts_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_UP:
				_move_selection(-1)
				input_delay = input_delay_threshold
				get_tree().root.set_input_as_handled()
			
			KEY_S, KEY_DOWN:
				_move_selection(1)
				input_delay = input_delay_threshold
				get_tree().root.set_input_as_handled()
			
			KEY_A, KEY_LEFT:
				_move_selection(-1)
				input_delay = input_delay_threshold
				get_tree().root.set_input_as_handled()
			
			KEY_D, KEY_RIGHT:
				_move_selection(1)
				input_delay = input_delay_threshold
				get_tree().root.set_input_as_handled()
			
			KEY_ENTER, KEY_SPACE:
				_confirm_skill_selection()
				input_delay = input_delay_threshold
				get_tree().root.set_input_as_handled()
			
			KEY_ESCAPE:
				close_menu()
				input_delay = input_delay_threshold
				get_tree().root.set_input_as_handled()

## 内部方法：处理目标选择输入
func _handle_target_selection_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_UP:
				_move_target_selection(-1)
				input_delay = input_delay_threshold
				get_tree().root.set_input_as_handled()
			
			KEY_S, KEY_DOWN:
				_move_target_selection(1)
				input_delay = input_delay_threshold
				get_tree().root.set_input_as_handled()
			
			KEY_A, KEY_LEFT:
				_move_target_selection(-1)
				input_delay = input_delay_threshold
				get_tree().root.set_input_as_handled()
			
			KEY_D, KEY_RIGHT:
				_move_target_selection(1)
				input_delay = input_delay_threshold
				get_tree().root.set_input_as_handled()
			
			KEY_ENTER, KEY_SPACE:
				_confirm_target_selection()
				input_delay = input_delay_threshold
				get_tree().root.set_input_as_handled()
			
			KEY_ESCAPE:
				current_state = MenuState.MARTIAL_ARTS_MENU
				target_selector.visible = false
				input_delay = input_delay_threshold
				get_tree().root.set_input_as_handled()

## 内部方法：移动菜单选择
func _move_selection(direction: int) -> void:
	current_selected_index += direction
	current_selected_index = clamp(current_selected_index, 0, available_skills.size() - 1)
	_highlight_current_skill()
	hover_timer = 0.0  # 重置悬停计时器

## 内部方法：移动目标选择
func _move_target_selection(direction: int) -> void:
	current_selected_index += direction
	current_selected_index = clamp(current_selected_index, 0, available_targets.size() - 1)
	_highlight_current_target()

## 内部方法：确认技能选择
func _confirm_skill_selection() -> void:
	if current_selected_index < available_skills.size():
		current_selected_skill = available_skills[current_selected_index]
		current_state = MenuState.TARGET_SELECTION
		target_selector.visible = true
		current_selected_index = 0
		_highlight_current_target()

## 内部方法：确认目标选择
func _confirm_target_selection() -> void:
	if current_selected_index < available_targets.size():
		current_selected_target = available_targets[current_selected_index]
		
		# 发送菜单交互完成信号
		var action_data = {
			"skill": current_selected_skill,
			"target": current_selected_target
		}
		menu_interaction_completed.emit(action_data)
		target_selected.emit(current_selected_target)
		
		close_menu()

## 内部方法：高亮当前技能
func _highlight_current_skill() -> void:
	var children = martial_arts_container.get_children()
	for i in range(children.size()):
		if i == current_selected_index:
			children[i].modulate = Color.YELLOW
		else:
			children[i].modulate = Color.WHITE

## 内部方法：高亮当前目标
func _highlight_current_target() -> void:
	var children = target_selector.get_children()
	for i in range(children.size()):
		if i == current_selected_index:
			children[i].modulate = Color.YELLOW
		else:
			children[i].modulate = Color.WHITE

## 内部方法：显示技能预览
func _show_skill_preview() -> void:
	if current_selected_index < available_skills.size():
		var skill = available_skills[current_selected_index]
		skill_preview.visible = true
		
		# 更新预览内容
		if skill_preview.has_method("update_preview"):
			skill_preview.update_preview(skill)

## 内部方法：创建技能菜单项
func _create_skill_menu_item(skill: Dictionary, index: int) -> Control:
	var item = Control.new()
	item.custom_minimum_size = Vector2(200, 40)
	
	# 创建标签显示技能信息
	var label = Label.new()
	var skill_text = "%s (消耗: %d, 冷却: %d)" % [
		skill.get("name", "未知技能"),
		skill.get("cost", 0),
		skill.get("cooldown", 0)
	]
	label.text = skill_text
	item.add_child(label)
	
	return item

## 内部方法：创建目标项
func _create_target_item(target_id: String, index: int) -> Control:
	var item = Control.new()
	item.custom_minimum_size = Vector2(150, 40)
	
	# 创建标签显示目标信息
	var label = Label.new()
	label.text = target_id
	item.add_child(label)
	
	return item

## 内部方法：GUI焦点改变回调
func _on_gui_focus_changed(control: Control) -> void:
	# 处理鼠标悬停预览
	if control and control.is_inside_tree():
		hover_timer = 0.0

## 获取当前菜单状态
func get_menu_state() -> MenuState:
	return current_state

## 检查菜单是否打开
func is_menu_open() -> bool:
	return current_state != MenuState.CLOSED

## 启用/禁用输入
func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled

## 获取当前选中的技能
func get_selected_skill() -> Dictionary:
	return current_selected_skill

## 获取当前选中的目标
func get_selected_target() -> String:
	return current_selected_target