extends Control
class_name CharacterGrowthUiScript
## CharacterGrowthUiScript - 角色成长UI脚本
##
## 负责管理角色成长UI的显示和交互
## 包括角色面板、属性分配和天赋网格

# 节点引用
@onready var tab_container: TabContainer = $TabContainer

# 角色面板节点（Tab 0）
@onready var character_panel = $TabContainer/角色面板
@onready var level_value: Label = $TabContainer/角色面板/MarginContainer/VBoxContainer/LevelContainer/LevelValue
@onready var realm_value: Label = $TabContainer/角色面板/MarginContainer/VBoxContainer/RealmContainer/RealmValue
@onready var strength_value: Label = $TabContainer/角色面板/MarginContainer/VBoxContainer/AttributesGrid/StrengthValue
@onready var agility_value: Label = $TabContainer/角色面板/MarginContainer/VBoxContainer/AttributesGrid/AgilityValue
@onready var constitution_value: Label = $TabContainer/角色面板/MarginContainer/VBoxContainer/AttributesGrid/ConstitutionValue
@onready var intelligence_value: Label = $TabContainer/角色面板/MarginContainer/VBoxContainer/AttributesGrid/IntelligenceValue
@onready var willpower_value: Label = $TabContainer/角色面板/MarginContainer/VBoxContainer/AttributesGrid/WillpowerValue
@onready var luck_value: Label = $TabContainer/角色面板/MarginContainer/VBoxContainer/AttributesGrid/LuckValue

# 属性分配节点（Tab 1）
@onready var attribute_panel = $TabContainer/属性分配
@onready var available_points_value: Label = $TabContainer/属性分配/MarginContainer/VBoxContainer/AvailablePointsContainer/AvailablePointsValue
@onready var strength_slider: HSlider = $TabContainer/属性分配/MarginContainer/VBoxContainer/StrengthContainer/StrengthSlider
@onready var agility_slider: HSlider = $TabContainer/属性分配/MarginContainer/VBoxContainer/AgilityContainer/AgilitySlider
@onready var constitution_slider: HSlider = $TabContainer/属性分配/MarginContainer/VBoxContainer/ConstitutionContainer/ConstitutionSlider
@onready var intelligence_slider: HSlider = $TabContainer/属性分配/MarginContainer/VBoxContainer/IntelligenceContainer/IntelligenceSlider
@onready var willpower_slider: HSlider = $TabContainer/属性分配/MarginContainer/VBoxContainer/WillpowerContainer/WillpowerSlider
@onready var luck_slider: HSlider = $TabContainer/属性分配/MarginContainer/VBoxContainer/LuckContainer/LuckSlider
@onready var confirm_button: Button = $TabContainer/属性分配/MarginContainer/VBoxContainer/ButtonsContainer/ConfirmButton
@onready var reset_button: Button = $TabContainer/属性分配/MarginContainer/VBoxContainer/ButtonsContainer/ResetButton

# 天赋网格节点（Tab 2）
@onready var talent_panel = $TabContainer/天赋网格
@onready var talent_grid_container: GridContainer = $TabContainer/天赋网格/MarginContainer/VBoxContainer/TalentGrid

# 角色系统引用
var character_system: CharacterSystem = null

# 临时属性分配数据
var temp_attribute_allocation = {
	"strength": 0,
	"agility": 0,
	"constitution": 0,
	"intelligence": 0,
	"willpower": 0,
	"luck": 0
}

func _ready() -> void:
	print("[CharacterGrowthUI] Initialized")
	
	# 获取角色系统引用
	character_system = get_node_or_null("/root/CharacterSystem")
	if not character_system:
		push_warning("[CharacterGrowthUI] CharacterSystem not found!")
		return
	
	# 连接角色系统信号
	character_system.level_up_event.connect(_on_level_up)
	character_system.realm_breakthrough.connect(_on_realm_breakthrough)
	character_system.experience_gained.connect(_on_experience_gained)
	character_system.attribute_points_allocated.connect(_on_attribute_allocated)
	character_system.attributes_reset.connect(_on_attributes_reset)
	
	# 连接UI按钮信号
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_allocation)
	if reset_button:
		reset_button.pressed.connect(_on_reset_allocation)
	
	# 连接属性滑块信号
	if strength_slider:
		strength_slider.value_changed.connect(_on_strength_slider_changed)
	if agility_slider:
		agility_slider.value_changed.connect(_on_agility_slider_changed)
	if constitution_slider:
		constitution_slider.value_changed.connect(_on_constitution_slider_changed)
	if intelligence_slider:
		intelligence_slider.value_changed.connect(_on_intelligence_slider_changed)
	if willpower_slider:
		willpower_slider.value_changed.connect(_on_willpower_slider_changed)
	if luck_slider:
		luck_slider.value_changed.connect(_on_luck_slider_changed)
	
	# 初始化天赋网格按钮
	_initialize_talent_grid()
	
	# 初始化UI显示
	_update_all_ui()
	# 测试升级流程（添加这段）
	# await get_tree().create_timer(2.0).timeout  # 等待2秒
	# if character_system:
	#	print("=== 开始升级测试 ===")
	#	character_system.add_experience(1000)
	#	print("=== 升级测试完成 ===")

