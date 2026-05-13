## MartialArtsSystem
## 武学系统
##
## 管理武学的获取、熟练度、装备和组合等功能。
##
## 功能：
## - 武学获取与管理（数据库、玩家武学、残页）
## - 武学装备（4个槽位、装备/卸载）
## - 熟练度系统（等级、经验、升级）
## - 武学组合（组合数据、执行）
##
## 依赖系统：
## - 无直接依赖

extends Node

# ============================================================================
# 常量定义
# ============================================================================

const FRAGMENT_NEEDED_FOR_SYNTHESIS: int = 3  # 合成所需残页数
const EMPTY_MANUAL_ITEM_ID: String = "empty_manual"  # 空槽位ID

const MAX_EQUIPPED_MARTIAL_ARTS: int = 4  # 最大装备武学数
const MAX_PROFICIENCY_LEVEL: int = 10  # 最大熟练度等级

# ============================================================================
# 信号定义
# ============================================================================

signal martial_art_acquired(martial_art_id: String)
signal martial_art_proficiency_changed(martial_art_id: String, new_level: int)
signal martial_art_equipped(martial_art_id: String, slot_index: int)
signal martial_art_combo_executed(combo_name: String, damage_multiplier: float)
signal martial_art_unequipped(martial_art_id: String, slot_index: int)

# 武学数据结构（内部使用，避免与全局 MartialArtData 冲突）
class MartialArtInfo:
	var id: String
	var name: String
	var description: String
	var school: String  # 门派
	var grade: String   # 品阶（黄、玄、地、天）
	var weapon_type: String  # 武器类型
	var base_damage: float
	var damage_scale: float
	var hit_count: int
	var element_type: String
	var startup_frames: float
	var active_frames: float
	var recovery_frames: float
	var total_duration: float
	var cost_stamina: float
	var cost_mana: float
	var cooldown: float
	var unlock_level: int
	var proficiency_level: int
	var fragments_collected: int
	
	func _init(p_id: String = "", p_name: String = "", p_description: String = "", p_school: String = "", p_grade: String = "", 
			   p_weapon_type: String = "", p_base_damage: float = 0.0, p_damage_scale: float = 1.0, p_hit_count: int = 1,
			   p_element_type: String = "", p_startup_frames: float = 0.0, p_active_frames: float = 0.0, 
			   p_recovery_frames: float = 0.0, p_total_duration: float = 0.0, p_cost_stamina: float = 0.0, 
			   p_cost_mana: float = 0.0, p_cooldown: float = 0.0, p_unlock_level: int = 1):
		id = p_id
		name = p_name
		description = p_description
		school = p_school
		grade = p_grade
		weapon_type = p_weapon_type
		base_damage = p_base_damage
		damage_scale = p_damage_scale
		hit_count = p_hit_count
		element_type = p_element_type
		startup_frames = p_startup_frames
		active_frames = p_active_frames
		recovery_frames = p_recovery_frames
		total_duration = p_total_duration
		cost_stamina = p_cost_stamina
		cost_mana = p_cost_mana
		cooldown = p_cooldown
		unlock_level = p_unlock_level
		proficiency_level = 0
		fragments_collected = 0
	
	# 复制方法
	func duplicate(deep: bool = false) -> MartialArtInfo:
		var copy = MartialArtInfo.new()
		copy.id = id
		copy.name = name
		copy.description = description
		copy.school = school
		copy.grade = grade
		copy.weapon_type = weapon_type
		copy.base_damage = base_damage
		copy.damage_scale = damage_scale
		copy.hit_count = hit_count
		copy.element_type = element_type
		copy.startup_frames = startup_frames
		copy.active_frames = active_frames
		copy.recovery_frames = recovery_frames
		copy.total_duration = total_duration
		copy.cost_stamina = cost_stamina
		copy.cost_mana = cost_mana
		copy.cooldown = cooldown
		copy.unlock_level = unlock_level
		copy.proficiency_level = proficiency_level
		copy.fragments_collected = fragments_collected
		return copy

# 武学系统数据
var martial_arts_database: Dictionary = {}  # 存储所有武学数据
var player_martial_arts: Dictionary = {}   # 玩家已获取的武学
var player_fragments: Dictionary = {}      # 玩家拥有的武学残页
var equipped_martial_arts: Array = []      # 已装备的武学（4个槽位）
var martial_art_combos: Dictionary = {}    # 武学组合数据

# 初始化
func _ready():
	# 初始化4个武学槽位
	for i in range(4):
		equipped_martial_arts.append(null)
	
	# 加载基础武学数据
	load_basic_martial_arts()

