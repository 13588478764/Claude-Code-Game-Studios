## config_loader_test.gd
## 配置加载器单元测试
##
## 测试 TR-enemy-scaling-007

extends GutTest

const EnemyScalingConfigLoader = preload("res://scripts/enemy_scaling/config_loader.gd")

var config_loader: EnemyScalingConfigLoader

func before_each():
	config_loader = EnemyScalingConfigLoader.new()

## AC-15: 配置文件修改生效
func test_linear_coefficient_from_config():
	# Given: 加载配置文件
	var success = config_loader.load_config()
	assert_true(success, "Config should load successfully")
	
	# When: 获取线性系数
	var linear_coefficient = config_loader.get_linear_coefficient()
	
	# Then: 应该是0.15 (或修改后的值)
	assert_almost_eq(linear_coefficient, 0.15, 0.01, "Linear coefficient should be 0.15")

## 验证配置文件加载
func test_config_file_loads():
	var success = config_loader.load_config()
	assert_true(success, "Config file should load successfully")
	assert_true(config_loader.is_loaded(), "Config should be marked as loaded")

## 验证等级缩放配置
func test_level_scaling_config():
	config_loader.load_config()
	var level_scaling = config_loader.get_level_scaling_config()
	
	assert_true(level_scaling.has("early_stage"), "Should have early_stage config")
	assert_true(level_scaling.has("mid_stage"), "Should have mid_stage config")
	assert_true(level_scaling.has("late_stage"), "Should have late_stage config")

## 验证初期线性段配置
func test_early_stage_config():
	config_loader.load_config()
	var early_stage = config_loader.get_early_stage_config()
	
	assert_eq(early_stage.get("min_level"), 1)
	assert_eq(early_stage.get("max_level"), 33)
	assert_almost_eq(early_stage.get("base_coefficient"), 1.0, 0.01)
	assert_almost_eq(early_stage.get("linear_coefficient"), 0.15, 0.01)

## 验证中期温和指数段配置
func test_mid_stage_config():
	config_loader.load_config()
	var mid_stage = config_loader.get_mid_stage_config()
	
	assert_eq(mid_stage.get("min_level"), 34)
	assert_eq(mid_stage.get("max_level"), 66)
	assert_almost_eq(mid_stage.get("base_coefficient"), 5.8, 0.01)
	assert_almost_eq(mid_stage.get("exponent"), 1.2737, 0.01)

## 验证后期陡峭指数段配置
func test_late_stage_config():
	config_loader.load_config()
	var late_stage = config_loader.get_late_stage_config()
	
	assert_eq(late_stage.get("min_level"), 67)
	assert_eq(late_stage.get("max_level"), 99)
	assert_almost_eq(late_stage.get("base_coefficient"), 13.5, 0.01)
	assert_almost_eq(late_stage.get("exponent"), 2.0, 0.01)

## 验证境界缩放配置
func test_realm_scaling_config():
	config_loader.load_config()
	var realm_scaling = config_loader.get_realm_scaling_config()
	
	assert_eq(realm_scaling.get("realm_count"), 9)
	assert_almost_eq(realm_scaling.get("base_coefficient"), 1.0, 0.01)
	assert_almost_eq(realm_scaling.get("per_realm_bonus"), 0.1, 0.01)

## 验证区域倍率配置
func test_region_multipliers_config():
	config_loader.load_config()
	var regions = config_loader.get_region_multipliers_config()
	
	assert_true(regions.has("beginner"), "Should have beginner region")
	assert_true(regions.has("normal"), "Should have normal region")
	assert_true(regions.has("hard"), "Should have hard region")
	assert_true(regions.has("elite"), "Should have elite region")
	assert_true(regions.has("final"), "Should have final region")
	
	assert_almost_eq(regions["beginner"]["multiplier"], 0.8, 0.01)
	assert_almost_eq(regions["normal"]["multiplier"], 1.0, 0.01)
	assert_almost_eq(regions["hard"]["multiplier"], 1.3, 0.01)
	assert_almost_eq(regions["elite"]["multiplier"], 1.6, 0.01)
	assert_almost_eq(regions["final"]["multiplier"], 2.0, 0.01)

