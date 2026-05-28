## CharacterSystem
## 角色系统核心管理器
## 负责管理角色的核心属性、等级、境界和成长机制。
## 包括属性管理、经验值系统、升级机制、境界突破和天赋网格系统。
## 主要功能：
## - 角色属性管理（六维属性系统）
## - 经验值获取和升级机制
## - 境界突破系统
## - 天赋网格解锁和效果应用
## - 战斗属性计算

extends Node

# 注意：此脚本作为AutoLoad单例使用，不需要class_name声明
# AutoLoad名称：CharacterSystem

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

# 信号定义
signal level_up_event(new_level: int, attribute_points: int, talent_points: int)
signal realm_breakthrough(new_realm: String, realm_bonus: float, realm_index: int)
signal experience_gained(amount: int, current_exp: int, required_exp: int)
signal attribute_points_allocated(attribute_name: String, points: int, new_value: int)
signal attributes_reset(free_reset_used: bool)

# 角色核心属性
class CharacterAttributes:
	var strength: int = 10      # 力道
	var agility: int = 10       # 身法
	var constitution: int = 10  # 根骨
	var intelligence: int = 10  # 悟性
	var willpower: int = 10     # 定力
	var luck: int = 10          # 福缘

	func get_total() -> Dictionary:
		return {
			"strength": strength,
			"agility": agility,
			"constitution": constitution,
			"intelligence": intelligence,
			"willpower": willpower,
			"luck": luck
		}

	func add_points(points_dict: Dictionary) -> void:
		if points_dict.has("strength"):
			strength += int(points_dict["strength"])
		if points_dict.has("agility"):
			agility += int(points_dict["agility"])
		if points_dict.has("constitution"):
			constitution += int(points_dict["constitution"])
		if points_dict.has("intelligence"):
			intelligence += int(points_dict["intelligence"])
		if points_dict.has("willpower"):
			willpower += int(points_dict["willpower"])
		if points_dict.has("luck"):
			luck += int(points_dict["luck"])

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
var level: int = 1
var experience: int = 0
var total_attribute_points: int = 0
var allocated_attribute_points: int = 0
var total_talent_points: int = 0    # 天赋点总数
var allocated_talent_points: int = 0  # 已分配天赋点数
var attributes: CharacterAttributes = CharacterAttributes.new()
var realm_index: int = 0  # 当前境界索引 (0-9)
var realm_bonus: float = 1.0  # 境界加成系数
var free_reset_count: int = 0  # 免费重置次数

# 寿命管理器引用（用于NPC寿命系统）
var lifespan_manager: LifespanManager = null

# 天赋网格系统 (Array[Array] — 4x4 dict 网格, GDScript 嵌套泛型限制, 不再细化)
var talent_grid: Array = []  # 4x4天赋网格 [[{unlocked: bool, effect: {...}}, ...], ...]
var talent_definitions: Dictionary = {}  # 天赋定义 {talent_id: {name: str, effect: {...}, description: str}}

# 经验值配置
## exponent 字段仅作 fallback / 配置兜底; 实际曲线由 _get_exp_exponent() 按等级分段返回。
## 分段配置对齐 design/gdd/experience-system.md L170-L172:
##   Lv 1-33  → 1.0 (线性, 引导期)
##   Lv 34-66 → 1.5 (温和指数, 中期)
##   Lv 67-99 → 1.8 (陡峭指数, 后期, 受 50000 EXP 上限约束)
var exp_curve: Dictionary = {
	"base": 100,
	"exponent": 1.5,
	"realm_multiplier": [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 6.0]
}

func _ready() -> void:
	# 初始化角色
	initialize_character()

	# 初始化寿命管理器
	initialize_lifespan_manager()

