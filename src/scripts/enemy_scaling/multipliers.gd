## Multipliers
## multipliers.gd
## 区域难度和敌人类型倍率系统
## 实现5个区域难度等级和3种敌人类型的倍率
## TR-enemy-scaling-003, TR-enemy-scaling-004
##
## 主要功能：
## - 待补充

extends Node

class_name EnemyMultipliers

# 区域难度枚举
enum RegionDifficulty {
	BEGINNER = 0,      # 新手区 0.8x
	NORMAL = 1,        # 普通区 1.0x
	HARD = 2,          # 困难区 1.3x
	ELITE = 3,         # 精英区 1.6x
	FINAL = 4          # 终局区 2.0x
}

# 敌人类型枚举
enum EnemyType {
	NORMAL = 0,        # 普通敌人 1.0x HP/攻击
	ELITE = 1,         # 精英敌人 2.0x HP/1.5x攻击
	BOSS = 2           # Boss 4.0x HP/2.0x攻击
}

## 获取区域难度倍率
##
## @param region_id: 区域ID (0-4)
## @return: 区域难度倍率 (0.8-2.0)
static func get_region_multiplier(region_id: int) -> float:
	match region_id:
		RegionDifficulty.BEGINNER:
			return 0.8
		RegionDifficulty.NORMAL:
			return 1.0
		RegionDifficulty.HARD:
			return 1.3
		RegionDifficulty.ELITE:
			return 1.6
		RegionDifficulty.FINAL:
			return 2.0
		_:
			push_warning("Invalid region ID: %d. Using NORMAL (1.0x)" % region_id)
			return 1.0


## 获取敌人类型倍率
##
## @param enemy_type: 敌人类型 (0-2)
## @return: 包含 hp_multiplier 和 attack_multiplier 的字典
static func get_enemy_type_multipliers(enemy_type: int) -> Dictionary:
	match enemy_type:
		EnemyType.NORMAL:
			return {
				"hp_multiplier": 1.0,
				"attack_multiplier": 1.0
			}
		EnemyType.ELITE:
			return {
				"hp_multiplier": 2.0,
				"attack_multiplier": 1.5
			}
		EnemyType.BOSS:
			return {
				"hp_multiplier": 4.0,
				"attack_multiplier": 2.0
			}
		_:
			push_warning("Invalid enemy type: %d. Using NORMAL (1.0x/1.0x)" % enemy_type)
			return {
				"hp_multiplier": 1.0,
				"attack_multiplier": 1.0
			}


## 获取区域难度名称
##
## @param region_id: 区域ID (0-4)
## @return: 区域难度名称
static func get_region_name(region_id: int) -> String:
	match region_id:
		RegionDifficulty.BEGINNER:
			return "新手区"
		RegionDifficulty.NORMAL:
			return "普通区"
		RegionDifficulty.HARD:
			return "困难区"
		RegionDifficulty.ELITE:
			return "精英区"
		RegionDifficulty.FINAL:
			return "终局区"
		_:
			return "未知区域"


## 获取敌人类型名称
##
## @param enemy_type: 敌人类型 (0-2)
## @return: 敌人类型名称
static func get_enemy_type_name(enemy_type: int) -> String:
	match enemy_type:
		EnemyType.NORMAL:
			return "普通敌人"
		EnemyType.ELITE:
			return "精英敌人"
		EnemyType.BOSS:
			return "Boss"
		_:
			return "未知类型"


## 计算最终敌人属性
##
## @param base_hp: 基础HP
## @param base_attack: 基础攻击力
## @param level_coefficient: 等级系数 (从 LevelCoefficient)
## @param realm_coefficient: 境界系数 (从 RealmCoefficient)
## @param region_id: 区域ID
## @param enemy_type: 敌人类型
## @return: 包含 final_hp 和 final_attack 的字典
static func calculate_final_stats(
	base_hp: float,
	base_attack: float,
	level_coefficient: float,
	realm_coefficient: float,
	region_id: int,
	enemy_type: int
) -> Dictionary:
	var region_multiplier = get_region_multiplier(region_id)
	var type_multipliers = get_enemy_type_multipliers(enemy_type)
	
	var final_hp = base_hp * level_coefficient * realm_coefficient * region_multiplier * type_multipliers["hp_multiplier"]
	var final_attack = base_attack * level_coefficient * realm_coefficient * region_multiplier * type_multipliers["attack_multiplier"]
	
	return {
		"final_hp": final_hp,
		"final_attack": final_attack
	}