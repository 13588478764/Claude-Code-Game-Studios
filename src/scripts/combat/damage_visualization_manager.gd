## DamageVisualizationManager
## 武侠奇遇录 - 伤害可视化与反馈系统
##
## 负责显示伤害数字、特效和反馈，包括颜色、动画和音效。
## 遵循 GDD 中定义的可视化规则。
##
## 依赖关系：
## - UI 系统：显示伤害数字标签
## - 动画系统：播放伤害数字动画
## - 音频系统：播放伤害音效
## - 粒子系统：播放伤害特效
##
## 主要功能：
## - 伤害数字显示（不同伤害类型的颜色）
## - 伤害动画播放（上升、淡出、闪烁）
## - 伤害预览显示（预期伤害值）
## - 伤害分解显示（详细伤害计算过程）
## - 伤害反馈播放（音效和特效）

extends Node

class_name DamageVisualizationManager

# ============================================================================
# 常量定义
# ============================================================================

## 外功伤害颜色（白色）
const DAMAGE_COLOR_PHYSICAL: Color = Color.WHITE

## 内功伤害颜色（蓝色）
const DAMAGE_COLOR_ENERGY: Color = Color.CYAN

## 真实伤害颜色（红色）
const DAMAGE_COLOR_TRUE: Color = Color.RED

## 暴击伤害颜色（金色）
const DAMAGE_COLOR_CRITICAL: Color = Color.YELLOW

## 伤害数字显示时长（秒）
const DAMAGE_NUMBER_DURATION: float = 1.0

## 普通伤害缩放
const DAMAGE_NUMBER_SCALE_NORMAL: float = 1.0

## 暴击伤害缩放
const DAMAGE_NUMBER_SCALE_CRITICAL: float = 1.5

## 伤害数字向上偏移（像素）
const DAMAGE_NUMBER_OFFSET_Y: float = -50.0

## 伤害数字字体大小
const DAMAGE_NUMBER_FONT_SIZE: int = 32

## 普通伤害上升距离（像素）
const DAMAGE_NUMBER_RISE_NORMAL: float = 50.0

## 暴击伤害上升距离（像素）
const DAMAGE_NUMBER_RISE_CRITICAL: float = 100.0

## 暴击闪烁次数
const CRITICAL_BLINK_COUNT: int = 5

## 暴击闪烁间隔（秒）
const CRITICAL_BLINK_INTERVAL: float = 0.1

# ============================================================================
# 信号定义
# ============================================================================

## 伤害可视化完成信号
signal damage_visualized(damage_value: int, damage_type: String, is_critical: bool)

## 伤害动画开始信号
signal damage_animation_started(damage_value: int, is_critical: bool)

## 伤害动画完成信号
signal damage_animation_finished(damage_value: int)

## 伤害反馈播放信号
signal damage_feedback_played(damage_type: String, is_critical: bool)

# ============================================================================
# 公共方法
# ============================================================================

## 显示伤害数字
## @param damage_value: 伤害值
## @param damage_type: 伤害类型 (physical/energy/true)
## @param is_critical: 是否暴击
## @param position: 显示位置 (Vector2)
func show_damage_number(damage_value: int, damage_type: String, is_critical: bool, position: Vector2 = Vector2.ZERO) -> void:
	# 获取伤害数字颜色
	var color: Color = _get_damage_color(damage_type, is_critical)
	
	# 获取伤害数字缩放
	var scale: float = DAMAGE_NUMBER_SCALE_NORMAL
	if is_critical:
		scale = DAMAGE_NUMBER_SCALE_CRITICAL
	
	# 创建伤害数字标签
	var damage_label: Label = Label.new()
	damage_label.text = str(damage_value)
	damage_label.add_theme_font_size_override("font_size", DAMAGE_NUMBER_FONT_SIZE)
	damage_label.add_theme_color_override("font_color", color)
	damage_label.position = position + Vector2(0, DAMAGE_NUMBER_OFFSET_Y)
	damage_label.scale = Vector2(scale, scale)
	
	# 添加到场景
	add_child(damage_label)
	
	# 发送信号
	emit_signal("damage_animation_started", damage_value, is_critical)
	
	# 播放动画
	_animate_damage_number(damage_label, damage_value, is_critical)
	
	# 发送信号
	emit_signal("damage_visualized", damage_value, damage_type, is_critical)

## 显示伤害预览
## @param expected_damage: 预期伤害值
## @param target_name: 目标名称 (可选)
## @return 预览文本
func show_damage_preview(expected_damage: int, target_name: String = "") -> String:
	var preview_text: String = "对%s造成约%d点伤害" % [target_name if target_name else "当前目标", expected_damage]
	return preview_text

