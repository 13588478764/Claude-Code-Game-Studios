## ExpCalculationManager
## 经验值计算与分配管理器
##
## 实现EXP计算公式、等级缩放修正、队伍分配和升级曲线。
## 提供完整的经验值计算流程和队伍分配机制。
##
## 主要功能：
## - 基础经验值计算
## - 等级缩放修正
## - 悟性属性加成
## - 全局倍率应用
## - 队伍经验值分配
## - 升级曲线计算

extends Node
class_name ExpCalculationManager

# ============================================================================
# 常量定义
# ============================================================================

const EXP_CURVE_EARLY = 1.0    # 初期线性增长
const EXP_CURVE_MID = 1.5      # 中期温和指数增长
const EXP_CURVE_LATE = 2.5     # 后期陡峭指数增长
REPLACE

# 基础经验值公式
# Base_EXP = Enemy_Base_Value × (Enemy_Level / Player_Level)^Scaling_Factor
func calculate_base_exp(enemy_base_value: int, enemy_level: int, player_level: int, scaling_factor: float = 1.5) -> float:
	if player_level <= 0:
		player_level = 1  # 避免除以零
	
	var base_exp = enemy_base_value * pow(float(enemy_level) / float(player_level), scaling_factor)
	return base_exp

# 等级缩放修正公式
# 最高等级敌人+50%加成，最低等级敌人-80%惩罚
func apply_level_scaling(base_exp: float, enemy_level: int, player_level: int) -> float:
	var level_difference = enemy_level - player_level
	var level_bonus = 1.0  # 基础倍率
	
	if level_difference > 0:
		# 敌人等级更高，获得加成（最高+50%）
		var bonus_percentage = min(0.5, float(level_difference) * 0.05)  # 每级5%加成，最高50%
		level_bonus = 1.0 + bonus_percentage
	elif level_difference < 0:
		# 敌人等级更低，受到惩罚（最低-80%）
		var penalty_percentage = min(0.8, float(abs(level_difference)) * 0.1)  # 每级10%惩罚，最高80%
		level_bonus = 1.0 - penalty_percentage
	
	# 如果等级差过大（>10级），不获得EXP
	if abs(level_difference) > 10:
		level_bonus = 0.0
	
	return base_exp * level_bonus

# 悟性修正系数（每10点悟性+1%EXP）
func apply_wisdom_bonus(exp: float, wisdom_attribute: int) -> float:
	var wisdom_bonus = 1.0 + (float(wisdom_attribute) / 1000.0)  # 每10点悟性增加1%
	return exp * wisdom_bonus

# 全局倍率（双倍经验活动等）
func apply_global_multiplier(exp: float, multiplier: float = 1.0) -> float:
	return exp * multiplier

# 队伍EXP分配公式
# 总池分配：所有参与战斗的角色平分总EXP
# 后备队员：未参战但在队伍中的角色获得50%的平分份额
func distribute_party_exp(total_exp: float, party_members: Array) -> Dictionary:
	var distribution = {}
	var active_members = []
	var backup_members = []
	
	# 分离参战和后备成员
	for member in party_members:
		if member.get("is_active", true):  # 默认为参战
			active_members.append(member)
		else:
			backup_members.append(member)
	
	# 计算参战成员的EXP
	var active_exp_per_member = 0.0
	if active_members.size() > 0:
		active_exp_per_member = total_exp / active_members.size()
	
	# 分配参战成员EXP
	for member in active_members:
		var member_id = member.get("id", "unknown")
		distribution[member_id] = active_exp_per_member
	
	# 分配后备成员EXP（50%份额）
	var backup_exp_per_member = 0.0
	if active_members.size() > 0:
		backup_exp_per_member = active_exp_per_member * 0.5
	
	for member in backup_members:
		var member_id = member.get("id", "unknown")
		distribution[member_id] = backup_exp_per_member
	
	return distribution

# 计算升级所需EXP
# 升级所需EXP = 基础值 × 等级^指数系数
func calculate_level_curve(current_level: int, base_value: int = 100, exponent_coefficient: float = 1.0) -> int:
	var exp_to_level = int(base_value * pow(current_level, exponent_coefficient))
	return exp_to_level

# 根据等级阶段返回不同的指数系数
func get_exponent_coefficient_for_level(level: int) -> float:
	if level <= 10:
		# 初期线性增长
		return EXP_CURVE_EARLY
	elif level <= 30:
		# 中期温和指数增长
		return EXP_CURVE_MID
	else:
		# 后期陡峭指数增长
		return EXP_CURVE_LATE

# 计算特定等级的总经验需求（从1级到目标等级的累计经验）
func calculate_total_exp_for_level(target_level: int, base_value: int = 100) -> int:
	var total_exp = 0
	for level in range(2, target_level + 1):  # 从2级开始计算到目标等级
		var exp_for_level = calculate_level_curve(level - 1, base_value, get_exponent_coefficient_for_level(level - 1))
		total_exp += exp_for_level
	return total_exp

# 计算从当前等级到目标等级所需的经验
func calculate_exp_to_next_level(current_level: int, base_value: int = 100) -> int:
	var exponent_coefficient = get_exponent_coefficient_for_level(current_level)
	return calculate_level_curve(current_level, base_value, exponent_coefficient)

# 完整的EXP计算流程
func calculate_full_exp(enemy_data: Dictionary, player_level: int, wisdom_attribute: int, party_members: Array, global_multiplier: float = 1.0) -> Dictionary:
	# 1. 计算基础EXP
	var base_exp = calculate_base_exp(
		enemy_data.get("base_value", 50),
		enemy_data.get("level", 1),
		player_level,
		enemy_data.get("scaling_factor", 1.5)
	)
	
	# 2. 应用等级缩放修正
	var level_scaled_exp = apply_level_scaling(base_exp, enemy_data.get("level", 1), player_level)
	
	# 3. 应用悟性修正
	var wisdom_scaled_exp = apply_wisdom_bonus(level_scaled_exp, wisdom_attribute)
	
	# 4. 应用全局倍率
	var final_exp = apply_global_multiplier(wisdom_scaled_exp, global_multiplier)
	
	# 5. 分配给队伍成员
	var party_distribution = distribute_party_exp(final_exp, party_members)
	
	return {
		"base_exp": base_exp,
		"level_scaled_exp": level_scaled_exp,
		"wisdom_scaled_exp": wisdom_scaled_exp,
		"final_exp": final_exp,
		"party_distribution": party_distribution
	}

# 获取当前等级到下一级所需的经验
func get_exp_to_next_level(current_level: int, base_value: int = 100) -> int:
	return calculate_exp_to_next_level(current_level, base_value)