func initialize_character() -> void:
	"""初始化角色默认状态"""
	level = 1
	experience = 0
	total_attribute_points = 5  # 初始5点属性点
	allocated_attribute_points = 0
	total_talent_points = 1     # 初始1点天赋点
	allocated_talent_points = 0
	attributes = CharacterAttributes.new()
	realm_index = 0
	realm_bonus = 1.0
	free_reset_count = 0
	
	# 初始化天赋网格系统
	initialize_talent_grid()
	
	print("角色初始化完成")

func initialize_lifespan_manager() -> void:
	"""初始化寿命管理器"""
	# 创建寿命管理器实例
	lifespan_manager = LifespanManager.new()
	add_child(lifespan_manager)
	
	# 连接寿命警告信号
	lifespan_manager.npc_lifespan_warning.connect(_on_npc_lifespan_warning)
	
	print("寿命管理器初始化完成")

func _on_npc_lifespan_warning(npc_id: String, remaining_years: int):
	"""处理NPC寿命警告信号"""
	print("[CharacterSystem] NPC %s 寿命将尽，剩余 %d 年" % [npc_id, remaining_years])
	# 这里可以触发特殊剧情或对话

func initialize_talent_grid() -> void:
	"""初始化4x4天赋网格"""
	# 创建4x4网格，所有节点初始为未解锁状态
	talent_grid.clear()
	for row in range(4):
		var grid_row: Array = []
		for col in range(4):
			grid_row.append({
				"unlocked": false,
				"effect": {}
			})
		talent_grid.append(grid_row)
	
	# 初始化天赋定义（示例数据）
	talent_definitions = {
		"talent_0_0": {"name": "力拔山兮", "effect": {"strength": 10}, "description": "增加10点力道"},
		"talent_0_1": {"name": "身轻如燕", "effect": {"agility": 10}, "description": "增加10点身法"},
		"talent_0_2": {"name": "铜皮铁骨", "effect": {"constitution": 10}, "description": "增加10点根骨"},
		"talent_0_3": {"name": "天资聪颖", "effect": {"intelligence": 10}, "description": "增加10点悟性"},
		"talent_1_0": {"name": "意志坚定", "effect": {"willpower": 10}, "description": "增加10点定力"},
		"talent_1_1": {"name": "福星高照", "effect": {"luck": 10}, "description": "增加10点福缘"},
		"talent_1_2": {"name": "内力深厚", "effect": {"internal_energy_max": 50}, "description": "增加50点内力上限"},
		"talent_1_3": {"name": "生命源泉", "effect": {"max_health": 100}, "description": "增加100点最大生命值"},
		"talent_2_0": {"name": "破甲专家", "effect": {"physical_attack": 20}, "description": "增加20点物理攻击力"},
		"talent_2_1": {"name": "闪避大师", "effect": {"evasion": 0.1}, "description": "增加10%闪避率"},
		"talent_2_2": {"name": "暴击专家", "effect": {"critical_rate": 0.05}, "description": "增加5%暴击率"},
		"talent_2_3": {"name": "命中专家", "effect": {"hit_rate": 0.05}, "description": "增加5%命中率"},
		"talent_3_0": {"name": "掉落专家", "effect": {"drop_rate_bonus": 10.0}, "description": "增加10%掉落加成"},
		"talent_3_1": {"name": "内力回复", "effect": {"internal_energy_regen": 0.02}, "description": "增加2%内力回复率"},
		"talent_3_2": {"name": "防御专家", "effect": {"defense": 20}, "description": "增加20点防御力"},
		"talent_3_3": {"name": "全属性提升", "effect": {"strength": 5, "agility": 5, "constitution": 5, "intelligence": 5, "willpower": 5, "luck": 5}, "description": "所有属性各增加5点"}
	}

func add_experience(exp_amount: int) -> void:
	"""添加经验值并处理升级"""
	experience += exp_amount

	# 发射经验值获得信号
	var required_exp: int = get_exp_required_for_level(level + 1)
	experience_gained.emit(exp_amount, experience, required_exp)

	# 全局事件广播 — 让 HUD player_status_panel 刷新经验条
	# to_next 语义: 距离下一级所需的剩余经验值
	if GameEvents:
		var to_next: int = max(0, required_exp - experience)
		GameEvents.player_exp_changed.emit(experience, to_next)

	check_level_up()

