## LevelUpManager
## 等级提升管理器
##
## 管理等级提升逻辑的节点，处理小境界提升和大境界突破。
## 包括经验值阈值计算、圆满状态检查和境界突破验证。
##
## 主要功能：
## - 小境界等级提升
## - 大境界突破处理
## - 经验值阈值计算
## - 圆满状态管理
## - 突破条件验证
## - 新功能解锁

extends Node
class_name LevelUpManager

# ============================================================================
# 常量定义
# ============================================================================

const BASE_EXP = 100
const EXPONENT_COEFFICIENT = 1.5
const MINOR_BONUS_BASE = 5
const MAJOR_BONUS_RATE = 0.1  # 10%全属性加成

# ============================================================================
# 信号定义
# ============================================================================

signal minor_realm_upgraded(character_id: String, new_level: int)
signal major_realm_breakthrough_started(character_id: String, new_realm: String)
signal major_realm_breakthrough_completed(character_id: String, new_realm: String)
signal perfect_state_achieved(character_id: String, realm: String)
signal exp_threshold_calculated(level: int, threshold: int)

# 境界结构定义
var realm_structure = {
	"Qi_Refining": {"start_level": 1, "end_level": 10, "realm_name": "炼气期", "difficulty_coefficient": 1.0},
	"Foundation_Building": {"start_level": 11, "end_level": 20, "realm_name": "筑基期", "difficulty_coefficient": 1.5},
	"Golden_Core": {"start_level": 21, "end_level": 30, "realm_name": "金丹期", "difficulty_coefficient": 2.0},
	"Nascent_Soul": {"start_level": 31, "end_level": 40, "realm_name": "元婴期", "difficulty_coefficient": 2.5},
	"Spirit_Transformation": {"start_level": 41, "end_level": 50, "realm_name": "化神期", "difficulty_coefficient": 3.0},
	"Return_to_Void": {"start_level": 51, "end_level": 60, "realm_name": "返虚期", "difficulty_coefficient": 3.5},
	"Unity_with_Dao": {"start_level": 61, "end_level": 70, "realm_name": "合道期", "difficulty_coefficient": 4.0},
	"Great_Vehicle": {"start_level": 71, "end_level": 80, "realm_name": "大乘期", "difficulty_coefficient": 4.5},
	"Heavenly_Tribulation": {"start_level": 81, "end_level": 90, "realm_name": "渡劫期", "difficulty_coefficient": 5.0},
	"True_Immortal": {"start_level": 91, "end_level": 99, "realm_name": "真仙境", "difficulty_coefficient": 6.0}
}

# 玩家数据
var player_data = {
	"level": 1,
	"exp": 0,
	"total_exp": 0,
	"current_realm": "Qi_Refining",
	"attribute_points": 0,
	"talent_points": 0,
	"breakthrough_items": {"Foundation_Pill": 0},  # 突破道具
	"perfect_state": false  # 圆满状态
}

# 系统引用
var experience_system = null
var character_progression_system = null

# 初始化
func _ready():
	# 初始化等级提升管理器
	pass

# 触发小境界提升
func trigger_minor_realm_up(character_id: String):
	if not player_data.has(character_id):
		push_error("Player data not found for character: " + character_id)
		return false
	
	var char_data = player_data
	if char_data.exp >= calculate_exp_threshold(char_data.level):
		# 提升等级
		char_data.level += 1
		char_data.exp = 0  # 重置EXP
		
		# 增加属性点和天赋点
		char_data.attribute_points += 5
		char_data.talent_points += 1
		
		# 恢复满血/满内力（这部分需要与健康/内力系统集成）
		restore_full_hp_mp(character_id)
		
		# 检查是否达到圆满状态
		if check_perfect_state(char_data.level, char_data.current_realm):
			char_data.perfect_state = true
			emit_signal("perfect_state_achieved", character_id, get_current_realm_name(char_data.current_realm))
		
		# 发射信号
		emit_signal("minor_realm_upgraded", character_id, char_data.level)
		
		return true
	
	return false

# 触发大境界突破
func trigger_major_realm_breakthrough(character_id: String) -> bool:
	if not player_data.has(character_id):
		push_error("Player data not found for character: " + character_id)
		return false
	
	var char_data = player_data
	if not char_data.perfect_state:
		push_error("Character is not in perfect state for breakthrough")
		return false
	
	# 验证突破条件
	if not verify_breakthrough_conditions(char_data):
		push_error("Breakthrough conditions not met")
		return false
	
	# 开始突破
	emit_signal("major_realm_breakthrough_started", character_id, get_next_realm_name(char_data.current_realm))
	
	# 执行突破逻辑
	var old_realm = char_data.current_realm
	var new_realm = get_next_realm_key(old_realm)
	
	if new_realm != "":
		char_data.current_realm = new_realm
		char_data.perfect_state = false  # 退出圆满状态
		
		# 应用大境界突破奖励（全属性+10%加成）
		apply_major_breakthrough_bonus(character_id)
		
		# 解锁新功能（武学槽位、装备栏位等）
		unlock_new_functions(character_id)
		
		# 发射突破完成信号
		emit_signal("major_realm_breakthrough_completed", character_id, get_current_realm_name(char_data.current_realm))
		
		return true
	
	return false

