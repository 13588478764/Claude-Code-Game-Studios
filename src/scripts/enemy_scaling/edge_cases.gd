## EdgeCases
## edge_cases.gd
## 边缘情况处理系统
## 处理等级差距保护、战斗中升级、数据异常等边缘情况
## TR-enemy-scaling-006
##
## 主要功能：
## - 待补充

extends Node

class_name EdgeCaseHandler

# 等级差距阈值
const LEVEL_DIFFERENCE_THRESHOLD = 20

# 默认值
const DEFAULT_BASE_HP = 100
const DEFAULT_BASE_ATTACK = 20

# UI 提示类型
enum WarningType {
	NONE = 0,
	TOO_EASY = 1,
	TOO_HARD = 2,
	DATA_ERROR = 3
}

## 检查等级差距并返回调整后的倍率
static func check_level_difference(
	player_level: int,
	region_min_level: int,
	region_max_level: int,
	original_region_multiplier: float
) -> Dictionary:
	var adjusted_multiplier = original_region_multiplier
	var warning_type = WarningType.NONE
	
	if player_level > region_max_level + LEVEL_DIFFERENCE_THRESHOLD:
		adjusted_multiplier = 0.5
		warning_type = WarningType.TOO_EASY
	elif player_level < region_min_level - LEVEL_DIFFERENCE_THRESHOLD:
		adjusted_multiplier = original_region_multiplier
		warning_type = WarningType.TOO_HARD
	
	return {
		"adjusted_multiplier": adjusted_multiplier,
		"warning_type": warning_type
	}

## 获取警告信息
static func get_warning_message(warning_type: int) -> String:
	match warning_type:
		WarningType.TOO_EASY:
			return "此区域对你来说过于简单"
		WarningType.TOO_HARD:
			return "此区域对你来说过于困难,敌人将按推荐等级缩放"
		WarningType.DATA_ERROR:
			return "检测到数据异常,已使用默认值"
		_:
			return ""

## 处理战斗中升级
static func should_update_enemy_stats_on_level_up(
	is_battle_active: bool,
	player_level_before: int,
	player_level_after: int
) -> bool:
	if is_battle_active:
		return false
	return player_level_after != player_level_before

## 处理数据异常 - 基础HP
static func validate_base_hp(base_hp: float) -> Dictionary:
	if base_hp <= 0:
		push_warning("Invalid base HP: %f. Using default value: %d" % [base_hp, DEFAULT_BASE_HP])
		return {
			"validated_hp": DEFAULT_BASE_HP,
			"has_error": true
		}
	return {
		"validated_hp": base_hp,
		"has_error": false
	}

## 处理数据异常 - 基础攻击
static func validate_base_attack(base_attack: float) -> Dictionary:
	if base_attack <= 0:
		push_warning("Invalid base attack: %f. Using default value: %d" % [base_attack, DEFAULT_BASE_ATTACK])
		return {
			"validated_attack": DEFAULT_BASE_ATTACK,
			"has_error": true
		}
	return {
		"validated_attack": base_attack,
		"has_error": false
	}

## 处理数据异常 - 区域倍率
static func validate_region_multiplier(region_multiplier: float) -> Dictionary:
	if region_multiplier <= 0:
		push_warning("Invalid region multiplier: %f. Using default value: 1.0" % region_multiplier)
		return {
			"validated_multiplier": 1.0,
			"has_error": true
		}
	return {
		"validated_multiplier": region_multiplier,
		"has_error": false
	}

## 综合验证所有敌人属性数据
static func validate_all_enemy_data(
	base_hp: float,
	base_attack: float,
	region_multiplier: float
) -> Dictionary:
	var hp_result = validate_base_hp(base_hp)
	var attack_result = validate_base_attack(base_attack)
	var multiplier_result = validate_region_multiplier(region_multiplier)
	
	var has_any_error = hp_result["has_error"] or attack_result["has_error"] or multiplier_result["has_error"]
	
	return {
		"validated_hp": hp_result["validated_hp"],
		"validated_attack": attack_result["validated_attack"],
		"validated_multiplier": multiplier_result["validated_multiplier"],
		"has_error": has_any_error,
		"warning_type": WarningType.DATA_ERROR if has_any_error else WarningType.NONE
	}

## 获取推荐等级范围
static func get_region_recommended_level_range(region_id: int) -> Dictionary:
	match region_id:
		0:
			return {"min_level": 1, "max_level": 20}
		1:
			return {"min_level": 15, "max_level": 35}
		2:
			return {"min_level": 30, "max_level": 50}
		3:
			return {"min_level": 45, "max_level": 65}
		4:
			return {"min_level": 60, "max_level": 99}
		_:
			return {"min_level": 1, "max_level": 99}
