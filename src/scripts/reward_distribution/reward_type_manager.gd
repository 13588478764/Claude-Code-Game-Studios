## RewardTypeManager
## RewardTypeManager系统
##
## 主要功能：
## - 待补充

extends Node

class_name RewardTypeManager

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

extends Node

## 奖励类型管理器
## 实现四大类奖励类型的定义、验证和分类功能

# 奖励类型枚举
enum RewardCategory {
	MATERIAL_RESOURCES,      # 物质资源
	PROGRESSION_RESOURCES,   # 成长资源  
	EQUIPMENT_ITEMS,         # 装备物品
	NARRATIVE_STATUS         # 叙事状态
}

# 物质资源子类型
enum MaterialType {
	SILVER,                 # 银两
	BASIC_MATERIALS,        # 基础材料
	RARE_MATERIALS          # 稀有材料
}

# 成长资源子类型
enum ProgressionType {
	EXPERIENCE,             # 经验值
	MARTIAL_ARTS_PROFICIENCY, # 武学熟练度/残页
	ATTRIBUTE_POINTS,       # 属性点
	TALENT_POINTS           # 天赋点
}

# 装备物品子类型
enum EquipmentType {
	FINISHED_EQUIPMENT,     # 成品装备
	CONSUMABLES,            # 消耗品
	SPECIAL_ITEMS           # 特殊道具
}

# 叙事状态子类型
enum NarrativeType {
	REPUTATION,             # 声望/善恶值
	TEMPORARY_BUFFS,        # 临时Buff
	ENCOUNTER_TITLES        # 奇遇专属称号
}

# 奖励类型配置数据
var reward_type_config: Dictionary = {}

# 奖励类型验证缓存
var type_validation_cache: Dictionary = {}

func _init():
	# 初始化奖励类型配置
	_load_reward_type_config()

# 加载奖励类型配置
func _load_reward_type_config():
	# 从JSON文件加载配置（如果存在）
	var config_path = "res://data/reward_types.json"
	if ResourceLoader.exists(config_path):
		var config_file = FileAccess.open(config_path, FileAccess.READ)
		if config_file:
			var json_text = config_file.get_as_text()
			var json = JSON.new()
			var parse_result = json.parse(json_text)
			if parse_result == OK:
				reward_type_config = json.data
			else:
				print("警告: 无法解析奖励类型配置文件: ", json.get_error_message())
			config_file.close()
	else:
		# 使用默认配置
		_initialize_default_config()

# 初始化默认配置
func _initialize_default_config():
	reward_type_config = {
		"material_resources": {
			"silver": {"name": "银两", "stackable": true, "max_stack": 999999},
			"basic_materials": {
				"iron_ore": {"name": "铁矿石", "stackable": true, "max_stack": 999},
				"herb_common": {"name": "普通草药", "stackable": true, "max_stack": 999},
				"wood": {"name": "木材", "stackable": true, "max_stack": 999}
			},
			"rare_materials": {
				"thousand_year_ginseng": {"name": "千年灵芝", "stackable": false, "max_stack": 1},
				"mystic_iron": {"name": "玄铁精", "stackable": true, "max_stack": 99}
			}
		},
		"progression_resources": {
			"experience": {"name": "经验值", "stackable": true, "max_stack": 999999999},
			"martial_arts_proficiency": {
				"proficiency_fragment": {"name": "武学熟练度残页", "stackable": true, "max_stack": 999}
			},
			"attribute_points": {"name": "属性点", "stackable": true, "max_stack": 999},
			"talent_points": {"name": "天赋点", "stackable": true, "max_stack": 999}
		},
		"equipment_items": {
			"finished_equipment": {
				"common_sword": {"name": "普通剑", "stackable": false, "max_stack": 1, "rarity": "common"},
				"rare_sword": {"name": "稀有剑", "stackable": false, "max_stack": 1, "rarity": "rare"}
			},
			"consumables": {
				"health_potion": {"name": "回血丹", "stackable": true, "max_stack": 99},
				"qi_potion": {"name": "回气丹", "stackable": true, "max_stack": 99},
				"antidote": {"name": "解毒草", "stackable": true, "max_stack": 99},
				"invisibility_powder": {"name": "隐匿符", "stackable": true, "max_stack": 99}
			},
			"special_items": {
				"key": {"name": "钥匙", "stackable": false, "max_stack": 1},
				"letter": {"name": "信件", "stackable": false, "max_stack": 1},
				"quest_item": {"name": "任务物品", "stackable": false, "max_stack": 1},
				"manual": {"name": "秘籍", "stackable": false, "max_stack": 1}
			}
		},
		"narrative_status": {
			"reputation": {
				"good_reputation": {"name": "善名", "stackable": false, "max_stack": 1},
				"evil_reputation": {"name": "恶名", "stackable": false, "max_stack": 1}
			},
			"temporary_buffs": {
				"refreshed_mind": {"name": "神清气爽", "stackable": false, "max_stack": 1, "duration": 3600}
			},
			"encounter_titles": {
				"high_master": {"name": "破庙高人", "stackable": false, "max_stack": 1, "bonus_luck": 5}
			}
		}
	}