func show_ui() -> void:
	"""显示UI"""
	show()
	_update_all_ui()

func hide_ui() -> void:
	"""隐藏UI"""
	hide()

# ============================================================================
# 信号处理函数
# ============================================================================

func _on_level_up(new_level: int, attribute_points: int, talent_points: int) -> void:
	"""角色升级事件"""
	print("[CharacterGrowthUI] Level up to %d" % new_level)
	_update_all_ui()

func _on_realm_breakthrough(new_realm: String, realm_bonus: float, realm_index: int) -> void:
	"""境界突破事件"""
	print("[CharacterGrowthUI] Realm breakthrough to %s" % new_realm)
	_update_all_ui()

func _on_experience_gained(amount: int, current_exp: int, required_exp: int) -> void:
	"""经验值获得事件"""
	_update_character_panel()

func _on_attribute_allocated(attribute_name: String, points: int, new_value: int) -> void:
	"""属性点分配事件"""
	print("[CharacterGrowthUI] Attribute allocated: %s +%d = %d" % [attribute_name, points, new_value])
	_update_all_ui()

func _on_attributes_reset(free_reset_used: bool) -> void:
	"""属性重置事件"""
	print("[CharacterGrowthUI] Attributes reset (free: %s)" % free_reset_used)
	_reset_temp_allocation()
	_update_all_ui()

# ============================================================================
# 属性分配滑块处理
# ============================================================================

func _on_strength_slider_changed(value: float) -> void:
	temp_attribute_allocation["strength"] = int(value)
	_update_allocation_preview()

func _on_agility_slider_changed(value: float) -> void:
	temp_attribute_allocation["agility"] = int(value)
	_update_allocation_preview()

func _on_constitution_slider_changed(value: float) -> void:
	temp_attribute_allocation["constitution"] = int(value)
	_update_allocation_preview()

func _on_intelligence_slider_changed(value: float) -> void:
	temp_attribute_allocation["intelligence"] = int(value)
	_update_allocation_preview()

func _on_willpower_slider_changed(value: float) -> void:
	temp_attribute_allocation["willpower"] = int(value)
	_update_allocation_preview()

func _on_luck_slider_changed(value: float) -> void:
	temp_attribute_allocation["luck"] = int(value)
	_update_allocation_preview()

func _on_confirm_allocation() -> void:
	"""确认属性分配"""
	if not character_system:
		return
	
	# 执行属性分配
	for attr_name in temp_attribute_allocation:
		var points = temp_attribute_allocation[attr_name]
		if points > 0:
			character_system.allocate_attribute_points(attr_name, points)
	
	# 重置临时分配
	_reset_temp_allocation()

func _on_reset_allocation() -> void:
	"""重置属性分配"""
	_reset_temp_allocation()
	_update_allocation_panel()

# ============================================================================
# UI更新函数
# ============================================================================

func _update_all_ui() -> void:
	"""更新所有UI"""
	_update_character_panel()
	_update_allocation_panel()
	_update_talent_panel()

func _update_character_panel() -> void:
	"""更新角色面板"""
	if not character_system:
		return
	
	var final_attrs = character_system.get_final_attributes()
	var current_realm = character_system.get_current_realm()
	var required_exp = character_system.get_exp_required_for_level(character_system.level + 1)
	
	if level_value:
		level_value.text = "%d" % character_system.level
	if realm_value:
		realm_value.text = "%s (加成 %.0f%%)" % [current_realm["name"], (character_system.realm_bonus - 1.0) * 100]
	
	if strength_value:
		strength_value.text = "%d" % final_attrs.strength
	if agility_value:
		agility_value.text = "%d" % final_attrs.agility
	if constitution_value:
		constitution_value.text = "%d" % final_attrs.constitution
	if intelligence_value:
		intelligence_value.text = "%d" % final_attrs.intelligence
	if willpower_value:
		willpower_value.text = "%d" % final_attrs.willpower
	if luck_value:
		luck_value.text = "%d" % final_attrs.luck

