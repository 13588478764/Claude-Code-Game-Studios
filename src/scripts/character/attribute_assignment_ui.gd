extends Control

# 属性点分配系统 - UI管理器
# 负责管理属性点分配界面的显示和交互

# 信号定义
signal allocation_applied
signal assignment_interface_closed

# 引用AttributePointManager
var attribute_manager: Node = null

# UI元素引用
@onready var strength_label = $VBoxContainer/StrengthRow/ValueLabel
@onready var agility_label = $VBoxContainer/AgilityRow/ValueLabel
@onready var constitution_label = $VBoxContainer/ConstitutionRow/ValueLabel
@onready var intelligence_label = $VBoxContainer/IntelligenceRow/ValueLabel
@onready var willpower_label = $VBoxContainer/WillpowerRow/ValueLabel
@onready var luck_label = $VBoxContainer/LuckRow/ValueLabel
@onready var available_points_label = $VBoxContainer/AvailablePointsRow/ValueLabel

@onready var strength_add_button = $VBoxContainer/StrengthRow/AddButton
@onready var agility_add_button = $VBoxContainer/AgilityRow/AddButton
@onready var constitution_add_button = $VBoxContainer/ConstitutionRow/AddButton
@onready var intelligence_add_button = $VBoxContainer/IntelligenceRow/AddButton
@onready var willpower_add_button = $VBoxContainer/WillpowerRow/AddButton
@onready var luck_add_button = $VBoxContainer/LuckRow/AddButton

@onready var apply_button = $VBoxContainer/ApplyButton
@onready var close_button = $VBoxContainer/CloseButton
@onready var recommend_button = $VBoxContainer/RecommendButton

# 属性类型常量
const ATTRIBUTE_STRENGTH = "strength"      # 力道
const ATTRIBUTE_AGILITY = "agility"        # 身法  
const ATTRIBUTE_CONSTITUTION = "constitution"  # 根骨
const ATTRIBUTE_INTELLIGENCE = "intelligence"  # 悟性
const ATTRIBUTE_WILLPOWER = "willpower"    # 定力
const ATTRIBUTE_LUCK = "luck"              # 福缘

# 临时存储分配变化
var temp_allocation: Dictionary = {}

func _ready():
	# 初始化UI
	_setup_ui()
	
	# 连接按钮信号
	strength_add_button.pressed.connect(_on_strength_add_pressed)
	agility_add_button.pressed.connect(_on_agility_add_pressed)
	constitution_add_button.pressed.connect(_on_constitution_add_pressed)
	intelligence_add_button.pressed.connect(_on_intelligence_add_pressed)
	willpower_add_button.pressed.connect(_on_willpower_add_pressed)
	luck_add_button.pressed.connect(_on_luck_add_pressed)
	
	apply_button.pressed.connect(_on_apply_pressed)
	close_button.pressed.connect(_on_close_pressed)
	recommend_button.pressed.connect(_on_recommend_pressed)
	
	# 初始加载属性数据
	refresh_ui()

# 设置AttributePointManager引用
func set_attribute_manager(manager: Node) -> void:
	attribute_manager = manager
	refresh_ui()

# 设置UI可见性
func set_visible(visible: bool) -> void:
	.visible = visible
	if visible:
		refresh_ui()

# 显示分配界面
func show_assignment_interface() -> void:
	.visible = true
	refresh_ui()

# 隐藏分配界面
func hide_assignment_interface() -> void:
	.visible = false

# 设置初始UI状态
func _setup_ui():
	# 初始化临时分配数据
	temp_allocation = {
		ATTRIBUTE_STRENGTH: 0,
		ATTRIBUTE_AGILITY: 0,
		ATTRIBUTE_CONSTITUTION: 0,
		ATTRIBUTE_INTELLIGENCE: 0,
		ATTRIBUTE_WILLPOWER: 0,
		ATTRIBUTE_LUCK: 0
	}

