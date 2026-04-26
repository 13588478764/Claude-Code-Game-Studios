# 武侠奇遇录 - 角色成长UI脚本
# 负责管理角色成长UI的显示和交互，包括角色面板、属性分配和天赋网格

extends Control

# UI元素引用
var character_panel = null
var attribute_allocation_panel = null
var talent_grid_panel = null

# 角色面板元素
var level_value_label = null
var realm_value_label = null
var strength_value_label = null
var agility_value_label = null
var constitution_value_label = null
var intelligence_value_label = null
var willpower_value_label = null
var luck_value_label = null
var attribute_points_value_label = null
var close_character_button = null
var reset_character_button = null
var apply_character_button = null
var strength_add_button = null
var agility_add_button = null
var constitution_add_button = null
var intelligence_add_button = null
var willpower_add_button = null
var luck_add_button = null

# 属性分配面板元素
var strength_slider = null
var agility_slider = null
var constitution_slider = null
var intelligence_slider = null
var willpower_slider = null
var luck_slider = null
var strength_slider_value = null
var agility_slider_value = null
var constitution_slider_value = null
var intelligence_slider_value = null
var willpower_slider_value = null
var luck_slider_value = null
var available_points_value = null
var reset_allocation_button = null
var apply_allocation_button = null

# 天赋网格面板元素
var talent_grid_container = null
var talent_nodes = []
var talent_grid_description = null
var reset_talents_button = null
var close_talent_grid_button = null

# 数据引用
var character_system = null
var temp_attributes = {}
var temp_attribute_points = 0
var temp_talent_points = 0

func _ready():
	# 初始化UI元素引用
	initialize_ui_elements()
	
	# 连接信号
	connect_signals()
	
	# 初始化数据
	initialize_data()
	
	# 连接角色系统信号
	connect_character_system_signals()