# 获取奖励类别
func get_reward_category(reward_id: String) -> int:
	if type_validation_cache.has(reward_id):
		return type_validation_cache[reward_id]
	
	# 在所有类别中搜索奖励ID
	for category in reward_type_config.keys():
		var category_data = reward_type_config[category]
		for subcategory in category_data.keys():
			if typeof(category_data[subcategory]) == TYPE_DICTIONARY:
				if category_data[subcategory].has(reward_id):
					var category_enum = _get_category_enum_from_string(category)
					type_validation_cache[reward_id] = category_enum
					return category_enum
			else:
				# 直接的奖励项
				if subcategory == reward_id:
					var category_enum = _get_category_enum_from_string(category)
					type_validation_cache[reward_id] = category_enum
					return category_enum
	
	# 未找到，返回-1表示无效
	type_validation_cache[reward_id] = -1
	return -1

# 根据字符串获取类别枚举
func _get_category_enum_from_string(category_str: String) -> int:
	match category_str:
		"material_resources":
			return RewardCategory.MATERIAL_RESOURCES
		"progression_resources":
			return RewardCategory.PROGRESSION_RESOURCES
		"equipment_items":
			return RewardCategory.EQUIPMENT_ITEMS
		"narrative_status":
			return RewardCategory.NARRATIVE_STATUS
		_:
			return -1

# 验证奖励ID是否有效
func is_valid_reward_id(reward_id: String) -> bool:
	return get_reward_category(reward_id) != -1

# 获取奖励配置
func get_reward_config(reward_id: String) -> Dictionary:
	# 在所有类别中搜索奖励ID
	for category in reward_type_config.keys():
		var category_data = reward_type_config[category]
		for subcategory in category_data.keys():
			if typeof(category_data[subcategory]) == TYPE_DICTIONARY:
				if category_data[subcategory].has(reward_id):
					return category_data[subcategory][reward_id]
			else:
				# 直接的奖励项
				if subcategory == reward_id:
					return category_data[subcategory]
	
	return {}

# 获取物质资源配置
func get_material_config(material_id: String) -> Dictionary:
	if reward_type_config.has("material_resources"):
		var materials = reward_type_config["material_resources"]
		for subcategory in materials.keys():
			if typeof(materials[subcategory]) == TYPE_DICTIONARY:
				if materials[subcategory].has(material_id):
					return materials[subcategory][material_id]
	return {}

# 获取成长资源配置
func get_progression_config(progression_id: String) -> Dictionary:
	if reward_type_config.has("progression_resources"):
		var progression = reward_type_config["progression_resources"]
		for subcategory in progression.keys():
			if typeof(progression[subcategory]) == TYPE_DICTIONARY:
				if progression[subcategory].has(progression_id):
					return progression[subcategory][progression_id]
			else:
				if subcategory == progression_id:
					return progression[subcategory]
	return {}

# 获取装备物品配置
func get_equipment_config(equipment_id: String) -> Dictionary:
	if reward_type_config.has("equipment_items"):
		var equipment = reward_type_config["equipment_items"]
		for subcategory in equipment.keys():
			if typeof(equipment[subcategory]) == TYPE_DICTIONARY:
				if equipment[subcategory].has(equipment_id):
					return equipment[subcategory][equipment_id]
	return {}

# 获取叙事状态配置
func get_narrative_config(narrative_id: String) -> Dictionary:
	if reward_type_config.has("narrative_status"):
		var narrative = reward_type_config["narrative_status"]
		for subcategory in narrative.keys():
			if typeof(narrative[subcategory]) == TYPE_DICTIONARY:
				if narrative[subcategory].has(narrative_id):
					return narrative[subcategory][narrative_id]
	return {}

# 添加自定义奖励类型
func add_custom_reward_type(category: String, subcategory: String, reward_id: String, config: Dictionary):
	if not reward_type_config.has(category):
		reward_type_config[category] = {}
	
	if not reward_type_config[category].has(subcategory):
		reward_type_config[category][subcategory] = {}
	
	reward_type_config[category][subcategory][reward_id] = config
	
	# 清除缓存
	type_validation_cache.clear()

# 保存奖励类型配置到文件
func save_reward_type_config():
	var config_path = "user://reward_types.json"
	var json = JSON.new()
	json.stringify(reward_type_config)
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	if file:
		file.store_string(json)
		file.close()
		print("奖励类型配置已保存到: ", config_path)
	else:
		print("错误: 无法保存奖励类型配置到: ", config_path)

# 重置为默认配置
func reset_to_default_config():
	_initialize_default_config()
	type_validation_cache.clear()