# 计算EXP阈值
func calculate_exp_threshold(current_level: int) -> int:
	var current_realm = get_realm_by_level(current_level)
	if not realm_structure.has(current_realm):
		push_error("Unknown realm for level: " + str(current_level))
		return 999999  # 返回一个很大的数，防止意外升级
	
	var realm_info = realm_structure[current_realm]
	var current_sub_level = current_level - realm_info.start_level + 1
	
	# EXP阈值 = 基础EXP × (当前小境界^指数系数) × 境界难度系数
	var threshold = int(BASE_EXP * pow(current_sub_level, EXPONENT_COEFFICIENT) * realm_info.difficulty_coefficient)
	
	# 发射信号
	emit_signal("exp_threshold_calculated", current_level, threshold)
	
	return threshold

# 检查圆满状态
func check_perfect_state(level: int, realm: String) -> bool:
	if not realm_structure.has(realm):
		return false
	
	var realm_info = realm_structure[realm]
	return level == realm_info.end_level

# 验证突破条件
func verify_breakthrough_conditions(char_data) -> bool:
	# 检查EXP是否已满（实际上在圆满状态下EXP已经是满的）
	if not char_data.perfect_state:
		return false
	
	# 检查是否持有特定突破道具（如：筑基丹）
	var required_item = get_required_breakthrough_item(char_data.current_realm)
	if char_data.breakthrough_items.get(required_item, 0) <= 0:
		push_warning("Missing required breakthrough item: " + required_item)
		return false
	
	# 检查是否完成特定的"心魔试炼"任务或Boss战（这里简化处理）
	# 实际游戏中可能需要检查任务完成状态
	
	return true

# 获取当前境界名称
func get_current_realm_name(realm_key: String) -> String:
	if realm_structure.has(realm_key):
		return realm_structure[realm_key].realm_name
	return "未知境界"

# 获取下一个境界名称
func get_next_realm_name(current_realm: String) -> String:
	var next_realm_key = get_next_realm_key(current_realm)
	if next_realm_key != "":
		return get_current_realm_name(next_realm_key)
	return "已达到最高境界"

# 获取下一个境界键
func get_next_realm_key(current_realm: String) -> String:
	var realm_keys = realm_structure.keys()
	var current_index = realm_keys.find(current_realm)
	
	if current_index != -1 and current_index < realm_keys.size() - 1:
		return realm_keys[current_index + 1]
	
	return ""  # 已达到最高境界

# 根据等级获取所属境界
func get_realm_by_level(level: int) -> String:
	for realm_key in realm_structure.keys():
		var realm_info = realm_structure[realm_key]
		if level >= realm_info.start_level and level <= realm_info.end_level:
			return realm_key
	
	return "Qi_Refining"  # 默认返回第一个境界

# 应用大境界突破奖励
func apply_major_breakthrough_bonus(character_id: String):
	# 全属性+10%加成
	# 这里需要与角色属性系统集成
	if character_progression_system:
		character_progression_system.apply_percentage_bonus(character_id, MAJOR_BONUS_RATE)

# 解锁新功能
func unlock_new_functions(character_id: String):
	# 解锁新武学槽位、装备栏位或世界区域访问权限
	# 这里需要与其他系统集成
	if character_progression_system:
		character_progression_system.unlock_new_slots(character_id)

# 恢复满血/满内力
func restore_full_hp_mp(character_id: String):
	# 与健康/内力系统集成，恢复满血/满内力
	if character_progression_system:
		character_progression_system.restore_full_hp_mp(character_id)

# 获取所需突破道具
func get_required_breakthrough_item(current_realm: String) -> String:
	# 根据当前境界确定所需突破道具
	match current_realm:
		"Qi_Refining":
			return "Foundation_Pill"  # 筑基丹
		"Foundation_Building":
			return "Core_Pill"  # 结金丹
		"Golden_Core":
			return "Soul_Pill"  # 元婴丹
		"Nascent_Soul":
			return "Spirit_Pill"  # 化神丹
		_:
			return "Universal_Breakthrough_Pill"  # 通用突破丹

# 添加EXP
func add_exp(character_id: String, exp_amount: int):
	if not player_data.has(character_id):
		push_error("Player data not found for character: " + character_id)
		return
	
	var char_data = player_data
	char_data.exp += exp_amount
	char_data.total_exp += exp_amount
	
	# 检查是否可以小境界提升
	while char_data.exp >= calculate_exp_threshold(char_data.level):
		if not trigger_minor_realm_up(character_id):
			break  # 如果无法升级则跳出循环

# 获取玩家当前境界信息
func get_current_realm_info(character_id: String) -> Dictionary:
	if not player_data.has(character_id):
		return {}
	
	var char_data = player_data
	var realm_info = realm_structure[char_data.current_realm]
	
	return {
		"current_realm_key": char_data.current_realm,
		"current_realm_name": get_current_realm_name(char_data.current_realm),
		"current_level_in_realm": char_data.level - realm_info.start_level + 1,
		"total_levels_in_realm": realm_info.end_level - realm_info.start_level + 1,
		"is_perfect_state": char_data.perfect_state,
		"exp_to_next": calculate_exp_threshold(char_data.level) - char_data.exp,
		"exp_progress": float(char_data.exp) / float(calculate_exp_threshold(char_data.level))
	}

# 获取玩家状态
func get_player_status(character_id: String) -> Dictionary:
	if not player_data.has(character_id):
		return {}
	
	var char_data = player_data
	return {
		"level": char_data.level,
		"exp": char_data.exp,
		"total_exp": char_data.total_exp,
		"current_realm": char_data.current_realm,
		"attribute_points": char_data.attribute_points,
		"talent_points": char_data.talent_points,
		"is_perfect_state": char_data.perfect_state
	}