func _update_allocation_panel() -> void:
	"""更新属性分配面板"""
	if not character_system:
		return
	
	var available = character_system.total_attribute_points - character_system.allocated_attribute_points
	
	if available_points_value:
		available_points_value.text = "%d" % available
	
	# 更新滑块最大值
	var max_allocatable = available
	if strength_slider:
		strength_slider.max_value = max_allocatable
		strength_slider.value = temp_attribute_allocation["strength"]
	if agility_slider:
		agility_slider.max_value = max_allocatable
		agility_slider.value = temp_attribute_allocation["agility"]
	if constitution_slider:
		constitution_slider.max_value = max_allocatable
		constitution_slider.value = temp_attribute_allocation["constitution"]
	if intelligence_slider:
		intelligence_slider.max_value = max_allocatable
		intelligence_slider.value = temp_attribute_allocation["intelligence"]
	if willpower_slider:
		willpower_slider.max_value = max_allocatable
		willpower_slider.value = temp_attribute_allocation["willpower"]
	if luck_slider:
		luck_slider.max_value = max_allocatable
		luck_slider.value = temp_attribute_allocation["luck"]

func _update_allocation_preview() -> void:
	"""更新属性分配预览"""
	if not character_system:
		return
	
	var total_allocated = 0
	for points in temp_attribute_allocation.values():
		total_allocated += points
	
	var available = character_system.total_attribute_points - character_system.allocated_attribute_points
	var remaining = available - total_allocated
	
	if available_points_value:
		available_points_value.text = "%d (剩余: %d)" % [available, remaining]

func _update_talent_panel() -> void:
	"""更新天赋网格面板"""
	if not character_system:
		return
	
	var available_talent_points = character_system.total_talent_points - character_system.allocated_talent_points
	
	# 在天赋网格的TitleLabel中显示可用天赋点
	var title_label = talent_grid_container.get_parent().get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = "天赋网格 (4x4) - 可用天赋点: %d" % available_talent_points
	
	# 更新天赋网格按钮状态
	_update_talent_grid_buttons()

func _initialize_talent_grid() -> void:
	"""初始化天赋网格按钮"""
	if not talent_grid_container:
		return
	
	# 使用场景中已有的16个按钮，为它们连接信号
	var button_index = 0
	for row in range(4):
		for col in range(4):
			if button_index >= talent_grid_container.get_child_count():
				break
			
			var button = talent_grid_container.get_child(button_index)
			if button is Button:
				# 连接按钮信号
				button.pressed.connect(_on_talent_button_pressed.bind(row, col))
				# 设置初始文本
				button.text = "天赋\n%d,%d" % [row, col]
			
			button_index += 1

func _update_talent_grid_buttons() -> void:
	"""更新天赋网格按钮状态"""
	if not character_system or not talent_grid_container:
		return
	
	var button_index = 0
	for row in range(4):
		for col in range(4):
			if button_index >= talent_grid_container.get_child_count():
				break
			
			var button = talent_grid_container.get_child(button_index)
			if button is Button:
				var is_unlocked = character_system.talent_grid[row][col]["unlocked"]
				
				# 更新按钮外观
				if is_unlocked:
					button.modulate = Color(1.0, 0.84, 0.0)  # 金色
					button.text = "已点亮\n%d,%d" % [row, col]
				else:
					button.modulate = Color(0.5, 0.5, 0.5)  # 灰色
					button.text = "未点亮\n%d,%d" % [row, col]
			
			button_index += 1

func _on_talent_button_pressed(row: int, col: int) -> void:
	"""天赋按钮点击"""
	if not character_system:
		return
	
	if character_system.unlock_talent(row, col):
		print("[CharacterGrowthUI] Talent unlocked at (%d, %d)" % [row, col])
		_update_talent_panel()
		_update_character_panel()  # 更新角色面板以反映天赋效果
	else:
		print("[CharacterGrowthUI] Failed to unlock talent at (%d, %d)" % [row, col])

func _reset_temp_allocation() -> void:
	"""重置临时属性分配"""
	temp_attribute_allocation = {
		"strength": 0,
		"agility": 0,
		"constitution": 0,
		"intelligence": 0,
		"willpower": 0,
		"luck": 0
	}