func initialize_ui_elements():
	"""初始化UI元素引用"""
	# 获取面板引用
	character_panel = get_node("TabContainer/CharacterPanel")
	attribute_allocation_panel = get_node("TabContainer/AttributeAllocationPanel")
	talent_grid_panel = get_node("TabContainer/TalentGridPanel")
	
	# 角色面板元素
	level_value_label = get_node("TabContainer/CharacterPanel/Background/LevelInfo/LevelValue")
	realm_value_label = get_node("TabContainer/CharacterPanel/Background/LevelInfo/RealmValue")
	strength_value_label = get_node("TabContainer/CharacterPanel/Background/AttributesPanel/StrengthRow/StrengthValue")
	agility_value_label = get_node("TabContainer/CharacterPanel/Background/AttributesPanel/AgilityRow/AgilityValue")
	constitution_value_label = get_node("TabContainer/CharacterPanel/Background/AttributesPanel/ConstitutionRow/ConstitutionValue")
	intelligence_value_label = get_node("TabContainer/CharacterPanel/Background/AttributesPanel/IntelligenceRow/IntelligenceValue")
	willpower_value_label = get_node("TabContainer/CharacterPanel/Background/AttributesPanel/WillpowerRow/WillpowerValue")
	luck_value_label = get_node("TabContainer/CharacterPanel/Background/AttributesPanel/LuckRow/LuckValue")
	attribute_points_value_label = get_node("TabContainer/CharacterPanel/Background/AttributePointsRow/AttributePointsValue")
	close_character_button = get_node("TabContainer/CharacterPanel/Background/CloseButton")
	reset_character_button = get_node("TabContainer/CharacterPanel/Background/AttributePointsRow/ResetButton")
	apply_character_button = get_node("TabContainer/CharacterPanel/Background/AttributePointsRow/ApplyButton")
	strength_add_button = get_node("TabContainer/CharacterPanel/Background/AttributesPanel/StrengthRow/StrengthAddButton")
	agility_add_button = get_node("TabContainer/CharacterPanel/Background/AttributesPanel/AgilityRow/AgilityAddButton")
	constitution_add_button = get_node("TabContainer/CharacterPanel/Background/AttributesPanel/ConstitutionRow/ConstitutionAddButton")
	intelligence_add_button = get_node("TabContainer/CharacterPanel/Background/AttributesPanel/IntelligenceRow/IntelligenceAddButton")
	willpower_add_button = get_node("TabContainer/CharacterPanel/Background/AttributesPanel/WillpowerRow/WillpowerAddButton")
	luck_add_button = get_node("TabContainer/CharacterPanel/Background/AttributesPanel/LuckRow/LuckAddButton")
	
	# 属性分配面板元素
	strength_slider = get_node("TabContainer/AttributeAllocationPanel/AttributeSliders/StrengthSliderRow/StrengthSlider")
	agility_slider = get_node("TabContainer/AttributeAllocationPanel/AttributeSliders/AgilitySliderRow/AgilitySlider")
	constitution_slider = get_node("TabContainer/AttributeAllocationPanel/AttributeSliders/ConstitutionSliderRow/ConstitutionSlider")
	intelligence_slider = get_node("TabContainer/AttributeAllocationPanel/AttributeSliders/IntelligenceSliderRow/IntelligenceSlider")
	willpower_slider = get_node("TabContainer/AttributeAllocationPanel/AttributeSliders/WillpowerSliderRow/WillpowerSlider")
	luck_slider = get_node("TabContainer/AttributeAllocationPanel/AttributeSliders/LuckSliderRow/LuckSlider")
	strength_slider_value = get_node("TabContainer/AttributeAllocationPanel/AttributeSliders/StrengthSliderRow/StrengthSliderValue")
	agility_slider_value = get_node("TabContainer/AttributeAllocationPanel/AttributeSliders/AgilitySliderRow/AgilitySliderValue")
	constitution_slider_value = get_node("TabContainer/AttributeAllocationPanel/AttributeSliders/ConstitutionSliderRow/ConstitutionSliderValue")
	intelligence_slider_value = get_node("TabContainer/AttributeAllocationPanel/AttributeSliders/IntelligenceSliderRow/IntelligenceSliderValue")
	willpower_slider_value = get_node("TabContainer/AttributeAllocationPanel/AttributeSliders/WillpowerSliderRow/WillpowerSliderValue")
	luck_slider_value = get_node("TabContainer/AttributeAllocationPanel/AttributeSliders/LuckSliderRow/LuckSliderValue")
	available_points_value = get_node("TabContainer/AttributeAllocationPanel/AttributePointsInfo/AvailablePointsValue")
	reset_allocation_button = get_node("TabContainer/AttributeAllocationPanel/AttributePointsInfo/ResetAllocationButton")
	apply_allocation_button = get_node("TabContainer/AttributeAllocationPanel/AttributePointsInfo/ApplyAllocationButton")
	
	# 天赋网格面板元素
	talent_grid_container = get_node("TabContainer/TalentGridPanel/TalentGridContainer")
	talent_grid_description = get_node("TabContainer/TalentGridPanel/TalentGridDescription")
	reset_talents_button = get_node("TabContainer/TalentGridPanel/ResetTalentsButton")
	close_talent_grid_button = get_node("TabContainer/TalentGridPanel/CloseTalentGridButton")
	
	# 获取天赋节点
	talent_nodes = []
	for i in range(4):
		for j in range(4):
			var node_name = "TalentNode%d%d" % [i, j]
			var talent_node = talent_grid_container.get_node(node_name)
			talent_nodes.append(talent_node)

func connect_signals():
	"""连接UI信号"""
	# 角色面板信号
	if close_character_button:
		close_character_button.pressed.connect(_on_close_character_button_pressed)
	if reset_character_button:
		reset_character_button.pressed.connect(_on_reset_character_button_pressed)
	if apply_character_button:
		apply_character_button.pressed.connect(_on_apply_character_button_pressed)
	if strength_add_button:
		strength_add_button.pressed.connect(_on_strength_add_button_pressed)
	if agility_add_button:
		agility_add_button.pressed.connect(_on_agility_add_button_pressed)
	if constitution_add_button:
		constitution_add_button.pressed.connect(_on_constitution_add_button_pressed)
	if intelligence_add_button:
		intelligence_add_button.pressed.connect(_on_intelligence_add_button_pressed)
	if willpower_add_button:
		willpower_add_button.pressed.connect(_on_willpower_add_button_pressed)
	if luck_add_button:
		luck_add_button.pressed.connect(_on_luck_add_button_pressed)
	
	# 属性分配面板信号
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
	if reset_allocation_button:
		reset_allocation_button.pressed.connect(_on_reset_allocation_button_pressed)
	if apply_allocation_button:
		apply_allocation_button.pressed.connect(_on_apply_allocation_button_pressed)
	
	# 天赋网格面板信号
	if reset_talents_button:
		reset_talents_button.pressed.connect(_on_reset_talents_button_pressed)
	if close_talent_grid_button:
		close_talent_grid_button.pressed.connect(_on_close_talent_grid_button_pressed)
	
	# 为每个天赋节点连接信号
	for i in range(16):
		var talent_node = talent_nodes[i]
		talent_node.pressed.connect(_on_talent_node_pressed.bind(i))
		talent_node.mouse_entered.connect(_on_talent_node_mouse_entered.bind(i))
		talent_node.mouse_exited.connect(_on_talent_node_mouse_exited.bind(i))

