## debug_visualizer.gd
## 调试可视化工具
##
## 实现开发模式下的缩放参数显示和难度曲线图表
## TR-enemy-scaling-008

extends Control
class_name EnemyScalingDebugVisualizer

# 导入所有缩放系统
const LevelCoefficient = preload("res://scripts/enemy_scaling/level_coefficient.gd")
const RealmCoefficient = preload("res://scripts/enemy_scaling/realm_coefficient.gd")
const EnemyMultipliers = preload("res://scripts/enemy_scaling/multipliers.gd")
const DynamicDifficulty = preload("res://scripts/enemy_scaling/dynamic_difficulty.gd")
const EnemyGenerator = preload("res://scripts/enemy_scaling/enemy_generator.gd")

# UI 组件
var _scaling_panel: PanelContainer
var _scaling_label: Label
var _attribute_panel: PanelContainer
var _attribute_label: Label
var _curve_panel: PanelContainer
var _curve_line: Line2D

# 数据
var _current_player_level: int = 1
var _current_region_id: int = 0
var _current_enemy_type: int = 0
var _failure_count: int = 0
var _perfect_win_count: int = 0

var enemy_generator: EnemyGenerator

func _ready():
	# 仅在开发模式启用
	if not OS.is_debug_build():
		queue_free()
		return
	
	enemy_generator = EnemyGenerator.new()
	
	# 创建 UI
	_create_ui()
	_update_all_panels()

## 创建调试 UI
func _create_ui():
	# 设置容器
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# 创建缩放系数面板
	_scaling_panel = PanelContainer.new()
	_scaling_panel.anchor_left = 0.0
	_scaling_panel.anchor_top = 0.0
	_scaling_panel.anchor_right = 0.3
	_scaling_panel.anchor_bottom = 0.4
	_scaling_panel.offset_left = 10
	_scaling_panel.offset_top = 10
	_scaling_panel.offset_right = -10
	_scaling_panel.offset_bottom = -10
	add_child(_scaling_panel)
	
	_scaling_label = Label.new()
	_scaling_label.text = "缩放系数面板"
	_scaling_panel.add_child(_scaling_label)
	
	# 创建属性对比面板
	_attribute_panel = PanelContainer.new()
	_attribute_panel.anchor_left = 0.35
	_attribute_panel.anchor_top = 0.0
	_attribute_panel.anchor_right = 0.65
	_attribute_panel.anchor_bottom = 0.4
	_attribute_panel.offset_left = 10
	_attribute_panel.offset_top = 10
	_attribute_panel.offset_right = -10
	_attribute_panel.offset_bottom = -10
	add_child(_attribute_panel)
	
	_attribute_label = Label.new()
	_attribute_label.text = "属性对比面板"
	_attribute_panel.add_child(_attribute_label)
	
	# 创建难度曲线面板
	_curve_panel = PanelContainer.new()
	_curve_panel.anchor_left = 0.7
	_curve_panel.anchor_top = 0.0
	_curve_panel.anchor_right = 1.0
	_curve_panel.anchor_bottom = 0.4
	_curve_panel.offset_left = 10
	_curve_panel.offset_top = 10
	_curve_panel.offset_right = -10
	_curve_panel.offset_bottom = -10
	add_child(_curve_panel)
	
	_curve_line = Line2D.new()
	_curve_line.width = 2.0
	_curve_line.default_color = Color.WHITE
	_curve_panel.add_child(_curve_line)

## 更新所有面板
func _update_all_panels():
	_update_scaling_panel()
	_update_attribute_panel()
	_update_curve_panel()

## 更新缩放系数面板
##
## 开发者UI-1: 显示当前玩家的等级系数、境界系数、区域难度倍率、动态难度调整状态
func _update_scaling_panel():
	var level_coeff = LevelCoefficient.calculate_level_coefficient(_current_player_level)
	var realm_coeff = RealmCoefficient.calculate_realm_coefficient(_current_player_level)
	var region_mult = EnemyMultipliers.get_region_multiplier(_current_region_id)
	var dynamic_coeff = DynamicDifficulty.calculate_dynamic_coefficient(
		_failure_count, _perfect_win_count
	)
	
	var region_name = EnemyMultipliers.get_region_name(_current_region_id)
	
	var text = "缩放系数面板\n"
	text += "玩家等级: %d\n" % _current_player_level
	text += "等级系数: %.4f\n" % level_coeff
	text += "境界系数: %.2f\n" % realm_coeff
	text += "区域: %s (%.2f)\n" % [region_name, region_mult]
	text += "动态难度: %.2f\n" % dynamic_coeff
	
	if _failure_count > 0:
		text += "失败次数: %d (惩罚)\n" % _failure_count
	elif _perfect_win_count > 0:
		text += "无伤胜利: %d (奖励)\n" % _perfect_win_count
	
	_scaling_label.text = text