func check_level_up() -> void:
	"""检查是否可以升级"""
	while experience >= get_exp_required_for_level(level + 1) and level < 99:
		level_up()

func level_up() -> void:
	"""角色升级"""
	if level >= 99:
		return

	# 升级前先记录原等级,用于 GameEvents 全局信号
	var old_level: int = level

	# 消耗升级所需经验
	experience -= get_exp_required_for_level(level + 1)
	level += 1

	# 获得属性点和天赋点
	total_attribute_points += 5
	total_talent_points += 1

	# 发射升级信号
	level_up_event.emit(level, total_attribute_points, total_talent_points)

	# 全局事件广播 — 让 HUD player_status_panel 刷新等级显示
	if GameEvents:
		GameEvents.player_level_up.emit(level, old_level)
		# 升级后经验条会重置 (experience 已扣除升级消耗), 同步广播
		var required_exp: int = get_exp_required_for_level(level + 1)
		var to_next: int = max(0, required_exp - experience)
		GameEvents.player_exp_changed.emit(experience, to_next)

	# 检查境界突破
	check_realm_breakthrough()

	print("角色升级到 %d 级" % level)

func check_realm_breakthrough() -> void:
	"""检查是否达到境界突破条件"""
	var current_realm: Dictionary = get_current_realm()
	if level == current_realm["level_range"][1]:
		# TODO(beta): 触发突破界面, 当前自动突破用于测试
		print("达到 %s 期圆满，准备突破" % current_realm["name"])

func breakthrough_realm() -> void:
	"""境界突破"""
	if realm_index >= 9:  # 已经是最高境界
		return

	# 突破前先记录原境界名,用于 GameEvents 全局信号
	var old_realm_name: String = get_current_realm()["name"]

	realm_index += 1
	realm_bonus = 1.0 + (realm_index * 0.1)  # 每次突破增加10%全属性加成
	free_reset_count += 1  # 获得一次免费重置机会

	var current_realm: Dictionary = get_current_realm()

	# 发射境界突破信号
	realm_breakthrough.emit(current_realm["name"], realm_bonus, realm_index)

	# 全局事件广播 — 让 HUD 等监听 GameEvents 的系统刷新境界图标
	if GameEvents:
		GameEvents.player_realm_changed.emit(current_realm["name"], old_realm_name)

	print("突破到 %s 期，全属性加成 %.1f%%" % [current_realm["name"], (realm_bonus - 1.0) * 100])

func get_current_realm() -> Dictionary:
	"""获取当前境界信息"""
	return REALMS[realm_index]

func get_realm_by_level(target_level: int) -> Dictionary:
	"""根据等级获取对应的境界"""
	for i in range(REALMS.size()):
		var realm: Dictionary = REALMS[i]
		if target_level >= realm["level_range"][0] and target_level <= realm["level_range"][1]:
			return {"realm": realm, "index": i}
	return {"realm": REALMS[9], "index": 9}  # 默认返回最高境界

func get_exp_required_for_level(target_level: int) -> int:
	"""计算升级到目标等级所需的经验值"""
	if target_level <= 1:
		return 0
	if target_level > 99:
		target_level = 99

	var realm_info: Dictionary = get_realm_by_level(target_level - 1)
	var realm_multiplier: float = exp_curve["realm_multiplier"][realm_info["index"]]

	# 分段 exponent 对齐 design/gdd/experience-system.md L170-L172
	var exponent: float = _get_exp_exponent(target_level)
	var exp_required: float = exp_curve["base"] * pow(target_level, exponent) * realm_multiplier
	return int(exp_required)

