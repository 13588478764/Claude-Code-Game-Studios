# 武侠奇遇录 - 角色系统
# 负责管理角色的核心属性、等级、境界和成长机制

extends Node

# 角色核心属性
class CharacterAttributes:
	var strength = 10      # 力道
	var agility = 10       # 身法  
	var constitution = 10  # 根骨
	var intelligence = 10  # 悟性
	var willpower = 10     # 定力
	var luck = 10          # 福缘
	
	func get_total():
		return {
			"strength": strength,
			"agility": agility,
			"constitution": constitution,
			"intelligence": intelligence,
			"willpower": willpower,
			"luck": luck
		}
	
	func add_points(points_dict):
		if points_dict.has("strength"):
			strength += points_dict["strength"]
		if points_dict.has("agility"):
			agility += points_dict["agility"]
		if points_dict.has("constitution"):
			constitution += points_dict["constitution"]
		if points_dict.has("intelligence"):
			intelligence += points_dict["intelligence"]
		if points_dict.has("willpower"):
			willpower += points_dict["willpower"]
		if points_dict.has("luck"):
			luck += points_dict["luck"]

# 境界定义
const REALMS = [
	{"name": "炼气", "level_range": [1, 10]},
	{"name": "筑基", "level_range": [11, 20]},
	{"name": "金丹", "level_range": [21, 30]},
	{"name": "元婴", "level_range": [31, 40]},
	{"name": "化神", "level_range": [41, 50]},
	{"name": "返虚", "level_range": [51, 60]},
	{"name": "合道", "level_range": [61, 70]},
	{"name": "大乘", "level_range": [71, 80]},
	{"name": "渡劫", "level_range": [81, 90]},
	{"name": "真仙", "level_range": [91, 99]}
]

# 角色状态
var level = 1
var experience = 0
var total_attribute_points = 0
var allocated_attribute_points = 0
var attributes = CharacterAttributes.new()
var realm_index = 0  # 当前境界索引 (0-9)
var realm_bonus = 1.0  # 境界加成系数
var free_reset_count = 0  # 免费重置次数

# 经验值配置
var exp_curve = {
	"base": 100,
	"exponent": 1.5,
	"realm_multiplier": [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 6.0]
}

func _ready():
	# 初始化角色
	initialize_character()

func initialize_character():
	"""初始化角色默认状态"""
	level = 1
	experience = 0
	total_attribute_points = 5  # 初始5点属性点
	allocated_attribute_points = 0
	attributes = CharacterAttributes.new()
	realm_index = 0
	realm_bonus = 1.0
	free_reset_count = 0
	
	print("角色初始化完成")

func add_experience(exp_amount):
	"""添加经验值并处理升级"""
	experience += exp_amount
	check_level_up()

func check_level_up():
	"""检查是否可以升级"""
	while experience >= get_exp_required_for_level(level + 1) and level < 99:
		level_up()

func level_up():
	"""角色升级"""
	if level >= 99:
		return
	
	# 消耗升级所需经验
	experience -= get_exp_required_for_level(level + 1)
	level += 1
	
	# 获得属性点
	total_attribute_points += 5
	
	# 检查境界突破
	check_realm_breakthrough()
	
	print("角色升级到 %d 级" % level)

func check_realm_breakthrough():
	"""检查是否达到境界突破条件"""
	var current_realm = get_current_realm()
	if level == current_realm["level_range"][1]:
		# 达到当前境界的最大等级
		print("达到 %s 期圆满，准备突破" % current_realm["name"])
		# 这里应该触发突破界面，但暂时先自动突破用于测试
		# 在实际游戏中，玩家需要完成特定条件才能突破

func breakthrough_realm():
	"""境界突破"""
	if realm_index >= 9:  # 已经是最高境界
		return
	
	realm_index += 1
	realm_bonus = 1.0 + (realm_index * 0.1)  # 每次突破增加10%全属性加成
	free_reset_count += 1  # 获得一次免费重置机会
	
	print("突破到 %s 期，全属性加成 %.1f%%" % [get_current_realm()["name"], (realm_bonus - 1.0) * 100])

func get_current_realm():
	"""获取当前境界信息"""
	return REALMS[realm_index]

func get_realm_by_level(target_level):
	"""根据等级获取对应的境界"""
	for i in range(REALMS.size()):
		var realm = REALMS[i]
		if target_level >= realm["level_range"][0] and target_level <= realm["level_range"][1]:
			return {"realm": realm, "index": i}
	return {"realm": REALMS[9], "index": 9}  # 默认返回最高境界

func get_exp_required_for_level(target_level):
	"""计算升级到目标等级所需的经验值"""
	if target_level <= 1:
		return 0
	if target_level > 99:
		target_level = 99
	
	var realm_info = get_realm_by_level(target_level - 1)
	var realm_multiplier = exp_curve["realm_multiplier"][realm_info["index"]]
	
	var exp_required = exp_curve["base"] * pow(target_level, exp_curve["exponent"]) * realm_multiplier
	return int(exp_required)

