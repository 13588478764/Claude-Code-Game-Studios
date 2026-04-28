# 境界解锁管理器
# 负责根据角色境界解锁相应的装备槽位

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

# 槽位定义结构
class SlotDefinition:
	var slot_type: int
	var required_realm: int
	var max_tier: int
	
	func _init(type: int, realm: int, tier: int):
		slot_type = type
		required_realm = realm
		max_tier = tier

# 信号定义
signal realm_unlocked(slot_type: int, character_realm: int)
signal slot_lock_status_updated(slot_type: int, is_locked: bool)

# 初始化
func _ready():
	print("境界解锁管理器已初始化")

# 根据境界解锁槽位
func unlock_slots_for_realm(realm_level: int) -> Array:
	var unlocked_slots = []
	
	# 根据境界等级解锁对应的槽位
	match realm_level:
		RealmLevel.LIANG_QI:
			# 炼气期解锁基础槽位
			unlocked_slots.append(SlotType.WEAPON_MAIN)
			unlocked_slots.append(SlotType.BODY)
			unlocked_slots.append(SlotType.FEET)
		RealmLevel.ZHU_JI:
			# 筑基期解锁头部和手部槽位
			unlocked_slots.append(SlotType.HEAD)
			unlocked_slots.append(SlotType.HANDS)
		RealmLevel.JIN_DAN:
			# 金丹期解锁腿部和第一个戒指槽位
			unlocked_slots.append(SlotType.LEGS)
			unlocked_slots.append(SlotType.RING_1)
		RealmLevel.YUAN_YING:
			# 元婴期解锁副手武器和项链槽位
			unlocked_slots.append(SlotType.WEAPON_OFFHAND)
			unlocked_slots.append(SlotType.NECKLACE)
		RealmLevel.HUA_SHEN:
			# 化神期解锁腰带槽位
			unlocked_slots.append(SlotType.BELT)
		RealmLevel.FAN_XU:
			# 返虚期解锁第一个内功心法槽位
			unlocked_slots.append(SlotType.INNER_ART_1)
		RealmLevel.HE_DAO:
			# 合道期解锁第二个内功心法槽位
			unlocked_slots.append(SlotType.INNER_ART_2)
		RealmLevel.DA_CHENG:
			# 大乘期解锁轻功秘籍槽位
			unlocked_slots.append(SlotType.LIGHT_ART)
		RealmLevel.DU_JIE:
			# 渡劫期解锁第二个戒指槽位
			unlocked_slots.append(SlotType.RING_2)
		RealmLevel.ZHEN_XIAN:
			# 真仙境解锁第三个内功心法槽位
			unlocked_slots.append(SlotType.INNER_ART_3)
	
	return unlocked_slots

# 检查境界要求
func check_realm_requirements(slot_type: int, character_realm: int) -> bool:
	var required_realm = get_required_realm_for_slot(slot_type)
	return character_realm >= required_realm

# 获取槽位所需的境界
func get_required_realm_for_slot(slot_type: int) -> int:
	match slot_type:
		SlotType.WEAPON_MAIN: return RealmLevel.LIANG_QI
		SlotType.WEAPON_OFFHAND: return RealmLevel.YUAN_YING
		SlotType.HEAD: return RealmLevel.ZHU_JI
		SlotType.BODY: return RealmLevel.LIANG_QI
		SlotType.HANDS: return RealmLevel.ZHU_JI
		SlotType.LEGS: return RealmLevel.JIN_DAN
		SlotType.FEET: return RealmLevel.LIANG_QI
		SlotType.RING_1: return RealmLevel.JIN_DAN
		SlotType.RING_2: return RealmLevel.DU_JIE
		SlotType.NECKLACE: return RealmLevel.YUAN_YING
		SlotType.BELT: return RealmLevel.HUA_SHEN
		SlotType.INNER_ART_1: return RealmLevel.FAN_XU
		SlotType.INNER_ART_2: return RealmLevel.HE_DAO
		SlotType.INNER_ART_3: return RealmLevel.ZHEN_XIAN
		SlotType.LIGHT_ART: return RealmLevel.DA_CHENG
		_: return RealmLevel.LIANG_QI  # 默认为炼气期