func initialize_data():
	"""初始化临时数据"""
	temp_attributes = {
		"strength": 0,
		"agility": 0,
		"constitution": 0,
		"intelligence": 0,
		"willpower": 0,
		"luck": 0
	}
	temp_attribute_points = 0
	temp_talent_points = 0

func connect_character_system_signals():
	"""连接角色系统信号"""
	# 尝试获取角色系统
	character_system = get_node_or_null("/root/CharacterSystem")
	if character_system:
		# 连接角色系统信号以实时更新UI
		character_system.level_up.connect(_on_character_level_up)
		character_system.realm_breakthrough.connect(_on_character_realm_breakthrough)
		character_system.attribute_points_allocated.connect(_on_attribute_points_allocated)
		character_system.attributes_reset.connect(_on_attributes_reset)

func update_character_display():
	"""更新角色面板显示"""
	if not character_system:
		character_system = get_node_or_null("/root/CharacterSystem")
	
	if character_system:
		# 更新等级和境界
		if level_value_label:
			level_value_label.text = str(character_system.level)
		
		if realm_value_label:
			var current_realm = character_system.get_current_realm()
			realm_value_label.text = current_realm["name"]
		
		# 更新属性值
		var final_attrs = character_system.get_final_attributes()
		if strength_value_label:
			strength_value_label.text = str(final_attrs.strength)
			temp_attributes["strength"] = final_attrs.strength
		if agility_value_label:
			agility_value_label.text = str(final_attrs.agility)
			temp_attributes["agility"] = final_attrs.agility
		if constitution_value_label:
			constitution_value_label.text = str(final_attrs.constitution)
			temp_attributes["constitution"] = final_attrs.constitution
		if intelligence_value_label:
			intelligence_value_label.text = str(final_attrs.intelligence)
			temp_attributes["intelligence"] = final_attrs.intelligence
		if willpower_value_label:
			willpower_value_label.text = str(final_attrs.willpower)
			temp_attributes["willpower"] = final_attrs.willpower
		if luck_value_label:
			luck_value_label.text = str(final_attrs.luck)
			temp_attributes["luck"] = final_attrs.luck
		
		# 更新可用属性点
		if attribute_points_value_label:
			var available_points = character_system.total_attribute_points - character_system.allocated_attribute_points
			attribute_points_value_label.text = str(available_points)
			temp_attribute_points = available_points

func update_attribute_allocation_display():
	"""更新属性分配面板显示"""
	if not character_system:
		character_system = get_node_or_null("/root/CharacterSystem")
	
	if character_system:
		# 更新滑块值和显示值
		var attrs = character_system.get_final_attributes()
		if strength_slider:
			strength_slider.value = attrs.strength
			strength_slider.max_value = attrs.strength + (character_system.total_attribute_points - character_system.allocated_attribute_points)
		if agility_slider:
			agility_slider.value = attrs.agility
			agility_slider.max_value = attrs.agility + (character_system.total_attribute_points - character_system.allocated_attribute_points)
		if constitution_slider:
			constitution_slider.value = attrs.constitution
			constitution_slider.max_value = attrs.constitution + (character_system.total_attribute_points - character_system.allocated_attribute_points)
		if intelligence_slider:
			intelligence_slider.value = attrs.intelligence
			intelligence_slider.max_value = attrs.intelligence + (character_system.total_attribute_points - character_system.allocated_attribute_points)
		if willpower_slider:
			willpower_slider.value = attrs.willpower
			willpower_slider.max_value = attrs.willpower + (character_system.total_attribute_points - character_system.allocated_attribute_points)
		if luck_slider:
			luck_slider.value = attrs.luck
			luck_slider.max_value = attrs.luck + (character_system.total_attribute_points - character_system.allocated_attribute_points)
		
		# 更新滑块显示值
		if strength_slider_value:
			strength_slider_value.text = str(int(strength_slider.value))
		if agility_slider_value:
			agility_slider_value.text = str(int(agility_slider.value))
		if constitution_slider_value:
			constitution_slider_value.text = str(int(constitution_slider.value))
		if intelligence_slider_value:
			intelligence_slider_value.text = str(int(intelligence_slider.value))
		if willpower_slider_value:
			willpower_slider_value.text = str(int(willpower_slider.value))
		if luck_slider_value:
			luck_slider_value.text = str(int(luck_slider.value))
		
		# 更新可用点数
		if available_points_value:
			var available_points = character_system.total_attribute_points - character_system.allocated_attribute_points
			available_points_value.text = str(available_points)