func allocate_attribute_points(attribute_name, points):
	"""分配属性点"""
	if allocated_attribute_points + points > total_attribute_points:
		push_warning("属性点不足")
		return false
	
	if points <= 0:
		return false
	
	match attribute_name:
		"strength":
			attributes.strength += points
		"agility":
			attributes.agility += points
		"constitution":
			attributes.constitution += points
		"intelligence":
			attributes.intelligence += points
		"willpower":
			attributes.willpower += points
		"luck":
			attributes.luck += points
		_:
			push_warning("未知属性: %s" % attribute_name)
			return false
	
	allocated_attribute_points += points
	return true

func reset_attributes():
	"""重置属性点"""
	if free_reset_count > 0:
		free_reset_count -= 1
	else:
		# 需要消耗洗髓丹
		if not consume_wash_marrow_pill():
			push_warning("没有足够的洗髓丹或免费重置次数")
			return false
	
	# 重置所有属性到基础值
	attributes = CharacterAttributes.new()
	allocated_attribute_points = 0
	return true

func consume_wash_marrow_pill():
	"""消耗洗髓丹"""
	# 这里需要与物品系统集成
	# 暂时返回true用于测试
	return true

func get_final_attributes():
	"""获取最终属性（包含境界加成）"""
	var final_attrs = CharacterAttributes.new()
	final_attrs.strength = int(attributes.strength * realm_bonus)
	final_attrs.agility = int(attributes.agility * realm_bonus)
	final_attrs.constitution = int(attributes.constitution * realm_bonus)
	final_attrs.intelligence = int(attributes.intelligence * realm_bonus)
	final_attrs.willpower = int(attributes.willpower * realm_bonus)
	final_attrs.luck = int(attributes.luck * realm_bonus)
	return final_attrs

func get_combat_stats():
	"""获取战斗属性"""
	var final_attrs = get_final_attributes()
	var combat_stats = {
		"physical_attack": final_attrs.strength * 2,
		"magical_attack": final_attrs.intelligence * 2,
		"max_health": final_attrs.constitution * 10,
		"defense": final_attrs.constitution + final_attrs.willpower,
		"evasion": final_attrs.agility / 10.0,
		"critical_rate": final_attrs.intelligence / 20.0,
		"hit_rate": final_attrs.willpower / 15.0,
		"internal_energy_max": final_attrs.constitution * 5 + final_attrs.intelligence * 3,
		"internal_energy_regen": 0.05,  # 基础5%内力回复率
		"drop_rate_bonus": final_attrs.luck / 5.0
	}
	return combat_stats

# 调试函数
func debug_print_character_info():
	"""打印角色信息用于调试"""
	print("=== 角色信息 ===")
	print("等级: %d" % level)
	print("境界: %s" % get_current_realm()["name"])
	print("经验值: %d / %d" % [experience, get_exp_required_for_level(level + 1)])
	print("属性点: %d / %d" % [allocated_attribute_points, total_attribute_points])
	print("免费重置次数: %d" % free_reset_count)
	print("境界加成: %.1f%%" % ((realm_bonus - 1.0) * 100))
	
	var final_attrs = get_final_attributes()
	print("最终属性:")
	print("  力道: %d" % final_attrs.strength)
	print("  身法: %d" % final_attrs.agility)
	print("  根骨: %d" % final_attrs.constitution)
	print("  悟性: %d" % final_attrs.intelligence)
	print("  定力: %d" % final_attrs.willpower)
	print("  福缘: %d" % final_attrs.luck)
	
	var combat_stats = get_combat_stats()
	print("战斗属性:")
	print("  物理攻击: %d" % combat_stats["physical_attack"])
	print("  内功攻击: %d" % combat_stats["magical_attack"])
	print("  最大生命: %d" % combat_stats["max_health"])
	print("  防御力: %d" % combat_stats["defense"])
	print("  闪避率: %.1f%%" % (combat_stats["evasion"] * 100))
	print("  暴击率: %.1f%%" % (combat_stats["critical_rate"] * 100))
	print("  命中率: %.1f%%" % (combat_stats["hit_rate"] * 100))
	print("  内力上限: %d" % combat_stats["internal_energy_max"])
	print("  内力回复: %.1f%%" % (combat_stats["internal_energy_regen"] * 100))
	print("  掉落加成: %.1f%%" % (combat_stats["drop_rate_bonus"] * 100))
	print("================")

# UI回调函数
func _on_test_button_pressed():
	"""测试按钮点击回调"""
	# 测试升级
	add_experience(1000)
	
	# 测试属性分配
	allocate_attribute_points("strength", 2)
	allocate_attribute_points("agility", 2)
	allocate_attribute_points("constitution", 1)
	
	# 测试境界突破
	if level >= 10:
		breakthrough_realm()
	
	# 打印调试信息
	debug_print_character_info()