# 加载基础武学数据
func load_basic_martial_arts():
	# 示例：添加一些基础武学
	var basic_sword = MartialArtInfo.new(
		"sword_basic_01", 
		"基础剑法", 
		"最基础的剑法，适合初学者练习", 
		"通用", 
		"黄阶", 
		"Sword", 
		50.0, 
		1.0, 
		1, 
		"无", 
		0.5, 
		0.3, 
		1.0, 
		1.8, 
		5.0, 
		10.0, 
		2.0, 
		1
	)
	
	var basic_fist = MartialArtInfo.new(
		"fist_basic_01", 
		"基础拳法", 
		"最基础的拳法，锻炼根基", 
		"通用", 
		"黄阶", 
		"Fist", 
		45.0, 
		1.0, 
		1, 
		"无", 
		0.6, 
		0.4, 
		1.2, 
		2.2, 
		8.0, 
		8.0, 
		2.5, 
		1
	)
	
	var basic_palm = MartialArtInfo.new(
		"palm_basic_01",
		"基础掌法",
		"以柔克刚的掌法，适合近身搏击",
		"通用",
		"黄阶",
		"Palm",
		55.0,
		1.0,
		1,
		"无",
		0.4,
		0.5,
		0.8,
		1.7,
		6.0,
		12.0,
		2.0,
		1
	)

	martial_arts_database[basic_sword.id] = basic_sword
	martial_arts_database[basic_fist.id] = basic_fist
	martial_arts_database[basic_palm.id] = basic_palm

# 获取武学数据
func get_martial_art_data(martial_art_id: String):
	if martial_arts_database.has(martial_art_id):
		return martial_arts_database[martial_art_id]
	return null

# 获取玩家武学
func get_player_martial_art(martial_art_id: String):
	if player_martial_arts.has(martial_art_id):
		return player_martial_arts[martial_art_id]
	return null

# 检查玩家是否拥有武学
func has_martial_art(martial_art_id: String) -> bool:
	return player_martial_arts.has(martial_art_id)

# 通过多种方式获取武学（残页合成、奇遇奖励、黑市购买等）
func acquire_martial_art_fragment(martial_art_id: String) -> bool:
	if !martial_arts_database.has(martial_art_id):
		print("错误：武学ID不存在: ", martial_art_id)
		return false
	
	# 如果玩家还没有这个武学的记录，创建一个
	if !player_fragments.has(martial_art_id):
		player_fragments[martial_art_id] = 0
	
	# 增加残页数量
	player_fragments[martial_art_id] += 1
	print("获得武学残页: ", martial_art_id, " 当前数量: ", player_fragments[martial_art_id])
	
	# 检查是否可以合成
	if player_fragments[martial_art_id] >= FRAGMENT_NEEDED_FOR_SYNTHESIS:
		if has_item(EMPTY_MANUAL_ITEM_ID):  # 检查是否有空白秘籍
			synthesize_martial_art(martial_art_id)
		else:
			print("缺少空白秘籍，无法合成武学")
	
	return true

# 合成武学（3张同名残页 + 1本空白秘籍 = 完整武学）
func synthesize_martial_art(martial_art_id: String) -> bool:
	if !player_fragments.has(martial_art_id) or player_fragments[martial_art_id] < FRAGMENT_NEEDED_FOR_SYNTHESIS:
		print("残页数量不足，无法合成")
		return false
	
	if !has_item(EMPTY_MANUAL_ITEM_ID):
		print("缺少空白秘籍，无法合成")
		return false
	
	# 检查基础武学是否存在
	if !martial_arts_database.has(martial_art_id):
		print("基础武学数据不存在")
		return false
	
	# 消耗材料
	player_fragments[martial_art_id] -= FRAGMENT_NEEDED_FOR_SYNTHESIS
	remove_item(EMPTY_MANUAL_ITEM_ID, 1)
	
	# 创建完整的武学数据并添加到玩家武学库
	var martial_art_data = martial_arts_database[martial_art_id].duplicate(true)
	martial_art_data.fragments_collected = FRAGMENT_NEEDED_FOR_SYNTHESIS  # 记录合成时的残页数量
	
	player_martial_arts[martial_art_id] = martial_art_data
	emit_signal("martial_art_acquired", martial_art_id)
	
	print("成功合成武学: ", martial_art_data.name)
	
	return true

# 检查玩家是否拥有指定物品
func has_item(item_id: String) -> bool:
	# 这里简化处理，实际项目中应该有一个物品管理系统
	if item_id == EMPTY_MANUAL_ITEM_ID:
		# 假设玩家总是有一定数量的空白秘籍
		return true
	return false

# 移除物品
func remove_item(item_id: String, count: int) -> bool:
	# 这里简化处理，实际项目中应该有一个物品管理系统
	if item_id == EMPTY_MANUAL_ITEM_ID:
		print("消耗了 ", count, " 本空白秘籍")
		return true
	return false

