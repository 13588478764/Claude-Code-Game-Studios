# HitDetectionManager
# 管理命中检测逻辑的系统，实现命中率计算、随机判定、强制命中检查和结果反馈

extends Node

# 信号定义
signal hit_detected(attacker_id: String, target_id: String, hit_success: bool)
signal guaranteed_hit_detected(attacker_id: String, target_id: String)
signal miss_detected(attacker_id: String, target_id: String)

# 常量定义
const MIN_HIT_CHANCE = 0.05  # 最小命中率 5%
const MAX_HIT_CHANCE = 0.95  # 最大命中率 95%
const AGI_FACTOR = 0.005      # 身法系数

# 系统引用
var combat_system = null
var damage_calculation_system = null
var health_defense_system = null
var equipment_system = null
var character_progression_system = null

# 基础命中率
var base_hit_chance: float = 0.9  # 默认90%基础命中率

# 初始化
func _ready():
	# 初始化命中检测系统
	pass

# 计算命中率
func calculate_hit_chance(attacker, target) -> float:
	# 获取攻击方和防御方的身法属性
	var attacker_agi = get_character_agility(attacker)
	var defender_agi = get_character_agility(target)
	
	# 计算身法差值对命中率的影响
	var agi_difference = (attacker_agi - defender_agi) * AGI_FACTOR
	
	# 计算最终命中率
	var hit_chance = base_hit_chance + agi_difference
	
	# 应用状态修正（由其他系统提供）
	var status_modifier = get_status_modifier(attacker, target)
	hit_chance += status_modifier
	
	# 限制命中率在5%-95%范围内
	hit_chance = clamp(hit_chance, MIN_HIT_CHANCE, MAX_HIT_CHANCE)
	
	return hit_chance

# 检查是否强制命中
func is_guaranteed_hit(attacker, target, skill_data = null) -> bool:
	# 检查目标是否处于破防状态
	if is_target_broken(target):
		return true
	
	# 检查目标是否处于眩晕状态
	if is_target_stunned(target):
		return true
	
	# 检查目标是否处于冻结状态
	if is_target_frozen(target):
		return true
	
	# 检查技能是否包含Sure_Hit标签
	if skill_data and has_sure_hit_tag(skill_data):
		return true
	
	return false

# 执行命中判定
func perform_hit_check(attacker, target, skill_data = null) -> bool:
	# 检查是否强制命中
	if is_guaranteed_hit(attacker, target, skill_data):
		emit_signal("guaranteed_hit_detected", get_character_id(attacker), get_character_id(target))
		return true
	
	# 计算命中率
	var hit_chance = calculate_hit_chance(attacker, target)
	
	# 生成随机数进行判定
	var random_value = randf()
	var hit_success = random_value < hit_chance
	
	# 发射命中检测信号
	emit_signal("hit_detected", get_character_id(attacker), get_character_id(target), hit_success)
	
	if not hit_success:
		emit_signal("miss_detected", get_character_id(attacker), get_character_id(target))
	
	return hit_success

# 获取命中结果
func get_hit_result(attacker, target, skill_data = null) -> Dictionary:
	var is_hit = perform_hit_check(attacker, target, skill_data)
	var hit_chance = calculate_hit_chance(attacker, target)
	
	var result = {
		"hit_success": is_hit,
		"hit_chance": hit_chance,
		"is_guaranteed": is_guaranteed_hit(attacker, target, skill_data),
		"attacker_id": get_character_id(attacker),
		"target_id": get_character_id(target)
	}
	
	return result

# 获取角色身法属性
func get_character_agility(character) -> int:
	# 从角色成长系统获取身法属性
	if character.has_method("get_agility"):
		return character.get_agility()
	elif character.has_method("get_attribute"):
		return character.get_attribute("agility")
	else:
		# 默认身法值
		return 10

# 获取角色ID
func get_character_id(character) -> String:
	if character.has_method("get_id"):
		return character.get_id()
	elif character.has_method("get_name"):
		return character.get_name()
	else:
		return str(character)

# 获取状态修正
func get_status_modifier(attacker, target) -> float:
	var modifier = 0.0
	
	# 检查攻击方状态
	if has_status_effect(attacker, "Focus"):  # 专注状态
		modifier += 0.2  # +20%命中率
	elif has_status_effect(attacker, "Eagle_Eye"):  # 鹰眼状态
		modifier += 0.15  # +15%命中率
	
	# 检查防御方状态
	if has_status_effect(target, "Blind"):  # 失明状态
		modifier += 0.3  # +30%命中率（目标难以闪避）
	elif has_status_effect(target, "Slowed"):  # 迟缓状态
		modifier += 0.15  # +15%命中率（目标闪避率降低）
	
	return modifier

# 检查目标是否处于破防状态
func is_target_broken(target) -> bool:
	if target.has_method("is_in_break_state"):
		return target.is_in_break_state()
	return false

# 检查目标是否处于眩晕状态
func is_target_stunned(target) -> bool:
	if target.has_method("is_stunned"):
		return target.is_stunned()
	return false

# 检查目标是否处于冻结状态
func is_target_frozen(target) -> bool:
	if target.has_method("is_frozen"):
		return target.is_frozen()
	return false

# 检查技能是否包含Sure_Hit标签
func has_sure_hit_tag(skill_data) -> bool:
	if skill_data and skill_data.has("tags"):
		return "Sure_Hit" in skill_data["tags"]
	return false

# 检查角色是否有特定状态效果
func has_status_effect(character, status_name: String) -> bool:
	if character.has_method("has_status_effect"):
		return character.has_status_effect(status_name)
	return false

# 设置基础命中率
func set_base_hit_chance(chance: float):
	base_hit_chance = clamp(chance, MIN_HIT_CHANCE, MAX_HIT_CHANCE)

# 获取当前命中率参数
func get_hit_chance_parameters() -> Dictionary:
	return {
		"base_hit_chance": base_hit_chance,
		"agi_factor": AGI_FACTOR,
		"min_hit_chance": MIN_HIT_CHANCE,
		"max_hit_chance": MAX_HIT_CHANCE
	}