## 验证敌人类型倍率配置
func test_enemy_type_multipliers_config():
	config_loader.load_config()
	var types = config_loader.get_enemy_type_multipliers_config()
	
	assert_true(types.has("normal"), "Should have normal enemy type")
	assert_true(types.has("elite"), "Should have elite enemy type")
	assert_true(types.has("boss"), "Should have boss enemy type")
	
	assert_almost_eq(types["normal"]["hp_multiplier"], 1.0, 0.01)
	assert_almost_eq(types["elite"]["hp_multiplier"], 2.0, 0.01)
	assert_almost_eq(types["boss"]["hp_multiplier"], 4.0, 0.01)

## 验证动态难度配置
func test_dynamic_difficulty_config():
	config_loader.load_config()
	var dynamic = config_loader.get_dynamic_difficulty_config()
	
	assert_true(dynamic.has("failure_penalty"), "Should have failure_penalty config")
	assert_true(dynamic.has("perfect_win_bonus"), "Should have perfect_win_bonus config")
	
	var failure = dynamic["failure_penalty"]
	assert_almost_eq(failure["per_failure_reduction"], 0.1, 0.01)
	assert_almost_eq(failure["min_coefficient"], 0.7, 0.01)

## 验证边缘情况配置
func test_edge_cases_config():
	config_loader.load_config()
	var edge_cases = config_loader.get_edge_cases_config()
	
	assert_eq(edge_cases.get("level_difference_threshold"), 20)
	assert_almost_eq(edge_cases.get("too_easy_multiplier"), 0.5, 0.01)
	assert_eq(edge_cases.get("default_base_hp"), 100)
	assert_eq(edge_cases.get("default_base_attack"), 20)

## 验证参数验证范围
func test_validation_config():
	config_loader.load_config()
	var validation = config_loader.get_validation_config()
	
	assert_true(validation.has("level_range"), "Should have level_range")
	assert_true(validation.has("coefficient_range"), "Should have coefficient_range")
	assert_true(validation.has("multiplier_range"), "Should have multiplier_range")

## 验证参数验证函数
func test_validate_parameter():
	config_loader.load_config()
	
	# 有效值
	assert_true(config_loader.validate_parameter(0.5, 0.1, 1.0))
	assert_true(config_loader.validate_parameter(0.1, 0.1, 1.0))
	assert_true(config_loader.validate_parameter(1.0, 0.1, 1.0))
	
	# 无效值
	assert_false(config_loader.validate_parameter(0.05, 0.1, 1.0))
	assert_false(config_loader.validate_parameter(1.5, 0.1, 1.0))

## 验证配置重新加载
func test_reload_config():
	var success1 = config_loader.load_config()
	assert_true(success1)
	
	var success2 = config_loader.reload_config()
	assert_true(success2)
	assert_true(config_loader.is_loaded())

## 验证获取完整配置
func test_get_full_config():
	config_loader.load_config()
	var full_config = config_loader.get_full_config()
	
	assert_true(full_config.has("level_scaling"))
	assert_true(full_config.has("realm_scaling"))
	assert_true(full_config.has("region_multipliers"))
	assert_true(full_config.has("enemy_type_multipliers"))
	assert_true(full_config.has("dynamic_difficulty"))
	assert_true(full_config.has("edge_cases"))
	assert_true(full_config.has("validation"))

## 验证配置版本
func test_config_version():
	config_loader.load_config()
	var full_config = config_loader.get_full_config()
	
	assert_eq(full_config.get("version"), "1.0")

## 验证配置描述
func test_config_description():
	config_loader.load_config()
	var full_config = config_loader.get_full_config()
	
	assert_true(full_config.has("description"))
	assert_true("敌人缩放系统" in full_config.get("description", ""))

## 验证配置最后更新时间
func test_config_last_updated():
	config_loader.load_config()
	var full_config = config_loader.get_full_config()
	
	assert_true(full_config.has("last_updated"))
	assert_eq(full_config.get("last_updated"), "2026-04-28")