func update_talent_grid_display():
	"""更新天赋网格显示"""
	if not character_system:
		character_system = get_node_or_null("/root/CharacterSystem")
	
	if character_system and character_system.talent_grid.size() == 4:
		# 更新天赋网格状态
		for i in range(4):
			for j in range(4):
				var talent_node = talent_nodes[i * 4 + j]
				var talent_info = character_system.talent_grid[i][j]
				
				if talent_info["unlocked"]:
					# 已解锁的天赋节点显示为金色
					talent_node.modulate = Color.YELLOW
				else:
					# 未解锁的天赋节点显示为灰色
					talent_node.modulate = Color.GRAY

func _on_character_level_up(new_level, attribute_points, talent_points):
	"""角色升级时更新UI"""
	update_character_display()
	update_attribute_allocation_display()

func _on_character_realm_breakthrough(new_realm, realm_bonus, realm_index):
	"""角色境界突破时更新UI"""
	update_character_display()

func _on_attribute_points_allocated(attribute_name, points, new_value):
	"""属性点分配时更新UI"""
	update_character_display()
	update_attribute_allocation_display()

func _on_attributes_reset(used_free_reset):
	"""属性重置时更新UI"""
	update_character_display()
	update_attribute_allocation_display()

func _on_close_character_button_pressed():
	"""关闭角色面板按钮回调"""
	hide()

func _on_reset_character_button_pressed():
	"""重置角色属性按钮回调"""
	# 重置到原始属性值
	if character_system:
		var original_attributes = character_system.attributes.get_total()
		temp_attributes["strength"] = original_attributes["strength"]
		temp_attributes["agility"] = original_attributes["agility"]
		temp_attributes["constitution"] = original_attributes["constitution"]
		temp_attributes["intelligence"] = original_attributes["intelligence"]
		temp_attributes["willpower"] = original_attributes["willpower"]
		temp_attributes["luck"] = original_attributes["luck"]
		
		# 更新显示
		if strength_value_label:
			strength_value_label.text = str(temp_attributes["strength"])
		if agility_value_label:
			agility_value_label.text = str(temp_attributes["agility"])
		if constitution_value_label:
			constitution_value_label.text = str(temp_attributes["constitution"])
		if intelligence_value_label:
			intelligence_value_label.text = str(temp_attributes["intelligence"])
		if willpower_value_label:
			willpower_value_label.text = str(temp_attributes["willpower"])
		if luck_value_label:
			luck_value_label.text = str(temp_attributes["luck"])

