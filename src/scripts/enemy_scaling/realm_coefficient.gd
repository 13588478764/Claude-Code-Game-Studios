## RealmCoefficient
## realm_coefficient.gd
## 境界对齐系统实现
## 实现9个境界等级,每个境界+10%全属性加成,与玩家境界一一对应
## TR-enemy-scaling-002
##
## 主要功能：
## - 待补充

extends Node

class_name RealmCoefficient

## 计算境界缩放系数
##
## 根据玩家等级返回对应的境界系数,用于敌人属性计算
## 9个境界等级,每个境界提供全属性+10%加成
##
## @param player_level: 玩家当前等级 (1-99)
## @return: 境界缩放系数 (1.1-1.9)
static func calculate_realm_coefficient(player_level: int) -> float:
	# 参数验证
	if player_level < 1:
		push_warning("Invalid player level: %d. Clamping to 1." % player_level)
		player_level = 1
	elif player_level > 99:
		push_warning("Invalid player level: %d. Clamping to 99." % player_level)
		player_level = 99
	
	# 9个境界等级映射 (每个境界11级)
	# 境界1 (Lv 1-11): 1.1x
	# 境界2 (Lv 12-22): 1.2x
	# 境界3 (Lv 23-33): 1.3x
	# 境界4 (Lv 34-44): 1.4x
	# 境界5 (Lv 45-55): 1.5x
	# 境界6 (Lv 56-66): 1.6x
	# 境界7 (Lv 67-77): 1.7x
	# 境界8 (Lv 78-88): 1.8x
	# 境界9 (Lv 89-99): 1.9x
	
	var realm_level: int = ((player_level - 1) / 11) + 1
	var coefficient: float = 1.0 + (realm_level * 0.1)
	
	return coefficient


## 获取玩家所在的境界等级
##
## @param player_level: 玩家当前等级 (1-99)
## @return: 境界等级 (1-9)
static func get_realm_level(player_level: int) -> int:
	if player_level < 1:
		return 1
	elif player_level > 99:
		return 9
	
	return ((player_level - 1) / 11) + 1


## 获取境界的等级范围
##
## @param realm_level: 境界等级 (1-9)
## @return: 包含 min_level 和 max_level 的字典
static func get_realm_level_range(realm_level: int) -> Dictionary:
	if realm_level < 1:
		realm_level = 1
	elif realm_level > 9:
		realm_level = 9
	
	var min_level: int = (realm_level - 1) * 11 + 1
	var max_level: int = realm_level * 11
	
	# 最后一个境界的最大等级是99
	if realm_level == 9:
		max_level = 99
	
	return {
		"min_level": min_level,
		"max_level": max_level
	}