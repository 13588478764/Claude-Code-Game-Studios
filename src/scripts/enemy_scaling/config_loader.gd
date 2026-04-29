## ConfigLoader
## config_loader.gd
敌人缩放系统配置加载器
从JSON配置文件加载所有缩放参数
TR-enemy-scaling-007
##
## 主要功能：
## - 待补充

extends Node

class_name ConfigLoader

# ============================================================================
# 常量定义
# ============================================================================

# ============================================================================
# 信号定义
# ============================================================================

# ============================================================================
# 成员变量
# ============================================================================

# ============================================================================
# 生命周期方法
# ============================================================================

# ============================================================================
# 公共方法
# ============================================================================

# ============================================================================
# 私有方法
# ============================================================================

class_name EnemyScalingConfigLoader

# 配置文件路径
const CONFIG_PATH = "res://data/enemy_scaling_config.json"

# 缓存的配置数据
var _config_data: Dictionary = {}
var _is_loaded: bool = false

## 加载配置文件
##
## @return: 是否加载成功
func load_config() -> bool:
	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open config file: %s" % CONFIG_PATH)
		return false
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("Failed to parse config file: %s" % CONFIG_PATH)
		return false
	
	_config_data = json.data
	_is_loaded = true
	return true

## 获取等级缩放配置
##
## @return: 等级缩放配置字典
func get_level_scaling_config() -> Dictionary:
	if not _is_loaded:
		load_config()
	
	return _config_data.get("level_scaling", {})

## 获取初期线性段配置
func get_early_stage_config() -> Dictionary:
	var level_scaling = get_level_scaling_config()
	return level_scaling.get("early_stage", {})

## 获取中期温和指数段配置
func get_mid_stage_config() -> Dictionary:
	var level_scaling = get_level_scaling_config()
	return level_scaling.get("mid_stage", {})

## 获取后期陡峭指数段配置
func get_late_stage_config() -> Dictionary:
	var level_scaling = get_level_scaling_config()
	return level_scaling.get("late_stage", {})

## 获取线性系数 (用于AC-15测试)
##
## @return: 线性系数值
func get_linear_coefficient() -> float:
	var early_stage = get_early_stage_config()
	return early_stage.get("linear_coefficient", 0.15)

## 获取境界缩放配置
func get_realm_scaling_config() -> Dictionary:
	if not _is_loaded:
		load_config()
	
	return _config_data.get("realm_scaling", {})

## 获取区域倍率配置
func get_region_multipliers_config() -> Dictionary:
	if not _is_loaded:
		load_config()
	
	return _config_data.get("region_multipliers", {})

## 获取敌人类型倍率配置
func get_enemy_type_multipliers_config() -> Dictionary:
	if not _is_loaded:
		load_config()
	
	return _config_data.get("enemy_type_multipliers", {})

## 获取动态难度配置
func get_dynamic_difficulty_config() -> Dictionary:
	if not _is_loaded:
		load_config()
	
	return _config_data.get("dynamic_difficulty", {})

## 获取边缘情况配置
func get_edge_cases_config() -> Dictionary:
	if not _is_loaded:
		load_config()
	
	return _config_data.get("edge_cases", {})

## 获取验证范围配置
func get_validation_config() -> Dictionary:
	if not _is_loaded:
		load_config()
	
	return _config_data.get("validation", {})

## 验证配置参数
##
## @param value: 要验证的值
## @param min_val: 最小值
## @param max_val: 最大值
## @return: 是否在有效范围内
func validate_parameter(value: float, min_val: float, max_val: float) -> bool:
	return value >= min_val and value <= max_val

## 重新加载配置文件
##
## @return: 是否重新加载成功
func reload_config() -> bool:
	_config_data = {}
	_is_loaded = false
	return load_config()

## 获取完整配置数据
##
## @return: 完整的配置字典
func get_full_config() -> Dictionary:
	if not _is_loaded:
		load_config()
	
	return _config_data.duplicate(true)

## 检查配置是否已加载
##
## @return: 是否已加载
func is_loaded() -> bool:
	return _is_loaded