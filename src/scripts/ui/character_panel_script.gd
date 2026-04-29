## CharacterPanelScript
## 武侠奇遇录 - 角色面板脚本
负责管理角色面板的显示和交互
##
## 主要功能：
## - 待补充

extends Node

class_name CharacterPanelScript

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

# UI元素引用
var level_value_label = null
var realm_value_label = null
var strength_value_label = null
var agility_value_label = null
var constitution_value_label = null
var intelligence_value_label = null
var willpower_value_label = null
var luck_value_label = null
var attribute_points_value_label = null
var close_button = null
var reset_button = null
var apply_button = null
var strength_add_button = null
var agility_add_button = null
var constitution_add_button = null
var intelligence_add_button = null
var willpower_add_button = null
var luck_add_button = null

# 临时属性存储
var temp_attributes = {
	"strength": 0,
	"agility": 0,
	"constitution": 0,
	"intelligence": 0,
	"willpower": 0,
	"luck": 0
}
var temp_attribute_points = 0

func _ready():
	# 获取UI元素引用
	var character_panel = get_parent()
	level_value_label = character_panel.get_node("Background/LevelInfo/LevelValue")
	realm_value_label = character_panel.get_node("Background/LevelInfo/RealmValue")
	strength_value_label = character_panel.get_node("Background/AttributesPanel/StrengthRow/StrengthValue")
	agility_value_label = character_panel.get_node("Background/AttributesPanel/AgilityRow/AgilityValue")
	constitution_value_label = character_panel.get_node("Background/AttributesPanel/ConstitutionRow/ConstitutionValue")
	intelligence_value_label = character_panel.get_node("Background/AttributesPanel/IntelligenceRow/IntelligenceValue")
	willpower_value_label = character_panel.get_node("Background/AttributesPanel/WillpowerRow/WillpowerValue")
	luck_value_label = character_panel.get_node("Background/AttributesPanel/LuckRow/LuckValue")
	attribute_points_value_label = character_panel.get_node("Background/AttributePointsRow/AttributePointsValue")
	close_button = character_panel.get_node("Background/CloseButton")
	reset_button = character_panel.get_node("Background/ResetButton")
	apply_button = character_panel.get_node("Background/ApplyButton")
	strength_add_button = character_panel.get_node("Background/AttributesPanel/StrengthRow/StrengthAddButton")
	agility_add_button = character_panel.get_node("Background/AttributesPanel/AgilityRow/AgilityAddButton")
	constitution_add_button = character_panel.get_node("Background/AttributesPanel/ConstitutionRow/ConstitutionAddButton")
	intelligence_add_button = character_panel.get_node("Background/AttributesPanel/IntelligenceRow/IntelligenceAddButton")
	willpower_add_button = character_panel.get_node("Background/AttributesPanel/WillpowerRow/WillpowerAddButton")
	luck_add_button = character_panel.get_node("Background/AttributesPanel/LuckRow/LuckAddButton")
	
	# 连接按钮信号
	if reset_button != null:
		reset_button.pressed.connect(_on_reset_button_pressed)
	if apply_button != null:
		apply_button.pressed.connect(_on_apply_button_pressed)
	if strength_add_button != null:
		strength_add_button.pressed.connect(_on_strength_add_button_pressed)
	if agility_add_button != null:
		agility_add_button.pressed.connect(_on_agility_add_button_pressed)
	if constitution_add_button != null:
		constitution_add_button.pressed.connect(_on_constitution_add_button_pressed)
	if intelligence_add_button != null:
		intelligence_add_button.pressed.connect(_on_intelligence_add_button_pressed)
	if willpower_add_button != null:
		willpower_add_button.pressed.connect(_on_willpower_add_button_pressed)
	if luck_add_button != null:
		luck_add_button.pressed.connect(_on_luck_add_button_pressed)

func update_display(character_data):
	"""更新角色面板显示"""
	if level_value_label != null:
		level_value_label.text = str(character_data["level"])
	
	if realm_value_label != null:
		realm_value_label.text = character_data["realm"]
	
	if strength_value_label != null:
		strength_value_label.text = str(character_data["attributes"]["strength"])
		temp_attributes["strength"] = character_data["attributes"]["strength"]
	
	if agility_value_label != null:
		agility_value_label.text = str(character_data["attributes"]["agility"])
		temp_attributes["agility"] = character_data["attributes"]["agility"]
	
	if constitution_value_label != null:
		constitution_value_label.text = str(character_data["attributes"]["constitution"])
		temp_attributes["constitution"] = character_data["attributes"]["constitution"]
	
	if intelligence_value_label != null:
		intelligence_value_label.text = str(character_data["attributes"]["intelligence"])
		temp_attributes["intelligence"] = character_data["attributes"]["intelligence"]
	
	if willpower_value_label != null:
		willpower_value_label.text = str(character_data["attributes"]["willpower"])
		temp_attributes["willpower"] = character_data["attributes"]["willpower"]
	
	if luck_value_label != null:
		luck_value_label.text = str(character_data["attributes"]["luck"])
		temp_attributes["luck"] = character_data["attributes"]["luck"]
	
	if attribute_points_value_label != null:
		attribute_points_value_label.text = str(character_data["attribute_points"])
		temp_attribute_points = character_data["attribute_points"]