# 更新槽位锁定状态
func update_slot_lock_status(character: Dictionary, slot_manager) -> Dictionary:
	var updated_slots = {}
	var character_realm = character.get("realm_level", RealmLevel.LIANG_QI)
	
	# 获取所有槽位类型
	var all_slot_types = slot_manager.get_all_slot_types()
	
	for slot_type in all_slot_types:
		var is_unlocked = check_realm_requirements(slot_type, character_realm)
		updated_slots[slot_type] = is_unlocked
		
		# 发出槽位锁定状态更新信号
		emit_signal("slot_lock_status_updated", slot_type, not is_unlocked)
	
	return updated_slots

# 境界变化事件处理
func on_realm_changed(new_realm: int, character: Dictionary, slot_manager) -> Array:
	var newly_unlocked_slots = []
	
	# 获取当前角色的槽位状态
	var current_slot_status = update_slot_lock_status(character, slot_manager)
	
	# 检查哪些槽位是新解锁的
	for slot_type in current_slot_status.keys():
		if current_slot_status[slot_type]:  # 如果槽位已解锁
			# 检查之前是否被锁定
			var required_realm = get_required_realm_for_slot(slot_type)
			if new_realm >= required_realm:
				newly_unlocked_slots.append(slot_type)
				emit_signal("realm_unlocked", slot_type, new_realm)
	
	return newly_unlocked_slots

# 获取境界名称
func get_realm_name(realm_level: int) -> String:
	match realm_level:
		RealmLevel.LIANG_QI: return "炼气期"
		RealmLevel.ZHU_JI: return "筑基期"
		RealmLevel.JIN_DAN: return "金丹期"
		RealmLevel.YUAN_YING: return "元婴期"
		RealmLevel.HUA_SHEN: return "化神期"
		RealmLevel.FAN_XU: return "返虚期"
		RealmLevel.HE_DAO: return "合道期"
		RealmLevel.DA_CHENG: return "大乘期"
		RealmLevel.DU_JIE: return "渡劫期"
		RealmLevel.ZHEN_XIAN: return "真仙境"
		_: return "未知境界"

# 获取境界解锁的槽位描述
func get_realm_unlock_description(realm_level: int) -> String:
	var description = get_realm_name(realm_level) + "解锁槽位："
	
	match realm_level:
		RealmLevel.LIANG_QI:
			description += "主手武器、身体、脚部"
		RealmLevel.ZHU_JI:
			description += "头部、手部"
		RealmLevel.JIN_DAN:
			description += "腿部、戒指1"
		RealmLevel.YUAN_YING:
			description += "副手武器、项链"
		RealmLevel.HUA_SHEN:
			description += "腰带"
		RealmLevel.FAN_XU:
			description += "内功心法1"
		RealmLevel.HE_DAO:
			description += "内功心法2"
		RealmLevel.DA_CHENG:
			description += "轻功秘籍"
		RealmLevel.DU_JIE:
			description += "戒指2"
		RealmLevel.ZHEN_XIAN:
			description += "内功心法3"
		_:
			description += "无"
	
	return description

# 测试函数
func test_realm_unlocks():
	print("开始测试境界解锁机制...")
	
	# 测试每个境界解锁的槽位
	var test_realm = RealmLevel.ZHU_JI
	var unlocked = unlock_slots_for_realm(test_realm)
	
	if unlocked.size() > 0:
		print("✅ 境界解锁功能正常")
	else:
		print("❌ 境界解锁功能异常")
	
	# 测试境界要求检查
	var req_check = check_realm_requirements(SlotType.WEAPON_MAIN, RealmLevel.LIANG_QI)
	if req_check:
		print("✅ 境界要求检查功能正常")
	else:
		print("❌ 境界要求检查功能异常")
	
	print("境界解锁机制测试完成")