## 更新属性对比面板
##
## 开发者UI-2: 显示基础属性vs缩放后属性、各个倍率的贡献百分比、公式计算过程可视化
func _update_attribute_panel():
	var enemy_base_data = {
		"base_hp": 100,
		"base_attack": 20
	}
	
	var enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data,
		_current_player_level,
		_current_region_id,
		_current_enemy_type,
		_failure_count,
		_perfect_win_count
	)
	
	var hp_multiplier = (enemy["final_hp"] / enemy["base_hp"]) if enemy["base_hp"] > 0 else 0
	var attack_multiplier = (enemy["final_attack"] / enemy["base_attack"]) if enemy["base_attack"] > 0 else 0
	
	var text = "属性对比面板\n"
	text += "基础HP: %.0f → 最终HP: %.0f (×%.2f)\n" % [enemy["base_hp"], enemy["final_hp"], hp_multiplier]
	text += "基础攻击: %.0f → 最终攻击: %.0f (×%.2f)\n" % [enemy["base_attack"], enemy["final_attack"], attack_multiplier]
	text += "\n倍率贡献:\n"
	text += "  等级系数: %.4f (%.1f%%)\n" % [
		enemy["level_coefficient"],
		(enemy["level_coefficient"] / hp_multiplier * 100) if hp_multiplier > 0 else 0
	]
	text += "  境界系数: %.2f (%.1f%%)\n" % [
		enemy["realm_coefficient"],
		(enemy["realm_coefficient"] / hp_multiplier * 100) if hp_multiplier > 0 else 0
	]
	text += "  区域倍率: %.2f (%.1f%%)\n" % [
		enemy["region_multiplier"],
		(enemy["region_multiplier"] / hp_multiplier * 100) if hp_multiplier > 0 else 0
	]
	text += "  类型倍率: %.2f (%.1f%%)\n" % [
		enemy["type_hp_multiplier"],
		(enemy["type_hp_multiplier"] / hp_multiplier * 100) if hp_multiplier > 0 else 0
	]
	text += "  动态系数: %.2f (%.1f%%)\n" % [
		enemy["dynamic_coefficient"],
		(enemy["dynamic_coefficient"] / hp_multiplier * 100) if hp_multiplier > 0 else 0
	]
	
	_attribute_label.text = text

## 更新难度曲线面板
##
## 开发者UI-3: 显示横轴玩家等级(1-99)、纵轴敌人属性倍率、三段式曲线的衔接点
func _update_curve_panel():
	_curve_line.clear_points()
	
	var curve_points = []
	var max_multiplier = 0.0
	
	# 计算所有等级的倍率
	for level in range(1, 100):
		var level_coeff = LevelCoefficient.calculate_level_coefficient(level)
		var realm_coeff = RealmCoefficient.calculate_realm_coefficient(level)
		var total_mult = level_coeff * realm_coeff
		
		curve_points.append(total_mult)
		max_multiplier = max(max_multiplier, total_mult)
	
	# 绘制曲线
	var panel_size = _curve_panel.get_rect().size
	var padding = 20.0
	var graph_width = panel_size.x - padding * 2
	var graph_height = panel_size.y - padding * 2
	
	for i in range(curve_points.size()):
		var x = padding + (i / 99.0) * graph_width
		var y = padding + graph_height - (curve_points[i] / max_multiplier) * graph_height
		_curve_line.add_point(Vector2(x, y))
	
	# 标记衔接点 (33, 66)
	# 这些点在曲线上会有明显的变化

## 设置玩家等级
func set_player_level(level: int):
	_current_player_level = clamp(level, 1, 99)
	_update_all_panels()

## 设置区域
func set_region(region_id: int):
	_current_region_id = clamp(region_id, 0, 4)
	_update_all_panels()

## 设置敌人类型
func set_enemy_type(enemy_type: int):
	_current_enemy_type = clamp(enemy_type, 0, 2)
	_update_all_panels()

## 设置失败次数
func set_failure_count(count: int):
	_failure_count = max(0, count)
	_update_all_panels()

## 设置无伤胜利次数
func set_perfect_win_count(count: int):
	_perfect_win_count = max(0, count)
	_update_all_panels()

## 获取调试信息
func get_debug_info() -> Dictionary:
	return {
		"player_level": _current_player_level,
		"region_id": _current_region_id,
		"enemy_type": _current_enemy_type,
		"failure_count": _failure_count,
		"perfect_win_count": _perfect_win_count
	}