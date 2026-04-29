## EnemyGenerator
## enemy_generator.gd
敌人实例生成集成系统
集成所有缩放系统,生成最终敌人实例
TR-enemy-scaling-001 to TR-enemy-scaling-006
##
## 主要功能：
## - 待补充

extends Node

class_name EnemyGenerator

# 导入所有缩放系统
const LevelCoefficient = preload("res://scripts/enemy_scaling/level_coefficient.gd")
const RealmCoefficient = preload("res://scripts/enemy_scaling/realm_coefficient.gd")
const EnemyMultipliers = preload("res://scripts/enemy_scaling/multipliers.gd")
const DynamicDifficulty = preload("res://scripts/enemy_scaling/dynamic_difficulty.gd")
const EdgeCaseHandler = preload("res://scripts/enemy_scaling/edge_cases.gd")
const EnemyScalingConfigLoader = preload("res://scripts/enemy_scaling/config_loader.gd")

# 配置加载器实例
var config_loader: EnemyScalingConfigLoader

func _init():
	config_loader = EnemyScalingConfigLoader.new()
	config_loader.load_config()

## 生成敌人实例
##
## 完整缩放公式: 最终属性 = 基础属性 × 等级系数 × 境界系数 × 区域倍率 × 类型倍率 × 动态调整系数
##
## @param enemy_base_data: 敌人基础数据 (包含 base_hp, base_attack 等)
## @param player_level: 玩家等级
## @param region_id: 区域ID
## @param enemy_type: 敌人类型
## @param failure_count: 连续失败次数 (可选)
## @param perfect_win_count: 连续无伤胜利次数 (可选)
## @param is_battle_active: 是否在战斗中 (可选)
## @return: 包含最终属性的字典
func generate_enemy_instance(
	enemy_base_data: Dictionary,
	player_level: int,
	region_id: int,
	enemy_type: int,
	failure_count: int = 0,
	perfect_win_count: int = 0,
	is_battle_active: bool = false
) -> Dictionary:
	
	# 1. 验证基础数据
	var validated_data = EdgeCaseHandler.validate_all_enemy_data(
		enemy_base_data.get("base_hp", 100),
		enemy_base_data.get("base_attack", 20),
		EnemyMultipliers.get_region_multiplier(region_id)
	)
	
	var base_hp = validated_data["validated_hp"]
	var base_attack = validated_data["validated_attack"]
	
	# 2. 计算等级系数
	var level_coefficient = LevelCoefficient.calculate_level_coefficient(player_level)
	
	# 3. 计算境界系数
	var realm_coefficient = RealmCoefficient.calculate_realm_coefficient(player_level)
	
	# 4. 获取区域倍率
	var region_multiplier = EnemyMultipliers.get_region_multiplier(region_id)
	
	# 5. 检查等级差距并调整区域倍率
	var region_range = EdgeCaseHandler.get_region_recommended_level_range(region_id)
	var level_check = EdgeCaseHandler.check_level_difference(
		player_level,
		region_range["min_level"],
		region_range["max_level"],
		region_multiplier
	)
	region_multiplier = level_check["adjusted_multiplier"]
	var warning_type = level_check["warning_type"]
	
	# 6. 获取敌人类型倍率
	var type_multipliers = EnemyMultipliers.get_enemy_type_multipliers(enemy_type)
	
	# 7. 计算动态难度系数
	var dynamic_coefficient = DynamicDifficulty.calculate_dynamic_coefficient(
		failure_count,
		perfect_win_count
	)
	
	# 8. 计算最终属性
	var final_hp = base_hp * level_coefficient * realm_coefficient * region_multiplier * type_multipliers["hp_multiplier"] * dynamic_coefficient
	var final_attack = base_attack * level_coefficient * realm_coefficient * region_multiplier * type_multipliers["attack_multiplier"] * dynamic_coefficient
	
	# 9. 构建敌人实例数据
	var enemy_instance = {
		"base_hp": base_hp,
		"base_attack": base_attack,
		"final_hp": final_hp,
		"final_attack": final_attack,
		"player_level": player_level,
		"region_id": region_id,
		"enemy_type": enemy_type,
		"level_coefficient": level_coefficient,
		"realm_coefficient": realm_coefficient,
		"region_multiplier": region_multiplier,
		"type_hp_multiplier": type_multipliers["hp_multiplier"],
		"type_attack_multiplier": type_multipliers["attack_multiplier"],
		"dynamic_coefficient": dynamic_coefficient,
		"warning_type": warning_type,
		"warning_message": EdgeCaseHandler.get_warning_message(warning_type),
		"has_data_error": validated_data["has_error"]
	}
	
	return enemy_instance

## 生成多个敌人实例
##
## @param enemy_base_data: 敌人基础数据
## @param player_level: 玩家等级
## @param region_id: 区域ID
## @param enemy_type: 敌人类型
## @param count: 生成数量
## @return: 敌人实例数组
func generate_enemy_group(
	enemy_base_data: Dictionary,
	player_level: int,
	region_id: int,
	enemy_type: int,
	count: int = 1
) -> Array:
	var enemies = []
	for i in range(count):
		var enemy = generate_enemy_instance(
			enemy_base_data,
			player_level,
			region_id,
			enemy_type
		)
		enemies.append(enemy)
	return enemies

## 获取敌人生成摘要
##
## @param enemy_instance: 敌人实例
## @return: 摘要字符串
func get_enemy_summary(enemy_instance: Dictionary) -> String:
	var region_name = EnemyMultipliers.get_region_name(enemy_instance["region_id"])
	var enemy_type_name = EnemyMultipliers.get_enemy_type_name(enemy_instance["enemy_type"])
	
	var summary = "敌人生成摘要:\n"
	summary += "  区域: %s\n" % region_name
	summary += "  类型: %s\n" % enemy_type_name
	summary += "  玩家等级: %d\n" % enemy_instance["player_level"]
	summary += "  基础HP: %.0f → 最终HP: %.0f\n" % [enemy_instance["base_hp"], enemy_instance["final_hp"]]
	summary += "  基础攻击: %.0f → 最终攻击: %.0f\n" % [enemy_instance["base_attack"], enemy_instance["final_attack"]]
	summary += "  等级系数: %.4f\n" % enemy_instance["level_coefficient"]
	summary += "  境界系数: %.2f\n" % enemy_instance["realm_coefficient"]
	summary += "  区域倍率: %.2f\n" % enemy_instance["region_multiplier"]
	summary += "  动态系数: %.2f\n" % enemy_instance["dynamic_coefficient"]
	
	if enemy_instance["warning_type"] != EdgeCaseHandler.WarningType.NONE:
		summary += "  警告: %s\n" % enemy_instance["warning_message"]
	
	if enemy_instance["has_data_error"]:
		summary += "  [数据异常已处理]\n"
	
	return summary