func _on_apply_character_button_pressed():
	"""应用角色属性按钮回调"""
	if not character_system:
		return
	
	# 计算属性点变化
	var original_attributes = character_system.attributes.get_total()
	var points_used = 0
	
	points_used += temp_attributes["strength"] - original_attributes["strength"]
	points_used += temp_attributes["agility"] - original_attributes["agility"]
	points_used += temp_attributes["constitution"] - original_attributes["constitution"]
	points_used += temp_attributes["intelligence"] - original_attributes["intelligence"]
	points_used += temp_attributes["willpower"] - original_attributes["willpower"]
	points_used += temp_attributes["luck"] - original_attributes["luck"]
	
	# 检查是否有足够的属性点
	var available_points = character_system.total_attribute_points - character_system.allocated_attribute_points
	if points_used > available_points:
		print("❌ 属性点不足，无法应用分配")
		return
	
	# 应用属性点分配
	if temp_attributes["strength"] > original_attributes["strength"]:
		character_system.allocate_attribute_points("strength", temp_attributes["strength"] - original_attributes["strength"])
	if temp_attributes["agility"] > original_attributes["agility"]:
		character_system.allocate_attribute_points("agility", temp_attributes["agility"] - original_attributes["agility"])
	if temp_attributes["constitution"] > original_attributes["constitution"]:
		character_system.allocate_attribute_points("constitution", temp_attributes["constitution"] - original_attributes["constitution"])
	if temp_attributes["intelligence"] > original_attributes["intelligence"]:
		character_system.allocate_attribute_points("intelligence", temp_attributes["intelligence"] - original_attributes["intelligence"])
	if temp_attributes["willpower"] > original_attributes["willpower"]:
		character_system.allocate_attribute_points("willpower", temp_attributes["willpower"] - original_attributes["willpower"])
	if temp_attributes["luck"] > original_attributes["luck"]:
		character_system.allocate_attribute_points("luck", temp_attributes["luck"] - original_attributes["luck"])
	
	print("✅ 属性点分配已应用")

func _on_strength_add_button_pressed():
	"""力道增加按钮回调"""
	if temp_attribute_points > 0:
		temp_attributes["strength"] += 1
		temp_attribute_points -= 1
		if strength_value_label:
			strength_value_label.text = str(temp_attributes["strength"])
		if attribute_points_value_label:
			attribute_points_value_label.text = str(temp_attribute_points)
	else:
		print("❌ 没有可用的属性点")

func _on_agility_add_button_pressed():
	"""身法增加按钮回调"""
	if temp_attribute_points > 0:
		temp_attributes["agility"] += 1
		temp_attribute_points -= 1
		if agility_value_label:
			agility_value_label.text = str(temp_attributes["agility"])
		if attribute_points_value_label:
			attribute_points_value_label.text = str(temp_attribute_points)
	else:
		print("❌ 没有可用的属性点")

func _on_constitution_add_button_pressed():
	"""根骨增加按钮回调"""
	if temp_attribute_points > 0:
		temp_attributes["constitution"] += 1
		temp_attribute_points -= 1
		if constitution_value_label:
			constitution_value_label.text = str(temp_attributes["constitution"])
		if attribute_points_value_label:
			attribute_points_value_label.text = str(temp_attribute_points)
	else:
		print("❌ 没有可用的属性点")

func _on_intelligence_add_button_pressed():
	"""悟性增加按钮回调"""
	if temp_attribute_points > 0:
		temp_attributes["intelligence"] += 1
		temp_attribute_points -= 1
		if intelligence_value_label:
			intelligence_value_label.text = str(temp_attributes["intelligence"])
		if attribute_points_value_label:
			attribute_points_value_label.text = str(temp_attribute_points)
	else:
		print("❌ 没有可用的属性点")

func _on_willpower_add_button_pressed():
	"""定力增加按钮回调"""
	if temp_attribute_points > 0:
		temp_attributes["willpower"] += 1
		temp_attribute_points -= 1
		if willpower_value_label:
			willpower_value_label.text = str(temp_attributes["willpower"])
		if attribute_points_value_label:
			attribute_points_value_label.text = str(temp_attribute_points)
	else:
		print("❌ 没有可用的属性点")

func _on_luck_add_button_pressed():
	"""福缘增加按钮回调"""
	if temp_attribute_points > 0:
		temp_attributes["luck"] += 1
		temp_attribute_points -= 1
		if luck_value_label:
			luck_value_label.text = str(temp_attributes["luck"])
		if attribute_points_value_label:
			attribute_points_value_label.text = str(temp_attribute_points)
	else:
		print("❌ 没有可用的属性点")

func _on_strength_slider_changed(value):
	"""力道滑块变化回调"""
	if strength_slider_value:
		strength_slider_value.text = str(int(value))
	update_attribute_allocation_display()

func _on_agility_slider_changed(value):
	"""身法滑块变化回调"""
	if agility_slider_value:
		agility_slider_value.text = str(int(value))
	update_attribute_allocation_display()

func _on_constitution_slider_changed(value):
	"""根骨滑块变化回调"""
	if constitution_slider_value:
		constitution_slider_value.text = str(int(value))
	update_attribute_allocation_display()