# 刷新UI显示
func refresh_ui():
	if not attribute_manager:
		push_error("Attribute manager not set")
		return
	
	# 获取当前属性值
	var current_attributes = attribute_manager.get_all_attributes()
	var available_points = attribute_manager.get_available_points()
	
	# 显示当前属性值 + 临时分配值
	strength_label.text = str(current_attributes[ATTRIBUTE_STRENGTH] + temp_allocation[ATTRIBUTE_STRENGTH])
	agility_label.text = str(current_attributes[ATTRIBUTE_AGILITY] + temp_allocation[ATTRIBUTE_AGILITY])
	constitution_label.text = str(current_attributes[ATTRIBUTE_CONSTITUTION] + temp_allocation[ATTRIBUTE_CONSTITUTION])
	intelligence_label.text = str(current_attributes[ATTRIBUTE_INTELLIGENCE] + temp_allocation[ATTRIBUTE_INTELLIGENCE])
	willpower_label.text = str(current_attributes[ATTRIBUTE_WILLPOWER] + temp_allocation[ATTRIBUTE_WILLPOWER])
	luck_label.text = str(current_attributes[ATTRIBUTE_LUCK] + temp_allocation[ATTRIBUTE_LUCK])
	
	# 显示可用点数（减去已分配的临时点数）
	var total_allocated_temp = 0
	for attr in temp_allocation:
		total_allocated_temp += temp_allocation[attr]
	available_points_label.text = str(max(0, available_points - total_allocated_temp))

# 处理属性增加按钮点击
func _on_strength_add_pressed():
	_add_temp_allocation(ATTRIBUTE_STRENGTH)

func _on_agility_add_pressed():
	_add_temp_allocation(ATTRIBUTE_AGILITY)

func _on_constitution_add_pressed():
	_add_temp_allocation(ATTRIBUTE_CONSTITUTION)

func _on_intelligence_add_pressed():
	_add_temp_allocation(ATTRIBUTE_INTELLIGENCE)

func _on_willpower_add_pressed():
	_add_temp_allocation(ATTRIBUTE_WILLPOWER)

func _on_luck_add_pressed():
	_add_temp_allocation(ATTRIBUTE_LUCK)

# 添加临时分配
func _add_temp_allocation(attribute_type: String):
	if not attribute_manager:
		push_error("Attribute manager not set")
		return
	
	# 检查是否有可用点数
	var available_points = attribute_manager.get_available_points()
	var total_allocated_temp = 0
	for attr in temp_allocation:
		total_allocated_temp += temp_allocation[attr]
	
	if total_allocated_temp >= available_points:
		push_warning("No available points to allocate")
		return
	
	# 检查属性是否达到上限
	var current_attributes = attribute_manager.get_all_attributes()
	var current_value = current_attributes[attribute_type] + temp_allocation[attribute_type]
	if current_value >= 99:  # MAX_ATTRIBUTE_VALUE
		push_warning("Attribute %s has reached maximum value" % attribute_type)
		return
	
	# 增加临时分配
	temp_allocation[attribute_type] += 1
	refresh_ui()

# 应用分配变更
func apply_allocation_changes() -> bool:
	if not attribute_manager:
		push_error("Attribute manager not set")
		return false
	
	# 检查是否有临时分配
	var has_changes = false
	for attr in temp_allocation:
		if temp_allocation[attr] > 0:
			has_changes = true
			break
	
	if not has_changes:
		push_warning("No changes to apply")
		return false
	
	# 应用所有临时分配
	for attr in temp_allocation:
		for i in range(temp_allocation[attr]):
			attribute_manager.allocate_point(attr)
	
	# 重置临时分配
	for attr in temp_allocation:
		temp_allocation[attr] = 0
	
	# 发送信号
	emit_signal("allocation_applied")
	refresh_ui()
	
	return true

