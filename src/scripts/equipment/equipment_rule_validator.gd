## 装备规则验证器
## 负责验证装备品阶、职业和性别限制
extends Node

class_name EquipmentRuleValidator

# 槽位类型枚举
enum SlotType {
	WEAPON_MAIN,      # 主手武器
	WEAPON_OFFHAND,    # 副手武器
	HEAD,              # 头部
	BODY,              # 身体
	HANDS,             # 手部
	LEGS,              # 腿部
	FEET,              # 脚部
	RING_1,            # 戒指1
	RING_2,            # 戒指2
	NECKLACE,          # 项链
	BELT,              # 腰带
	INNER_ART_1,       # 内功心法1
	INNER_ART_2,       # 内功心法2
	INNER_ART_3,       # 内功心法3
	LIGHT_ART,         # 轻功秘籍
}

# 境界等级枚举（对应10个大境界）
enum RealmLevel {
	LIANG_QI,    # 炼气期 (1-9级)
	ZHU_JI,      # 筑基期 (10-19级)
	JIN_DAN,     # 金丹期 (20-29级)
	YUAN_YING,   # 元婴期 (30-39级)
	HUA_SHEN,    # 化神期 (40-49级)
	FAN_XU,      # 返虚期 (50-59级)
	HE_DAO,      # 合道期 (60-69级)
	DA_CHENG,    # 大乘期 (70-79级)
	DU_JIE,      # 渡劫期 (80-89级)
	ZHEN_XIAN    # 真仙境 (90-99级)
}

# 装备品阶枚举
enum EquipmentTier {
	COMMON = 1,    # 普通（白色）
	RARE = 2,      # 稀有（蓝色）
	EPIC = 3,      # 史诗（紫色）
	LEGENDARY = 4, # 传说（金色）
}

# 职业类型枚举
enum CharacterClass {
	SWORDSMAN,    # 剑客
	SPEARMAN,     # 枪客
	AXEMAN,       # 刀客
	FIST_FIGHTER, # 拳师
	QI_CULTIVATOR # 灵力修炼者
}

# 性别枚举
enum Gender {
	MALE,   # 男性
	FEMALE, # 女性
	UNISEX  # 无性别限制
}

# 信号定义
signal validation_performed(item_id: String, is_valid: bool, reason: String)

# 初始化
func _ready():
	print("装备规则验证器已初始化")

# 验证装备品阶
func validate_equipment_tier(item_id: String, character_realm: int) -> bool:
	var item_info = get_item_info(item_id)
	if not item_info:
		print("错误：物品不存在 - ", item_id)
		return false

	var item_tier = item_info.get("tier", EquipmentTier.COMMON)

	match item_tier:
		EquipmentTier.COMMON:
			return true
		EquipmentTier.RARE:
			return character_realm >= RealmLevel.ZHU_JI
		EquipmentTier.EPIC:
			return character_realm >= RealmLevel.YUAN_YING
		EquipmentTier.LEGENDARY:
			return character_realm >= RealmLevel.DA_CHENG
		_:
			return false

# 验证职业限制
func validate_profession_requirement(item_id: String, character_class: int) -> bool:
	var item_info = get_item_info(item_id)
	if not item_info:
		print("错误：物品不存在 - ", item_id)
		return false

	var required_class = item_info.get("required_class", -1)

	if required_class == -1:
		return true

	return character_class == required_class

# 验证性别限制
func validate_gender_requirement(item_id: String, character_gender: int) -> bool:
	var item_info = get_item_info(item_id)
	if not item_info:
		print("错误：物品不存在 - ", item_id)
		return false

	var required_gender = item_info.get("required_gender", Gender.UNISEX)

	if required_gender == Gender.UNISEX:
		return true

	return character_gender == required_gender

