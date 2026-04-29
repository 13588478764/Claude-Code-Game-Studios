# 成长数据结构管理器
# 实现成长数据结构定义，包括等级、境界、属性、技能等

extends Node

class_name GrowthDataStructureManager

# 信号定义
signal data_structure_defined(structure_name: String)

# 常量定义
const DATA_VERSION = "1.0.0"

# 成长数据结构
class GrowthData:
	var version: String
	var character_id: String
	var timestamp: int
	
	var progression: CharacterProgressionData
	var attributes: AttributeData
	var martial_arts: MartialArtsData
	var equipment: EquipmentData
	var encounters: EncounterData
	
	func _init():
		version = DATA_VERSION
		character_id = ""
		timestamp = Time.get_unix_time_from_system()
		progression = CharacterProgressionData.new()
		attributes = AttributeData.new()
		martial_arts = MartialArtsData.new()
		equipment = EquipmentData.new()
		encounters = EncounterData.new()

# 角色成长数据结构
class CharacterProgressionData:
	var level: int
	var realm: int  # 0-9 对应10个大境界
	var experience: int
	var experience_to_next_level: int
	
	func _init():
		level = 1
		realm = 0
		experience = 0
		experience_to_next_level = 100  # 初始升级所需经验

# 属性数据结构
class AttributeData:
	var total_points: int
	var allocated_points: int
	var reset_count: int
	var values: Dictionary  # 属性名称到数值的映射
	
	func _init():
		total_points = 0
		allocated_points = 0
		reset_count = 0
		values = {
			"strength": 10,      # 力道
			"agility": 10,      # 身法
			"constitution": 10,  # 根骨
			"intelligence": 10,  # 悟性
			"willpower": 10,   # 定力
			"luck": 10         # 福缘
		}

# 武学数据结构
class MartialArtsData:
	var learned_skills: Array  # 武学ID列表
	var skill_proficiencies: Dictionary  # 武学ID -> 熟练度
	var inner_arts: Array  # 内功心法配置 [slot1, slot2, slot3]
	var light_art: String  # 轻功秘籍
	
	func _init():
		learned_skills = []
		skill_proficiencies = {}
		inner_arts = [null, null, null]  # 三个内功槽位
		light_art = ""

# 装备数据结构
class EquipmentData:
	var slots: Dictionary  # 槽位类型 -> 装备ID
	var backpack: Array  # 背包中的装备ID列表
	
	func _init():
		slots = {}  # 初始化时会根据装备系统定义的槽位来填充
		backpack = []

# 奇遇数据结构
class EncounterData:
	var completed_encounters: Array  # 完成的奇遇ID列表
	var encounter_effects: Dictionary  # 奇遇ID -> 效果数据
	
	func _init():
		completed_encounters = []
		encounter_effects = {}

# 存档元数据结构
class SaveMetadata:
	var save_slot: int  # 存档槽位 (1-3)
	var player_name: String
	var play_time: int  # 游戏时间（秒）
	var last_location: String
	var checksum: String  # CRC32校验码
	
	func _init():
		save_slot = 1
		player_name = ""
		play_time = 0
		last_location = ""
		checksum = ""

# 定义成长数据结构
func define_growth_data_structure() -> GrowthData:
	var growth_data = GrowthData.new()
	
	# 发射信号通知其他系统
	data_structure_defined.emit("GrowthData")
	
	return growth_data

# 定义属性分配数据结构
func define_attribute_data_structure() -> AttributeData:
	var attribute_data = AttributeData.new()
	
	# 发射信号通知其他系统
	data_structure_defined.emit("AttributeData")
	
	return attribute_data

# 定义技能学习数据结构
func define_skill_data_structure() -> MartialArtsData:
	var martial_arts_data = MartialArtsData.new()
	
	# 发射信号通知其他系统
	data_structure_defined.emit("MartialArtsData")
	
	return martial_arts_data

# 定义装备数据结构
func define_equipment_data_structure() -> EquipmentData:
	var equipment_data = EquipmentData.new()
	
	# 发射信号通知其他系统
	data_structure_defined.emit("EquipmentData")
	
	return equipment_data

# 定义奇遇历史数据结构
func define_encounter_data_structure() -> EncounterData:
	var encounter_data = EncounterData.new()
	
	# 发射信号通知其他系统
	data_structure_defined.emit("EncounterData")
	
	return encounter_data