# 智能推荐分配方案
func recommend_allocation_scheme(current_martial_arts: Array = []) -> Dictionary:
	if not attribute_manager:
		push_error("Attribute manager not set")
		return {}
	
	# 基于当前武学配置提供推荐
	var recommendation: Dictionary = {}
	
	# 根据武学类型推荐属性
	for martial_art in current_martial_arts:
		if "sword" in martial_art.name.to_lower() or "剑" in martial_art.name:
			# 剑法类武学推荐力道和悟性
			recommendation[ATTRIBUTE_STRENGTH] = recommendation.get(ATTRIBUTE_STRENGTH, 0) + 1
			recommendation[ATTRIBUTE_INTELLIGENCE] = recommendation.get(ATTRIBUTE_INTELLIGENCE, 0) + 1
		elif "staff" in martial_art.name.to_lower() or "杖" in martial_art.name:
			# 棍杖类武学推荐根骨和悟性
			recommendation[ATTRIBUTE_CONSTITUTION] = recommendation.get(ATTRIBUTE_CONSTITUTION, 0) + 1
			recommendation[ATTRIBUTE_INTELLIGENCE] = recommendation.get(ATTRIBUTE_INTELLIGENCE, 0) + 1
		elif "fist" in martial_art.name.to_lower() or "拳" in martial_art.name:
			# 拳法类武学推荐力道和身法
			recommendation[ATTRIBUTE_STRENGTH] = recommendation.get(ATTRIBUTE_STRENGTH, 0) + 1
			recommendation[ATTRIBUTE_AGILITY] = recommendation.get(ATTRIBUTE_AGILITY, 0) + 1
		elif "dodge" in martial_art.name.to_lower() or "闪" in martial_art.name or "身法" in martial_art.name:
			# 身法类武学推荐身法和定力
			recommendation[ATTRIBUTE_AGILITY] = recommendation.get(ATTRIBUTE_AGILITY, 0) + 1
			recommendation[ATTRIBUTE_WILLPOWER] = recommendation.get(ATTRIBUTE_WILLPOWER, 0) + 1
		elif "heal" in martial_art.name.to_lower() or "疗" in martial_art.name or "治疗" in martial_art.name:
			# 治疗类武学推荐悟性和定力
			recommendation[ATTRIBUTE_INTELLIGENCE] = recommendation.get(ATTRIBUTE_INTELLIGENCE, 0) + 1
			recommendation[ATTRIBUTE_WILLPOWER] = recommendation.get(ATTRIBUTE_WILLPOWER, 0) + 1
	
	return recommendation

# 处理应用按钮点击
func _on_apply_pressed():
	apply_allocation_changes()

# 处理关闭按钮点击
func _on_close_pressed():
	# 重置临时分配
	for attr in temp_allocation:
		temp_allocation[attr] = 0
	refresh_ui()
	hide_assignment_interface()
	emit_signal("assignment_interface_closed")

# 处理推荐按钮点击
func _on_recommend_pressed():
	# 这里可以调用推荐逻辑，或者让外部系统提供武学信息
	var current_martial_arts = []  # 从外部系统获取当前武学
	var recommendation = recommend_allocation_scheme(current_martial_arts)
	
	# 应用推荐（如果用户确认）
	_apply_recommendation(recommendation)

# 应用推荐
func _apply_recommendation(recommendation: Dictionary):
	if not attribute_manager:
		return
	
	var available_points = attribute_manager.get_available_points()
	var total_allocated_temp = 0
	for attr in temp_allocation:
		total_allocated_temp += temp_allocation[attr]
	var remaining_points = available_points - total_allocated_temp
	
	# 应用推荐，但不超过可用点数
	for attr in recommendation:
		var points_to_add = min(recommendation[attr], remaining_points)
		temp_allocation[attr] += points_to_add
		remaining_points -= points_to_add
		if remaining_points <= 0:
			break
	
	refresh_ui()

# 获取当前临时分配状态
func get_temp_allocation() -> Dictionary:
	return temp_allocation.duplicate()

# 重置临时分配
func reset_temp_allocation() -> void:
	for attr in temp_allocation:
		temp_allocation[attr] = 0
	refresh_ui()