func _get_exp_exponent(target_level: int) -> float:
	"""根据目标等级返回 EXP 公式的分段指数 (GDD experience-system.md L170-L172)。

	参数:
		target_level: 目标升级等级 (1-99)
	返回:
		1.0 (Lv 1-33) / 1.5 (Lv 34-66) / 1.8 (Lv 67-99)
	"""
	if target_level <= 33:
		return 1.0
	elif target_level <= 66:
		return 1.5
	else:
		return 1.8

func allocate_attribute_points(attribute_name: String, points: int) -> bool:
	"""分配属性点"""
	# 验证输入参数
	if points <= 0:
		return false

	# 验证属性点是否足够
	if allocated_attribute_points + points > total_attribute_points:
		return false

	# 验证属性名称是否有效
	var valid_attributes: Array = ["strength", "agility", "constitution", "intelligence", "willpower", "luck"]
	if not valid_attributes.has(attribute_name):
		return false

	# 执行属性分配
	var old_value: int = 0
	var new_value: int = 0

	match attribute_name:
		"strength":
			old_value = attributes.strength
			attributes.strength += points
			new_value = attributes.strength
		"agility":
			old_value = attributes.agility
			attributes.agility += points
			new_value = attributes.agility
		"constitution":
			old_value = attributes.constitution
			attributes.constitution += points
			new_value = attributes.constitution
		"intelligence":
			old_value = attributes.intelligence
			attributes.intelligence += points
			new_value = attributes.intelligence
		"willpower":
			old_value = attributes.willpower
			attributes.willpower += points
			new_value = attributes.willpower
		"luck":
			old_value = attributes.luck
			attributes.luck += points
			new_value = attributes.luck
	
	allocated_attribute_points += points
	
	# 发射属性点分配信号
	attribute_points_allocated.emit(attribute_name, points, new_value)
	
	return true

func reset_attributes() -> bool:
	"""重置属性点"""
	var used_free_reset: bool = false

	if free_reset_count > 0:
		free_reset_count -= 1
		used_free_reset = true
	else:
		# 需要消耗洗髓丹
		if not consume_wash_marrow_pill():
			push_warning("没有足够的洗髓丹或免费重置次数")
			return false

	# 重置所有属性到基础值
	attributes = CharacterAttributes.new()
	allocated_attribute_points = 0

	# 发射重置信号
	attributes_reset.emit(used_free_reset)

	return true

func consume_wash_marrow_pill() -> bool:
	"""消耗洗髓丹"""
	# 与物品系统集成
	var item_manager: Node = get_node_or_null("/root/MainGame/ItemManager")
	if item_manager:
		return item_manager.remove_item(item_manager.ITEM_WASH_MARROW_PILL, 1)
	else:
		# 如果没有物品管理器，返回false（在实际游戏中不应该发生）
		push_warning("物品管理器未找到，无法消耗洗髓丹")
		return false

# 天赋网格系统功能

func unlock_talent(row: int, col: int) -> bool:
	"""解锁天赋节点"""
	# 验证坐标范围
	if row < 0 or row >= 4 or col < 0 or col >= 4:
		return false

	# 验证天赋点是否足够
	if allocated_talent_points >= total_talent_points:
		return false

	# 验证节点是否已经解锁
	if talent_grid[row][col]["unlocked"]:
		return false

	# 解锁天赋节点
	talent_grid[row][col]["unlocked"] = true
	allocated_talent_points += 1

	# 设置天赋效果
	var talent_id: String = "talent_%d_%d" % [row, col]
	if talent_definitions.has(talent_id):
		talent_grid[row][col]["effect"] = talent_definitions[talent_id]["effect"]

	return true

func reset_talents() -> bool:
	"""重置天赋网格"""
	# 重置所有天赋节点为未解锁状态
	for row in range(4):
		for col in range(4):
			talent_grid[row][col]["unlocked"] = false
			talent_grid[row][col]["effect"] = {}

	# 重置已分配天赋点数
	allocated_talent_points = 0

	return true