# 将成长数据转换为字典（用于JSON序列化）
func growth_data_to_dict(growth_data: GrowthData) -> Dictionary:
	var result = {}
	
	result["version"] = growth_data.version
	result["characterId"] = growth_data.character_id
	result["timestamp"] = growth_data.timestamp
	
	result["progression"] = {
		"level": growth_data.progression.level,
		"realm": growth_data.progression.realm,
		"experience": growth_data.progression.experience,
		"experienceToNextLevel": growth_data.progression.experience_to_next_level
	}
	
	result["attributes"] = {
		"totalPoints": growth_data.attributes.total_points,
		"allocatedPoints": growth_data.attributes.allocated_points,
		"resetCount": growth_data.attributes.reset_count,
		"values": growth_data.attributes.values
	}
	
	result["martialArts"] = {
		"learnedSkills": growth_data.martial_arts.learned_skills,
		"skillProficiencies": growth_data.martial_arts.skill_proficiencies,
		"innerArts": growth_data.martial_arts.inner_arts,
		"lightArt": growth_data.martial_arts.light_art
	}
	
	result["equipment"] = {
		"slots": growth_data.equipment.slots,
		"backpack": growth_data.equipment.backpack
	}
	
	result["encounters"] = {
		"completedEncounters": growth_data.encounters.completed_encounters,
		"encounterEffects": growth_data.encounters.encounter_effects
	}
	
	return result

# 从字典创建成长数据（用于JSON反序列化）
func dict_to_growth_data(data_dict: Dictionary) -> GrowthData:
	var growth_data = GrowthData.new()
	
	growth_data.version = data_dict.get("version", DATA_VERSION)
	growth_data.character_id = data_dict.get("characterId", "")
	growth_data.timestamp = data_dict.get("timestamp", Time.get_unix_time_from_system())
	
	# 设置进度数据
	if data_dict.has("progression"):
		var prog_data = data_dict["progression"]
		growth_data.progression.level = prog_data.get("level", 1)
		growth_data.progression.realm = prog_data.get("realm", 0)
		growth_data.progression.experience = prog_data.get("experience", 0)
		growth_data.progression.experience_to_next_level = prog_data.get("experienceToNextLevel", 100)
	
	# 设置属性数据
	if data_dict.has("attributes"):
		var attr_data = data_dict["attributes"]
		growth_data.attributes.total_points = attr_data.get("totalPoints", 0)
		growth_data.attributes.allocated_points = attr_data.get("allocatedPoints", 0)
		growth_data.attributes.reset_count = attr_data.get("resetCount", 0)
		growth_data.attributes.values = attr_data.get("values", {
			"strength": 10, "agility": 10, "constitution": 10,
			"intelligence": 10, "willpower": 10, "luck": 10
		})
	
	# 设置武学数据
	if data_dict.has("martialArts"):
		var ma_data = data_dict["martialArts"]
		growth_data.martial_arts.learned_skills = ma_data.get("learnedSkills", [])
		growth_data.martial_arts.skill_proficiencies = ma_data.get("skillProficiencies", {})
		growth_data.martial_arts.inner_arts = ma_data.get("innerArts", [null, null, null])
		growth_data.martial_arts.light_art = ma_data.get("lightArt", "")
	
	# 设置装备数据
	if data_dict.has("equipment"):
		var eq_data = data_dict["equipment"]
		growth_data.equipment.slots = eq_data.get("slots", {})
		growth_data.equipment.backpack = eq_data.get("backpack", [])
	
	# 设置奇遇数据
	if data_dict.has("encounters"):
		var enc_data = data_dict["encounters"]
		growth_data.encounters.completed_encounters = enc_data.get("completedEncounters", [])
		growth_data.encounters.encounter_effects = enc_data.get("encounterEffects", {})
	
	return growth_data

# 验证数据结构完整性
func validate_data_structure(growth_data: GrowthData) -> bool:
	# 检查必要字段是否存在
	if not growth_data:
		return false
	
	if not growth_data.progression:
		return false
	
	if not growth_data.attributes:
		return false
	
	# 检查等级范围
	if growth_data.progression.level < 1 or growth_data.progression.level > 99:
		return false
	
	# 检查境界范围
	if growth_data.progression.realm < 0 or growth_data.progression.realm > 9:
		return false
	
	# 检查属性值
	for attr_name in growth_data.attributes.values:
		var attr_value = growth_data.attributes.values[attr_name]
		if attr_value < 0:  # 属性值不应为负
			return false
	
	return true