## 显示详细伤害分解
## @param damage_data: 伤害数据字典
## @return 分解文本
func show_detailed_damage_breakdown(damage_data: Dictionary) -> String:
	var breakdown_text: String = ""
	
	# 基础伤害
	if damage_data.has("base_damage"):
		breakdown_text += "基础伤害: %d\n" % damage_data["base_damage"]
	
	# 暴击系数
	if damage_data.has("critical_multiplier") and damage_data["critical_multiplier"] > 1.0:
		breakdown_text += "暴击系数: %.2fx\n" % damage_data["critical_multiplier"]
	
	# 连击系数
	if damage_data.has("combo_multiplier") and damage_data["combo_multiplier"] > 1.0:
		breakdown_text += "连击系数: %.2fx\n" % damage_data["combo_multiplier"]
	
	# 弱点系数
	if damage_data.has("weakness_multiplier") and damage_data["weakness_multiplier"] > 1.0:
		breakdown_text += "弱点系数: %.2fx\n" % damage_data["weakness_multiplier"]
	
	# 状态修正
	if damage_data.has("status_multiplier") and damage_data["status_multiplier"] > 1.0:
		breakdown_text += "状态修正: %.2fx\n" % damage_data["status_multiplier"]
	
	# 最终伤害
	if damage_data.has("final_damage"):
		breakdown_text += "最终伤害: %d" % damage_data["final_damage"]
	
	return breakdown_text

## 播放伤害反馈（特效和音效）
## @param damage_type: 伤害类型 (physical/energy/true)
## @param is_critical: 是否暴击
func play_damage_feedback(damage_type: String, is_critical: bool) -> void:
	# 播放音效
	_play_damage_sound(damage_type, is_critical)
	
	# 播放特效
	_play_damage_effect(damage_type, is_critical)
	
	# 发送信号
	emit_signal("damage_feedback_played", damage_type, is_critical)


# ============================================================================
# 私有方法
# ============================================================================

## 获取伤害数字颜色
## @param damage_type: 伤害类型
## @param is_critical: 是否暴击
## @return 颜色值
func _get_damage_color(damage_type: String, is_critical: bool) -> Color:
	if is_critical:
		return DAMAGE_COLOR_CRITICAL
	
	match damage_type:
		"physical":
			return DAMAGE_COLOR_PHYSICAL
		"energy":
			return DAMAGE_COLOR_ENERGY
		"true":
			return DAMAGE_COLOR_TRUE
		_:
			push_warning("DamageVisualizationManager: 未知的伤害类型: %s" % damage_type)
			return DAMAGE_COLOR_PHYSICAL

## 播放伤害数字动画
## @param label: 伤害数字标签
## @param damage_value: 伤害值
## @param is_critical: 是否暴击
func _animate_damage_number(label: Label, damage_value: int, is_critical: bool) -> void:
	# 创建 Tween 动画
	var tween: Tween = create_tween()
	
	if is_critical:
		# 暴击动画: 闪烁 + 上升
		tween.set_parallel(true)
		tween.tween_property(label, "position:y", label.position.y - DAMAGE_NUMBER_RISE_CRITICAL, DAMAGE_NUMBER_DURATION)
		tween.tween_property(label, "modulate:a", 0.0, DAMAGE_NUMBER_DURATION)
		
		# 闪烁效果
		for i in range(CRITICAL_BLINK_COUNT):
			tween.tween_callback(func(): label.modulate = Color.WHITE)
			tween.tween_callback(func(): label.modulate = DAMAGE_COLOR_CRITICAL)
			tween.tween_interval(CRITICAL_BLINK_INTERVAL)
	else:
		# 普通动画: 上升 + 淡出
		tween.set_parallel(true)
		tween.tween_property(label, "position:y", label.position.y - DAMAGE_NUMBER_RISE_NORMAL, DAMAGE_NUMBER_DURATION)
		tween.tween_property(label, "modulate:a", 0.0, DAMAGE_NUMBER_DURATION)
	
	# 动画完成后删除标签
	tween.tween_callback(func(): 
		emit_signal("damage_animation_finished", damage_value)
		label.queue_free()
	)

## 播放伤害音效
## @param damage_type: 伤害类型
## @param is_critical: 是否暴击
func _play_damage_sound(damage_type: String, is_critical: bool) -> void:
	# 这里应该播放对应的音效
	# 实现细节由音频系统处理
	pass

## 播放伤害特效
## @param damage_type: 伤害类型
## @param is_critical: 是否暴击
func _play_damage_effect(damage_type: String, is_critical: bool) -> void:
	# 这里应该播放对应的特效
	# 实现细节由粒子系统处理
	pass