func get_talent_effects() -> Dictionary:
	"""获取所有已解锁天赋的效果"""
	var total_effects: Dictionary = {}

	for row in range(4):
		for col in range(4):
			if talent_grid[row][col]["unlocked"]:
				var effect: Dictionary = talent_grid[row][col]["effect"]
				for key in effect:
					if total_effects.has(key):
						total_effects[key] += effect[key]
					else:
						total_effects[key] = effect[key]

	return total_effects

func get_final_attributes() -> CharacterAttributes:
	"""获取最终属性（包含境界加成和天赋效果）"""
	var final_attrs: CharacterAttributes = CharacterAttributes.new()
	
	# 基础属性 + 境界加成
	final_attrs.strength = int(attributes.strength * realm_bonus)
	final_attrs.agility = int(attributes.agility * realm_bonus)
	final_attrs.constitution = int(attributes.constitution * realm_bonus)
	final_attrs.intelligence = int(attributes.intelligence * realm_bonus)
	final_attrs.willpower = int(attributes.willpower * realm_bonus)
	final_attrs.luck = int(attributes.luck * realm_bonus)
	
	# 应用天赋效果
	var talent_effects: Dictionary = get_talent_effects()
	if talent_effects.has("strength"):
		final_attrs.strength += int(talent_effects["strength"])
	if talent_effects.has("agility"):
		final_attrs.agility += int(talent_effects["agility"])
	if talent_effects.has("constitution"):
		final_attrs.constitution += int(talent_effects["constitution"])
	if talent_effects.has("intelligence"):
		final_attrs.intelligence += int(talent_effects["intelligence"])
	if talent_effects.has("willpower"):
		final_attrs.willpower += int(talent_effects["willpower"])
	if talent_effects.has("luck"):
		final_attrs.luck += int(talent_effects["luck"])

	return final_attrs

func get_combat_stats() -> Dictionary:
	"""获取战斗属性（包含天赋效果）"""
	var final_attrs: CharacterAttributes = get_final_attributes()
	var combat_stats: Dictionary = {
		"physical_attack": final_attrs.strength * 2,
		"magical_attack": final_attrs.intelligence * 2,
		"max_health": final_attrs.constitution * 10,
		"defense": final_attrs.constitution + final_attrs.willpower,
		"evasion": final_attrs.agility / 10.0,
		# 暴击率 = 身法 × 0.3% + 福缘 × 0.2% (对齐 design/gdd/character-progression-system.md L59)
		"critical_rate": final_attrs.agility * 0.003 + final_attrs.luck * 0.002,
		"hit_rate": final_attrs.willpower / 15.0,
		"internal_energy_max": final_attrs.constitution * 5 + final_attrs.intelligence * 3,
		"internal_energy_regen": 0.05,  # 基础5%内力回复率
		"drop_rate_bonus": final_attrs.luck / 5.0
	}
	
	# 应用天赋效果到战斗属性
	var talent_effects: Dictionary = get_talent_effects()
	if talent_effects.has("physical_attack"):
		combat_stats["physical_attack"] += talent_effects["physical_attack"]
	if talent_effects.has("max_health"):
		combat_stats["max_health"] += talent_effects["max_health"]
	if talent_effects.has("defense"):
		combat_stats["defense"] += talent_effects["defense"]
	if talent_effects.has("evasion"):
		combat_stats["evasion"] += talent_effects["evasion"]
	if talent_effects.has("critical_rate"):
		combat_stats["critical_rate"] += talent_effects["critical_rate"]
	if talent_effects.has("hit_rate"):
		combat_stats["hit_rate"] += talent_effects["hit_rate"]
	if talent_effects.has("internal_energy_max"):
		combat_stats["internal_energy_max"] += talent_effects["internal_energy_max"]
	if talent_effects.has("internal_energy_regen"):
		combat_stats["internal_energy_regen"] += talent_effects["internal_energy_regen"]
	if talent_effects.has("drop_rate_bonus"):
		combat_stats["drop_rate_bonus"] += talent_effects["drop_rate_bonus"]

	return combat_stats

