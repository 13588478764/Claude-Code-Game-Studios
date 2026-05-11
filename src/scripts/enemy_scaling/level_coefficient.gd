## LevelCoefficient
## level_coefficient.gd
## 三段式等级缩放曲线实现
## 实现初期线性(Lv 1-33)、中期温和指数(Lv 34-66)、后期陡峭指数(Lv 67-99)的敌人属性缩放
## TR-enemy-scaling-001
##
## 主要功能：
## - 待补充

extends Node

class_name LevelCoefficient

## 计算等级缩放系数
##
## 根据玩家等级返回对应的缩放系数,用于敌人属性计算
## 
## @param player_level: 玩家当前等级 (1-99)
## @return: 等级缩放系数 (1.0-29.8)
static func calculate_level_coefficient(player_level: int) -> float:
	# 参数验证
	if player_level < 1:
		push_warning("Invalid player level: %d. Clamping to 1." % player_level)
		player_level = 1
	elif player_level > 99:
		push_warning("Invalid player level: %d. Clamping to 99." % player_level)
		player_level = 99
	
	# 三段式缩放曲线
	var coefficient: float
	
	if player_level <= 33:
		# 初期线性段 (Lv 1-33)
		# level_coefficient = 1.0 + (level - 1) × 0.15
		coefficient = 1.0 + (player_level - 1) * 0.15
	elif player_level <= 66:
		# 中期温和指数段 (Lv 34-66)
		# level_coefficient = 5.8 × (level / 34)^1.2737
		# 注: 指数调整为 1.2737 以确保 Lv 66 = 13.5，满足 AC-5 要求
		coefficient = 5.8 * pow(float(player_level) / 34.0, 1.2737)
	else:
		# 后期陡峭指数段 (Lv 67-99)
		# level_coefficient = 13.5 × (level / 67)^2.0
		coefficient = 13.5 * pow(float(player_level) / 67.0, 2.0)
	
	return coefficient