func _on_intelligence_slider_changed(value):
	"""悟性滑块变化回调"""
	if intelligence_slider_value:
		intelligence_slider_value.text = str(int(value))
	update_attribute_allocation_display()

func _on_willpower_slider_changed(value):
	"""定力滑块变化回调"""
	if willpower_slider_value:
		willpower_slider_value.text = str(int(value))
	update_attribute_allocation_display()

func _on_luck_slider_changed(value):
	"""福缘滑块变化回调"""
	if luck_slider_value:
		luck_slider_value.text = str(int(value))
	update_attribute_allocation_display()

func _on_reset_allocation_button_pressed():
	"""重置分配按钮回调"""
	update_attribute_allocation_display()

func _on_apply_allocation_button_pressed():
	"""应用分配按钮回调"""
	if not character_system:
		return
	
	# 获取当前属性值
	var current_attrs = character_system.attributes.get_total()
	
	# 计算需要分配的点数
	var strength_points = int(strength_slider.value) - current_attrs["strength"]
	var agility_points = int(agility_slider.value) - current_attrs["agility"]
	var constitution_points = int(constitution_slider.value) - current_attrs["constitution"]
	var intelligence_points = int(intelligence_slider.value) - current_attrs["intelligence"]
	var willpower_points = int(willpower_slider.value) - current_attrs["willpower"]
	var luck_points = int(luck_slider.value) - current_attrs["luck"]
	
	# 计算总点数
	var total_points_needed = strength_points + agility_points + constitution_points + intelligence_points + willpower_points + luck_points
	
	# 检查是否有足够的点数
	var available_points = character_system.total_attribute_points - character_system.allocated_attribute_points
	if total_points_needed > available_points:
		print("❌ 属性点不足，无法应用分配")
		return
	
	# 应用属性分配
	if strength_points > 0:
		character_system.allocate_attribute_points("strength", strength_points)
	if agility_points > 0:
		character_system.allocate_attribute_points("agility", agility_points)
	if constitution_points > 0:
		character_system.allocate_attribute_points("constitution", constitution_points)
	if intelligence_points > 0:
		character_system.allocate_attribute_points("intelligence", intelligence_points)
	if willpower_points > 0:
		character_system.allocate_attribute_points("willpower", willpower_points)
	if luck_points > 0:
		character_system.allocate_attribute_points("luck", luck_points)
	
	print("✅ 属性分配已应用")

func _on_talent_node_pressed(node_index):
	"""天赋节点点击回调"""
	var row = node_index / 4
	var col = node_index % 4
	
	if character_system:
		# 尝试解锁天赋节点
		var result = character_system.unlock_talent(row, col)
		if result:
			print("✅ 天赋节点 (%d, %d) 已解锁" % [row, col])
			update_talent_grid_display()
		else:
			print("❌ 无法解锁天赋节点 (%d, %d)" % [row, col])

func _on_talent_node_mouse_entered(node_index):
	"""天赋节点鼠标进入回调"""
	var row = node_index / 4
	var col = node_index % 4
	
	if character_system and character_system.talent_definitions.size() > 0:
		var talent_id = "talent_%d_%d" % [row, col]
		if character_system.talent_definitions.has(talent_id):
			var talent_info = character_system.talent_definitions[talent_id]
			if talent_grid_description:
				talent_grid_description.text = "%s: %s" % [talent_info["name"], talent_info["description"]]
		else:
			if talent_grid_description:
				talent_grid_description.text = "未知天赋节点 (%d, %d)" % [row, col]

func _on_talent_node_mouse_exited(node_index):
	"""天赋节点鼠标离开回调"""
	if talent_grid_description:
		talent_grid_description.text = "将鼠标悬停在天赋节点上查看描述"

func _on_reset_talents_button_pressed():
	"""重置天赋按钮回调"""
	if character_system:
		var result = character_system.reset_talents()
		if result:
			print("✅ 天赋已重置")
			update_talent_grid_display()
		else:
			print("❌ 天赋重置失败")

func _on_close_talent_grid_button_pressed():
	"""关闭天赋网格按钮回调"""
	hide()

func show_character_growth_ui():
	"""显示角色成长UI"""
	show()
	update_character_display()
	update_attribute_allocation_display()
	update_talent_grid_display()

func _process(delta):
	"""每帧处理函数，用于实时更新UI"""
	# 这里可以添加需要每帧更新的UI逻辑
	pass