static func get_luck_bonus_coefficient(luck_stat: float) -> float:
	"""福缘加成系数 (软上限) — 单一真值, 对齐 design/gdd/character-progression-system.md L146-L152。

	所有使用 (1 + luck/100) 线性公式的系统都应迁移到本函数, 实现 100 点后边际递减,
	防止极端福缘 Build 让奇遇/掉落/合成收益脱离设计预期。

	采用 static 设计 — 调用方既可通过 Autoload 路径 `CharacterSystem.get_luck_bonus_coefficient(luck)`
	使用, 也可在单元测试里不挂载 Autoload 直接调用脚本的 static 方法, 保持公式可测试性。

	参数:
		luck_stat: 玩家福缘属性值 (允许 float 兼容含天赋加成后的非整数值)
	返回:
		加成系数 0.0-2.32:
		- luck = 0   → 0.0
		- luck = 50  → 0.5  (线性段, 每点 +1%)
		- luck = 100 → 1.0  (拐点)
		- luck = 200 → 1.33 (递减段, 每点 +0.33%)
		- luck = 495 → 2.32 (上限示例)
	"""
	if luck_stat <= 0.0:
		return 0.0
	if luck_stat <= 100.0:
		return luck_stat / 100.0
	return 1.0 + (luck_stat - 100.0) / 300.0

# 寿命系统相关方法
func get_npc_lifespan_info(npc_id: String) -> Dictionary:
	"""获取NPC寿命信息（用于UI显示和对话系统）"""
	if lifespan_manager:
		return lifespan_manager.get_npc_lifespan_info(npc_id)
	return {}

func get_npc_age_description(npc_id: String) -> String:
	"""获取NPC年龄描述（用于对话系统）"""
	if lifespan_manager:
		return lifespan_manager.get_age_description(npc_id)
	return "年龄未知"

func get_npc_lifespan_description(npc_id: String) -> String:
	"""获取NPC寿命描述（用于对话系统）"""
	if lifespan_manager:
		return lifespan_manager.get_lifespan_description(npc_id)
	return "未知"

func is_npc_lifespan_warning(npc_id: String) -> bool:
	"""检查NPC是否寿命将尽（用于剧情判定）"""
	if lifespan_manager:
		return lifespan_manager.is_npc_lifespan_warning(npc_id)
	return false

# 调试函数
func debug_print_character_info() -> void:
	"""打印角色信息用于调试"""
	print("=== 角色信息 ===")
	print("等级: %d" % level)
	print("境界: %s" % get_current_realm()["name"])
	print("经验值: %d / %d" % [experience, get_exp_required_for_level(level + 1)])
	print("属性点: %d / %d" % [allocated_attribute_points, total_attribute_points])
	print("天赋点: %d / %d" % [allocated_talent_points, total_talent_points])
	print("免费重置次数: %d" % free_reset_count)
	print("境界加成: %.1f%%" % ((realm_bonus - 1.0) * 100))

	var final_attrs: CharacterAttributes = get_final_attributes()
	print("最终属性:")
	print("  力道: %d" % final_attrs.strength)
	print("  身法: %d" % final_attrs.agility)
	print("  根骨: %d" % final_attrs.constitution)
	print("  悟性: %d" % final_attrs.intelligence)
	print("  定力: %d" % final_attrs.willpower)
	print("  福缘: %d" % final_attrs.luck)
	
	var combat_stats: Dictionary = get_combat_stats()
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
	
	# 打印天赋网格状态
	print("天赋网格状态:")
	for row in range(4):
		var row_str: String = ""
		for col in range(4):
			if talent_grid[row][col]["unlocked"]:
				row_str += "X "
			else:
				row_str += "O "
		print("  %s" % row_str)

	# 打印NPC寿命信息
	if lifespan_manager:
		print("\n=== NPC寿命信息 ===")
		lifespan_manager.debug_print_all_npcs()

	print("================")