# 增加武学熟练度
func increase_proficiency(martial_art_id: String, base_gain: int, luck_factor: float = 0.0, combo_multiplier: float = 1.0) -> float:
	if !player_martial_arts.has(martial_art_id):
		print("玩家未拥有该武学: ", martial_art_id)
		return 0.0
	
	var martial_art = player_martial_arts[martial_art_id]
	
	# 计算熟练度获取
	var proficiency_gain = base_gain * (1 + luck_factor) * combo_multiplier
	
	# 增加熟练度
	martial_art.proficiency_level += int(proficiency_gain)
	
	# 限制熟练度上限
	if martial_art.proficiency_level > 15:
		martial_art.proficiency_level = 15
	
	emit_signal("martial_art_proficiency_changed", martial_art_id, martial_art.proficiency_level)
	
	print("武学 ", martial_art.name, " 熟练度提升至: ", martial_art.proficiency_level)
	
	return proficiency_gain

# 装备武学到指定槽位
func equip_martial_art(martial_art_id: String, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= equipped_martial_arts.size():
		print("槽位索引无效: ", slot_index)
		return false
	
	if !player_martial_arts.has(martial_art_id):
		print("玩家未拥有该武学: ", martial_art_id)
		return false
	
	var martial_art = player_martial_arts[martial_art_id]
	equipped_martial_arts[slot_index] = martial_art
	
	emit_signal("martial_art_equipped", martial_art_id, slot_index)
	
	print("武学 ", martial_art.name, " 已装备到槽位 ", slot_index)
	
	return true

# 获取已装备的武学
func get_equipped_martial_art(slot_index: int):
	if slot_index < 0 or slot_index >= equipped_martial_arts.size():
		return null
	return equipped_martial_arts[slot_index]

# 执行武学组合
func execute_combo(combo_sequence: Array) -> Dictionary:
	var result = {
		"success": false,
		"damage_multiplier": 1.0,
		"combo_name": "",
		"effects": []
	}
	
	if combo_sequence.size() < 2:
		print("连招序列至少需要2个武学")
		return result
	
	# 这里简化处理，实际项目中应该有复杂的连招逻辑
	var total_multiplier = 1.0
	var combo_name = ""
	
	for i in range(combo_sequence.size()):
		var martial_art_id = combo_sequence[i]
		if !player_martial_arts.has(martial_art_id):
			print("玩家未拥有武学: ", martial_art_id)
			return result
		
		var martial_art = player_martial_arts[martial_art_id]
		total_multiplier += 0.2  # 简化的连招加成
		if i > 0:
			combo_name += "+"
		combo_name += martial_art.name
	
	result.success = true
	result.damage_multiplier = total_multiplier
	result.combo_name = combo_name
	result.effects.append("连招效果：伤害+" + str(int((total_multiplier - 1) * 100)) + "%")
	
	emit_signal("martial_art_combo_executed", combo_name, total_multiplier)
	
	print("成功执行连招: ", combo_name, " 伤害倍率: ", total_multiplier)
	
	return result

# 计算武学伤害（考虑熟练度等因素）
func calculate_damage(martial_art_id: String, base_stats: Dictionary) -> float:
	if !player_martial_arts.has(martial_art_id):
		print("玩家未拥有该武学: ", martial_art_id)
		return 0.0
	
	var martial_art = player_martial_arts[martial_art_id]
	
	# 基础伤害
	var damage = martial_art.base_damage
	
	# 熟练度加成（每级2%）
	damage *= (1 + martial_art.proficiency_level * 0.02)
	
	# 属性加成
	if base_stats.has("strength"):
		damage += base_stats.strength * martial_art.damage_scale
	
	# 武器适配（简化处理）
	# 这里应该检查当前装备的武器类型与武学要求的匹配度
	
	# 随机浮动
	var random_variance = randf_range(0.95, 1.05)
	damage *= random_variance
	
	return damage

# 获取玩家武学列表
func get_player_martial_arts_list() -> Array:
	var list = []
	for martial_art_id in player_martial_arts:
		list.append(player_martial_arts[martial_art_id])
	return list

# 获取玩家武学残页统计
func get_player_fragments_summary() -> Dictionary:
	return player_fragments.duplicate()

# 检查武学是否可以装备（基于角色等级和武器适配）
func can_equip_martial_art(martial_art_id: String, player_level: int, current_weapon_type: String) -> bool:
	if !player_martial_arts.has(martial_art_id):
		return false
	
	var martial_art = player_martial_arts[martial_art_id]
	
	# 检查角色等级是否满足要求
	if player_level < martial_art.unlock_level:
		return false
	
	# 检查武器适配（简化处理）
	if current_weapon_type != martial_art.weapon_type and martial_art.weapon_type != "None":
		# 武器不匹配，但仍可装备但效果降低
		# 这里返回true，但实际使用时会有惩罚
		pass
	
	return true
