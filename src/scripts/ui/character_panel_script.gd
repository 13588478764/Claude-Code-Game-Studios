# 武侠奇遇录 - 角色面板脚本
# 负责管理角色面板的显示和交互

extends Node

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

func update_display(character_data):
	"""更新角色面板显示"""
	if level_value_label != null:
		level_value_label.text = str(character_data["level"])
	
	if realm_value_label != null:
		realm_value_label.text = character_data["realm"]
	
	if strength_value_label != null:
		strength_value_label.text = str(character_data["attributes"]["strength"])
	
	if agility_value_label != null:
		agility_value_label.text = str(character_data["attributes"]["agility"])
	
	if constitution_value_label != null:
		constitution_value_label.text = str(character_data["attributes"]["constitution"])
	
	if intelligence_value_label != null:
		intelligence_value_label.text = str(character_data["attributes"]["intelligence"])
	
	if willpower_value_label != null:
		willpower_value_label.text = str(character_data["attributes"]["willpower"])
	
	if luck_value_label != null:
		luck_value_label.text = str(character_data["attributes"]["luck"])
	
	if attribute_points_value_label != null:
		attribute_points_value_label.text = str(character_data["attribute_points"])

func _on_close_button_pressed():
	"""关闭按钮回调"""
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager != null:
		ui_manager.switch_to_state(ui_manager.UIState.MAIN_MENU)