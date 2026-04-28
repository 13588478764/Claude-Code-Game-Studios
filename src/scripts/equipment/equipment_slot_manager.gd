# 装备槽位管理器
# 负责定义和管理角色的装备槽位

extends Node

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

# 槽位定义结构
class EquipmentSlot:
	var slot_type: int
	var equipment_id: String
	var is_locked: bool
	var required_realm: int
	var max_equipment_tier: int
	
	func _init(type: int):
		slot_type = type
		equipment_id = ""
		is_locked = true
		required_realm = 0
		max_equipment_tier = 1

# 角色装备槽位结构
class CharacterEquipment:
	var slots: Dictionary
	
	func _init():
		slots = {}
		# 初始化所有槽位
		for slot_type in SlotType.values():
			slots[slot_type] = EquipmentSlot.new(slot_type)

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

# 信号定义
signal slot_defined(slot_type: int, is_unlocked: bool)

# 初始化
func _ready():
	print("装备槽位管理器已初始化")

# 定义槽位类型
func define_slot_types():
	var slot_definitions = {}
	
	# 武器槽位
	slot_definitions[SlotType.WEAPON_MAIN] = {"name": "weapon_main", "required_realm": RealmLevel.LIANG_QI, "max_tier": 1}
	slot_definitions[SlotType.WEAPON_OFFHAND] = {"name": "weapon_offhand", "required_realm": RealmLevel.YUAN_YING, "max_tier": 3}
	
	# 防具槽位
	slot_definitions[SlotType.HEAD] = {"name": "head", "required_realm": RealmLevel.ZHU_JI, "max_tier": 2}
	slot_definitions[SlotType.BODY] = {"name": "body", "required_realm": RealmLevel.LIANG_QI, "max_tier": 1}
	slot_definitions[SlotType.HANDS] = {"name": "hands", "required_realm": RealmLevel.ZHU_JI, "max_tier": 2}
	slot_definitions[SlotType.LEGS] = {"name": "legs", "required_realm": RealmLevel.JIN_DAN, "max_tier": 2}
	slot_definitions[SlotType.FEET] = {"name": "feet", "required_realm": RealmLevel.LIANG_QI, "max_tier": 1}
	
	# 饰品槽位
	slot_definitions[SlotType.RING_1] = {"name": "ring_1", "required_realm": RealmLevel.JIN_DAN, "max_tier": 2}
	slot_definitions[SlotType.RING_2] = {"name": "ring_2", "required_realm": RealmLevel.DU_JIE, "max_tier": 4}
	slot_definitions[SlotType.NECKLACE] = {"name": "necklace", "required_realm": RealmLevel.YUAN_YING, "max_tier": 3}
	slot_definitions[SlotType.BELT] = {"name": "belt", "required_realm": RealmLevel.HUA_SHEN, "max_tier": 3}
	
	# 特殊槽位
	slot_definitions[SlotType.INNER_ART_1] = {"name": "inner_art_1", "required_realm": RealmLevel.FAN_XU, "max_tier": 3}
	slot_definitions[SlotType.INNER_ART_2] = {"name": "inner_art_2", "required_realm": RealmLevel.HE_DAO, "max_tier": 3}
	slot_definitions[SlotType.INNER_ART_3] = {"name": "inner_art_3", "required_realm": RealmLevel.ZHEN_XIAN, "max_tier": 4}
	slot_definitions[SlotType.LIGHT_ART] = {"name": "light_art", "required_realm": RealmLevel.DA_CHENG, "max_tier": 4}
	
	return slot_definitions

# 初始化角色槽位
func initialize_character_slots(character: Dictionary) -> CharacterEquipment:
	var char_equipment = CharacterEquipment.new()
	var slot_defs = define_slot_types()
	
	# 根据角色当前境界设置槽位状态
	var character_realm = character.get("realm_level", RealmLevel.LIANG_QI)
	
	for slot_type in char_equipment.slots.keys():
		var slot = char_equipment.slots[slot_type]
		var slot_def = slot_defs.get(slot_type, {"required_realm": 0, "max_tier": 1})
		
		# 检查槽位是否已解锁
		slot.is_locked = slot_def.required_realm > character_realm
		slot.required_realm = slot_def.required_realm
		slot.max_equipment_tier = slot_def.max_tier
	
	return char_equipment

# 获取指定类型的槽位
func get_slot_by_type(character_equipment: CharacterEquipment, slot_type: int) -> EquipmentSlot:
	if character_equipment.slots.has(slot_type):
		return character_equipment.slots[slot_type]
	else:
		print("错误：槽位类型不存在 - ", slot_type)
		return null

# 验证槽位类型有效性
func is_valid_slot_type(slot_type: int) -> bool:
	return slot_type in SlotType.values()

# 获取槽位名称
func get_slot_name(slot_type: int) -> String:
	match slot_type:
		SlotType.WEAPON_MAIN: return "主手武器"
		SlotType.WEAPON_OFFHAND: return "副手武器"
		SlotType.HEAD: return "头部"
		SlotType.BODY: return "身体"
		SlotType.HANDS: return "手部"
		SlotType.LEGS: return "腿部"
		SlotType.FEET: return "脚部"
		SlotType.RING_1: return "戒指1"
		SlotType.RING_2: return "戒指2"
		SlotType.NECKLACE: return "项链"
		SlotType.BELT: return "腰带"
		SlotType.INNER_ART_1: return "内功心法1"
		SlotType.INNER_ART_2: return "内功心法2"
		SlotType.INNER_ART_3: return "内功心法3"
		SlotType.LIGHT_ART: return "轻功秘籍"
		_: return "未知槽位"

# 获取所有槽位类型
func get_all_slot_types() -> Array:
	return SlotType.values()

# 测试函数
func test_slot_definitions():
	print("开始测试槽位定义...")
	
	var slot_defs = define_slot_types()
	
	# 验证槽位数量
	if slot_defs.size() == 15:
		print("✅ 槽位数量正确：15个槽位")
	else:
		print("❌ 槽位数量错误：期望15个，实际", slot_defs.size())
	
	# 验证特定槽位
	if slot_defs.has(SlotType.WEAPON_MAIN) and slot_defs[SlotType.WEAPON_MAIN].required_realm == RealmLevel.LIANG_QI:
		print("✅ 主手武器槽位定义正确")
	else:
		print("❌ 主手武器槽位定义错误")
	
	if slot_defs.has(SlotType.RING_2) and slot_defs[SlotType.RING_2].required_realm == RealmLevel.DU_JIE:
		print("✅ 第二戒指槽位定义正确")
	else:
		print("❌ 第二戒指槽位定义错误")
	
	print("槽位定义测试完成")