# 综合验证装备是否可以装备
func can_equip_item(item_id: String, slot_type: int, character: Dictionary) -> bool:
	var item_info = get_item_info(item_id)
	if not item_info:
		emit_signal("validation_performed", item_id, false, "物品不存在")
		return false

	if not validate_equipment_tier(item_id, character.get("realm_level", RealmLevel.LIANG_QI)):
		emit_signal("validation_performed", item_id, false, "境界不足，无法装备此品阶装备")
		return false

	if not validate_profession_requirement(item_id, character.get("character_class", CharacterClass.SWORDSMAN)):
		emit_signal("validation_performed", item_id, false, "职业不符，无法装备")
		return false

	if not validate_gender_requirement(item_id, character.get("gender", Gender.MALE)):
		emit_signal("validation_performed", item_id, false, "性别不符，无法装备")
		return false

	if not is_slot_compatible(item_id, slot_type):
		emit_signal("validation_performed", item_id, false, "装备类型与槽位不匹配")
		return false

	emit_signal("validation_performed", item_id, true, "验证通过")
	return true

# 验证装备更换
func validate_equipment_change(old_item_id: String, new_item_id: String, slot_type: int) -> bool:
	if new_item_id == "":
		return true

	return can_equip_item(new_item_id, slot_type, get_test_character())

# 获取物品信息（模拟从数据库获取）
func get_item_info(item_id: String) -> Dictionary:
	var sample_items = {
		"sword_common_001": {
			"id": "sword_common_001",
			"name": "铁剑",
			"tier": EquipmentTier.COMMON,
			"type": "weapon",
			"slot": SlotType.WEAPON_MAIN,
			"required_class": -1,
			"required_gender": Gender.UNISEX
		},
		"sword_rare_001": {
			"id": "sword_rare_001",
			"name": "精钢剑",
			"tier": EquipmentTier.RARE,
			"type": "weapon",
			"slot": SlotType.WEAPON_MAIN,
			"required_class": CharacterClass.SWORDSMAN,
			"required_gender": Gender.UNISEX
		},
		"sword_epic_001": {
			"id": "sword_epic_001",
			"name": "青冥剑",
			"tier": EquipmentTier.EPIC,
			"type": "weapon",
			"slot": SlotType.WEAPON_MAIN,
			"required_class": CharacterClass.SWORDSMAN,
			"required_gender": Gender.UNISEX
		},
		"sword_legendary_001": {
			"id": "sword_legendary_001",
			"name": "天外飞仙",
			"tier": EquipmentTier.LEGENDARY,
			"type": "weapon",
			"slot": SlotType.WEAPON_MAIN,
			"required_class": CharacterClass.SWORDSMAN,
			"required_gender": Gender.UNISEX
		},
		"armor_male_001": {
			"id": "armor_male_001",
			"name": "男性专用护甲",
			"tier": EquipmentTier.RARE,
			"type": "armor",
			"slot": SlotType.BODY,
			"required_class": -1,
			"required_gender": Gender.MALE
		},
		"necklace_female_001": {
			"id": "necklace_female_001",
			"name": "女性专用项链",
			"tier": EquipmentTier.EPIC,
			"type": "accessory",
			"slot": SlotType.NECKLACE,
			"required_class": -1,
			"required_gender": Gender.FEMALE
		}
	}

	return sample_items.get(item_id, {})

# 检查槽位兼容性
func is_slot_compatible(item_id: String, slot_type: int) -> bool:
	var item_info = get_item_info(item_id)
	if not item_info:
		return false

	var item_slot_type = item_info.get("slot", -1)
	return item_slot_type == slot_type

# 获取测试角色信息
func get_test_character() -> Dictionary:
	return {
		"realm_level": RealmLevel.ZHEN_XIAN,
		"character_class": CharacterClass.SWORDSMAN,
		"gender": Gender.MALE
	}

# 获取品阶名称
func get_tier_name(tier: int) -> String:
	match tier:
		EquipmentTier.COMMON: return "普通"
		EquipmentTier.RARE: return "稀有"
		EquipmentTier.EPIC: return "史诗"
		EquipmentTier.LEGENDARY: return "传说"
		_: return "未知"

# 获取职业名称
func get_class_name(class_type: int) -> String:
	match class_type:
		CharacterClass.SWORDSMAN: return "剑客"
		CharacterClass.SPEARMAN: return "枪客"
		CharacterClass.AXEMAN: return "刀客"
		CharacterClass.FIST_FIGHTER: return "拳师"
		CharacterClass.QI_CULTIVATOR: return "灵力修炼者"
		_: return "未知"
