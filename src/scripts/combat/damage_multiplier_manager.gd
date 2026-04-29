# DamageMultiplierManager - 伤害倍率与修正系统
#
# 负责计算所有伤害倍率和修正系数，包括暴击、连击、弱点和状态效果
# 遵循 GDD 中定义的乘法修正公式
#
# 信号:
#   - multiplier_applied(damage_type, multiplier_value, reason)

extends Node

class_name DamageMultiplierManager

# 暴击系数范围
const CRITICAL_MULTIPLIER_MIN: float = 1.5
const CRITICAL_MULTIPLIER_MAX: float = 2.0

# 连击系数
const COMBO_MULTIPLIER_PER_HIT: float = 0.05  # 每段 5%
const COMBO_MULTIPLIER_MAX: float = 0.30      # 最高 30%

# 弱点系数
const WEAKNESS_MULTIPLIER: float = 1.5

# 状态效果修正范围
const STATUS_MULTIPLIER_MIN: float = 1.2      # 最低 20% 加成
const STATUS_MULTIPLIER_MAX: float = 1.5      # 最高 50% 加成

# 信号定义
signal multiplier_applied(damage_type: String, multiplier_value: float, reason: String)

# ============================================================================
# 公共方法
# ============================================================================

## 计算暴击系数
## 参数:
##   - critical_chance: 暴击率 (0-100)
##   - critical_damage: 暴击伤害加成 (0-100)
## 返回: 暴击系数 (1.0 或 1.5-2.0)
func calculate_critical_multiplier(critical_chance: float, critical_damage: float) -> float:
	# 验证参数范围
	critical_chance = clamp(critical_chance, 0.0, 100.0)
	critical_damage = clamp(critical_damage, 0.0, 100.0)
	
	# 根据暴击率判断是否触发暴击
	var is_critical: bool = randf() * 100.0 < critical_chance
	
	if not is_critical:
		return 1.0
	
	# 计算暴击系数: 1.5 + (暴击伤害加成 / 100) * 0.5
	# 例如: 暴击伤害加成 100% -> 系数 2.0
	var critical_multiplier: float = CRITICAL_MULTIPLIER_MIN + (critical_damage / 100.0) * (CRITICAL_MULTIPLIER_MAX - CRITICAL_MULTIPLIER_MIN)
	
	return clamp(critical_multiplier, CRITICAL_MULTIPLIER_MIN, CRITICAL_MULTIPLIER_MAX)


## 计算连击系数
## 参数:
##   - combo_count: 当前连击数
## 返回: 连击系数 (1.0 + 连击加成)
func calculate_combo_multiplier(combo_count: int) -> float:
	# 连击数必须为正数
	combo_count = max(0, combo_count)
	
	# 计算连击加成: 每段 5%，最高 30%
	var combo_bonus: float = float(combo_count) * COMBO_MULTIPLIER_PER_HIT
	combo_bonus = clamp(combo_bonus, 0.0, COMBO_MULTIPLIER_MAX)
	
	return 1.0 + combo_bonus


## 计算弱点系数
## 参数:
##   - attack_element: 攻击属性 (金/木/水/火/土)
##   - target_weakness: 目标弱点属性
## 返回: 弱点系数 (1.0 或 1.5)
func calculate_weakness_multiplier(attack_element: String, target_weakness: String) -> float:
	# 如果没有弱点或属性不匹配，返回 1.0
	if target_weakness.is_empty() or attack_element.is_empty():
		return 1.0
	
	# 检查是否克制
	if _is_element_advantage(attack_element, target_weakness):
		return WEAKNESS_MULTIPLIER
	
	return 1.0


## 计算状态效果修正
## 参数:
##   - status_effects: 状态效果数组 (如 ["易伤", "破防"])
## 返回: 状态修正系数 (1.0 或 1.2-1.5)
func calculate_status_multiplier(status_effects: Array) -> float:
	if status_effects.is_empty():
		return 1.0
	
	# 计算状态修正: 每个状态效果增加相应百分比，最高 50%
	var status_bonus: float = 0.0
	
	for effect in status_effects:
		match effect:
			"易伤":
				status_bonus += 0.20  # 易伤: 20% 加成
			"破防":
				status_bonus += 0.15  # 破防: 15% 加成
			"虚弱":
				status_bonus += 0.10  # 虚弱: 10% 加成
			_:
				status_bonus += 0.10  # 其他状态: 10% 加成
	
	# 限制最高 50% 加成
	status_bonus = clamp(status_bonus, 0.0, 0.50)
	
	return 1.0 + status_bonus


## 应用所有修正系数到伤害值
## 参数:
##   - base_damage: 基础伤害值
##   - critical_chance: 暴击率
##   - critical_damage: 暴击伤害加成
##   - combo_count: 连击数
##   - attack_element: 攻击属性
##   - target_weakness: 目标弱点
##   - status_effects: 状态效果数组
## 返回: 应用所有修正后的伤害值
func apply_all_multipliers(
	base_damage: int,
	critical_chance: float,
	critical_damage: float,
	combo_count: int,
	attack_element: String,
	target_weakness: String,
	status_effects: Array
) -> int:
	
	var final_damage: float = float(base_damage)
	
	# 应用暴击系数
	var critical_multiplier: float = calculate_critical_multiplier(critical_chance, critical_damage)
	final_damage *= critical_multiplier
	
	# 应用连击系数
	var combo_multiplier: float = calculate_combo_multiplier(combo_count)
	final_damage *= combo_multiplier
	
	# 应用弱点系数
	var weakness_multiplier: float = calculate_weakness_multiplier(attack_element, target_weakness)
	final_damage *= weakness_multiplier
	
	# 应用状态效果修正
	var status_multiplier: float = calculate_status_multiplier(status_effects)
	final_damage *= status_multiplier
	
	# 四舍五入到整数
	return int(round(final_damage))


# ============================================================================
# 私有方法
# ============================================================================

## 检查属性克制关系
## 参数:
##   - attack_element: 攻击属性
##   - target_weakness: 目标弱点属性
## 返回: 是否存在克制关系
func _is_element_advantage(attack_element: String, target_weakness: String) -> bool:
	# 五行相克关系: 金克木, 木克土, 土克水, 水克火, 火克金
	var advantage_map: Dictionary = {
		"金": ["木"],
		"木": ["土"],
		"土": ["水"],
		"水": ["火"],
		"火": ["金"]
	}
	
	if attack_element in advantage_map:
		return target_weakness in advantage_map[attack_element]
	
	return false