func _on_close_button_pressed():
	"""关闭按钮回调"""
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager != null:
		ui_manager.switch_to_state(ui_manager.UIState.MAIN_MENU)

func _on_reset_button_pressed():
	"""重置按钮回调"""
	# 重置到原始属性值
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null:
		var original_attributes = character_system.attributes.get_total()
		temp_attributes["strength"] = original_attributes["strength"]
		temp_attributes["agility"] = original_attributes["agility"]
		temp_attributes["constitution"] = original_attributes["constitution"]
		temp_attributes["intelligence"] = original_attributes["intelligence"]
		temp_attributes["willpower"] = original_attributes["willpower"]
		temp_attributes["luck"] = original_attributes["luck"]
		
		# 更新显示
		if strength_value_label != null:
			strength_value_label.text = str(temp_attributes["strength"])
		if agility_value_label != null:
			agility_value_label.text = str(temp_attributes["agility"])
		if constitution_value_label != null:
			constitution_value_label.text = str(temp_attributes["constitution"])
		if intelligence_value_label != null:
			intelligence_value_label.text = str(temp_attributes["intelligence"])
		if willpower_value_label != null:
			willpower_value_label.text = str(temp_attributes["willpower"])
		if luck_value_label != null:
			luck_value_label.text = str(temp_attributes["luck"])

func _on_apply_button_pressed():
	"""应用按钮回调"""
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system == null:
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
	if points_used > temp_attribute_points:
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
	
	# 关闭面板
	_on_close_button_pressed()

func _on_strength_add_button_pressed():
	"""力道增加按钮回调"""
	if temp_attribute_points > 0:
		temp_attributes["strength"] += 1
		temp_attribute_points -= 1
		if strength_value_label != null:
			strength_value_label.text = str(temp_attributes["strength"])
		if attribute_points_value_label != null:
			attribute_points_value_label.text = str(temp_attribute_points)
	else:
		print("❌ 没有可用的属性点")

func _on_agility_add_button_pressed():
	"""身法增加按钮回调"""
	if temp_attribute_points > 0:
		temp_attributes["agility"] += 1
		temp_attribute_points -= 1
		if agility_value_label != null:
			agility_value_label.text = str(temp_attributes["agility"])
		if attribute_points_value_label != null:
			attribute_points_value_label.text = str(temp_attribute_points)
	else:
		print("❌ 没有可用的属性点")

func _on_constitution_add_button_pressed():
	"""根骨增加按钮回调"""
	if temp_attribute_points > 0:
		temp_attributes["constitution"] += 1
		temp_attribute_points -= 1
		if constitution_value_label != null:
			constitution_value_label.text = str(temp_attributes["constitution"])
		if attribute_points_value_label != null:
			attribute_points_value_label.text = str(temp_attribute_points)
	else:
		print("❌ 没有可用的属性点")

func _on_intelligence_add_button_pressed():
	"""悟性增加按钮回调"""
	if temp_attribute_points > 0:
		temp_attributes["intelligence"] += 1
		temp_attribute_points -= 1
		if intelligence_value_label != null:
			intelligence_value_label.text = str(temp_attributes["intelligence"])
		if attribute_points_value_label != null:
			attribute_points_value_label.text = str(temp_attribute_points)
	else:
		print("❌ 没有可用的属性点")

func _on_willpower_add_button_pressed():
	"""定力增加按钮回调"""
	if temp_attribute_points > 0:
		temp_attributes["willpower"] += 1
		temp_attribute_points -= 1
		if willpower_value_label != null:
			willpower_value_label.text = str(temp_attributes["willpower"])
		if attribute_points_value_label != null:
			attribute_points_value_label.text = str(temp_attribute_points)
	else:
		print("❌ 没有可用的属性点")

func _on_luck_add_button_pressed():
	"""福缘增加按钮回调"""
	if temp_attribute_points > 0:
		temp_attributes["luck"] += 1
		temp_attribute_points -= 1
		if luck_value_label != null:
			luck_value_label.text = str(temp_attributes["luck"])
		if attribute_points_value_label != null:
			attribute_points_value_label.text = str(temp_attribute_points)
	else:
		print("❌ 没有可用的属性点")